local LuaExt = require "common.LuaExt"

local GradeDef = {
}

local defaultPBGradeData = {
    grade_id = 0,
    now_grade_score = 0,
    highest_grade_score = 0,
    already_get_reward_ids = {},
}

local defaultPBGradeInfo = {
    season_id = 0,
    grade_data = LuaExt.const(table.copy(defaultPBGradeData)),
}

local defaultPBGradeShowData = {
    grade_id = 0,
    now_grade_score = 0,
}

local defaultPBGradeShowInfo = {
    season_id = 0,
    grade_show_data = LuaExt.const(table.copy(defaultPBGradeShowData)),
}

local defaultPBGradePlayerData = {
    cur_season_id = 0,
    grade_infos = {},
}

---@return PBGradeData
function GradeDef.newGradeData()
    return LuaExt.const(table.copy(defaultPBGradeData))
end

---@return PBGradeInfo
function GradeDef.newGradeInfo()
    return LuaExt.const(table.copy(defaultPBGradeInfo))
end

---@return PBGradeShowData
function GradeDef.newGradeShowData()
    return LuaExt.const(table.copy(defaultPBGradeShowData))
end

---@return PBGradeShowInfo
function GradeDef.newGradeShowInfo()
    return LuaExt.const(table.copy(defaultPBGradeShowInfo))
end

---@return PBGradePlayerData
function GradeDef.newGradePlayerData()
    return LuaExt.const(table.copy(defaultPBGradePlayerData))
end

return GradeDef
