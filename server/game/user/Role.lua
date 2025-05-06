local moon = require "moon"
local common = require "common"
local uuid = require "uuid"
local GameCfg = common.GameCfg
local ErrorCode = common.ErrorCode
local CmdCode = common.CmdCode
local Database = common.Database
local RoleDef = require("common.def.RoleDef")

---@type user_context
local context = ...
local scripts = context.scripts

local RoleDefine = {
    RoleID = { Start = 1000000, End = 1000999 },
    RoleSkill = { Start = 1001000, End = 1012999 },
}

---@class Role
local Role = {}

function Role.Init()
    --加载全部角色数据
    local roleinfos = Role.LoadRoles()
    local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
    if roleinfos then
        scripts.UserModel.SetRoles(roleinfos)
    end

    local roles = scripts.UserModel.GetRoles()
    if not roles then
        roles = RoleDef.newUserRoleDatas()

        local init_cfg = GameCfg.Init[1]
        if not init_cfg then
            return { code = ErrorCode.ConfigError, error = "no init_cfg" }
        end

        for k, v in pairs(init_cfg.item) do
            if k >= RoleDefine.RoleID.Start and k <= RoleDefine.RoleID.End then
                local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
                local role_cfg = GameCfg.HumanRole[k]
                if not role_cfg then
                    return { code = ErrorCode.ConfigError, error = "no role_cfg" }
                end

                local role_info = RoleDef.newRoleData()
                role_info.config_id = k
                role_info.cur_main_skill_id = role_cfg.init_main_skill
                for _, skillid in pairs(role_cfg.main_skill) do
                    local skill_info = {
                        config_id = skillid,
                        star_level = 0,
                    }
                    table.insert(role_info.main_skill, skill_info)
                end
                role_info.cur_minor_skill1_id = role_cfg.init_q_skill
                for _, skillid in pairs(role_cfg.q_skill) do
                    local skill_info = {
                        config_id = skillid,
                        star_level = 0,
                    }
                    table.insert(role_info.minor_skill1, skill_info)
                end
                role_info.cur_minor_skill2_id = role_cfg.init_e_skill
                for _, skillid in pairs(role_cfg.e_skill) do
                    local skill_info = {
                        config_id = skillid,
                        star_level = 0,
                    }
                    table.insert(role_info.minor_skill2, skill_info)
                end

                roles.role_list[k] = role_info
            end
        end

        if roles.role_list[init_cfg.battle_role] then
            roles.battle_role_id = init_cfg.battle_role
            scripts.User.SimpleSetShowRole(roles.role_list[init_cfg.battle_role])
        end

        scripts.UserModel.SetRoles(roles)
        Role.SaveRolesNow()
    end

    return { code = ErrorCode.None }
end

function Role.Start()
    -- body
end

function Role.SaveRolesNow(roleTypes)
    local roles = scripts.UserModel.GetRoles()
    if not roles then
        return false
    end

    local success = Database.saveuserroles(context.addr_db_user, context.uid, roles)
    return success
end

function Role.LoadRoles()
    local roleinfos = Database.loaduserroles(context.addr_db_user, context.uid)
    return roleinfos
end

return Role