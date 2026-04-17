local moon = require "moon"
local common = require "common"
local GameCfg = common.GameCfg
local ErrorCode = common.ErrorCode
local CmdCode = common.CmdCode
local Database = common.Database
local ItemDef = require("common.def.ItemDef")
local BagDef = require("common.def.BagDef")
local ItemDefine = require("common.logic.ItemDefine")
local CommonCfgDef = require("common.def.CommonCfgDef")
local AweItemDef = require("common.def.AweItemDef")

---@type user_context
local context = ...
local scripts = context.scripts

---@class AweItem
local AweItem = {}

function AweItem.Init()
    --加载全部角色数据
    local aweiteminfo = AweItem.LoadAweItem()
    if aweiteminfo then
        scripts.UserModel.SetAweItems(aweiteminfo)
    end

    local aweitems = scripts.UserModel.GetAweItems()
    if not aweitems then
        aweitems = AweItemDef.newAweItems()
        scripts.UserModel.SetAweItems(aweitems)
    end
end

function AweItem.Start(isnew)
    local aweitems = scripts.UserModel.GetAweItems()
    if not aweitems then
        return false
    end

    if isnew then
        -- 初始化AweItem
        -- for _, item in pairs(aweitems) do
        --     item.config_id = 0
        --     item.up_level = 0
        --     item.star_level = 0
        --     item.buff_ids = {}
        --     item.star_lv_fail_cnt = 0
        -- end
        AweItem.SaveAweItemNow()
    end
end

function AweItem.SaveAweItemNow()
    local aweitems = scripts.UserModel.GetAweItems()
    if not aweitems then
        return false
    end

    local success = Database.saveuseraweitem(context.addr_db_user, context.uid, aweitems)
    return success
end

function AweItem.LoadAweItem()
    local aweiteminfo = Database.loaduseraweitem(context.addr_db_user, context.uid)
    return aweiteminfo
end

function AweItem.SaveAndLog()
    local aweitems = scripts.UserModel.GetAweItems()
    if not aweitems then    
        return false
    end

    AweItem.SaveAweItemNow()
    context.S2C(context.net_id, CmdCode["PBAweItemsSyncCmd"], { awe_item_info = aweitems }, 0)

    return true
end

function AweItem.PBAweItemsGetInfoReqCmd(req)
    local aweitems = scripts.UserModel.GetAweItems()
    if not aweitems then
        return context.S2C(context.net_id, CmdCode.PBAweItemsGetInfoRspCmd,
            { code = ErrorCode.ServerInternalError, error = "数据加载出错", uid = context.uid },
            req.msg_context.stub_id)
    end

    local rsp_msg = {
        code = ErrorCode.None,
        error = "",
        uid = req.msg.uid,
        awe_item_info = aweitems,
    }

    return context.S2C(context.net_id, CmdCode.PBAweItemsGetInfoRspCmd, rsp_msg, req.msg_context.stub_id)
end

