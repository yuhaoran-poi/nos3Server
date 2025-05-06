local LuaExt = require "common.LuaExt"

---@class RankScoreDataClass
---@field nCampType number 阵营类型 0-鬼 1-人
---@field nGrade number 品阶
---@field nLevel number 品级
---@field nStarNum number 星星数
---@field nOfflineDay number 离线天数
---@field fMvpRate number MVP率
---@field nLianShenNum number 连杀数
---@field fWinRate number 胜率
local defaultPBRankScoreData = {
    nCampType = 0,
    nGrade = 0,
    nLevel = 0,
    nStarNum = 0,
    nOfflineDay = 0,
    fMvpRate = 0.0,
    nLianShenNum = 0,
    fWinRate = 0.0,
}

local RankScoreDef = {}
---@return RankScoreDataClass
function RankScoreDef.newRankScoreData()
    return LuaExt.const(table.copy(defaultPBRankScoreData))
end

return RankScoreDef
