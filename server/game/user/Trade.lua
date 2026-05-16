local moon = require "moon"
local common = require "common"
local clusterd = require("cluster")
local datetime = require("moon.datetime")
local GameCfg = common.GameCfg
local ErrorCode = common.ErrorCode
local CmdCode = common.CmdCode
local Database = common.Database
local json = require "json"
local TradeDef = require("common.def.TradeDef")
local BagDef = require("common.def.BagDef")
local ItemDef = require("common.def.ItemDef")
local ItemDefine = require("common.logic.ItemDefine")

---@type user_context
local context = ...
local scripts = context.scripts

local MAX_SALE_CAPACITY = 50
local MAX_SEARCH_IDS_COUNT = 100
local TRADE_LOG_MAX_COUNT = 100

---@class Trade
local Trade = {}

function Trade.Init()
    local trade_info = Trade.LoadTradeInfo()
    if trade_info then
        local trade_data = TradeDef.newSelfTradeData()
        trade_data.simple_info = trade_info
        scripts.UserModel.SetTradeData(trade_data)
    end

    local player_trade_data = scripts.UserModel.GetTradeData()
    if not player_trade_data then
        player_trade_data = TradeDef.newSelfTradeData()
        local trade_cfg = GameCfg.TransactionConfig[1]
        if trade_cfg and trade_cfg.order_num and trade_cfg.account_market then
            player_trade_data.simple_info.box_capacity = trade_cfg.order_num
            player_trade_data.simple_info.can_onsale_cnt = trade_cfg.account_market
            player_trade_data.simple_info.update_ts = moon.time()
        end
        scripts.UserModel.SetTradeData(player_trade_data)
    end
end

function Trade.Start()
    local player_trade_data = scripts.UserModel.GetTradeData()
    if not player_trade_data then
        return
    end

    Trade.CheckData()
    if not TradeDef.GM_UID[context.uid] then
        Trade.DealOfflineTradeLogSale()
        Trade.DealOfflineTradeTakeDown()
    end

    Trade.SaveTradeInfoNow()
end

function Trade.CheckData()
    local player_trade_data = scripts.UserModel.GetTradeData()
    if not player_trade_data then
        return false
    end

    if player_trade_data.simple_info.trade_ids and table.size(player_trade_data.simple_info.trade_ids) > 0 then
        local new_product_datas = Database.RedisGetProductData(context.addr_db_redis, player_trade_data.simple_info
            .trade_ids)
        if new_product_datas then
            player_trade_data.simple_info.trade_ids = {}
            for _, product_data in pairs(new_product_datas) do
                player_trade_data.product_list[product_data.trade_id] = product_data
                table.insert(player_trade_data.simple_info.trade_ids, product_data.trade_id)
            end
        end
    end

    local trade_logs = Database.loadplayertradelog(context.addr_db_user, context.uid)
    if not trade_logs then
        return false
    end
    player_trade_data.log_list = trade_logs

    return true
end

function Trade.SaveTradeInfoNow()
    local player_trade_data = scripts.UserModel.GetTradeData()
    if not player_trade_data then
        return false
    end

    local success = Database.savetradeinfo(context.addr_db_user, context.uid, player_trade_data.simple_info)
    return success
end

function Trade.LoadTradeInfo()
    local trade_info = Database.loadtradeinfo(context.addr_db_user, context.uid)
    return trade_info
end

function Trade.SearchTradeRecordWitchConditions(condition1, condition2, condition3, condition4, condition5, sort_type, start_idx)
    if not TradeDef.SortDescribe[sort_type] then
        return ErrorCode.SearchProductTypeErr
    end

    local trade_records = Database.gettraderecordswithconditions(context.addr_db_user, condition1, condition2,
        condition3, condition4, condition5, TradeDef.SortDescribe[sort_type], start_idx, MAX_SEARCH_IDS_COUNT)
    if not trade_records then
        return ErrorCode.SearchProductFailed
    end
    if table.size(trade_records) == 0 then
        return ErrorCode.SearchProductNone
    end

    return ErrorCode.None, trade_records
end

function Trade.SearchTradeRecordWithIds(ids, sort_type, start_idx)
    if not TradeDef.SortDescribe[sort_type] then
        return ErrorCode.SearchProductTypeErr
    end
    if start_idx < 0 then
        return ErrorCode.SearchProductStartErr
    end

    local trade_records = Database.gettraderecordwithids(context.addr_db_user, ids, TradeDef.SortDescribe[sort_type])
    if not trade_records then
        return ErrorCode.SearchProductFailed
    end
    moon.debug(string.format("SearchTradeRecordWithIds: %s", json.pretty_encode(trade_records)))
    if table.size(trade_records) == 0 then
        return ErrorCode.SearchProductNone
    end

    return ErrorCode.None, trade_records
end

