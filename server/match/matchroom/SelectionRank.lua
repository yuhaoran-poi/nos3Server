--[[
* @file : SelectionRank.lua
* @type: multi service
* @brief : 排位模式
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




---@class SelectionRank
local SelectionRank = {}

function SelectionRank.Init()
    return true
     
end

function SelectionRank.Start()
    
    return true
end
 
 
 
return SelectionRank