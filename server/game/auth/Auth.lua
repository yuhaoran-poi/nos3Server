
local moon = require("moon")
local uuid = require("uuid")
local queue = require("moon.queue")
local common = require("common")
local clusterd = require("cluster")
local serverconf = require("serverconf")
local json = require "json"
local fishsteam = require "fishsteam"

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
        if not ok then
            --local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
            moon.send("lua", context.addr_dgate, "DGate.Kick", 0, req.fd)
            moon.kill(addr_dsnode)
            context.net_id_map[req.net_id] = nil
            return { code = 2002, error = err }
        end
    else
        addr_dsnode = u.addr_dsnode
    end

    local dsid, err = moon.call("lua", addr_dsnode, "DsNode.Login", req)
    --local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
    if not dsid then
        --local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
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

local function doAuth(Auth, req)
    local u = context.uid_map[req.uid]
    -- moon.warn(string.format("req.uid %d", req.uid))
    -- moon.error(string.format("doAuth context.uid_map = %s", json.pretty_encode(context.uid_map)))
    local addr_user
    if not u then
        moon.warn(string.format("doAuth uid = %d not found", req.uid))
        local conf = {
            name = "user" .. req.uid,
            file = "game/service_user.lua"
        }
        addr_user = moon.new_service(conf)
        if addr_user == 0 then
            context.openid_map[req.msg.login_data.authkey] = nil
            return { code = 2001, error = "create user service failed!" }
        end
        req.addr_user = addr_user

        local ok, err = moon.call("lua", addr_user, "User.Load", req)
        if not ok then
            moon.error(string.format("doAuth User.Load err = %s", json.pretty_encode(err)))
            moon.kill(addr_user)
            context.uid_map[req.uid] = nil
            context.openid_map[req.msg.login_data.authkey] = nil
            return { code = 2002, error = err }
        end
    else
        -- 本节点顶号登录，直接重定向
        -- moon.send("lua", context.addr_gate, "Gate.Kick", req.uid)
        -- addr_user = u.addr_user
        -- req.addr_user = addr_user
        context.openid_map[req.msg.login_data.authkey] = nil
        return { code = 2005, error = "player online" }
    end

    local authkey, err = moon.call("lua", addr_user, "User.Login", req)
    --
    if not authkey then
        print(authkey, err)
        --moon.send("lua", context.addr_gate, "Gate.Kick", 0, req.fd)
        moon.kill(addr_user)
        context.uid_map[req.uid] = nil
        context.openid_map[req.msg.login_data.authkey] = nil
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
    moon.warn(string.format("doAuth net_id = %d, u.net_id = %d", req.net_id, u.net_id))

    print("doAuth uid_map", req.uid, u.addr_user)

    if req.pull then
        print("doAuth pull", req.uid, req.net_id)
        context.openid_map[req.msg.login_data.authkey] = nil
        return { code = 2004, error = "req.pull is true" }
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

    context.openid_map[req.msg.login_data.authkey] = nil
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
    moon.error(string.format("QuitOneUser net_id = %d", u.net_id))
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

            local count = table.size(context.uid_map)
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

    fishsteam.CheckFishSteam()
    local rgubTicket =
    "080210C8CC93A108180420522A8001F4F43E49CD856FC8070912D10580998E03EF9A166501D63D6A96D6DEFA624E2822FF7E8EE2C513C9E89D41BA5089706003D50F635650F4E20D4D00FE000B46A64DA2A5D7E1E332FDFB82FCF13643C14A0228A78A3AD3ACB17B103F0396D196C4639C6AFDBE3EB7A552BF061FD7E172CEB8F9D9A32F6AEA247D985938E40B6523"
    local ticket_length = string.len(rgubTicket)
    local appKey = serverconf.STEAM_APP_KEY
    local appId = serverconf.STEAM_APP_ID
    local now = moon.time()
    local begValidTimem = now - 60
    local endValidTime = now + 60
    begValidTimem = 1755174198
    endValidTime = 1755174798
    local steam_id = fishsteam.CheckSteamAuthSessionTicket(rgubTicket, ticket_length, appKey, appId, begValidTimem,
    endValidTime, 0)
    moon.warn("Auth.Init steam_id = ", steam_id)

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