function Trade.OnTradeTakeDownMail(trade_product, now_state, positive)
    local trade_cfg = GameCfg.TransactionConfig[1]
    if not trade_cfg or not trade_cfg.unsell_email or not trade_cfg.expire_email then
        moon.error(string.format("OnTradeTakeDownMail trade_cfg not found = %s", trade_product))
        return
    end

    if TradeDef.GM_UID[context.uid] then
        -- GM不用处理下架
        return
    end

    local ret = Database.updatetradeproduct(context.addr_db_user, trade_product.trade_id,
        { state = now_state }, { state = TradeDef.StateType.TAKE_DOWNED }, true)
    if ret ~= 1 then
        moon.error(string.format("OnTradeTakeDownMail err = %s", json.pretty_encode(trade_product)))
        return
    end

    -- 发送邮件
    local item_simple_data = ItemDef.newItemSimple()
    item_simple_data.config_id = trade_product.config_id
    item_simple_data.item_count = trade_product.total_num
    local attach_items_simple = {}
    attach_items_simple[trade_product.config_id] = item_simple_data
    
    if positive then
        -- 主动下架
        local mail_ret = scripts.Mail.RecvImmediateMail(trade_cfg.unsell_email, attach_items_simple, {}, {})
        if not mail_ret then
            moon.error(string.format("OnTradeTakeDownMail mail_ret false trade_product = %s",
                json.pretty_encode(trade_product)))
            return
        end
    else
        -- 过期下架
        local mail_ret = scripts.Mail.RecvImmediateMail(trade_cfg.expire_email, attach_items_simple, {}, {})
        if not mail_ret then
            moon.error(string.format("OnTradeTakeDownMail mail_ret false trade_product = %s",
                json.pretty_encode(trade_product)))
            return
        end
    end
end

function Trade.OnTradeLogSaleMail(trade_log, need_save)
    if trade_log.send_mail ~= 0 then
        moon.error(string.format("OnTradeLogSaleMail trade_log.send_mail not 0 trade_log = %s",
        json.pretty_encode(trade_log)))
        return
    end
    
    if TradeDef.GM_UID[trade_log.seller_uid] then
        -- GM不用发送邮件
        return
    end

    local trade_cfg = GameCfg.TransactionConfig[1]
    if not trade_cfg or not trade_cfg.sell_email or not trade_cfg.order_currency then
        moon.error("OnTradeLogSaleMail trade_cfg.sell_email or trade_cfg.order_currency not found = %s")
        return
    end
    local player_trade_data = scripts.UserModel.GetTradeData()
    if not player_trade_data then
        moon.error("OnTradeLogSaleMail not found player_trade_data")
        return
    end

    local add_coins = {}
    add_coins[trade_cfg.order_currency] = {
        coin_id = trade_cfg.order_currency,
        coin_count = trade_log.deal_price * trade_log.deal_num - trade_log.trade_tax,
    }
    -- 发送邮件
    local mail_ret = scripts.Mail.RecvImmediateMail(trade_cfg.sell_email, {}, {}, add_coins)
    if not mail_ret then
        moon.error(string.format("OnTradeLogSaleMail mail_ret false trade_log = %s", json.pretty_encode(trade_log)))
        return
    end
    trade_log.send_mail = 1
    -- 通知Trademgr更改邮件发送记录
    clusterd.send(3999, "trademgr", "Trademgr.UserDealTradeLog", trade_log.log_id)

    -- 修改player_trade_data
    if need_save then
        if player_trade_data.product_list[trade_log.trade_id] then
            local now_num = player_trade_data.product_list[trade_log.trade_id].trade_data.now_num
            if now_num - trade_log.deal_num <= 0 then
                player_trade_data.product_list[trade_log.trade_id] = nil
                for idx, trade_id in pairs(player_trade_data.simple_info.trade_ids) do
                    if trade_id == trade_log.trade_id then
                        table.remove(player_trade_data.simple_info.trade_ids, idx)
                        break
                    end
                end
            else
                player_trade_data.product_list[trade_log.trade_id].trade_data.now_num = now_num - trade_log.deal_num
            end
        end
        table.insert(player_trade_data.log_list, trade_log)
        if table.size(player_trade_data.log_list) > TRADE_LOG_MAX_COUNT then
            table.remove(player_trade_data.log_list, 1)
        end
        Trade.SaveTradeInfoNow()
    end
end

function Trade.OnTradeAddLog(trade_log)
    local player_trade_data = scripts.UserModel.GetTradeData()
    if not player_trade_data then
        return
    end

    -- 修改player_trade_data
    table.insert(player_trade_data.log_list, trade_log)
    if table.size(player_trade_data.log_list) > TRADE_LOG_MAX_COUNT then
        table.remove(player_trade_data.log_list, 1)
    end
    Trade.SaveTradeInfoNow()
end

function Trade.DealOfflineTradeLogSale()
    local trade_logs = Database.gettradelognomail(context.addr_db_user, context.uid)
    if not trade_logs or table.size(trade_logs) == 0 then
        return
    end
    for _, trade_log in pairs(trade_logs) do
        moon.warn(string.format("DealOfflineTradeLogSale trade_log = %s", json.pretty_encode(trade_log)))
        Trade.OnTradeLogSaleMail(trade_log, false)
    end
end

