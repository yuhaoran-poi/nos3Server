--require("common.LuaPanda").start("127.0.0.1", 8818)
local moon = require("moon")
local common = require("common")
local RankLogic = require("common.logic.RankLogic")
local RankDef = require("common.def.RankDef")
local ErrorCode = common.ErrorCode

local conf = ...

---@class rank_context:base_context
local context = {
    conf = conf,
    scripts = {},
    addr_gate = moon.queryservice("gate"),
    addr_auth = moon.queryservice("auth"),
    addr_center = moon.queryservice("center"),
    addr_db_user = moon.queryservice("db_user"),
    addr_db_server = moon.queryservice("db_server"),
    addr_db_openid = moon.queryservice("db_openid"),
    addr_mail = moon.queryservice("mail"),
    addr_dgate = moon.queryservice("dgate"),
    addr_rank = moon.queryservice("rank"),
}

local rank_service = {}

function rank_service.Init()
    -- 初始化排行榜
    RankLogic.Init()

    -- 启动排行榜更新队列处理器（定时批量处理）
    RankLogic.StartQueueProcessor()

    -- 设置定时刷新任务
    rank_service.setupRefreshTasks()

    -- 设置定时同步到Redis的任务
    rank_service.setupSyncTasks()

    print("Rank service initialized")
    return true
end

function rank_service.Start()
    print("Rank service started")
    return true
end

function rank_service.setupRefreshTasks()
    -- 每日刷新任务
    moon.async(function()
        while true do
            local now = moon.time()
            local next_day = math.floor(now / 86400) * 86400 + 86400
            local sleep_time = next_day - now
            moon.sleep(sleep_time * 1000)
            print("Daily ranks refreshed - now_time:", moon.time())

            -- 刷新每日排行榜
            rank_service.refreshDailyRanks()
        end
    end)

    -- 每周刷新任务
    moon.async(function()
        while true do
            local now = moon.time()
            local next_week = math.floor(now / 604800) * 604800 + 604800
            local sleep_time = next_week - now
            moon.sleep(sleep_time * 1000)
            print("Weekly ranks refreshed - now_time:", moon.time())

            -- 刷新每周排行榜
            rank_service.refreshWeeklyRanks()
        end
    end)

    -- 每月刷新任务
    moon.async(function()
        while true do
            local now = moon.time()
            local next_month = rank_service.getNextMonthTime(now)
            local sleep_time = next_month - now
            moon.sleep(sleep_time * 1000)
            print("Monthly ranks refreshed - now_time:", moon.time())

            -- 刷新每月排行榜
            rank_service.refreshMonthlyRanks()
        end
    end)
end

function rank_service.getNextMonthTime(timestamp)
    local date = os.date("*t", timestamp)
    date.month = date.month + 1
    if date.month > 12 then
        date.month = 1
        date.year = date.year + 1
    end
    return os.time(date)
end

function rank_service.refreshDailyRanks()
    -- 刷新每日排行榜
    RankLogic.RefreshRankData(RankDef.RankType.Antique)
    print("Daily ranks refreshed")
end

function rank_service.refreshWeeklyRanks()
    -- 刷新每周排行榜
    RankLogic.RefreshRankData(RankDef.RankType.Duanwei_Weekly)
    RankLogic.RefreshRankData(RankDef.RankType.Mainline)
    RankLogic.RefreshRankData(RankDef.RankType.Fengta)
    RankLogic.RefreshRankData(RankDef.RankType.Fadian_Weekly)
    RankLogic.RefreshRankData(RankDef.RankType.GuildActive)
    RankLogic.RefreshRankData(RankDef.RankType.GuildMoney)
    RankLogic.RefreshRankData(RankDef.RankType.GuildScore_Weekly)

    print("Weekly ranks refreshed")
end

function rank_service.refreshMonthlyRanks()
    -- 刷新每月排行榜
    RankLogic.RefreshRankData(RankDef.RankType.Fadian_Monthly)

    print("Monthly ranks refreshed")
end

-- 刷新赛季排行榜
function rank_service.refreshSeasonRanks()
    -- 刷新赛季排行榜
    RankLogic.RefreshRankData(RankDef.RankType.Duanwei_Season)
    RankLogic.RefreshRankData(RankDef.RankType.GuildScore_Season)

    print("Season ranks refreshed")
end

-- 设置定时同步到Redis的任务
function rank_service.setupSyncTasks()
    -- 每5分钟同步一次所有排行榜数据到Redis
    moon.async(function()
        while true do
            moon.sleep(60000) -- 5分钟 = 300000毫秒(为方便测试 暂时设置为60s)
            rank_service.syncAllRanksToRedis()
        end
    end)
end

-- 同步所有排行榜数据到Redis
function rank_service.syncAllRanksToRedis()
    -- 遍历 RankDef.RankType 表的值，而不是键
    for _, rank_type in pairs(RankDef.RankType) do
        local res = RankLogic.SaveRankDataToRedis(rank_type)
        if res ~= ErrorCode.None then
            moon.error("Sync rank data to redis failed for rank_type:", rank_type)
        end
    end
    print("All ranks synced to redis")
end

-- 合并流动榜
function rank_service.mergeFlowRanks(rank_type)
    return RankLogic.MergeFlowRanks(rank_type)
end

-- 获取排行榜数据
function rank_service.getRankData(rank_type, rank_id)
    return RankLogic.GetRankData(rank_type, rank_id)
end

-- 处理玩家上榜
function rank_service.handlePlayerRankUpdate(rank_type, uid, player_data, force)
    return RankLogic.UpdatePlayerRank(rank_type, uid, player_data, force)
end

-- 玩家领取排行榜奖励
function rank_service.getRankReward(rank_type, uid)
    return RankLogic.GetRankReward(rank_type, uid)
end

-- 注册命令
local command = {}

command.Init = rank_service.Init
command.Start = rank_service.Start
command.mergeFlowRanks = rank_service.mergeFlowRanks
command.getRankData = rank_service.getRankData
command.handlePlayerRankUpdate = rank_service.handlePlayerRankUpdate
command.getRankReward = rank_service.getRankReward

-- 处理 Lua 消息
moon.dispatch("lua", function(sender, session, cmd, ...)
    local fn = command[cmd]
    if fn then
        if session ~= 0 then
            moon.response("lua", sender, session, fn(...))
        else
            fn(...)
        end
    else
        moon.error("rank service recv unknown cmd " .. tostring(cmd))
    end
end)

-- 服务已通过 main_game.lua 配置启动

moon.shutdown(function()
    moon.quit()
end)