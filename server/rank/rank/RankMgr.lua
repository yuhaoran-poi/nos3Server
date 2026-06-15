local moon = require("moon")
local json = require("json")
local common = require("common")
local ErrorCode = common.ErrorCode

local RankLogic = require("common.logic.RankLogic")
local RankDef = require("common.def.RankDef")

---@type rank_context
local context = ...

---@class RankMgr
local RankMgr = {}

function RankMgr.Init()
    context.addr_db_server = moon.queryservice("db_server")
    context.addr_db_user = moon.queryservice("db_user")
    context.addr_db_redis = moon.queryservice("db_redis")
    context.addr_db_log = moon.queryservice("db_log")

    RankLogic.Init(context)
    RankLogic.StartQueueProcessor()
    RankMgr.setupRefreshTasks()
    RankMgr.setupSyncTasks()
    moon.info("RankMgr initialized")
    return true
end

function RankMgr.handlePlayerRankUpdate(msg)
    --moon.debug("handlePlayerRankUpdate received:", json.encode(msg))
    local rank_type = msg.rank_type
    local uid = msg.uid
    local player_data = msg.player_data
    local force = msg.force
    return RankLogic.UpdatePlayerRank(rank_type, uid, player_data, force)
end

function RankMgr.GetAllRankTypes()
    return RankLogic.GetAllRankTypes()
end

function RankMgr.GetRankInfo(msg)
    local rank_type = msg.rank_type
    local rank_id = msg.rank_id
    local uid = msg.uid
    return RankLogic.GetRankInfo(rank_type, rank_id, uid)
end

function RankMgr.GetRankReward(msg)
    local rank_type = msg.rank_type
    local uid = msg.uid
    -- local period = msg.period
    return RankLogic.GetRankReward(rank_type, uid)
end

function RankMgr.GetUnclaimedRewards(msg)
    local uid = msg.uid
    return RankLogic.GetUnclaimedRewards(uid)
end

function RankMgr.SendRankRewardMail(msg)
    local uid = msg.uid
    local rank_type = msg.rank_type
    local period = msg.period
    local reward_id = msg.reward_id
    local rank = msg.rank
    return RankLogic.SendRewardMailToPlayer(uid, rank_type, period, reward_id, rank)
end

function RankMgr.UpdatePlayerInfo(msg)
    local uid = msg.uid
    local info = msg.info
    return RankLogic.EnqueuePlayerInfoUpdate(uid, info)
end

-- 判断是否是新的刷新分钟（用于测试）
local function isNewRefreshTime(lastTime)
    local currentTime = moon.time()
    -- 如果当前时间比上次刷新时间晚5分钟以上，返回true
    if currentTime - lastTime >= 300 then  -- 300秒 = 5分钟
        return true
    end
    return false
end

-- 判断是否是新的一周（周一0点后）
local function isNewWeek(lastTime)
    local t1 = os.date("*t", lastTime)
    local t2 = os.date("*t", moon.time())

    -- 简化但有效的判断：如果超过7天，或者年份不同，或者同一年份但天数差>=7
    if t2.year > t1.year then
        return true
    elseif t2.year < t1.year then
        return false
    else
        -- 同一年
        if t2.yday - t1.yday >= 7 then
            return true
        end

        -- 如果当前是周一，或者天数差大于当前是周几
        -- 比如上次是周日（wday=1），今天是周一（wday=2）：应该刷新
        -- 或者上次是周二，今天是周一（跨周了）
        local daysDiff = t2.yday - t1.yday
        if daysDiff > 0 and (t2.wday == 2 or (daysDiff >= (8 - t1.wday) or t2.wday < t1.wday)) then
            return true
        end
    end

    return false
end

-- 判断是否是新的一月（1号0点后）
local function isNewMonth(lastTime)
    local t1 = os.date("*t", lastTime)
    local t2 = os.date("*t", moon.time())

    if t2.year > t1.year then return true end
    if t2.year < t1.year then return false end
    if t2.month > t1.month then return true end
    if t2.month < t1.month then return false end

    -- 同一年同一月，看是否跨了1号
    return t2.day ~= t1.day and t2.day == 1
end

-- 判断是否是新的一天（0点后）
local function isNewDay(lastTime)
    local t1 = os.date("*t", lastTime)
    local t2 = os.date("*t", moon.time())

    if t2.year > t1.year then return true end
    if t2.year < t1.year then return false end
    if t2.month > t1.month then return true end
    if t2.month < t1.month then return false end

    return t2.day ~= t1.day
end

-- 每周刷新的排行榜
local weeklyRanks = {
    RankDef.RankType.Duanwei_Weekly,
    RankDef.RankType.Mainline,
    RankDef.RankType.Fengta,
    RankDef.RankType.Fadian_Weekly,
    RankDef.RankType.Antique,
    RankDef.RankType.Player,
    RankDef.RankType.Role,
}

-- 每月刷新的排行榜
local monthlyRanks = {
    RankDef.RankType.Fadian_Monthly,
}

-- 记录上次刷新时间
local lastRefreshWeek = moon.time()
local lastRefreshMonth = moon.time()
local lastRefreshDay = moon.time()

function RankMgr.setupRefreshTasks()
    -- 每周刷新任务（现为了做测试暂时改为每天刷新）
    moon.async(function()
        while true do
            moon.sleep(30000) -- 30秒检测一次
            if isNewDay(lastRefreshDay) then
                moon.info(string.format("[RankMgr] Daily rank refresh triggered"))
                for _, rank_type in ipairs(weeklyRanks) do
                    RankLogic.RefreshRankData(rank_type)
                end
                moon.info(string.format("[RankMgr] Daily rank refresh completed"))
                lastRefreshDay = moon.time()
            end
        end
    end)

    -- 每月刷新任务（每5分钟检查一次是否到了新的一月）
    moon.async(function()
        while true do
            moon.sleep(30000) -- 30秒检测一次
            if isNewMonth(lastRefreshMonth) then
                moon.info(string.format("[RankMgr] Monthly rank refresh triggered"))
                for _, rank_type in ipairs(monthlyRanks) do
                    RankLogic.RefreshRankData(rank_type)
                end
                lastRefreshMonth = moon.time()
            end
        end
    end)
end

function RankMgr.setupSyncTasks()
    moon.async(function()
        while true do
            moon.sleep(60000)
            RankLogic.SaveAllRankDataToRedis()
        end
    end)
end

-- 刷新赛季排行榜（赛季段位榜和宗门赛季积分榜）
function RankMgr.RefreshSeasonRanks()
    moon.info("[RankMgr] RefreshSeasonRanks triggered")

    local seasonRanks = {
        RankDef.RankType.Duanwei_Season,     -- 赛季段位榜
        RankDef.RankType.GuildScore_Season,  -- 宗门赛季积分榜
    }

    for _, rank_type in ipairs(seasonRanks) do
        moon.info(string.format("[RankMgr] Refreshing season rank: %d", rank_type))
        RankLogic.RefreshRankData(rank_type)
    end

    moon.info("[RankMgr] Season ranks refresh completed")
    return true
end

function RankMgr.Start()
    moon.info("RankMgr started")
    return true
end

return RankMgr