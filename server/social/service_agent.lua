--require("common.LuaPanda").start("127.0.0.1", 8818)
local moon = require("moon")
local setup = require("common.setup")

---@class agent_context:base_context
---@field scripts agent_scripts
local context = {
    scripts = {},
}

local command = setup(context)

---@diagnostic disable-next-line: duplicate-set-field
command.hotfix = function(names)
    
end

