local moon = require("moon")
local socket = require("moon.socket")
--- send message to target node
--local cluster = require("cluster")

---@type gate_context
local context = ...

local listenfd

---@class DGate
local DGate = {}

function DGate.Init()
    return true
end

function DGate.Start()
    ---开始接收客户端网络链接
    listenfd  = socket.listen(context.conf.host, context.conf.port, moon.PTYPE_SOCKET_MOON)
    assert(listenfd>0,"DGate server listen failed")
    socket.start(listenfd)
    print("DGate GAME Server Start Listen", context.conf.host, context.conf.port)
    
    -- 新增定时器轮询
    -- moon.async(function()
    --     while true do
    --         moon.sleep(30000) -- 每30秒检查一次
    --         -- 遍历所有用户
    --         local now_ts = moon.time()
    --         for _, c in pairs(context.dsid_map) do
    --             -- 60秒超时
    --             -- if now_ts - c.last_ping_time > 60 and c.dsid > 10000 then
    --             if now_ts - c.last_ping_time > 60 then
    --                 moon.warn("user", c.dsid, "ping timeout")
    --                 socket.close(c.fd)
    --             end
    --         end
    --     end
    -- end)

    return true
end

function DGate.Shutdown()
    for _, c in pairs(context.net_id_map) do
        socket.close(c.fd)
    end
    if listenfd then
        socket.close(listenfd)
    end
    moon.quit()
    return true
end

function DGate.Kick(net_id, fd, ignore_socket_event)
    print("gate kick", net_id, fd, ignore_socket_event)
    if net_id and net_id >0 then
        local c = context.net_id_map[net_id]
        if c then
            socket.close(c.fd)
        end
        if ignore_socket_event then
            context.fd_map[c.fd] = nil
            context.net_id_map[net_id] = nil
        end
    end

    if fd and fd>0 then
        socket.close(fd)
    end
    return true
end

function DGate.BindDS(req)
    if context.auth_watch[req.fd] ~= req.sign then
        return false, "client closed before auth done!"
    end
    local old = context.net_id_map[req.net_id]
    if old and old.fd ~= req.fd then
        context.fd_map[old.fd] = nil
        socket.close(old.fd)
        print("kick dsnode", req.net_id, "oldfd", old.fd, "newfd", req.fd)
    end

    local c = {
        dsid = req.dsid,
        net_id = req.net_id,
        fd = req.fd,
        addr_dsnode = req.addr_dsnode,
        last_ping_time = moon.time(),
    }

    context.fd_map[req.fd] = c
    context.dsid_map[req.dsid] = c
    context.net_id_map[req.net_id] = c
    context.auth_watch[req.fd] = nil
    print(string.format("BindDS fd:%d net_id:%d serviceid:%08X", req.fd, req.net_id,  req.addr_dsnode))
    --向集群记录net_id-node

    return true
end

function DGate.ForwardC2D(GnId,MessagePack)
    context.C2D(GnId,MessagePack)
end
function DGate.ForwardD2D(GnId,MessagePack)
    context.D2D(GnId,MessagePack)
end
return DGate