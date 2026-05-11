local moon = require "moon"
local common = require "common"
local clusterd = require("cluster")
local datetime = require("moon.datetime")
local GameCfg = common.GameCfg
local ErrorCode = common.ErrorCode
local CmdCode = common.CmdCode
local Database = common.Database
local json = require "json"
local AuctionDef = require("common.def.AuctionDef")
local BagDef = require("common.def.BagDef")
local ItemDef = require("common.def.ItemDef")
local ItemDefine = require("common.logic.ItemDefine")

---@type user_context
local context = ...
local scripts = context.scripts

local MAX_SALE_CAPACITY = 50
local MAX_SEARCH_IDS_COUNT = 10
local TRADE_LOG_MAX_COUNT = 100

---@class Auction
local Auction = {}

function Auction.Init()
    -- local auction_info = Auction.LoadAuctionInfo()
    -- if auction_info then
    --     local auction_data = AuctionDef.newSelfAuctionData()
    --     auction_data.simple_info = auction_info
    --     scripts.UserModel.SetAuctionData(auction_data)
    -- end

    -- local player_auction_data = scripts.UserModel.GetAuctionData()
    -- if not player_auction_data then
    --     player_auction_data = AuctionDef.newSelfAuctionData()
    --     local auction_cfg = GameCfg.TransactionConfig[2]
    --     if auction_cfg and auction_cfg.order_num and auction_cfg.account_market then
    --         player_auction_data.simple_info.box_capacity = auction_cfg.order_num
    --         player_auction_data.simple_info.can_onsale_cnt = auction_cfg.account_market
    --         player_auction_data.simple_info.update_ts = moon.time()
    --     end
    --     scripts.UserModel.SetAuctionData(player_auction_data)
    -- end
end

function Auction.Start()
    -- local player_auction_data = scripts.UserModel.GetAuctionData()
    -- if not player_auction_data then
    --     return
    -- end

    -- Auction.CheckData()
    -- Auction.DealOfflineAuctionLog()
    -- Auction.DealOfflineAuctionTakeDown()
    -- Auction.DealOfflineAuctionFailMail()

    -- Auction.SaveAuctionInfoNow()
end

function Auction.CheckData()
    local player_auction_data = scripts.UserModel.GetAuctionData()
    if not player_auction_data then
        return false
    end

    if player_auction_data.simple_info.auction_ids and table.size(player_auction_data.simple_info.auction_ids) > 0 then
        local new_product_datas = Database.RedisGetAuctionProductData(context.addr_db_redis,
            player_auction_data.simple_info.auction_ids)
        if new_product_datas then
            player_auction_data.simple_info.auction_ids = {}
            for _, product_data in pairs(new_product_datas) do
                player_auction_data.product_list[product_data.auction_id] = product_data
                table.insert(player_auction_data.simple_info.auction_ids, product_data.auction_id)
            end
        end
    end

    local auction_logs = Database.loadplayerauctionlog(context.addr_db_user, context.uid)
    if not auction_logs then
        return false
    end
    player_auction_data.log_list = auction_logs

    return true
end

function Auction.SaveAuctionInfoNow()
    local player_auction_data = scripts.UserModel.GetAuctionData()
    if not player_auction_data then
        return false
    end

    local success = Database.saveauctioninfo(context.addr_db_user, context.uid, player_auction_data.simple_info)
    return success
end

function Auction.LoadAuctionInfo()
    local auction_info = Database.loadauctioninfo(context.addr_db_user, context.uid)
    return auction_info
end

function Auction.SearchAuctionWitchConditions(state_type, condition1, condition2, condition3, condition4, condition5,
                                              custome_conditions1, custome_condition2, sort_type, start_idx, select_num)
    if not AuctionDef.SortDescribe[sort_type] then
        return ErrorCode.SearchProductTypeErr
    end

    local auction_products = Database.getauctionwithconditions(context.addr_db_user, state_type, condition1, condition2,
        condition3, condition4, condition5, custome_conditions1, custome_condition2, AuctionDef.SortDescribe[sort_type],
        start_idx, select_num)
    if not auction_products then
        return ErrorCode.SearchProductFailed
    end
    if table.size(auction_products) == 0 then
        return ErrorCode.SearchProductNone
    end

    return ErrorCode.None, auction_products
end

function Auction.SearchAuctionWithIds(state_type, ids, sort_type, start_idx, select_num)
    if not AuctionDef.SortDescribe[sort_type] then
        return ErrorCode.SearchProductTypeErr
    end
    if start_idx < 0 then
        return ErrorCode.SearchProductStartErr
    end

    local auction_products = Database.getauctionwithids(context.addr_db_user, state_type, ids,
        AuctionDef.SortDescribe[sort_type], start_idx, select_num)
    if not auction_products then
        return ErrorCode.SearchProductFailed
    end
    if table.size(auction_products) == 0 then
        return ErrorCode.SearchProductNone
    end

    return ErrorCode.None, auction_products