function Trade.DealOfflineTradeTakeDown()
    local where_data = {
        seller_uid = context.uid,
        state = TradeDef.StateType.TAKE_DOWNING,
    }
    local trade_products = Database.gettradeproduct(context.addr_db_user, where_data, MAX_SEARCH_IDS_COUNT)
    if not trade_products then
        return
    end
    if table.size(trade_products) == 0 then
        return
    end

    for _, trade_product in pairs(trade_products) do
        moon.warn(string.format("DealOfflineTradeTakeDown trade_product = %s", json.pretty_encode(trade_product)))
        Trade.OnTradeTakeDownMail(trade_product, TradeDef.StateType.TAKE_DOWNING, false)
    end
end

function Trade.CheckOnSaleCnt(player_trade_data)
    local now_ts = moon.time()
    local trade_cfg = GameCfg.TransactionConfig[1]
    if trade_cfg and trade_cfg.account_market and trade_cfg.refresh_time then
        if not datetime.is_same_day(player_trade_data.simple_info.update_ts, now_ts - trade_cfg.refresh_time) then
            player_trade_data.simple_info.can_onsale_cnt = trade_cfg.account_market
            player_trade_data.simple_info.update_ts = moon.time()
            Trade.SaveTradeInfoNow()
        end
    end
end

function Trade.PBGetTradeInfoReqCmd(req)
    local player_trade_data = scripts.UserModel.GetTradeData()
    if not player_trade_data then
        return context.S2C(context.net_id, CmdCode["PBGetTradeInfoRspCmd"],
            { code = ErrorCode.ServerInternalError, error = "数据加载出错", uid = context.uid }, req.msg_context.stub_id)
    end
    Trade.CheckOnSaleCnt(player_trade_data)

    local rsp = {
        code = ErrorCode.None,
        error = "",
        uid = context.uid,
        self_trade_info = player_trade_data
    }
    return context.S2C(context.net_id, CmdCode["PBGetTradeInfoRspCmd"], rsp, req.msg_context.stub_id)
end

