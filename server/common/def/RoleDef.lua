local LuaExt = require "common.LuaExt"

local RoleDef = {
    LogType = {
        AllInfo = 1,
        SimpleInfo = 2,
        MagicInfo = 3,
        DiagramsInfo = 4,
        SpaceRingInfo = 5,
    },
    RoleDefine = {
        RoleID = { Start = 1000000, End = 1000999 },
        RoleSkill = { Start = 1001000, End = 1012999 },
    },
    SkillType = {
        MinorSkill_1 = 1, -- 小技能1
        MinorSkill_2 = 2, -- 小技能2
        PassiveSkill = 3, -- 被动技能
        MainSkill = 4, -- 主技能
        BigSkill_1 = 5, -- 大技能1
        BigSkill_2 = 6, -- 大技能2
    },
    InlayType = 1000,
    -- 装备分页槽位定义(PBRoleEquipScheme.equips 的 key)
    -- 集中定义避免魔法数字; 新装备类型(诡器等)在此追加槽位段
    EquipSlotType = {
        BaguaBase = 0,     -- 八卦槽位 = BaguaBase + UniqueItem.type5 (1~8: 乾巽坎艮坤震离兑)
        MagicItem = 9,     -- 法器槽
        SpaceRing = 10,    -- 空间戒指槽
    },
    -- 装备分页规则(方案数量/解锁费用/初始解锁/槽位类型校验 全部走 LoadoutConfig 表):
    --   unlock: 0=初始解锁 1=需付费解锁; unlock_cost: map{coin_id: 数量}
    --   槽位类型校验: 槽位1~8 配 UniqueItem.type5(卦位), 槽位9/10 配 UniqueItem.type1(大类)
    -- 精力系统规则(角色级)
    EnergyDef = {
        Max = 100,          -- 精力上限(固定, 不可扩展)
        Init = 100,         -- 新角色初始精力(满)
        CostPerGame = 10,   -- 门票模式每局消耗(统一不分档)
        RecoverHour = 6,    -- 每日恢复时刻(凌晨6点, 恢复不满的角色至满)
        PillRecover = 10,   -- 精力丹回复量(超出上限封顶)
    },
}

local defaultPBStudyBook = {
    book_id = 0,
    start_time = 0,
    end_time = 0,
    now_time = 0,
}

local defaultPBSimpleRoleData = {
    config_id = 0,
    skins = {},
    magic_item_id = 0,
}

local defaultPBRoleData = {
    config_id = 0,
    star_level = 0,
    exp = 0,
    magic_item = {},
    digrams_cards = {},
    equip_books = {},
    study_books = {},
    last_check_time = 0,
    skins = {},
    cur_main_skill_id = 0,
    main_skill = {},
    cur_minor_skill1_id = 0,
    minor_skill1 = {},
    cur_minor_skill2_id = 0,
    minor_skill2 = {},
    cur_passive_skill_id = 0,
    passive_skill = {},
    emoji = {},
    up_lv_rewards = {},
    space_ring = {},
    star_fail_cnt = 0,
    cur_big_skill1_id = 0,
    big_skill1 = {},
    cur_big_skill2_id = 0,
    big_skill2 = {},
    cur_reserve_skill1_id = 0,
    reserve_skill1 = {},
    cur_reserve_skill2_id = 0,
    reserve_skill2 = {},
    equip_schemes = {},     -- 装备分页(权威存储), 登录校准时初始化 scheme1
    cur_scheme_idx = 0,     -- 当前激活分页(0=未初始化, 校准后=1)
    energy = 100,           -- 精力(0~100, 新角色默认满)
    energy_pay_ts = 0,      -- 最近一次门票模式扣精力时间戳(0=无)
}

local defaultPBRoleEquipScheme = {
    scheme_idx = 0,
    unlocked = 0,    -- 1=已解锁 0=未解锁
    equips = {},    -- map<槽位号, PBItemData> 槽位见 RoleDef.EquipSlotType
}

local defaultPBUserRoleDatas = {
    battle_role_id = 0,
    model_role_id = 0,
    role_list = {},
}

local defaultPBRoleLog = {
    uid = 0,
    config_id = 0,
    star_level = 0,
    exp = 0,
    role_data = {},
    change_reason = "",
    log_ts = 0,
}

---@return PBStudyBook
function RoleDef.newStudyBook()
    return LuaExt.const(table.copy(defaultPBStudyBook))
end

---@return PBSimpleRoleData
function RoleDef.newSimpleRoleData()
    return LuaExt.const(table.copy(defaultPBSimpleRoleData))
end

---@return PBRoleData
function RoleDef.newRoleData()
    return LuaExt.const(table.copy(defaultPBRoleData))
end

---@return PBRoleEquipScheme
function RoleDef.newEquipScheme()
    return LuaExt.const(table.copy(defaultPBRoleEquipScheme))
end

---@return PBUserRoleDatas
function RoleDef.newUserRoleDatas()
    return LuaExt.const(table.copy(defaultPBUserRoleDatas))
end

---@return PBRoleLog
function RoleDef.newRoleLog()
    return LuaExt.const(table.copy(defaultPBRoleLog))
end

return RoleDef
