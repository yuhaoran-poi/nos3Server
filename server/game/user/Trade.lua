local moon = require "moon"
local common = require "common"
local clusterd = require("cluster")
local GameCfg = common.GameCfg
local ErrorCode = common.ErrorCode
local CmdCode = common.CmdCode
local Database = common.Database
local TradeDef = require("common.def.TradeDef")
local BagDef = require("common.def.BagDef")
local ItemDef = require("common.def.ItemDef")

---@type user_context
local context = ...
local scripts = context.scripts

local MAX_SALE_CAPACITY = 50
local MAX_SEARCH_IDS_COUNT = 10

---@class Trade
local Trade = {}

function Trade.Init()
    -- local trade_info = Trade.LoadTradeInfo()
    -- if trade_info then
    --     local trade_data = TradeDef.newSelfTradeData()
    --     trade_data.simple_info = trade_info
    --     scripts.UserModel.SetTradeData(trade_data)
    -- end

    -- local trade_data = scripts.UserModel.GetTradeData()
    -- if not trade_data then
    --     trade_data = TradeDef.newSelfTradeData()
    --     trade_data.simple_info.box_capacity = 10
    --     scripts.UserModel.SetTradeData(trade_data)
    -- end
end

function Trade.Start()
    -- local trade_data = scripts.UserModel.GetTradeData()
    -- if not trade_data then
    --     return
    -- end

    -- Trade.SaveTradeInfoNow()
end

function Trade.CheckData()
    local trade_data = scripts.UserModel.GetTradeData()
    if not trade_data then
        return false
    end

    local new_product_datas = Database.RedisGetProductData(context.addr_db_redis, trade_data.simple_info.trade_ids)
    if not new_product_datas then
        return false
    end
    trade_data.simple_info.trade_ids = {}
    for _, product_data in pairs(new_product_datas) do
        trade_data.product_datas[product_data.trade_id] = product_data
        table.insert(trade_data.simple_info.trade_ids, product_data.trade_id)
    end

    local trade_logs = Database.loadplayertradelog(context.addr_db_user, context.uid)
    if not trade_logs then
        return false
    end
    trade_data.log_list = trade_logs

    return true
end

function Trade.SaveTradeInfoNow()
    local trade_data = scripts.UserModel.GetTradeData()
    if not trade_data then
        return false
    end

    local success = Database.savetradeinfo(context.addr_db_user, context.uid, trade_data.simple_info)
    return success
end

function Trade.LoadTradeInfo()
    local trade_info = Database.loadtradeinfo(context.addr_db_user, context.uid)
    return trade_info
end

function Trade.SearchTradeProductWithIds(ids, sort_type, start_idx)
    if not TradeDef.SortDescribe[sort_type] then
        return ErrorCode.SearchProductTypeErr
    end
    if start_idx < 0 then
        return ErrorCode.SearchProductStartErr
    end

    local trade_record_ids = Database.gettraderecordwithids(context.addr_db_user, ids, TradeDef.SortDescribe[sort_type])
    if not trade_record_ids then
        return ErrorCode.SearchProductFailed
    end
    if table.size(trade_record_ids) == 0 then
        return ErrorCode.SearchProductNone
    end

    -- 向Trademgr请求商品类目详情
end

