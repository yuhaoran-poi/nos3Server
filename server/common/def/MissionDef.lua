local LuaExt = require "common.LuaExt"

local MissionDef = {
    ETaskState = {
        NO_PROGRESS = 0, -- 未领取
        NO_COMPLETE = 1, -- 未完成
        COMPLETE = 2,    -- 已完成
        GET_REWARD = 3,  -- 已领取奖励
    },
    EConditionIds = {
        SIGN_CNT = 1,   -- 签到次数
        ONLINE_TIME = 2, -- 在线时间
        ACTIVITY_CNT = 3, -- 累计活跃度
        ACCOUNT_LEVEL = 4, -- 账户达到等级
        OUT_TASK_CNT = 5,  -- 累计完成局外任务次数  -- 未做
        IN_TASK_CNT = 6,   -- 累计完成局内任务次数  -- 未做
        KILL_MONSTER_CNT = 7, -- 累计击杀怪物数量  -- 未做
        GET_ITEM_CNT = 8,     -- 累计从X渠道中获得道具数量
        UNLOCK_ROLE_SKIN_CNT = 9,  -- 累计解锁角色皮肤数量
        UNLOCK_ROLE_SKIN = 10,      -- 解锁指定角色皮肤
        UNLOCK_ROLE_CNT = 11, -- 累计解锁角色数量
        UNLOCK_ROLE = 12,     -- 解锁指定角色
        BATTLE_CHAPTER_CNT = 13, -- 完成副本章节次数    -- 未做
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
        GOD_ENTER_BATTLE_CNT = 34,  -- 装备X神明进入战斗次数    -- 未做
        MAKE_ITEM_CNT = 35,         -- 只做X品质Y类型Z道具的次数
        CONSUME_ITEM_CNT = 36,      -- 通过X渠道消耗Y类型Z道具的次数
        GET_LINGBI_COIN_CNT = 37,   -- 累计获得灵币数量         -- 未做
        GET_BOOTY_VALUE_CNT = 38,   -- 累计从X章节Y难度获得战利品价值    -- 未做
        UNLOCK_ITEM_SKIN_CNT = 39,  -- 累计解锁道具皮肤数量
        TOTAL_RECHARGE_CNT = 40,    -- 累计充值金额
        ACHIEVEMENT_CNT = 41,           -- 累计完成成就次数     -- 未做
        ROLE_EQUIP_DIAGRAMS_CNT = 42,   -- X角色装备Y品质八卦牌数量
    }
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
}

local defaultPBAchivementMissionInfo = {
    now_mission_datas = {},
    complete_ids = {},
}

local defaultPBPlayerMissionInfo = {
    linear_info = LuaExt.const(table.copy(defaultPBLinearMissionInfo)),
    period_info = LuaExt.const(table.copy(defaultPBPeriodMissionInfo)),
    achivement_info = LuaExt.const(table.copy(defaultPBAchivementMissionInfo)),
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

---@return PBPlayerMissionInfo
function MissionDef.newPlayerMissionInfo()
    return LuaExt.const(table.copy(defaultPBPlayerMissionInfo))
end

return MissionDef
