local moon = require "moon"
local uuid = require "uuid"
local coqueue = require "moon.queue"
local common = require "common"
local GameDef= common.GameDef
local Database = common.Database
local GameCfg = common.GameCfg --游戏配置
local ErrorCode = common.ErrorCode --逻辑错误码
local CmdCode = common.CmdCode --客户端通信消息码

---@type agent_context
local context = ...
local scripts = context.scripts ---方便访问同服务的其它lua模块
 
---@class Agent
local Agent = {}

function Agent.Init()
   
    return true
end

function Agent.Start()
    return true
end

function Agent.Shutdown()
    moon.quit()
    return true
end

 
return Agent