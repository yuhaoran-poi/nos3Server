--[[
* @file : SelectionNormal.lua
* @type: multi service
* @brief : 普通模式
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




---@class SelectionNormal
local SelectionNormal = {}

function SelectionNormal.Init()
    return true
     
end

function SelectionNormal.Start()
    
    return true
end
 
 
 
 
 
 
return SelectionNormal