local moon = require "moon"
local common = require "common"
local cluster = require("cluster")
local GameCfg = common.GameCfg
local ErrorCode = common.ErrorCode
local CmdCode = common.CmdCode

---@type guild_context
local context = ...
local scripts = context.scripts

---@class GuildTask
local GuildTask = {}

function GuildTask.Init()
    local data = scripts.GuildModel.Get()
    if not data.guild_task then
        data.guild_task = {
            
        }
    end
end

function GuildTask.Start()
    -- body
end

 

return GuildTask