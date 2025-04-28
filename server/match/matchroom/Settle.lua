--[[
* @file : Settle.lua
* @type: multi service
* @brief : 战斗结算流程
* @author : yq
]]

local moon = require "moon"
local common = require "common"
local cluster = require("cluster")
local queue = require "moon.queue"
local lock = queue()
---@type matchroom_context
local context = ...
local scripts = context.scripts




---@class Settle
local Settle = {}

function Settle.Init()
    return true
     
end

function Settle.Start()
    
    return true
end
function Settle.InitData()
    
end
function Settle.Shutdown()
    moon.quit()
    return true
end

 
 
return Settle