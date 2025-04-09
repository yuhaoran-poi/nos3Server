local moon = require("moon")
local common = require("common")
local CmdCode = common.CmdCode
local GameCfg = common.GameCfg
local Database = common.Database

---@type guildnamemgr_context
local context = ...
local scripts = context.scripts



---@class GuildNameMgr
local GuildNameMgr = {}

function GuildNameMgr:Init()
end

return GuildNameMgr