function Trade.PBTradeSaleReqCmd(req)
    -- 参数验证
    if not req.msg.config_id
        or not req.msg.pos
        or not req.msg.sale_num
        or not req.msg.single_price
        or not req.msg.sale_ts then
        return context.S2C(context.net_id, CmdCode.PBTradeSaleRspCmd, {
            code = ErrorCode.ParamInvalid,
            error = "无效请求参数",
            uid = context.uid,
        }, req.msg_context.stub_id)
    end

    local player_trade_data = scripts.UserModel.GetTradeData()
    if not player_trade_data then
        return context.S2C(context.net_id, CmdCode["PBTradeSaleRspCmd"],
            { code = ErrorCode.ServerInternalError, error = "数据加载出错", uid = context.uid }, req.msg_context.stub_id)
    end
    Trade.CheckOnSaleCnt(player_trade_data)

    local is_gm = false
    if TradeDef.GM_UID[context.uid] then
        is_gm = true
    end

    local item_conf = GameCfg.Item[req.msg.config_id]
    if not item_conf then
        return context.S2C(context.net_id, CmdCode["PBTradeSaleRspCmd"],
            { code = ErrorCode.ConfigError, error = "物品配置不存在", uid = context.uid }, req.msg_context.stub_id)
    end
    if not item_conf.could_sell or item_conf.could_sell ~= 1 then
        return context.S2C(context.net_id, CmdCode["PBTradeSaleRspCmd"],
            { code = ErrorCode.TradeItemNotAllowed, error = "物品不允许交易", uid = context.uid }, req.msg_context.stub_id)
    end

    local trade_cfg = GameCfg.TransactionConfig[1]
    if not trade_cfg
        or not trade_cfg.service_charge_type
        or not trade_cfg.order_percentage
        or not trade_cfg.order_time
        or not trade_cfg.order_time[req.msg.sale_ts] then
        return context.S2C(context.net_id, CmdCode["PBTradeSaleRspCmd"],
            { code = ErrorCode.ConfigError, error = "交易上架费用配置不存在", uid = context.uid }, req.msg_context.stub_id)
    end

    if player_trade_data.simple_info.box_capacity + 1 > MAX_SALE_CAPACITY
        and not is_gm then
        return context.S2C(context.net_id, CmdCode["PBTradeSaleRspCmd"],
            { code = ErrorCode.TradeCapacityNotEnough, error = "交易容量不足", uid = context.uid }, req.msg_context.stub_id)
    end

    if player_trade_data.simple_info.can_onsale_cnt <= 0
        and not is_gm then
        return context.S2C(context.net_id, CmdCode["PBTradeSaleRspCmd"],
            { code = ErrorCode.TradeCntNotEnough, error = "交易次数不足", uid = context.uid }, req.msg_context.stub_id)
    end

    local errcode, item_data = scripts.Bag.GetOneItemData(BagDef.BagType.Cangku, req.msg.pos)
    if errcode ~= ErrorCode.None
        or not item_data
        or item_data.common_info.config_id ~= req.msg.config_id then
        return context.S2C(context.net_id, CmdCode["PBTradeSaleRspCmd"],
            { code = ErrorCode.ItemNotExist, error = "物品不存在", uid = context.uid }, req.msg_context.stub_id)
    end

    if item_data.common_info.item_count < req.msg.sale_num
        and not is_gm then
        moon.error(string.format("Trade.PBTradeSaleRspCmd item_data:%s", json.pretty_encode(item_data)))
        moon.error(string.format("Trade.PBTradeSaleRspCmd req.msg:%s", json.pretty_encode(req.msg)))
        return context.S2C(context.net_id, CmdCode["PBTradeSaleRspCmd"],
            { code = ErrorCode.ItemNotEnough, error = "物品数量不足", uid = context.uid }, req.msg_context.stub_id)
    end

    if item_data.common_info.trade_cnt == 0
        and not is_gm then
        return context.S2C(context.net_id, CmdCode["PBTradeSaleRspCmd"],
            { code = ErrorCode.TradeCntNotEnough, error = "交易次数不足", uid = context.uid }, req.msg_context.stub_id)
    end

    local bag_change_log = {}
    local trade_cost_items = {}
    trade_cost_items[req.msg.pos] = {
        config_id = item_data.common_info.config_id,
        uniqid = 0,
        item_count = -req.msg.sale_num,
    }
    -- 扣除上架费用
    local trade_cost_coins = {}
    trade_cost_coins[trade_cfg.service_charge_type] = {
        coin_id = trade_cfg.service_charge_type,
        coin_count = -trade_cfg.order_time[req.msg.sale_ts],
    }
    -- 向上取整trade_rate_coin_count
    local trade_rate_coin_count = math.ceil((trade_cfg.order_percentage * req.msg.sale_num * req.msg.single_price) /
        10000)
    trade_cost_coins[trade_cfg.service_charge_type].coin_count = trade_cost_coins[trade_cfg.service_charge_type]
        .coin_count - trade_rate_coin_count
    
    local err_code = ErrorCode.None
    if not is_gm then
        err_code = scripts.Bag.CheckItemsEnoughPos(BagDef.BagType.Cangku, trade_cost_items)
        if err_code ~= ErrorCode.None then
            return context.S2C(context.net_id, CmdCode["PBTradeSaleRspCmd"],
                { code = err_code, error = "物品数量不足", uid = context.uid }, req.msg_context.stub_id)
        end
        err_code = scripts.Bag.CheckCoinsEnough(trade_cost_coins)
        if err_code ~= ErrorCode.None then
            return context.S2C(context.net_id, CmdCode["PBTradeSaleRspCmd"],
                { code = err_code, error = "上架费用不足", uid = context.uid }, req.msg_context.stub_id)
        end

        err_code = scripts.Bag.DelItemsPos(BagDef.BagType.Cangku, trade_cost_items, bag_change_log)
        if err_code ~= ErrorCode.None then
            scripts.Bag.RollBackWithChange(bag_change_log)
            return context.S2C(context.net_id, CmdCode["PBTradeSaleRspCmd"],
                { code = err_code, error = "物品数量不足", uid = context.uid }, req.msg_context.stub_id)
        end
        err_code = scripts.Bag.DealCoins(trade_cost_coins, bag_change_log)
        if err_code ~= ErrorCode.None then
            scripts.Bag.RollBackWithChange(bag_change_log)
            return context.S2C(context.net_id, CmdCode["PBTradeSaleRspCmd"],
                { code = err_code, error = "上架费用不足", uid = context.uid }, req.msg_context.stub_id)
        end
    end

    -- item_data.common_info.item_count = req.msg.sale_num
    local product_data = TradeDef.newTradeProductBaseData()
    product_data.trade_id = 1
    product_data.seller_uid = context.uid
    product_data.config_id = item_data.common_info.config_id
    product_data.total_num = req.msg.sale_num
    product_data.beg_ts = moon.time()
    product_data.end_ts = moon.time() + req.msg.sale_ts
    product_data.state = TradeDef.StateType.ON_SALE
    product_data.trade_data.single_price = req.msg.single_price
    product_data.trade_data.sale_num = 0
    product_data.trade_data.now_num = req.msg.sale_num

    local sale_data = {
        uid = context.uid,
        product_data = product_data,
        condition1 = 0,
        condition2 = 0,
        condition3 = 0,
        condition4 = 0,
        condition5 = 0,
    }
    if table.size(item_conf.market) >= 1 then
        sale_data.condition1 = item_conf.market[1]
    end
    if table.size(item_conf.market) >= 2 then
        sale_data.condition2 = item_conf.market[2]
    end
    if table.size(item_conf.market) >= 3 then
        sale_data.condition3 = item_conf.market[3]
    end
    if table.size(item_conf.market) >= 4 then
        sale_data.condition4 = item_conf.market[4]
    end
    if table.size(item_conf.market) >= 5 then
        sale_data.condition5 = item_conf.market[5]
    end
    local res, err = clusterd.call(3999, "trademgr", "Trademgr.AddTradeProduct", sale_data)
    if err then
        moon.error("Trade.PBTradeSaleReqCmd Trademgr.AddTradeProduct err:%s", err)
        if not is_gm then
            scripts.Bag.RollBackWithChange(bag_change_log)
        end
        return context.S2C(context.net_id, CmdCode["PBTradeSaleRspCmd"],
            { code = ErrorCode.SaleProductErr, error = "寄售商品出错", uid = context.uid }, req.msg_context.stub_id)
    else
        if res <= 0 then
            if not is_gm then
                scripts.Bag.RollBackWithChange(bag_change_log)
            end
            return context.S2C(context.net_id, CmdCode["PBTradeSaleRspCmd"],
                { code = ErrorCode.SaleProductErr, error = "寄售商品出错", uid = context.uid }, req.msg_context.stub_id)
        end

        product_data.trade_id = res
        player_trade_data.product_list[product_data.trade_id] = product_data
        player_trade_data.simple_info.can_onsale_cnt = player_trade_data.simple_info.can_onsale_cnt - 1
        table.insert(player_trade_data.simple_info.trade_ids, product_data.trade_id)
    end

    if not is_gm then
        scripts.Bag.SaveAndLog(bag_change_log, ItemDef.ChangeReason.TradeSale)
    end
    Trade.SaveTradeInfoNow()

    return context.S2C(context.net_id, CmdCode["PBTradeSaleRspCmd"],
        { code = ErrorCode.None, error = "寄售商品成功", uid = context.uid, trade_id = product_data.trade_id },
        req.msg_context.stub_id)
