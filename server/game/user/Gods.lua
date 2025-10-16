local moon = require "moon"
local common = require "common"
local protocol = require("common.protocol_pb")
local clusterd = require("cluster")
local GameCfg = common.GameCfg
local ErrorCode = common.ErrorCode
local CmdCode = common.CmdCode
local Database = common.Database
local ProtoEnum = require("tools.ProtoEnum")
local GodsDef = require("common.def.GodsDef")
local BagDef = require("common.def.BagDef")
local ItemDef = require("common.def.ItemDef")
local ItemDefine = require("common.logic.ItemDefine")

---@type user_context
local context = ...
local scripts = context.scripts

---@class Gods
local Gods = {}

function Gods.Init()
    --加载全部角色数据
    local godsinfo = Gods.LoadGods()
    if godsinfo then
        scripts.UserModel.SetGods(godsinfo)
    end

    local gods = scripts.UserModel.GetGods()
    if not gods then
        gods = GodsDef.newUserGods()
        scripts.UserModel.SetGods(gods)
    end
end

function Gods.Start(isnew)
    local gods = scripts.UserModel.GetGods()
    if not gods then
        return false
    end

    if isnew then
        -- 初始化Gods
        for _, god in pairs(GameCfg.GodList) do
            if god.default_unlock == 1 then
                local god_image = GodsDef.newGodImage()
                god_image.config_id = god.id
                gods.gods_image[god.id] = god_image
            end
        end
        for _, block in pairs(GameCfg.GodSlot) do
            if block.default_unlock == 1 then
                local god_block = GodsDef.newGodBlock()
                god_block.idx = block.id
                gods.gods_block[block.id] = god_block
            end
        end

        Gods.SaveGodsNow()
    end
end

function Gods.SaveGodsNow()
    local gods = scripts.UserModel.GetGods()
    if not gods then
        return false
    end

    local success = Database.saveusergods(context.addr_db_user, context.uid, gods)
    return success
end

function Gods.LoadGods()
    local godsinfo = Database.loadusergods(context.addr_db_user, context.uid)
    return godsinfo
end

function Gods.SaveAndLog(change_gods, change_blocks)
    local gods = scripts.UserModel.GetGods()
    if not gods then
        return false
    end

    local update_info = {
        gods_image = {},
        gods_block = {},
    }
    if change_gods then
        for god_id, _ in pairs(change_gods) do
            update_info.gods_image[god_id] = gods.gods_image[god_id]
        end
    end
    if change_blocks then
        for block_id, _ in pairs(change_blocks) do
            update_info.gods_block[block_id] = gods.gods_block[block_id]
        end
    end

    Gods.SaveGodsNow()
    if table.size(update_info.gods_image) + table.size(update_info.gods_block) > 0 then
        context.S2C(context.net_id, CmdCode["PBGodsInfoSyncCmd"], { gods_info = update_info }, 0)
    end

    return true
end

function Gods.GetBattleGods()
    local gods = scripts.UserModel.GetGods()
    if not gods then
        return nil
    end

    local res = GodsDef.newUserGods()
    for _, block in pairs(gods.gods_block) do
        res.gods_block[block.idx] = block
        if block.god_id > 0 then
            res.gods_image[block.god_id] = gods.gods_image[block.god_id]
        end
    end

    return res
end

function Gods.PBGodsGetInfoReqCmd(req)
    local gods = scripts.UserModel.GetGods()
    if not gods then
        return context.S2C(context.net_id, CmdCode.PBGodsGetInfoRspCmd,
            { code = ErrorCode.ServerInternalError, error = "数据加载出错", uid = context.uid },
            req.msg_context.stub_id)
    end

    local rsp_msg = {
        code = ErrorCode.None,
        error = "",
        uid = req.msg.uid,
        gods_info = gods,
    }

    return context.S2C(context.net_id, CmdCode.PBGodsGetInfoRspCmd, rsp_msg, req.msg_context.stub_id)
end

