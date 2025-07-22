local moon = require "moon"
local common = require "common"
local uuid = require "uuid"
local json = require "json"
local GameCfg = common.GameCfg
local ErrorCode = common.ErrorCode
local CmdCode = common.CmdCode
local Database = common.Database
local RoleDef = require("common.def.RoleDef")
local BagDef = require("common.def.BagDef")
local ProtoEnum = require("tools.ProtoEnum")

---@type user_context
local context = ...
local scripts = context.scripts

---@class Role
local Role = {}

function Role.Init()
    
end

function Role.Start()
    --加载全部角色数据
    local roleinfos = Role.LoadRoles()
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
            if k >= RoleDef.RoleDefine.RoleID.Start and k <= RoleDef.RoleDefine.RoleID.End then
                --local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
                Role.AddRole(k)
            end
        end
        Role.SetRoleBattle(init_cfg.battle_role, false)

        Role.SaveRolesNow()
    end

    -- return { code = ErrorCode.None }
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

function Role.CheckRoleStudyBook(role_info)
    local now_time = moon.time()
    moon.warn(string.format("CheckRoleStudyBook role_info = %s", json.pretty_encode(role_info)))
    if now_time - role_info.last_check_time < 10 then
        return
    end

    local end_study = {}
    for book_id, study_book in pairs(role_info.study_books) do
        study_book.now_time = now_time
        if study_book.end_time <= now_time then
            role_info.equip_books[book_id] = 1
            table.insert(end_study, book_id)
        end
    end

    for _, book_id in pairs(end_study) do
        role_info.study_books[book_id] = nil
    end

    role_info.last_check_time = now_time
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
            -- 检测更新角色真经学习进度
            Role.CheckRoleStudyBook(roleinfo)

            update_info.role_list[roleid] = table.copy(roleinfo)

            if roleid == roles.battle_role_id then
                -- 同步到玩家属性上
                local show_role = RoleDef.newSimpleRoleData()
                show_role.config_id = roleinfo.config_id
                show_role.skins = roleinfo.skins
                if roleinfo.magic_item and roleinfo.magic_item.common_info then
                    show_role.magic_item_id = roleinfo.magic_item.common_info.config_id
                end

                local update_user_attr = {}
                update_user_attr[ProtoEnum.UserAttrType.cur_show_role] = show_role
                scripts.User.SetUserAttr(update_user_attr, true)
            end
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
            star = -1,
        }
        if skillid == role_info.cur_main_skill_id then
            skill_info.star = 0
        end
        role_info.main_skill[skillid] = skill_info
    end
    role_info.cur_minor_skill1_id = role_cfg.init_q_skill
    for _, skillid in pairs(role_cfg.q_skill) do
        local skill_info = {
            config_id = skillid,
            star = -1,
        }
        if skillid == role_info.cur_minor_skill1_id then
            skill_info.star = 0
        end
        role_info.minor_skill1[skillid] = skill_info
    end
    role_info.cur_minor_skill2_id = role_cfg.init_e_skill
    for _, skillid in pairs(role_cfg.e_skill) do
        local skill_info = {
            config_id = skillid,
            star = -1,
        }
        if skillid == role_info.cur_minor_skill2_id then
            skill_info.star = 0
        end
        role_info.minor_skill2[skillid] = skill_info
    end
    role_info.cur_passive_skill_id = role_cfg.init_passive_skill
    for _, skillid in pairs(role_cfg.passive_skill) do
        local skill_info = {
            config_id = skillid,
            star = -1,
        }
        if skillid == role_info.cur_passive_skill_id then
            skill_info.star = 0
        end
        role_info.passive_skill[skillid] = skill_info
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

    local role_info = roles.role_list[roleid]
    Role.CheckRoleStudyBook(role_info)

    return ErrorCode.None, role_info
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
    else
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
    end
    if not item_data then
        return ErrorCode.ItemNotExist
    end

    local uniqitem_cfg = GameCfg.UniqueItem[item_data.common_info.config_id]
    local item_cfg = GameCfg.Item[taboo_word_id]
    if not uniqitem_cfg or not item_cfg then
        return ErrorCode.ConfigError
    end
    if uniqitem_cfg.type4 ~= item_cfg.type4 then
        return ErrorCode.InlayTypeNotMatch
    end
    if inlay_type ~= 1 and uniqitem_cfg.type5 ~= item_cfg.type5 then
        return ErrorCode.InlayTypeNotMatch
    end

    -- 扣除道具消耗
    local cost_items = {}
    cost_items[taboo_word_id] = {
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
    else
        item_data.special_info.diagrams_item.tabooword_id = taboo_word_id
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
    for _, cfg in pairs(up_exp_cfgs) do
        if cfg.allexp > role_info.exp then
            if role_info.exp + add_exp >= cfg.allexp then
                local canAdd = math.min(cfg.allexp - role_info.exp, remain_exp)
                if not exps[cfg.cost] then
                    exps[cfg.cost] = 0
                end
                exps[cfg.cost] = exps[cfg.cost] + canAdd
                remain_exp = remain_exp - canAdd
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
        local cost_cfg = GameCfg.UpLvCostIDMapping[id]
        if not cost_cfg then
            return ErrorCode.ItemUpLvCostNotExist
        end

        scripts.Item.GetItemsFromCfg(cost_cfg, (count / cost_cfg.cnt), true, cost_items, cost_coins)
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

    return ErrorCode.None, change_log
end

function Role.CheckUseItemUpLv(roleid, exp_id, exp_cnt)
    local roles = scripts.UserModel.GetRoles()
    if not roles or not roles.role_list or not roles.role_list[roleid] then
        return ErrorCode.RoleNotExist
    end

    local role_info = roles.role_list[roleid]
    local after_up_exp = role_info.exp + exp_cnt
    local success = false
    local up_exp_cfgs = GameCfg.RoleUpLv
    if not up_exp_cfgs then
        return ErrorCode.ConfigError
    end
    for _, cfg in pairs(up_exp_cfgs) do
        if role_info.exp < cfg.allexp and after_up_exp >= cfg.allexp then
            if cfg.cost ~= exp_id then
                return ErrorCode.ConfigError
            end
        end

        if after_up_exp < cfg.allexp then
            success = true
            break
        end
    end
    if not success then
        return ErrorCode.RoleMaxExp
    end

    -- role_info.exp = after_up_exp

    return ErrorCode.None
end

function Role.UpExp(roleid, exp_cnt)
    local roles = scripts.UserModel.GetRoles()
    if not roles or not roles.role_list or not roles.role_list[roleid] then
        return ErrorCode.RoleNotExist
    end

    local role_info = roles.role_list[roleid]
    role_info.exp = role_info.exp + exp_cnt

    return ErrorCode.None
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

    local cost_key = "cost" .. (role_info.star_level + 1)
    if not star_cfg[cost_key] then
        return ErrorCode.ConfigError
    end
    local cost_cfg = star_cfg[cost_key]

    -- 计算消耗资源
    local cost_items = {}
    local cost_coins = {}
    scripts.Item.GetItemsFromCfg(cost_cfg, 1, true, cost_items, cost_coins)

    -- 检查资源是否足够
    local err_code_items = scripts.Bag.CheckItemsEnough(BagDef.BagType.Cangku, cost_items, {})
    if err_code_items ~= ErrorCode.None then
        return err_code_items
    end
    local err_code_coins = scripts.Bag.CheckCoinsEnough(cost_coins)
    if err_code_coins ~= ErrorCode.None then
        return err_code_coins
    end

    -- 增加星星
    role_info.star_level = role_info.star_level + 1

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

    return ErrorCode.None, change_log
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
    local takeoff_items = {}

    local item_small_type, takeoff_item_data = Role.GetRoleEquipment(role_info, item_data.common_info.config_id,
        req.msg.equip_idx)
    if item_small_type ~= scripts.ItemDefine.EItemSmallType.MagicItem
        and item_small_type ~= item_small_type == scripts.ItemDefine.EItemSmallType.HumanDiagrams then
        return context.S2C(context.net_id, CmdCode["PBRoleWearEquipRspCmd"],
            { code = ErrorCode.ItemNotExist, error = "装备不存在", uid = context.uid }, req.msg_context.stub_id)
    end
    if item_small_type == scripts.ItemDefine.EItemSmallType.MagicItem then
        -- 检测法器类型是否正确
        --local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
        local uniqitem_cfg = GameCfg.UniqueItem[item_data.common_info.config_id]
        if not uniqitem_cfg or uniqitem_cfg.type4 ~= role_cfg.magic_slot_type then
            return context.S2C(context.net_id, CmdCode["PBRoleWearEquipRspCmd"],
                { code = ErrorCode.ConfigError, error = "法器类型错误", uid = context.uid }, req.msg_context.stub_id)
        end
    end
    if item_small_type == scripts.ItemDefine.EItemSmallType.HumanDiagrams then
        -- 检测八卦牌位置是否正确
        local uniqitem_cfg = GameCfg.UniqueItem[item_data.common_info.config_id]
        if not uniqitem_cfg or uniqitem_cfg.type5 ~= req.msg.equip_idx then
            return context.S2C(context.net_id, CmdCode["PBRoleWearEquipRspCmd"],
                { code = ErrorCode.ConfigError, error = "八卦牌类型错误", uid = context.uid }, req.msg_context.stub_id)
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
    --local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
    scripts.Bag.SaveAndLog(save_bags, bag_change_log)

    local change_roles = {}
    change_roles[req.msg.roleid] = "WearEquipment"
    Role.SaveAndLog(change_roles)

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
    local item_small_type, takeoff_item_data = Role.GetRoleEquipment(role_info, req.msg.takeoff_config_id,
        req.msg.takeoff_idx)
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

    for idx, skin_id in pairs(req.msg.change_skins) do
        local skin_image, itype = scripts.ItemImage.GetImage(skin_id)
        if not skin_image then
            return context.S2C(context.net_id, CmdCode["PBRoleWearSkinRspCmd"],
                { code = ErrorCode.ItemNotExist, error = "皮肤不存在", uid = context.uid }, req.msg_context.stub_id)
        end
    end

    for idx, skin_id in pairs(req.msg.change_skins) do
        role_info.skins[idx] = skin_id
    end

    context.S2C(context.net_id, CmdCode["PBRoleWearSkinRspCmd"],
        { code = ErrorCode.None, error = "", uid = context.uid }, req.msg_context.stub_id)

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
        local emoji_image, itype = scripts.ItemImage.GetImage(emoji_id)
        if not emoji_image then
            return context.S2C(context.net_id, CmdCode["PBRoleChangeEmojiRspCmd"],
                { code = ErrorCode.ItemNotExist, error = "皮肤不存在", uid = context.uid }, req.msg_context.stub_id)
        end

        local emoji_cfg = GameCfg.Skin[emoji_id]
        if not emoji_cfg or emoji_cfg.type ~= itype then
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

    local role_info = roles.role_list[req.msg.roleid]
    if not role_info then
        return context.S2C(context.net_id, CmdCode["PBChangeBattleRoleRspCmd"],
            { code = ErrorCode.RoleNotExist, error = "角色不存在", uid = context.uid }, req.msg_context.stub_id)
    end

    Role.SetRoleBattle(req.msg.roleid, true)
    Role.SaveRolesNow()
    return context.S2C(context.net_id, CmdCode["PBChangeBattleRoleRspCmd"],
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
    for id, skill in pairs(role_info.main_skill) do
        if id == req.msg.skill_id then
            skill_star = skill.star
            skill_name = "main_skill"
            break
        end
    end
    if skill_star < 0 then
        for id, skill in pairs(role_info.minor_skill1) do
            if id == req.msg.skill_id then
                skill_star = skill.star
                skill_name = "minor_skill1"
                break
            end
        end
    end
    if skill_star < 0 then
        for id, skill in pairs(role_info.minor_skill2) do
            if id == req.msg.skill_id then
                skill_star = skill.star
                skill_name = "minor_skill2"
                break
            end
        end
    end
    if skill_star < 0 then
        for id, skill in pairs(role_info.passive_skill) do
            if id == req.msg.skill_id then
                skill_star = skill.star
                skill_name = "passive_skill"
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

    -- 计算消耗资源
    local cost_items = {}
    local cost_coins = {}
    scripts.Item.GetItemsFromCfg(cost_cfg, 1, true, cost_items, cost_coins)

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

    -- 增加星星
    skill_star = skill_star + 1
    for id, skill in pairs(role_info[skill_name]) do
        if id == req.msg.skill_id then
            skill.star = skill_star
            break
        end
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

    context.S2C(context.net_id, CmdCode.PBRoleSkillUpStarRspCmd, {
        code = ErrorCode.None,
        error = "",
        uid = context.uid,
        roleid = req.msg.roleid,
        skill_id = req.msg.skill_id,
    }, req.msg_context.stub_id)

    local save_bags = {}
    for bagType, _ in pairs(bag_change_log) do
        save_bags[bagType] = 1
    end
    if table.size(save_bags) > 0 then
        scripts.Bag.SaveAndLog(save_bags, bag_change_log)
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

    -- 计算消耗资源
    local items, coins = scripts.Item.GetItemsFromCfg(reward_cfg.award, 1)
    if items and table.size(items) > 0 then
        local err_code = scripts.Bag.CheckEmptyEnough(BagDef.BagType.Cangku, items)
        if err_code ~= ErrorCode.None then
            return context.S2C(context.net_id, CmdCode["PBRoleGetUpLvRewardRspCmd"],
                { code = err_code, error = "背包空间不足" }, req.msg_context.stub_id)
        end
    end

    -- 领取奖励
    local bag_change_log = {}
    local err_code_add = ErrorCode.None
    if items and table.size(items) > 0 then
        err_code_add = scripts.Bag.AddItems(BagDef.BagType.Cangku, items, {}, bag_change_log)
        if err_code_add ~= ErrorCode.None then
            scripts.Bag.RollBackWithChange(bag_change_log)
            return context.S2C(context.net_id, CmdCode["PBRoleGetUpLvRewardRspCmd"],
                { code = err_code_add, error = "添加道具失败" }, req.msg_context.stub_id)
        end
    end
    if coins and table.size(coins) > 0 then
        err_code_add = scripts.Bag.DealCoins(coins, bag_change_log)
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
    local save_bags = {}
    for bagType, _ in pairs(bag_change_log) do
        save_bags[bagType] = 1
    end
    scripts.Bag.SaveAndLog(save_bags, bag_change_log)

    if table.size(change_roles) > 0 then
        scripts.Role.SaveAndLog(change_roles)
    end
end

function Role.PBRoleStudyBookReqCmd(req)
    -- 参数验证
    if not req.msg.uid or not req.msg.composite_id then
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

    local save_bags = {}
    for bagType, _ in pairs(bag_change_log) do
        save_bags[bagType] = 1
    end
    if table.size(save_bags) > 0 then
        scripts.Bag.SaveAndLog(save_bags, bag_change_log)
    end

    local change_roles = {}
    change_roles[req.msg.roleid] = "StudyBook"
    scripts.Role.SaveAndLog(change_roles)
end

function Role.PBRoleSkillCompositeReqCmd(req)
    -- 参数验证
    if not req.msg.uid or not req.msg.roleid or not req.msg.skill_id or not req.msg.composite_id then
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
            if skill_id == req.msg.skill_id then
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
            if skill_id == req.msg.skill_id then
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
            if skill_id == req.msg.skill_id then
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
            if skill_id == req.msg.skill_id then
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
    scripts.Item.GetItemsFromCfg(composite_cfg.unlock_cost, 1, true, cost_items, cost_coins)

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
        local skill_info = {
            config_id = req.msg.composite_id,
            star = 0,
        }
        role_info.minor_skill1[req.msg.composite_id] = skill_info
    elseif composite_cfg.type == RoleDef.SkillType.MinorSkill_2 then
        local skill_info = {
            config_id = req.msg.composite_id,
            star = 0,
        }
        role_info.minor_skill2[req.msg.composite_id] = skill_info
    elseif composite_cfg.type == RoleDef.SkillType.PassiveSkill then
        local skill_info = {
            config_id = req.msg.composite_id,
            star = 0,
        }
        role_info.passive_skill[req.msg.composite_id] = skill_info
    elseif composite_cfg.type == RoleDef.SkillType.MainSkill then
        local skill_info = {
            config_id = req.msg.composite_id,
            star = 0,
        }
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
    local save_bags = {}
    for bagType, _ in pairs(bag_change_log) do
        save_bags[bagType] = 1
    end
    scripts.Bag.SaveAndLog(save_bags, bag_change_log)

    if table.size(change_roles) > 0 then
        scripts.Role.SaveAndLog(change_roles)
    end
end

function Role.PBRoleSkillSwitchReqCmd(req)
    -- 参数验证
    if not req.msg.uid or not req.msg.roleid or not req.msg.skill_id or not req.msg.composite_id then
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

return Role