function AweItem.PBAweItemUpLvReqCmd(req)
    -- 参数验证
    if not req.msg.awe_item_id then
        return context.S2C(context.net_id, CmdCode.PBAweItemUpLvRspCmd, {
            code = ErrorCode.ParamInvalid,
            error = "无效的请求参数",
            uid = context.uid,
        }, req.msg_context.stub_id)
    end

    local awe_cfg = GameCfg.OnlyOneItem[req.msg.awe_item_id]
    if not awe_cfg then
        return context.S2C(context.net_id, CmdCode.PBAweItemUpLvRspCmd, {
            code = ErrorCode.ConfigError,
            error = "配置不存在",
            uid = context.uid,
        }, req.msg_context.stub_id)
    end

    local aweitems = scripts.UserModel.GetAweItems()
    if not aweitems then
        return context.S2C(context.net_id, CmdCode.PBAweItemUpLvRspCmd,
            { code = ErrorCode.ServerInternalError, error = "数据加载出错", uid = context.uid },
            req.msg_context.stub_id)
    end

    -- 从map中获取对应的道具
    local aweitem = aweitems.awe_item_map[req.msg.awe_item_id]
    if not aweitem then
        return context.S2C(context.net_id, CmdCode.PBAweItemUpLvRspCmd, {
            code = ErrorCode.AweItemNotUnlock,
            error = "镇山之宝未解锁",
            uid = context.uid,
        }, req.msg_context.stub_id)
    end

    -- 获取镇上之宝的等级
    local now_level = aweitem.up_level

    local uplv_cfg = GameCfg.AweItemUpLv[now_level + 1]
    if not uplv_cfg or not uplv_cfg.cost then
        return context.S2C(context.net_id, CmdCode.PBAweItemUpLvRspCmd, {
            code = ErrorCode.ConfigError,
            error = "配置不存在",
            uid = context.uid,
        }, req.msg_context.stub_id)
    end

    local session_lv_condition = uplv_cfg.condition
    -- 判断一次赛季等级和是否达到条件

    local change_reason = ItemDef.ChangeReason.AweItemUpLv
    local level_field = "up_level"

    -- 计算消耗资源
    local cost_items = {}
    local cost_coins = {}
    ItemDefine.GetItemsFromCfg(uplv_cfg.cost, 1, true, cost_items, cost_coins)

    -- 检查资源是否足够
    local err_code_items = scripts.Bag.CheckItemsEnough(BagDef.BagType.Cangku, cost_items, {})
    if err_code_items ~= ErrorCode.None then
        return context.S2C(context.net_id, CmdCode.PBAweItemUpLvRspCmd, {
            code = ErrorCode.ItemNotExist,
            error = "消耗不足",
            uid = context.uid,
        }, req.msg_context.stub_id)
    end
    local err_code_coins = scripts.Bag.CheckCoinsEnough(cost_coins)
    if err_code_coins ~= ErrorCode.None then
        return context.S2C(context.net_id, CmdCode.PBAweItemUpLvRspCmd, {
            code = ErrorCode.CoinNotExist,
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
            return context.S2C(context.net_id, CmdCode.PBAweItemUpLvRspCmd, {
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
            return context.S2C(context.net_id, CmdCode.PBAweItemUpLvRspCmd, {
                code = ErrorCode.CoinNotExist,
                error = "消耗不足",
                uid = context.uid,
            }, req.msg_context.stub_id)
        end
    end

    -- 升级必定成功
    aweitem[level_field] = now_level + 1

    -- 保存数据
    scripts.Bag.SaveAndLog(change_log, change_reason)
    AweItem.SaveAndLog()

    return context.S2C(context.net_id, CmdCode.PBAweItemUpLvRspCmd, {
        code = ErrorCode.None,
        error = "",
        uid = context.uid,
        awe_item_info = aweitems,
    }, req.msg_context.stub_id)
end

function AweItem.UpStar(awe_item_id)
    local awe_cfg = GameCfg.OnlyOneItem[awe_item_id]
    if not awe_cfg then
        return ErrorCode.ConfigError, nil
    end

    local star_cfg = GameCfg.UpStar[awe_item_id]
    if not star_cfg then
        return ErrorCode.ConfigError, nil
    end

    local aweitems = scripts.UserModel.GetAweItems()
    if not aweitems then
        return ErrorCode.ServerInternalError, nil
    end

    -- 从map中获取对应的道具
    local aweitem = aweitems.awe_item_map[awe_item_id]
    if not aweitem then
        return ErrorCode.AweItemNotUnlock, nil
    end

    local now_star_level = aweitem.star_level

    local awe_level = aweitem.up_level
    local uplv_cfg = GameCfg.AweItemUpLv[awe_level]
    if not uplv_cfg then
        return ErrorCode.ConfigError, nil
    end

    if now_star_level >= uplv_cfg.max_star then
        return ErrorCode.ItemMaxStar, nil
    end
    if now_star_level >= star_cfg.maxlv then
         return ErrorCode.ItemMaxStar, nil
     end

    local cost_key = "cost" .. (now_star_level + 1)
    if not star_cfg[cost_key] then
        return ErrorCode.ConfigError, nil
    end
    local cost_cfg = star_cfg[cost_key]
    if not cost_cfg then
        return ErrorCode.ConfigError, nil
    end
    
    local rate_key = "rate" .. (now_star_level + 1)
    if not star_cfg[rate_key] then
        return ErrorCode.ConfigError, nil
    end
    local rate_cfg = star_cfg[rate_key]
    if not rate_cfg then
        return ErrorCode.ConfigError, nil
    end
        
    local fail_cnt_field = "star_lv_fail_cnt"
    local level_field = "star_level"

    -- 计算消耗资源
    local cost_items = {}
    local cost_coins = {}
    ItemDefine.GetItemsFromCfg(cost_cfg, 1, true, cost_items, cost_coins)

    -- 检查资源是否足够
    local err_code_items = scripts.Bag.CheckItemsEnough(BagDef.BagType.Cangku, cost_items, {})
    if err_code_items ~= ErrorCode.None then
        return ErrorCode.ItemNotExist, nil
    end
    local err_code_coins = scripts.Bag.CheckCoinsEnough(cost_coins)
    if err_code_coins ~= ErrorCode.None then
        return ErrorCode.CoinNotExist, nil
    end

    -- 扣除消耗
    local change_log = {}
    local err_code_del = ErrorCode.None
    if table.size(cost_items) > 0 then
        err_code_del = scripts.Bag.DelItems(BagDef.BagType.Cangku, cost_items, {}, change_log)
        if err_code_del ~= ErrorCode.None then
            scripts.Bag.RollBackWithChange(change_log)
            return ErrorCode.ItemNotExist, nil
        end
    end
    if table.size(cost_coins) > 0 then
        err_code_del = scripts.Bag.DealCoins(cost_coins, change_log)
        if err_code_del ~= ErrorCode.None then
            scripts.Bag.RollBackWithChange(change_log)
            return ErrorCode.CoinNotExist, nil
        end
    end

    -- 计算升星概率
    local add_rate_cfg = CommonCfgDef.getConf("UpStarAdditionRate")
    if not add_rate_cfg then
        return ErrorCode.ConfigError, nil
    end
    local now_rate = rate_cfg + add_rate_cfg.value * aweitem[fail_cnt_field]
    local rand_num = math.random(1, 10000)
    moon.error(" 1111111111111 rand_num =  " .. rand_num .. " now_rate = " .. now_rate)
    local success = rand_num <= now_rate
    moon.error(" 1111111111111 success = " .. tostring(success))

    if success then
        aweitem[level_field] = now_star_level + 1
        aweitem[fail_cnt_field] = 0
        
        local awe_cfg = GameCfg.OnlyOneItem[awe_item_id]
        if not awe_cfg then
            return ErrorCode.ConfigError, nil
        end

        -- 在aweitem里面添加buffid
        for star_lv, buff_id in ipairs(awe_cfg.buff) do
            if star_lv == now_star_level + 1 then
                aweitem.buff_id = buff_id
                scripts.User.AddAccountBuff(nil, nil, buff_id)
            end
        end
    else
        aweitem[fail_cnt_field] = aweitem[fail_cnt_field] + 1
    end

    -- 保存数据
    AweItem.SaveAndLog()

    return success and ErrorCode.None or ErrorCode.UpStarProbFail, change_log
end

function AweItem.AweItemUnlock(aweitem_id)
    -- 参数验证
    if not aweitem_id then
        return ErrorCode.ParamInvalid
    end

    local aweitems = scripts.UserModel.GetAweItems()
    if not aweitems then
        return ErrorCode.ServerInternalError
    end

    local aweitem = aweitems.awe_item_map[aweitem_id]
    if aweitem then
        return ErrorCode.AweItemAlreadyUnlock
    end

    -- 获取解锁配置
    local awe_cfg = GameCfg.OnlyOneItem[aweitem_id]
    if not awe_cfg then
        return ErrorCode.ConfigError
    end

    -- 创建新的AweItem
    local aweitem = AweItemDef.newAweItem()
    aweitem.config_id = aweitem_id
    aweitem.up_level = 1
    aweitem.star_level = 1
    for star_lv, buff_id in ipairs(awe_cfg.buff) do
        if star_lv == 1 then
            aweitem.buff_id = buff_id
            scripts.User.AddAccountBuff(nil, nil, buff_id)
        end
    end
    aweitems.awe_item_map[aweitem_id] = aweitem

    -- 保存数据
    AweItem.SaveAndLog()

    return ErrorCode.None
end

return AweItem