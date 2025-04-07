local moon = require("moon")
local hotfix = require("hotfix")
local fs = require("fs")
local seri = require("seri")
local datetime = require("moon.datetime")
local common = require("common")
local cluster = require("cluster")
local GameDef = common.GameDef
local protocol = common.protocol
local CmdCode = common.CmdCode
local GameCfg = common.GameCfg

local string = string
local type = type
local strfmt = string.format
local traceback = debug.traceback

local unpack_one = seri.unpack_one
local pack = moon.pack
local raw_send = moon.raw_send


local command = {}

hotfix.addsearcher(function(file)
    local content = moon.env(file)
    return load(content, "@" .. file), file
end)

local function load_scripts(context, sname)
    --local ret = LuaPanda and LuaPanda.BP and LuaPanda.BP();
    local dir = strfmt("game/%s/", sname)
    local scripts = moon.env_unpacked(dir)
    if not scripts then
        scripts = {}
        local list = fs.listdir(dir, 10)
        for _, file in ipairs(list) do
            if not fs.isdir(file) then
                local name = fs.stem(file)
                scripts[name] = dir .. name .. ".lua"
            end
        end
        moon.env_packed(dir, scripts)
    end

    for name, file in pairs(scripts) do
        local fn
        local content = moon.env(file)
        if content then
            fn = load(content, "@" .. file)
        else
            fn = assert(loadfile(file))
        end
        local t = fn(context)
        assert(type(t) == "table")

        context.scripts[name] = t
        hotfix.register(file, fn, t)

        for k, v in pairs(t) do
            if type(v) == "function" then
                if string.sub(k, 1, 3) == "C2S" then
                    command[k] = v
                elseif string.sub(k, -string.len("Cmd")) == "Cmd" then
                    command[k] = v
                else
                    command[name .. "." .. k] = v
                end
            end
        end
    end
end

---@param context base_context
local function start_hour_timer(context)
    local fn = command["OnHour"]
    if not fn then
        return
    end

    local MILLSECONDS_ONE_HOUR <const> = 3600000

    local hour = datetime.localtime(moon.time()).hour
    moon.async(function()
        while true do
            local diff = MILLSECONDS_ONE_HOUR - moon.now() % MILLSECONDS_ONE_HOUR + 100
            moon.sleep(diff)
            local tm = datetime.localtime(moon.time())
            if hour == tm.hour then
                moon.error("not hour!")
            else
                hour = tm.hour
                local _ = context.batch_invoke("OnHour", hour)
                if hour == 0 then
                    hour = tm.hour
                    local _ = context.batch_invoke("OnDay", datetime.localday())
                end
            end
        end
    end)
end

local function extract_gn(GnId)
    local node = (GnId & 0xFF000000) >> 24 -- 获取node部分
    local flag = (GnId >> 23) & 0x1    -- 获取flag部分
    local index = GnId & 0x007FFFFF    -- 获取index部分
    -- 返回node、flag和index
    return node, flag, index
end

local function get_globalds()
    local data = moon.env("GloabalDsGnId")
    if data then
        return math.tointeger(data)
    end
    return 0
end

-- 转发发往客户端的消息(只能向客户端转发)
local function forwardD2C(context, GnId, MessagePack)
    if GnId == 0 then
        return
    end
    if not context.NODE then
        context.NODE = math.tointeger(moon.env("NODE"))
    end
    local node, flag, index = extract_gn(GnId)
    if context.NODE == node then
        -- 本节点转发
        if flag == 0 then
            context.D2C(GnId, MessagePack)
        end
    else
       
        -- 通过其他节点转发
        if flag == 0 then
            cluster.send(node, 'gate', "ForwardD2C", GnId, MessagePack)
        else
            print("forwardD2C err, cannot send msg to other client !!!", GnId)
        end
    end
