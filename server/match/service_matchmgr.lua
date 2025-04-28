--require("common.LuaPanda").start("127.0.0.1", 8818)
local moon = require("moon")
local setup = require("common.setup")

---@class matchmgr_context:base_context
---@field scripts matchmgr_scripts
local context = {
    scripts = {},
    addr_db_game = 0,
    -- 所有房间信息<匹配类型定义,<房间ID,房间信息>>
    ---@type table<number, table<number,table>>
    rooms = {},
    -- 所有队伍信息<匹配类型定义,<队伍ID,队伍信息>>
    ---@type table<number, table<number,table>>
    teams = {},
    -- 记录玩家对应的room_id
    ---@type table<number, number>
    uid_room = {},
}

local command = setup(context)

---@diagnostic disable-next-line: duplicate-set-field
command.hotfix = function(names)
    
end