end

function Trade.PBSearchTradeProductReqCmd(req)
    -- 参数验证
    if not req.msg.sort_type
        or not req.msg.start_idx then
        return context.S2C(context.net_id, CmdCode.PBSearchTradeProductRspCmd, {
            code = ErrorCode.ParamInvalid,
            error = "无效请求参数",
            uid = context.uid,
        }, req.msg_context.stub_id)
    end

    local player_trade_data = scripts.UserModel.GetTradeData()
    if not player_trade_data then
        return context.S2C(context.net_id, CmdCode["PBSearchTradeProductRspCmd"],
            { code = ErrorCode.ServerInternalError, error = "数据加载出错", uid = context.uid }, req.msg_context.stub_id)
    end

    if req.msg.config_ids and table.size(req.msg.config_ids) > 0 then
        local trade_cfg = GameCfg.TransactionConfig[1]
        local max_search_num = MAX_SEARCH_IDS_COUNT
        if trade_cfg and trade_cfg.collection_num and trade_cfg.collection_num > max_search_num then
            max_search_num = trade_cfg.collection_num
        end
        if table.size(req.msg.config_ids) > max_search_num then
            return context.S2C(context.net_id, CmdCode.PBSearchTradeProductRspCmd, {
                code = ErrorCode.SearchIdsOverflow,
                error = "搜索商品数量超过最大数量",
                uid = context.uid,
            }, req.msg_context.stub_id)
        end

        local errcode, trade_records = Trade.SearchTradeRecordWithIds(req.msg.config_ids, req.msg.sort_type,
            req.msg.start_idx)
        if errcode ~= ErrorCode.None then
            return context.S2C(context.net_id, CmdCode.PBSearchTradeProductRspCmd, {
                code = errcode,
                error = "搜索商品出错",
                uid = context.uid,
            }, req.msg_context.stub_id)
        end

        return context.S2C(context.net_id, CmdCode.PBSearchTradeProductRspCmd, {
            code = ErrorCode.None,
            error = "搜索商品成功",
            uid = context.uid,
            search_products = trade_records,
        }, req.msg_context.stub_id)
    else
        if not req.msg.condition1 and not req.msg.condition2 and not req.msg.condition3
            and not req.msg.condition4 and not req.msg.condition5 then
            return context.S2C(context.net_id, CmdCode.PBSearchTradeProductRspCmd, {
                code = ErrorCode.SearchParamsInvalid,
                error = "无效请求参数",
                uid = context.uid,
            }, req.msg_context.stub_id)
        end

        local errcode, trade_records = Trade.SearchTradeRecordWitchConditions(req.msg.condition1, req.msg.condition2,
            req.msg.condition3, req.msg.condition4, req.msg.condition5, req.msg.sort_type, req.msg.start_idx)
        if errcode ~= ErrorCode.None then
            return context.S2C(context.net_id, CmdCode.PBSearchTradeProductRspCmd, {
                code = errcode,
                error = "搜索商品出错",
                uid = context.uid,
            }, req.msg_context.stub_id)
        end


        return context.S2C(context.net_id, CmdCode.PBSearchTradeProductRspCmd, {
            code = ErrorCode.None,
            error = "搜索商品成功",
            uid = context.uid,
            search_products = trade_records,
        }, req.msg_context.stub_id)
    end
end

