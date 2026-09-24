local LuaExt = require "common.LuaExt"

local MissionDef = {
    ETaskState = {
        NO_PROGRESS = 0, -- 未领取
        NO_COMPLETE = 1, -- 未完成
        COMPLETE = 2,    -- 已完成
        GET_REWARD = 3,  -- 已领取奖励
    },
    EVitalityType = {
        Achievement = 1,    -- 成就点(成就任务)
        Linear = 2,         -- 线性任务活跃点(未开通)
        PeriodDay = 3,      -- 每日活跃点(领每日任务奖励累计,每日重置)
        PeriodWeek = 4,     -- 每周活跃点(领每日+每周任务奖励累计,每周重置)
        ActivityBase = 1000, -- 活动活跃点基址: 实际type = ActivityBase + 活动类型id(ActivityMissionTypeConfig表id)
    },
    EConditionIds = {
        SIGN_CNT = 1,   -- 签到次数
        ONLINE_TIME = 2, -- 在线时间
        ACTIVITY_CNT = 3, -- 累计活跃度
        ACCOUNT_LEVEL = 4, -- 账户达到等级
        OUT_TASK_CNT = 5,  -- 累计完成局外任务次数
        IN_TASK_CNT = 6,   -- 累计完成局内任务次数
        KILL_MONSTER_CNT = 7, -- 累计击杀怪物数量
        GET_ITEM_CNT = 8,     -- 累计从X渠道中获得道具数量
        UNLOCK_ROLE_SKIN_CNT = 9,  -- 累计解锁角色皮肤数量
        UNLOCK_ROLE_SKIN = 10,      -- 解锁指定角色皮肤
        UNLOCK_ROLE_CNT = 11, -- 累计解锁角色数量
        UNLOCK_ROLE = 12,     -- 解锁指定角色
        BATTLE_CHAPTER_CNT = 13, -- 完成副本章节次数
        RECHARGE_CNT = 14,       -- 充值金额
        GET_TREASURE_CNT = 15,   -- 累计获得宝箱数量
        OPEN_TREASURE_CNT = 16,  -- 累计开启宝箱数量
        LIGHT_EQP_CNT = 17,      -- 开光X品质Y类型装备次数
        APPRAISE_ANTIQUE_CNT = 18, -- 鉴定X品质Y类型古董次数
        ROLE_STAR_CNT = 22,        -- 角色达到X星级的数量
        ROLE_LEVEL_CNT = 23,        -- 角色达到X等级的数量
        ROLE_STAR = 24,             -- 某角色达到星级
        ROLE_LEVEL = 25,            -- 某角色达到等级
        ROLE_UNLOCK_SKILL_CNT = 26, -- 角色已解锁技能数量
        ROLE_UNLOCK_SKILL = 27,     -- X角色已解锁Y技能次数
        ROLE_EQUIP_MAGIC_ITEM_CNT = 28, -- X角色装备Y品质法器数量
        INLAY_TABOO_WORD_CNT = 29,  -- 镶嵌X品质Y讳字的次数
        SHOW_ANTIQUE_CNT = 30,      -- 展示品质Z古董的数量
        UNLOCK_GOD_CNT = 31,        -- 解锁神明次数
        UNLOCK_GOD = 32,            -- 解锁指定神明次数
        GOD_LEVEL = 33,             -- 某神明达到等级
        GOD_ENTER_BATTLE_CNT = 34,  -- 装备X神明进入战斗次数
        MAKE_ITEM_CNT = 35,         -- 只做X品质Y类型Z道具的次数
        CONSUME_ITEM_CNT = 36,      -- 通过X渠道消耗Y类型Z道具的次数
        GET_LINGBI_COIN_CNT = 37,   -- 累计获得灵币数量(coin_id=1,任何渠道入账均计入)
        GET_BOOTY_VALUE_CNT = 38,   -- 累计从X章节Y难度获得战利品价值
        UNLOCK_ITEM_SKIN_CNT = 39,  -- 累计解锁道具皮肤数量
        TOTAL_RECHARGE_CNT = 40,    -- 累计充值金额
        ACHIEVEMENT_CNT = 41,           -- 累计完成成就次数
        ROLE_EQUIP_DIAGRAMS_CNT = 42,   -- X角色装备Y品质八卦牌数量
        CONTINUE_SIGN_CNT = 43,          -- 连续签到次数（每日限一次，断签重置）
        BATTLE_FINISH_CNT = 44,          -- 对局完成次数
        SUCCESS_LEAVE_CNT = 45,          -- 成功撤离次数
        CLEAR_KILL_CNT = 46,             -- 通关X章节并击杀Y类型Z怪物次数
        TOTAL_FAIL_CNT = 47,             -- 累计失败次数
        TEAM_BATTLE_FINISH_CNT = 48,     -- 组队对局完成次数
        SINGLE_DAMAGE_REACH = 49,        -- 单局伤害总量达到阈值
        TOTAL_DAMAGE = 50,               -- 累计局内伤害总量
        SINGLE_HEAL_REACH = 51,          -- 单局治疗总量达到阈值
        TOTAL_HEAL = 52,                 -- 累计局内治疗总量
        OPEN_CONTAINER_CNT = 53,         -- 局内开启X类型Y品质容器数量
        TOTAL_OPEN_CONTAINER_CNT = 54,   -- 累计开启X类型Y品质容器数量
        FALL_LIMIT_CNT = 55,             -- 本局倒地次数不超过param1计1次
        TOTAL_FALL_CNT = 56,             -- 累计倒地次数
        TOTAL_RESCUE_CNT = 57,           -- 累计救人次数
        TOTAL_GAME_TIME = 58,            -- 累计游戏时长
        CLEAR_TIME_LIMIT = 59,           -- 通关param_arr章节(0=任意)且完美通关(param2=1时要求)且时长<=param1秒的次数(仅统计成功通关的对局时长)
        BRING_OUT_ITEM_CNT = 60,         -- 单局带出X类型Y品质材料数量
        TOTAL_BRING_OUT_ITEM_CNT = 61,   -- 累计带出X类型Y品质材料数量
        SPECIFY_ROLE_BATTLE_CNT = 62,    -- 指定X角色完成对局次数
        BATTLE_WEIGHT_LOAD = 63,         -- 单局负重使用量
        TRADE_HOUSE_EARN = 64,           -- 交易行收益金额
        TRADE_HOUSE_SHELF_CNT = 65,      -- 交易行上架数量
        TOTAL_ACCOUNT_EXP = 66,          -- 累计获取账户经验
        TOTAL_ROLE_EXP = 67,             -- 累计获取角色经验
        TOTAL_GRADE_SCORE = 68,          -- 累计获取段位积分
        SINGLE_IN_TASK_CNT = 69,         -- 单局完成局内任务数量
        SINGLE_KILL_MONSTER_CNT = 70,    -- 单局击杀X类型Y怪物数量
        SINGLE_GET_ITEM_CNT = 71,        -- 单局从X来源获得Y类型Z道具/货币数量
        SINGLE_BOOTY_VALUE_CNT = 72,     -- 单局从X章节Y难度带出Z价值战利品
        UNLOCK_SKIN_CNT = 73,            -- 累积解锁X类型皮肤总数
        STRENGTHEN_EQP_CNT = 74,         -- 强化X品质Y类型装备次数
        EQP_MAX_LEVEL = 75,              -- X品质Y类型装备最高等级
        UPSTAR_EQP_CNT = 76,             -- 升星X品质Y类型装备次数
        EQP_MAX_STAR = 77,               -- X品质Y类型装备最高星级
        SKILL_MAX_LEVEL = 78,            -- X角色Y技能最高等级
        SKILL_MAX_STAR = 79,             -- X角色Y技能最高星级
        ROLE_MAX_LEVEL = 80,             -- X角色最高等级
        ROLE_MAX_STAR = 81,              -- X角色最高星级
        APPRAISE_SUCCESS_CNT = 82,       -- 成功鉴定X品质古董次数
        PERFECT_CLEAR_CNT = 83,          -- 主线模式击杀鬼王并完成结算，没有失败也没有撤离计1次（限定主线模式+击杀鬼王）
        MAIN_TASK_COMPLETE_CNT = 84,     -- 累计完成主线任务次数（结算时该局完成主线计1次）
        SUB_TASK_COMPLETE_CNT = 85,      -- 累计完成支线任务次数（结算时累加该局支线任务完成数量）
        HISTORY_MAX_GRADE_SCORE = 86,    -- 账户历史最高段位积分（各赛季单赛季最高分的最大值，覆盖型）
        GAME_COLLECT_ITEM_CNT = 87,      -- 累计收集局内指定道具数量（param1类型0不限; param2局内道具id）
        GAME_CONSUME_ITEM_CNT = 88,      -- 累计消耗局内指定道具数量（param1类型0不限; param2局内道具id）
        DAILY_TASK_COMPLETE_CNT = 89,    -- 累计完成日常任务次数（每完成一个每日任务计1次）
        WEEKLY_TASK_COMPLETE_CNT = 90,   -- 累计完成周常任务次数（每完成一个每周任务计1次）
        TEAM_KILL_MONSTER_CNT = 91,      -- 组队击杀X类型Y怪物数量（param1怪物类型0不限; param2怪物id 0不限; 仅队伍人数>=2统计）
        TEAM_BATTLE_CHAPTER_CNT = 92,    -- 组队完成X章节Y难度次数（param_arr章节0=任意; param1难度0=任意; 以结算成功为准, 仅队伍人数>=2统计）
        TEAM_SUCCESS_LEAVE_CNT = 93,     -- 组队成功撤离次数（仅队伍人数>=2统计）
	},
    ActivityMissionType = {
        GHOST_GATE = 1,          -- 鬼门关·幽冥试炼（赛季制，通关任务）
        GHOST_KING = 2,          -- 鬼王入侵·讨伐令（赛季制，讨伐任务）
        DEMON_TOWER = 3,         -- 封魔塔·镇魔之路（赛季制，层数冲刺）
        SEVEN_SIGN = 4,          -- 七日签到·灵宝阁（每日签到，签满7天）
        LEVEL_SPRINT = 5,        -- 道法精进·等级冲刺（账户等级达档位领奖）
        SEVEN_TARGET = 6,        -- 天师下山·七日目标（完成任务积攒积分领档位）
    },
}

