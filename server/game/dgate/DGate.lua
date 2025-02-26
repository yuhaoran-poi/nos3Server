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
    print("DGate GAME Server Start Listen",context.conf.host, context.conf.port)
    return true
end

function DGate.Shutdown()
    for _, c in pairs(context.gnid_map) do
        socket.close(c.fd)
    end
    if listenfd then
        socket.close(listenfd)
    end
    moon.quit()
    return true
end

function DGate.Kick(gnid, fd, ignore_socket_event)
    print("gate kick", gnid, fd, ignore_socket_event)
    if gnid and gnid >0 then
        local c = context.gnid_map[gnid]
        if c then
            socket.close(c.fd)
        end
        if ignore_socket_event then
            context.fd_map[c.fd] = nil
            context.gnid_map[gnid] = nil
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
    local old = context.gnid_map[req.gnid]
    if old and old.fd ~= req.fd then
        context.fd_map[old.fd] = nil
        socket.close(old.fd)
        print("kick dsnode", req.gnid, "oldfd", old.fd, "newfd", req.fd)
    end

    local c = {
        gnid = req.gnid,
        fd = req.fd,
        addr_dsnode = req.addr_dsnode
    }

    context.fd_map[req.fd] = c
    context.gnid_map[req.gnid] = c
    context.auth_watch[req.fd] = nil
    print(string.format("BindDS fd:%d gnid:%d serviceid:%08X", req.fd, req.gnid,  req.addr_dsnode))
    --向集群记录gnid-node

    return true
end

function DGate.ForwardC2D(GnId,MessagePack)
    context.C2D(GnId,MessagePack)
end
function DGate.ForwardD2D(GnId,MessagePack)
    context.D2D(GnId,MessagePack)
end
return DGate