local LuaExt = require "common.LuaExt"

local ItemDef = {
    ChangeReason = {
        BagMove = 1, --背包移动道具
        ItemDecompose = 2, --背包分解道具
        BagAddCapacity = 3, --背包增加容量
        GhostWearEquip = 4, --鬼宠装备道具
        GhostTakeoffEquip = 5, --鬼宠脱下道具
        GetMailAttach = 6,     --获取邮件附件
        RoleWearEquip = 7,     --角色装备道具
        RoleTakeoffEquip = 8,  --角色脱下道具
        RoleSkillUpStar = 9,   --角色升级技能星数
        RoleUpLvReward = 10,   --角色升级奖励
        RoleStudyBook = 11,    --角色学习书籍
        RoleCompositeSkill = 12, --角色合成技能
        ShopBuy = 13,            --商城购买
        TradeSale = 14,          --交易行出售
        RoleEquipLight = 15,     --角色装备开光
        GhostEquipLight = 16,    --鬼宠装备开光
        BagLight = 17,           --背包开光
        DsAddItems = 18,         --Ds增加道具
        ImageUpLv = 19,          --图鉴升级
        UseItemUpLv = 20,        --使用道具升级
        ImageUpStar = 21,        --图鉴升星
        ItemRepair = 22,         --道具修理
        ItemComposite = 23,      --道具合成
        InlayItem = 24,          --镶嵌道具
        GodsUnlock = 25,         --解锁神明
        GodsUpLv = 26,           --升级神明
        GodsBlockUnlock = 27,    --解锁神龛

        -- WearEquipment = 25,      --装备道具
        -- TakeOffEquipment = 26,   --脱下道具
        -- WearSkin = 27,           --装备皮肤
        -- ChangeEmoji = 28,        --改变emoji
        -- SkillUpStar = 29,        --升级技能星数
        -- UpLvReward = 30,         --升级奖励
        -- StudyBook = 31,          --学习书籍
        -- CompositeSkill = 32,     --合成技能
        -- SwitchSkill = 33,        --切换技能
        -- AddRole = 34,            --增加角色
        -- LightMagicItem = 35,     --角色法器开光
        -- LightDiagramsCard = 36,  --角色八卦牌开光
        -- UpLv = 37,               --升级
        -- UpStar = 38,             --升级星数
        -- InlayTabooWord = 39,     --镶嵌讳字
    },
    TabooWordInlay = {
        RoleType = 1000,
        GhostType = 1001,
    },
    LogType = {
        ChangeNum = 1,  --变更道具数量
        ChangeInfo = 2, --变更道具信息
    },
}

local defaultPBCoin = {
    coin_id = 0,
    coin_count = 0,
}

-- 通用道具数据
local defaultPBItemCommonData = {
    config_id = 0,
    uniqid = 0,
    item_count = 0,
    item_type = 0,
    trade_cnt = 0,
}

local defaultPBDurabItem = {
    cur_durability = 0,
    strong_value = 0,
}

local defaultPBMagicItem = {
    cur_durability = 0,
    strong_value = 0,
    tabooword_id = 0,
    light_cnt = 0,
    tags = {},
    ability_tag = {},
}

local defaultPBDiagramsCard = {
    cur_durability = 0,
    strong_value = 0,
    tabooword_id = 0,
    light_cnt = 0,
    tags = {},
    ability_tag = {},
}

-- 道具数据
local defaultPBItemData = {
    itype = 0,
    common_info =  LuaExt.const(table.copy(defaultPBItemCommonData)),
    special_info = {},
}

local defaultPBItemSimple = {
    config_id = 0,
    item_count = 0,
    uniqid = 0,
}

local defaultPBItemLog = {
    uid = 0,
    config_id = 0,
    old_num = 0,
    new_num = 0,
    mod_uniqid = 0,
    del_uniqids = {},
    add_uniqids = {},
    old_item_data = {},
    new_item_data = {},
    relation_roleid = 0,
    relation_ghostid = 0,
    relation_ghost_uniqid = 0,
    relation_imageid = 0,
    change_type = 0,
    change_reason = 0,
    log_ts = 0,
}

local defaultPBImage = {
    config_id = 0,
    star_level = 0,
    exp = 0,
}

local defaultPBSkinImage = {
    config_id = 0,
}

local defaultPBUserImage = {
    item_image = {},
    magic_item_image = {},
    human_diagrams_image = {},
    ghost_diagrams_image = {},
    skin_image = {},
}

--- @return PBCoin
function ItemDef.newCoin()
    return LuaExt.const(table.copy(defaultPBCoin))
end

--- @return PBItemCommon
function ItemDef.newItemCommonData()
    return LuaExt.const(table.copy(defaultPBItemCommonData))
end

--- @return PBDurabItem
function ItemDef.newDurabItem()
    return LuaExt.const(table.copy(defaultPBDurabItem))
end

--- @return PBMagicItem
function ItemDef.newMagicItem()
    return LuaExt.const(table.copy(defaultPBMagicItem))
end

--- @return PBDiagramsCard
function ItemDef.newDiagramsCard()
    return LuaExt.const(table.copy(defaultPBDiagramsCard))
end

--- @return PBItemData
function ItemDef.newItemData()
    return LuaExt.const(table.copy(defaultPBItemData))
end

--- @return PBItemSimple
function ItemDef.newItemSimple()
    return LuaExt.const(table.copy(defaultPBItemSimple))
end

---@return PBItemLog
function ItemDef.newPBItemLog()
    return LuaExt.const(table.copy(defaultPBItemLog))
end

--- @return PBImage
function ItemDef.newImage()
    return LuaExt.const(table.copy(defaultPBImage))
end

--- @return PBSkinImage
function ItemDef.newSkinImage()
    return LuaExt.const(table.copy(defaultPBSkinImage))
end

--- @return PBUserImage
function ItemDef.newUserImage()
    return LuaExt.const(table.copy(defaultPBUserImage))
end

return ItemDef