--require("common.LuaPanda").start("127.0.0.1", 8818)
local moon = require("moon")
local setup = require("common.setup")

---@class matchhelp_context:base_context
---@field scripts matchhelp_scripts
local context = {
    scripts = {},
    addr_db_game = 0,
    matchmgr_addr = 0,
}

local command = setup(context)

---@diagnostic disable-next-line: duplicate-set-field
command.hotfix = function(names)
    
end

