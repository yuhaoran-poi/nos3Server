local moon = require("moon")
local datetime = require("moon.datetime")
local socket = require("moon.socket")
local common = require("common")
local CmdCode = common.CmdCode
local GameCfg = common.GameCfg --游戏配置
local Database = common.Database
local ErrorCode = common.ErrorCode
local lock_auction_data = require("moon.queue")()
local lock_auction_log = require("moon.queue")()
local httpc = require("moon.http.client")
local json = require("json")
local crypt = require("crypt")
local protocol = require("common.protocol_pb")
local AuctionDef = require("common.def.AuctionDef")
local ProtoEnum = require("tools.ProtoEnum")
local UserAttrLogic = require("common.logic.UserAttrLogic")
local jencode = json.encode
local jdecode = json.decode

---@type auctionmgr_context
local context = ...

local listenfd
local MAX_SEARCH_NUM = 1000

---@class Auctionmgr
local Auctionmgr = {
    load_finish = false,
    now_auction_id = 0,
    now_log_id = 0,
    product_list = {},          -- 交易行商品简要信息
    product_endts = {},       -- 商品id-过期时间
    min_endts = 0,             -- 最近过期时间
    take_down_auction_ids = {}, -- 交易行下架商品id
    add_auction_logs = {},     -- 交易行商品日志添加
}

function Auctionmgr.Init()
    -- -- 新增定时器轮询
    moon.async(function()
        while true do
            moon.sleep(3000) -- 每3秒检查一次
            if Auctionmgr.load_finish then
                Auctionmgr.CheckEndts()
                Auctionmgr.TakeDownProduct()
            end
        end
    end)

    moon.async(function()
        while true do
            moon.sleep(1000) -- 每1秒检查一次
            if Auctionmgr.load_finish then
                Auctionmgr.AddAuctionLog()
            end
        end
    end)

    return true
end

function Auctionmgr.Start()
    Auctionmgr.now_auction_id = Database.getmaxauctionid(context.addr_db_game)
    if Auctionmgr.now_auction_id < 0 then
        moon.error("Auctionmgr.Start getmaxauctionid failed")
        return
    end
    if Auctionmgr.now_auction_id == 0 then
        Auctionmgr.now_auction_id = 1
    else
        Auctionmgr.now_auction_id = Auctionmgr.now_auction_id + 1
    end
    Auctionmgr.now_log_id = Database.getmaxauctionlogid(context.addr_db_game)
    if Auctionmgr.now_log_id < 0 then
        moon.error("Auctionmgr.Start getmaxauctionlogid failed")
        return
    end
    if Auctionmgr.now_log_id == 0 then
        Auctionmgr.now_log_id = 1
    else
        Auctionmgr.now_log_id = Auctionmgr.now_log_id + 1
    end

    local now_ts = moon.time()

    local start_auction_id = 0
    while true do
        local auction_products = Database.getauctionproductwithnum(context.addr_db_game, start_auction_id,
            AuctionDef.StateType.ON_SALE, MAX_SEARCH_NUM)
        if not auction_products or table.size(auction_products) <= 0 then
            moon.error("Auctionmgr.Start getauctionproductwithnum failed", start_auction_id, MAX_SEARCH_NUM)
            break
        end

        for i = 1, table.size(auction_products) do
            local auction_product = auction_products[i]
            if auction_product.auction_id > start_auction_id then
                start_auction_id = auction_product.auction_id
            end

            if now_ts >= auction_product.end_ts then
                -- 已过期，应该下架
                auction_product.state = AuctionDef.StateType.TAKE_DOWNING
                Auctionmgr.take_down_auction_ids[auction_product.auction_id] = auction_product
                -- 删除从redis商品表
                Database.RedisDelAuctionProductData(context.addr_db_redis, { auction_product.auction_id })
            else
                Auctionmgr.product_endts[auction_product.auction_id] = auction_product.end_ts
                if Auctionmgr.min_endts == 0 or Auctionmgr.min_endts > auction_product.end_ts then
                    Auctionmgr.min_endts = auction_product.end_ts
                end
                Auctionmgr.product_list[auction_product.auction_id] = auction_product
            end
        end

        if table.size(auction_products) < MAX_SEARCH_NUM then
            break
        end
    end

    Auctionmgr.load_finish = true
    return true
end

function Auctionmgr.CheckEndts()
    local now_ts = moon.time()

    local scope <close> = lock_auction_data()

    if now_ts >= Auctionmgr.min_endts then
        local remove_auction_ids = {}
        for auction_id, end_ts in pairs(Auctionmgr.product_endts) do
            if now_ts >= end_ts then
                if Auctionmgr.product_list[auction_id] then
                    local product_data = Auctionmgr.product_list[auction_id]
                    product_data.state = AuctionDef.StateType.TAKE_DOWNING
                    Auctionmgr.take_down_auction_ids[auction_id] = product_data
                    table.insert(remove_auction_ids, auction_id)
                end
            else
                if Auctionmgr.min_endts < now_ts or Auctionmgr.min_endts > end_ts then
                    Auctionmgr.min_endts = end_ts
                end
            end
        end
        if table.size(remove_auction_ids) > 0 then
            -- 删除从redis商品表
            Database.RedisDelAuctionProductData(context.addr_db_redis, remove_auction_ids)

            for _, auction_id in pairs(remove_auction_ids) do
                Auctionmgr.product_list[auction_id] = nil
                Auctionmgr.product_endts[auction_id] = nil
            end
        end
    end
