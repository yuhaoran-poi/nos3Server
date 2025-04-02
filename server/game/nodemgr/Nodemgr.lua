local moon = require("moon")
local socket = require("moon.socket")
local common = require("common")
local CmdCode = common.CmdCode
local GameCfg = common.GameCfg --游戏配置
---@type nodemgr_context
local context = ...

local listenfd

---@class Nodemgr
local Nodemgr = {}

function Nodemgr.Init()
    return 123
end

function Nodemgr.Start()
    ---开始接收客户端网络链接
    -- listenfd  = socket.listen(context.conf.host, context.conf.port, moon.PTYPE_SOCKET_MOON)
    -- assert(listenfd>0,"server listen failed")
    -- socket.start(listenfd)
    -- print("GAME Server Start Listen",context.conf.host, context.conf.port)
    return true
end

function Nodemgr.Shutdown()
    for _, n in pairs(context.node_map) do
        socket.close(n.fd)
    end
    if listenfd then
        socket.close(listenfd)
    end
    moon.quit()
    return true
end

function Nodemgr.BindNode(msg)
    local ret = LuaPanda and LuaPanda.BP and LuaPanda.BP()
    local old = context.node_map[msg.nid]
    if old then
        return {error = "node already bind"}
    end

    local n = {
        nid = msg.nid,
        chost = msg.chost,
        cport = msg.cport,
    }

    context.node_map[msg.nid] = n
    print(string.format("BindNode nid:%d", msg.nid))

    --通知mgr上的其他服务，有新的节点上线
    moon.send("lua", context.addr_usermgr, "Usermgr.NodeOnline", n)
    
    return {error = "success"}
end

-- function Nodemgr.BindGnId(req)
--     local n = {
--         fd = req.fd,
--         net_id = req.net_id
--     }
--     context.fd_map[req.fd] = n
--     print(string.format("BindGnId fd:%d net_id:%d ", req.fd, req.net_id))
--     return true
-- end

return Nodemgr