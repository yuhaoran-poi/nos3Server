--require("common.LuaPanda").start("127.0.0.1", 8818)
local moon = require("moon")
local common = require("common")
local setup = require("common.setup")

local conf = ...

---@class guildnamemgr_context:base_context
---@field scripts center_scripts
local context ={
    conf = conf,
    guild_map={},
}

setup(context)