end

function Auctionmgr.TakeDownProduct()
    if table.size(Auctionmgr.take_down_auction_ids) <= 0 then
        return
    end

    local now_ts = moon.time()
    for auction_id, product_data in pairs(Auctionmgr.take_down_auction_ids) do
        local ret = Database.updateauctionproduct(context.addr_db_game, auction_id,
            { state = AuctionDef.StateType.ON_SALE }, { state = AuctionDef.StateType.TAKE_DOWNING }, true)
        if ret ~= 1 then
            moon.error(string.format("Auctionmgr.TakeDownProduct err = %s", json.pretty_encode(product_data)))
        else
            if product_data.auction_data.buyer_uid then
                -- 给失败的买家退回邮件
                local wait_data = {
                    uid = product_data.auction_data.buyer_uid,
                    auction_id = product_data.auction_id,
                    config_id = product_data.config_id,
                    uniqid = product_data.uniqid,
                    price = product_data.auction_data.cur_price,
                    send_ts = now_ts,
                }
                Database.RedisSetAuctionWaitMail(context.addr_db_redis, wait_data)
                context.send_user(product_data.auction_data.buyer_uid, "Auction.OnAuctionFailMail", wait_data)
            end

            -- 通知卖家商品已下架
            context.send_user(product_data.seller_uid, "Auction.OnAuctionTakeDownMail", product_data,
                AuctionDef.StateType.TAKE_DOWNING, false)
        end
    end
end

function Auctionmgr.AddAuctionLog()
    local short_scope <close> = lock_auction_log()

    if table.size(Auctionmgr.add_auction_logs) == 0 then
        return
    end

    for _, auction_log in pairs(Auctionmgr.add_auction_logs) do
        auction_log.log_id = Auctionmgr.now_log_id
        Database.addauctionlog(context.addr_db_game, auction_log)
        Auctionmgr.now_log_id = Auctionmgr.now_log_id + 1
    end
    for _, trade_log in pairs(Auctionmgr.add_auction_logs) do
        context.send_user(trade_log.seller_uid, "Auction.OnAuctionLogSaleMail", trade_log, true)
        context.send_user(trade_log.buyer_uid, "Auction.OnAuctionLogBuyMail", trade_log)
    end
    Auctionmgr.add_auction_logs = {}
end

function Auctionmgr.AddAuctionProduct(req_data)
    moon.info(string.format("Auctionmgr.AddAuctionProduct req_data = %s", json.pretty_encode(req_data)))
    if not Auctionmgr.load_finish or Auctionmgr.now_auction_id <= 0 then
        return 0
    end
    local product_data = req_data.product_data
    product_data.auction_id = Auctionmgr.now_auction_id
    -- 添加到交易行商品表
    local ret_rows = Database.addauctionproduct(context.addr_db_game, product_data, req_data.condition1,
        req_data.condition2, req_data.condition3, req_data.condition4, req_data.condition5, req_data.custom_conditions1,
        req_data.custom_condition2)
    if ret_rows <= 0 then
        return 0
    end

    local scope <close> = lock_auction_data()

    Auctionmgr.now_auction_id = Auctionmgr.now_auction_id + 1
    Auctionmgr.product_endts[product_data.auction_id] = product_data.end_ts
    if Auctionmgr.min_endts > product_data.end_ts then
        Auctionmgr.min_endts = product_data.end_ts
    end
    Auctionmgr.product_list[product_data.auction_id] = product_data

    -- 添加到redis商品表
    Database.RedisSetAuctionProductData(context.addr_db_redis, product_data)

    return product_data.auction_id
end

