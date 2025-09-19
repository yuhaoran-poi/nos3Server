local moon = require "moon"
local common = require "common"
local uuid = require "uuid"
local GameCfg = common.GameCfg
local ErrorCode = common.ErrorCode
local CmdCode = common.CmdCode
local Database = common.Database
local GhostDef = require("common.def.GhostDef")
local BagDef = require("common.def.BagDef")
local ProtoEnum = require("tools.ProtoEnum")
local ItemDefine = require("common.logic.ItemDefine")

---@type user_context
local context = ...
local scripts = context.scripts

---@class Ghost
local Ghost = {}

function Ghost.Init()
    --加载全部角色数据
    local ghostinfos = Ghost.LoadGhosts()
    if ghostinfos then
        scripts.UserModel.SetGhosts(ghostinfos)
    end

    local ghosts = scripts.UserModel.GetGhosts()
    if not ghosts then
        ghosts = GhostDef.newUserGhostDatas()
        scripts.UserModel.SetGhosts(ghosts)
    end
end

function Ghost.Start(isnew)
    local ghosts = scripts.UserModel.GetGhosts()
    if not ghosts then
        return false
    end

    if isnew then
        local init_cfg = GameCfg.Init[1]
        if not init_cfg then
            return false
        end

        for k, v in pairs(init_cfg.item) do
            if k >= GhostDef.GhostDefine.GhostID.Start and k <= GhostDef.GhostDefine.GhostID.End then
                local ret = Ghost.AddGhost(k)

                if ret.code == ErrorCode.None and k == init_cfg.battle_ghost then
                    Ghost.SetGhostBattle(ret.uniqid, false)
                end
            end
        end

        Ghost.SaveGhostsNow()
    end
end

function Ghost.SaveGhostsNow()
    local ghosts = scripts.UserModel.GetGhosts()
    if not ghosts then
        return false
    end

    local success = Database.saveuserghosts(context.addr_db_user, context.uid, ghosts)
    return success
end

function Ghost.LoadGhosts()
    local ghostinfos = Database.loaduserghosts(context.addr_db_user, context.uid)
    return ghostinfos
end

function Ghost.AddLog(ghostid, reason)
    local ghosts = scripts.UserModel.GetGhosts()
    if not ghosts or not ghosts.ghost_list or not ghosts.ghost_list[ghostid] then
        return false
    end

    local log_info = {
        reason = reason,
        info = {},
    }
    log_info.info = table.copy(ghosts.ghost_list[ghostid], true)

    --存储日志

    return true
end

function Ghost.SaveAndLog(change_ghosts)
    local ghosts = scripts.UserModel.GetGhosts()
    if not ghosts then
        return false
    end

    local update_info = {
        battle_ghost_id = ghosts.battle_ghost_id,
        battle_ghost_uniqid = ghosts.battle_ghost_uniqid,
        ghost_list = {},
        ghost_image_list = {},
    }
    if change_ghosts.ghost then
        for uniqid, reason in pairs(change_ghosts.ghost) do
            local ghostinfo = ghosts.ghost_list[uniqid]
            if not ghostinfo then
                return false
            end
            update_info.ghost_list[uniqid] = table.copy(ghostinfo)
            local ghostimage = ghosts.ghost_image_list[ghostinfo.config_id]
            if not ghostimage then
                return false
            end
            if not update_info.ghost_image_list[ghostinfo.config_id] then
                update_info.ghost_image_list[ghostinfo.config_id] = ghostimage
            end
        end
    end
    if change_ghosts.image then
        for config_id, reason in pairs(change_ghosts.image) do
            local ghostimage = ghosts.ghost_image_list[config_id]
            if not ghostimage then
                return false
            end
            if not update_info.ghost_image_list[config_id] then
                update_info.ghost_image_list[config_id] = ghostimage
            end
        end
    end

    Ghost.SaveGhostsNow()
    context.S2C(context.net_id, CmdCode["PBGhostInfoSyncCmd"], { ghosts_info = update_info }, 0)

    --存储日志

    return true
