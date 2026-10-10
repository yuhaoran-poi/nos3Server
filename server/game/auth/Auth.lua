
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

local SERVER_PB_VERSION = CmdCode.CrC or ""

local mem_player_limit = 0 --内存中最小玩家数量
local min_online_time = 60 --seconds，logout间隔大于这个时间的,并且不在线的,user服务会被退出

---@type auth_context
local context = ...
--
local auth_queue = context.auth_queue
--local temp_openid = {}
local NODE = math.tointeger(moon.env("NODE"))

--------------------------------------------------------------------------
-- 登录重载段并发限流(轮询式排队)
-- 登录分两段: 前置校验(steam/loginuser一条流ODKU, 走
-- mysqldriver 保留连接秒回)立即执行, 失败立即返回不占队列;
-- 重载段 doAuth(User.Load ~25条SQL+RPC)排队限流, 突增时超出的立即返回
-- "排队中"+前方人数, 客户端节流重发登录请求即查询排队位置。
-- 槽位数与 db_game 业务连接数(poolsize=20)匹配: 并发20时每时刻恰好
-- 20条in-flight SQL, 再多只会互相排队空耗协程。
--------------------------------------------------------------------------
-- 槽数与db_game业务连接数的关系: LOGIN_MAX_CONCURRENT = poolsize - 在线业务余量
-- (SaveRun存档/各模块save/业务查询也消费业务池, 登录突发不能挤占否则存档POOL_EMPTY;
--  当前poolsize=30, 留10条余量给在线业务, 8节点×31连接 < MySQL max_connections=500)
--------------------------------------------------------------------------
local LOGIN_MAX_CONCURRENT = 10      -- 同时执行的登录重载段(doAuth)数上限
local LOGIN_QUEUE_LIMIT = 2000       -- 排队长度上限, 超限直接拒绝(每项约1KB, 2000项≈2MB)
local LOGIN_QUEUE_ITEM_TIMEOUT = 7200 -- 队列项存活秒数(2小时): 仅用于作废断线玩家的残留项,
                                      -- 不限制排队本身; 推送周期性下行流量可保活NAT连接
local LOGIN_QUEUE_PUSH_INTERVAL = 15 -- 排队位置推送间隔(秒)
local LOGIN_DEAD_CHECK_AFTER = 60    -- 队列项等待超过该秒数后, 出队执行前后检测连接存活,
                                     -- 死连接直接作废, 不白跑User.Load不留幽灵会话

local login_loading = 0             -- 当前正在执行的登录重载段数
local login_waitings = {}           -- FIFO: {req, authkey, pid, run, enqueue_ts}
local login_queuing_map = {}        -- map<plateform_id, true>: 去重标记(该玩家是否在队列), 队列项本体只在login_waitings

-- 登录响应(直接执行/排队异步执行/超时清理共用)
-- 排队响应(LoginQueuing)不踢线, 客户端还要靠这条连接轮询; 其余失败照旧Kick
local function login_respond(target_net_id, target_fd, target_stub_id, res)
    local ret =
    {
        code = res.code,
        error = res.error or "",
        uid = res.res and res.res.uid or 0,
        net_id = res.res and res.res.net_id or 0,
        queue_waiting = res.queue_waiting or 0,
    }
    context.S2C(target_net_id, CmdCode.PBClientLoginRspCmd, ret, target_stub_id)
    if res.code ~= ErrorCode.None and res.code ~= ErrorCode.LoginQueuing then
        moon.send("lua", context.addr_gate, "Gate.Kick", 0, target_fd) -- body
    end
end

-- 登录排队后续同步(队列位置推送/出队终态/排队超时):
-- 排队中的连接已回过Rsp(2451), 入队后的一切通知一律走SyncCmd,
-- 保证每个PBClientLoginReqCmd恰好收到一条PBClientLoginRspCmd
local function login_queue_sync(target_net_id, res)
    local ret =
    {
        uid = res.uid or 0,
        net_id = res.net_id or 0,
        queue_waiting = res.queue_waiting or 0,
        code = res.code or ErrorCode.ServerInternalError,
        error = res.error or "",
    }
    context.S2C(target_net_id, CmdCode.PBClientLoginQueueSyncCmd, ret, 0)
end

