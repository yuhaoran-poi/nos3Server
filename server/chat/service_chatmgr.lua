--require("common.LuaPanda").start("127.0.0.1", 8818)
local moon = require("moon")
local setup = require("common.setup")

---@class chatmgr_context:base_context
---@field scripts chatmgr_scripts
local context = {
    scripts = {},
    addr_db_game = 0,
    -- 频道组播id信息
    Channels = {},
}

local command = setup(context)

---@diagnostic disable-next-line: duplicate-set-field
command.hotfix = function(names)
    
end

