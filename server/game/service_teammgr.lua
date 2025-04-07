local moon = require "moon"
local socket = require "moon.socket"
local common = require "common"
local setup = require "common.setup"

local protocol = common.protocol

local conf = ...

---@class team_context:base_context
---@field scripts team_scripts
local context = {
    conf = conf,
    team_info = {}, -- 队伍ID -> 队伍信息
    user_team = {}, -- 用户ID -> 队伍ID
}

setup(context)


moon.shutdown(function()
    moon.quit()
end)