-- 查询玩家当前排队位置(1=队首)与队列项; 不在队列返回0
-- login_queuing_map仅做plateform_id去重(O(1)快速判存), 队列项定位靠pid匹配
local function login_queue_position(plateform_id)
    if not login_queuing_map[plateform_id] then
        return 0
    end
    for i, w in ipairs(login_waitings) do
        if w.pid == plateform_id then
            return i, w
        end
    end
    return 0
end

-- 调度: 用空槽逐个异步执行队首登录(前置声明, 执行核内回调驱动)
local login_dispatch
-- 用户会话清理函数(前置声明, 定义在下方; 出队后检测到死连接时在dispatch协程内使用)
local QuitOneUser

-- 登录重载段执行核(调用前必须已占槽): 执行doAuth→释放槽→驱动队列,
-- 返回终态res(直接路径由外层发Rsp, 排队出队路径发Sync)
local function login_execute_inslot(run, authkey)
    local ok, res = pcall(run)
    login_loading = login_loading - 1
    -- 先驱动队列再发终态通知: 即使通知环节出错, 槽位补位链也不会断
    login_dispatch()
    if ok then
        return res
    end
    -- 原本会传播到xpcall兜底; 这里本地兜底并顺带清理openid_map, 不影响该玩家重试
    moon.error(string.format("login doAuth error: authkey=%s err=%s", tostring(authkey), tostring(res)))
    context.openid_map[authkey] = nil
    return { code = ErrorCode.ServerInternalError, error = "LOGIN_INTERNAL_ERROR" }
end

login_dispatch = function()
    while login_loading < LOGIN_MAX_CONCURRENT and #login_waitings > 0 do
        local wait = table.remove(login_waitings, 1)
        -- 键为plateform_id(稳定标识), authkey仅存队列项内用于openid_map的配对清理
        login_queuing_map[wait.pid] = nil
        -- 同步占槽后再启动协程: while的计数判断不依赖moon.async的调度语义
        login_loading = login_loading + 1
        moon.async(function()
            -- 执行前活性检测(仅长等待项): 排队中断开的玩家视同超时作废,
            -- 不白跑User.Load、不留幽灵会话; 检测在协程内yield,
            -- 不影响dispatch的while循环对loading的同步判断
            if moon.time() - wait.enqueue_ts > LOGIN_DEAD_CHECK_AFTER then
                local alive = moon.call("lua", context.addr_gate, "Gate.CheckFdAlive", wait.fd)
                if not alive then
                    login_loading = login_loading - 1
                    context.openid_map[wait.authkey] = nil
                    moon.warn(string.format("login queue item dead before exec, uid=%s pid=%s waited=%ds",
                        tostring(wait.uid), tostring(wait.pid), moon.time() - wait.enqueue_ts))
                    login_dispatch() -- 补位下一个
                    return
                end
            end
            local res = login_execute_inslot(wait.run, wait.authkey)
            -- 执行后活性检测: doAuth成功但连接已死则立即清理本次登录产生的会话
            -- (user服务/uid_map/usermgr注册), 不等60秒定时清理, 该玩家可立刻重登
            if res.code == ErrorCode.None then
                local alive = moon.call("lua", context.addr_gate, "Gate.CheckFdAlive", wait.fd)
                if not alive then
                    local u = context.uid_map[wait.uid]
                    if u then
                        QuitOneUser(u) -- User.Exit(user服务自会保存+usermgr注销) + 清uid_map/net_id_map
                    end
                    context.openid_map[wait.authkey] = nil
                    moon.warn(string.format("login dead after exec, cleanup session uid=%s", tostring(wait.uid)))
                    return
                end
            end
            -- 出队终态属于"入队后的后续通知", 走Sync(该Req的Rsp已由入队响应消耗);
            -- doAuth返回结构为{code,error,res={uid,net_id}}, 此处转平铺
            login_queue_sync(wait.net_id, {
                uid = res.res and res.res.uid or 0,
                net_id = res.res and res.res.net_id or 0,
                code = res.code or 0,
                error = res.error or "",
            })
            -- 终态失败踢线, 成功保持连接进入游戏
            if res.code ~= ErrorCode.None then
                moon.send("lua", context.addr_gate, "Gate.Kick", 0, wait.fd)
            end
        end)
    end
end