end

function Auction.OnAuctionFailMail(wait_data)
    local auction_cfg = GameCfg.TransactionConfig[2]
    if not auction_cfg or not auction_cfg.failed_email then
        moon.error("OnAuctionFailMail auction_cfg.failed_email not found")
        return
    end

    local player_auction_data = scripts.UserModel.GetAuctionData()
    if not player_auction_data then
        return
    end

    local add_coins = {}
    add_coins[auction_cfg.order_currency] = {
        coin_id = auction_cfg.order_currency,
        coin_count = wait_data.price
    }
    local mail_ret = scripts.Mail.RecvImmediateMail(auction_cfg.failed_email, {}, {}, add_coins)
    if not mail_ret then
        moon.error(string.format("OnAuctionFailMail mail_ret false wait_data = %s", json.pretty_encode(wait_data)))
        return
    end

    Database.RedisDelAuctionWaitMail(context.addr_db_redis, context.uid, wait_data.auction_id, wait_data.price)
end

function Auction.OnAuctionTakeDownMail(auction_product, now_state, positive)
    local auction_cfg = GameCfg.TransactionConfig[2]
    if not auction_cfg or not auction_cfg.unsell_email or not auction_cfg.expire_email then
        moon.error(string.format("OnAuctionTakeDownMail auction_cfg not found = %s", auction_product))
        return
    end

    local ret = Database.updateauctionproduct(context.addr_db_user, auction_product.auction_id,
        { state = now_state }, { state = AuctionDef.StateType.TAKE_DOWNED }, true)
    if ret ~= 1 then
        moon.error(string.format("OnAuctionTakeDownMail err = %s", json.pretty_encode(auction_product)))
        return
    end

    -- 发送邮件
    local items_data = {}
    table.insert(items_data, auction_product.item_data)
    
    if positive then
        -- 主动下架
        local mail_ret = scripts.Mail.RecvImmediateMail(auction_cfg.unsell_email, {}, items_data, {})
        if not mail_ret then
            moon.error(string.format("OnAuctionTakeDownMail mail_ret false auction_product = %s",
                json.pretty_encode(auction_product)))
            return
        end
    else
        -- 过期下架
        local mail_ret = scripts.Mail.RecvImmediateMail(auction_cfg.expire_email, {}, items_data, {})
        if not mail_ret then
            moon.error(string.format("OnAuctionTakeDownMail mail_ret false auction_product = %s",
                json.pretty_encode(auction_product)))
            return
        end
    end
end

function Auction.OnAuctionLogSaleMail(auction_log, need_save)
    if auction_log.send_seller_mail ~= 0 then
        return
    end

    local auction_cfg = GameCfg.TransactionConfig[2]
    if not auction_cfg or not auction_cfg.sell_email or not auction_cfg.order_currency then
        moon.error("OnAuctionLogSaleMail auction_cfg.sell_email or auction_cfg.order_currency not found = %s")
        return
    end
    local player_auction_data = scripts.UserModel.GetAuctionData()
    if not player_auction_data then
        return
    end

    local add_coins = {}
    add_coins[auction_cfg.order_currency] = {
        coin_id = auction_cfg.order_currency,
        coin_count = auction_log.deal_price - auction_log.auction_tax,
    }
    -- 发送邮件
    local mail_ret = scripts.Mail.RecvImmediateMail(auction_cfg.sell_email, {}, {}, add_coins)
    if not mail_ret then
        moon.error(string.format("OnAuctionLogSaleMail mail_ret false auction_log = %s", json.pretty_encode(auction_log)))
        return
    end
    auction_log.send_seller_mail = 1
    -- 通知Auctionmgr更改邮件发送记录
    clusterd.send(3999, "auctionmgr", "Auctionmgr.SellerDealAuctionLog", auction_log.log_id)

    -- 修改player_auction_data
    if need_save then
        if player_auction_data.product_list[auction_log.auction_id] then
            player_auction_data.product_list[auction_log.auction_id] = nil
            for idx, auction_id in pairs(player_auction_data.simple_info.auction_ids) do
                if auction_id == auction_log.auction_id then
                    table.remove(player_auction_data.simple_info.auction_ids, idx)
                    break
                end
            end
        end
        table.insert(player_auction_data.log_list, auction_log)
        if table.size(player_auction_data.log_list) > TRADE_LOG_MAX_COUNT then
            table.remove(player_auction_data.log_list, 1)
        end
        Auction.SaveAuctionInfoNow()
    end
