--[[
* @file : GuildFounds.lua
* @brief : 公会商店：相关功能
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

---@class GuildShop
local GuildShop = {}

function GuildShop.Init()
    return true
     
end

function GuildShop.Start()
    return true
end

 

return GuildShop