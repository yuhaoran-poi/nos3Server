local moon = require "moon"
local datetime = require("moon.datetime")
local common = require "common"
local clusterd = require("cluster")
local GameCfg = common.GameCfg
local ErrorCode = common.ErrorCode
local CmdCode = common.CmdCode
local Database = common.Database
local SeasonPassDef = require("common.def.SeasonPassDef")
local ProtoEnum = require("tools.ProtoEnum")
local ItemDefine = require("common.logic.ItemDefine")
local BagDef = require("common.def.BagDef")
local ItemDef = require("common.def.ItemDef")
local RoleDef = require("common.def.RoleDef")

local GONGDE_COIN_ID = 7

---@type user_context
local context = ...
local scripts = context.scripts

---@class SeasonPass
local SeasonPass = {}

function SeasonPass.Init()
    --加载段位数据
    local season_pass_player_data = SeasonPass.LoadSeasonPassInfo()
    if season_pass_player_data then
        scripts.UserModel.SetSeasonPass(season_pass_player_data)
    end

    local season_pass = scripts.UserModel.GetSeasonPass()
    if not season_pass then
        season_pass = SeasonPassDef.newSeasonPassPlayerData()
        season_pass.uid = context.uid

        local seasonpass_cfgs = GameCfg.SeasonPassShop
        if seasonpass_cfgs and table.size(seasonpass_cfgs) > 0 then
            for _, seasonpass_cfg in pairs(seasonpass_cfgs) do
                if seasonpass_cfg.default_unlock == 1 then
                    local new_seasonpass_info = SeasonPassDef.newSeasonPassData()
                    new_seasonpass_info.pass_id = seasonpass_cfg.id
                    season_pass.season_pass_infos[new_seasonpass_info.pass_id] = new_seasonpass_info
                end
            end
        end
        scripts.UserModel.SetSeasonPass(season_pass)
    end
end

function SeasonPass.Start()
    local season_pass = scripts.UserModel.GetSeasonPass()
    if not season_pass then
        return
    end

    -- SeasonPass.SaveSeasonPasssNow()
    scripts.UserModel.AddDirtyModule("SeasonPass")
end

function SeasonPass.SaveSeasonPasssNow()
    local season_pass = scripts.UserModel.GetSeasonPass()
    if not season_pass then
        return false
    end

    local success = Database.saveseasonpassinfo(context.addr_db_user, context.uid, season_pass)
    scripts.UserModel.RemoveDirtyModule("SeasonPass")
    return success
end

function SeasonPass.TimingSave()
    local season_pass = scripts.UserModel.GetSeasonPass()
    if not season_pass then
        return false
    end

    local success = Database.saveseasonpassinfo(context.addr_db_user, context.uid, season_pass)
    return success
end

function SeasonPass.LoadSeasonPassInfo()
    local season_pass = Database.loadseasonpassinfo(context.addr_db_user, context.uid)
    return season_pass
end

function SeasonPass.PBGetSeasonPassPlayerReqCmd(req)
    -- 参数验证
    if not req.msg.uid then
        return context.S2C(context.net_id, CmdCode.PBGetSeasonPassPlayerRspCmd, {
            code = ErrorCode.ParamInvalid,
            error = "无效请求参数",
            uid = context.uid,
        }, req.msg_context.stub_id)
    end

    local season_pass = scripts.UserModel.GetSeasonPass()
    if not season_pass then
        return context.S2C(context.net_id, CmdCode.PBGetSeasonPassPlayerRspCmd,
            { code = ErrorCode.ServerInternalError, error = "数据加载出错", uid = context.uid }, req.msg_context.stub_id)
    end

    return context.S2C(context.net_id, CmdCode.PBGetSeasonPassPlayerRspCmd, {
        code = ErrorCode.None,
        error = "",
        uid = context.uid,
        season_pass_datas = season_pass,
    }, req.msg_context.stub_id)
end

