local moon = require "moon"
local common = require "common"
local ErrorCode = common.ErrorCode --逻辑错误码
local CmdEnum = common.CmdEnum
local GameCfg = common.GameCfg     --游戏配置
-- local cluster = require("cluster")

---@class RankScoreDataClass
local RankScoreData = {
    nCampType = 0,
    nGrade = 0,
    nLevel = 0,
    nStarNum = 0,
    nOfflineDay = 0,
    fMvpRate = 0.0,
    nLianShenNum = 0,
    fWinRate = 0.0,
}

local RankScoreLogic = {}

function RankScoreLogic.Init()
    return true
end

 
-- 获取连胜分
function RankScoreLogic.GetRankScoreData(nCampType, nLianShengNum)
    return 0
end
-- 获取胜率分
function RankScoreLogic.GetRankScoreData(nCampType, nLianShengNum)
    return 0
end
-- 获取掉线分
function RankScoreLogic.GetOfflineScore(nCampType, nOfflineDay)
    return 0
end
-- 获取mvp分
function RankScoreLogic.GetMvpScore(fMvpNum)
    return 0
end
-- 获取星星分数
function RankScoreLogic.GetRankBaseScore(nStarNum)
    return 0
end
function RankScoreLogic.GetTeamScore(nTeamPlayerNum)
    return 0
end
function RankScoreLogic.GetWinRateScore(nCampType, fWinRate)
    return 0
end
function RankScoreLogic.GetRankStarNum(nGrade, nLevel, nStar)
    if nGrade <= 0 then
        nGrade = 1
    end
    if nLevel <= 0 then
        nLevel = 1
    end
    local nTotalStarNum = nStar
    local nMinGrade = math.min(nGrade - 1, 4)
    for i = 1, nMinGrade do
        local cfg = GameCfg.RankLevel[i]
        if cfg then
            nTotalStarNum = nTotalStarNum + cfg.max_level * cfg.top_star
        end
    end
    if nGrade <= 4 then
        local cfg = GameCfg.RankLevel[nGrade]
        if cfg then
            nTotalStarNum = nTotalStarNum + (nLevel-1) * cfg.top_star
        end
    end
    return nTotalStarNum
end
-- 获取玩家RankScore
---@param data RankScoreDataClass
function RankScoreLogic.GetRankScore(data)
    return RankScoreLogic.GetRankStarNum(data.nGrade, data.nLevel, data.nStarNum)
end
return RankScoreLogic