local defaultPBConditionData = {
    cond_id = 0,
    target_value = 0,
    now_value = 0,
    is_complete = 0,
    params = {},
    arr_params = {},
}

local defaultPBMissionData = {
    mission_id = 0,
    mission_type = 0,
    mission_state = 0,
    beg_ts = 0,
    end_ts = 0,
    cond_datas = {},
}

local defaultPBLinearMissionInfo = {
    last_check_ts = 0,
    now_mission_datas = {},
    complete_ids = {},
    wait_beg_mission_datas = {},
}

local defaultPBPeriodMissionInfo = {
    last_update_ts = 0,
    now_day_mission_datas = {},
    complete_day_ids = {},
    now_week_mission_datas = {},
    complete_week_ids = {},
    now_month_mission_datas = {},
    complete_month_ids = {},
    day_total_vitality = 0,
    day_got_award_ids = {},
    week_total_vitality = 0,
    week_got_award_ids = {},
}

local defaultPBAchivementMissionInfo = {
    now_mission_datas = {},
    complete_ids = {},
    total_vitality = 0,
    got_award_ids = {},
}

local defaultPBActivityMissionInfo = {
    last_update_ts = 0,
    now_mission_datas = {},
    complete_ids = {},
    total_vitality = {},
    got_award_ids = {},
    target_login_days = 0,
    target_last_login_ts = 0,
    mailed_expire_types = {},
    season_id = 0,
}

