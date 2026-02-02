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
        SortOutItems = 28,       --整理物品
        BattleSettle = 29,       --战斗结算
        BattleRunAway = 30,      --战斗逃跑
        GradeReward = 31,        --段位奖励

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
        AntiqueIdentify = 40,       -- 古董鉴定
        AntiqueShow = 41,           -- 古董展示
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

local defaultPBSkill = {
    config_id = 0,
    star = 0,
    star_fail_cnt = 0,
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

local defaultPBSpaceRing = {
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
    extra_param = 0,
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
    star_fail_cnt = 0,
}

local defaultPBSkinImage = {
    config_id = 0,
    valid_ts = 0,
}

local defaultPBUserImage = {
    item_image = {},
    magic_item_image = {},
    human_diagrams_image = {},
    ghost_diagrams_image = {},
    skin_image = {},
    space_ring_image = {},
}

local defaultPBAntique = {
    quality = 0,
    price = {},
    remain_identify_num = 0,
    tags = {},
    is_fake = 0,
    identify_histroy = {},
}

local defaultAntiqueShowcase = {
    showcase_id = 0,
    box_num = 0,
    antique_show_list = {},
}

local defaultAntiqueShowcaseS = {
    antique_showcase_list = {},
}

--- @return PBCoin
function ItemDef.newCoin()
    return LuaExt.const(table.copy(defaultPBCoin))
end

--- @return PBSkill
function ItemDef.newSkill()
    return LuaExt.const(table.copy(defaultPBSkill))
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

--- @return PBSpaceRing
function ItemDef.newSpaceRing()
    return LuaExt.const(table.copy(defaultPBSpaceRing))
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

--- @return PBAntique
function ItemDef.newAntique()
    return LuaExt.const(table.copy(defaultPBAntique))
end

--- @return PBAntiqueShowcaseData
function ItemDef.newAntiqueShowcase()
    return LuaExt.const(table.copy(defaultAntiqueShowcase))
end

--- @return PBAntiqueShowcaseDataS
function ItemDef.newAntiqueShowcaseS()
    return LuaExt.const(table.copy(defaultAntiqueShowcaseS))
end

--- @return PBItemData
function ItemDef.newItemDataFromData(itemdata, itype, item_type)
    local new_data = LuaExt.const(table.copy(defaultPBItemData))
    new_data.itype = itype
    if itemdata.common_info then
        if itemdata.common_info.config_id then
            new_data.common_info.config_id = itemdata.common_info.config_id
        end
        if itemdata.common_info.uniqid then
            new_data.common_info.uniqid = itemdata.common_info.uniqid
        end
        if itemdata.common_info.item_count then
            new_data.common_info.item_count = itemdata.common_info.item_count
        end
        if itemdata.common_info.trade_cnt then
            new_data.common_info.trade_cnt = itemdata.common_info.trade_cnt
        end
        new_data.common_info.item_type = item_type
    end
    if itemdata.special_info then
        if itemdata.special_info.durab_item and next(itemdata.special_info.durab_item) ~= nil then
            new_data.special_info.durab_item = LuaExt.const(table.copy(defaultPBDurabItem))
            new_data.special_info.durab_item.cur_durability = itemdata.special_info.durab_item.cur_durability
            new_data.special_info.durab_item.strong_value = itemdata.special_info.durab_item.strong_value
        end
        if itemdata.special_info.magic_item and next(itemdata.special_info.magic_item) ~= nil then
            new_data.special_info.magic_item = LuaExt.const(table.copy(defaultPBMagicItem))
            new_data.special_info.magic_item.cur_durability = itemdata.special_info.magic_item.cur_durability
            new_data.special_info.magic_item.strong_value = itemdata.special_info.magic_item.strong_value
            new_data.special_info.magic_item.tabooword_id = itemdata.special_info.magic_item.tabooword_id
            new_data.special_info.magic_item.light_cnt = itemdata.special_info.magic_item.light_cnt
            new_data.special_info.magic_item.tags = itemdata.special_info.magic_item.tags
            new_data.special_info.magic_item.ability_tag = itemdata.special_info.magic_item.ability_tag
        end
        if itemdata.special_info.diagrams_card and next(itemdata.special_info.diagrams_card) ~= nil then
            new_data.special_info.diagrams_card = LuaExt.const(table.copy(defaultPBDiagramsCard))
            new_data.special_info.diagrams_card.cur_durability = itemdata.special_info.diagrams_card.cur_durability
            new_data.special_info.diagrams_card.strong_value = itemdata.special_info.diagrams_card.strong_value
            new_data.special_info.diagrams_card.tabooword_id = itemdata.special_info.diagrams_card.tabooword_id
            new_data.special_info.diagrams_card.light_cnt = itemdata.special_info.diagrams_card.light_cnt
            new_data.special_info.diagrams_card.tags = itemdata.special_info.diagrams_card.tags
            new_data.special_info.diagrams_card.ability_tag = itemdata.special_info.diagrams_card.ability_tag
        end
        if itemdata.special_info.antique_item and next(itemdata.special_info.antique_item) ~= nil then
            new_data.special_info.antique_item = LuaExt.const(table.copy(defaultPBAntique))
            new_data.special_info.antique_item.quality = itemdata.special_info.antique_item.quality
            new_data.special_info.antique_item.price = itemdata.special_info.antique_item.price
            new_data.special_info.antique_item.remain_identify_num = itemdata.special_info.antique_item
                .remain_identify_num
            new_data.special_info.antique_item.tags = itemdata.special_info.antique_item.tags
            new_data.special_info.antique_item.is_fake = itemdata.special_info.antique_item.is_fake
            new_data.special_info.antique_item.identify_histroy = itemdata.special_info.antique_item.identify_histroy
        end
        if itemdata.special_info.space_ring and next(itemdata.special_info.space_ring) ~= nil then
            new_data.special_info.space_ring = LuaExt.const(table.copy(defaultPBSpaceRing))
            new_data.special_info.space_ring.cur_durability = itemdata.special_info.space_ring.cur_durability
            new_data.special_info.space_ring.strong_value = itemdata.special_info.space_ring.strong_value
            new_data.special_info.space_ring.tabooword_id = itemdata.special_info.space_ring.tabooword_id
            new_data.special_info.space_ring.light_cnt = itemdata.special_info.space_ring.light_cnt
            new_data.special_info.space_ring.tags = itemdata.special_info.space_ring.tags
            new_data.special_info.space_ring.ability_tag = itemdata.special_info.space_ring.ability_tag
        end
    end

    return new_data
end

return ItemDef