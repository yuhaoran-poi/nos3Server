--[[
* @file : GuildFounds.lua
* @brief : 公会金库：战利品 DKP 捐赠、维护资金 相关功能
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

---@class GuildTreasury
local GuildTreasury = {}

function GuildTreasury.Init()
    local data = scripts.GuildModel.Get()
     
end

function GuildTreasury.Start()
    -- body
end

 

return GuildTreasury