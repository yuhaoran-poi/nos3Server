local LuaExt = require "common.LuaExt"

local RoleDef = {
    LogType = {
        AllInfo = 1,
        SimpleInfo = 2,
        MagicInfo = 3,
        DiagramsInfo = 4,
    },
    RoleDefine = {
        RoleID = { Start = 1000000, End = 1000999 },
        RoleSkill = { Start = 1001000, End = 1012999 },
    },
    InlayType = 1000,
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
    passive_skill = {},
    emoji = {},
    up_lv_rewards = {},
}

local defaultPBUserRoleDatas = {
    battle_role_id = 0,
    role_list = {},
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

---@return PBUserRoleDatas
function RoleDef.newUserRoleDatas()
    return LuaExt.const(table.copy(defaultPBUserRoleDatas))
end

return RoleDef
