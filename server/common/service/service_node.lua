--require("common.LuaPanda").start("127.0.0.1", 8818)

local moon = require("moon")
local common = require("common")
local setup = require("common.setup")
local conf = ...

---@class node_context:base_context
---@field scripts node_scripts
local context ={
    logics = {},
}

setup(context,"node")

moon.shutdown(function()
    moon.quit()
end)