function Trade.PBGetSingleTradeRecordReqCmd(req)
    -- 参数验证
    if not req.msg.config_id then
        return context.S2C(context.net_id, CmdCode.PBGetSingleTradeRecordRspCmd, {
            code = ErrorCode.ParamInvalid,
            error = "无效请求参数",
            uid = context.uid,
        }, req.msg_context.stub_id)
    end

    local res, err = clusterd.call(3999, "trademgr", "Trademgr.GetTradeRecordInfo", req.msg.config_id)
    if err then
        moon.error(string.format("Trade.PBGetSingleTradeRecordReqCmd Trademgr.GetTradeRecordInfo err:%s", err))
        return context.S2C(context.net_id, CmdCode.PBGetSingleTradeRecordRspCmd, {
            code = ErrorCode.SearchProductFailed,
            error = "搜索商品出错",
            uid = context.uid,
        }, req.msg_context.stub_id)
    end
    if not res then
        return context.S2C(context.net_id, CmdCode.PBGetSingleTradeRecordRspCmd, {
            code = ErrorCode.SearchProductFailed,
            error = "搜索商品出错",
            uid = context.uid,
        }, req.msg_context.stub_id)
    end

    moon.debug(string.format("Trade.PBGetSingleTradeRecordReqCmd res:%s", json.pretty_encode(res)))
    -- local record = {
    --     trade_sim_data = TradeDef.newTradeSearchSimpleData(),
    --     price_to_num = {},
    -- }
    -- record.trade_sim_data.config_id = res.trade_config_id
    -- record.trade_sim_data.min_price = res.min_price
    -- record.trade_sim_data.last_deal_price = res.last_deal_price
    -- record.trade_sim_data.yes_average_price = res.yes_average_price
    -- record.trade_sim_data.min_price_num = res.min_price_num
    -- if res.price_to_num and table.size(res.price_to_num) > 0 then
    --     for price, price_num_data in pairs(res.price_to_num) do
    --         local price_and_num = {
    --             price = price,
    --             now_num = price_num_data.now_num,
    --         }
    --         record.price_to_num[price] = price_and_num
    --     end
    -- end

    return context.S2C(context.net_id, CmdCode.PBGetSingleTradeRecordRspCmd, {
        code = ErrorCode.None,
        error = "搜索商品成功",
        uid = context.uid,
        trade_record = res,
    }, req.msg_context.stub_id)
end

