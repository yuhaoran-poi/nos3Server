local LuaExt = require "common.LuaExt"
local UserAttrDef = require "common.def.UserAttrDef"
local TeamDef = {}
-- 队伍匹配相关数据
--- @class TeamMatchDataClass
--- @field match_type number 匹配类型
--- @filed camp_type number 阵营类型
--- @field comfirm_time number 确认时间
--- @field match_time number 匹配时间
--- @field is_camer boolean 是否主播
--- @field need_ai boolean 是否需要AI
--- @field rank_score number 队伍排位分
local defaultTeamMatchData = {
    match_type = 0, -- 匹配类型
    camp_type = 0, -- 阵营类型
    comfirm_time = 0, -- 确认时间
    match_time = 0, -- 匹配时间
    is_camer = false, -- 是否主播
    need_ai = false, -- 是否需要AI
    rank_score = 0, -- 队伍排位分
}
-- 队伍服务器数据
--- @class TeamDataClass
--- @field team_id number 队伍ID
--- @field master_uid number 队长UID
--- @field members table<number, PBUserAttr> 成员列表，key为UID，value为用户简单信息
--- @field match_data TeamMatchDataClass 匹配相关数据
local defaultTeamData = {
    team_id = 0,
    master_uid = 0,
    members = {},
    match_data = LuaExt.const(table.copy(defaultTeamMatchData))
}
-- 创建新的队伍数据
--- @return TeamDataClass
function TeamDef.newTeamData()
    return LuaExt.const(table.copy(defaultTeamData))
end


return TeamDef