local defaultPBPlayerMissionInfo = {
    linear_info = LuaExt.const(table.copy(defaultPBLinearMissionInfo)),
    period_info = LuaExt.const(table.copy(defaultPBPeriodMissionInfo)),
    achivement_info = LuaExt.const(table.copy(defaultPBAchivementMissionInfo)),
    activity_info = LuaExt.const(table.copy(defaultPBActivityMissionInfo)),
}

---@return PBConditionData
function MissionDef.newConditionData()
    return LuaExt.const(table.copy(defaultPBConditionData))
end

---@return PBMissionData
function MissionDef.newMissionData()
    return LuaExt.const(table.copy(defaultPBMissionData))
end

---@return PBLinearMissionInfo
function MissionDef.newLinearMissionInfo()
    return LuaExt.const(table.copy(defaultPBLinearMissionInfo))
end

---@return PBPeriodMissionInfo
function MissionDef.newPeriodMissionInfo()
    return LuaExt.const(table.copy(defaultPBPeriodMissionInfo))
end

---@return PBActivityMissionInfo
function MissionDef.newActivityMissionInfo()
    return LuaExt.const(table.copy(defaultPBActivityMissionInfo))
end

---@return PBPlayerMissionInfo
function MissionDef.newPlayerMissionInfo()
    return LuaExt.const(table.copy(defaultPBPlayerMissionInfo))
end

return MissionDef