end
local function _internal(context)
    ---@class base_context
    ---@field scripts table
    ---@field addr_gate integer
    ---@field addr_auth integer
    ---@field addr_center integer
    ---@field addr_db_user integer
    ---@field addr_db_server integer
    ---@field addr_db_openid integer
    ---@field addr_mail integer
    local base_context = context

    setmetatable(base_context, {
        __index = function(t, key)
            if string.sub(key, 1, 5) == "addr_" then
                local addr = moon.queryservice(string.sub(key, 6))
                if addr == 0 then
                    error("Can not found service: " .. tostring(key))
                end
                t[key] = addr
                return addr
            end
            return nil
        end
    })

    if not base_context.scripts then
        base_context.scripts = {}
    end

    --- 开启整点定时器
    function base_context.start_hour_timer()
        start_hour_timer(context)
    end

    --- 批量调用所有脚本的函数, 如果发生错误, 会打印错误信息
    function base_context.batch_invoke(cmd, ...)
        for _, v in pairs(context.scripts) do
            local f = v[cmd]
            if f then
                local ok, err = xpcall(f, traceback, ...)
                if not ok then
                    moon.error(err)
                end
            end
        end
    end

    --- 批量调用所有脚本的函数, 如果发生错误, 抛出异常
    function base_context.batch_invoke_throw(cmd, ...)
        for _, v in pairs(context.scripts) do
            local f = v[cmd]
            if f then
                f(...)
            end
        end
    end

    --- send message to client.
    function base_context.S2CX(uid, cmd_code, mtable, stubId)
        -- 查询uid对应的节点
        local net_id = cluster.call(9999, 'usermgr', "getNetIdByUid", uid)
        base_context.S2C(net_id, cmd_code, mtable, stubId)
    end

    base_context.S2C = function(net_id, cmd_code, mtable, stubId)
        forwardD2C(context, net_id, protocol.encodeMessagePacket(net_id, cmd_code, mtable, stubId or 0))
        --moon.raw_send('S2C', context.addr_gate, protocol.encodePacket(uid, cmd_code, mtable,mc))
    end
    base_context.send_user = function(uid, cmd, ...)
        -- 查询uid对应的节点
        local node, addr_user = cluster.call(9999, 'usermgr', "getAddrUserByUid", uid)
        if not context.NODE then
            context.NODE = math.tointeger(moon.env("NODE"))
        end
        if node == 0 or addr_user == 0 then
            moon.warn("send_user failed, node = ", node, " addr_user = ", addr_user)
            return
        end
        if context.NODE == node then
            moon.send("lua", addr_user, cmd, ...)
        else
            cluster.send(node, addr_user, cmd, ...)
        end
    end
    base_context.send_users = function(uids, not_uids, cmd, ...)
        if not_uids then
            local tmp = {}
            for _, uid in ipairs(uids) do
                if not not_uids[uid] then
                    table.insert(tmp, uid)
                end
            end
            uids = tmp
        end
        --查询在线用户列表
        local online_uids = cluster.call(9999, "usermgr", "Usermgr.getOnlineUsers", uids)
        if not online_uids then
            return false, "getOnlineUsers failed"
        end

        if not context.NODE then
            context.NODE = math.tointeger(moon.env("NODE"))
        end
        --遍历在线用户列表，发送消息
        for uid, info in pairs(online_uids) do
            local node, addr_user = info.node, info.addr_user
            if node ~= 0 or addr_user ~= 0 then
                if context.NODE == node then
                    moon.send("lua", addr_user, cmd, ...)
                else
                    cluster.send(node, addr_user, cmd, ...)
                end
            else
                moon.warn("send_user failed, node = ", node, " uid= ", uid, "addr_user = ", addr_user)
            end
        end
        return true
    end



    --- send message to user-service and get results.
    base_context.call_user = function(uid, cmd, ...)
        --return moon.call("lua", context.addr_auth, "Auth.CallUser", uid, ...)
        local node, addr_user = cluster.call(9999, 'usermgr', "getAddrUserByUid", uid)
        if node == 0 or addr_user == 0 then
            moon.warn("send_user failed, node = ", node, " addr_user = ", addr_user)
            return
        end
        if not context.NODE then
            context.NODE = math.tointeger(moon.env("NODE"))
        end
        if context.NODE == node then
            return moon.call("lua", addr_user, cmd, ...)
        else
            return cluster.call(node, addr_user, cmd, ...)
        end
    end

    command.hotfix = function(fixlist)
        for name, file in pairs(fixlist) do
            local ok, t = hotfix.update(file)
            if ok then
                print(moon.name, "hotfix", name, file)
                for k, v in pairs(t) do
                    if string.sub(k, 1, 3) == "C2S" then
                        command[k] = v
                    else
                        command[name .. "." .. k] = v
                    end
                end
            else
                moon.error(moon.name, "hotfix failed", t, name, file)
                break
            end
        end
    end

    command.reload = function(names)
        GameCfg.Reload(names)
        print(moon.name, "reload", table.concat(names, " "))
    end

    command.Init = function(...)
        GameCfg.Load()
        base_context.batch_invoke_throw("Init", ...)
        return true
    end

    command.Start = function(...)
        base_context.batch_invoke_throw("Start", ...)
        return true
    end
