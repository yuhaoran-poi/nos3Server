local moon = require("moon")
local socket = require("moon.socket")
local common = require("common")
local CmdCode = common.CmdCode
local GameCfg = common.GameCfg --游戏配置
---@type usermgr_context
local context = ...

local listenfd

---@class Usermgr
local Usermgr = {}

function Usermgr.Init()
    return 123
end

function Usermgr.Start()
    ---开始接收客户端网络链接
    -- listenfd  = socket.listen(context.conf.host, context.conf.port, moon.PTYPE_SOCKET_MOON)
    -- assert(listenfd>0,"server listen failed")
    -- socket.start(listenfd)
    -- print("GAME Server Start Listen",context.conf.host, context.conf.port)
    return true
end

function Usermgr.Shutdown()
    for _, n in pairs(context.node_map) do
        socket.close(n.fd)
    end
    if listenfd then
        socket.close(listenfd)
    end
    moon.quit()
    return true
end

function Usermgr.NodeOnline(msg)
    local n = {
        nid = msg.nid,
        -- chost = msg.chost,
        -- cport = msg.cport,
        user_num = 0,
    }
    context.node_info[msg.nid] = n

    print(string.format("Usermgr.NodeOnline nid:%d", msg.nid))
end

function Usermgr.NodeOffline(msg)
    local removed_users = {}  -- 新增：记录被移除的用户ID
    
    -- 修改循环逻辑，收集需要删除的用户ID
    for uid, nid in pairs(context.user_node) do
        if nid == msg.nid then
            table.insert(removed_users, uid)
        end
    end
    
    -- 批量删除用户节点映射
    for _, uid in ipairs(removed_users) do
        context.user_node[uid] = nil
    end
    
    -- 移除节点信息并打印日志
    context.node_info[msg.nid] = nil
    print(string.format("Usermgr.NodeOffline nid:%d, removed %d users", msg.nid, #removed_users))
end

function Usermgr.ApplyLogin(msg)
    --local ret = LuaPanda and LuaPanda.BP and LuaPanda.BP()
    if not context.node_info[msg.nid] then
        return { error = "not node" }
    end

    local old = context.user_node[msg.uid]
    if old and old ~= msg.nid then
        local res = {
            nid = old.nid,
            addr_user = old.addr_user,
        }

        -- local now_node = context.node_info[old]
        -- if now_node then
        --     res.chost = now_node.host
        --     res.cport = now_node.port
        -- end

        return { error = "user already login", res }
    end

    context.user_node[msg.uid] = {nid = msg.nid, addr_user = msg.addr_user}
    if not old then
        context.node_info[msg.nid].user_num = context.node_info[msg.nid].user_num + 1
    end

    print(string.format("ApplyLogin uid:%d nid:%d", msg.uid, msg.nid))
    return { error = "success" }
end

function Usermgr.NotifyLogout(msg)
    local old = context.user_node[msg.uid]
    if not old or old ~= msg.nid then
        return
    end

    if context.node_info[msg.nid] then
        context.node_info[msg.nid].user_num = context.node_info[msg.nid].user_num - 1
    end
    context.user_node[msg.uid] = nil
end

--- 获取用户user_addr
---@param uid number 用户ID
---@return number node_id   用户所在节点ID
function Usermgr.getAddrUserByUid(uid)
    return context.user_node[uid]
end

--- 获取在线用户列表
---@param _uids table 用户ID列表，格式为 {uid1, uid2, ...}
---@return table 在线用户列表，格式为 {uid1 = {node_id1,addr_user1}, uid2 = {node_id2,addr_user2}, ...}
function Usermgr.getOnlineUsers(_uids)
    local online_users = {}
    for uid in pairs(_uids or {}) do
        local info = context.user_node[uid]
        if info then
            online_users[uid] = { info.nid, info.addr_user }
        end
    end
    return online_users
end

--- 获取不在线用户列表
---@param _uids table 用户ID列表，格式为 {uid1, uid2,...}
---@return table 不在线用户列表，格式为 {uid1, uid2,...}
function Usermgr.getOfflineUsers(_uids)
    local offline_users = {}
    for uid in pairs(_uids or {}) do
        local info = context.user_node[uid]
        if not info then
            table.insert(offline_users, uid)
        end
    end
    return offline_users
end

 

return Usermgr