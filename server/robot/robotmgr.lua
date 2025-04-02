--[[
* @file : robotmgr.lua
* @brief : 机器人管理器
]]

require("socket.core")
print("LuaSocket is installed and loaded successfully.")

-- require("common.LuaPanda").start("127.0.0.1", 8818)
--print("LuaPanda successfully.")

local moon = require("moon")
local socket = require("moon.socket")
local common = require("common")
local protocol = common.protocol
local conf = ...

 

 
local function reaLine()
    while true do
        local s = io.read()
        if s then
            return s
        end
        moon.sleep(0)  -- 让出协程但不挂起
        moon.sleep(0)  -- 让出协程但不挂起
    end
end
local mode = false
local function Run(RobotMgr)
    -- 实时交互模式
    while true do
        print("please input cmd:")
        local args = reaLine()
        local t = string.split(args, " ")
        local ret = moon.call("lua", RobotMgr.robot_addr, "DoCmd", t)
        
    end
     
end


 
---@class RobotMgr
local RobotMgr = {}

RobotMgr.Init = function()
    RobotMgr.robot_addr = moon.queryservice("robot")
    moon.async(function()
        Run(RobotMgr)

    end)
   
    return true
end
 

if conf.name then
  
  
    moon.dispatch("lua", function(sender, session, cmd, ...)
        -- 如果dbs为空，说明连接池已经满了，等待连接池有空闲连接
        local fn = RobotMgr[cmd]
        if fn then
            moon.response("lua", sender, session, fn(...))
        else
            moon.error("unknown Robot command", cmd, ...)
        end
    end)
    
end



return RobotMgr
 

