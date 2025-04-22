--require("common.LuaPanda").start("127.0.0.1", 8818)

local moon = require("moon")
local socket = require("moon.socket")
local common = require("common")
local setup = require("common.setup")

local protocol = common.protocol

local conf = ...

---@class citymgr_context:base_context
local context = {
    conf = conf,
    city_nowid = conf.city_startid,
    citys = {},             --当前主城列表
    uid_cityid = {},        --uid所在的主城id
    waitds_citys = {},      --等待DS的主城id列表 status:0--请求DS,1--查询DS状态
}

setup(context)

moon.shutdown(function()
    moon.quit()
end)
