--require("common.LuaPanda").start("127.0.0.1", 8818)

local moon = require("moon")
local socket = require("moon.socket")
local common = require("common")
local setup = require("common.setup")

local protocol = common.protocol

local conf = ...

---@class friendmgr_context:base_context
local context = {
    conf = conf,
---@diagnostic disable-next-line: missing-fields
    user_relations = {},
}
--

setup(context)
context.addr_db_redis = moon.queryservice("db_mgr")
if moon.queryservice("db_game") > 0 then
    context.addr_db_game = moon.queryservice("db_game")
end

moon.shutdown(function()
    moon.quit()
end)
