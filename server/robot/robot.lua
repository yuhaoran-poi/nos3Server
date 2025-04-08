--[[
* @file : robot.lua
* @brief : 模拟客户端请求,用于协议功能测试
]]

require("socket.core")
print("LuaSocket is installed and loaded successfully.")

--require("common.LuaPanda").start("127.0.0.1", 8818)
--print("LuaPanda successfully.")

local moon = require("moon")
local socket = require("moon.socket")
local common = require("common")
local protocol = common.protocol
local conf = ...
---@class Client
local Client = require "robot.logic.Client"
require "robot.logic.ClientLogin"
require "robot.logic.ClientGuild"
require "robot.logic.ClientFriend"
require "robot.logic.ClientMail"
require "robot.logic.ClientTeam"

local all_robot = {}
local cur_index = 1
 


 
 



 

 
local function read(fd)
    local now_cmd_data = {}
    --local ret = LuaPanda and LuaPanda.BP and LuaPanda.BP()
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
            stub_id = MessagePack.stub_id,
            cmd = subname,
            data = submsg
        })
    end

    return true, now_cmd_data
end
function Client.new(host, port)
    local clientBase = {
        fd = nil,
        ok = false,
        last_error = nil,
        username = "robot",
        password = "123456",
        cb_map = {},
        stub_id = 0,
        uid = nil,
        login_ok = false,
        index = 0,
    }
    local client = setmetatable(clientBase, { __index = Client })
    -- 尝试建立socket连接
    local fd, err = socket.connect(host, port, moon.PTYPE_SOCKET_TCP)
    if not fd then
        client.last_error = err
        moon.error("connect failed: %s", err)
        return nil
    end
    
    client.fd = fd
    client.ok = true
    client.username = "robot"
    client.password = "123456"
    client.cb_map = {}
    client.stub_id = 0
    client.uid = nil
    client.login_ok = false
    client.index = 0
    -- 启动异步读取循环
    moon.async(function()
        while client.ok do
            local ret = LuaPanda and LuaPanda.BP and LuaPanda.BP()
            local success,ret, result = pcall(read, client.fd)
            if not success or not ret then
                client.ok = false
                client.last_error = result or "read error"
                moon.error("socket error: %s", client.last_error)
                return
            end

            for _, v in pairs(result) do
                moon.info("received: ",client.index, v.cmd, v.data)
                print_r(v.data)
                ret = LuaPanda and LuaPanda.BP and LuaPanda.BP()
                if v.stub_id > 0 then
                    local cb = client.cb_map[v.stub_id]
                    if cb then
                        cb(v.data)
                        client.cb_map[v.stub_id] = nil
                    end
                else
                    local cmd = "On"..v.cmd
                    local f = client[cmd]
                    if f then
                        f(client, v.data)
                    end
                end
            end
        end
    end)

    return client
end

-- 发送请求包
function Client:send(msgname, msg, cb)
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




function Client:help()
    local info =
    [[
"Usage":lua robot.lua cmd [args] ...
	help 					this help
	exit					exit console
	addbot                  index
	delbot                  index
    curbot                  index
    addlogin                   index
]]
    print(info)
end

function Client:exit()
    os.exit()
end
function Client:addlogin(index)
   local bot = Client:addbot(index)
   if bot then
       bot:login()
   end
end

function Client:addbot(index)
    local ret = LuaPanda and LuaPanda.BP and LuaPanda.BP()
    index = tonumber(index) or 1
    local robot = Client.new(conf.host, conf.port)
    robot:Init()
    robot.index = index
  
    if all_robot[index] then
        print("robot found!")
        return nil
    end
    all_robot[index] = robot
    cur_index = index
    print("add robot success!" .. index)
    return robot
end

function Client:delbot(index)
    index = tonumber(index) or 1
    local robot = all_robot[index]
    if not robot then print("robot not found!") return end
    robot:disconnect()
    all_robot[index] = nil
    print("del robot success!" .. index)
    if index == cur_index then
        cur_index = 0
        -- cur_index 取出结果集第一条记录
        for k, v in pairs(all_robot) do
            cur_index = k
            break
        end
    end
end

function Client:curbot(index)
    index = tonumber(index) or 1
    local robot = all_robot[index]
    local ret = LuaPanda and LuaPanda.BP and LuaPanda.BP()
    if not robot then
        print("robot not found!")
        return
    end
    cur_index = index
    print("robot info:" .. index)
    print("robot id:" .. robot.index)
    print("robot name:" .. robot.user_name)
end

 
 


 
---@class Robot
local Robot = {}

Robot.Init = function()
     
   
    return true
end

Robot.DoCmd = function(params)
    local cmd = params[1]
    table.remove(params, 1)
    local f = Client[cmd]
    if f then
        local cur_bot = all_robot[cur_index] or Client
        local ok, err = pcall(f, cur_bot, table.unpack(params))
        if not ok then print(err) end
    else
        print("not found cmd<".. tostring(cmd).. ">! use <help> cmd for usage!")
    end
end

if conf.name then
  
  
    moon.dispatch("lua", function(sender, session, cmd, ...)
        -- 如果dbs为空，说明连接池已经满了，等待连接池有空闲连接
        local fn = Robot[cmd]
        if fn then
            moon.response("lua", sender, session, fn(...))
        else
            moon.error("unknown Robot command", cmd, ...)
        end
    end)
    
end



return Robot
 

