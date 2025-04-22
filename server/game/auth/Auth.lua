
local moon = require("moon")
local uuid = require("uuid")
local queue = require("moon.queue")
local common = require("common")
local clusterd = require("cluster")

local db = common.Database
local CmdCode = common.CmdCode
local CmdEnum = common.CmdEnum
local ErrorCode = common.ErrorCode
local pb = require "pb"
local traceback = debug.traceback

local mem_player_limit = 0 --内存中最小玩家数量
local min_online_time = 60 --seconds，logout间隔大于这个时间的,并且不在线的,user服务会被退出

---@type auth_context
local context = ...
--
local auth_queue = context.auth_queue
--local temp_openid = {}
local NODE = math.tointeger(moon.env("NODE"))

local function doDSAuth(req)
    local u = context.net_id_map[req.net_id]
    local addr_dsnode
    if not u then
        local conf = {
            name = "dsnode"..req.net_id,
            file = "game/service_dsnode.lua"
        }
        addr_dsnode = moon.new_service(conf)
        if addr_dsnode == 0 then
            return { code = 2001, error = "create dsnode service failed!" }
        end
        req.addr_dsnode = addr_dsnode

        local ok, err = moon.call("lua", addr_dsnode, "DsNode.Load", req)
        local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
        if not ok then
            moon.send("lua", context.addr_dgate, "DGate.Kick", 0, req.fd)
            moon.kill(addr_dsnode)
            context.net_id_map[req.net_id] = nil
            return { code = 2002, error = err }
        end
    else
        addr_dsnode = u.addr_dsnode
    end

    local dsid, err = moon.call("lua", addr_dsnode, "DsNode.Login", req)
    local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
    if not dsid then
        print(dsid, err)
        moon.send("lua", context.addr_dgate, "DGate.Kick", 0, req.fd)
        moon.kill(addr_dsnode)
        context.net_id_map[req.net_id] = nil
        return { code = 2003, error = err }
    end

    if not u then
        u = {
            addr_dsnode = addr_dsnode,
            dsid = dsid,
            net_id = req.net_id,
            logouttime = moon.time(),
            online = false
        }

        context.ds_map[req.dsid] = u
        context.net_id_map[req.net_id] = u
    end

    req.addr_dsnode = addr_dsnode

    local pass = true

    if pass then
        u.logouttime = 0
        print("DS login success", req.net_id)
    else
        print("DS login failed", req.net_id)
    end

    moon.send("lua", context.addr_dgate, "DGate.BindDS", req)

    local res = {
        result = pass and 0 or 1,---maybe banned
        connId = req.fd,
        net_id = req.net_id,
        dsid = u.dsid,
    }
    --context.S2D(req.net_id, CmdCode["dsgatepb.AuthResultCmd"], res, req.msg_context.stub_id)
    return { code = 0, error = "sucess", res = res }
end

local function doAuth(Auth,req)
    local u = context.uid_map[req.uid]
    local addr_user
    if not u then
        local conf = {
            name = "user" .. req.uid,
            file = "game/service_user.lua"
        }
        addr_user = moon.new_service(conf)
        if addr_user == 0 then
            return { code = 2001, error = "create user service failed!" }
        end

        req.addr_user = addr_user
        local ok, err = moon.call("lua", addr_user, "User.Load", req)
        if not ok then
            --moon.send("lua", context.addr_gate, "Gate.Kick", 0, req.fd)
            moon.kill(addr_user)
            context.uid_map[req.uid] = nil
            return { code = 2002, error = err }
        end
    else
        addr_user = u.addr_user
        req.addr_user = addr_user
    end

    local authkey, err = moon.call("lua", addr_user, "User.Login", req)
    --
    if not authkey then
        print(authkey, err)
        --moon.send("lua", context.addr_gate, "Gate.Kick", 0, req.fd)
        moon.kill(addr_user)
        context.uid_map[req.uid] = nil
        return { code = 2003, error = err }
    end

    u = {
        addr_user = addr_user,
        authkey = authkey,
        openid = "",
        uid = req.uid,
        logouttime = 0,
        online = true,
        net_id = req.net_id
    }

    context.uid_map[req.uid] = u
    context.net_id_map[req.net_id] = u

    print("doAuth uid_map", req.uid, u.addr_user)

    if req.pull then
        print("doAuth pull", req.uid, req.net_id)
        return { code = 2003, error = "req.pull is true" }
    end

    --req.addr_user = addr_user
    
    -- local pass = true
    -- if pass then
    --     u.logouttime = 0
    --     print("login success", req.uid)
    -- else
    --     print("login failed", req.uid)
    -- end

    db.updatelogin(context.addr_db_game, req.uid)
    moon.send("lua", context.addr_gate, "Gate.BindUser", req)

    local res = {
        result = 0, --maybe banned
        net_id = u.net_id,
        uid = u.uid,
    }
    return { code = 0, error = "sucess", res = res }
