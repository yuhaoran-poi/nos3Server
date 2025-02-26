--require("common.LuaPanda").start("127.0.0.1", 8818)
local moon = require("moon")
local seri = require("seri")
local socket = require("moon.socket")
local common = require("common")
local setup = require("common.setup")
local protocol = common.protocol
local GameDef = common.GameDef
local CmdCode = common.CmdCode
local conf = ...

local redirect = moon.redirect

local PTYPE_C2S = GameDef.PTYPE_C2S

---@class gate_context:base_context
---@field scripts gate_scripts
local context = {
    conf = conf,
    uid_map = {},
    fd_map = {},
    gnid_map = {},  --直连到本Gate的所有客户端
    auth_watch = {},
}

setup(context)

socket.on("accept", function(fd, msg)
    print("client: accept ", fd, moon.decode(msg, "Z"))
    socket.set_enable_chunked(fd, "w")
    --local ret = LuaPanda and LuaPanda.BP and LuaPanda.BP()
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
                gateNetId = MessagePack.gateNetId,
                broadcast = MessagePack.broadcast,
                stubId =    MessagePack.stubId,
                msgType =   MessagePack.msgType
              }
           local subname,submsg = protocol.DecodeMessagePack(MessagePack)
            --先校验协议版本号
            if subname == "dsgatepb.AuthCmd" then
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
            protocol.print_message(c.gnid, buf,"message",1)
        end
        local name, req = protocol.decode(moon.decode(msg,"B"))
        for key, MessagePack in ipairs(req.messages) do
            if MessagePack.gateNetId < GameDef.DSGateConst.MinNodeGateNetId then
               if  MessagePack.gateNetId == GameDef.DSGateConst.GlobalGateNetId then
                  -- 转发到ds全局服务器
                  context.forwardC(MessagePack.gateNetId,MessagePack)
               elseif   MessagePack.gateNetId == GameDef.DSGateConst.ExternalGateNetId then
                   -- 外围服务器处理
                   redirect(MessagePack, c.addr_user, GameDef.PTYPE_C2S, 0, 0)
               end
            else
                --转发
                c.ds_gnid = MessagePack.gateNetId
                if MessagePack.msgType == CmdCode["dsgatepb.SubDSCmd"] then
                    local subname,submsg = protocol.DecodeMessagePack(MessagePack)
                    submsg.Addr = socket.getaddress(fd)
                    context.S2D(MessagePack.gateNetId, CmdCode["dsgatepb.SubDSCmd"], submsg,MessagePack.stubId)
                else
                    context.forwardC(MessagePack.gateNetId,MessagePack)
                end
                
            end
        end
        --redirect(msg, c.addr_user, GameDef.PTYPE_C2D, 0, 0)
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
        srcGnId = c.gnid
    }
    if c.ds_gnid then
       context.S2D(c.ds_gnid, CmdCode["dsgatepb.DisconnectGateCmd"], DisconnectGateCmd,0)
    end
    -- 发送消息通知Gloabal
    context.S2D(0, CmdCode["dsgatepb.DisconnectGateCmd"], DisconnectGateCmd,0)
    context.fd_map[fd] = nil
    context.uid_map[c.uid] = nil
    context.gnid_map[c.gnid] = nil
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
    local gnid = seri.unpack_one(buf, true)
    if type(gnid) == "number" then
        local c = context.gnid_map[gnid]
        if not c then
            -- 客户端没有找到,如果是ServerForward可以通知服务器删除客户端
            return
        end

        socket.write(c.fd, buf)

        if moon.DEBUG() then
            protocol.print_message(gnid, buf,"D2C")
        end
    else
        local p = moon.ref_buffer(msg)
        for _, one in ipairs(gnid) do
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

