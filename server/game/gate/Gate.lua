local moon = require("moon")
local socket = require("moon.socket")
local common = require("common")
local CmdCode = common.CmdCode
---@type gate_context
local context = ...

local listenfd

---@class Gate
local Gate = {}

function Gate.Init()
    return true
end

function Gate.Start()
    ---开始接收客户端网络链接
    listenfd  = socket.listen(context.conf.host, context.conf.port, moon.PTYPE_SOCKET_MOON)
    assert(listenfd>0,"server listen failed")
    socket.start(listenfd)
    print("GAME Server Start Listen",context.conf.host, context.conf.port)
    return true
end

function Gate.Shutdown()
    for _, c in pairs(context.uid_map) do
        socket.close(c.fd)
    end
    if listenfd then
        socket.close(listenfd)
    end
    moon.quit()
    return true
end

function Gate.Kick(uid, fd, ignore_socket_event)
    print("gate kick", uid, fd, ignore_socket_event)
    if uid and uid >0 then
        local c = context.uid_map[uid]
        if c then
            socket.close(c.fd)

            -- -- 发送消息通知所在的ds
            -- local DisconnectGateCmd = {
            --     srcGnId = c.net_id
            -- }
            -- if c.ds_net_id then
            --     context.S2D(c.ds_net_id, CmdCode["dsgatepb.DisconnectGateCmd"], DisconnectGateCmd, 0)
            -- end
            -- if c.fd then
            --     context.fd_map[c.fd] = nil
            -- end
            -- if c.uid then
            --     context.uid_map[c.uid] = nil -- body
            -- end
            -- if c.net_id then
            --     context.net_id_map[c.net_id] = nil
            -- end
        end

        if ignore_socket_event then
            context.fd_map[c.fd] = nil
            context.uid_map[uid] = nil
            context.net_id_map[c.net_id] = nil
            moon.error(string.format("Gate.Kick net_id = %d", c.net_id))
        end
    end

    if fd and fd>0 then
        socket.close(fd)
    end
    return true
end

function Gate.BindUser(req)
    if context.auth_watch[req.fd] ~= req.sign then
        return false, "client closed before auth done!"
    end
    local old = context.uid_map[req.uid]
    if old and old.fd ~= req.fd then
        context.fd_map[old.fd] = nil
        socket.close(old.fd)
        print("kick user", req.uid, "oldfd", old.fd, "newfd", req.fd)
    end

    local c = {
        uid = req.uid,
        fd = req.fd,
        net_id = req.net_id,
        addr_user = req.addr_user
    }

    context.fd_map[req.fd] = c
    context.uid_map[req.uid] = c
    context.net_id_map[req.net_id] = c
    -- moon.warn(string.format("Gate.BindUser net_id = %d, c.net_id = %d", req.net_id, c.net_id))
    context.auth_watch[req.fd] = nil
    moon.info(string.format("BindUser fd:%d uid:%d net_id:%d serviceid:%08X", req.fd, req.uid, req.net_id, req.addr_user))
    return true
end

function Gate.BindGnId(req)
    local c = {
        fd = req.fd,
        net_id = req.net_id
    }
    context.fd_map[req.fd] = c
    context.net_id_map[req.net_id] = c
    moon.warn(string.format("BindGnId fd:%d net_id:%d ", req.fd, req.net_id))
    return true
end
function Gate.ForwardD2C(GnId, MessagePack)
    context.D2C(GnId, MessagePack)
end
-- 发送系统消息到本gate所有玩家
function Gate.BroadcastSysChat(channel_msgs)
    moon.info("BroadcastSysChat channel_msgs = ", channel_msgs)
    for net_id, _ in pairs(context.net_id_map) do
        local msg = { infos = {} }
        for _, v in ipairs(channel_msgs) do
            table.insert(msg.infos, v)
        end
        context.S2C(net_id, CmdCode.PBChatSynCmd, msg, 0)
    end
    return true
end

function Gate.SendSystemMail(mail_info)
    moon.info("SendSystemMail mail_info = ", mail_info.simple_data.mail_id)

    for _, c in pairs(context.uid_map) do
        if c and c.addr_user then
            moon.send("lua", c.addr_user, "Mail.RecvSystemMail", mail_info)
        end
    end
    return true
end

function Gate.InvalidSystemMail(mail_id)
    moon.info("InvalidSystemMail mail_id = ", mail_id)

    for _, c in pairs(context.uid_map) do
        if c and c.addr_user then
            moon.send("lua", c.addr_user, "Mail.InvalidSystemMail", mail_id)
        end
    end
    return true
end

return Gate