end

function Auction.OnAuctionLogBuyMail(auction_log)
    if auction_log.send_buyer_mail ~= 0 then
        return
    end

    local auction_cfg = GameCfg.TransactionConfig[2]
    if not auction_cfg or not auction_cfg.shipments_email then
        moon.error(string.format("OnAuctionLogBuyMail auction_cfg.shipments_email not found = %s", auction_log))
        return
    end

    local player_auction_data = scripts.UserModel.GetAuctionData()
    if not player_auction_data then
        return
    end

    local items_data = {}
    table.insert(items_data, auction_log.item_data)
    -- 发送邮件
    local mail_ret = scripts.Mail.RecvImmediateMail(auction_cfg.shipments_email, {}, items_data, {})
    if not mail_ret then
        moon.error(string.format("OnAuctionLogBuyMail mail_ret false auction_log = %s", json.pretty_encode(auction_log)))
        return
    end
    auction_log.send_buyer_mail = 1
    -- 通知Auctionmgr更改邮件发送记录
    clusterd.send(3999, "auctionmgr", "Auctionmgr.BuyerDealAuctionLog", auction_log.log_id)

    -- 修改player_auction_data
    table.insert(player_auction_data.log_list, auction_log)
    if table.size(player_auction_data.log_list) > TRADE_LOG_MAX_COUNT then
        table.remove(player_auction_data.log_list, 1)
    end
    Auction.SaveAuctionInfoNow()
end

function Auction.DealOfflineAuctionLog()
    local auction_logs = Database.getgetauctionlognomail(context.addr_db_user, context.uid)
    if not auction_logs or table.size(auction_logs) == 0 then
        return
    end
    for _, auction_log in pairs(auction_logs) do
        if auction_log.send_seller_mail == 0 then
            Auction.OnAuctionLogSaleMail(auction_log, false)
        end
        if auction_log.send_buyer_mail == 0 then
            Auction.OnAuctionLogBuyMail(auction_log)
        end
    end
end

function Auction.DealOfflineAuctionTakeDown()
    local where_data = {
        seller_uid = context.uid,
        state = AuctionDef.StateType.TAKE_DOWNING,
    }
    local auction_products = Database.getauctionproduct(context.addr_db_user, where_data, MAX_SEARCH_IDS_COUNT)
    if not auction_products then
        return
    end
    if table.size(auction_products) == 0 then
        return
    end

    for _, auction_product in pairs(auction_products) do
        Auction.OnAuctionTakeDownMail(auction_product, AuctionDef.StateType.TAKE_DOWNING, false)
    end
end

function Auction.DealOfflineAuctionFailMail()
    local fail_mails = Database.RedisGetAllAuctionWaitMails(context.addr_db_redis, context.uid)
    for key_str, wait_data in pairs(fail_mails) do
        Auction.OnAuctionFailMail(wait_data)
    end
end

function Auction.CheckOnSaleCnt(player_auction_data)
    local now_ts = moon.time()
    local auction_cfg = GameCfg.TransactionConfig[2]
    if auction_cfg and auction_cfg.account_market and auction_cfg.refresh_time then
        if not datetime.is_same_day(player_auction_data.simple_info.update_ts, now_ts - auction_cfg.refresh_time) then
            player_auction_data.simple_info.can_onsale_cnt = auction_cfg.account_market
            player_auction_data.simple_info.update_ts = moon.time()
            Auction.SaveAuctionInfoNow()
        end
    end
end

function Auction.PBGetAuctionInfoReqCmd(req)
    local player_auction_data = scripts.UserModel.GetAuctionData()
    if not player_auction_data then
        return context.S2C(context.net_id, CmdCode["PBGetAuctionInfoRspCmd"],
            { code = ErrorCode.ServerInternalError, error = "数据加载出错", uid = context.uid }, req.msg_context.stub_id)
    end
    Auction.CheckOnSaleCnt(player_auction_data)

    local rsp = {
        code = ErrorCode.None,
        error = "",
        uid = context.uid,
        self_auction_info = player_auction_data
    }
    return context.S2C(context.net_id, CmdCode["PBGetAuctionInfoRspCmd"], rsp, req.msg_context.stub_id)
end

