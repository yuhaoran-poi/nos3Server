--[[
周天轮转(门票流转) 活动定义
需求: 《驱灵天师》周天轮转(门票流转)系统策划案 V1.3

活动/积分/轮换配置已接入策划表 GameCfg.WeekRotation(见 static/table/WeekRotation.lua):
    id / activity_type / bind_mode / cycle_week / max_round / full_score
    tier_scores(各档积分线) / tier_rewards(各档宝箱数) / rewards_id(宝箱道具ID)
    chapterid(可计分章节列表) / difficulty1~5 + score1~5(难度组→积分)
    轮换配对由 cycle_week × activity_type 推导, 轮次上限取每行 max_round。
本文件仅保留运行参数(切换时刻/锚点)与玩家数据结构定义。
]]

local LuaExt = require "common.LuaExt"

local WeekRotationDef = {}

-- 活动类型(案子2.1)
WeekRotationDef.ActivityType = {
    MAINLINE = 1,   -- 主线活动(7001/7002/7003)
    SUB_MODE = 2,   -- 副模式活动(7004/7005/7006)
}

-- 绑定模式(策划表 bind_mode 编号, chapterid缺省时的降级章节段见 MODE_CHAPTER_RANGE)
WeekRotationDef.BindMode = {
    MAINLINE = 1,       -- 主线   章节段 1~1000
    GUIWANG  = 2,       -- 鬼王入侵 章节段 2001~3000
    FENGTA   = 3,       -- 封魔塔 章节段 3001~4000
    GUILMEN  = 4,       -- 鬼门关 章节段 1001~2000
}

WeekRotationDef.MODE_CHAPTER_RANGE = {
    [WeekRotationDef.BindMode.MAINLINE] = { 1, 1000 },
    [WeekRotationDef.BindMode.GUIWANG]  = { 2001, 3000 },
    [WeekRotationDef.BindMode.FENGTA]   = { 3001, 4000 },
    [WeekRotationDef.BindMode.GUILMEN]  = { 1001, 2000 },
}

-- 掉落表说明: 宝箱开启复用现有道具使用链路(PBUseItemReqCmd use_type=6随机礼包),
-- 策划在Item表为宝箱道具(rewards_id)配置 use_award/award_weight/award_count(案子10.3的掉落数值),
-- 80:20票种分流拍平为两行权重即可(数学等价), 本模块不单独维护掉落表

-- 运行参数(非策划数值表, 属服务器运营参数)
local Config = {
    -- P02 活动切换时刻: 每周三 06:00(从凌晨起算的秒数偏移, 2026-11 策划由05:00改为06:00)
    SWITCH_HOUR_OFFSET = 6 * 3600,
    -- 周期锚点(上线开启时间)已由策划表 WeekRotation.open_time 承载(约定只填周期第1周主活动行, 如7001),
    -- 表未配置时活动整体静默。⚠️ 上线后不可再改, 改动 = 全员周期错位触发一次数据重置
}

-- 玩家单活动数据
---@class WeekRotationData
---@field activity_id integer 活动ID(7001~7006)
---@field score integer 当前轮积分(每轮清零, 案子2.5)
---@field round integer 当前轮次(1起)
---@field locked integer 达轮次上限锁定标记(案子2.6)
---@field claimed_tiers table<integer, integer> 已领档位 {[tier]=1}
local defaultWeekRotationData = {
    activity_id = 0,
    score = 0,            -- 当前轮积分(每轮清零, 案子2.5)
    round = 1,            -- 当前轮次(1起)
    locked = 0,           -- 达轮次上限后锁定(案子2.6)
    claimed_tiers = {},   -- 已领档位 { [tier]=1 }
}

-- 玩家周活动总数据(存储于 mgame.weekrotations 表 json 列, 服务器私有结构不走网络)
---@class WeekRotationPlayerData
---@field uid integer
---@field data_key integer 数据归属的全局周序号(0起), 跨周即重置(案子2.9)
---@field remind_key string 结束前1小时提醒去重(全局周序号字符串)
---@field activities table<integer, WeekRotationData> {[activity_id]=WeekRotationData}
local defaultWeekRotationPlayerData = {
    uid = 0,
    data_key = -1,        -- 数据归属的全局周序号(0起), 跨周即重置(案子2.9)
    remind_key = "",      -- 结束前1小时提醒去重(全局周序号字符串)
    activities = {},      -- { [activity_id] = defaultWeekRotationData }
}

---@return WeekRotationData
function WeekRotationDef.newActivityData(activity_id)
    local t = LuaExt.const(table.copy(defaultWeekRotationData))
    t.activity_id = activity_id
    return t
end

---@return WeekRotationPlayerData
function WeekRotationDef.newPlayerData()
    return LuaExt.const(table.copy(defaultWeekRotationPlayerData))
end

-- 导出
WeekRotationDef.Config = Config

return WeekRotationDef