function Auctionmgr.BuyAuctionProduct(buyer_uid, auction_id, uniqid, buy_price)
    if not Auctionmgr.load_finish then
        return { code = ErrorCode.TradeProductNotExist }
    end
    
    local auction_cfg = GameCfg.TransactionConfig[2]
    if not auction_cfg then
        return { code = ErrorCode.TradeProductNotExist }
    end

    local scope <close> = lock_auction_data()

    if not Auctionmgr.product_list[auction_id] then
        return {code = ErrorCode.TradeProductNotExist}
    end
    local product_data = Auctionmgr.product_list[auction_id]
    -- 判断价格是否允许,最低价,向上取整
    local floor_price = product_data.auction_data.start_price
    if product_data.auction_data.cur_price > 0 then
        floor_price = math.ceil(product_data.auction_data.cur_price * auction_cfg.bid_percentage / 10000)
    end
    if buy_price < floor_price then
        return { code = ErrorCode.BuyPriceTooLow }
    end
    local real_buy_price = buy_price
    if real_buy_price >= product_data.auction_data.buyout_price then
        real_buy_price = product_data.auction_data.buyout_price
    end

    local now_ts = moon.time()
    -- 记录旧拍卖者,准备退回
    local old_buy_price = product_data.auction_data.cur_price
    local old_buyer_uid = product_data.auction_data.buyer_uid
    -- 更新拍卖数据
    product_data.auction_data.cur_price = real_buy_price
    product_data.auction_data.buyer_uid = buyer_uid
    if real_buy_price == product_data.auction_data.buyout_price then
        product_data.state = AuctionDef.StateType.CLOSE
    end
    if product_data.state == AuctionDef.StateType.ON_SALE
        and product_data.end_ts - now_ts < auction_cfg.auction_deadline
        and product_data.delay_cnt < auction_cfg.auction_postpone_maxtime then
        product_data.end_ts = product_data.end_ts + auction_cfg.postpone_extratime
        product_data.delay_cnt = product_data.delay_cnt + 1
    end

    local function change_auction_record_log()
        local short_scope <close> = lock_auction_log()

        -- 添加交易日志到Auctionmgr.auction_logs
        if product_data.state == AuctionDef.StateType.CLOSE then
            local auction_log = AuctionDef.newAuctionLogData()
            auction_log.auction_id = product_data.auction_id
            auction_log.config_id = product_data.config_id
            auction_log.uniqid = product_data.uniqid
            auction_log.item_data = product_data.item_data
            auction_log.deal_price = product_data.auction_data.cur_price
            auction_log.seller_uid = product_data.seller_uid
            auction_log.buyer_uid = product_data.auction_data.buyer_uid
            auction_log.auction_ts = now_ts
            if auction_cfg.service_charge then
                -- 向上取整
                auction_log.auction_tax = math.ceil(product_data.auction_data.cur_price * auction_cfg.service_charge /
                    10000)
            end
            table.insert(Auctionmgr.add_auction_logs, auction_log)
        end
    end
    change_auction_record_log()

    local update_data = {
        end_ts = product_data.end_ts,
        delay_cnt = product_data.delay_cnt,
        cur_price = product_data.auction_data.cur_price,
        buyer_uid = product_data.auction_data.buyer_uid,
        state = product_data.state,
    }
    Database.updateauctionproduct(context.addr_db_game, product_data.auction_id, nil, update_data, false)
    if product_data.state == AuctionDef.StateType.CLOSE then
        Auctionmgr.product_endts[product_data.auction_id] = nil
        Auctionmgr.product_list[product_data.auction_id] = nil
        -- 删除从redis商品表
        Database.RedisDelAuctionProductData(context.addr_db_redis, { product_data.auction_id })
    else
        -- 修改到redis商品表
        Database.RedisSetAuctionProductData(context.addr_db_redis, product_data)
    end

    -- 给失败的买家退回邮件
    local wait_data = {
        uid = old_buyer_uid,
        auction_id = product_data.auction_id,
        config_id = product_data.config_id,
        uniqid = product_data.uniqid,
        price = old_buy_price,
        send_ts = now_ts,
    }
    Database.RedisSetAuctionWaitMail(context.addr_db_redis, wait_data)
    context.send_user(old_buyer_uid, "Auction.OnAuctionFailMail", wait_data)

    return { code = ErrorCode.None, real_buy_price = real_buy_price }
end

function Auctionmgr.SellerDealAuctionLog(log_id)
    Database.updateauctionlog(context.addr_db_game, log_id, 1, nil)
end

function Auctionmgr.BuyerDealAuctionLog(log_id)
    Database.updateauctionlog(context.addr_db_game, log_id, nil, 1)
end

function Auctionmgr.TakeOffProduct(uid, auction_id)
    local scope <close> = lock_auction_data()

    if Auctionmgr.product_list[auction_id] then
        local product_data = Auctionmgr.product_list[auction_id]
        if product_data.seller_uid ~= uid then
            return ErrorCode.TradeProductNotSeller
        end

        if product_data.auction_data.buyer_uid > 0 then
            local now_ts = moon.time()
            -- 给失败的买家退回邮件
            local wait_data = {
                uid = product_data.auction_data.buyer_uid,
                auction_id = product_data.auction_id,
                config_id = product_data.config_id,
                uniqid = product_data.uniqid,
                price = product_data.auction_data.cur_price,
                send_ts = now_ts,
            }
            Database.RedisSetAuctionWaitMail(context.addr_db_redis, wait_data)
            context.send_user(product_data.auction_data.buyer_uid, "Auction.OnAuctionFailMail", wait_data)
        end

        context.send_user(product_data.seller_uid, "Auction.OnAuctionTakeDownMail", product_data,
            AuctionDef.StateType.ON_SALE, true)

        Auctionmgr.product_list[auction_id] = nil
        Auctionmgr.product_endts[auction_id] = nil
        -- 删除从redis商品表
        Database.RedisDelAuctionProductData(context.addr_db_redis, { auction_id })

        return ErrorCode.None
    end
    
    return ErrorCode.TradeProductNotExist
end

function Auctionmgr.Shutdown()
    -- for _, n in pairs(context.rooms) do
    --     socket.close(n.fd)
    -- end
    if listenfd then
        socket.close(listenfd)
    end
    moon.quit()
    return true
end

return Auctionmgr
