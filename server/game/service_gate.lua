--require("common.LuaPanda").start("127.0.0.1", 8818)

local moon = require("moon")
local seri = require("seri")
local socket = require("moon.socket")
local common = require("common")
local setup = require("common.setup")
local buffer = require("buffer")
local protocol = common.protocol
local GameDef = common.GameDef
local CmdCode = common.CmdCode
local wfront = buffer.write_front
local conf = ...

local redirect = moon.redirect

local PTYPE_C2S = GameDef.PTYPE_C2S

---@class gate_context:base_context
---@field scripts gate_scripts
local context = {
    conf = conf,
    uid_map = {},
    fd_map = {},
    net_id_map = {},  --直连到本Gate的所有客户端
    auth_watch = {},
}

setup(context)

socket.on("accept", function(fd, msg)
    print("client: accept ", fd, moon.decode(msg, "Z"))
    socket.set_enable_chunked(fd, "w")
    --socket.settimeout(fd, 60)
end)

socket.on("message", function(fd, msg)
    local c = context.fd_map[fd]
    if not c then
        ---first message must be auth message
        context.auth_watch[fd] = tostring(msg)
        local name, req = protocol.decode(moon.decode(msg,"B"))
        for key, MessagePack in ipairs(req.messages) do
            local reqmsg = {}
            reqmsg.msg_context = {
                net_id = MessagePack.net_id,
                broadcast = MessagePack.broadcast,
                stub_id =    MessagePack.stub_id,
                msg_type =   MessagePack.msg_type
              }
           local subname,submsg = protocol.DecodeMessagePack(MessagePack)
            --先校验协议版本号
            if subname == "PBClientLoginReqCmd" then
               reqmsg.msg = submsg
               reqmsg.sign = context.auth_watch[fd]
               reqmsg.fd = fd
               reqmsg.addr = socket.getaddress(fd)
               reqmsg.pull = false
               reqmsg.isDS = false
               moon.send("lua", context.addr_auth, subname, reqmsg)
            else
                print("client: message", fd, subname, submsg)
            end
        end
    else
        if moon.DEBUG() then
            local buf = moon.decode(msg, "B")
            protocol.print_message(c.net_id, buf,"message",1)
        end
        -- local name, req = protocol.decode(moon.decode(msg,"B"))
        -- for key, MessagePack in ipairs(req.messages) do
        --     -- 外围服务器处理
        --     redirect(MessagePack, c.addr_user, GameDef.PTYPE_C2S, 0, 0)
        -- end
        --wfront(msg, seri.packs(c.net_id))
        redirect(msg, c.addr_user, GameDef.PTYPE_C2S, 0, 0)
    end
end)

socket.on("close", function(fd, msg)
    local data = moon.decode(msg, "Z")
    context.auth_watch[fd] = nil
    local c = context.fd_map[fd]
    if not c then
        print("client: close", fd, data)
        return
    end
     -- 发送消息通知所在的ds
    local DisconnectGateCmd = {
        srcGnId = c.net_id
    }
    if c.ds_net_id then
        context.S2D(c.ds_net_id, CmdCode["dsgatepb.DisconnectGateCmd"], DisconnectGateCmd, 0)
    end
    context.fd_map[fd] = nil
    if c.uid then
        context.uid_map[c.uid] = nil -- body
    end
    if c.net_id then
        context.net_id_map[c.net_id] = nil
    end
    moon.send('lua', context.addr_auth, "Auth.Disconnect", c.uid)
    print("client: close", fd, c.uid, data)
end)

moon.raw_dispatch("S2C",function(msg)
    local buf = moon.decode(msg, "L")
    local uid = seri.unpack_one(buf, true)
    if type(uid) == "number" then
        local c = context.uid_map[uid]
        if not c then
            return
        end

        socket.write(c.fd, buf)

        if moon.DEBUG() then
            protocol.print_message(uid, buf,"S2C")
        end
    else
        local p = moon.ref_buffer(buf)
        for _, one in ipairs(uid) do
            local c = context.uid_map[one]
            if c then
                socket.write_ref_buffer(c.fd,p)
                if moon.DEBUG() then
                    protocol.print_message(one, buf,"S2C")
                end
            end
        end
        moon.unref_buffer(p)
    end
end)

moon.raw_dispatch("SBC",function(msg)
    local buf = moon.decode(msg, "L")
    local p = moon.ref_buffer(buf)
    for uid, c in pairs(context.uid_map) do
        socket.write_ref_buffer(c.fd,p)
        if moon.DEBUG() then
            protocol.print_message(uid, buf,"SBC")
        end
    end
    moon.unref_buffer(p)
end)

moon.raw_dispatch("D2C",function(msg)
    local buf = moon.decode(msg, "L")
    local net_id = seri.unpack_one(buf, true)
    if type(net_id) == "number" then
        local c = context.net_id_map[net_id]
        if not c then
            -- 客户端没有找到,如果是ServerForward可以通知服务器删除客户端
            return
        end

        socket.write(c.fd, buf)

        if moon.DEBUG() then
            protocol.print_message(net_id, buf,"D2C")
        end
    else
        local p = moon.ref_buffer(msg)
        for _, one in ipairs(net_id) do
            local c = context.GnId_map[one]
            if c then
                socket.write_ref_buffer(c.fd,p)
                if moon.DEBUG() then
                    protocol.print_message(one, buf,"D2C")
                end
            end
        end
        moon.unref_buffer(p)
    end
end)

