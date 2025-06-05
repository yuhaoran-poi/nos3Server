local moon = require "moon"
local common = require "common"
local uuid = require "uuid"
local GameCfg = common.GameCfg
local ErrorCode = common.ErrorCode
local CmdCode = common.CmdCode
local Database = common.Database
local RoleDef = require("common.def.RoleDef")
local ProtoEnum = require("tools.ProtoEnum")

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
    
end

function Role.Start()
    --加载全部角色数据
    local roleinfos = Role.LoadRoles()
    --local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
    if roleinfos then
        scripts.UserModel.SetRoles(roleinfos)
    end

    local roles = scripts.UserModel.GetRoles()
    if not roles then
        local init_cfg = GameCfg.Init[1]
        if not init_cfg then
            return { code = ErrorCode.ConfigError, error = "no init_cfg" }
        end

        roles = RoleDef.newUserRoleDatas()
        scripts.UserModel.SetRoles(roles)

        for k, v in pairs(init_cfg.item) do
            if k >= RoleDefine.RoleID.Start and k <= RoleDefine.RoleID.End then
                --local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
                Role.AddRole(k)
            end
        end
        Role.SetRoleBattle(init_cfg.battle_role, false)

        Role.SaveRolesNow()
    end

    return { code = ErrorCode.None }
end

function Role.SaveRolesNow()
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

function Role.SaveAndLog(change_roles)
    local roles = scripts.UserModel.GetRoles()
    if not roles then
        return false
    end

    -- 修改dataMap
    -- 去掉已经为0的道具格子
    -- 将变更记录作为PBBagUpdateSyncCmd发送
    local update_msg = {
        battle_role_id = roles.battle_role_id,
        role_list = {},
    }
    if change_roles then
        for roleid, reason in pairs(change_roles) do
            local roleinfo = roles.role_list[roleid]
            if not roleinfo then
                return false
            end
            update_msg.role_list[roleid] = table.copy(roleinfo)
        end
    end

    Role.SaveRolesNow()
    context.S2C(context.net_id, CmdCode["PBRoleInfoSyncCmd"], update_msg, 0)

    --存储日志

    return true
end

function Role.AddRole(roleid)
    local roles = scripts.UserModel.GetRoles()
    if not roles then
        return false
    end

    local role_cfg = GameCfg.HumanRole[roleid]
    if not role_cfg then
        return { code = ErrorCode.ConfigError, error = "no role_cfg" }
    end

    local role_info = RoleDef.newRoleData()
    role_info.config_id = roleid
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

    roles.role_list[roleid] = role_info
end

function Role.SetRoleBattle(roleid, sync_client)
    local roles = scripts.UserModel.GetRoles()
    if not roles then
        return false
    end

    if roles.role_list[roleid] then
        local role_info = roles.role_list[roleid]
        roles.battle_role_id = roleid

        -- 同步到玩家属性上
        local show_role = RoleDef.newSimpleRoleData()
        show_role.config_id = role_info.config_id
        show_role.skins = role_info.skins
        if role_info.magic_item then
            show_role.magic_item_id = role_info.magic_item.common_info.config_id
        end

        local update_user_attr = {}
        update_user_attr[ProtoEnum.UserAttrType.cur_show_role] = show_role
        scripts.User.SetUserAttr(update_user_attr, sync_client)
    end
end

---@return integer, PBRoleData
function Role.GetRoleInfo(roleid)
    local roles = scripts.UserModel.GetRoles()
    if not roles or not roles.role_list or not roles.role_list[roleid] then
        return ErrorCode.RoleNotExist, nil
    end

    return ErrorCode.None, roles.role_list[roleid]
end

-- function Role.GetMagicItemData(roleid)
--     local roles = scripts.UserModel.GetRoles()
--     if not roles or not roles.role_list or not roles.role_list[roleid] then
--         return ErrorCode.RoleNotExist
--     end

--     local role_info = roles.role_list[roleid]
--     if table.size(role_info.magic_item) < 0 then
--         return ErrorCode.NoMagicItem
--     end

--     return ErrorCode.None, role_info.magic_item
-- end

function Role.ModMagicItem(roleid, item_data)
    local roles = scripts.UserModel.GetRoles()
    if not roles or not roles.role_list or not roles.role_list[roleid] then
        return ErrorCode.RoleNotExist
    end

    local role_info = roles.role_list[roleid]
    role_info.magic_item = item_data

    return ErrorCode.None
end

function Role.ModDiagramsCard(roleid, item_data, slot)
    local roles = scripts.UserModel.GetRoles()
    if not roles or not roles.role_list or not roles.role_list[roleid] then
        return ErrorCode.RoleNotExist
    end

    local role_info = roles.role_list[roleid]
    role_info.digrams_cards[slot] = item_data

    return ErrorCode.None
end

function Role.PBClientGetUsrRolesInfoReqCmd(req)
    local roles = scripts.UserModel.GetRoles()
    if not roles then
        return context.S2C(context.net_id, CmdCode["PBClientGetUsrRolesInfoRspCmd"],
            { code = ErrorCode.ServerInternalError, error = "数据加载出错", uid = context.uid }, req.msg_context.stub_id)
    end

    local rsp_msg = {
        code = ErrorCode.None,
        error = "",
        uid = req.msg.uid,
        roles_info = roles,
    }

    return context.S2C(context.net_id, CmdCode["PBClientGetUsrRolesInfoRspCmd"], rsp_msg, req.msg_context.stub_id)
end

return Role