--require("common.LuaPanda").start("127.0.0.1", 8818)

local moon = require("moon")
local socket = require("moon.socket")
local common = require("common")
local setup = require("common.setup")

local protocol = common.protocol

local conf = ...

---@class roommgr_context:base_context
local context = {
    conf = conf,
    room_nowid = conf.room_startid,
    rooms = {}, --当前房间列表
    uid_roomid = {}, --uid所在的房间id
}
local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()

setup(context)

moon.shutdown(function()
    moon.quit()
end)
