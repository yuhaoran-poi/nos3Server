local moon = require("moon")
local json = require("json")
local common = require("common")
local ErrorCode = common.ErrorCode
local Database = common.Database

local RankLogic = require("common.logic.RankLogic")
local RankDef = require("common.def.RankDef")

---@type rank_context
local context = ...

---@class RankMgr
local RankMgr = {}

-- 记录上次刷新时间(启动时从Redis恢复, 避免跨周/跨月重启后漏刷)
local lastRefreshWeek
local lastRefreshMonth
local lastRefreshDay = moon.time()

-- 周/月刷新标记在Redis中的持久化key
local RANK_REFRESH_MARK_KEY = "rank:refresh_mark"

-- 从Redis恢复周/月刷新标记
local function loadRefreshMark()
    local addr_db = moon.queryservice("db_server")
    if not addr_db or addr_db == 0 then
        return nil
    end

    local res, mark_json = pcall(Database.loadserverdata_with_key, addr_db, RANK_REFRESH_MARK_KEY)
    if not res or not mark_json or mark_json == "" then
        return nil
    end

    local ok, mark = pcall(json.decode, mark_json)
    if not ok or type(mark) ~= "table" then
        moon.error("[RankMgr] Failed to decode rank refresh mark")
        return nil
    end
    return mark
end

-- 周期刷新完成后持久化刷新标记
local function saveRefreshMark()
    local addr_db = moon.queryservice("db_server")
    if not addr_db or addr_db == 0 then
        return
    end

    local mark = { week = lastRefreshWeek, month = lastRefreshMonth }
    local res, err = pcall(Database.saveserverdata_with_key, addr_db, RANK_REFRESH_MARK_KEY, json.encode(mark))
    if not res then
        moon.error("[RankMgr] Save rank refresh mark failed:", err)
    end
end

function RankMgr.Init()
    context.addr_db_server = moon.queryservice("db_server")
    context.addr_db_user = moon.queryservice("db_user")
    context.addr_db_redis = moon.queryservice("db_redis")
    context.addr_db_log = moon.queryservice("db_log")

    RankLogic.Init(context)
    RankLogic.StartQueueProcessor()

    -- 恢复刷新标记: 若停服跨越了周/月边界, 重启后30秒内即可补刷, 不会整周漏刷
    local mark = loadRefreshMark()
    lastRefreshWeek = tonumber(mark and mark.week) or moon.time()
    lastRefreshMonth = tonumber(mark and mark.month) or moon.time()
    moon.info(string.format("[RankMgr] Refresh mark restored: week=%s, month=%s",
        tostring(lastRefreshWeek), tostring(lastRefreshMonth)))

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

-- 确认领取奖励(两段式第二段: 游戏侧入包成功后调用)
function RankMgr.ConfirmRankReward(msg)
    return RankLogic.ConfirmRankReward(msg.rank_type, msg.uid)
end

-- 取消领取奖励(两段式回滚: 游戏侧入包失败时调用)
function RankMgr.CancelRankRewardClaim(msg)
    return RankLogic.CancelRankRewardClaim(msg.rank_type, msg.uid)
end

function RankMgr.GetUnclaimedRewards(msg)
    local uid = msg.uid
    return RankLogic.GetUnclaimedRewards(uid)
end

function RankMgr.CheckAndSendUnclaimedRewards(msg)
    local uid = msg.uid
    return RankLogic.CheckAndSendUnclaimedRewards(uid)
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

function RankMgr.setupRefreshTasks()
    -- 每周刷新任务（现为了做测试暂时改为每天刷新）
    moon.async(function()
        while true do
            moon.sleep(30000) -- 30秒检测一次
            if isNewWeek(lastRefreshWeek) then
                moon.info(string.format("[RankMgr] Weekly rank refresh triggered"))
                for _, rank_type in ipairs(weeklyRanks) do
                    RankLogic.RefreshRankData(rank_type)
                end
                moon.info(string.format("[RankMgr] Weekly rank refresh completed"))
                lastRefreshWeek = moon.time()
                saveRefreshMark()
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
                saveRefreshMark()
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