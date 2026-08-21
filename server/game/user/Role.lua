local moon = require "moon"
local common = require "common"
local uuid = require "uuid"
local json = require "json"
local GameCfg = common.GameCfg
local ErrorCode = common.ErrorCode
local CmdCode = common.CmdCode
local Database = common.Database
local clusterd = require("cluster")
local RoleDef = require("common.def.RoleDef")
local BagDef = require("common.def.BagDef")
local ProtoEnum = require("tools.ProtoEnum")
local ItemDefine = require("common.logic.ItemDefine")
local ItemDef = require("common.def.ItemDef")
local CommonCfgDef = require("common.def.CommonCfgDef")
local MissionDef = require("common.def.MissionDef")


---@type user_context
local context = ...
local scripts = context.scripts

---@class Role
local Role = {}

function Role.Init()
    --加载全部角色数据
    local roleinfos = Role.LoadRoles()
    if roleinfos then
        scripts.UserModel.SetRoles(roleinfos)
    end

    local roles = scripts.UserModel.GetRoles()
    if not roles then
        roles = RoleDef.newUserRoleDatas()
        scripts.UserModel.SetRoles(roles)
    end
end

function Role.Start(isnew)
    local roles = scripts.UserModel.GetRoles()
    if not roles then
        return false
    end

    if isnew then
        local init_cfg = GameCfg.Init[1]
        if not init_cfg then
            return { code = ErrorCode.ConfigError, error = "no init_cfg" }
        end

        for _, v in pairs(init_cfg.unlock_role) do
            if v >= RoleDef.RoleDefine.RoleID.Start and v <= RoleDef.RoleDefine.RoleID.End then
                --local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
                Role.AddRole(v)
            end
        end
        Role.SetRoleBattle(init_cfg.battle_role, false)

        -- Role.SaveRolesNow()
        scripts.UserModel.AddDirtyModule("Role")
    end
end

function Role.SaveRolesNow()
    local roles = scripts.UserModel.GetRoles()
    if not roles then
        return false
    end

    local success = Database.saveuserroles(context.addr_db_user, context.uid, roles)
    scripts.UserModel.RemoveDirtyModule("Role")
    return success
end

function Role.TimingSave()
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

function Role.CheckRoleStudyBook(role_info)
    local now_time = moon.time()
    -- moon.warn(string.format("CheckRoleStudyBook role_info = %s", json.pretty_encode(role_info)))
    if now_time - role_info.last_check_time < 10 then
        return false
    end

    local is_change = false
    local end_study = {}
    for book_id, study_book in pairs(role_info.study_books) do
        study_book.now_time = now_time
        if study_book.end_time <= now_time then
            role_info.equip_books[book_id] = 1
            table.insert(end_study, book_id)
            is_change = true
        end
    end

    for _, book_id in pairs(end_study) do
        role_info.study_books[book_id] = nil
    end

    role_info.last_check_time = now_time
    return is_change
end

function Role.SaveAndLog(change_roles)
    local roles = scripts.UserModel.GetRoles()
    if not roles then
        return false
    end

    local update_info = {
        battle_role_id = roles.battle_role_id,
        model_role_id = roles.model_role_id,
        role_list = {},
    }
    local write_log_datas = {}
    local save_now = false
    if change_roles then
        for roleid, reason in pairs(change_roles) do
            local roleinfo = roles.role_list[roleid]
            if not roleinfo then
                return false
            end
            -- 检测更新角色真经学习进度
            Role.CheckRoleStudyBook(roleinfo)

            update_info.role_list[roleid] = table.copy(roleinfo, true)
            if reason == "WearEquipment"
                or reason == "TakeOffEquipment"
                or reason == "UpLvReward"
                or reason == "AddRole"
                or reason == "LightMagicItem"
                or reason == "LightSpaceRing"
                or reason == "LightDiagramsCard" then
                save_now = true
            end

            local role_log = RoleDef.newRoleLog()
            role_log.uid = context.uid
            role_log.config_id = roleinfo.config_id
            role_log.star_level = roleinfo.star_level
            role_log.exp = roleinfo.exp
            -- role_log.role_data = table.copy(roleinfo, true)
            role_log.role_data = roleinfo
            role_log.change_reason = reason
            role_log.log_ts = moon.time()
            table.insert(write_log_datas, role_log)

            if roleid == roles.battle_role_id or roleid == roles.model_role_id then
                -- 同步到玩家属性上
                local show_role = RoleDef.newSimpleRoleData()
                show_role.config_id = roleinfo.config_id
                show_role.skins = roleinfo.skins
                if roleinfo.magic_item and roleinfo.magic_item.common_info then
                    show_role.magic_item_id = roleinfo.magic_item.common_info.config_id
                end

                local update_user_attr = {}
                if roleid == roles.battle_role_id then
                    update_user_attr[ProtoEnum.UserAttrType.cur_show_role] = show_role
                end
                if roleid == roles.model_role_id then
                    update_user_attr[ProtoEnum.UserAttrType.cur_model_role] = show_role
                end
                scripts.User.SetUserAttr(update_user_attr, true)
            end
        end
    end

    if save_now then
        Role.SaveRolesNow()
    else
        scripts.UserModel.AddDirtyModule("Role")
    end
    context.S2C(context.net_id, CmdCode["PBRoleInfoSyncCmd"], { roles_info = update_info }, 0)

    --存储日志
    if table.size(write_log_datas) > 0 then
        scripts.Role.SendLog(write_log_datas)
    end

    return true
end

function Role.SendLog(write_log_datas)
    moon.warn(string.format("Role.SendLog write_log_datas = %s", json.pretty_encode(write_log_datas)))
    --存储日志
    clusterd.send(3003, "logmgr", "LogMgr.RoleChangeLog", write_log_datas)
end

function Role.CheckAddRoles(roleids)
    local roles = scripts.UserModel.GetRoles()
    if not roles then
        return ErrorCode.ServerInternalError
    end

    for roleid, _ in pairs(roleids) do
        local role_cfg = GameCfg.HumanRole[roleid]
        if not role_cfg then
            return ErrorCode.ConfigError
        end
        if roles.role_list[roleid] and roles.role_list[roleid].config_id ~= 0 then
            return ErrorCode.RoleExist
        end
    end

    return ErrorCode.None
end

function Role.GetSkillNum(role_info, skillids)
    local num = table.size(role_info.main_skill) + table.size(role_info.minor_skill1) +
        table.size(role_info.minor_skill2) + table.size(role_info.passive_skill)

    -- 触发角色解锁技能数量
    scripts.Mission.TriggerCondition(MissionDef.EConditionIds.ROLE_UNLOCK_SKILL_CNT, { role_info.config_id }, num)
    for _, skillid in pairs(skillids) do
        scripts.Mission.TriggerCondition(MissionDef.EConditionIds.ROLE_UNLOCK_SKILL, { role_info.config_id, skillid }, 1)
    end
end

function Role.GetMaxSkillNum()
    local roles = scripts.UserModel.GetRoles()
    if not roles or not roles.role_list then
        return 0, 0
    end

    local max_skill_num, cur_roleid = 0, 0
    for roleid, role_info in pairs(roles.role_list) do
        local num = table.size(role_info.main_skill) + table.size(role_info.minor_skill1) +
            table.size(role_info.minor_skill2) + table.size(role_info.passive_skill)
        if num > max_skill_num then
            max_skill_num = num
            cur_roleid = roleid
        end
    end

    return max_skill_num, cur_roleid
end

function Role.GetRoleCnt()
    local roles = scripts.UserModel.GetRoles()
    if not roles or not roles.role_list then
        return 0
    end

    return table.size(roles.role_list)
end

function Role.AddRole(roleid)
    local roles = scripts.UserModel.GetRoles()
    if not roles then
        return ErrorCode.ServerInternalError
    end

    local role_cfg = GameCfg.HumanRole[roleid]
    if not role_cfg then
        return ErrorCode.ConfigError
    end

    if roles.role_list[roleid] and roles.role_list[roleid].config_id ~= 0 then
        return ErrorCode.RoleExist
    end

    local skillids = {}
    local role_info = RoleDef.newRoleData()
    role_info.config_id = roleid
    role_info.cur_main_skill_id = role_cfg.init_main_skill
    for _, skillid in pairs(role_cfg.main_skill) do
        local skill_info = ItemDef.newSkill()
        skill_info.config_id = skillid
        skill_info.star = -1
        if skillid == role_info.cur_main_skill_id then
            skill_info.star = 0
        end
        role_info.main_skill[skillid] = skill_info
        table.insert(skillids, skillid)
    end
    role_info.cur_minor_skill1_id = role_cfg.init_q_skill
    for _, skillid in pairs(role_cfg.q_skill) do
        local skill_info = ItemDef.newSkill()
        skill_info.config_id = skillid
        skill_info.star = -1
        if skillid == role_info.cur_minor_skill1_id then
            skill_info.star = 0
        end
        role_info.minor_skill1[skillid] = skill_info
        table.insert(skillids, skillid)
    end
    role_info.cur_minor_skill2_id = role_cfg.init_e_skill
    for _, skillid in pairs(role_cfg.e_skill) do
        local skill_info = ItemDef.newSkill()
        skill_info.config_id = skillid
        skill_info.star = -1
        if skillid == role_info.cur_minor_skill2_id then
            skill_info.star = 0
        end
        role_info.minor_skill2[skillid] = skill_info
    end
    role_info.cur_passive_skill_id = role_cfg.init_passive_skill
    for _, skillid in pairs(role_cfg.passive_skill) do
        local skill_info = ItemDef.newSkill()
        skill_info.config_id = skillid
        skill_info.star = -1
        if skillid == role_info.cur_passive_skill_id then
            skill_info.star = 0
        end
        role_info.passive_skill[skillid] = skill_info
        table.insert(skillids, skillid)
    end
    -- 初始化法器
    local init_magic_item_id = role_cfg.initial_equipment1
    local magic_item_cfg = GameCfg.UniqueItem[init_magic_item_id]
    if init_magic_item_id
        and magic_item_cfg
        and ItemDefine.GetItemType(init_magic_item_id) == ItemDefine.EItemSmallType.MagicItem then
        local new_item_data = ItemDef.newItemData()
        new_item_data.itype = ItemDefine.EItemSmallType.MagicItem
        new_item_data.common_info.config_id = init_magic_item_id
        -- new_item_data.common_info.uniqid = uuid.next()
        new_item_data.common_info.uniqid = common.UniqueId.next()
        new_item_data.common_info.item_count = 1
        new_item_data.common_info.item_type = magic_item_cfg.type1
        new_item_data.common_info.trade_cnt = magic_item_cfg.deal_num
        new_item_data.special_info.magic_item = ItemDef.newMagicItem()
        new_item_data.special_info.magic_item.cur_durability = magic_item_cfg.durability
        new_item_data.special_info.magic_item.strong_value = magic_item_cfg.sturdy
        -- 获取默认词条
        local uniq_item_cfg = GameCfg.UniqueItem[init_magic_item_id]
        if uniq_item_cfg and uniq_item_cfg.default_entry and table.size(uniq_item_cfg.default_entry) > 0 then
            for tag_id, tag_value in pairs(uniq_item_cfg.default_entry) do
                local new_tag = {
                    tag_id = tag_id,
                    val = tag_value,
                }
                table.insert(new_item_data.special_info.magic_item.tags, new_tag)
            end
        end
        role_info.magic_item = new_item_data
    end
    -- 初始化八卦牌
    if role_cfg.initial_equipment2 and table.size(role_cfg.initial_equipment2) > 0 then
        for equip_idx, diagrams_id in pairs(role_cfg.initial_equipment2) do
            local diagrams_item_cfg = GameCfg.UniqueItem[diagrams_id]
            if diagrams_item_cfg
                and ItemDefine.GetItemType(diagrams_id) == ItemDefine.EItemSmallType.HumanDiagrams then
                local new_item_data = ItemDef.newItemData()
                new_item_data.itype = ItemDefine.EItemSmallType.HumanDiagrams
                new_item_data.common_info.config_id = diagrams_id
                -- new_item_data.common_info.uniqid = uuid.next()
                new_item_data.common_info.uniqid = common.UniqueId.next()
                new_item_data.common_info.item_count = 1
                new_item_data.common_info.item_type = diagrams_item_cfg.type1
                new_item_data.common_info.trade_cnt = diagrams_item_cfg.deal_num
                new_item_data.special_info.diagrams_item = ItemDef.newDiagramsCard()
                new_item_data.special_info.diagrams_item.cur_durability = diagrams_item_cfg.durability
                new_item_data.special_info.diagrams_item.strong_value = diagrams_item_cfg.sturdy
                -- 获取默认词条
                local uniq_item_cfg = GameCfg.UniqueItem[diagrams_id]
                if uniq_item_cfg and uniq_item_cfg.default_entry and table.size(uniq_item_cfg.default_entry) > 0 then
                    for tag_id, tag_value in pairs(uniq_item_cfg.default_entry) do
                        local new_tag = {
                            tag_id = tag_id,
                            val = tag_value,
                        }
                        table.insert(new_item_data.special_info.diagrams_item.tags, new_tag)
                    end
                end
                role_info.digrams_cards[equip_idx] = new_item_data
            end
        end
    end
    -- 初始化空间戒指
    local init_space_ring_id = role_cfg.initial_equipment3
    local space_ring_cfg = GameCfg.UniqueItem[init_space_ring_id]
    if init_space_ring_id
        and space_ring_cfg
        and ItemDefine.GetItemType(init_space_ring_id) == ItemDefine.EItemSmallType.SpaceRing then
        local new_item_data = ItemDef.newItemData()
        new_item_data.itype = ItemDefine.EItemSmallType.SpaceRing
        new_item_data.common_info.config_id = init_space_ring_id
        -- new_item_data.common_info.uniqid = uuid.next()
        new_item_data.common_info.uniqid = common.UniqueId.next()
        new_item_data.common_info.item_count = 1
        new_item_data.common_info.item_type = space_ring_cfg.type1
        new_item_data.common_info.trade_cnt = space_ring_cfg.deal_num
        new_item_data.special_info.space_ring = ItemDef.newSpaceRing()
        new_item_data.special_info.space_ring.cur_durability = space_ring_cfg.durability
        new_item_data.special_info.space_ring.strong_value = space_ring_cfg.sturdy
        -- 获取默认词条
        local uniq_item_cfg = GameCfg.UniqueItem[init_space_ring_id]
        if uniq_item_cfg and uniq_item_cfg.default_entry and table.size(uniq_item_cfg.default_entry) > 0 then
            for tag_id, tag_value in pairs(uniq_item_cfg.default_entry) do
                local new_tag = {
                    tag_id = tag_id,
                    val = tag_value,
                }
                table.insert(new_item_data.special_info.space_ring.tags, new_tag)
            end
        end
        role_info.space_ring = new_item_data
    end
    -- 初始化皮肤
    if role_cfg.initial_suit and table.size(role_cfg.initial_suit) > 0 then
        local change_image_ids = {}
        for skin_idx, skin_id in pairs(role_cfg.initial_suit) do
            local skin_cfg = GameCfg.Skin[skin_id]
            if skin_cfg then
                role_info.skins[skin_idx] = skin_id
                scripts.ItemImage.AddItemImage(skin_id, change_image_ids, true)
            end
        end
        -- 图鉴信息变更
        if table.size(change_image_ids) > 0 then
            scripts.ItemImage.SaveAndSync(change_image_ids)
        end
    end

    roles.role_list[roleid] = role_info

    Role.GetSkillNum(role_info, skillids)
    -- 触发角色数量
    scripts.Mission.TriggerCondition(MissionDef.EConditionIds.UNLOCK_ROLE_CNT, {}, table.size(roles.role_list))
    -- 触发指定角色解锁
    scripts.Mission.TriggerCondition(MissionDef.EConditionIds.UNLOCK_ROLE, { roleid }, 1)

    return ErrorCode.None
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

        -- 同步给房间其他人
        scripts.Room.SyncRoleInfo(role_info)
    end