-- 直接执行路径(未入队, processLogin协程内同步执行):
-- 占槽→执行核→返回res由外层login_respond发Rsp
local function login_execute(run, authkey)
    login_loading = login_loading + 1
    return login_execute_inslot(run, authkey)
end

-- 定时清理超时队列项(玩家排队中断线且重发未命中时, 防陈旧项堆积占满队列)
moon.async(function()
    while true do
        moon.sleep(10 * 1000)
        local now_ts = moon.time()
        while #login_waitings > 0 do
            local wait = login_waitings[1]
            if now_ts - wait.enqueue_ts <= LOGIN_QUEUE_ITEM_TIMEOUT then
                break
            end
            table.remove(login_waitings, 1)
            -- 键为plateform_id(稳定标识), authkey仅用于openid_map的配对清理
            login_queuing_map[wait.pid] = nil
            context.openid_map[wait.authkey] = nil
            -- 排队超时属于"入队后的后续通知", 走Sync + 踢线
            login_queue_sync(wait.net_id, {
                uid = wait.uid,
                net_id = wait.net_id,
                code = ErrorCode.ServerBusy,
                error = "LOGIN_QUEUE_TIMEOUT",
            })
            moon.send("lua", context.addr_gate, "Gate.Kick", 0, wait.fd)
        end
    end
end)

