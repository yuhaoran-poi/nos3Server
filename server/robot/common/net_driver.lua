--[[
local print_r = require "robot.common.print_r"
local moon = require("moon")
local socket = require("moon.socket")
local common = require("common")
local protocol = common.protocol
local MSGID = common.CmdCode

---@class driver
local driver = {}

 
function driver:Init_driver(client)
    self.ip = ""
    self.port = 0
    self.fd = 0
    self.stub_id = 0
    self.cb_map = {}
    self.client = client
end

 

local function log(...)
    local str = table.concat(table.pack(...), " ")
    print(string.format("\x1b[1;34m%d: %s\x1b[m", os.time(), str))
end

local function logf(...)
    print(string.format("\x1b[1;34m%d: %s\x1b[m", os.time(), string.format(...)))
end

local function logerr(...)
    print(string.format("\x1b[1;31m%d: %s\x1b[m", os.time(), string.format(...)))
end
 

 
function driver:connect(ip, port)
    if self.start_recv then
        return false, "already connected!"
    end
    self.ip = ip
    self.port = port
    self.start_recv = false
    logf("connect server, ip:%s ip:%d", ip, port)
    local fd, err = socket.connect(ip, port, moon.PTYPE_SOCKET_TCP)
   
    if fd then
        self.fd = fd
        self.start_recv = true
        self:start_read()
        return true
    else
        logerr("connect server error, ip:%s ip:%d", ip, port)
        return false, err
    end
end
function driver:read()
    local now_cmd_data = {}

    local data, err = socket.read(self.fd, 2)
    if not data then
        return false, err
    end

    local len = string.unpack(">H", data)
    data, err = socket.read(self.fd, len)
    if not data then
        return false, err
    end

    local name, t, id = protocol.decodestring(data)
    for _, MessagePack in ipairs(t.messages) do
        local subname, submsg = protocol.DecodeMessagePack(MessagePack)
        table.insert(now_cmd_data, {
            stub_id = MessagePack.stub_id,
            cmd = subname,
            data = submsg
        })
    end

    return true, now_cmd_data
end

function driver:start_read()
    moon.async(function()
            local cmd, msgs = self:read()
            local ret = LuaPanda and LuaPanda.BP and LuaPanda.BP();
            if not cmd then
                print("socket error", msgs)
                return
            end
            print_r(msgs)
            for _, v in pairs(msgs) do
               self:dispatch_package(v)
            end
    
    end)
end

 
-- 发送请求包
function driver:send(msgname, msg, cb)
    local stub_id = 0
    if cb then
        self.stub_id = self.stub_id + 1
        self.cb_map[self.stub_id] = cb
        stub_id = self.stub_id
    end
    local MessagePack = protocol.encodeMessagePacket(0, msgname, msg, stub_id or 0)
    local Packet = { messages = { MessagePack } }
    local data = protocol.encodestring(1, Packet)
    local len = #data
    return socket.write(self.fd, string.pack(">H", len) .. data)
end

 

-- 分发包
function driver:dispatch_package(msg)
    print_r(msg)
     
end


-- 关闭链接
function driver:close()
     
end

return driver--]]
