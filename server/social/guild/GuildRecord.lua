--[[
* @file : GuildRecord.lua
* @brief : 公会记录
* @author : yq
]]

local moon = require "moon"
local common = require "common"
local cluster = require("cluster")
local GameCfg = common.GameCfg
local ErrorCode = common.ErrorCode
local CmdCode = common.CmdCode

---@type guild_context
local context = ...
local scripts = context.scripts

---@class GuildRecord
local GuildRecord = {}

function GuildRecord.Init()
     return true
end

function GuildRecord.Start()
    return true
end

 

return GuildRecord