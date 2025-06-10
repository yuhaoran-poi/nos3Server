local moon = require "moon"
local common = require "common"
local uuid = require "uuid"
local GameCfg = common.GameCfg
local ErrorCode = common.ErrorCode
local CmdCode = common.CmdCode
local Database = common.Database
local GhostDef = require("common.def.GhostDef")
local ProtoEnum = require("tools.ProtoEnum")

---@type user_context
local context = ...
local scripts = context.scripts

local GhostDefine = {
    GhostID = { Start = 1017000, End = 1017999 },
    GhostSkin = { Start = 1070000, End = 1119999 },
}

---@class Ghost
local Ghost = {}

function Ghost.Init()
    
end

function Ghost.Start()
    --加载全部角色数据
    local ghostinfos = Ghost.LoadGhosts()
    if ghostinfos then
        scripts.UserModel.SetGhosts(ghostinfos)
    end

    local ghosts = scripts.UserModel.GetGhosts()
    if not ghosts then
        ghosts = GhostDef.newUserGhostDatas()
        local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
        local init_cfg = GameCfg.Init[1]
        if not init_cfg then
            return { code = ErrorCode.ConfigError, error = "no init_cfg" }
        end

        for k, v in pairs(init_cfg.item) do
            if k >= GhostDefine.GhostID.Start and k <= GhostDefine.GhostID.End then
                local ret = Ghost.AddGhost(k)

                if ret.code == ErrorCode.None and k == init_cfg.battle_ghost then
                    Ghost.SetGhostBattle(ret.uniqid, false)
                end
            end
        end

        scripts.UserModel.SetGhosts(ghosts)
        Ghost.SaveGhostsNow()
    end

    return { code = ErrorCode.None }
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
    if change_ghosts then
        for uniqid, reason in pairs(change_ghosts) do
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

---@return integer, PBGhostData ? nil
function Ghost.GetGhostInfo(ghostid)
    local ghosts = scripts.UserModel.GetGhosts()
    if not ghosts or not ghosts.ghost_list or not ghosts.ghost_list[ghostid] then
        return ErrorCode.GhostNotExist
    end

    return ErrorCode.None, ghosts.ghost_list[ghostid]
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
    local item_small_type = scripts.ItemDefine.GetItemType(config_id)
    if item_small_type == scripts.ItemDefine.EItemSmallType.GhostDiagrams then
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
    local item_small_type = scripts.ItemDefine.GetItemType(config_id)
    if item_small_type == scripts.ItemDefine.EItemSmallType.GhostDiagrams then
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
    local takeoff_items = {}

    local item_small_type, takeoff_item_data = Ghost.GetGhostEquipment(ghost_info, item_data.common_info.config_id,
        req.msg.equip_idx)
    if item_small_type ~= item_small_type == scripts.ItemDefine.EItemSmallType.GhostDiagrams then
        return context.S2C(context.net_id, CmdCode["PBGhostWearEquipRspCmd"],
            { code = ErrorCode.ItemNotExist, error = "装备不存在", uid = context.uid }, req.msg_context.stub_id)
    end
    -- 检测八卦牌位置是否正确
    local uniqitem_cfg = GameCfg.UniqueItem[item_data.common_info.config_id]
    if not uniqitem_cfg or uniqitem_cfg.type5 ~= req.msg.equip_idx then
        return context.S2C(context.net_id, CmdCode["PBGhostWearEquipRspCmd"],
            { code = ErrorCode.ConfigError, error = "八卦牌配置不存在", uid = context.uid }, req.msg_context.stub_id)
    end
    if takeoff_item_data then
        takeoff_items[takeoff_item_data.common_info.uniqid] = takeoff_item_data
    end

    -- 扣除道具消耗
    err_code = scripts.Bag.DelItems(req.msg.bag_name, {}, del_unique_items, bag_change_log)
    if err_code ~= ErrorCode.None then
        scripts.Bag.RollBackWithChange(bag_change_log)
        return context.S2C(context.net_id, CmdCode["PBGhostWearEquipRspCmd"],
            { code = err_code, error = "更换装备失败", uid = context.uid }, req.msg_context.stub_id)
    end
    -- 添加道具
    err_code = scripts.Bag.AddItems(req.msg.bag_name, {}, takeoff_items, bag_change_log)
    if err_code ~= ErrorCode.None then
        scripts.Bag.RollBackWithChange(bag_change_log)
        return context.S2C(context.net_id, CmdCode["PBGhostWearEquipRspCmd"],
            { code = err_code, error = "更换装备失败", uid = context.uid }, req.msg_context.stub_id)
    end

    -- 鬼宠穿戴新装备
    Ghost.ChangeEquipment(ghost_info, item_data.common_info.config_id, req.msg.equip_idx, item_data)

    -- 保存数据并同步给客户端
    local save_bags = {}
    for bagType, _ in pairs(bag_change_log) do
        save_bags[bagType] = 1
    end
    local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
    scripts.Bag.SaveAndLog(save_bags, bag_change_log)

    local change_ghosts = {}
    change_ghosts[req.msg.ghost_uniqid] = "WearEquipment"
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
    local takeoff_items = {}
    local item_small_type, takeoff_item_data = Ghost.GetGhostEquipment(ghost_info, req.msg.takeoff_config_id,
        req.msg.takeoff_idx)
    if item_small_type == scripts.ItemDefine.EItemSmallType.HumanDiagrams then
        -- 检测八卦牌位置是否正确
        local uniqitem_cfg = GameCfg.UniqueItem[req.msg.takeoff_config_id]
        if not uniqitem_cfg or uniqitem_cfg.type5 ~= req.msg.takeoff_idx then
            return context.S2C(context.net_id, CmdCode["PBGhostTakeOffEquipRspCmd"],
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
        return context.S2C(context.net_id, CmdCode["PBGhostTakeOffEquipRspCmd"],
            { code = ErrorCode.ItemNotExist, error = "装备不存在", uid = context.uid }, req.msg_context.stub_id)
    end

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
    local change_ghosts = {}
    change_ghosts[req.msg.ghost_uniqid] = "TakeOffEquipment"
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

return Ghost