end

function Role.SetRoleModel(roleid, sync_client)
    local roles = scripts.UserModel.GetRoles()
    if not roles then
        return false
    end

    if roles.role_list[roleid] then
        local role_info = roles.role_list[roleid]
        roles.model_role_id = roleid

        -- 同步到玩家属性上
        local show_role = RoleDef.newSimpleRoleData()
        show_role.config_id = role_info.config_id
        show_role.skins = role_info.skins
        if role_info.magic_item and role_info.magic_item.common_info then
            show_role.magic_item_id = role_info.magic_item.common_info.config_id
        end

        local update_user_attr = {}
        update_user_attr[ProtoEnum.UserAttrType.cur_model_role] = show_role
        scripts.User.SetUserAttr(update_user_attr, sync_client)

        -- 同步给房间其他人
        -- scripts.Room.SyncRoleInfo(role_info)
    end
end

---@return PBRoleData ? nil
function Role.GetRoleInfo(roleid)
    local roles = scripts.UserModel.GetRoles()
    if not roles or not roles.role_list or not roles.role_list[roleid] then
        return nil
    end

    local role_info = roles.role_list[roleid]
    Role.CheckRoleStudyBook(role_info)

    return role_info
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
            Role.CheckRoleStudyBook(role_info)
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

function Role.ModSpaceRing(roleid, item_data, slot)
    local roles = scripts.UserModel.GetRoles()
    if not roles or not roles.role_list or not roles.role_list[roleid] then
        return ErrorCode.RoleNotExist
    end

    local role_info = roles.role_list[roleid]
    role_info.space_ring = item_data

    return ErrorCode.None
end

function Role.PBClientGetUsrRolesInfoReqCmd(req)
    local roles = scripts.UserModel.GetRoles()
    if not roles then
        return context.S2C(context.net_id, CmdCode["PBClientGetUsrRolesInfoRspCmd"],
            { code = ErrorCode.ServerInternalError, error = "数据加载出错", uid = context.uid }, req.msg_context.stub_id)
    end

    local change_roles = {}
    for roleid, role_info in pairs(roles.role_list) do
        local is_change = Role.CheckRoleStudyBook(role_info)
        if is_change then
            change_roles[roleid] = "StudyBook"
        end
    end
    if table.size(change_roles) > 0 then
        Role.SaveAndLog(change_roles)
        roles = scripts.UserModel.GetRoles()
    end

    local rsp_msg = {
        code = ErrorCode.None,
        error = "",
        uid = req.msg.uid,
        roles_info = roles,
    }

    return context.S2C(context.net_id, CmdCode["PBClientGetUsrRolesInfoRspCmd"], rsp_msg, req.msg_context.stub_id)
end

function Role.PBClientGetRoleInfoReqCmd(req)
    -- 参数验证
    if not req.msg.roleid then
        return context.S2C(context.net_id, CmdCode.PBClientGetRoleInfoRspCmd, {
            code = ErrorCode.ParamInvalid,
            error = "无效请求参数",
            uid = context.uid,
            roleid = req.msg.roleid or 0,
        }, req.msg_context.stub_id)
    end

    local roles = scripts.UserModel.GetRoles()
    if not roles then
        return context.S2C(context.net_id, CmdCode["PBClientGetRoleInfoRspCmd"],
            { code = ErrorCode.ServerInternalError, error = "数据加载出错", uid = context.uid, roleid = req.msg.roleid },
            req.msg_context.stub_id)
    end
    
    if not roles.role_list[req.msg.roleid] then
        return context.S2C(context.net_id, CmdCode["PBClientGetRoleInfoRspCmd"],
            { code = ErrorCode.RoleNotExist, error = "角色不存在", uid = context.uid, roleid = req.msg.roleid },
            req.msg_context.stub_id)
    end

    local role_info = roles.role_list[req.msg.roleid]
    local is_change = Role.CheckRoleStudyBook(role_info)
    if is_change then
        local change_roles = {}
        change_roles[req.msg.roleid] = "StudyBook"
        Role.SaveAndLog(change_roles)
    end

    local rsp_msg = {
        code = ErrorCode.None,
        error = "",
        uid = req.msg.uid,
        role_info = role_info,
    }

    return context.S2C(context.net_id, CmdCode["PBClientGetRoleInfoRspCmd"], rsp_msg, req.msg_context.stub_id)
end

function Role.GetRoleEquipment(role_info, config_id, equip_idx)
    local item_small_type = ItemDefine.GetItemType(config_id)
    if item_small_type == ItemDefine.EItemSmallType.MagicItem then
        -- 检测现在是否携带有法器
        if role_info.magic_item and role_info.magic_item.common_info then
            return item_small_type, role_info.magic_item
        end
    elseif item_small_type == ItemDefine.EItemSmallType.HumanDiagrams then
        -- 检测现在是否携带有相应位置八卦牌
        if role_info.digrams_cards
            and role_info.digrams_cards[equip_idx]
            and role_info.digrams_cards[equip_idx].common_info then
            return item_small_type, role_info.digrams_cards[equip_idx]
        end
    elseif item_small_type == ItemDefine.EItemSmallType.SpaceRing then
        -- 检测现在是否携带有相应位置空间戒指
        if role_info.space_ring and role_info.space_ring.common_info then
            return item_small_type, role_info.space_ring
        end
    end

    return item_small_type, nil
end

function Role.ChangeEquipment(battle_role_id, model_role_id, role_info, config_id, equip_idx, equip_item_data)
    local item_small_type = ItemDefine.GetItemType(config_id)
    if item_small_type == ItemDefine.EItemSmallType.MagicItem then
        if equip_item_data then
            role_info.magic_item = equip_item_data
        else
            role_info.magic_item = {}
        end
        
        local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
        -- 同步到玩家属性上
        if battle_role_id == role_info.config_id or model_role_id == role_info.config_id then
            local show_role = RoleDef.newSimpleRoleData()
            show_role.config_id = role_info.config_id
            show_role.skins = role_info.skins
            if role_info.magic_item and role_info.magic_item.common_info then
                show_role.magic_item_id = role_info.magic_item.common_info.config_id
            else
                show_role.magic_item_id = 0
            end

            local update_user_attr = {}
            if battle_role_id == role_info.config_id then
                update_user_attr[ProtoEnum.UserAttrType.cur_show_role] = show_role
            end
            if model_role_id == role_info.config_id then
                update_user_attr[ProtoEnum.UserAttrType.cur_model_role] = show_role
            end
            scripts.User.SetUserAttr(update_user_attr, true)
        end
    elseif item_small_type == ItemDefine.EItemSmallType.HumanDiagrams then
        if equip_item_data then
            role_info.digrams_cards[equip_idx] = equip_item_data
        else
            role_info.digrams_cards[equip_idx] = nil
        end
    elseif item_small_type == ItemDefine.EItemSmallType.SpaceRing then
        if equip_item_data then
            role_info.space_ring = equip_item_data
        else
            role_info.space_ring = {}
        end
    end
end

function Role.InlayTabooWord(roleid, taboo_word_id, inlay_type, uniqid)
    local roles = scripts.UserModel.GetRoles()
    if not roles or not roles.role_list or not roles.role_list[roleid] then
        return ErrorCode.RoleNotExist
    end

    local role_info = roles.role_list[roleid]
    local item_data = nil
    if inlay_type == 1 then
        if role_info.magic_item
            and role_info.magic_item.common_info
            and role_info.magic_item.common_info.uniqid == uniqid then
            item_data = role_info.magic_item
        end
    elseif inlay_type == 2 then
        if role_info.digrams_cards then
            for _, digrams_card in pairs(role_info.digrams_cards) do
                if digrams_card
                    and digrams_card.common_info
                    and digrams_card.common_info.uniqid == uniqid then
                    item_data = digrams_card
                    break
                end
            end
        end
    elseif inlay_type == 3 then
        if role_info.space_ring
            and role_info.space_ring.common_info
            and role_info.space_ring.common_info.uniqid == uniqid then
            item_data = role_info.space_ring
        end
    end
    if not item_data then
        return ErrorCode.ItemNotExist
    end

    local uniqitem_cfg = GameCfg.UniqueItem[item_data.common_info.config_id]
    local item_cfg = GameCfg.Item[taboo_word_id]
    if not uniqitem_cfg or not item_cfg then
        return ErrorCode.ConfigError
    end
    -- if inlay_type == 1 then
    --     if item_cfg.type4 ~= ItemDef.TabooWordInlay.RoleType then
    --         return ErrorCode.InlayTypeNotMatch
    --     end
    -- elseif inlay_type == 2 then
    --     if uniqitem_cfg.type4 ~= item_cfg.type4 then
    --         return ErrorCode.InlayTypeNotMatch
    --     end
    --     if uniqitem_cfg.type5 ~= item_cfg.type5 then
    --         return ErrorCode.InlayTypeNotMatch
    --     end
    -- end
    local is_match = false
    for _, inlay in pairs(uniqitem_cfg.text_type) do
        if inlay == item_cfg.type4 then
            is_match = true
            break
        end
    end
    if not is_match then
        return ErrorCode.InlayTypeNotMatch
    end

    -- 扣除道具消耗
    local cost_items = {}
    cost_items[taboo_word_id] = {
        id = taboo_word_id,
        count = -1,
        pos = 0,
    }
    local err_code = scripts.Bag.CheckItemsEnough(BagDef.BagType.Cangku, cost_items, {})
    if err_code ~= ErrorCode.None then
        return ErrorCode.ItemNotEnough
    end

    local bag_change_log = {}
    local err_code_del = scripts.Bag.DelItems(BagDef.BagType.Cangku, cost_items, {}, bag_change_log)
    if err_code_del ~= ErrorCode.None then
        scripts.Bag.RollBackWithChange(bag_change_log)
        return ErrorCode.ItemNotEnough
    end

    -- 镶嵌讳字
    if inlay_type == 1 then
        item_data.special_info.magic_item.tabooword_id = taboo_word_id
    elseif inlay_type == 2 then
        item_data.special_info.diagrams_item.tabooword_id = taboo_word_id
    elseif inlay_type == 3 then
        item_data.special_info.space_ring.tabooword_id = taboo_word_id
    end

    return ErrorCode.None, bag_change_log
    -- local save_bags = {}
    -- for bagType, _ in pairs(bag_change_log) do
    --     save_bags[bagType] = 1
    -- end
    -- if table.size(save_bags) > 0 then
    --     scripts.Bag.SaveAndLog(save_bags, bag_change_log)
    -- end

    -- local change_roles = {}
    -- change_roles[roleid] = "InlayTabooWord"
    -- scripts.Role.SaveAndLog(change_roles)
end

function Role.GetLvMoreThanNum(target_role_id, target_lv_exps)
    local roles = scripts.UserModel.GetRoles()
    if not roles or not roles.role_list then
        return
    end

    for _, lv_exp in pairs(target_lv_exps) do
        local num = 0
        for roleid, role_info in pairs(roles.role_list) do
            if roleid ~= target_role_id and role_info.exp >= lv_exp.exp then
                num = num + 1
            end
        end
        -- 触发角色达到指定等级的数量
        scripts.Mission.TriggerCondition(MissionDef.EConditionIds.ROLE_LEVEL_CNT, { lv_exp.lv }, num + 1)
        scripts.Mission.TriggerCondition(MissionDef.EConditionIds.ROLE_LEVEL, { target_role_id }, lv_exp.lv)
    end

    for roleid, role_info in pairs(roles.role_list) do
        if roleid == target_role_id then
            -- 角色榜更新
            scripts.Rank.UpdateRank_Role(roleid, target_lv_exps.lv, role_info.skins)
        end
    end
end

function Role.GetSingleExpMoreThanIds(target_exp)
    local roles = scripts.UserModel.GetRoles()
    if not roles or not roles.role_list then
        return {}
    end

    local roleid_exps = {}
    for roleid, role_info in pairs(roles.role_list) do
        if role_info.exp >= target_exp then
            roleid_exps[roleid] = role_info.exp
        end
    end

    return roleid_exps
end

function Role.GetMaxExpRoleid()
    local roles = scripts.UserModel.GetRoles()
    if not roles or not roles.role_list then
        return 0, 0
    end

    local max_exp, cur_roleid = 0, 0
    for roleid, role_info in pairs(roles.role_list) do
        if role_info.exp > max_exp then
            max_exp = role_info.exp
            cur_roleid = roleid
        end
    end

    return max_exp, cur_roleid
end

