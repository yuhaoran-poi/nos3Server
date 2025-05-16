local LuaExt = require "common.LuaExt"

local RoleDef = {
    LogType = {
        AllInfo = 1,
        SimpleInfo = 2,
        MagicInfo = 3,
        DiagramsInfo = 4,
    }
}

local defaultPBSimpleRoleData = {
    config_id = 0,
    skins = {}
}

local defaultPBRoleData = {
    config_id = 0,
    star_level = 0,
    exp = 0,
    magic_item = {},
    digrams_cards = {},
    equip_books = {},
    study_books = {},
    skins = {},
    cur_main_skill_id = 0,
    main_skill = {},
    cur_minor_skill1_id = 0,
    minor_skill1 = {},
    cur_minor_skill2_id = 0,
    minor_skill2 = {},
    passive_skill = {},
    emoji = {}
}

local defaultPBUserRoleDatas = {
    battle_role_id = 0,
    role_list = {},
}

---@return PBSimpleRoleData
function RoleDef.newSimpleRoleData()
    return LuaExt.const(table.copy(defaultPBSimpleRoleData))
end

---@return PBRoleData
function RoleDef.newRoleData()
    return LuaExt.const(table.copy(defaultPBRoleData))
end

---@return PBUserRoleDatas
function RoleDef.newUserRoleDatas()
    return LuaExt.const(table.copy(defaultPBUserRoleDatas))
end

return RoleDef