function Auction.PBAuctionSaleReqCmd(req)
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

    local player_auction_data = scripts.UserModel.GetAuctionData()
    if not player_auction_data then
        return context.S2C(context.net_id, CmdCode["PBAuctionSaleRspCmd"],
            { code = ErrorCode.ServerInternalError, error = "数据加载出错", uid = context.uid }, req.msg_context.stub_id)
    end
    Auction.CheckOnSaleCnt(player_auction_data)

    local uniqitem_conf = GameCfg.UniqueItem[req.msg.config_id]
    if not uniqitem_conf then
        return context.S2C(context.net_id, CmdCode["PBAuctionSaleRspCmd"],
            { code = ErrorCode.ConfigError, error = "物品配置不存在", uid = context.uid }, req.msg_context.stub_id)
    end
    if not uniqitem_conf.could_sell or uniqitem_conf.could_sell ~= 1 then
        return context.S2C(context.net_id, CmdCode["PBAuctionSaleRspCmd"],
            { code = ErrorCode.TradeItemNotAllowed, error = "物品不允许交易", uid = context.uid }, req.msg_context.stub_id)
    end

    local auction_cfg = GameCfg.TransactionConfig[2]
    if not auction_cfg
        or not auction_cfg.service_charge_type
        or not auction_cfg.order_percentage
        or not auction_cfg.order_time
        or not auction_cfg.order_time[req.msg.sale_ts] then
        return context.S2C(context.net_id, CmdCode["PBAuctionSaleRspCmd"],
            { code = ErrorCode.ConfigError, error = "交易上架费用配置不存在", uid = context.uid }, req.msg_context.stub_id)
    end

    if player_auction_data.simple_info.box_capacity + 1 > MAX_SALE_CAPACITY then
        return context.S2C(context.net_id, CmdCode["PBAuctionSaleRspCmd"],
            { code = ErrorCode.TradeCapacityNotEnough, error = "交易容量不足", uid = context.uid }, req.msg_context.stub_id)
    end

    if player_auction_data.simple_info.can_onsale_cnt <= 0 then
        return context.S2C(context.net_id, CmdCode["PBAuctionSaleRspCmd"],
            { code = ErrorCode.TradeCntNotEnough, error = "交易次数不足", uid = context.uid }, req.msg_context.stub_id)
    end

    -- if item_type == ItemDefine.EItemSmallType.SkinCard then
    --     local errcode, item_data = scripts.Bag.GetOneItemData(BagDef.BagType.Cangku, req.msg.pos)
    --     if errcode ~= ErrorCode.None
    --         or not item_data
    --         or item_data.common_info.config_id ~= req.msg.config_id
    --         or item_data.common_info.item_count < 1
    --         or req.msg.uniqid ~= 0 then
    --         return context.S2C(context.net_id, CmdCode["PBAuctionSaleRspCmd"],
    --             { code = ErrorCode.ItemNotExist, error = "物品不存在", uid = context.uid }, req.msg_context.stub_id)
    --     end

    --     if item_data.common_info.trade_cnt == 0 then
    --         return context.S2C(context.net_id, CmdCode["PBAuctionSaleRspCmd"],
    --             { code = ErrorCode.TradeCntNotEnough, error = "交易次数不足", uid = context.uid }, req.msg_context.stub_id)
    --     end
    -- else
    --     local errcode, pos, item_data = scripts.Bag.GetUniqItemData(BagDef.BagType.Cangku, req.msg.uniqid)
    --     if errcode ~= ErrorCode.None
    --         or pos ~= req.msg.pos
    --         or not item_data
    --         or item_data.common_info.config_id ~= req.msg.config_id then
    --         return context.S2C(context.net_id, CmdCode["PBAuctionSaleRspCmd"],
    --             { code = ErrorCode.ItemNotExist, error = "物品不存在", uid = context.uid }, req.msg_context.stub_id)
    --     end

    --     if item_data.common_info.trade_cnt == 0 then
    --         return context.S2C(context.net_id, CmdCode["PBAuctionSaleRspCmd"],
    --             { code = ErrorCode.TradeCntNotEnough, error = "交易次数不足", uid = context.uid }, req.msg_context.stub_id)
    --     end
    -- end

    local errcode, item_data = scripts.Bag.GetOneItemData(BagDef.BagType.Cangku, req.msg.pos)
    if errcode ~= ErrorCode.None
        or not item_data
        or item_data.common_info.config_id ~= req.msg.config_id
        or item_data.common_info.uniqid ~= req.msg.uniqid
        or item_data.common_info.item_count < 1 then
        return context.S2C(context.net_id, CmdCode["PBAuctionSaleRspCmd"],
            { code = ErrorCode.ItemNotExist, error = "物品不存在", uid = context.uid }, req.msg_context.stub_id)
    end

    local item_type = ItemDefine.GetItemType(req.msg.config_id)
    if item_type ~= ItemDefine.EItemSmallType.SkinCard then
        if item_data.common_info.trade_cnt == 0 then
            return context.S2C(context.net_id, CmdCode["PBAuctionSaleRspCmd"],
                { code = ErrorCode.TradeCntNotEnough, error = "交易次数不足", uid = context.uid }, req.msg_context.stub_id)
        end
    end

    local bag_change_log = {}
    local auction_cost_items = {}
    auction_cost_items[req.msg.pos] = {
        config_id = item_data.common_info.config_id,
        uniqid = item_data.common_info.uniqid,
        item_count = -1,
    }
    -- 扣除上架费用
    local auction_cost_coins = {}
    auction_cost_coins[auction_cfg.service_charge_type] = {
        coin_id = auction_cfg.service_charge_type,
        coin_count = -auction_cfg.order_time[req.msg.sale_ts],
    }
    -- 向上取整auction_rate_coin_count
    local auction_rate_coin_count = math.ceil((auction_cfg.order_percentage * req.msg.buyout_price) / 10000)
    auction_cost_coins[auction_cfg.service_charge_type].coin_count = auction_cost_coins[auction_cfg.service_charge_type]
        .coin_count - auction_rate_coin_count
    
    local err_code = scripts.Bag.CheckItemsEnoughPos(BagDef.BagType.Cangku, auction_cost_items)
    if err_code ~= ErrorCode.None then
        return context.S2C(context.net_id, CmdCode["PBAuctionSaleRspCmd"],
            { code = ErrorCode.ItemNotEnough, error = "物品数量不足", uid = context.uid }, req.msg_context.stub_id)
    end
    err_code = scripts.Bag.CheckCoinsEnough(auction_cost_coins)
    if err_code ~= ErrorCode.None then
        return context.S2C(context.net_id, CmdCode["PBAuctionSaleRspCmd"],
            { code = err_code, error = "上架费用不足", uid = context.uid }, req.msg_context.stub_id)
    end

    err_code = scripts.Bag.DelItemsPos(BagDef.BagType.Cangku, auction_cost_items, bag_change_log)
    if err_code ~= ErrorCode.None then
        scripts.Bag.RollBackWithChange(bag_change_log)
        return context.S2C(context.net_id, CmdCode["PBAuctionSaleRspCmd"],
            { code = err_code, error = "物品数量不足", uid = context.uid }, req.msg_context.stub_id)
    end
    err_code = scripts.Bag.DealCoins(auction_cost_coins, bag_change_log)
    if err_code ~= ErrorCode.None then
        scripts.Bag.RollBackWithChange(bag_change_log)
        return context.S2C(context.net_id, CmdCode["PBAuctionSaleRspCmd"],
            { code = err_code, error = "上架费用不足", uid = context.uid }, req.msg_context.stub_id)
    end

    -- item_data.common_info.item_count = req.msg.sale_num
    local product_data = AuctionDef.newAuctionProductBaseData()
    product_data.auction_id = 1
    product_data.seller_uid = context.uid
    product_data.config_id = item_data.common_info.config_id
    product_data.uniqid = item_data.common_info.uniqid
    product_data.item_data = item_data
    product_data.beg_ts = moon.time()
    product_data.end_ts = moon.time() + req.msg.sale_ts
    product_data.state = AuctionDef.StateType.ON_SALE
    product_data.auction_data.start_price = req.msg.start_price
    product_data.auction_data.buyout_price = req.msg.buyout_price
    product_data.auction_data.cur_price = req.msg.start_price

    local sale_data = {
        uid = context.uid,
        product_data = product_data,
        condition1 = 0,
        condition2 = 0,
        condition3 = 0,
        condition4 = 0,
        condition5 = 0,
        custom_conditions1 = {},
        custom_condition2 = 0,
    }
    if table.size(uniqitem_conf.market) >= 1 then
        sale_data.condition1 = uniqitem_conf.market[1]
    end
    if table.size(uniqitem_conf.market) >= 2 then
        sale_data.condition2 = uniqitem_conf.market[2]
    end
    if table.size(uniqitem_conf.market) >= 3 then
        sale_data.condition3 = uniqitem_conf.market[3]
    end
    if table.size(uniqitem_conf.market) >= 4 then
        sale_data.condition4 = uniqitem_conf.market[4]
    end
    if table.size(uniqitem_conf.market) >= 5 then
        sale_data.condition5 = uniqitem_conf.market[5]
    end
    if item_type ~= ItemDefine.EItemSmallType.SkinCard and item_data.special_info then
        if item_data.special_info.magic_item then
            if table.size(item_data.special_info.magic_item.tags) > 0 then
                for _, tag in pairs(item_data.special_info.magic_item.tags) do
                    table.insert(sale_data.custom_conditions1, tag.tag_id)
                end
            end
            if table.size(item_data.special_info.magic_item.ability_tag) > 0 then
                sale_data.custom_condition2 = item_data.special_info.magic_item.ability_tag[1].tag_id
            end
        elseif item_data.special_info.diagrams_item then
            if table.size(item_data.special_info.diagrams_item.tags) > 0 then
                for _, tag in pairs(item_data.special_info.diagrams_item.tags) do
                    table.insert(sale_data.custom_conditions1, tag.tag_id)
                end
            end
            if table.size(item_data.special_info.diagrams_item.ability_tag) > 0 then
                sale_data.custom_condition2 = item_data.special_info.diagrams_item.ability_tag[1].tag_id
            end
        elseif item_data.special_info.space_ring then
            if table.size(item_data.special_info.space_ring.tags) > 0 then
                for _, tag in pairs(item_data.special_info.space_ring.tags) do
                    table.insert(sale_data.custom_conditions1, tag.tag_id)
                end
            end
            if table.size(item_data.special_info.space_ring.ability_tag) > 0 then
                sale_data.custom_condition2 = item_data.special_info.space_ring.ability_tag[1].tag_id
            end
        end
    end
    
    local res, err = clusterd.call(3999, "auctionmgr", "Auctionmgr.AddAuctionProduct", sale_data)
    if err then
        moon.error("Auction.PBAuctionSaleReqCmd Auctionmgr.AddAuctionProduct err:%s", err)
        scripts.Bag.RollBackWithChange(bag_change_log)
        return context.S2C(context.net_id, CmdCode["PBAuctionSaleRspCmd"],
            { code = ErrorCode.SaleProductErr, error = "寄售商品出错", uid = context.uid }, req.msg_context.stub_id)
    else
        if res <= 0 then
            scripts.Bag.RollBackWithChange(bag_change_log)
            return context.S2C(context.net_id, CmdCode["PBAuctionSaleRspCmd"],
                { code = ErrorCode.SaleProductErr, error = "寄售商品出错", uid = context.uid }, req.msg_context.stub_id)
        end

        product_data.auction_id = res
        player_auction_data.product_list[product_data.auction_id] = product_data
        table.insert(player_auction_data.simple_info.auction_ids, product_data.auction_id)
    end

    scripts.Bag.SaveAndLog(bag_change_log, ItemDef.ChangeReason.AuctionSale)
    Auction.SaveAuctionInfoNow()

    return context.S2C(context.net_id, CmdCode["PBAuctionSaleRspCmd"],
        { code = ErrorCode.None, error = "寄售商品成功", uid = context.uid, auction_id = product_data.auction_id },
        req.msg_context.stub_id)
