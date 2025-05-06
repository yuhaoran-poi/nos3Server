local LuaExt = require "common.LuaExt"

local GhostDef = {}

local defaultPBSimpleGhostData = {
    config_id = 0,
    skin_id = 0,
}

local defaultPBGhostData = {
    config_id = 0,
    uniqid = 0,
    star_level = 0,
    exp = 0,
    digrams_cards = {},
    passive_skills = {},
    active_skills = {},
    attrs = {},
    nature = 0,
}

local defaultPBGhostImage = {
    config_id = 0,
    star_level = 0,
    exp = 0,
    cur_skin_id = 0,
    skin_id_list = {},
}

local defaultPBUserGhostDatas = {
    battle_ghost_id = 0,
    battle_ghost_uniqid = 0,
    ghost_list = {},
    ghost_image_list = {},
}

---@return PBSimpleGhostData
function GhostDef.newSimpleGhostData()
    return LuaExt.const(table.copy(defaultPBSimpleGhostData))
end

---@return PBGhostData
function GhostDef.newGhostData()
    return LuaExt.const(table.copy(defaultPBGhostData))
end

---@return PBGhostImage
function GhostDef.newGhostImage()
    return LuaExt.const(table.copy(defaultPBGhostImage))
end

---@return PBUserGhostDatas
function GhostDef.newUserGhostDatas()
    return LuaExt.const(table.copy(defaultPBUserGhostDatas))
end

return GhostDef