end

local function QuitOneUser(u)
    moon.send("lua", u.addr_user, "User.Exit")
    context.uid_map[u.uid] = nil
    context.net_id_map[u.net_id] = nil
end

---@class Auth
local Auth = {}

Auth.Init = function()

    moon.async(function()
        while true do
            moon.sleep(10000)
            if context.server_exit then
                return
            end

            local now = moon.time()

            local count = table.count(context.uid_map)
            for _, u in pairs(context.uid_map) do
                if count > mem_player_limit then
                    if u.logouttime > 0 and (now - u.logouttime) > min_online_time then
                        QuitOneUser(u)
                        count = count - 1
                    end
                else
                    break
                end
            end
        end
    end)

    context.start_hour_timer()

    context.addr_db_game = moon.queryservice("db_game")

    local ok, err = moon.call("lua", context.addr_db_game, [[
        CREATE TABLE IF NOT EXISTS account (
            user_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
            username VARCHAR(64) NOT NULL,
            password_hash CHAR(32) NOT NULL,
            create_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            last_login TIMESTAMP NULL,
            PRIMARY KEY (user_id),
            UNIQUE INDEX (username)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])
    assert(ok, "Failed to create account table: " .. tostring(err)) -- 增强错误提示

    return true
end

Auth.Start = function()
    context.start_hour_timer()
    return true
end

Auth.Shutdown = function()
    context.server_exit = true
    print("begin: server exit save user")
    local ok, err = xpcall(function()
        while true do
            local ifbreak = true
            for uid, q in pairs(auth_queue) do
                local n = q("counter")
                if n > 0 then
                    ifbreak = false
                    print("wait all async event done:", uid, n)
                    break
                end
            end
            if ifbreak then
                break
            end
            moon.sleep(100)
        end

        ---let all user service quit
        local count  = 0
        for _ ,u in pairs(context.uid_map) do
            QuitOneUser(u)
            count = count + 1
        end
        return count
    end, debug.traceback)
    print("end: server exit save user", ok, err)
    moon.quit()
    return true
end

Auth.OnHour = function(v)
    print("OnHour", v)
    for _,u in pairs(context.uid_map) do
        if u.logouttime == 0 then
            moon.send("lua", u.addr_user, "User.OnHour", v)
        end
    end
end

Auth.OnDay = function(v)
    print("OnDay", v)
    for _, u in pairs(context.uid_map) do
        if u.logouttime == 0 then
            moon.send("lua", u.addr_user, "User.OnDay", v)
        end
    end
end

local function GenGN(value_node, value_flag, value_index)
    -- 首先确保index适合uint32的范围
    assert(value_index <= 0x007FFFFF, "Index out of range for its allocated bits")
    value_node = value_node & 0xFF
    value_flag = value_flag & 0x1
    -- 创建数字：node占据高8位，flag占据第23位，index占据低23位
    return (value_node << 24) |  (value_flag << 23) | value_index
end

Auth.AllocGateNetId = function(isds)
    if not context.gnstart then
        context.gnstart = 1
    end
    local condition = 1
    while condition < 0x007FFFFF do
        context.gnstart = context.gnstart + 1
        if context.gnstart > 0x007FFFFF then
            context.gnstart = 1
        end
        local net_id = GenGN(NODE, isds, context.gnstart)
        if context.net_id_map[net_id] == nil then
            return net_id
        end
        condition = condition + 1
    end
    return 0xFFFFFFFF
end

Auth.PBClientLoginReqCmd = function (req)
    local function processLogin()
        if req.msg.is_register then

            -- 注册逻辑（直接存储客户端提供的MD5）
            local check_res, check_err = db.checkuser(context.addr_db_game, req.msg.login_data.authkey)
            if check_err and not check_res and next(check_res) then
                return { code = 1001, error = "USERNAME_EXISTS" }
            end
            --
            local create_res, create_err = db.createuser(
                context.addr_db_game,
                req.msg.login_data.authkey,
                req.msg.password -- 直接使用客户端提供的MD5
            )
            --
            if create_err or not create_res.insert_id then
                return { code = 1002, error = "CREATE_ACCOUNT_FAILED" }
            end

            req.uid = create_res.insert_id
        else
            if req.msg.login_data.authkey == "" or req.msg.password == "" then
                return { code = 1003, error = "INVALID_USERNAME_OR_PASSWORD" }
            end
            -- 登录验证（直接比较MD5）
            local datas, err = db.getuserbyauthkey(context.addr_db_game, req.msg.login_data.authkey)
            print("datas=\n" .. print_r(datas, true))
            -- 判断user_data是否为nil或空表
            if err or datas == nil or next(datas) == nil then
                return { code = 1003, error = "INVALID_AUTHKEY" }
            end
            local data = datas[1]
            --
            if req.msg.password ~= data.password_hash then
                return { code = 1004, error = "INVALID_PASSWORD" }
            end

            --db.updatelogin(context.addr_db_game, data.user_id)
            req.uid = data.user_id
        end

        return doAuth(Auth, req)
    end

    local function func()
        if not req then
            return { code = 1005, error = "INVALID_REQUEST" }
        end
        ---服务器关闭时,中断所有客户端的登录请求
        if context.server_exit and not req.pull then
            return { code = 1006, error = "SERVER_CLOSED" }
        end

        req.net_id = Auth.AllocGateNetId(0)
        moon.send("lua", context.addr_gate, "Gate.BindGnId", req)

        local uid = context.openid_map[req.msg.login_data.authkey]
        if not uid then
            ---避免同一个玩家瞬间发送大量登录请求
            -- local tmp = temp_openid[req.msg.login_data.authkey]
            -- if tmp then
            --     moon.error("user logining", req.fd, req.msg.login_data.authkey)
            --     return { code = 1007, error = "USER_LOGINING" }
            -- end
            -- temp_openid[req.msg.login_data.authkey] = 1
        else
            moon.error("user online", req.fd, req.uid)
            return { code = 1008, error = "USER_ONLINE" }
        end

        return processLogin()
    end
    
    local res = func()
    local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
    local ret =
    {
        code = res.code,
        error = res.error or "",
        uid = res.res and res.res.uid or 0,
        net_id = res.res and res.res.net_id or 0,
    }
    context.S2C(req.net_id, CmdCode["PBClientLoginRspCmd"], ret, req.msg_context.stub_id)

    if res.code ~= 0 then
        moon.send("lua", context.addr_gate, "Gate.Kick", 0, req.fd) -- body
    end
end
 
Auth.PBDSLoginReqCmd = function(req)
    local function processLogin()
        -- DS连接验证
        if req.msg.login_data.authkey == ""
            or req.msg.login_data.auth_ticket ~= context.conf.ds_ticket then
            return { code = 1003, error = "INVALID_DS" }
        end

        req.dsid = req.msg.login_data.ds_id

        return doDSAuth(req)
    end

    local function func()
        if not req then
            return { code = 1005, error = "INVALID_REQUEST" }
        end
        ---服务器关闭时,中断所有客户端的登录请求
        if context.server_exit and not req.pull then
            return { code = 1006, error = "SERVER_CLOSED" }
        end

        req.net_id = Auth.AllocGateNetId(1)
        --moon.send("lua", context.addr_dgate, "DGate.BindGnId", req)

        local dsid = context.openid_map[req.msg.login_data.authkey]
        if dsid then
            moon.error("user online", req.fd, dsid)
            return { code = 1008, error = "USER_ONLINE" }
        end

        return processLogin()
    end
     
    local res = func()
    local ret =
    {
        code = res.code,
        error = res.error or "",
        dsid = res.res and res.res.dsid or 0,
        net_id = res.res and res.res.net_id or 0,
    }
    local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
    context.S2D(req.net_id, CmdCode["PBDSLoginRspCmd"], ret, req.msg_context.stub_id)

    if res.code ~= 0 then
        moon.send("lua", context.addr_dgate, "DGate.Kick", 0, req.fd) -- body
    end
end

 

---加载离线玩家
function Auth.PullUser(uid)
    local u = context.uid_map[uid]
    if not u then
        local ok,err = Auth.C2SLogin({fd =0 ,uid = uid, pull = true})
        if not ok then
            return ok, err
        end
        u = context.uid_map[uid]
    end
    return u
end

---向玩家发起调用，会主动加载玩家
function Auth.CallUser(uid, cmd, ...)
    if context.server_exit then
        error(string.format("call user %d cmd %s when server exit", uid, cmd))
    end

    local u, err = Auth.PullUser(uid)
    if not u then
        return false, err
    end

    if u.logouttime > 0 then
        u.logouttime = moon.time()
    end

    return moon.call("lua", u.addr_user, cmd, ...)
end

---向玩家发送消息，会主动加载玩家
function Auth.SendUser(uid, cmd, ...)
    local u, err = Auth.PullUser(uid)
    if not u then
        moon.error(err)
        return
    end

    if u.logouttime > 0 then
        u.logouttime = moon.time()
    end

    moon.send("lua", u.addr_user, cmd,...)
end

---向已经在内存的玩家发送消息,不会主动加载玩家
function Auth.TrySendUser(uid, cmd, ...)
    local u = context.uid_map[uid]
    if not u then
        return
    end
    moon.send("lua", u.addr_user, cmd,...)
end

function Auth.Disconnect(uid)
    local u = context.uid_map[uid]
    if u then
        assert(moon.call("lua", u.addr_user, "User.Logout"))
        u.logouttime = moon.time()
    end
end

return Auth


