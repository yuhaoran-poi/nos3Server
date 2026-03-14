local moon = require("moon")
local json = require("json")
local common = require("common")
local Database = common.Database
local ErrorCode = common.ErrorCode
local CmdCode = common.CmdCode

---@type user_context
local context = ...
local scripts = context.scripts

-- 最小可用的成就定义（如后续接表，可改为从 DB/表加载）
-- target_event: 事件名；target_value: 目标值；reward: 简化的奖励定义（示例）
local ACHIEVEMENT_DEFS = {
    [1001] = { name = "初来乍到",  desc = "完成首次登录",      target_event = "login_times",  target_value = 1,  reward = { coins = { [1000001] = 100 } } },
    [1002] = { name = "勤劳玩家",  desc = "累积在线10分钟",   target_event = "online_minutes", target_value = 10, reward = { coins = { [1000001] = 300 } } },
    [1003] = { name = "交易入门",  desc = "完成首次交易",      target_event = "trade_times",  target_value = 1,  reward = { coins = { [1000002] = 1 } } },
}

-- 用户成就数据，结构：
-- user_ach = {
--   [achievement_id] = { progress = number, status = 0|1|2 },
-- }
local user_ach = {}

local M = {}

local function _upsert(uid, achievement_id, progress, status)
    local sql = string.format([[
        INSERT INTO mgame.user_achievements (uid, achievement_id, progress, status)
        VALUES (%d, %d, %d, %d)
        ON DUPLICATE KEY UPDATE progress = %d, status = %d;
    ]], uid, achievement_id, progress, status, progress, status)
    return moon.call("lua", context.addr_db_user, sql)
end

local function _load(uid)
    local sql = string.format([[
        SELECT achievement_id, progress, status
        FROM mgame.user_achievements
        WHERE uid = %d;
    ]], uid)
    local res, err = moon.call("lua", context.addr_db_user, sql)
    if err then
        moon.error("load user_achievements failed ", uid, err)
        return
    end
    user_ach = {}
    if res and #res > 0 then
        for _, row in ipairs(res) do
            user_ach[row.achievement_id] = {
                progress = tonumber(row.progress) or 0,
                status = tonumber(row.status) or 0,
            }
        end
    end
end

local function _save_all(uid)
    for ach_id, v in pairs(user_ach) do
        _upsert(uid, ach_id, v.progress or 0, v.status or 0)
    end
end

local function _calc_status(ach_id, progress)
    local def = ACHIEVEMENT_DEFS[ach_id]
    if not def then return 0 end
    if progress >= def.target_value then
        -- 1=达成可领奖；若之前已经领取过则保持2
        local cur = user_ach[ach_id]
        if cur and cur.status == 2 then
            return 2
        end
        return 1
    end
    return 0
end

-- 公开：事件进度累加
-- event_name: 字符串（如 "login_times"）; delta: number
function M.AddProgress(event_name, delta)
    if not delta or delta == 0 then return end
    for ach_id, def in pairs(ACHIEVEMENT_DEFS) do
        if def.target_event == event_name then
            local node = user_ach[ach_id]
            if not node then
                node = { progress = 0, status = 0 }
                user_ach[ach_id] = node
            end
            node.progress = math.max(0, (node.progress or 0) + delta)
            node.status = _calc_status(ach_id, node.progress)
        end
    end
end

-- 公开：查询成就列表（内部命令可调用）
function M.GetAchievements(req)
    local list = {}
    for ach_id, def in pairs(ACHIEVEMENT_DEFS) do
        local node = user_ach[ach_id] or { progress = 0, status = 0 }
        table.insert(list, {
            achievement_id = ach_id,
            name = def.name,
            desc = def.desc,
            progress = node.progress,
            target = def.target_value,
            status = node.status,
        })
    end
    return { code = 0, achievements = list }
end
function M.GetAchievementsCmd(req) return M.GetAchievements(req) end

-- 公开：领取成就奖励（内部命令可调用）
-- msg: { achievement_id = number }
function M.ClaimAchievement(req)
    local ach_id = req.msg and req.msg.achievement_id or 0
    if not ACHIEVEMENT_DEFS[ach_id] then
        return { code = ErrorCode.ParamInvalid or 1, error = "成就不存在" }
    end
    local node = user_ach[ach_id]
    if not node or node.status ~= 1 then
        return { code = ErrorCode.ParamInvalid or 2, error = "不可领取" }
    end
    -- 发放奖励（最小实现：仅金币/货币示例，接入背包/货币模块可扩展）
    local reward = ACHIEVEMENT_DEFS[ach_id].reward or {}
    local coins = reward.coins or {}
    if next(coins) ~= nil then
        -- 若系统已有 coins 模块，可在此接入；当前仅返回数据
    end
    -- 标记已领取
    node.status = 2
    _upsert(context.uid, ach_id, node.progress or 0, node.status)
    return { code = ErrorCode.None or 0, error = "", reward = reward }
end
function M.ClaimAchievementCmd(req) return M.ClaimAchievement(req) end

-- 生命周期钩子：用户模块装载时调用
function M.Init(isnew)
    if not context.uid or context.uid == 0 then
        return true
    end
    _load(context.uid)
    -- 新用户可在此插入默认记录（此处不强制）
    return true
end

function M.Start(isnew)
    return true
end

function M.Online()
    -- 示例：登录即累计一次
    M.AddProgress("login_times", 1)
    _save_all(context.uid)
end

function M.Offline()
    _save_all(context.uid)
end

function M.Exit()
    _save_all(context.uid)
end

return M


