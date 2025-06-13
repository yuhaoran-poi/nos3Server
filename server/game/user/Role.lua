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

    local update_info = {
        battle_role_id = roles.battle_role_id,
        role_list = {},
    }
    if change_roles then
        for roleid, reason in pairs(change_roles) do
            local roleinfo = roles.role_list[roleid]
            if not roleinfo then
                return false
            end
            update_info.role_list[roleid] = table.copy(roleinfo)
        end
    end

    Role.SaveRolesNow()
    context.S2C(context.net_id, CmdCode["PBRoleInfoSyncCmd"], { roles_info = update_info }, 0)

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
        if role_info.magic_item and role_info.magic_item.common_info then
            show_role.magic_item_id = role_info.magic_item.common_info.config_id
        end

        local update_user_attr = {}
        update_user_attr[ProtoEnum.UserAttrType.cur_show_role] = show_role
        scripts.User.SetUserAttr(update_user_attr, sync_client)
    end
end

---@return integer, PBRoleData ? nil
function Role.GetRoleInfo(roleid)
    local roles = scripts.UserModel.GetRoles()
    if not roles or not roles.role_list or not roles.role_list[roleid] then
        return ErrorCode.RoleNotExist, nil
    end

    return ErrorCode.None, roles.role_list[roleid]
end

function Role.GetRolesInfo(roleids)
    local res = {
        errcode = ErrorCode.None,
        roles_info = {},
    }
    if not roleids or table.size(roleids) <= 0 then
        res.errcode = ErrorCode.RoleNotExist
        return res
    end

    local roles = scripts.UserModel.GetRoles()
    if not roles or not roles.role_list then
        res.errcode = ErrorCode.RoleNotExist
        return res
    end

    for _, roleid in pairs(roleids) do
        local role_info = roles.role_list[roleid]
        if role_info then
            res.roles_info[roleid] = role_info
        end
    end
    
    return res
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

function Role.GetRoleEquipment(role_info, config_id, equip_idx)
    local item_small_type = scripts.ItemDefine.GetItemType(config_id)
    if item_small_type == scripts.ItemDefine.EItemSmallType.MagicItem then
        -- 检测现在是否携带有法器
        if role_info.magic_item and role_info.magic_item.common_info then
            return item_small_type, role_info.magic_item
        end
    elseif item_small_type == scripts.ItemDefine.EItemSmallType.HumanDiagrams then
        -- 检测现在是否携带有相应位置八卦牌
        if role_info.digrams_cards
            and role_info.digrams_cards[equip_idx]
            and role_info.digrams_cards[equip_idx].common_info then
            return item_small_type, role_info.digrams_cards[equip_idx]
        end
    end

    return item_small_type, nil
end

function Role.ChangeEquipment(battle_role_id, role_info, config_id, equip_idx, equip_item_data)
    local item_small_type = scripts.ItemDefine.GetItemType(config_id)
    if item_small_type == scripts.ItemDefine.EItemSmallType.MagicItem then
        if equip_item_data then
            role_info.magic_item = equip_item_data
        else
            role_info.magic_item = nil
        end
        
        -- 同步到玩家属性上
        if battle_role_id == role_info.config_id then
            local show_role = RoleDef.newSimpleRoleData()
            show_role.config_id = role_info.config_id
            show_role.skins = role_info.skins
            if role_info.magic_item and role_info.magic_item.common_info then
                show_role.magic_item_id = role_info.magic_item.common_info.config_id
            else
                show_role.magic_item_id = 0
            end

            local update_user_attr = {}
            update_user_attr[ProtoEnum.UserAttrType.cur_show_role] = show_role
            scripts.User.SetUserAttr(update_user_attr, true)
        end
    elseif item_small_type == scripts.ItemDefine.EItemSmallType.HumanDiagrams then
        if equip_item_data then
            role_info.digrams_cards[equip_idx] = equip_item_data
        else
            role_info.digrams_cards[equip_idx] = nil
        end
    end
end

