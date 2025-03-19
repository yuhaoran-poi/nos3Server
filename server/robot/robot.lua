require("socket.core")
print("LuaSocket is installed and loaded successfully.")

--require("common.LuaPanda").start("127.0.0.1", 8818)
--print("LuaPanda successfully.")

local moon = require("moon")
local socket = require("moon.socket")
local common = require("common")

local protocol = common.protocol
local MSGID = common.CmdCode
local vector2 = common.vector2
--local GameCfg = common.GameCfg

local conf = ...
local fd_map = {}
-- local function read(fd)
--     local data, err = socket.read(fd, 2)
--     if not data then
--         return false, err
--     end
--     local len = string.unpack(">H", data)
--     data, err = socket.read(fd, len)
--     if not data then
--         return false, err
--     end
--     local name, t, id = protocol.decodestring(data)
--     if id == MSGID.S2CErrorCode then
--         moon.error(print_r(t, true))
--     end
--     return name, t
-- end

local function read(fd)
    local now_cmd_data = {}

    local data, err = socket.read(fd, 2)
    if not data then
        return false, err
    end

    local len = string.unpack(">H", data)
    data, err = socket.read(fd, len)
    if not data then
        return false, err
    end
    --local ret = LuaPanda and LuaPanda.BP and LuaPanda.BP()
    --local _, rsp = protocol.decode(moon.decode(data, "B"))
    local name, t, id = protocol.decodestring(data)
    --local _, rsp = protocol.decode(data)
    for _, MessagePack in ipairs(t.messages) do
        local subname, submsg = protocol.DecodeMessagePack(MessagePack)
        table.insert(now_cmd_data, {
            call_id = MessagePack.stub_id,
            cmd = subname,
            data = submsg
        })
    end

    return true, now_cmd_data
end

-- socket.on("message", function(fd, msg)
--     local ret = LuaPanda and LuaPanda.BP and LuaPanda.BP()
--     local c = fd_map[fd]
--     if not c then
--         local name, req = protocol.decode(moon.decode(msg, "B"))
--         for key, MessagePack in ipairs(req.messages) do
--             local reqmsg = {}
--             reqmsg.msg_context = {
--                 net_id = MessagePack.net_id,
--                 broadcast = MessagePack.broadcast,
--                 stub_id = MessagePack.stub_id,
--                 msg_type = MessagePack.msg_type
--             }
--             local subname, submsg = protocol.DecodeMessagePack(MessagePack)

--             print("client: message", fd, subname, submsg)
--         end
--     else
--         if moon.DEBUG() then
--             local buf = moon.decode(msg, "B")
--             protocol.print_message(c.net_id, buf, "message", 1)
--         end
--         local name, req = protocol.decode(moon.decode(msg, "B"))
--         for key, MessagePack in ipairs(req.messages) do
--             local subname, submsg = protocol.DecodeMessagePack(MessagePack)
--             if c.expect_state and c.expect_state.stub_id == MessagePack.stub_id then
--                 local fn = c.expect_state.fn
--                 if fn then
--                     fn(submsg)
--                 end
--             else
--                 print("msg call_id", MessagePack.stub_id)
--                 print("msg cmd", subname)
--                 print("msg data", submsg)
--             end
--         end
--     end
-- end)

local function send(fd, stub_id, msgId, msg)
    local MessagePack = protocol.encodeMessagePacket(0, msgId, msg, stub_id or 0)
    local Packet = { messages = { MessagePack } }
    local data = protocol.encodestring(1, Packet)
    --moon.raw_send(C2S, receiver, data, session)
    local len = #data
    return socket.write(fd, string.pack(">H",len)..data)
end

---@class Client
---@field fd integer
---@field expect_state table
---@field ok boolean
---@field now_stub_id integer
local Client = {}

function Client.new(host, port, name)
    local client = {
        fd = assert(socket.connect(host, port, moon.PTYPE_SOCKET_TCP)),
        expect_state = nil,
        ok = true,
        now_stub_id = 0,
    }

    moon.async(function ()
        while true do
            local cmd, msgs = read(client.fd)
            if not cmd then
                print("socket error", msgs)
                client.ok = false
                return
            end

            local _, _ = client:Call("PBPingCmd", {}, "PBPongCmd")

            for _, v in pairs(msgs) do
                if client.expect_state and client.expect_state.stub_id == v.call_id then
                    local fn = client.expect_state.fn
                    if fn then
                        fn(v.data)
                    end
                else
                    print("msg call_id", v.call_id)
                    print("msg cmd", v.cmd)
                    print("msg data", v.data)
                end
            end
        end
    end)

    return setmetatable(client, {__index = Client})
end

---阻塞等待指定消息返回
---@param self Client
---@param cmd string
---@param fn? function
---@return any
function Client.Expect(self, cmd, fn)
    assert(self.ok)
    self.expect_state = {cmd = cmd, fn = fn, co = coroutine.running()}
    return coroutine.yield()
end

---comment 发送消息
---@param self Client
---@param msgId any
---@param msg any
---@return boolean
function Client.Send(self, msgId, msg)
    if not self.ok then
        return false
    end
    self.now_stub_id = self.now_stub_id + 1
    send(self.fd, self.now_stub_id, msgId, msg)
    return true
end

---comment 发送消息并等待返回
---@param self Client
---@param sendMsgId any
---@param sendMsg any
---@param recvMsgName any
---@return any
function Client.Call(self, sendMsgId, sendMsg, recvMsgName)
    assert(self.ok)
    self.now_stub_id = self.now_stub_id + 1
    send(self.fd, self.now_stub_id, sendMsgId, sendMsg)
    return self:Expect(recvMsgName)
end


--游戏逻辑流程
local function client_handler(uname)
    local client = Client.new(conf.host, conf.port, uname)
    fd_map[client.fd] = client

    ---auth message
    local login_msg = {
        uid = 1,
        login_key = uname,
        version = "3",
        password = "4",
    }
    local S2CLogin, err = client:Call("PBClientLoginReqCmd", { login_data = login_msg }, "PBClientLoginRspCmd")
    assert(S2CLogin.ok, "S2CLogin failed")

    print("robot", login_msg, " login success")
end

moon.dispatch("lua", function()
    moon.warn("ignore")
end)

moon.async(function()
    --GameCfg.Load()

    moon.sleep(10)
    local username = 0

    local create_user
    create_user = function (un)
        if not un then
            username = username + 1
            un = username
        end

        moon.async(function ()
            print(xpcall(client_handler, debug.traceback, "robot"..tostring(un)))
            moon.sleep(2000000)
            --create_user(un)
        end)
    end

    moon.sleep(3000)
    --for _=1, GameCfg.constant.robot_num do
    for _ = 1, 1 do
        create_user()
        moon.sleep(10000000)
    end
end)

-- local function robot()
--     local username = 0

--     local create_user
--     create_user = function(un)
--         if not un then
--             username = username + 1
--             un = username
--         end

--         print(xpcall(client_handler, debug.traceback, "robot" .. tostring(un)))
--     end

--     --for _=1, GameCfg.constant.robot_num do
--     for _ = 1, 1 do
--         create_user()
--     end
-- end

-- robot()
