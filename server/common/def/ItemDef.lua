local LuaExt = require "common.LuaExt"
local ItemDef = {}

 
-- 通用道具数据
local defaultPBItemCommonData = {
    config_id = 0,
    uniqid = 0,
    item_count = 0,
    item_type = 0,
    trade_cnt = 0,
}

 
-- 拥有耐久度的不可堆叠道具
local defaultPBDurabItem = {
    cur_durability = 0,
    max_durability = 0,
}
 
-- 特殊道具数据
local defaultPBItemSpecial = {
    durab_item = LuaExt.const(table.copy(defaultPBDurabItem)),
    
}
-- 道具数据
local defaultPBItemData = {
    itype = 0,
    common_info =  LuaExt.const(table.copy(defaultPBItemCommonData)),
    special_info = LuaExt.const(table.copy(defaultPBItemSpecial))
}
--- @return PBItemCommon
function ItemDef.newPBItemCommonData()
    return LuaExt.const(table.copy(defaultPBItemCommonData))
end
--- @return PBDurabItem
function ItemDef.newPBDurabItem()
    return LuaExt.const(table.copy(defaultPBDurabItem))
end
--- @return PBItemSpecial
function ItemDef.newPBItemSpecialData()
    return LuaExt.const(table.copy(defaultPBItemSpecial))
end
--- @return PBItemData
function ItemDef.newPBItemData()
    return LuaExt.const(table.copy(defaultPBItemData))
end

return ItemDef