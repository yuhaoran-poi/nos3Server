--[[
* @file : Selection.lua
* @type: multi service
* @brief : 坂选（BP）流程
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




---@class Selection
local Selection = {}

function Selection.Init()
    return true
     
end

function Selection.Start()
    
    return true
end
function Selection.InitData()
    
end
function Selection.Shutdown()
    moon.quit()
    return true
end

 
 
return Selection