end

function Ghost.AddGhost(ghost_config_id)
    local ghosts = scripts.UserModel.GetGhosts()
    if not ghosts then
        return { code = ErrorCode.ServerInternalError, error = "no ghosts" }
    end

    local ghost_cfg = GameCfg.GhostInfo[ghost_config_id]
    if not ghost_cfg then
        return { code = ErrorCode.ConfigError, error = "no ghost_cfg" }
    end

    local ghost_info = GhostDef.newGhostData()
    ghost_info.config_id = ghost_config_id
    ghost_info.uniqid = uuid.next()

    ghosts.ghost_list[ghost_info.uniqid] = ghost_info

    if not ghosts.ghost_image_list[ghost_config_id] then
        local ghost_image = GhostDef.newGhostImage()
        ghost_image.config_id = ghost_config_id

        ghosts.ghost_image_list[ghost_config_id] = ghost_image
    end

    return { code = ErrorCode.None, error = "success", uniqid = ghost_info.uniqid }
end

function Ghost.SetGhostBattle(ghost_uniqid, sync_client)
    local ghosts = scripts.UserModel.GetGhosts()
    if not ghosts then
        return false
    end

    if ghosts.ghost_list[ghost_uniqid] then
        local ghost_info = ghosts.ghost_list[ghost_uniqid]
        local ghost_image = ghosts.ghost_image_list[ghost_info.config_id]
        ghosts.battle_ghost_id = ghost_info.config_id
        ghosts.battle_ghost_uniqid = ghost_info.uniqid

        local show_ghost = GhostDef.newSimpleGhostData()
        show_ghost.config_id = ghost_info.config_id
        show_ghost.skin_id = ghost_image.cur_skin_id

        local update_user_attr = {}
        update_user_attr[ProtoEnum.UserAttrType.cur_show_ghost] = show_ghost
        scripts.User.SetUserAttr(update_user_attr, sync_client)
    end
end

---@return PBGhostData ? nil
function Ghost.GetGhostInfo(ghostid)
    local ghosts = scripts.UserModel.GetGhosts()
    if not ghosts or not ghosts.ghost_list or not ghosts.ghost_list[ghostid] then
        return nil
    end

    return ghosts.ghost_list[ghostid]
end

function Ghost.ModDiagramsCard(ghostid, item_data, slot)
    local ghosts = scripts.UserModel.GetGhosts()
    if not ghosts or not ghosts.ghost_list or not ghosts.ghost_list[ghostid] then
        return ErrorCode.GhostNotExist
    end

    local ghost_info = ghosts.ghost_list[ghostid]
    ghost_info.digrams_cards[slot] = item_data

    return ErrorCode.None
end

function Ghost.UpLv(config_id, add_exp)
    local ghosts = scripts.UserModel.GetGhosts()
    if not ghosts or not ghosts.ghost_image_list or not ghosts.ghost_image_list[config_id] then
        return ErrorCode.GhostNotExist
    end

    local ghost_image_info = ghosts.ghost_image_list[config_id]
    local up_exp_cfgs = GameCfg.GhostUpLv
    if not up_exp_cfgs then
        return ErrorCode.ConfigError
    end

    local exps = {}
    local remain_exp = add_exp
    for _, cfg in pairs(up_exp_cfgs) do
        if cfg.allexp > ghost_image_info.exp then
            if ghost_image_info.exp + add_exp >= cfg.allexp then
                local canAdd = math.min(cfg.allexp - ghost_image_info.exp, remain_exp)
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
        return ErrorCode.GhostMaxExp
    end

    -- 计算消耗资源
    local cost_items = {}
    local cost_coins = {}
    for id, count in pairs(exps) do
        local cur_cfg = GameCfg.UpLvCostIDMapping[id]
        if not cur_cfg or not cur_cfg.cost or not cur_cfg.cnt then
            return ErrorCode.ItemUpLvCostNotExist
        end

        ItemDefine.GetItemsFromCfg(cur_cfg.cost, count / cur_cfg.cnt, true, cost_items, cost_coins)
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
    local new_exp = ghost_image_info.exp + add_exp
    ghost_image_info.exp = new_exp

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