end

function Auction.PBSearchAuctionProductReqCmd(req)
    -- 参数验证
    if not req.msg.sort_type
        or not req.msg.start_idx then
        return context.S2C(context.net_id, CmdCode.PBSearchAuctionProductRspCmd, {
            code = ErrorCode.ParamInvalid,
            error = "无效请求参数",
            uid = context.uid,
        }, req.msg_context.stub_id)
    end

    local player_auction_data = scripts.UserModel.GetAuctionData()
    if not player_auction_data then
        return context.S2C(context.net_id, CmdCode["PBSearchAuctionProductRspCmd"],
            { code = ErrorCode.ServerInternalError, error = "数据加载出错", uid = context.uid }, req.msg_context.stub_id)
    end

    if req.msg.config_ids and table.size(req.msg.config_ids) > 0 then
        local auction_cfg = GameCfg.TransactionConfig[2]
        local max_search_num = MAX_SEARCH_IDS_COUNT
        if auction_cfg and auction_cfg.collection_num and auction_cfg.collection_num > max_search_num then
            max_search_num = auction_cfg.collection_num
        end
        if table.size(req.msg.config_ids) > max_search_num then
            return context.S2C(context.net_id, CmdCode.PBSearchAuctionProductRspCmd, {
                code = ErrorCode.SearchIdsOverflow,
                error = "搜索商品数量超过最大数量",
                uid = context.uid,
            }, req.msg_context.stub_id)
        end

        local errcode, auction_products = Auction.SearchAuctionWithIds(AuctionDef.StateType.ON_SALE, req.msg.config_ids,
            req.msg.sort_type, req.msg.start_idx, 100)
        if errcode ~= ErrorCode.None then
            return context.S2C(context.net_id, CmdCode.PBSearchAuctionProductRspCmd, {
                code = errcode,
                error = "搜索商品出错",
                uid = context.uid,
            }, req.msg_context.stub_id)
        end

        return context.S2C(context.net_id, CmdCode.PBSearchAuctionProductRspCmd, {
            code = ErrorCode.None,
            error = "搜索商品成功",
            uid = context.uid,
            search_products = auction_products,
        }, req.msg_context.stub_id)
    else
        if not req.msg.condition1 and not req.msg.condition2 and not req.msg.condition3
            and not req.msg.condition4 and not req.msg.condition5 then
            return context.S2C(context.net_id, CmdCode.PBSearchAuctionProductRspCmd, {
                code = ErrorCode.SearchParamsInvalid,
                error = "无效请求参数",
                uid = context.uid,
            }, req.msg_context.stub_id)
        end

        local errcode, auction_products = Auction.SearchAuctionWitchConditions(req.msg.condition1, req.msg.condition2,
            req.msg.condition3, req.msg.condition4, req.msg.condition5, req.msg.sort_type, req.msg.start_idx)
        if errcode ~= ErrorCode.None then
            return context.S2C(context.net_id, CmdCode.PBSearchAuctionProductRspCmd, {
                code = errcode,
                error = "搜索商品出错",
                uid = context.uid,
            }, req.msg_context.stub_id)
        end


        return context.S2C(context.net_id, CmdCode.PBSearchAuctionProductRspCmd, {
            code = ErrorCode.None,
            error = "搜索商品成功",
            uid = context.uid,
            search_products = auction_products,
        }, req.msg_context.stub_id)
    end
