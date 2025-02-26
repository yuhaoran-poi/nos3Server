--require("common.LuaPanda").start("127.0.0.1", 8818)
local moon = require("moon")
local common = require("common")
local setup = require("common.setup")
local conf = ...

---@class mail_context:base_context
---@field scripts mail_scripts
local context ={
    conf = conf,
    models = {},
    uid_address = {}
}

setup(context,"room")

moon.shutdown(function()
    --- rewrite default behavior: quit immediately
end)