function Trade.PBTradeBuyReqCmd(req)
    -- 参数验证
    if not req.msg.config_id
        or not req.msg.buy_num
        or not req.msg.buy_max_price then
        return context.S2C(context.net_id, CmdCode.PBTradeBuyRspCmd, {
            code = ErrorCode.ParamInvalid,
            error = "无效请求参数",
            uid = context.uid,
        }, req.msg_context.stub_id)
    end

    local trade_cfg = GameCfg.TransactionConfig[1]
    if not trade_cfg or not trade_cfg.shipments_email then
        moon.error("PBTradeBuyReqCmd trade_cfg.shipments_email not found")
        return context.S2C(context.net_id, CmdCode.PBTradeBuyRspCmd, {
            code = ErrorCode.MailConfigError,
            error = "邮件参数错误",
            uid = context.uid,
        }, req.msg_context.stub_id)
    end

    if not trade_cfg.order_currency then
        return context.S2C(context.net_id, CmdCode.PBTradeBuyRspCmd, {
            code = ErrorCode.CoinNotEnough,
            error = "货币不足",
            uid = context.uid,
        }, req.msg_context.stub_id)
    end
    -- 校验玩家身上货币是否足够
    local coin_count = scripts.Bag.GetCoinCount(trade_cfg.order_currency)
    if coin_count <= 0 then
        return context.S2C(context.net_id, CmdCode.PBTradeBuyRspCmd, {
            code = ErrorCode.CoinNotEnough,
            error = "货币不足",
            uid = context.uid,
        }, req.msg_context.stub_id)
    end
    local lock_coin_count = math.min(coin_count, req.msg.buy_num * req.msg.buy_max_price)

    local cost_coins = {}
    cost_coins[trade_cfg.order_currency] = {
        coin_id = trade_cfg.order_currency,
        coin_count = -lock_coin_count,
    }
    local err_code_coins = scripts.Bag.CheckCoinsEnough(cost_coins)
    if err_code_coins ~= ErrorCode.None then
        return err_code_coins
    end
    local bag_change_logs = {}
    err_code_coins = scripts.Bag.DealCoins(cost_coins, bag_change_logs)
    if err_code_coins ~= ErrorCode.None then
        scripts.Bag.RollBackWithChange(bag_change_logs)
        return err_code_coins
    end

    local res, err = clusterd.call(3999, "trademgr", "Trademgr.BuyTradeProduct", context.uid, req.msg.config_id,
        req.msg.buy_num, req.msg.buy_max_price, lock_coin_count)
    if err or not res then
        moon.error(string.format("Trade.PBTradeBuyReqCmd Trademgr.BuyTradeProduct err:%s", err))
        scripts.Bag.RollBackWithChange(bag_change_logs)
        return context.S2C(context.net_id, CmdCode.PBTradeBuyRspCmd, {
            code = ErrorCode.TradeBuyError,
            error = "购买商品出错",
            uid = context.uid,
        }, req.msg_context.stub_id)
    end
    moon.debug(string.format("Trade.PBTradeBuyReqCmd Trademgr.BuyTradeProduct res:%s", json.pretty_encode(res)))
    if res.code ~= ErrorCode.None then
        scripts.Bag.RollBackWithChange(bag_change_logs)
        return context.S2C(context.net_id, CmdCode.PBTradeBuyRspCmd, {
            code = res.code,
            error = "购买商品出错",
            uid = context.uid,
        }, req.msg_context.stub_id)
    end

    if res.data.remain_coin and res.data.remain_coin > 0 then
        scripts.Bag.RollBackWithChange(bag_change_logs)
        -- 重新确定扣除的正确金额
        bag_change_logs = {}
        cost_coins[trade_cfg.order_currency].coin_count = cost_coins[trade_cfg.order_currency].coin_count +
            res.data.remain_coin
    end

    local is_gm = false
    if TradeDef.GM_UID[context.uid] then
        is_gm = true
    end

    if not is_gm then
        local add_list = {}
        add_list[req.msg.config_id] = {
            id = req.msg.config_id,
            count = res.data.total_real_buy_num,
            pos = 0,
        }
        local bag_code = scripts.Bag.CheckEmptyEnough(BagDef.BagType.Cangku, add_list, 0)
        if bag_code == ErrorCode.None then
            local stack_items, unstack_items = {}, {}
            local ok = ItemDefine.GetItemDataFromIdCount(add_list, {}, stack_items, unstack_items, cost_coins)
            if not ok then
                scripts.Bag.RollBackWithChange(bag_change_logs)
                moon.error(string.format("PBTradeBuyReqCmd GetItemDataFromIdCount err:\n%s", json.pretty_encode(add_list)))
                return
            end

            -- 添加道具前先扣除花费
            -- scripts.Bag.SaveAndLog(bag_change_logs, ItemDef.ChangeReason.TradeBuyCost)
            err_code_coins = scripts.Bag.DealCoins(cost_coins, bag_change_logs)
            if err_code_coins ~= ErrorCode.None then
                moon.error("Trade.PBTradeBuyReqCmd DealCoins err", err_code_coins)
                scripts.Bag.RollBackWithChange(bag_change_logs)
                return err_code_coins
            end

            -- 添加道具
            if table.size(stack_items) + table.size(unstack_items) > 0 then
                bag_code = scripts.Bag.AddItems(BagDef.BagType.Cangku, stack_items, unstack_items, bag_change_logs)
                if bag_code ~= ErrorCode.None then
                    scripts.Bag.RollBackWithChange(bag_change_logs)
                    moon.error(string.format("PBTradeBuyReqCmd AddItems stack_items err:\n%s",
                        json.pretty_encode(stack_items)))
                    moon.error(string.format("PBTradeBuyReqCmd AddItems unstack_items err:\n%s",
                        json.pretty_encode(unstack_items)))
                    return
                end
            end

            scripts.Bag.SaveAndLog(bag_change_logs, ItemDef.ChangeReason.TradeBuy)
        else
            -- 计算获得资源发送邮件
            local item_simple_data = ItemDef.newItemSimple()
            item_simple_data.config_id = req.msg.config_id
            item_simple_data.item_count = res.data.total_real_buy_num
            local attach_items_simple = {}
            attach_items_simple[req.msg.config_id] = item_simple_data

            local mail_ret = scripts.Mail.RecvImmediateMail(trade_cfg.shipments_email, attach_items_simple, {}, {})
            if not mail_ret then
                moon.error("Trade.PBTradeBuyReqCmd RecvImmediateMail err")
                scripts.Bag.RollBackWithChange(bag_change_logs)
                return context.S2C(context.net_id, CmdCode.PBTradeBuyRspCmd, {
                    code = ErrorCode.MailConfigError,
                    error = "购买商品邮件出错",
                    uid = context.uid,
                }, req.msg_context.stub_id)
            end

            -- 扣除花费
            err_code_coins = scripts.Bag.DealCoins(cost_coins, bag_change_logs)
            if err_code_coins ~= ErrorCode.None then
                moon.error("Trade.PBTradeBuyReqCmd DealCoins err", err_code_coins)
                scripts.Bag.RollBackWithChange(bag_change_logs)
                return err_code_coins
            end
            scripts.Bag.SaveAndLog(bag_change_logs, ItemDef.ChangeReason.TradeBuy)
        end
    end

    local msg_ret = {
        code = ErrorCode.None,
        error = "购买商品成功",
        uid = context.uid,
        buy_num = res.data.total_real_buy_num,
        buy_total_price = lock_coin_count - res.data.remain_coin,
    }
    moon.debug(string.format("Trade.PBTradeBuyReqCmd msg_ret:%s", json.pretty_encode(msg_ret)))
    return context.S2C(context.net_id, CmdCode.PBTradeBuyRspCmd, {
        code = ErrorCode.None,
        error = "购买商品成功",
        uid = context.uid,
        buy_num = res.data.total_real_buy_num,
        buy_total_price = lock_coin_count - res.data.remain_coin,
    }, req.msg_context.stub_id)
end