end

local function xpcall_ret(ok, ...)
    if ok then
        return pack(...)
    end
    return pack(false, ...)
end

local function do_client_command(context, cmd, uid, req)
    local fn = command[cmd]
    if fn then
        local ok, res = xpcall(fn, traceback, uid, req)
        if not ok then
            moon.error(res)
            context.S2C(uid, CmdCode.S2CErrorCode, { code = 1 }) -- server internal error
        else
            if res and res > 0 then
                context.S2C(uid, CmdCode.S2CErrorCode, { code = res })
            end
        end
    else
        moon.error(moon.name, "receive unknown PTYPE_C2S cmd " .. tostring(cmd) .. " " .. tostring(uid))
    end
end



--转发DS发来的消息
local function forwardD(context,GnId,MessagePack)
    if GnId == 0 then
        -- 全局DS
        GnId = get_globalds()
        if GnId == 0 then
            print("forwardD cur Node Cant find GloabalDsGnId!!!!",NODE)
            return
        end
    end
    local node,flag,index = extract_gn(GnId)
    if not context.NODE then
        context.NODE = math.tointeger(moon.env("NODE"))
    end
    if context.NODE == node then
        -- 本节点转发
        if flag == 1 then
            context.D2D(GnId,MessagePack)
        else
            --客户端消息需要通过Gate转发
            context.D2C(GnId,MessagePack)
        end
    else
        if node == 0 then
            print("forwardD err,node = 0,GnId = ",GnId)
            return
        end
        -- 通过其他节点转发
        if flag == 1 then
            cluster.send(node, 'dgate',"ForwardD2D", GnId,MessagePack)
        else
            cluster.send(node, 'gate',"ForwardD2C", GnId,MessagePack)
        end 
    end
end
-- 转发从客户端发来的消息(只能向DS转发)
local function forwardC(context,GnId,MessagePack)
    if GnId == 0 then
        -- 全局DS
        GnId = get_globalds()
        if GnId == 0 then
            print("forwardC cur Node Cant find GloabalDsGnId!!!!",NODE)
            return
        end
    end
    if not context.NODE then
        context.NODE = math.tointeger(moon.env("NODE"))
    end
    local node,flag,index = extract_gn(GnId)
    if context.NODE == node then
        -- 本节点转发
        if flag == 1 then
            context.C2D(GnId,MessagePack)
        end
    else
        -- 通过其他节点转发
        if flag == 1 then
            cluster.send(node, 'dgate',"ForwardC2D", GnId,MessagePack)
        else
            print("forwardC err, cannot send msg to other client !!!",GnId)
        end
    end
end



