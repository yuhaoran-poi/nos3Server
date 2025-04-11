--require("common.LuaPanda").start("127.0.0.1", 8818)
local moon = require("moon")
local setup = require("common.setup")

---@class guild_context:base_context
---@field scripts guild_scripts
local context = {
    guild_id = 0,
    addr_db_game = 0,
    scripts = {},
}

local command = setup(context)
context.addr_db_redis = moon.queryservice("db_user")
if moon.queryservice("db_game") > 0 then
    context.addr_db_user = moon.queryservice("db_game")
end
---@diagnostic disable-next-line: duplicate-set-field
command.hotfix = function(names)
    
end

