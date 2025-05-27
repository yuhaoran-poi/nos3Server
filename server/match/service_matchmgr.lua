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
    -- 申请匹配的队伍的列表（需等待队员确认）<队伍ID,申请时间>
    ---@type table<number,number>
    applying_teams = {},
    -- 匹配队伍列表<匹配类型定义,<队伍ID,开始匹配时间>>
    ---@type table<number, table<number,number>>
    matching_teams = {},
    -- 所有队伍信息<队伍ID,队伍信息>
    ---@type table<number, TeamDataClass>
    all_teams = {},
    ---@type number[]
    level_pool = {},      -- 等级池
    ---@type number[]
    rank_score_pool = {}, -- 排位分池
    -- 记录玩家对应的room_id
    ---@type table<number, number>
    uid_room = {},
    --[[
    -- 记录玩家对应的阵营camp_id
    ---@type table<number, number>
    user_camp = {},
    -- 记录阵营信息<camp_id, 阵营信息>
    ---@type table<number,Camp> 
    camp_class = {}, --]]
}

local command = setup(context)

---@diagnostic disable-next-line: duplicate-set-field
command.hotfix = function(names)
    
end