function Role.PBRoleWearEquipReqCmd(req)
    local roles = scripts.UserModel.GetRoles()
    if not roles then
        return context.S2C(context.net_id, CmdCode["PBRoleWearEquipRspCmd"],
            { code = ErrorCode.ServerInternalError, error = "数据加载出错", uid = context.uid }, req.msg_context.stub_id)
    end

    local role_info = roles.role_list[req.msg.roleid]
    if not role_info then
        return context.S2C(context.net_id, CmdCode["PBRoleWearEquipRspCmd"],
            { code = ErrorCode.RoleNotExist, error = "角色不存在", uid = context.uid }, req.msg_context.stub_id)
    end

    local errcode, item_data = scripts.Bag.GetOneItemData(req.msg.bag_name, req.msg.pos)
    if errcode ~= ErrorCode.None or not item_data then
        return context.S2C(context.net_id, CmdCode["PBRoleWearEquipRspCmd"],
            { code = errcode, error = "装备不存在", uid = context.uid }, req.msg_context.stub_id)
    end
    if item_data.common_info.config_id ~= req.msg.equip_config_id
        or item_data.common_info.uniqid ~= req.msg.equip_uniqid then
        return context.S2C(context.net_id, CmdCode["PBRoleWearEquipRspCmd"],
            { code = ErrorCode.ItemNotExist, error = "装备不存在", uid = context.uid }, req.msg_context.stub_id)
    end

    local del_unique_items = {}
    del_unique_items[item_data.common_info.uniqid] = {
        config_id = item_data.common_info.config_id,
        uniqid = item_data.common_info.uniqid,
        pos = req.msg.pos,
    }
    local bag_change_log = {}
    local err_code = ErrorCode.None
    local takeoff_items = {}

    local item_small_type, takeoff_item_data = Role.GetRoleEquipment(role_info, item_data.common_info.config_id,
        req.msg.equip_idx)
    if item_small_type ~= scripts.ItemDefine.EItemSmallType.MagicItem
        and item_small_type ~= item_small_type == scripts.ItemDefine.EItemSmallType.HumanDiagrams then
        return context.S2C(context.net_id, CmdCode["PBRoleWearEquipRspCmd"],
            { code = ErrorCode.ItemNotExist, error = "装备不存在", uid = context.uid }, req.msg_context.stub_id)
    end
    if item_small_type == scripts.ItemDefine.EItemSmallType.HumanDiagrams then
        -- 检测八卦牌位置是否正确
        local uniqitem_cfg = GameCfg.UniqueItem[item_data.common_info.config_id]
        if not uniqitem_cfg or uniqitem_cfg.type5 ~= req.msg.equip_idx then
            return context.S2C(context.net_id, CmdCode["PBRoleWearEquipRspCmd"],
                { code = ErrorCode.ConfigError, error = "八卦牌配置不存在", uid = context.uid }, req.msg_context.stub_id)
        end
    end
    if takeoff_item_data then
        takeoff_items[takeoff_item_data.common_info.uniqid] = takeoff_item_data
    end

    -- 扣除道具消耗
    err_code = scripts.Bag.DelItems(req.msg.bag_name, {}, del_unique_items, bag_change_log)
    if err_code ~= ErrorCode.None then
        scripts.Bag.RollBackWithChange(bag_change_log)
        return context.S2C(context.net_id, CmdCode["PBRoleWearEquipRspCmd"],
            { code = err_code, error = "更换装备失败", uid = context.uid }, req.msg_context.stub_id)
    end
    -- 添加道具
    err_code = scripts.Bag.AddItems(req.msg.bag_name, {}, takeoff_items, bag_change_log)
    if err_code ~= ErrorCode.None then
        scripts.Bag.RollBackWithChange(bag_change_log)
        return context.S2C(context.net_id, CmdCode["PBRoleWearEquipRspCmd"],
            { code = err_code, error = "更换装备失败", uid = context.uid }, req.msg_context.stub_id)
    end

    -- 角色穿戴新装备
    Role.ChangeEquipment(roles.battle_role_id, role_info, item_data.common_info.config_id, req.msg.equip_idx, item_data)

    -- 保存数据并同步给客户端
    local save_bags = {}
    for bagType, _ in pairs(bag_change_log) do
        save_bags[bagType] = 1
    end
    local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
    scripts.Bag.SaveAndLog(save_bags, bag_change_log)

    local change_roles = {}
    change_roles[req.msg.roleid] = "WearEquipment"
    scripts.Role.SaveAndLog(change_roles)

    local rsp_msg = {
        code = ErrorCode.None,
        error = "",
        uid = req.msg.uid,
        roleid = req.msg.roleid,
        bag_name = req.msg.bag_name,
        pos = req.msg.pos,
        equip_config_id = req.msg.equip_config_id,
        equip_uniqid = req.msg.equip_uniqid,
        equip_idx = req.msg.equip_idx,
    }
    return context.S2C(context.net_id, CmdCode["PBRoleWearEquipRspCmd"], rsp_msg, req.msg_context.stub_id)