Auth.PBClientLoginReqCmd = function(req)
    local function checkSteamTicket()
        local now_ts = moon.time()
        local begValidTimem = now_ts - 60
        local endValidTime = now_ts + 60
        local steam_id = fishsteam.CheckSteamAuthSessionTicket(req.msg.login_data.authkey,
            string.len(req.msg.login_data.authkey), serverconf.STEAM_APP_KEY, serverconf.STEAM_APP_ID, begValidTimem,
            endValidTime, 0)
        return steam_id
    end
    
    local function processLogin()
        local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
        local authkey = req.msg.login_data.authkey
        if authkey and string.sub(authkey, 1, 5) == "robot" then
            moon.debug("robot login ", authkey)
        else
            local steam_id = checkSteamTicket()
            if not steam_id or steam_id <= 10 then
                context.openid_map[req.msg.login_data.authkey] = nil
                return { code = ErrorCode.ParamInvalid, error = "INVALID_USERNAME_OR_PASSWORD" }
            end
            authkey = tostring(steam_id)
        end

        local check_res, check_err = db.checkuser(context.addr_db_game, authkey)
        if check_err then
            context.openid_map[req.msg.login_data.authkey] = nil
            return { code = ErrorCode.NicknameAlreadyExist, error = "USERNAME_EXISTS" }
        end
        
        if not check_res or next(check_res) == nil then
            local create_res, create_err = db.createuser(
                context.addr_db_game,
                authkey
            )
            --
            if create_err or not create_res.insert_id then
                context.openid_map[req.msg.login_data.authkey] = nil
                return { code = ErrorCode.CreateAccountFailed, error = "CREATE_ACCOUNT_FAILED" }
            end

            req.uid = create_res.insert_id
        else
            -- 登录验证（直接比较MD5）
            local datas, err = db.getuserbyauthkey(context.addr_db_game, authkey)
            print("datas=\n" .. print_r(datas, true))
            -- 判断user_data是否为nil或空表
            if err or datas == nil or next(datas) == nil then
                context.openid_map[req.msg.login_data.authkey] = nil
                return { code = ErrorCode.PasswordError, error = "INVALID_AUTHKEY" }
            end
            local data = datas[1]

            req.uid = data.user_id
        end

        return doAuth(Auth, req)
    end

    local function func()
        if not req then
            return { code = ErrorCode.ParamInvalid, error = "INVALID_REQUEST" }
        end
        ---服务器关闭时,中断所有客户端的登录请求
        if context.server_exit and not req.pull then
            return { code = ErrorCode.ServerInternalError, error = "SERVER_CLOSED" }
        end

        req.net_id = Auth.AllocGateNetId(0)
        moon.send("lua", context.addr_gate, "Gate.BindGnId", req)

        local fd = context.openid_map[req.msg.login_data.authkey]
        if not fd then
            ---避免同一个玩家瞬间发送大量登录请求
            context.openid_map[req.msg.login_data.authkey] = req.fd
            -- local tmp = temp_openid[req.msg.login_data.authkey]
            -- if tmp then
            --     moon.error("user logining", req.fd, req.msg.login_data.authkey)
            --     return { code = 1007, error = "USER_LOGINING" }
            -- end
            -- temp_openid[req.msg.login_data.authkey] = 1
        else
            moon.error("user logining", req.fd, req.uid)
            return { code = ErrorCode.UserAlreadyLogin, error = "USER_LOGINING" }
        end

        return processLogin()
    end
    
    local res = func()
    --local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
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
    --local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
    local function processLogin()
        -- DS连接验证
        if req.msg.login_data.authkey == ""
            or req.msg.login_data.auth_ticket ~= context.conf.ds_ticket then
            return { code = ErrorCode.CityVerifyFailed, error = "验证不通过" }
        end

        req.dsid = req.msg.login_data.ds_id

        return doDSAuth(req)
    end

    local function func()
        if not req then
            return { code = ErrorCode.ParamInvalid, error = "INVALID_REQUEST" }
        end
        ---服务器关闭时,中断所有客户端的登录请求
        if context.server_exit and not req.pull then
            return { code = ErrorCode.ServerInternalError, error = "SERVER_CLOSED" }
        end

        req.net_id = Auth.AllocGateNetId(1)
        --moon.send("lua", context.addr_dgate, "DGate.BindGnId", req)

        local dsid = context.openid_map[req.msg.login_data.authkey]
        if dsid then
            moon.error("user online", req.fd, dsid)
            return { code = ErrorCode.CityAlreadyConnected, error = "USER_ONLINE" }
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
    context.S2D(req.net_id, CmdCode["PBDSLoginRspCmd"], ret, req.msg_context.stub_id)

    if res.code ~= 0 then
        --local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
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
    -- moon.error(string.format("Auth.Disconnect begin context.uid_map = %s", json.pretty_encode(context.uid_map)))
    -- moon.error(string.format("Auth.Disconnect begin context.net_id_map = %s", json.pretty_encode(context.net_id_map)))
    if u then
        QuitOneUser(u)
        --assert(moon.call("lua", u.addr_user, "User.Logout"))
        u.logouttime = moon.time()
    end
    -- moon.error(string.format("Auth.Disconnect end context.uid_map = %s", json.pretty_encode(context.uid_map)))
    -- moon.error(string.format("Auth.Disconnect end context.net_id_map = %s", json.pretty_encode(context.net_id_map)))
end

return Auth


