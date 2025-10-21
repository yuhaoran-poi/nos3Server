--require("common.LuaPanda").start("127.0.0.1", 8818)
local moon = require("moon")
local seri = require("seri")
local socket = require("moon.socket")
local common = require("common")
local setup =  require("common.setup")
local protocol = common.protocol
local GameDef = common.GameDef
local CmdCode = common.CmdCode
local conf = ...

local redirect = moon.redirect

local PTYPE_D2S = GameDef.PTYPE_D2S

---@class gate_context:base_context
---@field scripts gate_scripts
local context = {
    conf = conf,
    dsid_map = {},
    net_id_map = {},  --直连到本Gate的所有ds服务器,gateNetId
    fd_map = {},
    auth_watch = {},
}

setup(context)

socket.on("accept", function(fd, msg)
    print("GAME SERVER: dugate accept ", fd, moon.decode(msg, "Z"))
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
            local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
           local subname,submsg = protocol.DecodeMessagePack(MessagePack)
            --先校验协议版本号
            if subname == "PBDSLoginReqCmd" then
               reqmsg.msg = submsg
               reqmsg.sign = context.auth_watch[fd]
               reqmsg.fd = fd
               reqmsg.addr = socket.getaddress(fd)
               reqmsg.pull = false
               reqmsg.isDS = true
               moon.send("lua", context.addr_auth, subname, reqmsg)
            else
               print("ds: message", fd, subname, submsg)
            end
        end
    else
        if moon.DEBUG() then
            local buf = moon.decode(msg, "B")
            protocol.print_message(c.net_id, buf, "message", 1)
        end
        local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
        c.last_ping_time = moon.time()
        redirect(msg, c.addr_dsnode, GameDef.PTYPE_D2S, 0, 0)
    end

end)

socket.on("close", function(fd, msg)
    local data = moon.decode(msg, "Z")
    context.auth_watch[fd] = nil
    local c = context.fd_map[fd]
    if not c then
        print("GAME SERVER: close", fd, data)
        return
    end
    context.fd_map[fd] = nil
    if c.dsid then
        context.dsid_map[c.dsid] = nil -- body
    end
    if c.net_id then
        context.net_id_map[c.net_id] = nil
    end
    moon.send('lua', context.addr_auth, "Auth.DsDisconnect", c.dsid)
    print("GAME SERVER: close", fd, c.net_id, data)
end)

moon.raw_dispatch("S2D", function(msg)
    local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
    local buf = moon.decode(msg, "L")
    local net_id = seri.unpack_one(buf, true)
    if type(net_id) == "number" then
        local c = context.net_id_map[net_id]
        if not c then
            return
        end

        socket.write(c.fd, buf)

        if moon.DEBUG() then
            protocol.print_message(net_id, buf,"S2D")
        end
    else
        local p = moon.ref_buffer(buf)
        for _, one in ipairs(net_id) do
            local c = context.net_id_map[one]
            if c then
                socket.write_ref_buffer(c.fd, p)
                if moon.DEBUG() then
                    protocol.print_message(one, buf, "S2D")
                end
            end
        end
        moon.unref_buffer(p)
    end
end)

moon.raw_dispatch("D2D",function(msg)
    local buf = moon.decode(msg, "L")
    local net_id = seri.unpack_one(buf, true)
    if type(net_id) == "number" then
        local c = context.net_id_map[net_id]
        if not c then
            return
        end

        socket.write(c.fd, buf)

        if moon.DEBUG() then
            protocol.print_message(net_id, buf,"D2D")
        end
    else
        local p = moon.ref_buffer(buf)
        for _, one in ipairs(net_id) do
            local c = context.GnId_map[one]
            if c then
                socket.write_ref_buffer(c.fd,p)
                if moon.DEBUG() then
                    protocol.print_message(one, buf,"D2D")
                end
            end
        end
        moon.unref_buffer(p)
    end
end)

moon.raw_dispatch("C2D",function(msg)
    local buf = moon.decode(msg, "L")
    local net_id = seri.unpack_one(buf, true)
    if type(net_id) == "number" then
        local c = context.net_id_map[net_id]
        if not c then
            return
        end

        socket.write(c.fd, buf)

        if moon.DEBUG() then
            protocol.print_message(net_id, buf,"C2D")
        end
    else
        local p = moon.ref_buffer(buf)
        for _, one in ipairs(net_id) do
            local c = context.GnId_map[one]
            if c then
                socket.write_ref_buffer(c.fd,p)
                if moon.DEBUG() then
                    protocol.print_message(one, buf,"C2D")
                end
            end
        end
        moon.unref_buffer(p)
    end
end)