end

function Auction.PBAuctionBuyReqCmd(req)
    -- 参数验证
    if not req.msg.auction_id
        or not req.msg.uniqid
        or not req.msg.buy_price then
        return context.S2C(context.net_id, CmdCode.PBAuctionBuyRspCmd, {
            code = ErrorCode.ParamInvalid,
            error = "无效请求参数",
            uid = context.uid,
        }, req.msg_context.stub_id)
    end

    local auction_cfg = GameCfg.TransactionConfig[2]
    if not auction_cfg or not auction_cfg.shipments_email then
        moon.error("PBAuctionBuyReqCmd auction_cfg.shipments_email not found")
        return context.S2C(context.net_id, CmdCode.PBAuctionBuyRspCmd, {
            code = ErrorCode.MailConfigError,
            error = "邮件参数错误",
            uid = context.uid,
        }, req.msg_context.stub_id)
    end

    if not auction_cfg.order_currency then
        return context.S2C(context.net_id, CmdCode.PBAuctionBuyRspCmd, {
            code = ErrorCode.CoinNotEnough,
            error = "货币不足",
            uid = context.uid,
        }, req.msg_context.stub_id)
    end
    -- 校验玩家身上货币是否足够
    local coin_count = scripts.Bag.GetCoinCount(auction_cfg.order_currency)
    if coin_count <= req.msg.buy_price then
        return context.S2C(context.net_id, CmdCode.PBAuctionBuyRspCmd, {
            code = ErrorCode.CoinNotEnough,
            error = "货币不足",
            uid = context.uid,
        }, req.msg_context.stub_id)
    end

    local cost_coins = {}
    cost_coins[auction_cfg.order_currency] = {
        coin_id = auction_cfg.order_currency,
        coin_count = -req.msg.buy_price,
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

    local res, err = clusterd.call(3999, "auctionmgr", "Auctionmgr.BuyAuctionProduct", context.uid, req.msg.auction_id,
        req.msg.uniqid, req.msg.buy_price)
    if err or not res then
        moon.error(string.format("Auction.PBAuctionBuyReqCmd Auctionmgr.BuyAuctionProduct err:%s", err))
        scripts.Bag.RollBackWithChange(bag_change_logs)
        return context.S2C(context.net_id, CmdCode.PBAuctionBuyRspCmd, {
            code = ErrorCode.TradeBuyError,
            error = "购买商品出错",
            uid = context.uid,
        }, req.msg_context.stub_id)
    end
    if res.code ~= ErrorCode.None then
        scripts.Bag.RollBackWithChange(bag_change_logs)
        return context.S2C(context.net_id, CmdCode.PBAuctionBuyRspCmd, {
            code = res.code,
            error = "购买商品出错",
            uid = context.uid,
        }, req.msg_context.stub_id)
    end

    if res.real_buy_price < req.msg.buy_price then
        scripts.Bag.RollBackWithChange(bag_change_logs)
        -- 重新扣除正确的金额
        bag_change_logs = {}
        cost_coins[auction_cfg.order_currency].coin_count = -res.real_buy_price
        err_code_coins = scripts.Bag.DealCoins(cost_coins, bag_change_logs)
        if err_code_coins ~= ErrorCode.None then
            scripts.Bag.RollBackWithChange(bag_change_logs)
            return err_code_coins
        end
    end

    scripts.Bag.SaveAndLog(bag_change_logs, ItemDef.ChangeReason.AuctionBuy)

    return context.S2C(context.net_id, CmdCode.PBAuctionBuyRspCmd, {
        code = ErrorCode.None,
        error = "购买商品成功",
        uid = context.uid,
        real_buy_price = res.real_buy_price,
    }, req.msg_context.stub_id)
end

function Auction.PBAuctionTakeOffProductReqCmd(req)
    -- 参数验证
    if not req.msg.auction_id then
        return context.S2C(context.net_id, CmdCode.PBAuctionTakeOffProductRspCmd, {
            code = ErrorCode.ParamInvalid,
            error = "无效请求参数",
            uid = context.uid,
        }, req.msg_context.stub_id)
    end

    local player_auction_data = scripts.UserModel.GetAuctionData()
    if not player_auction_data then
        return context.S2C(context.net_id, CmdCode.PBAuctionTakeOffProductRspCmd,
            { code = ErrorCode.ServerInternalError, error = "数据加载出错", uid = context.uid }, req.msg_context.stub_id)
    end
    if not player_auction_data.product_list[req.msg.auction_id] then
        return context.S2C(context.net_id, CmdCode.PBAuctionTakeOffProductRspCmd, {
            code = ErrorCode.TradeProductNotExist,
            error = "商品不存在",
            uid = context.uid,
            auction_id = req.msg.auction_id,
        }, req.msg_context.stub_id)
    end

    local res, err = clusterd.call(3999, "auctionmgr", "Auctionmgr.TakeOffProduct", context.uid, req.msg.auction_id)
    if err or res ~= ErrorCode.None then
        moon.error(string.format("Auction.PBAuctionTakeOffProductReqCmd Auctionmgr.TakeOffProduct err:%s", err))
        return context.S2C(context.net_id, CmdCode.PBAuctionTakeOffProductRspCmd, {
            code = ErrorCode.TradeTakeOffError,
            error = "下架商品出错",
            uid = context.uid,
            auction_id = req.msg.auction_id,
        }, req.msg_context.stub_id)
    end

    player_auction_data.product_list[req.msg.auction_id] = nil
    for idx, auction_id in pairs(player_auction_data.simple_info.auction_ids) do
        if auction_id == req.msg.auction_id then
            table.remove(player_auction_data.simple_info.auction_ids, idx)
            break
        end
    end
    Auction.SaveAuctionInfoNow()

    return context.S2C(context.net_id, CmdCode.PBAuctionTakeOffProductRspCmd, {
        code = res,
        error = "",
        uid = context.uid,
        auction_id = req.msg.auction_id,
    }, req.msg_context.stub_id)
end

function Auction.PBAuctionChangeFocusIdReqCmd(req)
    -- 参数验证
    if not req.msg.focus_op
        or not req.msg.focus_id then
        return context.S2C(context.net_id, CmdCode.PBAuctionChangeFocusIdRspCmd, {
            code = ErrorCode.ParamInvalid,
            error = "无效请求参数",
            uid = context.uid,
        }, req.msg_context.stub_id)
    end

    local player_auction_data = scripts.UserModel.GetAuctionData()
    if not player_auction_data then
        return context.S2C(context.net_id, CmdCode.PBAuctionChangeFocusIdRspCmd,
            { code = ErrorCode.ServerInternalError, error = "数据加载出错", uid = context.uid }, req.msg_context.stub_id)
    end

    if req.msg.focus_op == 0 then
        player_auction_data.simple_info.focus_auctionid_ts[req.msg.focus_id] = nil
    else
        local max_focus_num = 0
        local auction_cfg = GameCfg.TransactionConfig[2]
        if auction_cfg and auction_cfg.collection_num and auction_cfg.collection_num > max_focus_num then
            max_focus_num = auction_cfg.collection_num
        end
        if table.size(player_auction_data.simple_info.focus_auctionid_ts) >= max_focus_num then
            return context.S2C(context.net_id, CmdCode.PBAuctionChangeFocusIdRspCmd, {
                code = ErrorCode.FocusIdOverflow,
                error = "关注商品数量超过最大数量",
                uid = context.uid,
            }, req.msg_context.stub_id)
        end
        player_auction_data.simple_info.focus_auctionid_ts[req.msg.focus_id] = moon.time()
    end
    Auction.SaveAuctionInfoNow()

    return context.S2C(context.net_id, CmdCode.PBAuctionChangeFocusIdRspCmd, {
        code = ErrorCode.None,
        error = "更改关注商品",
        uid = context.uid,
        focus_id_ts = player_auction_data.simple_info.focus_auctionid_ts,
    }, req.msg_context.stub_id)
end

return Auction