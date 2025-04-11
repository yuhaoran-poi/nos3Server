--require("common.LuaPanda").start("127.0.0.1", 8818)
local moon = require("moon")
local common = require("common")
local setup = require("common.setup")

local conf = ...

---@class guildmgr_context:base_context
---@field scripts center_scripts
local context ={
    conf = conf,
    guilds = {},
    uid_to_guild = {},
    ---@type table<integer, integer> 节点ID到agent服务地址的映射
    node_agents = {},
    node_guilds = {}, --agent节点对应的guild_ids{[nid] = {guild_id1 = true,guild_id2 = true}}
}

setup(context)