end

function Role.PBRoleTakeOffEquipReqCmd(req)
    local roles = scripts.UserModel.GetRoles()
    if not roles then
        return context.S2C(context.net_id, CmdCode["PBRoleTakeOffEquipRspCmd"],
            { code = ErrorCode.ServerInternalError, error = "数据加载出错", uid = context.uid }, req.msg_context.stub_id)
    end

    local role_info = roles.role_list[req.msg.roleid]
    if not role_info then
        return context.S2C(context.net_id, CmdCode["PBRoleTakeOffEquipRspCmd"],
            { code = ErrorCode.RoleNotExist, error = "角色不存在", uid = context.uid }, req.msg_context.stub_id)
    end

    local bag_change_log = {}
    local err_code = ErrorCode.None
    local takeoff_items = {}
    local item_small_type, takeoff_item_data = Role.GetRoleEquipment(role_info, req.msg.takeoff_config_id, req.msg.takeoff_idx)
    if item_small_type ~= scripts.ItemDefine.EItemSmallType.MagicItem
        and item_small_type ~= item_small_type == scripts.ItemDefine.EItemSmallType.HumanDiagrams then
        return context.S2C(context.net_id, CmdCode["PBRoleTakeOffEquipRspCmd"],
            { code = ErrorCode.ItemNotExist, error = "装备不存在", uid = context.uid }, req.msg_context.stub_id)
    end
    if item_small_type == scripts.ItemDefine.EItemSmallType.HumanDiagrams then
        -- 检测八卦牌位置是否正确
        local uniqitem_cfg = GameCfg.UniqueItem[req.msg.takeoff_config_id]
        if not uniqitem_cfg or uniqitem_cfg.type5 ~= req.msg.takeoff_idx then
            return context.S2C(context.net_id, CmdCode["PBRoleTakeOffEquipRspCmd"],
                { code = ErrorCode.ConfigError, error = "八卦牌配置不存在", uid = context.uid }, req.msg_context.stub_id)
        end
    end
    if takeoff_item_data then
        takeoff_items[takeoff_item_data.common_info.uniqid] = takeoff_item_data
    end

    -- 判断卸下的装备是否一致
    if not takeoff_items[req.msg.takeoff_uniqid]
        or not takeoff_items[req.msg.takeoff_uniqid].common_info
        or takeoff_items[req.msg.takeoff_uniqid].common_info.config_id ~= req.msg.takeoff_config_id
        or takeoff_items[req.msg.takeoff_uniqid].common_info.uniqid ~= req.msg.takeoff_uniqid then
        return context.S2C(context.net_id, CmdCode["PBRoleTakeOffEquipRspCmd"],
            { code = ErrorCode.ItemNotExist, error = "装备不存在", uid = context.uid }, req.msg_context.stub_id)
    end

    -- 添加道具
    err_code = scripts.Bag.AddItems(req.msg.bag_name, {}, takeoff_items, bag_change_log)
    if err_code ~= ErrorCode.None then
        scripts.Bag.RollBackWithChange(bag_change_log)
        return context.S2C(context.net_id, CmdCode["PBRoleTakeOffEquipRspCmd"],
            { code = err_code, error = "更换装备失败", uid = context.uid }, req.msg_context.stub_id)
    end

    -- 角色卸下新装备
    Role.ChangeEquipment(roles.battle_role_id, role_info, req.msg.takeoff_config_id, req.msg.takeoff_idx, nil)

    -- 保存数据并同步给客户端
    local save_bags = {}
    for bagType, _ in pairs(bag_change_log) do
        save_bags[bagType] = 1
    end
    scripts.Bag.SaveAndLog(save_bags, bag_change_log)
    local change_roles = {}
    change_roles[req.msg.roleid] = "TakeOffEquipment"
    scripts.Role.SaveAndLog(change_roles)
    
    local rsp_msg = {
        code = ErrorCode.None,
        error = "",
        uid = req.msg.uid,
        roleid = req.msg.roleid,
        bag_name = req.msg.bag_name,
        takeoff_config_id = req.msg.takeoff_config_id,
        takeoff_uniqid = req.msg.takeoff_uniqid,
        takeoff_idx = req.msg.takeoff_idx,
    }
    return context.S2C(context.net_id, CmdCode["PBRoleTakeOffEquipRspCmd"], rsp_msg, req.msg_context.stub_id)
end

return Role