function Role.UpLv(roleid, add_exp)
    local roles = scripts.UserModel.GetRoles()
    if not roles or not roles.role_list or not roles.role_list[roleid] then
        return ErrorCode.RoleNotExist
    end

    local role_info = roles.role_list[roleid]
    local up_exp_cfgs = GameCfg.RoleUpLv
    if not up_exp_cfgs then
        return ErrorCode.ConfigError
    end

    local exps = {}
    local remain_exp = add_exp
    local new_lv_exp = {}
    for _, cfg in pairs(up_exp_cfgs) do
        if cfg.allexp > role_info.exp then
            if role_info.exp + add_exp >= cfg.allexp then
                local canAdd = math.min(cfg.allexp - role_info.exp, remain_exp)
                if not exps[cfg.cost] then
                    exps[cfg.cost] = 0
                end
                exps[cfg.cost] = exps[cfg.cost] + canAdd
                remain_exp = remain_exp - canAdd

                table.insert(new_lv_exp, {lv = cfg.id, exp = cfg.allexp})
                break
            else
                if not exps[cfg.cost] then
                    exps[cfg.cost] = 0
                end
                exps[cfg.cost] = exps[cfg.cost] + remain_exp
                remain_exp = 0

                break
            end
        end
    end
    if remain_exp > 0 or table.size(exps) <= 0 then
        return ErrorCode.RoleMaxExp
    end

    -- 计算消耗资源
    local cost_items = {}
    local cost_coins = {}
    for id, count in pairs(exps) do
        local cur_cfg = GameCfg.UpLvCostIDMapping[id]
        if not cur_cfg or not cur_cfg.cost or not cur_cfg.cnt then
            return ErrorCode.ItemUpLvCostNotExist
        end

        ItemDefine.GetItemsFromCfg(cur_cfg.cost, (count / cur_cfg.cnt), true, cost_items, cost_coins)
    end

    -- 检查资源是否足够
    local err_code_items = scripts.Bag.CheckItemsEnough(BagDef.BagType.Cangku, cost_items, {})
    if err_code_items ~= ErrorCode.None then
        return err_code_items
    end
    local err_code_coins = scripts.Bag.CheckCoinsEnough(cost_coins)
    if err_code_coins ~= ErrorCode.None then
        return err_code_coins
    end

    -- 增加经验
    local new_exp = role_info.exp + add_exp
    role_info.exp = new_exp

    -- 扣除消耗
    local change_log = {}
    local err_code_del = ErrorCode.None
    if table.size(cost_items) > 0 then
        err_code_del = scripts.Bag.DelItems(BagDef.BagType.Cangku, cost_items, {}, change_log)
        if err_code_del ~= ErrorCode.None then
            scripts.Bag.RollBackWithChange(change_log)
            return err_code_del
        end
    end
    if table.size(cost_coins) > 0 then
        err_code_del = scripts.Bag.DealCoins(cost_coins, change_log)
        if err_code_del ~= ErrorCode.None then
            scripts.Bag.RollBackWithChange(change_log)
            return err_code_del
        end
    end

    if table.size(new_lv_exp) > 0 then
        Role.GetLvMoreThanNum(roleid, new_lv_exp)
    end

    return ErrorCode.None, change_log
end

