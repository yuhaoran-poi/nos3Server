local LuaExt = require "common.LuaExt"
 
local MatchRoomDef = {}
-- 队伍服务器数据
--- @class MatchRoomDataClass
--- @field teams table<number,TeamDataClass> 玩家的队伍
--- @field ob_teams table<number,TeamDataClass> 观战队伍
--- @field ghost_num number 鬼的人数
--- @field human_num number 人的人数
--- @field red_num number   红队人数
--- @field blue_num number  蓝队人数
--- @field map_id number    地图ID
--- @field max_score number  最大分数
--- @field min_score number  最小分数
--- @field match_count number  匹配次数
--- @field match_time number  开始匹配时间
--- @field is_custom_room boolean 是否自定义房间
--- @field is_low_level boolean  是否低等级
--- @field is_camer boolean  是否主播模式
--- @field is_ai_ghost boolean  是否鬼AI
--- @field is_ai_human boolean  是否人AI
--- @field ai_human_num number 人AI数量
--- @field ai_ghost_num number 鬼AI数量
--- @field vec_search number[] 搜索范围
local defaultMatchRoomData = {
    teams = {}, -- 人的队伍
    ob_teams = {}, -- 观战队伍
    ghost_num = 0, -- 鬼的人数
    human_num = 0, -- 人的人数
    red_num = 0,   -- 红队人数
    blue_num = 0,  -- 蓝队人数
    map_id = 0,    -- 地图ID
    max_score = 0, -- 最大分数
    min_score = 0, -- 最小分数
    match_count = 0, -- 匹配次数
    match_time = 0, -- 开始匹配时间
    is_custom_room = false, -- 是否自定义房间
    is_low_level = false,   -- 是否低等级
    is_camer = false,       -- 是否主播模式
    is_ai_ghost = false,    -- 是否鬼AI
    is_ai_human = false,    -- 是否人AI
    ai_human_num = 0,       -- 人AI数量
    ai_ghost_num = 0,       -- 鬼AI数量
    vec_search = {},        -- 搜索范围
}

-- 一共6个队列，按人数划分开。1~5放人的队列 6放鬼的队列
--- @type table<number,number[]>
local defaultMatchTeamQueue = {
    [1] = {}, -- 1人队伍列表
    [2] = {}, -- 2人队伍列表
    [3] = {}, -- 3人队伍列表
    [4] = {}, -- 4人队伍列表
    [5] = {}, -- 5人队伍列表
    [6] = {}  -- 鬼的队伍列表
}
-- 创建新的队伍数据
--- @return MatchRoomDataClass
function MatchRoomDef.newMatchRoomData()
    return LuaExt.const(table.copy(defaultMatchRoomData))
end
-- 创建新的队伍队列
--- @return table<number,number[]>
function MatchRoomDef.newMatchTeamQueue()
    return LuaExt.const(table.copy(defaultMatchTeamQueue))
end

return MatchRoomDef