-- 统一定时推送排队位置(单协程, 不随入队数增长):
-- gate对登录中连接(BindGnId后BindUser前)的上行消息会被redirect到nil,
-- 客户端同连接轮询到不了auth, 由服务端周期性推送2451+当前位置,
-- 下行走gate的net_id_map->fd不受影响; 出队/超时的队列项不在遍历
-- 范围内, 自然不再收到推送
moon.async(function()
    while true do
        moon.sleep(LOGIN_QUEUE_PUSH_INTERVAL * 1000)
        -- 先快照再推送, 避免推送过程中队列被并发修改
        -- local pushes = {}
        for i, wait in ipairs(login_waitings) do
            -- pushes[#pushes + 1] = { req = wait.req, pos = i }
            login_queue_sync(wait.net_id, {
                uid = wait.uid,
                net_id = wait.net_id,
                queue_waiting = i,
                code = ErrorCode.LoginQueuing,
                error = "",
            })
        end
    end
end)

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
            moon.error("DsNode.Load failed! net_id = , fd = , error = ", req.net_id, req.fd, err)
            -- moon.send("lua", context.addr_dgate, "DGate.Kick", 0, req.fd)
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
        moon.error("DsNode.Login failed! net_id = , fd = , error = ", req.net_id, req.fd, err)
        -- moon.send("lua", context.addr_dgate, "DGate.Kick", 0, req.fd)
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

        context.dsid_map[req.dsid] = u
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

local function doAuth(req, plateform_id)
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
        req.plateform_id = plateform_id

        local ok, err = moon.call("lua", addr_user, "User.Load", req)
        if not ok then
            moon.error(string.format("doAuth User.Load err = %s", json.pretty_encode(err)))
            -- User.Load 开头已向 usermgr 注册过 ApplyLogin, 杀服务前必须注销:
            -- 否则 user_node[uid] 残留, 该玩家后续登录会被 "user already login" 拒绝
            clusterd.send(3999, "usermgr", "Usermgr.NotifyLogout", { uid = req.uid, nid = NODE })
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
        moon.warn(string.format("doAuth player online uid = %d context.uid_map = %s", req.uid, json.pretty_encode(context.uid_map)))
        return { code = 2005, error = "player online" }
    end

    local authkey, err = moon.call("lua", addr_user, "User.Login", req)
    --
    if not authkey then
        print(authkey, err)
        --moon.send("lua", context.addr_gate, "Gate.Kick", 0, req.fd)
        -- 同上: ApplyLogin 注册残留清理
        clusterd.send(3999, "usermgr", "Usermgr.NotifyLogout", { uid = req.uid, nid = NODE })
        moon.kill(addr_user)
        context.uid_map[req.uid] = nil
        context.openid_map[req.msg.login_data.authkey] = nil
        return { code = 2003, error = err }
    end

    u = {
        addr_user = addr_user,
        authkey = plateform_id,
        openid = "",
        uid = req.uid,
        logouttime = moon.time(),
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
    
    -- 初始化检查数据
    moon.send("lua", addr_user, "User.InitCheckData")

    context.openid_map[req.msg.login_data.authkey] = nil
    local res = {
        result = 0, --maybe banned
        net_id = u.net_id,
        uid = u.uid,
    }
    return { code = 0, error = "sucess", res = res }
end

QuitOneUser = function(u)
    moon.send("lua", u.addr_user, "User.Exit")
    -- 条件删除: 同uid可能有新会话已覆盖注册(出队执行中的旧doAuth清理时,
    -- 重连的新doAuth可能刚写入uid_map; 顶号/断线清理同理), 按key盲删会
    -- 误杀新会话导致其"假在线"(收code=0但S2C按uid_map路由全部丢失)
    if context.uid_map[u.uid] == u then
        context.uid_map[u.uid] = nil
    end
    if context.net_id_map[u.net_id] == u then
        context.net_id_map[u.net_id] = nil
    end
    moon.error(string.format("QuitOneUser net_id = %d", u.net_id))
end

local function QuitOneDs(ds)
    moon.send("lua", ds.addr_dsnode, "DsNode.Exit")
    -- dsid_map 是单槽位(dsid=房间号), 可能已被同一 dsid 的更新登录覆盖,
    -- 仅当槽位仍指向本记录时才清除, 避免误删当前连接在 dsid_map 上的注册
    if context.dsid_map[ds.dsid] == ds then
        context.dsid_map[ds.dsid] = nil
    end
    context.net_id_map[ds.net_id] = nil
    moon.error(string.format("QuitOneDs net_id = %d", ds.net_id))
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
            if count > mem_player_limit then
                -- 先收集待清理的 uid，遍历结束后再统一 QuitOneUser，
                -- 避免在 pairs 遍历 uid_map 的同时就地删除条目（QuitOneUser 内部清 uid_map）。
                local to_quit = {}
                for uid, u in pairs(context.uid_map) do
                    if u.logouttime > 0 and (now - u.logouttime) > min_online_time then
                        table.insert(to_quit, uid)
                    end
                end
                for _, uid in ipairs(to_quit) do
                    local u = context.uid_map[uid]
                    if u then
                        QuitOneUser(u)
                    end
                end
            end
        end
    end)

    context.start_hour_timer()

    context.addr_db_game = moon.queryservice("db_game")

    local ok, err = moon.call("lua", context.addr_db_game, [[
        CREATE TABLE IF NOT EXISTS account (
            user_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
            authkey VARCHAR(64) NOT NULL,
            username VARCHAR(64) NOT NULL,
            password_hash CHAR(32) NOT NULL DEFAULT '',
            ban_end_ts BIGINT NOT NULL DEFAULT 0,
            create_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            last_login TIMESTAMP NULL,
            PRIMARY KEY (user_id),
            UNIQUE INDEX uk_authkey (authkey)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])
    -- 注意: mysqldriver失败时返回的是badresult表(truthy)而非nil,
    -- 不能用assert(ok)判断, 必须检查badresult标记
    if not ok or ok.badresult then
        error("Failed to create account table: " .. tostring(ok and ok.message or err))
    end

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
        -- local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
        local plateform_id = req.msg.login_data.authkey
        if plateform_id and string.sub(plateform_id, 1, 5) == "robot" then
            moon.debug("robot login ", plateform_id)
        else
            local steam_id = checkSteamTicket()
            if not steam_id or steam_id <= 10 then
                context.openid_map[req.msg.login_data.authkey] = nil
                return { code = ErrorCode.ParamInvalid, error = "INVALID_USERNAME_OR_PASSWORD" }
            end
            plateform_id = tostring(steam_id)
        end

        -- 排队查询(重发登录/断线重连): plateform_id是稳定标识(robot原串/
        -- steam校验后的steam_id), 同一玩家换新ticket也能命中;
        -- 命中即返回位置, 不再做checkuser等前置查询, 并清当前请求占位
        local queue_pos, queue_wait = login_queue_position(plateform_id)
        if queue_pos > 0 then
            -- 队列项跟随新连接: 后续Sync推送与终态/Kick走新连接;
            -- 并原地更新被run_doauth闭包捕获的旧req对象的连接字段
            -- (net_id/fd/sign/msg_context), 否则出队doAuth仍按首连身份
            -- 做BindUser等绑定, 重连玩家的会话会绑到已断开的旧连接
            if queue_wait then
                queue_wait.net_id = req.net_id
                queue_wait.fd = req.fd
                if queue_wait.req then
                    -- 原地复写旧req的字段而非替换引用: run_doauth闭包的upvalue
                    -- 固定指向入队时的req表, 替换wait.req字段对闭包不可见;
                    -- sign/msg_context必须一并跟随, 否则出队doAuth的Gate.BindUser
                    -- 用旧sign校验新fd必失败——服务端在线但gate未绑定, 玩家假在线
                    queue_wait.req.net_id = req.net_id
                    queue_wait.req.fd = req.fd
                    queue_wait.req.sign = req.sign
                    queue_wait.req.msg_context = req.msg_context
                end
            end

            context.openid_map[req.msg.login_data.authkey] = nil
            return { code = ErrorCode.LoginQueuing, error = "LOGIN_QUEUING", queue_waiting = queue_pos }
        end

        -- 取号/建号一条流: 老号NOT EXISTS不满足→INSERT 0行(零自增消耗,不跳号);
        -- 新号插入拿自增uid; 并发首登竞态由ODKU兜底带回原uid;
        -- 新老号统一从语句2行集取uid(老号OK包insert_id为0)
        local login_res = db.loginuser(context.addr_db_game, plateform_id)
        local okp = (login_res and login_res.multiresultset) and login_res[1] or login_res
        local rows = (login_res and login_res.multiresultset) and login_res[2] or nil
        if not okp or okp.badresult or not rows or not rows[1] or not rows[1].user_id then
            context.openid_map[req.msg.login_data.authkey] = nil
            return { code = ErrorCode.CreateAccountFailed, error = "CREATE_ACCOUNT_FAILED" }
        end

        -- 老号封禁检查(新号行刚插入, ban_end_ts默认0, 直接跳过)
        if rows[1].ban_end_ts and rows[1].ban_end_ts > moon.time() then
            context.openid_map[req.msg.login_data.authkey] = nil
            return { code = ErrorCode.AccountBanned, error = "ACCOUNT_BANNED" }
        end

        req.uid = rows[1].user_id

        -- 登录重载段并发限流: 前置校验(走保留连接)已完成, req.uid已确定,
        -- 仅对 doAuth(User.Load ~25条SQL+RPC)排队。
        -- 注意必须包装成函数延迟执行: 入队路径在出队后才调用,
        -- 直接执行路径在login_execute占槽后才调用, 二者都依赖闭包
        local function run_doauth()
            return doAuth(req, plateform_id)
        end
        local authkey = req.msg.login_data.authkey
        if login_loading >= LOGIN_MAX_CONCURRENT then
            if #login_waitings >= LOGIN_QUEUE_LIMIT then
                context.openid_map[authkey] = nil
                return { code = ErrorCode.ServerBusy, error = "SERVER_BUSY" }
            end
            local wait = {
                req = req,              -- 入队请求对象: 重连时原地更新其连接字段(run闭包共享此表)
                uid = req.uid,
                net_id = req.net_id,
                fd = req.fd,
                authkey = authkey,     -- 入队请求的ticket: 超时/出队时清openid_map用
                pid = plateform_id,    -- 稳定标识: 新ticket重发时查位置用
                enqueue_ts = moon.time(),
                run = run_doauth,
            }
            table.insert(login_waitings, wait)
            login_queuing_map[plateform_id] = true -- 仅做去重标记, 队列项本体在login_waitings
            return { code = ErrorCode.LoginQueuing, error = "LOGIN_QUEUING", queue_waiting = #login_waitings }
        end

        return login_execute(run_doauth, authkey)
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

        if serverconf.CLIENT_VERSION ~= "" and req.msg.login_data.version ~= serverconf.CLIENT_VERSION then
            moon.error("client version mismatch: client=", req.msg.login_data.version, " server=",
                serverconf.CLIENT_VERSION)
            return { code = ErrorCode.ProtoError, error = "CLIENT_VERSION_MISMATCH" }
        end
        
        if SERVER_PB_VERSION ~= "" and req.msg.login_data.pb_version ~= SERVER_PB_VERSION then
            moon.error("PB version mismatch: client=", req.msg.login_data.pb_version, " server=", SERVER_PB_VERSION)
            return { code = ErrorCode.ProtoError, error = "PB_VERSION_MISMATCH" }
        end

        local fd = context.openid_map[req.msg.login_data.authkey]
        if not fd then
            ---避免同一个玩家瞬间发送大量登录请求
            context.openid_map[req.msg.login_data.authkey] = req.fd
        else
            -- 占位连接已断开: 登录中途断开(排队等待/加载中)的陈旧占位残留,
            -- gate的close事件此时无uid可通知auth清理; 同ticket重连(ticket
            -- 有效期内不变)被残留占位拦截会反复USER_LOGINING直到队列项出队。
            -- 检测占位fd存活, 死亡则覆盖占位放行
            local alive = moon.call("lua", context.addr_gate, "Gate.CheckFdAlive", fd)
            if not alive then
                context.openid_map[req.msg.login_data.authkey] = req.fd
            else
                moon.error("user logining", req.fd, req.uid)
                return { code = ErrorCode.UserAlreadyLogin, error = "USER_LOGINING" }
            end
        end

        return processLogin()
    end

    local res = func()
    login_respond(req.net_id, req.fd, req.msg_context.stub_id, res)
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
        moon.send("lua", context.addr_dgate, "DGate.BindGnId", req)

        if serverconf.CLIENT_VERSION ~= "" and req.msg.login_data.version ~= serverconf.CLIENT_VERSION then
            moon.error("client version mismatch: client=", req.msg.login_data.version, " server=",
                serverconf.CLIENT_VERSION)
            return { code = ErrorCode.ProtoError, error = "CLIENT_VERSION_MISMATCH" }
        end
        
        if SERVER_PB_VERSION ~= "" and req.msg.login_data.pb_version ~= SERVER_PB_VERSION then
            moon.error("PB version mismatch: client=", req.msg.login_data.pb_version, " server=", SERVER_PB_VERSION)
            return { code = ErrorCode.ProtoError, error = "PB_VERSION_MISMATCH" }
        end

        local dsid = context.openid_map[req.msg.login_data.authkey]
        if dsid then
            moon.error("ds online", req.fd, dsid)
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
    moon.warn(string.format("PBDSLoginRspCmd req.net_id:\n%d", req.net_id))
    moon.warn(string.format("PBDSLoginRspCmd ret:\n%s", json.pretty_encode(ret)))
    moon.warn(string.format("PBDSLoginRspCmd req.msg_context.stub_id:\n%d", req.msg_context.stub_id))
    -- local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
    context.S2D(req.net_id, CmdCode["PBDSLoginRspCmd"], ret, req.msg_context.stub_id)

    if res.code ~= 0 then
        --local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
        moon.error("PBDSLoginReqCmd failed! res.code = , error = ", res.code, res.error)
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
    moon.send("lua", u.addr_user, cmd, ...)
end

function Auth.BindGateSuccess(uid)
    if context.uid_map[uid] then
        context.uid_map[uid].logouttime = 0
    end
end

function Auth.Disconnect(uid)
    local u = context.uid_map[uid]
    -- moon.error(string.format("Auth.Disconnect begin context.uid_map = %s", json.pretty_encode(context.uid_map)))
    -- moon.error(string.format("Auth.Disconnect begin context.net_id_map = %s", json.pretty_encode(context.net_id_map)))
    if u then
        u.logouttime = moon.time()
        QuitOneUser(u)
        --assert(moon.call("lua", u.addr_user, "User.Logout"))
    end
    -- moon.error(string.format("Auth.Disconnect end context.uid_map = %s", json.pretty_encode(context.uid_map)))
    -- moon.error(string.format("Auth.Disconnect end context.net_id_map = %s", json.pretty_encode(context.net_id_map)))
end

function Auth.DsDisconnect(net_id)
    -- 必须按 net_id(具体哪条连接断开)定位记录。
    -- 不能按 dsid 查 dsid_map: 它是单槽位, 永远指向该房间"最新一次登录"的记录,
    -- 同一房间旧连接(如上一局 DS 在新局 DS 登录后才退出)的关闭会错杀当前局的
    -- dsnode, 触发 DsNode.Exit 补发把进行中的新一局拉回房间态
    local ds = context.net_id_map[net_id]
    if ds then
        QuitOneDs(ds)
    end
end

return Auth