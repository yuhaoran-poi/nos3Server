local LuaExt = require "common.LuaExt"
local ItemDef = {}

-- 通用道具数据
local defaultPBItemCommonData = {
    config_id = 0,
    uniqid = 0,
    item_count = 0,
    item_type = 0,
    trade_cnt = 0,
    lock_count = 0,
}

local defaultPBDurabItem = {
    cur_durability = 0,
    strong_value = 0,
}

local defaultPBMagicItem = {
    cur_durability = 0,
    strong_value = 0,
    light_cnt = 0,
    tags = {},
}

local defaultPBDiagramsCard = {
    cur_durability = 0,
    strong_value = 0,
    light_cnt = 0,
    tags = {},
}

-- 道具数据
local defaultPBItemData = {
    itype = 0,
    common_info =  LuaExt.const(table.copy(defaultPBItemCommonData)),
    special_info = {},
}

local defaultPBImage = {
    config_id = 0,
    star_level = 0,
    exp = 0,
}

local defaultPBUserImage = {
    item_image = {},
    magic_item_image = {},
    human_diagrams_image = {},
    ghost_diagrams_image = {},
}

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

--- @return PBImage
function ItemDef.newImage()
    return LuaExt.const(table.copy(defaultPBImage))
end

--- @return PBUserImage
function ItemDef.newUserImage()
    return LuaExt.const(table.copy(defaultPBUserImage))
end

return ItemDef