function Gods.PBGodsUnlockReqCmd(req)
    -- 参数验证
    if not req.msg.god_id then
        return context.S2C(context.net_id, CmdCode.PBGodsUnlockRspCmd, {
            code = ErrorCode.ParamInvalid,
            error = "无效请求参数",
            uid = context.uid,
        }, req.msg_context.stub_id)
    end

    local gods = scripts.UserModel.GetGods()
    if not gods then
        return context.S2C(context.net_id, CmdCode.PBGodsUnlockRspCmd,
            { code = ErrorCode.ServerInternalError, error = "数据加载出错", uid = context.uid },
            req.msg_context.stub_id)
    end
    if gods.gods_image[req.msg.god_id] then
        return context.S2C(context.net_id, CmdCode.PBGodsUnlockRspCmd, {
            code = ErrorCode.GodAlreadyUnlock,
            error = "已解锁",
            uid = context.uid,
            god_image = gods.gods_image[req.msg.god_id],
        }, req.msg_context.stub_id)
    end

    local god_cfg = GameCfg.GodList[req.msg.god_id]
    if not god_cfg then
        return context.S2C(context.net_id, CmdCode.PBGodsUnlockRspCmd, {
            code = ErrorCode.ConfigError,
            error = "配置不存在",
            uid = context.uid,
        }, req.msg_context.stub_id)
    end

    -- 计算消耗资源
    local cost_items = {}
    local cost_coins = {}
    ItemDefine.GetItemsFromCfg(god_cfg.unlock_cost, 1, true, cost_items, cost_coins)

    -- 检查资源是否足够
    local err_code_items = scripts.Bag.CheckItemsEnough(BagDef.BagType.Cangku, cost_items, {})
    if err_code_items ~= ErrorCode.None then
        return context.S2C(context.net_id, CmdCode.PBGodsUnlockRspCmd, {
            code = ErrorCode.ItemNotExist,
            error = "消耗不足",
            uid = context.uid,
        }, req.msg_context.stub_id)
    end
    local err_code_coins = scripts.Bag.CheckCoinsEnough(cost_coins)
    if err_code_coins ~= ErrorCode.None then
        return context.S2C(context.net_id, CmdCode.PBGodsUnlockRspCmd, {
            code = ErrorCode.ItemNotExist,
            error = "消耗不足",
            uid = context.uid,
        }, req.msg_context.stub_id)
    end

    local god_image = GodsDef.newGodImage()
    god_image.config_id = god_cfg.id
    gods.gods_image[god_cfg.id] = god_image

    -- 扣除消耗
    local change_log = {}
    local err_code_del = ErrorCode.None
    if table.size(cost_items) > 0 then
        err_code_del = scripts.Bag.DelItems(BagDef.BagType.Cangku, cost_items, {}, change_log)
        if err_code_del ~= ErrorCode.None then
            scripts.Bag.RollBackWithChange(change_log)
            return context.S2C(context.net_id, CmdCode.PBGodsUnlockRspCmd, {
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
            return context.S2C(context.net_id, CmdCode.PBGodsUnlockRspCmd, {
                code = ErrorCode.CoinNotExist,
                error = "消耗不足",
                uid = context.uid,
            }, req.msg_context.stub_id)
        end
    end

    -- 保存数据
    scripts.Bag.SaveAndLog(change_log, ItemDef.ChangeReason.GodsUnlock)
    Gods.SaveAndLog({ [god_cfg.id] = 1 }, nil)

    return context.S2C(context.net_id, CmdCode.PBGodsUnlockRspCmd, {
        code = ErrorCode.None,
        error = "",
        uid = context.uid,
        god_image = god_image,
    }, req.msg_context.stub_id)
end

function Gods.PBGodsUpLvReqCmd(req)
    -- 参数验证
    if not req.msg.god_id then
        return context.S2C(context.net_id, CmdCode.PBGodsUpLvRspCmd, {
            code = ErrorCode.ParamInvalid,
            error = "无效请求参数",
            uid = context.uid,
        }, req.msg_context.stub_id)
    end

    local gods = scripts.UserModel.GetGods()
    if not gods then
        return context.S2C(context.net_id, CmdCode.PBGodsUpLvRspCmd,
            { code = ErrorCode.ServerInternalError, error = "数据加载出错", uid = context.uid },
            req.msg_context.stub_id)
    end
    if not gods.gods_image[req.msg.god_id] then
        return context.S2C(context.net_id, CmdCode.PBGodsUpLvRspCmd, {
            code = ErrorCode.GodNotUnlock,
            error = "未解锁",
            uid = context.uid,
        }, req.msg_context.stub_id)
    end

    local now_lv = gods.gods_image[req.msg.god_id].lv
    local level_cfg = GameCfg.GodLevel[now_lv + 1]
    if not level_cfg then
        return context.S2C(context.net_id, CmdCode.PBGodsUpLvRspCmd, {
            code = ErrorCode.ConfigError,
            error = "配置不存在",
            uid = context.uid,
        }, req.msg_context.stub_id)
    end

    -- 计算消耗资源
    local cost_items = {}
    local cost_coins = {}
    ItemDefine.GetItemsFromCfg(level_cfg.cost, 1, true, cost_items, cost_coins)

    -- 检查资源是否足够
    local err_code_items = scripts.Bag.CheckItemsEnough(BagDef.BagType.Cangku, cost_items, {})
    if err_code_items ~= ErrorCode.None then
        return context.S2C(context.net_id, CmdCode.PBGodsUpLvRspCmd, {
            code = ErrorCode.ItemNotExist,
            error = "消耗不足",
            uid = context.uid,
        }, req.msg_context.stub_id)
    end
    local err_code_coins = scripts.Bag.CheckCoinsEnough(cost_coins)
    if err_code_coins ~= ErrorCode.None then
        return context.S2C(context.net_id, CmdCode.PBGodsUpLvRspCmd, {
            code = ErrorCode.ItemNotExist,
            error = "消耗不足",
            uid = context.uid,
        }, req.msg_context.stub_id)
    end

    gods.gods_image[req.msg.god_id].lv = now_lv + 1

    -- 扣除消耗
    local change_log = {}
    local err_code_del = ErrorCode.None
    if table.size(cost_items) > 0 then
        err_code_del = scripts.Bag.DelItems(BagDef.BagType.Cangku, cost_items, {}, change_log)
        if err_code_del ~= ErrorCode.None then
            scripts.Bag.RollBackWithChange(change_log)
            return context.S2C(context.net_id, CmdCode.PBGodsUpLvRspCmd, {
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
            return context.S2C(context.net_id, CmdCode.PBGodsUpLvRspCmd, {
                code = ErrorCode.CoinNotExist,
                error = "消耗不足",
                uid = context.uid,
            }, req.msg_context.stub_id)
        end
    end

    -- 保存数据
    scripts.Bag.SaveAndLog(change_log, ItemDef.ChangeReason.GodsUpLv)
    Gods.SaveAndLog({ [req.msg.god_id] = 1 }, nil)

    return context.S2C(context.net_id, CmdCode.PBGodsUpLvRspCmd, {
        code = ErrorCode.None,
        error = "",
        uid = context.uid,
        god_image = gods.gods_image[req.msg.god_id],
    }, req.msg_context.stub_id)
end

function Gods.PBGodsBlockUnlockReqCmd(req)
    -- 参数验证
    if not req.msg.unlock_idx then
        return context.S2C(context.net_id, CmdCode.PBGodsBlockUnlockRspCmd, {
            code = ErrorCode.ParamInvalid,
            error = "无效请求参数",
            uid = context.uid,
        }, req.msg_context.stub_id)
    end

    local gods = scripts.UserModel.GetGods()
    if not gods then
        return context.S2C(context.net_id, CmdCode.PBGodsBlockUnlockRspCmd,
            { code = ErrorCode.ServerInternalError, error = "数据加载出错", uid = context.uid },
            req.msg_context.stub_id)
    end
    if gods.gods_block[req.msg.unlock_idx] then
        return context.S2C(context.net_id, CmdCode.PBGodsBlockUnlockRspCmd, {
            code = ErrorCode.GodBlockAlreadyUnlock,
            error = "已解锁",
            uid = context.uid,
        }, req.msg_context.stub_id)
    end

    local block_cfg = GameCfg.GodSlot[req.msg.unlock_idx]
    if not block_cfg then
        return context.S2C(context.net_id, CmdCode.PBGodsBlockUnlockRspCmd, {
            code = ErrorCode.ConfigError,
            error = "配置不存在",
            uid = context.uid,
        }, req.msg_context.stub_id)
    end

    local query_user_attr = {}
    table.insert(query_user_attr, ProtoEnum.UserAttrType.account_level)
    local query_res = scripts.User.QueryUserAttr(query_user_attr)
    if query_res.user_attr[ProtoEnum.UserAttrType.account_level]
        and query_res.user_attr[ProtoEnum.UserAttrType.account_level] < block_cfg.unlock_godnum then
        return context.S2C(context.net_id, CmdCode.PBGodsBlockUnlockRspCmd, {
            code = ErrorCode.GodBlockUnlockLevelNotEnough,
            error = "解锁等级不足",
            uid = context.uid,
        }, req.msg_context.stub_id)
    end
    if table.size(gods.gods_image) < block_cfg.unlock_godnum then
        return context.S2C(context.net_id, CmdCode.PBGodsBlockUnlockRspCmd, {
            code = ErrorCode.GodBlockUnlockGodNumNotEnough,
            error = "解锁神明数量不足",
            uid = context.uid,
        }, req.msg_context.stub_id)
    end

    -- 计算消耗资源
    local cost_items = {}
    local cost_coins = {}
    ItemDefine.GetItemsFromCfg(block_cfg.cost, 1, true, cost_items, cost_coins)

    -- 检查资源是否足够
    local err_code_items = scripts.Bag.CheckItemsEnough(BagDef.BagType.Cangku, cost_items, {})
    if err_code_items ~= ErrorCode.None then
        return context.S2C(context.net_id, CmdCode.PBGodsBlockUnlockRspCmd, {
            code = ErrorCode.ItemNotExist,
            error = "消耗不足",
            uid = context.uid,
        }, req.msg_context.stub_id)
    end
    local err_code_coins = scripts.Bag.CheckCoinsEnough(cost_coins)
    if err_code_coins ~= ErrorCode.None then
        return context.S2C(context.net_id, CmdCode.PBGodsBlockUnlockRspCmd, {
            code = ErrorCode.CoinNotExist,
            error = "消耗不足",
            uid = context.uid,
        }, req.msg_context.stub_id)
    end

    local god_block = GodsDef.newGodBlock()
    god_block.idx = block_cfg.id
    gods.gods_block[block_cfg.id] = god_block

    -- 扣除消耗
    local change_log = {}
    local err_code_del = ErrorCode.None
    if table.size(cost_items) > 0 then
        err_code_del = scripts.Bag.DelItems(BagDef.BagType.Cangku, cost_items, {}, change_log)
        if err_code_del ~= ErrorCode.None then
            scripts.Bag.RollBackWithChange(change_log)
            return context.S2C(context.net_id, CmdCode.PBGodsBlockUnlockRspCmd, {
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
            return context.S2C(context.net_id, CmdCode.PBGodsBlockUnlockRspCmd, {
                code = ErrorCode.CoinNotExist,
                error = "消耗不足",
                uid = context.uid,
            }, req.msg_context.stub_id)
        end
    end

    -- 保存数据
    scripts.Bag.SaveAndLog(change_log, ItemDef.ChangeReason.GodsBlockUnlock)
    Gods.SaveAndLog(nil, { [block_cfg.id] = 1 })

    return context.S2C(context.net_id, CmdCode.PBGodsBlockUnlockRspCmd, {
        code = ErrorCode.None,
        error = "",
        uid = context.uid,
        god_block = god_block,
    }, req.msg_context.stub_id)
end

function Gods.PBGodsWearOrTakeoffReqCmd(req)
    -- 参数验证
    if not req.msg.block_idx
        or not req.msg.god_id then
        return context.S2C(context.net_id, CmdCode.PBGodsWearOrTakeoffRspCmd, {
            code = ErrorCode.ParamInvalid,
            error = "无效请求参数",
            uid = context.uid,
        }, req.msg_context.stub_id)
    end

    local gods = scripts.UserModel.GetGods()
    if not gods then
        return context.S2C(context.net_id, CmdCode.PBGodsWearOrTakeoffRspCmd,
            { code = ErrorCode.ServerInternalError, error = "数据加载出错", uid = context.uid },
            req.msg_context.stub_id)
    end
    if not gods.gods_block[req.msg.block_idx] then
        return context.S2C(context.net_id, CmdCode.PBGodsWearOrTakeoffRspCmd, {
            code = ErrorCode.GodBlockNotUnlock,
            error = "未解锁",
            uid = context.uid,
        }, req.msg_context.stub_id)
    end
    if req.msg.god_id > 0 and not gods.gods_image[req.msg.god_id] then
        return context.S2C(context.net_id, CmdCode.PBGodsWearOrTakeoffRspCmd, {
            code = ErrorCode.GodNotUnlock,
            error = "未解锁",
            uid = context.uid,
        }, req.msg_context.stub_id)
    end

    gods.gods_block[req.msg.block_idx].god_id = req.msg.god_id

    -- 保存数据
    Gods.SaveAndLog(nil, { [req.msg.block_idx] = 1 })

    return context.S2C(context.net_id, CmdCode.PBGodsWearOrTakeoffRspCmd, {
        code = ErrorCode.None,
        error = "",
        uid = context.uid,
        god_block = gods.gods_block[req.msg.block_idx],
    }, req.msg_context.stub_id)
end

return Gods