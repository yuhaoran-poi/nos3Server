local LuaExt = require "common.LuaExt"

local GodsDef = {}

local defaultPBGodImage = {
    config_id = 0,
    lv = 0,
}

local defaultPBGodBlock = {
    idx = 0,
    god_id = 0,
}

local defaultPBUserGods = {
    gods_image = {},
    gods_block = {},
}

---@return PBGodImage
function GodsDef.newGodImage()
    return LuaExt.const(table.copy(defaultPBGodImage))
end

---@return PBGodBlock
function GodsDef.newGodBlock()
    return LuaExt.const(table.copy(defaultPBGodBlock))
end

---@return PBUserGods
function GodsDef.newUserGods()
    return LuaExt.const(table.copy(defaultPBUserGods))
end

return GodsDef