function SeasonPass.PBUnlockSeasonPassReqCmd(req)
    -- 参数验证
    if not req.msg.uid or not req.msg.unlock_pass_id then
        return context.S2C(context.net_id, CmdCode.PBUnlockSeasonPassRspCmd, {
            code = ErrorCode.ParamInvalid,
            error = "无效请求参数",
            uid = context.uid,
        }, req.msg_context.stub_id)
    end

    local season_pass = scripts.UserModel.GetSeasonPass()
    if not season_pass then
        return context.S2C(context.net_id, CmdCode.PBUnlockSeasonPassRspCmd,
            { code = ErrorCode.ServerInternalError, error = "数据加载出错", uid = context.uid }, req.msg_context.stub_id)
    end
    if season_pass.season_pass_infos[req.msg.unlock_pass_id] then
        return context.S2C(context.net_id, CmdCode.PBUnlockSeasonPassRspCmd, {
            code = ErrorCode.AlreadyUnlockSeasonPass,
            error = "已解锁",
            uid = context.uid,
            season_pass_data = season_pass.season_pass_infos[req.msg.unlock_pass_id]
        }, req.msg_context.stub_id)
    end

    local seasonpass_cfg = GameCfg.SeasonPassShop[req.msg.unlock_pass_id]
    if not seasonpass_cfg then
        return context.S2C(context.net_id, CmdCode.PBUnlockSeasonPassRspCmd, {
            code = ErrorCode.ConfigError,
            error = "配置错误",
            uid = context.uid,
        }, req.msg_context.stub_id)
    end

    local now_ts = moon.time()
    if now_ts < seasonpass_cfg.time then
        return context.S2C(context.net_id, CmdCode.PBUnlockSeasonPassRspCmd, {
            code = ErrorCode.NotTimeUnlockSeaonPass,
            error = "未到解锁时间",
            uid = context.uid,
        }, req.msg_context.stub_id)
    end

    -- 计算消耗资源
    local cost_items = {}
    local cost_coins = {}
    ItemDefine.GetItemsFromCfg(seasonpass_cfg.unlock_cost, 1, true, cost_items, cost_coins)

    -- 检查资源是否足够
    local err_code_items = scripts.Bag.CheckItemsEnough(BagDef.BagType.Cangku, cost_items, {})
    if err_code_items ~= ErrorCode.None then
        return context.S2C(context.net_id, CmdCode.PBUnlockSeasonPassRspCmd, {
            code = ErrorCode.ItemNotExist,
            error = "消耗不足",
            uid = context.uid,
        }, req.msg_context.stub_id)
    end
    local err_code_coins = scripts.Bag.CheckCoinsEnough(cost_coins)
    if err_code_coins ~= ErrorCode.None then
        return context.S2C(context.net_id, CmdCode.PBUnlockSeasonPassRspCmd, {
            code = ErrorCode.ItemNotExist,
            error = "消耗不足",
            uid = context.uid,
        }, req.msg_context.stub_id)
    end

    -- 扣除消耗
    local change_log = {}
    local err_code_del = ErrorCode.None
    if table.size(cost_items) > 0 then
        err_code_del = scripts.Bag.DelItems(BagDef.BagType.Cangku, cost_items, {}, change_log)
        if err_code_del ~= ErrorCode.None then
            scripts.Bag.RollBackWithChange(change_log)
            return context.S2C(context.net_id, CmdCode.PBUnlockSeasonPassRspCmd, {
                code = ErrorCode.ItemNotExist,
                error = "消耗不足",
                uid = context.uid,
            }, req.msg_context.stub_id)
        end
    end
    if table.size(cost_coins) > 0 then
        err_code_del = scripts.Bag.DealCoins(cost_coins, change_log)
        if err_code_del ~= ErrorCode.None then
            scripts.Bag.RollBackWithChange(change_log)
            return context.S2C(context.net_id, CmdCode.PBUnlockSeasonPassRspCmd, {
                code = ErrorCode.CoinNotExist,
                error = "消耗不足",
                uid = context.uid,
            }, req.msg_context.stub_id)
        end
    end

    local new_seasonpass_info = SeasonPassDef.newSeasonPassData()
    new_seasonpass_info.pass_id = seasonpass_cfg.id
    season_pass.season_pass_infos[new_seasonpass_info.pass_id] = new_seasonpass_info

    -- 保存数据
    scripts.Bag.SaveAndLog(change_log, ItemDef.ChangeReason.SeasonPassUnlock)
    -- SeasonPass.SaveSeasonPasssNow()
    scripts.UserModel.AddDirtyModule("SeasonPass")

    return context.S2C(context.net_id, CmdCode.PBUnlockSeasonPassRspCmd, {
        code = ErrorCode.None,
        error = "",
        uid = context.uid,
        season_pass_data = new_seasonpass_info,
    }, req.msg_context.stub_id)
end

