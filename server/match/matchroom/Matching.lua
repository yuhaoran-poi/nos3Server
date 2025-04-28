--[[
* @file : Matching.lua
* @type: multi service
* @brief : 匹配流程
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




---@class Matching
local Matching = {}

function Matching.Init()
    return true
     
end

function Matching.Start()
    
    return true
end
function Matching.InitData()
    
end
function Matching.Shutdown()
    moon.quit()
    return true
end

 
 
return Matching