--[[
* @file : SelectionLRS.lua
* @type: multi service
* @brief : 狼人杀模式
* @author : yq
]]

local moon = require "moon"
local common = require "common"
local cluster = require("cluster")
local queue = require "moon.queue"
local lock = queue()
---@type selection_context
local context = ...
local scripts = context.scripts




---@class SelectionLRS
local SelectionLRS = {}

function SelectionLRS.Init()
    return true
     
end

function SelectionLRS.Start()
    
    return true
end
 
 
 
return SelectionLRS