return function(context, sname)
    sname = sname or moon.name
    context.forwardD = function(GnId,MessagePack)
        forwardD(context,GnId,MessagePack)
    end

    context.forwardC = function(GnId,MessagePack)
        forwardC(context,GnId,MessagePack)
    end

    _internal(context)

    load_scripts(context, sname)

    moon.dispatch("lua", function(sender, session, cmd, ...)
        local netcmd = cmd
        if string.sub(cmd, -string.len("Cmd")) == "Cmd" then
             netcmd = string.gsub(cmd, "%.", "_")
        end
        local fn = command[netcmd]
        if fn then
            if session ~= 0 then
                raw_send("lua", sender, xpcall_ret(xpcall(fn, traceback, ...)), session)
            else
                fn(...)
            end
        else
            moon.error(moon.name, "recv unknown cmd " .. tostring(cmd))
        end
    end)

    moon.register_protocol({
        name = "C2S",
        PTYPE = GameDef.PTYPE_C2S,
        --default client message dispatch
        israw = true,
        dispatch = function(msg)
            local buf = moon.decode(msg, "B")
            --see: user service's forward
            local uid = unpack_one(buf, true)
            local ok, cmd, data = pcall(protocol.decode, buf)
            if not ok then
                moon.error("protobuffer decode client message failed", cmd)
                moon.send("lua", context.gate, "Gate.Kick", uid)
                return
            end
            moon.async(do_client_command, context, cmd, uid, data)
        end
    })
 

    moon.register_protocol({
        name = "S2C",
        PTYPE = GameDef.PTYPE_S2C,
        dispatch = nil
    })

    moon.register_protocol({
        name = "SBC",
        PTYPE = GameDef.PTYPE_SBC,
        dispatch = nil
    })

    moon.register_protocol({
        name = "S2D",
        PTYPE = GameDef.PTYPE_S2D,
        dispatch = nil
    })
    moon.register_protocol({
        name = "D2S",
        PTYPE = GameDef.PTYPE_D2S,
        dispatch = nil
    })
    moon.register_protocol({
        name = "D2D",
        PTYPE = GameDef.PTYPE_D2D,
        dispatch = nil
    })
    moon.register_protocol({
        name = "C2D",
        PTYPE = GameDef.PTYPE_C2D,
        dispatch = nil
    })
    moon.register_protocol({
        name = "D2C",
        PTYPE = GameDef.PTYPE_D2C,
        dispatch = nil
    })
  
    --- send message to client.
    context.D2D = function(net_id, MessagePack)
        local Packet =  { messages =  {MessagePack} }
        local data = protocol.encodestring(1,  Packet)
        moon.raw_send('D2D', context.addr_dgate,seri.packs(net_id) .. data)
    end
    context.C2D = function(net_id, MessagePack)
        local Packet =  { messages =  {MessagePack} }
        local data = protocol.encodestring(1,  Packet)
        moon.raw_send('C2D', context.addr_dgate,seri.packs(net_id) .. data)
    end
    context.D2C = function(net_id, MessagePack)
        local Packet =  { messages =  {MessagePack} }
        local data = protocol.encodestring(1,  Packet)
        moon.raw_send('D2C', context.addr_gate,seri.packs(net_id) .. data)
    end

    context.S2C = function(net_id, cmd_code, mtable,stubId)
        forwardD2C(context,net_id,protocol.encodeMessagePacket(net_id, cmd_code, mtable,stubId or 0))
        --moon.raw_send('S2C', context.addr_gate, protocol.encodePacket(uid, cmd_code, mtable,mc))
    end

    context.S2D = function(net_id, cmd_code, mtable,stubId)
        forwardD(context,net_id,protocol.encodeMessagePacket(net_id, cmd_code, mtable,stubId or 0))
       -- moon.raw_send('S2D', context.addr_dgate, protocol.encodePacket(net_id, cmd_code, mtable,mc))
    end
    
    context.D2S = function(net_id, cmd_code, mtable,stubId)
        --forwardD(context,net_id,protocol.encodeMessagePacket(net_id, cmd_code, mtable,stubId or 0))
       -- moon.raw_send('S2D', context.addr_dgate, protocol.encodePacket(net_id, cmd_code, mtable,mc))
    end

    

 

    return command
end