function Ghost.CheckUseItemUpLv(config_id, exp_id, exp_cnt)
    local ghosts = scripts.UserModel.GetGhosts()
    if not ghosts or not ghosts.ghost_image_list or not ghosts.ghost_image_list[config_id] then
        return ErrorCode.GhostNotExist
    end

    local ghost_image_info = ghosts.ghost_image_list[config_id]
    local after_up_exp = ghost_image_info.exp + exp_cnt
    local success = false
    local up_exp_cfgs = GameCfg.GhostUpLv
    if not up_exp_cfgs then
        return ErrorCode.ConfigError
    end

    for _, cfg in pairs(up_exp_cfgs) do
        if ghost_image_info.exp < cfg.allexp and after_up_exp >= cfg.allexp then
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
        return ErrorCode.GhostMaxExp
    end

    -- ghost_image_info.exp = after_up_exp

    return ErrorCode.None
end

function Ghost.UpExp(config_id, exp_cnt)
    local ghosts = scripts.UserModel.GetGhosts()
    if not ghosts or not ghosts.ghost_image_list or not ghosts.ghost_image_list[config_id] then
        return ErrorCode.GhostNotExist
    end

    local ghost_image_info = ghosts.ghost_image_list[config_id]
    ghost_image_info.exp = ghost_image_info.exp + exp_cnt

    return ErrorCode.None
end

function Ghost.UpStar(config_id)
    local ghosts = scripts.UserModel.GetGhosts()
    if not ghosts or not ghosts.ghost_image_list or not ghosts.ghost_image_list[config_id] then
        return ErrorCode.GhostNotExist
    end

    local ghost_image_info = ghosts.ghost_image_list[config_id]
    local star_cfg = GameCfg.UpStar[ghost_image_info.config_id]
    if not star_cfg then
        return ErrorCode.ConfigError
    end
    if ghost_image_info.star_level >= star_cfg.maxlv then
        return ErrorCode.ItemMaxStar
    end

    local cost_key = "cost" .. (ghost_image_info.star_level + 1)
    if not star_cfg[cost_key] then
        return ErrorCode.ConfigError
    end
    local cost_cfg = star_cfg[cost_key]

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

    -- 增加星星
    ghost_image_info.star_level = ghost_image_info.star_level + 1

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

function Ghost.InlayTabooWord(ghost_uniqid, taboo_word_id, inlay_type, uniqid)
    local ghosts = scripts.UserModel.GetGhosts()
    if not ghosts or not ghosts.ghost_list or not ghosts.ghost_list[ghost_uniqid] then
        return ErrorCode.GhostNotExist
    end

    local ghost_info = ghosts.ghost_list[ghost_uniqid]
    local item_data = nil
    if ghost_info.digrams_cards then
        for _, digrams_card in pairs(ghost_info.digrams_cards) do
            if digrams_card
                and digrams_card.common_info
                and digrams_card.common_info.uniqid == uniqid then
                item_data = digrams_card
                break
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
    if uniqitem_cfg.type4 ~= item_cfg.type4
        or uniqitem_cfg.type5 ~= item_cfg.type5 then
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
    item_data.special_info.diagrams_item.tabooword_id = taboo_word_id

    return ErrorCode.None, bag_change_log
end

function Ghost.PBClientGetUsrGhostsInfoReqCmd(req)
    local ghosts = scripts.UserModel.GetGhosts()
    if not ghosts then
        return context.S2C(context.net_id, CmdCode["PBClientGetUsrGhostsInfoRspCmd"],
            { code = ErrorCode.ServerInternalError, error = "数据加载出错", uid = context.uid }, req.msg_context.stub_id)
    end

    local rsp_msg = {
        code = ErrorCode.None,
        error = "",
        uid = req.msg.uid,
        ghosts_info = ghosts,
    }

    return context.S2C(context.net_id, CmdCode["PBClientGetUsrGhostsInfoRspCmd"], rsp_msg, req.msg_context.stub_id)
