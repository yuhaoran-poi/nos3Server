--[[
* @file : CreateDS.lua
* @type: multi service
* @brief : 创建DS房间
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




---@class CreateDS
local CreateDS = {}

function CreateDS.Init()
    return true
     
end

function CreateDS.Start()
    
    return true
end
function CreateDS.InitData()
    
end
function CreateDS.Shutdown()
    moon.quit()
    return true
end

 
 
return CreateDS