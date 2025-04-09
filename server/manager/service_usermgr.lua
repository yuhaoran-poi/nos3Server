--require("common.LuaPanda").start("127.0.0.1", 8818)

local moon = require("moon")
local socket = require("moon.socket")
local common = require("common")
local setup = require("common.setup")

local protocol = common.protocol

local conf = ...

---@class usermgr_context:base_context
local context = {
    conf = conf,
    node_info = {}, -- 节点信息
    user_node = {}, -- 用户对应的节点信息
}

setup(context)

moon.shutdown(function()
    moon.quit()
end)