function Trade.PBTradeTakeOffProductReqCmd(req)
    -- 参数验证
    if not req.msg.trade_id then
        return context.S2C(context.net_id, CmdCode.PBTradeTakeOffProductRspCmd, {
            code = ErrorCode.ParamInvalid,
            error = "无效请求参数",
            uid = context.uid,
        }, req.msg_context.stub_id)
    end

    local player_trade_data = scripts.UserModel.GetTradeData()
    if not player_trade_data then
        return context.S2C(context.net_id, CmdCode.PBTradeTakeOffProductRspCmd,
            { code = ErrorCode.ServerInternalError, error = "数据加载出错", uid = context.uid }, req.msg_context.stub_id)
    end
    if not player_trade_data.product_list[req.msg.trade_id] then
        return context.S2C(context.net_id, CmdCode.PBTradeTakeOffProductRspCmd, {
            code = ErrorCode.TradeProductNotExist,
            error = "商品不存在",
            uid = context.uid,
            trade_id = req.msg.trade_id,
        }, req.msg_context.stub_id)
    end

    local res, err = clusterd.call(3999, "trademgr", "Trademgr.TakeOffProduct", context.uid, req.msg.trade_id)
    if err or res ~= ErrorCode.None then
        moon.error(string.format("Trade.PBTradeTakeOffProductReqCmd Trademgr.TakeOffProduct err:%s", err))
        return context.S2C(context.net_id, CmdCode.PBTradeTakeOffProductRspCmd, {
            code = ErrorCode.TradeTakeOffError,
            error = "下架商品出错",
            uid = context.uid,
            trade_id = req.msg.trade_id,
        }, req.msg_context.stub_id)
    end

    player_trade_data.product_list[req.msg.trade_id] = nil
    for idx, trade_id in ipairs(player_trade_data.simple_info.trade_ids) do
        if trade_id == req.msg.trade_id then
            table.remove(player_trade_data.simple_info.trade_ids, idx)
            break
        end
    end
    Trade.SaveTradeInfoNow()

    return context.S2C(context.net_id, CmdCode.PBTradeTakeOffProductRspCmd, {
        code = res,
        error = "",
        uid = context.uid,
        trade_id = req.msg.trade_id,
    }, req.msg_context.stub_id)
end

function Trade.PBTradeChangeFocusIdReqCmd(req)
    -- 参数验证
    if not req.msg.focus_op
        or not req.msg.focus_id then
        return context.S2C(context.net_id, CmdCode.PBTradeChangeFocusIdRspCmd, {
            code = ErrorCode.ParamInvalid,
            error = "无效请求参数",
            uid = context.uid,
        }, req.msg_context.stub_id)
    end

    local player_trade_data = scripts.UserModel.GetTradeData()
    if not player_trade_data then
        return context.S2C(context.net_id, CmdCode.PBTradeChangeFocusIdRspCmd,
            { code = ErrorCode.ServerInternalError, error = "数据加载出错", uid = context.uid }, req.msg_context.stub_id)
    end

    if req.msg.focus_op == 0 then
        player_trade_data.simple_info.focus_id_ts[req.msg.focus_id] = nil
    else
        local max_focus_num = 0
        local trade_cfg = GameCfg.TransactionConfig[1]
        if trade_cfg and trade_cfg.collection_num and trade_cfg.collection_num > max_focus_num then
            max_focus_num = trade_cfg.collection_num
        end
        if table.size(player_trade_data.simple_info.focus_id_ts) >= max_focus_num then
            return context.S2C(context.net_id, CmdCode.PBTradeChangeFocusIdRspCmd, {
                code = ErrorCode.FocusIdOverflow,
                error = "关注商品数量超过最大数量",
                uid = context.uid,
            }, req.msg_context.stub_id)
        end
        player_trade_data.simple_info.focus_id_ts[req.msg.focus_id] = moon.time()
    end
    Trade.SaveTradeInfoNow()

    return context.S2C(context.net_id, CmdCode.PBTradeChangeFocusIdRspCmd, {
        code = ErrorCode.None,
        error = "更改关注商品",
        uid = context.uid,
        focus_id_ts = player_trade_data.simple_info.focus_id_ts,
    }, req.msg_context.stub_id)
end

function Trade.PBTradeGetAllYesAveragePriceReqCmd(req)
    -- 参数验证
    if not req.msg.uid then
        return context.S2C(context.net_id, CmdCode.PBTradeGetAllYesAveragePriceRspCmd, {
            code = ErrorCode.ParamInvalid,
            error = "无效请求参数",
            uid = context.uid,
        }, req.msg_context.stub_id)
    end

    local start_config_id = 0
    local id_price_list = {}
    while true do
        local records = Database.gettraderecordaveragepriceseq(context.addr_db_user, start_config_id, 1000)
        if not records or table.size(records) <= 0 then
            moon.error("Trademgr.Start gettraderecordaveragepriceseq failed", start_config_id, 1000)
            break
        end
        for id, price in pairs(records) do
            if id > start_config_id then
                start_config_id = id
            end
            id_price_list[id] = price
        end

        if table.size(records) < 1000 then
            break
        end
    end

    return context.S2C(context.net_id, CmdCode.PBTradeGetAllYesAveragePriceRspCmd, {
        code = ErrorCode.None,
        error = "获取所有商品平均价格成功",
        uid = context.uid,
        yes_average_price = id_price_list,
    }, req.msg_context.stub_id)
end

return Trade