function SeasonPass.PBGetSeasonPassRewardReqCmd(req)
    -- 参数验证
    if not req.msg.uid or not req.msg.pass_id or not req.msg.cur_page_id or not req.msg.reward_id then
        return context.S2C(context.net_id, CmdCode.PBGetSeasonPassRewardRspCmd, {
            code = ErrorCode.ParamInvalid,
            error = "无效请求参数",
            uid = context.uid,
        }, req.msg_context.stub_id)
    end

    local season_pass = scripts.UserModel.GetSeasonPass()
    if not season_pass then
        return context.S2C(context.net_id, CmdCode.PBGetSeasonPassRewardRspCmd,
            { code = ErrorCode.ServerInternalError, error = "数据加载出错", uid = context.uid }, req.msg_context.stub_id)
    end
    if not season_pass.season_pass_infos[req.msg.pass_id] then
        return context.S2C(context.net_id, CmdCode.PBGetSeasonPassRewardRspCmd, {
            code = ErrorCode.NotUnlockSeasonPass,
            error = "未解锁",
            uid = context.uid,
            season_pass_data = season_pass.season_pass_infos[req.msg.pass_id]
        }, req.msg_context.stub_id)
    end

    local seasonpass_info = season_pass.season_pass_infos[req.msg.pass_id]
    if table.size(seasonpass_info.get_reward_id) > 0 then
        for _, reward_id in pairs(seasonpass_info.get_reward_id) do
            if reward_id == req.msg.reward_id then
                return context.S2C(context.net_id, CmdCode.PBGetSeasonPassRewardRspCmd, {
                    code = ErrorCode.AlreadyGetReward,
                    error = "已领取",
                    uid = context.uid,
                    season_pass_data = seasonpass_info
                }, req.msg_context.stub_id)
            end
        end
    end

    local seasonpass_cfg = GameCfg.SeasonPassShop[req.msg.pass_id]
    if not seasonpass_cfg then
        return context.S2C(context.net_id, CmdCode.PBGetSeasonPassRewardRspCmd, {
            code = ErrorCode.ConfigError,
            error = "配置错误",
            uid = context.uid,
        }, req.msg_context.stub_id)
    end
    if not seasonpass_cfg.group
        or not seasonpass_cfg.group[req.msg.cur_page_id] then
        return context.S2C(context.net_id, CmdCode.PBGetSeasonPassRewardRspCmd, {
            code = ErrorCode.ConfigError,
            error = "配置错误",
            uid = context.uid,
        }, req.msg_context.stub_id)
    end
    
    local group_id = seasonpass_cfg.group[req.msg.cur_page_id]
    local group_cfg = GameCfg.SeasonPassShopItemGroup[group_id]
    if not group_cfg or not group_cfg.group or table.size(group_cfg.group) == 0 then
        return context.S2C(context.net_id, CmdCode.PBGetSeasonPassRewardRspCmd, {
            code = ErrorCode.ConfigError,
            error = "配置错误",
            uid = context.uid,
        }, req.msg_context.stub_id)
    end

    if seasonpass_info.cost_coin < group_cfg.unlock_cost then
        return context.S2C(context.net_id, CmdCode.PBGetSeasonPassRewardRspCmd, {
            code = ErrorCode.CoinNotExist,
            error = "消耗不足",
            uid = context.uid,
        }, req.msg_context.stub_id)
    end

    local find_reward_id = false
    for _, reward_id in pairs(group_cfg.group) do
        if reward_id == req.msg.reward_id then
            find_reward_id = true
            break
        end
    end
    if not find_reward_id then
        return context.S2C(context.net_id, CmdCode.PBGetSeasonPassRewardRspCmd, {
            code = ErrorCode.ConfigError,
            error = "配置错误",
            uid = context.uid,
        }, req.msg_context.stub_id)
    end

    local reward_cfg = GameCfg.SeasonPassShopItem[req.msg.reward_id]
    if not reward_cfg then
        return context.S2C(context.net_id, CmdCode.PBGetSeasonPassRewardRspCmd, {
            code = ErrorCode.ConfigError,
            error = "配置错误",
            uid = context.uid,
        }, req.msg_context.stub_id)
    end
    local cost_coins = {}
    cost_coins[GONGDE_COIN_ID] = { coin_id = GONGDE_COIN_ID, coin_count = -reward_cfg.unlock_cost }

    -- 检查资源是否足够
    local err_code_coins = scripts.Bag.CheckCoinsEnough(cost_coins)
    if err_code_coins ~= ErrorCode.None then
        return context.S2C(context.net_id, CmdCode.PBGetSeasonPassRewardRspCmd, {
            code = ErrorCode.ItemNotExist,
            error = "消耗不足",
            uid = context.uid,
        }, req.msg_context.stub_id)
    end

    local reward_cfg_list = table.copy(reward_cfg.item, true)

    -- 检测是否有角色
    local add_roles = {}
    for reward_id, reward_cnt in pairs(reward_cfg_list or {}) do
        if RoleDef.RoleDefine.RoleID.Start <= reward_id
            and reward_id <= RoleDef.RoleDefine.RoleID.End then
            if reward_cnt > 1 or add_roles[reward_id] then
                return context.S2C(context.net_id, CmdCode.PBGetSeasonPassRewardRspCmd, {
                    code = ErrorCode.UseGiftNumError,
                    error = "配置错误",
                    uid = context.uid,
                }, req.msg_context.stub_id)
            end
            add_roles[reward_id] = 1
        end
    end
    -- 检测角色是否可以获得
    if table.size(add_roles) > 0 then
        local role_err_code = scripts.Role.CheckAddRoles(add_roles)
        if role_err_code ~= ErrorCode.None then
            return context.S2C(context.net_id, CmdCode.PBGetSeasonPassRewardRspCmd, {
                code = role_err_code,
                error = "角色已存在",
                uid = context.uid,
            }, req.msg_context.stub_id)
        end

        -- 将角色从reward_cfg_list中移除
        for role_id, _ in pairs(add_roles) do
            reward_cfg_list[role_id] = nil
        end
    end

    -- 计算获得资源
    local add_items, add_coins = {}, {}
    ItemDefine.GetItemsFromCfg(reward_cfg_list, 1, false, add_items, add_coins)
    if table.size(add_items) + table.size(add_coins) + table.size(add_roles) <= 0 then
        return context.S2C(context.net_id, CmdCode.PBGetSeasonPassRewardRspCmd, {
            code = ErrorCode.ConfigError,
            error = "配置错误",
            uid = context.uid,
        }, req.msg_context.stub_id)
    end
    if table.size(add_items) > 0 then
        local ret_code = scripts.Bag.TryEmptyEnough(BagDef.BagType.Cangku, add_items, 0)
        if ret_code ~= ErrorCode.None then
            return context.S2C(context.net_id, CmdCode.PBGetSeasonPassRewardRspCmd, {
                code = ret_code,
                error = "尝试添加道具失败",
                uid = context.uid,
            }, req.msg_context.stub_id)
        end
    end

    -- 根据道具表生成item_data
    local stack_items, unstack_items, deal_coins = {}, {}, {}
    local ok = ItemDefine.GetItemDataFromIdCount(add_items, add_coins, stack_items, unstack_items, deal_coins)
    if not ok then
        return context.S2C(context.net_id, CmdCode.PBGetSeasonPassRewardRspCmd, {
            code = ErrorCode.ConfigError,
            error = "配置错误",
            uid = context.uid,
        }, req.msg_context.stub_id)
    end

    local bag_change_log = {}
    -- 扣除道具消耗
    if table.size(cost_coins) > 0 then
        local ret_code = scripts.Bag.DealCoins(cost_coins, bag_change_log)
        if ret_code ~= ErrorCode.None then
            scripts.Bag.RollBackWithChange(bag_change_log)
            return context.S2C(context.net_id, CmdCode.PBGetSeasonPassRewardRspCmd, {
                code = ret_code,
                error = "消耗不足",
                uid = context.uid,
            }, req.msg_context.stub_id)
        end
    end
    -- 添加道具
    if table.size(stack_items) + table.size(unstack_items) > 0 then
        local ret_code = scripts.Bag.AddItems(BagDef.BagType.Cangku, stack_items, unstack_items, bag_change_log)
        if ret_code ~= ErrorCode.None then
            scripts.Bag.RollBackWithChange(bag_change_log)
            return context.S2C(context.net_id, CmdCode.PBGetSeasonPassRewardRspCmd, {
                code = ret_code,
                error = "添加道具失败",
                uid = context.uid,
            }, req.msg_context.stub_id)
        end
    end

    local change_roles = {}
    -- 添加角色
    if table.size(add_roles) then
        for roleid, _ in pairs(add_roles) do
            local role_err_code = scripts.Role.AddRole(roleid)
            if role_err_code ~= ErrorCode.None then
                scripts.Bag.RollBackWithChange(bag_change_log)
                return context.S2C(context.net_id, CmdCode.PBGetSeasonPassRewardRspCmd, {
                    code = ErrorCode.RoleAddFail,
                    error = "添加角色失败",
                    uid = context.uid,
                }, req.msg_context.stub_id)
            end
            change_roles[roleid] = "AddRole"
        end
    end

    seasonpass_info.cost_coin = seasonpass_info.cost_coin + reward_cfg.unlock_cost
    table.insert(seasonpass_info.get_reward_id, req.msg.reward_id)

    -- 保存数据
    scripts.Bag.SaveAndLog(bag_change_log, ItemDef.ChangeReason.SeasonPassGetReward)
    -- 角色变更
    if table.size(change_roles) > 0 then
        scripts.Role.SaveAndLog(change_roles)
    end
    SeasonPass.SaveSeasonPasssNow()

    return context.S2C(context.net_id, CmdCode.PBGetSeasonPassRewardRspCmd, {
        code = ErrorCode.None,
        error = "",
        uid = context.uid,
        season_pass_data = seasonpass_info,
    }, req.msg_context.stub_id)
end

return SeasonPass