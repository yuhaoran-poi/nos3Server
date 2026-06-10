--require("common.LuaPanda").start("127.0.0.1", 8818)
local moon = require("moon")
local setup = require("common.setup")
local json = require("json")

---@class rank_context:base_context
---@field scripts rank_scripts
local context = {
    scripts = {},
}

local command = setup(context)

local RankMgr = context.scripts.RankMgr
moon.info(string.format("[ServiceRank] Loaded RankMgr: type=%s, exists=%s", type(RankMgr), tostring(RankMgr ~= nil)))

command.handlePlayerRankUpdate = function(...)
    moon.info(string.format("[ServiceRank] handlePlayerRankUpdate called, args=%s", json.encode({...})))
    return RankMgr.handlePlayerRankUpdate(...)
end

command.GetAllRankTypes = function(...)
    return RankMgr.GetAllRankTypes()
end

command.GetRankInfo = function(...)
    return RankMgr.GetRankInfo(...)
end

command.GetRankReward = function(...)
    return RankMgr.GetRankReward(...)
end

command.GetUnclaimedRewards = function(...)
    return RankMgr.GetUnclaimedRewards(...)
end

command.SendRankRewardMail = function(...)
    return RankMgr.SendRankRewardMail(...)
end

command.RemovePlayerFromRewardData = function(...)
    return RankMgr.RemovePlayerFromRewardData(...)
end

command.UpdatePlayerInfo = function(...)
    return RankMgr.UpdatePlayerInfo(...)
end

---@diagnostic disable-next-line: duplicate-set-field
command.hotfix = function(names)

end