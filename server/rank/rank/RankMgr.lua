local moon = require("moon")
local json = require("json")
local common = require("common")
local ErrorCode = common.ErrorCode
local Database = common.Database

local RankLogic = require("common.logic.RankLogic")
local RankDef = require("common.def.RankDef")
local GameCfg = common.GameCfg

---@type rank_context
local context = ...

---@class RankMgr
local RankMgr = {}

-- 榜实例清单由配置表驱动(static/table/RankBoard.lua), 旧14榜已屏蔽不再刷新
-- window: 1=周榜(周一刷新) 2=总榜(赛季结束刷新)
-- 注意: 必须定义在所有使用它的函数(RankMgr.TestRefreshRanks/RefreshSeasonRanks/setupRefreshTasks)之前
local function getBoardRankTypes(window)
    local list = {}
    if GameCfg.RankBoard then
        for rank_type, cfg in pairs(GameCfg.RankBoard) do
            if cfg.window == window then
                table.insert(list, rank_type)
            end
        end
    end
    table.sort(list)
    return list
end

-- 记录上次刷新时间(启动时从Redis恢复, 避免跨周重启后漏刷)
local lastRefreshWeek
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

    local mark = { week = lastRefreshWeek }
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

    -- 恢复刷新标记: 若停服跨越了周边界, 重启后30秒内即可补刷, 不会整周漏刷
    local mark = loadRefreshMark()
    lastRefreshWeek = tonumber(mark and mark.week) or moon.time()
    moon.info(string.format("[RankMgr] Refresh mark restored: week=%s",
        tostring(lastRefreshWeek)))

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

-- (旧单榜领奖与邮件转发 GetRankReward/ConfirmRankReward/CancelRankRewardClaim/
--  GetUnclaimedRewards/CheckAndSendUnclaimedRewards/SendRankRewardMail 已删除,
--  新三榜统一走 GetBoardReward/ConfirmBoardReward/CancelBoardRewardClaim, 见下方)

-- 新三榜: 按一级标签聚合领奖(两段式第一段, 取该标签下全部子榜最优名次档位)
function RankMgr.GetBoardReward(msg)
    return RankLogic.GetBoardReward(msg.category, msg.uid)
end

-- 新三榜: 确认领取(从该标签下全部子榜快照移除玩家)
function RankMgr.ConfirmBoardReward(msg)
    return RankLogic.ConfirmBoardReward(msg.category, msg.uid)
end

-- 新三榜: 取消领取(两段式回滚)
function RankMgr.CancelBoardRewardClaim(msg)
    return RankLogic.CancelBoardRewardClaim(msg.category, msg.uid)
end

-- 新三榜: 查询上期锁榜排名(领奖弹窗展示)
function RankMgr.GetBoardHistory(msg)
    return RankLogic.GetBoardHistory(msg.category, msg.uid)
end

-- 测试命令: 触发指定窗口全部榜实例刷新(快照+清空, 等价锁榜), 测试环境用
function RankMgr.TestRefreshRanks(msg)
    local window = tonumber(msg.window) or 1
    moon.info(string.format("[RankMgr] TestRefreshRanks: window=%d", window))
    for _, rank_type in ipairs(getBoardRankTypes(window)) do
        RankLogic.RefreshRankData(rank_type)
    end
    return ErrorCode.None
end

-- 测试命令: 清空全部榜实例数据与Redis键(测试幂等用)
function RankMgr.TestClearBoards(msg)
    moon.info("[RankMgr] TestClearBoards")
    local boards = GameCfg.RankBoard
    if not boards then
        return ErrorCode.None
    end
    for rank_type, _ in pairs(boards) do
        RankLogic.ClearBoard(rank_type)
    end
    return ErrorCode.None
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

-- (getBoardRankTypes 已上移至文件头部: TestRefreshRanks 等前部函数需要引用,
--  local 定义晚于调用函数时为nil全局, 曾导致刷新抛错不生效)

function RankMgr.setupRefreshTasks()
    -- 周榜刷新(周一0点后, 30秒轮询检测; 快照即锁榜结果, 保留一期)
    moon.async(function()
        while true do
            moon.sleep(30000) -- 30秒检测一次
            if isNewWeek(lastRefreshWeek) then
                moon.info(string.format("[RankMgr] Weekly rank refresh triggered"))
                for _, rank_type in ipairs(getBoardRankTypes(1)) do
                    RankLogic.RefreshRankData(rank_type)
                end
                moon.info(string.format("[RankMgr] Weekly rank refresh completed"))
                lastRefreshWeek = moon.time()
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

-- 刷新赛季总榜(Seasonmgr赛季结束时触发; 榜单=RankBoard中window=2的榜实例)
function RankMgr.RefreshSeasonRanks()
    moon.info("[RankMgr] RefreshSeasonRanks triggered")

    for _, rank_type in ipairs(getBoardRankTypes(2)) do
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