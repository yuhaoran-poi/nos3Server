local LuaExt = require "common.LuaExt"

local AweItemDef = {}

local defaultPBAweItem = {
    config_id = 0,
    up_level = 0,
    star_level = 0,
    buff_id = 0,
    star_lv_fail_cnt = 0,
}

local defaultPBAweItems = {
    awe_item_map = {},
}

---@return PBAweItem
function AweItemDef.newAweItem()
    return LuaExt.const(table.copy(defaultPBAweItem))
end

---@return PBUserAweItems
function AweItemDef.newAweItems()
    return LuaExt.const(table.copy(defaultPBAweItems))
end

return AweItemDef