end

function Ghost.GetGhostEquipment(ghost_info, config_id, equip_idx)
    local item_small_type = ItemDefine.GetItemType(config_id)
    if item_small_type == ItemDefine.EItemSmallType.GhostDiagrams then
        -- 检测现在是否携带有相应位置八卦牌
        if ghost_info.digrams_cards
            and ghost_info.digrams_cards[equip_idx]
            and ghost_info.digrams_cards[equip_idx].common_info then
            return item_small_type, ghost_info.digrams_cards[equip_idx]
        end
    end

    return item_small_type, nil
end

function Ghost.ChangeEquipment(ghost_info, config_id, equip_idx, equip_item_data)
    local item_small_type = ItemDefine.GetItemType(config_id)
    if item_small_type == ItemDefine.EItemSmallType.GhostDiagrams then
        if equip_item_data then
            ghost_info.digrams_cards[equip_idx] = equip_item_data
        else
            ghost_info.digrams_cards[equip_idx] = nil
        end
    end
end

function Ghost.PBGhostWearEquipReqCmd(req)
    local ghosts = scripts.UserModel.GetGhosts()
    if not ghosts then
        return context.S2C(context.net_id, CmdCode["PBGhostWearEquipRspCmd"],
            { code = ErrorCode.ServerInternalError, error = "数据加载出错", uid = context.uid }, req.msg_context.stub_id)
    end

    local ghost_info = ghosts.ghost_list[req.msg.ghost_uniqid]
    if not ghost_info then
        return context.S2C(context.net_id, CmdCode["PBGhostWearEquipRspCmd"],
            { code = ErrorCode.GhostNotExist, error = "鬼宠不存在", uid = context.uid }, req.msg_context.stub_id)
    end

    local errcode, item_data = scripts.Bag.GetOneItemData(req.msg.bag_name, req.msg.pos)
    if errcode ~= ErrorCode.None or not item_data then
        return context.S2C(context.net_id, CmdCode["PBGhostWearEquipRspCmd"],
            { code = errcode, error = "装备不存在", uid = context.uid }, req.msg_context.stub_id)
    end
    if item_data.common_info.config_id ~= req.msg.equip_config_id
        or item_data.common_info.uniqid ~= req.msg.equip_uniqid then
        return context.S2C(context.net_id, CmdCode["PBGhostWearEquipRspCmd"],
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

    local item_small_type, takeoff_item_data = Ghost.GetGhostEquipment(ghost_info, item_data.common_info.config_id,
        req.msg.equip_idx)
    if item_small_type ~= item_small_type == ItemDefine.EItemSmallType.GhostDiagrams then
        return context.S2C(context.net_id, CmdCode["PBGhostWearEquipRspCmd"],
            { code = ErrorCode.ItemNotExist, error = "装备不存在", uid = context.uid }, req.msg_context.stub_id)
    end
    -- 检测八卦牌位置是否正确
    local uniqitem_cfg = GameCfg.UniqueItem[item_data.common_info.config_id]
    if not uniqitem_cfg or uniqitem_cfg.type5 ~= req.msg.equip_idx then
        return context.S2C(context.net_id, CmdCode["PBGhostWearEquipRspCmd"],
            { code = ErrorCode.ConfigError, error = "八卦牌配置不存在", uid = context.uid }, req.msg_context.stub_id)
    end

    -- 扣除道具消耗
    err_code = scripts.Bag.DelItems(req.msg.bag_name, {}, del_unique_items, bag_change_log)
    if err_code ~= ErrorCode.None then
        scripts.Bag.RollBackWithChange(bag_change_log)
        return context.S2C(context.net_id, CmdCode["PBGhostWearEquipRspCmd"],
            { code = err_code, error = "更换装备失败", uid = context.uid }, req.msg_context.stub_id)
    end

    if takeoff_item_data then
        local takeoff_items = {}
        table.insert(takeoff_items, takeoff_item_data)
        -- 添加道具
        err_code = scripts.Bag.AddItems(req.msg.bag_name, {}, takeoff_items, bag_change_log)
        if err_code ~= ErrorCode.None then
            scripts.Bag.RollBackWithChange(bag_change_log)
            return context.S2C(context.net_id, CmdCode["PBGhostWearEquipRspCmd"],
                { code = err_code, error = "更换装备失败", uid = context.uid }, req.msg_context.stub_id)
        end
    end

    -- 鬼宠穿戴新装备
    Ghost.ChangeEquipment(ghost_info, item_data.common_info.config_id, req.msg.equip_idx, item_data)

    -- 保存数据并同步给客户端
    local save_bags = {}
    for bagType, _ in pairs(bag_change_log) do
        save_bags[bagType] = 1
    end
    --local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
    scripts.Bag.SaveAndLog(save_bags, bag_change_log)

    local change_ghosts = {
        ghost = {},
        image = {},
    }
    change_ghosts.ghost[req.msg.ghost_uniqid] = "WearEquipment"
    scripts.Ghost.SaveAndLog(change_ghosts)

    local rsp_msg = {
        code = ErrorCode.None,
        error = "",
        uid = req.msg.uid,
        ghost_uniqid = req.msg.ghost_uniqid,
        bag_name = req.msg.bag_name,
        pos = req.msg.pos,
        equip_config_id = req.msg.equip_config_id,
        equip_uniqid = req.msg.equip_uniqid,
        equip_idx = req.msg.equip_idx,
    }
    return context.S2C(context.net_id, CmdCode["PBGhostWearEquipRspCmd"], rsp_msg, req.msg_context.stub_id)
end

function Ghost.PBGhostTakeOffEquipReqCmd(req)
    local ghosts = scripts.UserModel.GetGhosts()
    if not ghosts then
        return context.S2C(context.net_id, CmdCode["PBGhostTakeOffEquipRspCmd"],
            { code = ErrorCode.ServerInternalError, error = "数据加载出错", uid = context.uid }, req.msg_context.stub_id)
    end

    local ghost_info = ghosts.ghost_list[req.msg.ghost_uniqid]
    if not ghost_info then
        return context.S2C(context.net_id, CmdCode["PBGhostTakeOffEquipRspCmd"],
            { code = ErrorCode.GhostNotExist, error = "角色不存在", uid = context.uid }, req.msg_context.stub_id)
    end

    local bag_change_log = {}
    local err_code = ErrorCode.None
    local item_small_type, takeoff_item_data = Ghost.GetGhostEquipment(ghost_info, req.msg.takeoff_config_id,
        req.msg.takeoff_idx)
    if item_small_type == ItemDefine.EItemSmallType.HumanDiagrams then
        -- 检测八卦牌位置是否正确
        local uniqitem_cfg = GameCfg.UniqueItem[req.msg.takeoff_config_id]
        if not uniqitem_cfg or uniqitem_cfg.type5 ~= req.msg.takeoff_idx then
            return context.S2C(context.net_id, CmdCode["PBGhostTakeOffEquipRspCmd"],
                { code = ErrorCode.ConfigError, error = "八卦牌配置不存在", uid = context.uid }, req.msg_context.stub_id)
        end
    end

    -- 判断卸下的装备是否一致
    if not takeoff_item_data
        or not takeoff_item_data.common_info
        or takeoff_item_data.common_info.config_id ~= req.msg.takeoff_config_id
        or takeoff_item_data.common_info.uniqid ~= req.msg.takeoff_uniqid then
        return context.S2C(context.net_id, CmdCode["PBGhostTakeOffEquipRspCmd"],
            { code = ErrorCode.ItemNotExist, error = "装备不存在", uid = context.uid }, req.msg_context.stub_id)
    end

    local takeoff_items = {}
    table.insert(takeoff_items, takeoff_item_data)
    -- 添加道具
    err_code = scripts.Bag.AddItems(req.msg.bag_name, {}, takeoff_items, bag_change_log)
    if err_code ~= ErrorCode.None then
        scripts.Bag.RollBackWithChange(bag_change_log)
        return context.S2C(context.net_id, CmdCode["PBGhostTakeOffEquipRspCmd"],
            { code = err_code, error = "更换装备失败", uid = context.uid }, req.msg_context.stub_id)
    end

    -- 角色卸下新装备
    Ghost.ChangeEquipment(ghost_info, req.msg.takeoff_config_id, req.msg.takeoff_idx, nil)

    -- 保存数据并同步给客户端
    local save_bags = {}
    for bagType, _ in pairs(bag_change_log) do
        save_bags[bagType] = 1
    end
    scripts.Bag.SaveAndLog(save_bags, bag_change_log)
    local change_ghosts = {
        ghost = {},
        image = {},
    }
    change_ghosts.ghost[req.msg.ghost_uniqid] = "TakeOffEquipment"
    scripts.Ghost.SaveAndLog(change_ghosts)

    local rsp_msg = {
        code = ErrorCode.None,
        error = "",
        uid = req.msg.uid,
        ghost_uniqid = req.msg.ghost_uniqid,
        bag_name = req.msg.bag_name,
        takeoff_config_id = req.msg.takeoff_config_id,
        takeoff_uniqid = req.msg.takeoff_uniqid,
        takeoff_idx = req.msg.takeoff_idx,
    }
    return context.S2C(context.net_id, CmdCode["PBGhostTakeOffEquipRspCmd"], rsp_msg, req.msg_context.stub_id)
end

function Ghost.PBGhostWearSkinReqCmd(req)
    local ghosts = scripts.UserModel.GetGhosts()
    if not ghosts
        or not ghosts.ghost_image_list
        or not ghosts.ghost_image_list[req.msg.ghost_config_id] then
        return context.S2C(context.net_id, CmdCode["PBGhostWearSkinRspCmd"],
            {
                code = ErrorCode.GhostNotExist,
                error = "",
                uid = context.uid,
                ghost_config_id = req.msg.ghost_config_id,
                skin = req.msg.skin
            }, req.msg_context.stub_id)
    end
    local ghost_image_info = ghosts.ghost_image_list[req.msg.ghost_config_id]

    if table.size(ghost_image_info.skin_id_list) <= 0 then
        return context.S2C(context.net_id, CmdCode["PBGhostWearSkinRspCmd"],
            {
                code = ErrorCode.ItemNotExist,
                error = "",
                uid = context.uid,
                ghost_config_id = req.msg.ghost_config_id,
                skin = req.msg.skin
            }, req.msg_context.stub_id)
    end

    local find_skin = false
    for _, skin_id in pairs(ghost_image_info.skin_id_list) do
        if skin_id == req.msg.skin then
            ghost_image_info.cur_skin_id = skin_id
            find_skin = true
            break
        end
    end

    if find_skin then
        context.S2C(context.net_id, CmdCode["PBGhostWearSkinRspCmd"],
            {
                code = ErrorCode.None,
                error = "",
                uid = context.uid,
                ghost_config_id = req.msg.ghost_config_id,
                skin = req.msg.skin
            }, req.msg_context.stub_id)
    else
        return context.S2C(context.net_id, CmdCode["PBGhostWearSkinRspCmd"],
            {
                code = ErrorCode.ItemNotExist,
                error = "",
                uid = context.uid,
                ghost_config_id = req.msg.ghost_config_id,
                skin = req.msg.skin
            }, req.msg_context.stub_id)
    end

    local change_ghosts = {
        ghost = {},
        image = {},
    }
    change_ghosts.image[req.msg.ghost_config_id] = "WearSkin"
    scripts.Ghost.SaveAndLog(change_ghosts)
end

return Ghost