function Role.GameAddExp(roleid, add_exp)
    local roles = scripts.UserModel.GetRoles()
    if not roles or not roles.role_list or not roles.role_list[roleid] then
        return ErrorCode.RoleNotExist
    end

    local role_info = roles.role_list[roleid]
    local up_exp_cfgs = GameCfg.RoleUpLv
    if not up_exp_cfgs then
        return ErrorCode.ConfigError
    end
    local last_lv_exp = 0
    if up_exp_cfgs[#up_exp_cfgs] and up_exp_cfgs[#up_exp_cfgs].allexp then
        last_lv_exp = up_exp_cfgs[#up_exp_cfgs].allexp
    end
    if role_info.exp + add_exp >= last_lv_exp then
        return ErrorCode.RoleMaxExp
    end
    add_exp = math.min(add_exp, last_lv_exp - role_info.exp)

    local new_lv_exp = {}
    for _, cfg in pairs(up_exp_cfgs) do
        if cfg.allexp > role_info.exp then
            if role_info.exp + add_exp >= cfg.allexp then
                table.insert(new_lv_exp, {lv = cfg.id, exp = cfg.allexp})
            else
                break
            end
        end
    end

    -- 增加经验
    local new_exp = role_info.exp + add_exp
    role_info.exp = new_exp

    if table.size(new_lv_exp) > 0 then
        Role.GetLvMoreThanNum(roleid, new_lv_exp)
    end

    return ErrorCode.None, new_exp
end

function Role.CheckUseItemUpLv(roleid, exp_id, up_exp_total, item_exps)
    local roles = scripts.UserModel.GetRoles()
    if not roles or not roles.role_list or not roles.role_list[roleid] then
        return ErrorCode.RoleNotExist, 0, {}
    end

    local up_exp_cfgs = GameCfg.RoleUpLv
    if not up_exp_cfgs then
        return ErrorCode.ConfigError, 0, {}
    end

    local success = false
    local max_exp = 0
    local role_info = roles.role_list[roleid]
    local after_up_exp = role_info.exp + up_exp_total
    for _, cfg in pairs(up_exp_cfgs) do
        if role_info.exp < cfg.allexp then
            if cfg.cost ~= exp_id then
                return ErrorCode.ConfigError, 0, {}
            end
        end
        if after_up_exp <= cfg.allexp then
            success = true
            break
        end
        max_exp = cfg.allexp
    end
    if success then
        local cost_items = {}
        for cost_id, exp_num in pairs(item_exps) do
            cost_items[cost_id] = {
                id = cost_id,
                count = -exp_num.num,
                pos = 0,
            }
        end
        return ErrorCode.None, up_exp_total, cost_items
    end

    local cost_items = {}
    local need_exp = max_exp - role_info.exp
    if need_exp > 0 then
        for cost_id, exp_num in pairs(item_exps) do
            local need_num = math.ceil(need_exp / exp_num.exp_cnt)
            need_num = math.min(need_num, exp_num.num)
            cost_items[cost_id] = {
                id = cost_id,
                count = -need_num,
                pos = 0,
            }
            need_exp = need_exp - need_num * exp_num.exp_cnt
            if need_exp <= 0 then
                break
            end
        end
    end

    return ErrorCode.None, max_exp - role_info.exp, cost_items
end

function Role.UpExp(roleid, exp_cnt)
    local roles = scripts.UserModel.GetRoles()
    if not roles or not roles.role_list or not roles.role_list[roleid] then
        return ErrorCode.RoleNotExist
    end

    local role_info = roles.role_list[roleid]
    local new_lv_exp = {}

    local up_exp_cfgs = GameCfg.RoleUpLv
    if up_exp_cfgs then
        for _, cfg in pairs(up_exp_cfgs) do
            if cfg.allexp > role_info.exp then
                if role_info.exp + exp_cnt >= cfg.allexp then
                    table.insert(new_lv_exp, { lv = cfg.id, exp = cfg.allexp })
                else
                    break
                end
            end
        end
    end

    -- 增加经验
    role_info.exp = role_info.exp + exp_cnt

    if table.size(new_lv_exp) > 0 then
        Role.GetLvMoreThanNum(roleid, new_lv_exp)
    end

    return ErrorCode.None
end

function Role.GetStarMoreThanNum(target_role_id, target_star)
    local roles = scripts.UserModel.GetRoles()
    if not roles or not roles.role_list then
        return 0
    end

    local num = 0
    for roleid, role_info in pairs(roles.role_list) do
        if roleid ~= target_role_id and role_info.star_level >= target_star then
            num = num + 1
        end
    end
    return num
end

function Role.GetMaxStarRoleid()
    local roles = scripts.UserModel.GetRoles()
    if not roles or not roles.role_list then
        return 0, 0
    end

    local max_star, cur_roleid = 0, 0
    for roleid, role_info in pairs(roles.role_list) do
        if role_info.star_level > max_star then
            max_star = role_info.star_level
            cur_roleid = roleid
        end
    end

    return max_star, cur_roleid
end

function Role.UpStar(roleid)
    local roles = scripts.UserModel.GetRoles()
    if not roles or not roles.role_list or not roles.role_list[roleid] then
        return ErrorCode.RoleNotExist
    end

    local role_info = roles.role_list[roleid]
    local star_cfg = GameCfg.UpStar[role_info.config_id]
    if not star_cfg then
        return ErrorCode.ConfigError
    end
    if role_info.star_level >= star_cfg.maxlv then
        return ErrorCode.ItemMaxStar
    end

    local up_exp_cfgs = GameCfg.RoleUpLv
    if not up_exp_cfgs then
        return ErrorCode.ConfigError
    end
    local max_star = 0
    for _, up_exp_cfg in pairs(up_exp_cfgs) do
        if up_exp_cfg.allexp <= role_info.exp then
            if up_exp_cfg.max_star > max_star then
                max_star = up_exp_cfg.max_star
            end
        else
            break
        end
    end
    if role_info.star_level + 1 > max_star then
        return ErrorCode.ItemMaxStar
    end

    local cost_key = "cost" .. (role_info.star_level + 1)
    if not star_cfg[cost_key] then
        return ErrorCode.ConfigError
    end
    local cost_cfg = star_cfg[cost_key]

    local rate_key = "rate" .. (role_info.star_level + 1)
    if not star_cfg[rate_key] then
        return ErrorCode.ConfigError
    end
    local rate_cfg = star_cfg[rate_key]

    local add_rate_cfg = CommonCfgDef.getConf("UpStarAdditionRate")
    if not add_rate_cfg then
        return ErrorCode.ConfigError
    end

    -- 计算消耗资源
    local cost_items = {}
    local cost_coins = {}
    ItemDefine.GetItemsFromCfg(cost_cfg, 1, true, cost_items, cost_coins)

    -- 检查资源是否足够
    local err_code_items = scripts.Bag.CheckItemsEnough(BagDef.BagType.Cangku, cost_items, {})
    if err_code_items ~= ErrorCode.None then
        return err_code_items
    end
    local err_code_coins = scripts.Bag.CheckCoinsEnough(cost_coins)
    if err_code_coins ~= ErrorCode.None then
        return err_code_coins
    end

    -- 扣除消耗
    local change_log = {}
    local err_code_del = ErrorCode.None
    if table.size(cost_items) > 0 then
        err_code_del = scripts.Bag.DelItems(BagDef.BagType.Cangku, cost_items, {}, change_log)
        if err_code_del ~= ErrorCode.None then
            scripts.Bag.RollBackWithChange(change_log)
            return err_code_del
        end
    end
    if table.size(cost_coins) > 0 then
        err_code_del = scripts.Bag.DealCoins(cost_coins, change_log)
        if err_code_del ~= ErrorCode.None then
            scripts.Bag.RollBackWithChange(change_log)
            return err_code_del
        end
    end

    -- 计算升星概率
    local now_rate = rate_cfg + add_rate_cfg.value * role_info.star_fail_cnt
    local random_rate = math.random(1, 10000)
    if random_rate > now_rate then
        -- 增加升星失败次数
        role_info.star_fail_cnt = role_info.star_fail_cnt + 1
        return ErrorCode.UpStarProbFail, change_log
    else
        -- 增加星星
        role_info.star_level = role_info.star_level + 1
        role_info.star_fail_cnt = 0

        -- 触发角色达到星级的数量
        local num = Role.GetStarMoreThanNum(roleid, role_info.star_level)
        scripts.Mission.TriggerCondition(MissionDef.EConditionIds.ROLE_STAR_CNT, { role_info.star_level }, num + 1)
        scripts.Mission.TriggerCondition(MissionDef.EConditionIds.ROLE_STAR, { roleid }, role_info.star_level)

        return ErrorCode.None, change_log
    end
end

function Role.PBRoleWearEquipReqCmd(req)
    -- 参数验证
    if not req.msg.roleid
        or not req.msg.equip_config_id
        or not req.msg.equip_uniqid
        or not req.msg.pos
        or req.msg.pos <= 0 then
        return context.S2C(context.net_id, CmdCode["PBRoleWearEquipRspCmd"],
            { code = ErrorCode.ParamInvalid, error = "无效请求参数", uid = req.msg.uid }, req.msg_context.stub_id)
    end

    local roles = scripts.UserModel.GetRoles()
    if not roles then
        return context.S2C(context.net_id, CmdCode["PBRoleWearEquipRspCmd"],
            { code = ErrorCode.ServerInternalError, error = "数据加载出错", uid = context.uid }, req.msg_context.stub_id)
    end

    if context.lock_item_role == 1 then
        return context.S2C(context.net_id, CmdCode.PBRoleWearEquipRspCmd,
            { code = ErrorCode.LockItemRole, error = "变更操作被锁定", uid = context.uid }, req.msg_context.stub_id)
    end

    local role_info = roles.role_list[req.msg.roleid]
    if not role_info then
        return context.S2C(context.net_id, CmdCode["PBRoleWearEquipRspCmd"],
            { code = ErrorCode.RoleNotExist, error = "角色不存在", uid = context.uid }, req.msg_context.stub_id)
    end

    local role_cfg = GameCfg.HumanRole[req.msg.roleid]
    if not role_cfg then
        return context.S2C(context.net_id, CmdCode["PBRoleWearEquipRspCmd"],
            { code = ErrorCode.ConfigError, error = "no role_cfg" }, req.msg_context.stub_id)
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

    local item_small_type, takeoff_item_data = Role.GetRoleEquipment(role_info, item_data.common_info.config_id,
        req.msg.equip_idx)
    if item_small_type ~= ItemDefine.EItemSmallType.MagicItem
        and item_small_type ~= ItemDefine.EItemSmallType.HumanDiagrams
        and item_small_type ~= ItemDefine.EItemSmallType.SpaceRing then
        return context.S2C(context.net_id, CmdCode["PBRoleWearEquipRspCmd"],
            { code = ErrorCode.ItemNotExist, error = "装备不存在", uid = context.uid }, req.msg_context.stub_id)
    end
    if item_small_type == ItemDefine.EItemSmallType.MagicItem then
        -- 检测法器类型是否正确
        --local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
        local uniqitem_cfg = GameCfg.UniqueItem[item_data.common_info.config_id]
        if not uniqitem_cfg or uniqitem_cfg.type4 ~= role_cfg.magic_slot_type then
            return context.S2C(context.net_id, CmdCode["PBRoleWearEquipRspCmd"],
                { code = ErrorCode.ConfigError, error = "法器类型错误", uid = context.uid }, req.msg_context.stub_id)
        end
    end
    if item_small_type == ItemDefine.EItemSmallType.HumanDiagrams then
        -- 检测八卦牌位置是否正确
        local uniqitem_cfg = GameCfg.UniqueItem[item_data.common_info.config_id]
        if not uniqitem_cfg or uniqitem_cfg.type5 ~= req.msg.equip_idx then
            return context.S2C(context.net_id, CmdCode["PBRoleWearEquipRspCmd"],
                { code = ErrorCode.ConfigError, error = "八卦牌类型错误", uid = context.uid }, req.msg_context.stub_id)
        end
    end

    -- 扣除道具消耗
    err_code = scripts.Bag.DelItems(req.msg.bag_name, {}, del_unique_items, bag_change_log)
    if err_code ~= ErrorCode.None then
        scripts.Bag.RollBackWithChange(bag_change_log)
        return context.S2C(context.net_id, CmdCode["PBRoleWearEquipRspCmd"],
            { code = err_code, error = "更换装备失败", uid = context.uid }, req.msg_context.stub_id)
    end
    item_data.common_info.trade_cnt = 0

    if takeoff_item_data then
        local takeoff_items = {}
        table.insert(takeoff_items, takeoff_item_data)
        -- 添加道具
        err_code = scripts.Bag.AddItems(req.msg.bag_name, {}, takeoff_items, bag_change_log)
        if err_code ~= ErrorCode.None then
            scripts.Bag.RollBackWithChange(bag_change_log)
            return context.S2C(context.net_id, CmdCode["PBRoleWearEquipRspCmd"],
                { code = err_code, error = "更换装备失败", uid = context.uid }, req.msg_context.stub_id)
        end
    end

    -- 角色穿戴新装备
    Role.ChangeEquipment(roles.battle_role_id, roles.model_role_id, role_info, item_data.common_info.config_id, req.msg.equip_idx, item_data)

    -- 保存数据并同步给客户端
    -- local save_bags = {}
    -- for bagType, _ in pairs(bag_change_log) do
    --     save_bags[bagType] = 1
    -- end
    -- --local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
    -- scripts.Bag.SaveAndLog(save_bags, bag_change_log)
    scripts.Bag.SaveAndLog(bag_change_log, ItemDef.ChangeReason.RoleWearEquip, req.msg.roleid)

    local change_roles = {}
    change_roles[req.msg.roleid] = "WearEquipment"
    Role.SaveAndLog(change_roles)

    if item_small_type == ItemDefine.EItemSmallType.MagicItem then
        local cur_uniqitem_cfg = GameCfg.UniqueItem[item_data.common_info.config_id]
        if cur_uniqitem_cfg and cur_uniqitem_cfg.type2 then
            -- 触发角色装备法器的数量
            scripts.Mission.TriggerCondition(MissionDef.EConditionIds.ROLE_EQUIP_MAGIC_ITEM_CNT,
                { role_info.config_id, cur_uniqitem_cfg.type2 }, 1)
        end
    elseif item_small_type == ItemDefine.EItemSmallType.HumanDiagrams then
        local cur_uniqitem_cfg = GameCfg.UniqueItem[item_data.common_info.config_id]
        if cur_uniqitem_cfg and cur_uniqitem_cfg.type2 then
            local cur_num = 0
            for _, digrams_card in pairs(role_info.digrams_cards) do
                local uniqitem_cfg = GameCfg.UniqueItem[item_data.common_info.config_id]
                if uniqitem_cfg
                    and uniqitem_cfg.type2
                    and uniqitem_cfg.type2 == cur_uniqitem_cfg.type2 then
                    cur_num = cur_num + 1
                end
            end
            -- 触发角色装备八卦牌的数量
            scripts.Mission.TriggerCondition(MissionDef.EConditionIds.ROLE_EQUIP_DIAGRAMS_CNT,
                { role_info.config_id, cur_uniqitem_cfg.type2 }, cur_num + 1)
        end
    end

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
    -- 参数验证
    if not req.msg.roleid
        or not req.msg.takeoff_config_id
        or not req.msg.takeoff_uniqid then
        return context.S2C(context.net_id, CmdCode["PBRoleTakeOffEquipRspCmd"],
            { code = ErrorCode.ParamInvalid, error = "无效请求参数", uid = req.msg.uid }, req.msg_context.stub_id)
    end

    local roles = scripts.UserModel.GetRoles()
    if not roles then
        return context.S2C(context.net_id, CmdCode["PBRoleTakeOffEquipRspCmd"],
            { code = ErrorCode.ServerInternalError, error = "数据加载出错", uid = context.uid }, req.msg_context.stub_id)
    end

    if context.lock_item_role == 1 then
        return context.S2C(context.net_id, CmdCode.PBRoleTakeOffEquipRspCmd,
            { code = ErrorCode.LockItemRole, error = "变更操作被锁定", uid = context.uid }, req.msg_context.stub_id)
    end

    local role_info = roles.role_list[req.msg.roleid]
    if not role_info then
        return context.S2C(context.net_id, CmdCode["PBRoleTakeOffEquipRspCmd"],
            { code = ErrorCode.RoleNotExist, error = "角色不存在", uid = context.uid }, req.msg_context.stub_id)
    end

    local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
    local bag_change_log = {}
    local err_code = ErrorCode.None
    local item_small_type, takeoff_item_data = Role.GetRoleEquipment(role_info, req.msg.takeoff_config_id,
        req.msg.takeoff_idx)
    if item_small_type ~= ItemDefine.EItemSmallType.MagicItem
        and item_small_type ~= item_small_type == ItemDefine.EItemSmallType.HumanDiagrams
        and item_small_type ~= ItemDefine.EItemSmallType.SpaceRing then
        return context.S2C(context.net_id, CmdCode["PBRoleTakeOffEquipRspCmd"],
            { code = ErrorCode.ItemNotExist, error = "装备不存在", uid = context.uid }, req.msg_context.stub_id)
    end
    if item_small_type == ItemDefine.EItemSmallType.HumanDiagrams then
        -- 检测八卦牌位置是否正确
        local uniqitem_cfg = GameCfg.UniqueItem[req.msg.takeoff_config_id]
        if not uniqitem_cfg or uniqitem_cfg.type5 ~= req.msg.takeoff_idx then
            return context.S2C(context.net_id, CmdCode["PBRoleTakeOffEquipRspCmd"],
                { code = ErrorCode.ConfigError, error = "八卦牌配置不存在", uid = context.uid }, req.msg_context.stub_id)
        end
    end

    -- 判断卸下的装备是否一致
    if not takeoff_item_data
        or not takeoff_item_data.common_info
        or takeoff_item_data.common_info.config_id ~= req.msg.takeoff_config_id
        or takeoff_item_data.common_info.uniqid ~= req.msg.takeoff_uniqid then
        return context.S2C(context.net_id, CmdCode["PBRoleTakeOffEquipRspCmd"],
            { code = ErrorCode.ItemNotExist, error = "装备不存在", uid = context.uid }, req.msg_context.stub_id)
    end

    local takeoff_items = {}
    table.insert(takeoff_items, takeoff_item_data)
    -- 添加道具
    err_code = scripts.Bag.AddItems(req.msg.bag_name, {}, takeoff_items, bag_change_log)
    if err_code ~= ErrorCode.None then
        scripts.Bag.RollBackWithChange(bag_change_log)
        return context.S2C(context.net_id, CmdCode["PBRoleTakeOffEquipRspCmd"],
            { code = err_code, error = "更换装备失败", uid = context.uid }, req.msg_context.stub_id)
    end

    -- 角色卸下新装备
    Role.ChangeEquipment(roles.battle_role_id, roles.model_role_id, role_info, req.msg.takeoff_config_id, req.msg.takeoff_idx, nil)

    -- 保存数据并同步给客户端
    -- local save_bags = {}
    -- for bagType, _ in pairs(bag_change_log) do
    --     save_bags[bagType] = 1
    -- end
    -- scripts.Bag.SaveAndLog(save_bags, bag_change_log)
    scripts.Bag.SaveAndLog(bag_change_log, ItemDef.ChangeReason.RoleTakeoffEquip, req.msg.roleid)

    local change_roles = {}
    change_roles[req.msg.roleid] = "TakeOffEquipment"
    Role.SaveAndLog(change_roles)

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

function Role.PBRoleWearSkinReqCmd(req)
    local roles = scripts.UserModel.GetRoles()
    if not roles then
        return context.S2C(context.net_id, CmdCode["PBRoleWearSkinRspCmd"],
            { code = ErrorCode.ServerInternalError, error = "数据加载出错", uid = context.uid }, req.msg_context.stub_id)
    end

    local role_info = roles.role_list[req.msg.roleid]
    if not role_info then
        return context.S2C(context.net_id, CmdCode["PBRoleWearSkinRspCmd"],
            { code = ErrorCode.RoleNotExist, error = "角色不存在", uid = context.uid }, req.msg_context.stub_id)
    end

    for idx, skin_id in pairs(req.msg.skins) do
        if skin_id > 0 then
            local is_valid = scripts.ItemImage.CheckImageValid(skin_id)
            if not is_valid then
                return context.S2C(context.net_id, CmdCode["PBRoleWearSkinRspCmd"],
                    { code = ErrorCode.ItemNotExist, error = "皮肤不存在", uid = context.uid }, req.msg_context.stub_id)
            end
            local skin_cfg = GameCfg.Skin[skin_id]
            if not skin_cfg then
                return context.S2C(context.net_id, CmdCode["PBRoleWearSkinRspCmd"],
                    { code = ErrorCode.ConfigError, error = "配置错误", uid = context.uid }, req.msg_context.stub_id)
            end
            if skin_cfg.belong ~= req.msg.roleid then
                return context.S2C(context.net_id, CmdCode["PBRoleWearSkinRspCmd"],
                    { code = ErrorCode.SkinNotMatch, error = "皮肤不匹配", uid = context.uid }, req.msg_context.stub_id)
            end
        end
    end

    -- for idx, skin_id in pairs(req.msg.skins) do
    --     role_info.skins[idx] = skin_id
    -- end
    role_info.skins = req.msg.skins

    context.S2C(context.net_id, CmdCode["PBRoleWearSkinRspCmd"],
        { code = ErrorCode.None, error = "", uid = context.uid, roleid = req.msg.roleid, skins = role_info.skins },
        req.msg_context.stub_id)

    local change_roles = {}
    change_roles[req.msg.roleid] = "WearSkin"
    Role.SaveAndLog(change_roles)
end

function Role.PBRoleChangeEmojiReqCmd(req)
    -- 参数验证
    if not req.msg.roleid or not req.msg.emoji or table.size(req.msg.emoji) == 0 then
        return context.S2C(context.net_id, CmdCode.PBRoleChangeEmojiRspCmd, {
            code = ErrorCode.ParamInvalid,
            error = "无效请求参数",
            uid = context.uid,
            roleid = req.msg.roleid or 0,
            emoji = req.msg.emoji or {},
        }, req.msg_context.stub_id)
    end

    local roles = scripts.UserModel.GetRoles()
    if not roles then
        return context.S2C(context.net_id, CmdCode["PBRoleChangeEmojiRspCmd"],
            { code = ErrorCode.ServerInternalError, error = "数据加载出错", uid = context.uid }, req.msg_context.stub_id)
    end

    local role_info = roles.role_list[req.msg.roleid]
    if not role_info then
        return context.S2C(context.net_id, CmdCode["PBRoleChangeEmojiRspCmd"],
            { code = ErrorCode.RoleNotExist, error = "角色不存在", uid = context.uid }, req.msg_context.stub_id)
    end

    local role_cfg = GameCfg.HumanRole[role_info.config_id]
    if not role_cfg or role_cfg.action_slot_num < table.size(req.msg.emoji) then
        return context.S2C(context.net_id, CmdCode["PBRoleChangeEmojiRspCmd"],
            { code = ErrorCode.ConfigError, error = "配置错误", uid = context.uid }, req.msg_context.stub_id)
    end

    for _, emoji_id in pairs(req.msg.emoji) do
        local is_valid = scripts.ItemImage.CheckImageValid(emoji_id)
        if not is_valid then
            return context.S2C(context.net_id, CmdCode["PBRoleChangeEmojiRspCmd"],
                { code = ErrorCode.ItemNotExist, error = "表情不存在", uid = context.uid }, req.msg_context.stub_id)
        end

        local emoji_cfg = GameCfg.Skin[emoji_id]
        if not emoji_cfg then
            return context.S2C(context.net_id, CmdCode["PBRoleChangeEmojiRspCmd"],
                { code = ErrorCode.EmojiNotMatch, error = "表情类型不匹配", uid = context.uid }, req.msg_context.stub_id)
        end
        local emoji_match = false
        for _, emoji_type in pairs(role_cfg.action_slot_type) do
            if emoji_type == emoji_cfg.type then
                emoji_match = true
                break
            end
        end
        if not emoji_match then
            return context.S2C(context.net_id, CmdCode["PBRoleChangeEmojiRspCmd"],
                { code = ErrorCode.EmojiNotMatch, error = "表情类型不匹配", uid = context.uid }, req.msg_context.stub_id)
        end
    end

    role_info.emoji = req.msg.emoji

    context.S2C(context.net_id, CmdCode["PBRoleChangeEmojiRspCmd"],
        { code = ErrorCode.None, error = "", uid = context.uid, roleid = req.msg.roleid, emoji = req.msg.emoji },
        req.msg_context.stub_id)

    local change_roles = {}
    change_roles[req.msg.roleid] = "ChangeEmoji"
    Role.SaveAndLog(change_roles)
end

function Role.PBChangeBattleRoleReqCmd(req)
    local roles = scripts.UserModel.GetRoles()
    if not roles then
        return context.S2C(context.net_id, CmdCode["PBChangeBattleRoleRspCmd"],
            { code = ErrorCode.ServerInternalError, error = "数据加载出错", uid = context.uid }, req.msg_context.stub_id)
    end

    if context.lock_item_role == 1 then
        return context.S2C(context.net_id, CmdCode.PBChangeBattleRoleRspCmd,
            { code = ErrorCode.LockItemRole, error = "变更操作被锁定", uid = context.uid }, req.msg_context.stub_id)
    end

    local role_info = roles.role_list[req.msg.roleid]
    if not role_info then
        return context.S2C(context.net_id, CmdCode["PBChangeBattleRoleRspCmd"],
            { code = ErrorCode.RoleNotExist, error = "角色不存在", uid = context.uid }, req.msg_context.stub_id)
    end

    Role.SetRoleBattle(req.msg.roleid, true)
    -- Role.SaveRolesNow()
    scripts.UserModel.AddDirtyModule("Role")
    return context.S2C(context.net_id, CmdCode["PBChangeBattleRoleRspCmd"],
        { code = ErrorCode.None, error = "success", uid = context.uid, roleid = req.msg.roleid }, req.msg_context.stub_id)
end

function Role.PBChangeModelRoleReqCmd(req)
    local roles = scripts.UserModel.GetRoles()
    if not roles then
        return context.S2C(context.net_id, CmdCode.PBChangeModelRoleRspCmd,
            { code = ErrorCode.ServerInternalError, error = "数据加载出错", uid = context.uid }, req.msg_context.stub_id)
    end

    local role_info = roles.role_list[req.msg.roleid]
    if not role_info then
        return context.S2C(context.net_id, CmdCode.PBChangeModelRoleRspCmd,
            { code = ErrorCode.RoleNotExist, error = "角色不存在", uid = context.uid }, req.msg_context.stub_id)
    end

    Role.SetRoleModel(req.msg.roleid, true)
    -- Role.SaveRolesNow()
    scripts.UserModel.AddDirtyModule("Role")
    return context.S2C(context.net_id, CmdCode.PBChangeModelRoleRspCmd,
        { code = ErrorCode.None, error = "success", uid = context.uid, roleid = req.msg.roleid }, req.msg_context.stub_id)
end


function Role.PBRoleSkillUpStarReqCmd(req)
    local roles = scripts.UserModel.GetRoles()
    if not roles then
        return context.S2C(context.net_id, CmdCode["PBRoleSkillUpStarRspCmd"],
            { code = ErrorCode.ServerInternalError, error = "数据加载出错", uid = context.uid }, req.msg_context.stub_id)
    end

    local role_info = roles.role_list[req.msg.roleid]
    if not role_info then
        return context.S2C(context.net_id, CmdCode["PBRoleSkillUpStarRspCmd"],
            { code = ErrorCode.RoleNotExist, error = "角色不存在", uid = context.uid }, req.msg_context.stub_id)
    end

    -- 确定升级的技能
    local skill_star = -1
    local skill_name = "none"
    local skill_star_fail_cnt = 0
    for id, skill in pairs(role_info.main_skill) do
        if id == req.msg.skill_id then
            skill_star = skill.star
            skill_name = "main_skill"
            skill_star_fail_cnt = skill.star_fail_cnt
            break
        end
    end
    if skill_star < 0 then
        for id, skill in pairs(role_info.minor_skill1) do
            if id == req.msg.skill_id then
                skill_star = skill.star
                skill_name = "minor_skill1"
                skill_star_fail_cnt = skill.star_fail_cnt
                break
            end
        end
    end
    if skill_star < 0 then
        for id, skill in pairs(role_info.minor_skill2) do
            if id == req.msg.skill_id then
                skill_star = skill.star
                skill_name = "minor_skill2"
                skill_star_fail_cnt = skill.star_fail_cnt
                break
            end
        end
    end
    if skill_star < 0 then
        for id, skill in pairs(role_info.passive_skill) do
            if id == req.msg.skill_id then
                skill_star = skill.star
                skill_name = "passive_skill"
                skill_star_fail_cnt = skill.star_fail_cnt
                break
            end
        end
    end
    if skill_star < 0 or skill_name == "none" then
        return context.S2C(context.net_id, CmdCode["PBRoleSkillUpStarRspCmd"],
            { code = ErrorCode.SkillNotExist, error = "技能不存在", uid = context.uid }, req.msg_context.stub_id)
    end

    local star_cfg = GameCfg.UpStar[req.msg.skill_id]
    if not star_cfg then
        return context.S2C(context.net_id, CmdCode["PBRoleSkillUpStarRspCmd"],
            { code = ErrorCode.ConfigError, error = "配置不存在", uid = context.uid }, req.msg_context.stub_id)
    end
    if skill_star >= star_cfg.maxlv then
        return context.S2C(context.net_id, CmdCode["PBRoleSkillUpStarRspCmd"],
            { code = ErrorCode.ItemMaxStar, error = "已达最大等级", uid = context.uid }, req.msg_context.stub_id)
    end

    local cost_key = "cost" .. (skill_star + 1)
    if not star_cfg[cost_key] then
        return context.S2C(context.net_id, CmdCode["PBRoleSkillUpStarRspCmd"],
            { code = ErrorCode.ConfigError, error = "配置不存在", uid = context.uid }, req.msg_context.stub_id)
    end
    local cost_cfg = star_cfg[cost_key]

    local rate_key = "rate" .. (skill_star + 1)
    if not star_cfg[rate_key] then
        return ErrorCode.ConfigError
    end
    local rate_cfg = star_cfg[rate_key]

    local add_rate_cfg = CommonCfgDef.getConf("UpStarAdditionRate")
    if not add_rate_cfg then
        return ErrorCode.ConfigError
    end

    -- 计算消耗资源
    local cost_items = {}
    local cost_coins = {}
    ItemDefine.GetItemsFromCfg(cost_cfg, 1, true, cost_items, cost_coins)

    -- 检查资源是否足够
    local err_code_items = scripts.Bag.CheckItemsEnough(BagDef.BagType.Cangku, cost_items, {})
    if err_code_items ~= ErrorCode.None then
        return context.S2C(context.net_id, CmdCode["PBRoleSkillUpStarRspCmd"],
            { code = err_code_items, error = "道具不足", uid = context.uid }, req.msg_context.stub_id)
    end
    local err_code_coins = scripts.Bag.CheckCoinsEnough(cost_coins)
    if err_code_coins ~= ErrorCode.None then
        return context.S2C(context.net_id, CmdCode["PBRoleSkillUpStarRspCmd"],
            { code = err_code_coins, error = "金币不足", uid = context.uid, skill_id = req.msg.skill_id }, req.msg_context.stub_id)
    end

    -- 扣除消耗
    local bag_change_log = {}
    local err_code_del = ErrorCode.None
    if table.size(cost_items) > 0 then
        err_code_del = scripts.Bag.DelItems(BagDef.BagType.Cangku, cost_items, {}, bag_change_log)
        if err_code_del ~= ErrorCode.None then
            scripts.Bag.RollBackWithChange(bag_change_log)
            return context.S2C(context.net_id, CmdCode["PBRoleSkillUpStarRspCmd"],
                { code = err_code_del, error = "道具不足", uid = context.uid }, req.msg_context.stub_id)
        end
    end
    if table.size(cost_coins) > 0 then
        err_code_del = scripts.Bag.DealCoins(cost_coins, bag_change_log)
        if err_code_del ~= ErrorCode.None then
            scripts.Bag.RollBackWithChange(bag_change_log)
            return context.S2C(context.net_id, CmdCode["PBRoleSkillUpStarRspCmd"],
                { code = err_code_del, error = "金币不足", uid = context.uid }, req.msg_context.stub_id)
        end
    end

    -- 计算升星概率
    local now_rate = rate_cfg + add_rate_cfg.value * skill_star_fail_cnt
    local random_rate = math.random(1, 10000)
    if random_rate > now_rate then
        -- 增加升星失败次数
        for id, skill in pairs(role_info[skill_name]) do
            if id == req.msg.skill_id then
                skill.star_fail_cnt = skill_star_fail_cnt + 1
                break
            end
        end

        context.S2C(context.net_id, CmdCode.PBRoleSkillUpStarRspCmd, {
            code = ErrorCode.UpStarProbFail,
            error = "",
            uid = context.uid,
            roleid = req.msg.roleid,
            skill_id = req.msg.skill_id,
        }, req.msg_context.stub_id)
    else
        -- 增加星星
        skill_star = skill_star + 1
        for id, skill in pairs(role_info[skill_name]) do
            if id == req.msg.skill_id then
                skill.star = skill_star
                skill.star_fail_cnt = 0
                break
            end
        end

        context.S2C(context.net_id, CmdCode.PBRoleSkillUpStarRspCmd, {
            code = ErrorCode.None,
            error = "",
            uid = context.uid,
            roleid = req.msg.roleid,
            skill_id = req.msg.skill_id,
        }, req.msg_context.stub_id)
    end

    -- local save_bags = {}
    -- for bagType, _ in pairs(bag_change_log) do
    --     save_bags[bagType] = 1
    -- end
    -- if table.size(save_bags) > 0 then
    --     scripts.Bag.SaveAndLog(save_bags, bag_change_log)
    -- end
    if table.size(bag_change_log) > 0 then
        scripts.Bag.SaveAndLog(bag_change_log, ItemDef.ChangeReason.RoleSkillUpStar, req.msg.roleid)
    end

    local change_roles = {}
    change_roles[req.msg.roleid] = "SkillUpStar"
    scripts.Role.SaveAndLog(change_roles)
end

function Role.PBRoleGetUpLvRewardReqCmd(req)
    local roles = scripts.UserModel.GetRoles()
    if not roles then
        return context.S2C(context.net_id, CmdCode["PBRoleGetUpLvRewardRspCmd"],
            { code = ErrorCode.ServerInternalError, error = "数据加载出错", uid = context.uid }, req.msg_context.stub_id)
    end

    local role_info = roles.role_list[req.msg.roleid]
    if not role_info then
        return context.S2C(context.net_id, CmdCode["PBRoleGetUpLvRewardRspCmd"],
            { code = ErrorCode.RoleNotExist, error = "角色不存在", uid = context.uid }, req.msg_context.stub_id)
    end

    if not role_info.up_lv_rewards[req.msg.reward_id]
        and role_info.up_lv_rewards[req.msg.reward_id] > 0 then
        return context.S2C(context.net_id, CmdCode["PBRoleGetUpLvRewardRspCmd"],
            { code = ErrorCode.RoleRewardAlreadyGet, error = "奖励已经领取过", uid = context.uid }, req.msg_context.stub_id)
    end

    local reward_cfg = GameCfg.RoleLvAward[req.msg.reward_id]
    if not reward_cfg or reward_cfg.role_id ~= role_info.config_id then
        return context.S2C(context.net_id, CmdCode["PBRoleGetUpLvRewardRspCmd"],
            { code = ErrorCode.ConfigError, error = "奖励不存在", uid = context.uid }, req.msg_context.stub_id)
    end
    local up_exp_cfg = GameCfg.RoleUpLv[reward_cfg.lv]
    if not up_exp_cfg or up_exp_cfg.exp > role_info.exp then
        return context.S2C(context.net_id, CmdCode["PBRoleGetUpLvRewardRspCmd"],
            { code = ErrorCode.UpExpNotEnough, error = "等级不足", uid = context.uid }, req.msg_context.stub_id)
    end

    -- 计算获得资源
    local add_items, add_coins = {}, {}
    ItemDefine.GetItemsFromCfg(reward_cfg.award, 1, false, add_items, add_coins)
    if table.size(add_items) > 0 then
        local err_code = scripts.Bag.CheckEmptyEnough(BagDef.BagType.Cangku, add_items, 0)
        if err_code ~= ErrorCode.None then
            return context.S2C(context.net_id, CmdCode["PBRoleGetUpLvRewardRspCmd"],
                { code = err_code, error = "背包空间不足" }, req.msg_context.stub_id)
        end
    end

    -- 根据道具表生成item_data
    -- local add_list = {}
    -- ItemDefine.GetItemListFromItemsCoins(add_items, add_coins, add_list)
    if table.size(add_items) + table.size(add_coins) <= 0 then
        return ErrorCode.ConfigError
    end
    local stack_items, unstack_items, deal_coins = {}, {}, {}
    local ok = ItemDefine.GetItemDataFromIdCount(add_items, add_coins, stack_items, unstack_items, deal_coins)
    if not ok then
        return ErrorCode.ConfigError
    end

    -- 领取奖励
    local bag_change_log = {}
    local err_code_add = ErrorCode.None
    if table.size(stack_items) + table.size(unstack_items) > 0 then
        err_code_add = scripts.Bag.AddItems(BagDef.BagType.Cangku, stack_items, unstack_items, bag_change_log)
        if err_code_add ~= ErrorCode.None then
            scripts.Bag.RollBackWithChange(bag_change_log)
            return context.S2C(context.net_id, CmdCode["PBRoleGetUpLvRewardRspCmd"],
                { code = err_code_add, error = "添加道具失败" }, req.msg_context.stub_id)
        end
    end
    if table.size(deal_coins) > 0 then
        err_code_add = scripts.Bag.DealCoins(deal_coins, bag_change_log)
        if err_code_add ~= ErrorCode.None then
            scripts.Bag.RollBackWithChange(bag_change_log)
            return context.S2C(context.net_id, CmdCode["PBRoleGetUpLvRewardRspCmd"],
                { code = err_code_add, error = "添加金币失败" }, req.msg_context.stub_id)
        end
    end

    -- 领取升级奖励记录
    role_info.up_lv_rewards[req.msg.reward_id] = 1
    local change_roles = {}
    change_roles[req.msg.roleid] = "UpLvReward"

    -- 执行完成回复
    context.S2C(context.net_id, CmdCode.PBRoleGetUpLvRewardRspCmd, {
        code = ErrorCode.None,
        error = "",
        uid = context.uid,
        roleid = req.msg.roleid,
        reward_id = req.msg.reward_id,
    }, req.msg_context.stub_id)

    -- 数据存储更新
    -- local save_bags = {}
    -- for bagType, _ in pairs(bag_change_log) do
    --     save_bags[bagType] = 1
    -- end
    -- scripts.Bag.SaveAndLog(save_bags, bag_change_log)
    scripts.Bag.SaveAndLog(bag_change_log, ItemDef.ChangeReason.RoleUpLvReward, req.msg.roleid)

    if table.size(change_roles) > 0 then
        scripts.Role.SaveAndLog(change_roles)
    end
end

function Role.PBRoleStudyBookReqCmd(req)
    --local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
    -- 参数验证
    if not req.msg.uid or not req.msg.roleid or not req.msg.book_id then
        return context.S2C(context.net_id, CmdCode.PBRoleStudyBookRspCmd, {
            code = ErrorCode.ParamInvalid,
            error = "无效请求参数",
            uid = req.msg.uid,
            roleid = req.msg.roleid or 0,
            book_id = req.msg.book_id or 0,
        }, req.msg_context.stub_id)
    end

    local roles = scripts.UserModel.GetRoles()
    if not roles then
        return context.S2C(context.net_id, CmdCode["PBRoleStudyBookRspCmd"],
            { code = ErrorCode.ServerInternalError, error = "数据加载出错", uid = context.uid }, req.msg_context.stub_id)
    end

    local role_info = roles.role_list[req.msg.roleid]
    if not role_info then
        return context.S2C(context.net_id, CmdCode["PBRoleStudyBookRspCmd"],
            { code = ErrorCode.RoleNotExist, error = "角色不存在", uid = context.uid }, req.msg_context.stub_id)
    end

    local book_cfg = GameCfg.Book[req.msg.book_id]
    if not book_cfg then
        return context.S2C(context.net_id, CmdCode["PBRoleStudyBookRspCmd"],
            { code = ErrorCode.ConfigError, error = "书籍不存在", uid = context.uid }, req.msg_context.stub_id)
    end

    -- 检查书籍是否已经学习
    if role_info.equip_books[req.msg.book_id]
        or role_info.study_books[req.msg.book_id] then
        return context.S2C(context.net_id, CmdCode["PBRoleStudyBookRspCmd"],
            { code = ErrorCode.BookAlreadyStudy, error = "书籍已经学习", uid = context.uid }, req.msg_context.stub_id)
    end

    -- 检查学习前置条件是否达成
    local pre_study = true
    for _, pre_book_id in pairs(book_cfg.condition) do
        if not role_info.equip_books[pre_book_id] then
            pre_study = false
            break
        end
    end
    if not pre_study then
        return context.S2C(context.net_id, CmdCode["PBRoleStudyBookRspCmd"],
            { code = ErrorCode.BookPreNotStudy, error = "书籍前置条件未达成", uid = context.uid }, req.msg_context.stub_id)
    end

    -- 检查是否有真经
    local cost_items = {}
    cost_items[req.msg.book_id] = {
        id = req.msg.book_id,
        count = -1,
        pos = 0,
    }
    local err_code = scripts.Bag.CheckItemsEnough(BagDef.BagType.Cangku, cost_items, {})
    if err_code ~= ErrorCode.None then
        return context.S2C(context.net_id, CmdCode["PBRoleStudyBookRspCmd"],
            { code = err_code, error = "道具不足" }, req.msg_context.stub_id)
    end
    -- 扣除消耗
    local bag_change_log = {}
    local err_code_del = scripts.Bag.DelItems(BagDef.BagType.Cangku, cost_items, {}, bag_change_log)
    if err_code_del ~= ErrorCode.None then
        scripts.Bag.RollBackWithChange(bag_change_log)
        return context.S2C(context.net_id, CmdCode["PBRoleStudyBookRspCmd"],
            { code = err_code_del, error = "道具不足", uid = context.uid }, req.msg_context.stub_id)
    end

    -- 学习真经
    local study_book = RoleDef.newStudyBook()
    study_book.book_id = req.msg.book_id
    study_book.start_time = moon.time()
    study_book.end_time = moon.time() + book_cfg.time
    study_book.now_time = moon.time()
    role_info.study_books[req.msg.book_id] = study_book

    context.S2C(context.net_id, CmdCode.PBRoleStudyBookRspCmd, {
        code = ErrorCode.None,
        error = "",
        uid = context.uid,
        roleid = req.msg.roleid,
        book_id = req.msg.book_id,
    }, req.msg_context.stub_id)

    -- local save_bags = {}
    -- for bagType, _ in pairs(bag_change_log) do
    --     save_bags[bagType] = 1
    -- end
    -- if table.size(save_bags) > 0 then
    --     scripts.Bag.SaveAndLog(save_bags, bag_change_log)
    -- end
    if table.size(bag_change_log) > 0 then
        scripts.Bag.SaveAndLog(bag_change_log, ItemDef.ChangeReason.RoleStudyBook, req.msg.roleid)
    end

    local change_roles = {}
    change_roles[req.msg.roleid] = "StudyBook"
    scripts.Role.SaveAndLog(change_roles)
end

function Role.PBRoleSkillCompositeReqCmd(req)
    -- 参数验证
    if not req.msg.uid or not req.msg.roleid or not req.msg.composite_id then
        return context.S2C(context.net_id, CmdCode.PBRoleSkillCompositeRspCmd, {
            code = ErrorCode.ParamInvalid,
            error = "无效请求参数",
            uid = req.msg.uid,
            roleid = req.msg.roleid or 0,
            composite_id = req.msg.composite_id or 0,
        }, req.msg_context.stub_id)
    end

    local roles = scripts.UserModel.GetRoles()
    if not roles then
        return context.S2C(context.net_id, CmdCode.PBRoleSkillCompositeRspCmd,
            { code = ErrorCode.ServerInternalError, error = "数据加载出错", uid = req.msg.uid }, req.msg_context.stub_id)
    end

    local role_info = roles.role_list[req.msg.roleid]
    if not role_info then
        return context.S2C(context.net_id, CmdCode.PBRoleSkillCompositeRspCmd,
            { code = ErrorCode.RoleNotExist, error = "角色不存在", uid = req.msg.uid }, req.msg_context.stub_id)
    end

    local rsp_msg = {
        code = ErrorCode.None,
        error = "",
        uid = req.msg.uid,
        roleid = req.msg.roleid or 0,
        composite_id = req.msg.composite_id or 0,
    }
    local composite_cfg = GameCfg.HumanSkill[req.msg.composite_id]
    local role_cfg = GameCfg.HumanRole[role_info.config_id]
    if not composite_cfg or not role_cfg then
        rsp_msg.code = ErrorCode.ConfigError
        rsp_msg.error = "配置不存在"
        return context.S2C(context.net_id, CmdCode.PBRoleSkillCompositeRspCmd, rsp_msg, req.msg_context.stub_id)
    end

    -- 检查是否已经激活和技能是否匹配
    local _find = false
    if composite_cfg.role_id ~= role_info.config_id then
        rsp_msg.code = ErrorCode.RoleSkillNotMatch
        rsp_msg.error = "技能角色不匹配"
        return context.S2C(context.net_id, CmdCode.PBRoleSkillCompositeRspCmd, rsp_msg, req.msg_context.stub_id)
    end
    if composite_cfg.type == RoleDef.SkillType.MinorSkill_1 then
        if role_info.minor_skill1[composite_cfg.id]
            and role_info.minor_skill1[composite_cfg.id].star >= 0 then
            rsp_msg.code = ErrorCode.RoleSkillAlreadyActive
            rsp_msg.error = "技能已激活"
            return context.S2C(context.net_id, CmdCode.PBRoleSkillCompositeRspCmd, rsp_msg, req.msg_context.stub_id)
        end
        for _, skill_id in pairs(role_cfg.q_skill) do
            if skill_id == req.msg.composite_id then
                _find = true
            end
        end
        if not _find then
            rsp_msg.code = ErrorCode.RoleSkillNotMatch
            rsp_msg.error = "技能不匹配"
            return context.S2C(context.net_id, CmdCode.PBRoleSkillCompositeRspCmd, rsp_msg, req.msg_context.stub_id)
        end
    elseif composite_cfg.type == RoleDef.SkillType.MinorSkill_2 then
        if role_info.minor_skill2[composite_cfg.id]
            and role_info.minor_skill2[composite_cfg.id].star >= 0 then
            rsp_msg.code = ErrorCode.RoleSkillAlreadyActive
            rsp_msg.error = "技能已激活"
            return context.S2C(context.net_id, CmdCode.PBRoleSkillCompositeRspCmd, rsp_msg, req.msg_context.stub_id)
        end
        for _, skill_id in pairs(role_cfg.e_skill) do
            if skill_id == req.msg.composite_id then
                _find = true
            end
        end
        if not _find then
            rsp_msg.code = ErrorCode.RoleSkillNotMatch
            rsp_msg.error = "技能不匹配"
            return context.S2C(context.net_id, CmdCode.PBRoleSkillCompositeRspCmd, rsp_msg, req.msg_context.stub_id)
        end
    elseif composite_cfg.type == RoleDef.SkillType.PassiveSkill then
        if role_info.passive_skill[composite_cfg.id]
            and role_info.passive_skill[composite_cfg.id].star >= 0 then
            rsp_msg.code = ErrorCode.RoleSkillAlreadyActive
            rsp_msg.error = "技能已激活"
            return context.S2C(context.net_id, CmdCode.PBRoleSkillCompositeRspCmd, rsp_msg, req.msg_context.stub_id)
        end
        for _, skill_id in pairs(role_cfg.passive_skill) do
            if skill_id == req.msg.composite_id then
                _find = true
            end
        end
        if not _find then
            rsp_msg.code = ErrorCode.RoleSkillNotMatch
            rsp_msg.error = "技能不匹配"
            return context.S2C(context.net_id, CmdCode.PBRoleSkillCompositeRspCmd, rsp_msg, req.msg_context.stub_id)
        end
    elseif composite_cfg.type == RoleDef.SkillType.MainSkill then
        if role_info.main_skill[composite_cfg.id]
            and role_info.main_skill[composite_cfg.id].star >= 0 then
            rsp_msg.code = ErrorCode.RoleSkillAlreadyActive
            rsp_msg.error = "技能已激活"
            return context.S2C(context.net_id, CmdCode.PBRoleSkillCompositeRspCmd, rsp_msg, req.msg_context.stub_id)
        end
        for _, skill_id in pairs(role_cfg.main_skill) do
            if skill_id == req.msg.composite_id then
                _find = true
            end
        end
        if not _find then
            rsp_msg.code = ErrorCode.RoleSkillNotMatch
            rsp_msg.error = "技能不匹配"
            return context.S2C(context.net_id, CmdCode.PBRoleSkillCompositeRspCmd, rsp_msg, req.msg_context.stub_id)
        end
    else
        rsp_msg.code = ErrorCode.ConfigError
        rsp_msg.error = "配置不存在"
        return context.S2C(context.net_id, CmdCode.PBRoleSkillCompositeRspCmd, rsp_msg, req.msg_context.stub_id)
    end

    local cost_items = {}
    local cost_coins = {}
    ItemDefine.GetItemsFromCfg(composite_cfg.unlock_cost, 1, true, cost_items, cost_coins)

    -- 检测道具是否足够
    rsp_msg.code = scripts.Bag.CheckItemsEnough(BagDef.BagType.Cangku, cost_items, {})
    if rsp_msg.code ~= ErrorCode.None then
        rsp_msg.error = "道具不足"
        return context.S2C(context.net_id, CmdCode.PBRoleSkillCompositeRspCmd, rsp_msg, req.msg_context.stub_id)
    end
    rsp_msg.code = scripts.Bag.CheckCoinsEnough(cost_coins)
    if rsp_msg.code ~= ErrorCode.None then
        rsp_msg.error = "货币不足"
        return context.S2C(context.net_id, CmdCode.PBRoleSkillCompositeRspCmd, rsp_msg, req.msg_context.stub_id)
    end

    local bag_change_log = {}
    local change_roles = {}
    -- 扣除道具消耗
    if table.size(cost_items) > 0 then
        rsp_msg.code = scripts.Bag.DelItems(req.msg.bag_name, cost_items, {}, bag_change_log)
        if rsp_msg.code ~= ErrorCode.None then
            scripts.Bag.RollBackWithChange(bag_change_log)
            return context.S2C(context.net_id, CmdCode.PBRoleSkillCompositeRspCmd, rsp_msg, req.msg_context.stub_id)
        end
    end
    if table.size(cost_coins) > 0 then
        rsp_msg.code = scripts.Bag.DealCoins(cost_coins, bag_change_log)
        if rsp_msg.code ~= ErrorCode.None then
            scripts.Bag.RollBackWithChange(bag_change_log)
            return context.S2C(context.net_id, CmdCode.PBRoleSkillCompositeRspCmd, rsp_msg, req.msg_context.stub_id)
        end
    end

    if composite_cfg.type == RoleDef.SkillType.MinorSkill_1 then
        local skill_info = ItemDef.newSkill()
        skill_info.config_id = req.msg.composite_id

        role_info.minor_skill1[req.msg.composite_id] = skill_info
    elseif composite_cfg.type == RoleDef.SkillType.MinorSkill_2 then
        local skill_info = ItemDef.newSkill()
        skill_info.config_id = req.msg.composite_id

        role_info.minor_skill2[req.msg.composite_id] = skill_info
    elseif composite_cfg.type == RoleDef.SkillType.PassiveSkill then
        local skill_info = ItemDef.newSkill()
        skill_info.config_id = req.msg.composite_id

        role_info.passive_skill[req.msg.composite_id] = skill_info
    elseif composite_cfg.type == RoleDef.SkillType.MainSkill then
        local skill_info = ItemDef.newSkill()
        skill_info.config_id = req.msg.composite_id

        role_info.main_skill[req.msg.composite_id] = skill_info
    else
        rsp_msg.code = ErrorCode.ConfigError
        rsp_msg.error = "配置不存在"
        scripts.Bag.RollBackWithChange(bag_change_log)
        return context.S2C(context.net_id, CmdCode.PBRoleSkillCompositeRspCmd, rsp_msg, req.msg_context.stub_id)
    end
    change_roles[req.msg.roleid] = "CompositeSkill"

    -- 执行完成回复
    context.S2C(context.net_id, CmdCode.PBRoleSkillCompositeRspCmd, rsp_msg, req.msg_context.stub_id)

    -- 数据存储更新
    -- local save_bags = {}
    -- for bagType, _ in pairs(bag_change_log) do
    --     save_bags[bagType] = 1
    -- end
    -- scripts.Bag.SaveAndLog(save_bags, bag_change_log)
    scripts.Bag.SaveAndLog(bag_change_log, ItemDef.ChangeReason.RoleCompositeSkill, req.msg.roleid)

    if table.size(change_roles) > 0 then
        scripts.Role.SaveAndLog(change_roles)
        Role.GetSkillNum(role_info, { req.msg.composite_id })
    end
end

function Role.PBRoleSkillSwitchReqCmd(req)
    -- 参数验证
    if not req.msg.uid or not req.msg.roleid or not req.msg.skill_id or not req.msg.skill_type then
        return context.S2C(context.net_id, CmdCode.PBRoleSkillSwitchRspCmd, {
            code = ErrorCode.ParamInvalid,
            error = "无效请求参数",
            uid = req.msg.uid,
            roleid = req.msg.roleid or 0,
            skill_type = req.msg.skill_type or 0,
            skill_id = req.msg.skill_id or 0,
        }, req.msg_context.stub_id)
    end

    local roles = scripts.UserModel.GetRoles()
    if not roles then
        return context.S2C(context.net_id, CmdCode.PBRoleSkillSwitchRspCmd,
            { code = ErrorCode.ServerInternalError, error = "数据加载出错", uid = req.msg.uid }, req.msg_context.stub_id)
    end

    local role_info = roles.role_list[req.msg.roleid]
    if not role_info then
        return context.S2C(context.net_id, CmdCode.PBRoleSkillSwitchRspCmd,
            { code = ErrorCode.RoleNotExist, error = "角色不存在", uid = req.msg.uid }, req.msg_context.stub_id)
    end

    if req.msg.skill_type == RoleDef.SkillType.MinorSkill_1 then
        if not role_info.minor_skill1[req.msg.skill_id]
            or role_info.minor_skill1[req.msg.skill_id].star < 0 then
            return context.S2C(context.net_id, CmdCode.PBRoleSkillSwitchRspCmd,
                { code = ErrorCode.RoleSkillNotExist, error = "角色技能不存在", uid = req.msg.uid }, req.msg_context.stub_id)
        end
        role_info.cur_minor_skill1_id = req.msg.skill_id
    elseif req.msg.skill_type == RoleDef.SkillType.MinorSkill_2 then
        if not role_info.minor_skill2[req.msg.skill_id]
            or role_info.minor_skill2[req.msg.skill_id].star < 0 then
            return context.S2C(context.net_id, CmdCode.PBRoleSkillSwitchRspCmd,
                { code = ErrorCode.RoleSkillNotExist, error = "角色技能不存在", uid = req.msg.uid }, req.msg_context.stub_id)
        end
        role_info.cur_minor_skill2_id = req.msg.skill_id
    elseif req.msg.skill_type == RoleDef.SkillType.PassiveSkill then
        if not role_info.passive_skill[req.msg.skill_id]
            or role_info.passive_skill[req.msg.skill_id].star < 0 then
            return context.S2C(context.net_id, CmdCode.PBRoleSkillSwitchRspCmd,
                { code = ErrorCode.RoleSkillNotExist, error = "角色技能不存在", uid = req.msg.uid }, req.msg_context.stub_id)
        end
        role_info.cur_passive_skill_id = req.msg.skill_id
    elseif req.msg.skill_type == RoleDef.SkillType.MainSkill then
        if not role_info.main_skill[req.msg.skill_id]
            or role_info.main_skill[req.msg.skill_id].star < 0 then
            return context.S2C(context.net_id, CmdCode.PBRoleSkillSwitchRspCmd,
                { code = ErrorCode.RoleSkillNotExist, error = "角色技能不存在", uid = req.msg.uid }, req.msg_context.stub_id)
        end
        role_info.cur_main_skill_id = req.msg.skill_id
    else
        return context.S2C(context.net_id, CmdCode.PBRoleSkillSwitchRspCmd,
            { code = ErrorCode.RoleSkillNotExist, error = "角色技能不存在", uid = req.msg.uid }, req.msg_context.stub_id)
    end

    -- 执行完成回复
    context.S2C(context.net_id, CmdCode.PBRoleSkillSwitchRspCmd, {
        code = ErrorCode.None,
        error = "成功",
        uid = req.msg.uid,
        roleid = req.msg.roleid or 0,
        skill_type = req.msg.skill_type or 0,
        skill_id = req.msg.skill_id or 0,
    }, req.msg_context.stub_id)

    -- 数据存储更新
    local change_roles = {}
    change_roles[req.msg.roleid] = "SwitchSkill"
    scripts.Role.SaveAndLog(change_roles)
end

function Role.PBRoleEquipmentRepairReqCmd(req)
    -- 参数验证
    if not req.msg.uid or not req.msg.roleid or not req.msg.need_repairs
        or table.size(req.msg.need_repairs) == 0 then
        return context.S2C(context.net_id, CmdCode.PBRoleEquipmentRepairRspCmd, {
            code = ErrorCode.ParamInvalid,
            error = "无效请求参数",
            uid = req.msg.uid,
            roleid = req.msg.roleid or 0,
            already_repairs = {},
        }, req.msg_context.stub_id)
    end

    if context.lock_item_role == 1 then
        return context.S2C(context.net_id, CmdCode.PBRoleEquipmentRepairRspCmd,
            { code = ErrorCode.LockItemRole, error = "变更操作被锁定", uid = context.uid }, req.msg_context.stub_id)
    end

    local roles = scripts.UserModel.GetRoles()
    if not roles then
        return context.S2C(context.net_id, CmdCode.PBRoleEquipmentRepairRspCmd,
            {
                code = ErrorCode.ServerInternalError,
                error = "数据加载出错",
                uid = req.msg.uid,
                roleid = req.msg.roleid or 0,
                already_repairs = {},
            },
            req.msg_context.stub_id)
    end

    -- 消耗配置
    -- local common_cfg = CommonCfgDef.getConf("MaintenanceCost")
    -- if not common_cfg then
    --     moon.error("role_repair_func common_cfg is nil")
    --     return context.S2C(context.net_id, CmdCode.PBRoleEquipmentRepairRspCmd,
    --         {
    --             code = ErrorCode.ConfigError,
    --             error = "配置错误",
    --             uid = req.msg.uid,
    --             roleid = req.msg.roleid or 0,
    --             already_repairs = {},
    --         },
    --         req.msg_context.stub_id)
    -- end
    local maintenance_cfgs = GameCfg.MaintenanceCost1
    if not maintenance_cfgs or table.size(maintenance_cfgs) <= 0 then
        moon.error("repair_func maintenance_cfgs is nil")
        return context.S2C(context.net_id, CmdCode.PBRoleEquipmentRepairRspCmd,
            {
                code = ErrorCode.ConfigError,
                error = "配置错误",
                uid = req.msg.uid,
                roleid = req.msg.roleid or 0,
                already_repairs = {},
            },
            req.msg_context.stub_id)
    end

    local role_info = roles.role_list[req.msg.roleid]
    if not role_info then
        return context.S2C(context.net_id, CmdCode.PBRoleEquipmentRepairRspCmd,
            {
                code = ErrorCode.RoleNotExist,
                error = "角色不存在",
                uid = req.msg.uid,
                roleid = req.msg.roleid or 0,
                already_repairs = {},
            },
            req.msg_context.stub_id)
    end

    local function role_repair_func(item_data, smallType, old_cost_items, old_cost_coins)
        local old_item_data = table.copy(item_data)
        local uniq_item_cfg = GameCfg.UniqueItem[item_data.common_info.config_id]
        if not uniq_item_cfg then
            moon.error("role_repair_func uniq_item_cfg is nil", item_data.common_info.config_id)
            return ErrorCode.ConfigError, 0
        end
        local cur_maintenance_cfg
        for _, maintenance_cfg in pairs(maintenance_cfgs) do
            if maintenance_cfg.type1 == uniq_item_cfg.type1
                and maintenance_cfg.type2 == uniq_item_cfg.type2 then
                cur_maintenance_cfg = maintenance_cfg
                break
            end
        end
        if not cur_maintenance_cfg or not cur_maintenance_cfg.cost then
            moon.error("repair_func cur_maintenance_cfg is nil", item_data.common_info.config_id)
            return ErrorCode.ConfigError, 0
        end

        local fix_durability = 0
        local errcode = ErrorCode.None
        if smallType == ItemDefine.EItemSmallType.MagicItem then
            if item_data.special_info.magic_item.strong_value <= 0 then
                return ErrorCode.StrongNotEnough, 0
            end
            if item_data.special_info.magic_item.cur_durability >= uniq_item_cfg.durability then
                return ErrorCode.DurabilityMax, 0
            end
            fix_durability = math.min(uniq_item_cfg.durability - item_data.special_info.magic_item.cur_durability,
                item_data.special_info.magic_item.strong_value)
        elseif smallType == ItemDefine.EItemSmallType.HumanDiagrams then
            if item_data.special_info.diagrams_item.strong_value <= 0 then
                return ErrorCode.StrongNotEnough, 0
            end
            if item_data.special_info.diagrams_item.cur_durability >= uniq_item_cfg.durability then
                return ErrorCode.DurabilityMax, 0
            end
            fix_durability = math.min(uniq_item_cfg.durability - item_data.special_info.diagrams_item.cur_durability,
                item_data.special_info.diagrams_item.strong_value)
        elseif smallType == ItemDefine.EItemSmallType.SpaceRing then
            if item_data.special_info.space_ring.strong_value <= 0 then
                return ErrorCode.StrongNotEnough, 0
            end
            if item_data.special_info.space_ring.cur_durability >= uniq_item_cfg.durability then
                return ErrorCode.DurabilityMax, 0
            end
            fix_durability = math.min(uniq_item_cfg.durability - item_data.special_info.space_ring.cur_durability,
                item_data.special_info.space_ring.strong_value)
        else
            return ErrorCode.ItemTypeMismatch, 0
        end
        if fix_durability <= 0 then
            return ErrorCode.DurabilityMax, 0
        end

        local change_cost_items = table.copy(old_cost_items, true)
        local change_cost_coins = table.copy(old_cost_coins, true)
        moon.info(string.format("role_repair_func 1 change_cost_coins = %s", json.pretty_encode(change_cost_items)))
        -- ItemDefine.GetItemsFromCfg(common_cfg.items, fix_durability, true, change_cost_items, change_cost_coins)
        ItemDefine.GetItemsFromCfg(cur_maintenance_cfg.cost, fix_durability, true, change_cost_items, change_cost_coins)

        -- 获取镇山之宝修复耐久度货币消耗折扣
        local repair_discount = scripts.AweItem.GetRepairCostDiscount()

        -- 应用折扣到货币消耗
        if repair_discount > 0 and change_cost_coins then
            for coin_id, coin_data in pairs(change_cost_coins) do
                local original_count = coin_data.coin_count or coin_data.count
                if original_count then
                    local discounted_count = math.floor(original_count * (10000 - repair_discount) / 10000)
                    if coin_data.coin_count then
                        coin_data.coin_count = discounted_count
                    end
                    moon.info(string.format("role_repair_func: uid=%d, coin_id=%d, original=%d, discounted=%d, discount=%d",
                        context.uid, coin_id, original_count, discounted_count, repair_discount))
                end
            end
        end

        -- 检测道具是否足够
        errcode = scripts.Bag.CheckItemsEnough(BagDef.BagType.Cangku, change_cost_items, {})
        if errcode ~= ErrorCode.None then
            return errcode, 0
        end
        errcode = scripts.Bag.CheckCoinsEnough(change_cost_coins)
        if errcode ~= ErrorCode.None then
            return errcode, 0
        end
        moon.info(string.format("role_repair_func 2 change_cost_coins = %s", json.pretty_encode(change_cost_items)))

        return ErrorCode.None, fix_durability, change_cost_items, change_cost_coins
    end

    local cost_items = {}
    local cost_coins = {}
    local add_durability_list = {}
    local last_ret_code = ErrorCode.None
    -- local fix_durability = 0
    for _, need_repair in ipairs(req.msg.need_repairs) do
        local smallType = ItemDefine.GetItemType(need_repair.config_id)
        if smallType == ItemDefine.EItemSmallType.MagicItem then
            if role_info.magic_item and role_info.magic_item.common_info
                and role_info.magic_item.common_info.config_id == need_repair.config_id
                and role_info.magic_item.common_info.uniqid == need_repair.uniqid then
                local ret_code, fix_durability, change_cost_items, change_cost_coins = role_repair_func(
                    role_info.magic_item, smallType, cost_items, cost_coins)
                last_ret_code = ret_code
                if ret_code == ErrorCode.None then
                    if change_cost_items and table.size(change_cost_items) > 0 then
                        cost_items = change_cost_items
                    end
                    if change_cost_coins and table.size(change_cost_coins) > 0 then
                        cost_coins = change_cost_coins
                    end
                    local add_durability = {
                        config_id = need_repair.config_id,
                        uniqid = need_repair.uniqid,
                        pos = need_repair.pos,
                        smallType = smallType,
                        fix_durability = fix_durability,
                    }
                    table.insert(add_durability_list, add_durability)
                end
            end
        elseif smallType == ItemDefine.EItemSmallType.HumanDiagrams then
            if role_info.digrams_cards and table.size(role_info.digrams_cards) > 0
                and role_info.digrams_cards[need_repair.pos]
                and role_info.digrams_cards[need_repair.pos].common_info
                and role_info.digrams_cards[need_repair.pos].common_info.config_id == need_repair.config_id
                and role_info.digrams_cards[need_repair.pos].common_info.uniqid == need_repair.uniqid then
                local ret_code, fix_durability, change_cost_items, change_cost_coins = role_repair_func(
                    role_info.digrams_cards[need_repair.pos], smallType, cost_items, cost_coins)
                last_ret_code = ret_code
                if ret_code == ErrorCode.None then
                    if change_cost_items and table.size(change_cost_items) > 0 then
                        cost_items = change_cost_items
                    end
                    if change_cost_coins and table.size(change_cost_coins) > 0 then
                        cost_coins = change_cost_coins
                    end
                    local add_durability = {
                        config_id = need_repair.config_id,
                        uniqid = need_repair.uniqid,
                        pos = need_repair.pos,
                        smallType = smallType,
                        fix_durability = fix_durability,
                    }
                    table.insert(add_durability_list, add_durability)
                end
            end
        elseif smallType == ItemDefine.EItemSmallType.SpaceRing then
            if role_info.space_ring and role_info.space_ring.common_info
                and role_info.space_ring.common_info.config_id == need_repair.config_id
                and role_info.space_ring.common_info.uniqid == need_repair.uniqid then
                local ret_code, fix_durability, change_cost_items, change_cost_coins = role_repair_func(
                    role_info.space_ring, smallType, cost_items, cost_coins)
                last_ret_code = ret_code
                if ret_code == ErrorCode.None then
                    if change_cost_items and table.size(change_cost_items) > 0 then
                        cost_items = change_cost_items
                    end
                    if change_cost_coins and table.size(change_cost_coins) > 0 then
                        cost_coins = change_cost_coins
                    end
                    local add_durability = {
                        config_id = need_repair.config_id,
                        uniqid = need_repair.uniqid,
                        pos = need_repair.pos,
                        smallType = smallType,
                        fix_durability = fix_durability,
                    }
                    table.insert(add_durability_list, add_durability)
                end
            end
        end
    end

    local already_repairs = {}
    if table.size(add_durability_list) > 0 then
        moon.info(string.format("PBRoleEquipmentRepairReqCmd cost_coins = %s", json.pretty_encode(cost_coins)))
        local bag_change_logs = {}
        -- 扣除道具
        if table.size(cost_items) > 0 then
            local bag_code = scripts.Bag.DelItems(BagDef.BagType.Cangku, cost_items, {}, bag_change_logs)
            if bag_code ~= ErrorCode.None then
                scripts.Bag.RollBackWithChange(bag_change_logs)
                return context.S2C(context.net_id, CmdCode.PBRoleEquipmentRepairRspCmd,
                    {
                        code = bag_code,
                        error = "道具不足",
                        uid = req.msg.uid,
                        roleid = req.msg.roleid or 0,
                        already_repairs = {},
                    },
                    req.msg_context.stub_id)
            end
        end
        if table.size(cost_coins) > 0 then
            local bag_code = scripts.Bag.DealCoins(cost_coins, bag_change_logs)
            if bag_code ~= ErrorCode.None then
                scripts.Bag.RollBackWithChange(bag_change_logs)
                return context.S2C(context.net_id, CmdCode.PBRoleEquipmentRepairRspCmd,
                    {
                        code = bag_code,
                        error = "货币不足",
                        uid = req.msg.uid,
                        roleid = req.msg.roleid or 0,
                        already_repairs = {},
                    },
                    req.msg_context.stub_id)
            end
        end

        for _, add_durability in ipairs(add_durability_list) do
            table.insert(already_repairs, {
                config_id = add_durability.config_id,
                uniqid = add_durability.uniqid,
                pos = add_durability.pos,
            })
            if add_durability.smallType == ItemDefine.EItemSmallType.MagicItem then
                -- 增加法器耐久度
                local item_data = role_info.magic_item
                item_data.special_info.magic_item.cur_durability = item_data.special_info.magic_item.cur_durability +
                    add_durability.fix_durability
                item_data.special_info.magic_item.strong_value = item_data.special_info.magic_item.strong_value -
                    add_durability.fix_durability
            elseif add_durability.smallType == ItemDefine.EItemSmallType.HumanDiagrams then
                -- 增加八卦牌耐久度
                local item_data = role_info.digrams_cards[add_durability.pos]
                item_data.special_info.diagrams_item.cur_durability = item_data.special_info.diagrams_item
                    .cur_durability + add_durability.fix_durability
                item_data.special_info.diagrams_item.strong_value = item_data.special_info.diagrams_item.strong_value -
                    add_durability.fix_durability
            elseif add_durability.smallType == ItemDefine.EItemSmallType.SpaceRing then
                -- 增加戒指耐久度
                local item_data = role_info.space_ring
                item_data.special_info.space_ring.cur_durability = item_data.special_info.space_ring.cur_durability +
                    add_durability.fix_durability
                item_data.special_info.space_ring.strong_value = item_data.special_info.space_ring.strong_value -
                    add_durability.fix_durability
            end
        end

        -- 存储数据
        if table.size(bag_change_logs) > 0 then
            scripts.Bag.SaveAndLog(bag_change_logs, ItemDef.ChangeReason.ItemRepair)
        end
        local change_roles = {}
        change_roles[req.msg.roleid] = "RepairEquipment"
        scripts.Role.SaveAndLog(change_roles)
    end

    return context.S2C(context.net_id, CmdCode.PBRoleEquipmentRepairRspCmd,
        {
            code = last_ret_code,
            error = "",
            uid = req.msg.uid,
            roleid = req.msg.roleid or 0,
            already_repairs = already_repairs,
        },
        req.msg_context.stub_id)
end

function Role.PBRoleEquipmentStrongRepairReqCmd(req)
    -- 参数验证
    if not req.msg.uid or not req.msg.roleid or not req.msg.config_id
        or not req.msg.uniqid then
        return context.S2C(context.net_id, CmdCode.PBRoleEquipmentStrongRepairRspCmd, {
            code = ErrorCode.ParamInvalid,
            error = "无效请求参数",
            uid = req.msg.uid,
            roleid = req.msg.roleid or 0,
            config_id = req.msg.config_id or 0,
            uniqid = req.msg.uniqid or 0,
            pos = req.msg.pos or 0,
        }, req.msg_context.stub_id)
    end

    if context.lock_item_role == 1 then
        return context.S2C(context.net_id, CmdCode.PBRoleEquipmentStrongRepairRspCmd,
            { code = ErrorCode.LockItemRole, error = "变更操作被锁定", uid = context.uid }, req.msg_context.stub_id)
    end

    local roles = scripts.UserModel.GetRoles()
    if not roles then
        return context.S2C(context.net_id, CmdCode.PBRoleEquipmentStrongRepairRspCmd,
            {
                code = ErrorCode.ServerInternalError,
                error = "数据加载出错",
                uid = req.msg.uid,
                roleid = req.msg.roleid,
                config_id = req.msg.config_id,
                uniqid = req.msg.uniqid,
                pos = req.msg.pos or 0,
            },
            req.msg_context.stub_id)
    end

    local role_info = roles.role_list[req.msg.roleid]
    if not role_info then
        return context.S2C(context.net_id, CmdCode.PBRoleEquipmentStrongRepairRspCmd,
            {
                code = ErrorCode.RoleNotExist,
                error = "角色不存在",
                uid = req.msg.uid,
                roleid = req.msg.roleid,
                config_id = req.msg.config_id,
                uniqid = req.msg.uniqid,
                pos = req.msg.pos or 0,
            },
            req.msg_context.stub_id)
    end

    local uniqitem_cfg = GameCfg.UniqueItem[req.msg.config_id]
    if not uniqitem_cfg then
        return context.S2C(context.net_id, CmdCode.PBRoleEquipmentStrongRepairRspCmd,
            {
                code = ErrorCode.ConfigError,
                error = "配置不存在",
                uid = req.msg.uid,
                roleid = req.msg.roleid,
                config_id = req.msg.config_id,
                uniqid = req.msg.uniqid,
                pos = req.msg.pos or 0,
            },
            req.msg_context.stub_id)
    end

    local function role_repair_strong_func(item_data, smallType)
        local old_item_data = table.copy(item_data)

        -- 消耗配置
        local maintenance_cfgs = GameCfg.MaintenanceCost2
        if not maintenance_cfgs or table.size(maintenance_cfgs) <= 0 then
            moon.error("repair_strong_func maintenance_cfgs is nil", item_data.common_info.config_id)
            return ErrorCode.ConfigError
        end
        local cur_maintenance_cfg
        for _, maintenance_cfg in pairs(maintenance_cfgs) do
            if maintenance_cfg.type1 == uniqitem_cfg.type1
                and maintenance_cfg.type2 == uniqitem_cfg.type2 then
                cur_maintenance_cfg = maintenance_cfg
                break
            end
        end
        if not cur_maintenance_cfg then
            moon.error("repair_strong_func cur_maintenance_cfg is nil", item_data.common_info.config_id)
            return ErrorCode.ConfigError
        end

        local cost_items = {}
        local cost_coins = {}
        local change_logs = {}
        if smallType == ItemDefine.EItemSmallType.MagicItem then
            if item_data.special_info.magic_item.strong_value > 0 then
                return ErrorCode.StrongNotZero
            end
            if item_data.special_info.magic_item.repair_strong_cnt >= cur_maintenance_cfg.sturdy_reset_count then
                return ErrorCode.StrongRepairMax
            end
            local repair_cost_key = "cost" .. (item_data.special_info.magic_item.repair_strong_cnt + 1)
            if not cur_maintenance_cfg[repair_cost_key]
                or table.size(cur_maintenance_cfg[repair_cost_key]) <= 0 then
                return ErrorCode.ConfigError
            end
            ItemDefine.GetItemsFromCfg(cur_maintenance_cfg[repair_cost_key], true, cost_items, cost_coins)

        elseif smallType == ItemDefine.EItemSmallType.HumanDiagrams
            or smallType == ItemDefine.EItemSmallType.GhostDiagrams then
            if item_data.special_info.diagrams_item.strong_value > 0 then
                return ErrorCode.StrongNotZero
            end
            if item_data.special_info.diagrams_item.repair_strong_cnt >= cur_maintenance_cfg.sturdy_reset_count then
                return ErrorCode.StrongRepairMax
            end
            local repair_cost_key = "cost" .. (item_data.special_info.diagrams_item.repair_strong_cnt + 1)
            if not cur_maintenance_cfg[repair_cost_key]
                or table.size(cur_maintenance_cfg[repair_cost_key]) <= 0 then
                return ErrorCode.ConfigError
            end
            ItemDefine.GetItemsFromCfg(cur_maintenance_cfg[repair_cost_key], true, cost_items, cost_coins)

        elseif smallType == ItemDefine.EItemSmallType.SpaceRing then
            if item_data.special_info.space_ring.strong_value > 0 then
                return ErrorCode.StrongNotZero
            end
            if item_data.special_info.space_ring.repair_strong_cnt >= cur_maintenance_cfg.sturdy_reset_count then
                return ErrorCode.StrongRepairMax
            end
            local repair_cost_key = "cost" .. (item_data.special_info.space_ring.repair_strong_cnt + 1)
            if not cur_maintenance_cfg[repair_cost_key]
                or table.size(cur_maintenance_cfg[repair_cost_key]) <= 0 then
                return ErrorCode.ConfigError
            end
            ItemDefine.GetItemsFromCfg(cur_maintenance_cfg[repair_cost_key], true, cost_items, cost_coins)

        else
            return ErrorCode.ItemTypeMismatch
        end

        -- 检测道具是否足够
        local errcode = scripts.Bag.CheckItemsEnough(BagDef.BagType.Cangku, cost_items, {})
        if errcode ~= ErrorCode.None then
            return errcode
        end
        errcode = scripts.Bag.CheckCoinsEnough(cost_coins)
        if errcode ~= ErrorCode.None then
            return errcode
        end

        -- 扣除道具
        if table.size(cost_items) > 0 then
            errcode = scripts.Bag.DelItems(BagDef.BagType.Cangku, cost_items, {}, change_logs)
            if errcode ~= ErrorCode.None then
                scripts.Bag.RollBackWithChange(change_logs)
                return errcode
            end
        end
        if table.size(cost_coins) > 0 then
            errcode = scripts.Bag.DealCoins(cost_coins, change_logs)
            if errcode ~= ErrorCode.None then
                scripts.Bag.RollBackWithChange(change_logs)
                return errcode
            end
        end

        return ErrorCode.None, change_logs
    end

    local smallType = ItemDefine.GetItemType(req.msg.config_id)
    if smallType == ItemDefine.EItemSmallType.MagicItem then
        if role_info.magic_item and role_info.magic_item.common_info
            and role_info.magic_item.common_info.config_id == req.msg.config_id
            and role_info.magic_item.common_info.uniqid == req.msg.uniqid then
            local ret_code, bag_change_logs = role_repair_strong_func(role_info.magic_item, smallType)
            if ret_code ~= ErrorCode.None then
                return context.S2C(context.net_id, CmdCode.PBRoleEquipmentStrongRepairRspCmd,
                    {
                        code = ret_code,
                        error = "修理失败",
                        uid = req.msg.uid,
                        roleid = req.msg.roleid,
                        config_id = req.msg.config_id,
                        uniqid = req.msg.uniqid,
                        pos = req.msg.pos or 0,
                    },
                    req.msg_context.stub_id)
            end

            -- 增加法器坚固值
            role_info.magic_item.special_info.magic_item.strong_value = uniqitem_cfg.sturdy
            role_info.magic_item.special_info.magic_item.repair_strong_cnt = role_info.magic_item.special_info
                .magic_item.repair_strong_cnt + 1

            -- 存储数据
            if table.size(bag_change_logs) > 0 then
                scripts.Bag.SaveAndLog(bag_change_logs, ItemDef.ChangeReason.ItemRepair)
            end
            local change_roles = {}
            change_roles[req.msg.roleid] = "RepairEquipment"
            scripts.Role.SaveAndLog(change_roles)
        end
    elseif smallType == ItemDefine.EItemSmallType.HumanDiagrams then
        if role_info.digrams_cards and table.size(role_info.digrams_cards) > 0
            and role_info.digrams_cards[req.msg.pos]
            and role_info.digrams_cards[req.msg.pos].common_info
            and role_info.digrams_cards[req.msg.pos].common_info.config_id == req.msg.config_id
            and role_info.digrams_cards[req.msg.pos].common_info.uniqid == req.msg.uniqid then
            local ret_code, bag_change_logs = role_repair_strong_func(role_info.digrams_cards[req.msg.pos],
                smallType)
            if ret_code ~= ErrorCode.None then
                return context.S2C(context.net_id, CmdCode.PBRoleEquipmentStrongRepairRspCmd,
                    {
                        code = ret_code,
                        error = "修理失败",
                        uid = req.msg.uid,
                        roleid = req.msg.roleid,
                        config_id = req.msg.config_id,
                        uniqid = req.msg.uniqid,
                        pos = req.msg.pos or 0,
                    },
                    req.msg_context.stub_id)
            end

            -- 增加八卦牌坚固值
            role_info.digrams_cards[req.msg.pos].special_info.diagrams_item.strong_value = uniqitem_cfg.sturdy
            role_info.digrams_cards[req.msg.pos].special_info.diagrams_item.repair_strong_cnt = role_info.digrams_cards
                [req.msg.pos].special_info.diagrams_item.repair_strong_cnt + 1

            -- 存储数据
            if table.size(bag_change_logs) > 0 then
                scripts.Bag.SaveAndLog(bag_change_logs, ItemDef.ChangeReason.ItemRepair)
            end
            local change_roles = {}
            change_roles[req.msg.roleid] = "RepairEquipment"
            scripts.Role.SaveAndLog(change_roles)
        end
    elseif smallType == ItemDefine.EItemSmallType.SpaceRing then
        if role_info.space_ring and role_info.space_ring.common_info
            and role_info.space_ring.common_info.config_id == req.msg.config_id
            and role_info.space_ring.common_info.uniqid == req.msg.uniqid then
            local ret_code, bag_change_logs = role_repair_strong_func(role_info.space_ring, smallType)
            if ret_code ~= ErrorCode.None then
                return context.S2C(context.net_id, CmdCode.PBRoleEquipmentStrongRepairRspCmd,
                    {
                        code = ret_code,
                        error = "修理失败",
                        uid = req.msg.uid,
                        roleid = req.msg.roleid,
                        config_id = req.msg.config_id,
                        uniqid = req.msg.uniqid,
                        pos = req.msg.pos or 0,
                    },
                    req.msg_context.stub_id)
            end

            -- 增加戒指坚固值
            role_info.space_ring.special_info.space_ring.strong_value = uniqitem_cfg.sturdy
            role_info.space_ring.special_info.space_ring.repair_strong_cnt = role_info.space_ring.special_info
                .space_ring.repair_strong_cnt + 1

            -- 存储数据
            if table.size(bag_change_logs) > 0 then
                scripts.Bag.SaveAndLog(bag_change_logs, ItemDef.ChangeReason.ItemRepair)
            end
            local change_roles = {}
            change_roles[req.msg.roleid] = "RepairEquipment"
            scripts.Role.SaveAndLog(change_roles)
        end
    end

    return context.S2C(context.net_id, CmdCode.PBRoleEquipmentStrongRepairRspCmd,
        {
            code = ErrorCode.None,
            error = "修理成功",
            uid = req.msg.uid,
            roleid = req.msg.roleid,
            config_id = req.msg.config_id,
            uniqid = req.msg.uniqid,
            pos = req.msg.pos or 0,
        },
        req.msg_context.stub_id)
end

return Role