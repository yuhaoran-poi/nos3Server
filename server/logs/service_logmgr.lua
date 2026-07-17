--require("common.LuaPanda").start("127.0.0.1", 8818)
local moon = require("moon")
local setup = require("common.setup")
local json = require("json")

---@class logmgr_context:base_context
---@field scripts logmgr_scripts
local context = {
    scripts = {},
    addr_db_log = 0,
    
}

local command = setup(context)

local cmd_list = {}
for k in pairs(command) do
    table.insert(cmd_list, k)
end
moon.error(string.format("command list: %s", json.pretty_encode(cmd_list)))

---@diagnostic disable-next-line: duplicate-set-field
command.hotfix = function(names)
    
end