function Trade.PBGetTradeInfoReqCmd(req)
    local trade_data = scripts.UserModel.GetTradeData()
    if not trade_data then
        return context.S2C(context.net_id, CmdCode["PBGetTradeInfoRspCmd"],
            { code = ErrorCode.ServerInternalError, error = "数据加载出错", uid = context.uid }, req.msg_context.stub_id)
    end

    local rsp = {
        code = ErrorCode.None,
        error = "",
        uid = context.uid,
        self_trade_info = trade_data
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

    local trade_data = scripts.UserModel.GetTradeData()
    if not trade_data then
        return context.S2C(context.net_id, CmdCode["PBTradeSaleRspCmd"],
            { code = ErrorCode.ServerInternalError, error = "数据加载出错", uid = context.uid }, req.msg_context.stub_id)
    end

    local item_conf = GameCfg.Item[req.msg.config_id]
    if not item_conf then
        return context.S2C(context.net_id, CmdCode["PBTradeSaleRspCmd"],
            { code = ErrorCode.ConfigError, error = "物品配置不存在", uid = context.uid }, req.msg_context.stub_id)
    end

    if trade_data.simple_info.box_capacity + 1 > MAX_SALE_CAPACITY then
        return context.S2C(context.net_id, CmdCode["PBTradeSaleRspCmd"],
            { code = ErrorCode.TradeCapacityNotEnough, error = "交易容量不足", uid = context.uid }, req.msg_context.stub_id)
    end

    local errcode, item_data = scripts.Bag.GetOneItemData(BagDef.BagType.Cangku, req.msg.pos)
    if errcode ~= ErrorCode.None
        or item_data.common_info.config_id ~= req.msg.config_id then
        return context.S2C(context.net_id, CmdCode["PBTradeSaleRspCmd"],
            { code = ErrorCode.ItemNotExist, error = "物品不存在", uid = context.uid }, req.msg_context.stub_id)
    end

    if item_data.common_info.item_count < req.msg.sale_num then
        return context.S2C(context.net_id, CmdCode["PBTradeSaleRspCmd"],
            { code = ErrorCode.ItemNotEnough, error = "物品数量不足", uid = context.uid }, req.msg_context.stub_id)
    end

    if item_data.common_info.trade_cnt == 0 then
        return context.S2C(context.net_id, CmdCode["PBTradeSaleRspCmd"],
            { code = ErrorCode.TradeCapacityNotEnough, error = "交易次数不足", uid = context.uid }, req.msg_context.stub_id)
    end

    -- 扣除道具消耗
    local trade_cost = {}
    local change_log = {}
    trade_cost[item_data.common_info.config_id] = {
        id = item_data.common_info.config_id,
        count = -req.msg.sale_num,
        pos = req.msg.pos,
    }
    local err_code = scripts.Bag.CheckItemsEnough(BagDef.BagType.Cangku, trade_cost, {})
    if err_code ~= ErrorCode.None then
        return context.S2C(context.net_id, CmdCode["PBTradeSaleRspCmd"],
            { code = ErrorCode.ItemNotEnough, error = "物品数量不足", uid = context.uid }, req.msg_context.stub_id)
    end
    err_code = scripts.Bag.DelItems(BagDef.BagType.Cangku, trade_cost, {}, change_log)
    if err_code ~= ErrorCode.None then
        scripts.Bag.RollBackWithChange(change_log)
        return context.S2C(context.net_id, CmdCode["PBTradeSaleRspCmd"],
            { code = err_code, error = "物品数量不足", uid = context.uid }, req.msg_context.stub_id)
    end

    item_data.common_info.item_count = req.msg.sale_num
    local product_data = {
        trade_id = 1,
        seller_uid = context.uid,
        item_data = item_data,
        beg_ts = moon.time(),
        end_ts = moon.time() + req.msg.sale_ts,
        state = TradeDef.TradeState.ON_SALE,
        trade_data = {
            single_price = req.msg.single_price,
            sale_num = req.msg.sale_num,
        },
    }
    local sale_data = {
        uid = context.uid,
        product_data = product_data,
        condition1 = item_conf.type1,
        condition2 = item_conf.type2,
        condition3 = item_conf.type3,
        condition4 = item_conf.type4,
        condition5 = item_conf.type5,
    }
    local res, err = clusterd.call(3999, "trademgr", "Trademgr.AddTradeProduct", sale_data)
    if err then
        moon.error("Trade.PBTradeSaleReqCmd Trademgr.AddTradeProduct err:%s", err)
        scripts.Bag.RollBackWithChange(change_log)
        return context.S2C(context.net_id, CmdCode["PBTradeSaleRspCmd"],
            { code = ErrorCode.SaleProductErr, error = "寄售商品出错", uid = context.uid }, req.msg_context.stub_id)
    else
        if res <= 0 then
            scripts.Bag.RollBackWithChange(change_log)
            return context.S2C(context.net_id, CmdCode["PBTradeSaleRspCmd"],
                { code = ErrorCode.SaleProductErr, error = "寄售商品出错", uid = context.uid }, req.msg_context.stub_id)
        end

        product_data.trade_id = res
        trade_data.product_datas[product_data.trade_id] = product_data
        table.insert(trade_data.simple_info.trade_ids, product_data.trade_id)
    end

    -- local save_bags = {}
    -- for bagType, _ in pairs(change_log) do
    --     save_bags[bagType] = 1
    -- end
    -- scripts.Bag.SaveAndLog(save_bags, change_log)
    scripts.Bag.SaveAndLog(change_log, ItemDef.ChangeReason.TradeSale)

    scripts.UserModel.SaveTradeData(trade_data)

    return context.S2C(context.net_id, CmdCode["PBTradeSaleRspCmd"],
        { code = ErrorCode.None, error = "寄售商品成功", uid = context.uid, trade_id = product_data.trade_id },
        req.msg_context.stub_id)
        
end

function Trade.PBAuctionSaleReqCmd(req)
    -- 参数验证
    if not req.msg.config_id
        or not req.msg.uniqid
        or not req.msg.pos
        or not req.msg.start_price
        or not req.msg.buyout_price
        or not req.msg.sale_ts then
        return context.S2C(context.net_id, CmdCode.PBAuctionSaleRspCmd, {
            code = ErrorCode.ParamInvalid,
            error = "无效请求参数",
            uid = context.uid,
        }, req.msg_context.stub_id)
    end

    local trade_data = scripts.UserModel.GetTradeData()
    if not trade_data then
        return context.S2C(context.net_id, CmdCode["PBAuctionSaleRspCmd"],
            { code = ErrorCode.ServerInternalError, error = "数据加载出错", uid = context.uid }, req.msg_context.stub_id)
    end

    local item_conf = GameCfg.Item[req.msg.config_id]
    if not item_conf then
        return context.S2C(context.net_id, CmdCode["PBAuctionSaleRspCmd"],
            { code = ErrorCode.ConfigError, error = "物品配置不存在", uid = context.uid }, req.msg_context.stub_id)
    end

    if trade_data.simple_info.box_capacity + 1 > MAX_SALE_CAPACITY then
        return context.S2C(context.net_id, CmdCode["PBAuctionSaleRspCmd"],
            { code = ErrorCode.TradeCapacityNotEnough, error = "交易容量不足", uid = context.uid }, req.msg_context.stub_id)
    end

    local errcode, item_data = scripts.Bag.GetOneItemData(BagDef.BagType.Cangku, req.msg.pos)
    if errcode ~= ErrorCode.None
        or item_data.common_info.config_id ~= req.msg.config_id
        or item_data.common_info.uniqid ~= req.msg.uniqid then
        return context.S2C(context.net_id, CmdCode["PBAuctionSaleRspCmd"],
            { code = ErrorCode.ItemNotExist, error = "物品不存在", uid = context.uid }, req.msg_context.stub_id)
    end

    if item_data.common_info.trade_cnt == 0 then
        return context.S2C(context.net_id, CmdCode["PBAuctionSaleRspCmd"],
            { code = ErrorCode.TradeCapacityNotEnough, error = "交易次数不足", uid = context.uid }, req.msg_context.stub_id)
    end

    local auction_unique_items = {}
    auction_unique_items[item_data.common_info.uniqid] = {
        config_id = item_data.common_info.config_id,
        uniqid = item_data.common_info.uniqid,
        pos = req.msg.pos,
    }
    -- 扣除道具消耗
    local trade_cost = {}
    local change_log = {}
    local err_code = scripts.Bag.CheckItemsEnough(BagDef.BagType.Cangku, trade_cost, auction_unique_items)
    if err_code ~= ErrorCode.None then
        return context.S2C(context.net_id, CmdCode["PBAuctionSaleRspCmd"],
            { code = ErrorCode.ItemNotEnough, error = "物品数量不足", uid = context.uid }, req.msg_context.stub_id)
    end
    err_code = scripts.Bag.DelItems(BagDef.BagType.Cangku, trade_cost, auction_unique_items, change_log)
    if err_code ~= ErrorCode.None then
        scripts.Bag.RollBackWithChange(change_log)
        return context.S2C(context.net_id, CmdCode["PBAuctionSaleRspCmd"],
            { code = err_code, error = "物品数量不足", uid = context.uid }, req.msg_context.stub_id)
    end

    local product_data = {
        trade_id = 1,
        seller_uid = context.uid,
        item_data = item_data,
        beg_ts = moon.time(),
        end_ts = moon.time() + req.msg.sale_ts,
        state = TradeDef.TradeState.ON_SALE,
        auction_data = {
            start_price = req.msg.start_price,
            buyout_price = req.msg.buyout_price,
            cur_price = req.msg.start_price,
            buyer_uid = 0,
        },
    }
    local sale_data = {
        uid = context.uid,
        product_data = product_data,
        condition1 = item_conf.type1,
        condition2 = item_conf.type2,
        condition3 = item_conf.type3,
        condition4 = item_conf.type4,
        condition5 = item_conf.type5,
        custome_condition = {},
    }

    local res, err = clusterd.call(3999, "trademgr", "Trademgr.AddAuctionProduct", sale_data)
    if err then
        moon.error("Trade.PBTradeSaleReqCmd Trademgr.AddAuctionProduct err:%s", err)
        scripts.Bag.RollBackWithChange(change_log)
        return context.S2C(context.net_id, CmdCode["PBAuctionSaleRspCmd"],
            { code = ErrorCode.SaleProductErr, error = "寄售商品出错", uid = context.uid }, req.msg_context.stub_id)
    else
        if res <= 0 then
            scripts.Bag.RollBackWithChange(change_log)
            return context.S2C(context.net_id, CmdCode["PBAuctionSaleRspCmd"],
                { code = ErrorCode.SaleProductErr, error = "寄售商品出错", uid = context.uid }, req.msg_context.stub_id)
        end

        product_data.trade_id = res
        trade_data.product_datas[product_data.trade_id] = product_data
        table.insert(trade_data.simple_info.trade_ids, product_data.trade_id)
    end

    -- local save_bags = {}
    -- for bagType, _ in pairs(change_log) do
    --     save_bags[bagType] = 1
    -- end
    -- scripts.Bag.SaveAndLog(save_bags, change_log)
    scripts.Bag.SaveAndLog(change_log, ItemDef.ChangeReason.TradeSale)
    scripts.UserModel.SaveTradeData(trade_data)

    return context.S2C(context.net_id, CmdCode["PBAuctionSaleRspCmd"],
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

    local trade_data = scripts.UserModel.GetTradeData()
    if not trade_data then
        return context.S2C(context.net_id, CmdCode["PBSearchTradeProductRspCmd"],
            { code = ErrorCode.ServerInternalError, error = "数据加载出错", uid = context.uid }, req.msg_context.stub_id)
    end

    if req.msg.config_ids and table.size(req.msg.config_ids) > 0 then
        if table.size(req.msg.config_ids) > MAX_SEARCH_IDS_COUNT then
            return context.S2C(context.net_id, CmdCode.PBSearchTradeProductRspCmd, {
                code = ErrorCode.SearchIdsOverflow,
                error = "无效请求参数",
                uid = context.uid,
            }, req.msg_context.stub_id)
        end
    else
        if not req.msg.condition1 and not req.msg.condition2 and not req.msg.condition3
            and not req.msg.condition4 and not req.msg.condition5 then
            return context.S2C(context.net_id, CmdCode.PBSearchTradeProductRspCmd, {
                code = ErrorCode.SearchParamsInvalid,
                error = "无效请求参数",
                uid = context.uid,
            }, req.msg_context.stub_id)
        end
    end
end

return Trade