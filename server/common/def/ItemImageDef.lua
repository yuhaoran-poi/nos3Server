local LuaExt = require "common.LuaExt"
local ItemImageDef = {}

local defaultPBUserImage = {
    item_image = {},
    magic_item_image = {},
    human_diagrams_image = {},
    ghost_diagrams_image = {},
}

local defaultPBImage = {
    config_id = 0,
    star_level = 0,
    exp = 0,
}

--- @return PBUserImage
function ItemImageDef.newUserImage()
    return LuaExt.const(table.copy(defaultPBUserImage))
end

--- @return PBImage
function ItemImageDef.newImage()
    return LuaExt.const(table.copy(defaultPBImage))
end

return ItemImageDef