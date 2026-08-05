local moon = require("moon")
local datetime = require("moon.datetime")
local socket = require("moon.socket")
local common = require("common")
local CmdCode = common.CmdCode
local GameCfg = common.GameCfg --游戏配置
local Database = common.Database
local ErrorCode = common.ErrorCode
local lock_trade_data = require("moon.queue")()
local lock_trade_log = require("moon.queue")()
local httpc = require("moon.http.client")
local json = require("json")
local crypt = require("crypt")
local protocol = require("common.protocol_pb")
local TradeDef = require("common.def.TradeDef")
local ProtoEnum = require("tools.ProtoEnum")
local UserAttrLogic = require("common.logic.UserAttrLogic")
local jencode = json.encode
local jdecode = json.decode

---@type trademgr_context
local context = ...

local listenfd
local MAX_SEARCH_NUM = 1000
local GM_UID = 100

---@class Trademgr
local Trademgr = {
    load_finish = false,
    now_trade_id = 0,
    now_log_id = 0,
    product_list = {},          -- 交易行商品简要信息
    trade_record_infos = {},  -- 交易行商品记录
    change_record_ids = {},   -- 交易行商品记录变更
    product_endts = {},       -- 商品id-过期时间
    min_endts = 0,             -- 最近过期时间
    take_down_trade_ids = {}, -- 交易行下架商品id
    change_product_num_state = {}, -- 交易行商品数量状态变更
    add_trade_logs = {},           -- 交易行商品日志添加
    wait_sale_mail_uids = {},    -- 等待发送销售邮件的uid列表
}

function Trademgr.Init()
    -- -- 新增定时器轮询
    moon.async(function()
        while true do
            moon.sleep(3000) -- 每3秒检查一次
            if Trademgr.load_finish then
                Trademgr.CheckEndts()
                Trademgr.UpdateChangeTradeRecords()
                Trademgr.TakeDownProduct()
            end
        end
    end)

    moon.async(function()
        while true do
            moon.sleep(1000) -- 每1秒检查一次
            if Trademgr.load_finish then
                Trademgr.UpdateProductNumState()
                Trademgr.AddTradeLog()
            end
        end
    end)

    return true
end

function Trademgr.Start()
    Trademgr.now_trade_id = Database.getmaxtradeid(context.addr_db_game)
    if Trademgr.now_trade_id < 0 then
        moon.error("Trademgr.Start getmaxtradeid failed")
        return
    end
    if Trademgr.now_trade_id == 0 then
        Trademgr.now_trade_id = 1
    else
        Trademgr.now_trade_id = Trademgr.now_trade_id + 1
    end
    Trademgr.now_log_id = Database.getmaxtradelogid(context.addr_db_game)
    if Trademgr.now_log_id < 0 then
        moon.error("Trademgr.Start getmaxtradelogid failed")
        return
    end
    if Trademgr.now_log_id == 0 then
        Trademgr.now_log_id = 1
    else
        Trademgr.now_log_id = Trademgr.now_log_id + 1
    end

    local now_ts = moon.time()
    -- 从trade_record表中加载trade_record_infos
    local need_mod_record = {}
    local start_config_id = 0
    while true do
        local trade_records = Database.gettraderecordseq(context.addr_db_game, start_config_id, MAX_SEARCH_NUM)
        if not trade_records or table.size(trade_records) <= 0 then
            moon.error("Trademgr.Start gettraderecordseq failed", start_config_id, MAX_SEARCH_NUM)
            break
        end
        for i = 1, table.size(trade_records) do
            local trade_record = trade_records[i]
            if trade_record.trade_config_id > start_config_id then
                start_config_id = trade_record.trade_config_id
            end

            local new_record_data = TradeDef.newTradeRecordInfo()
            new_record_data.trade_config_id = trade_record.trade_config_id
            new_record_data.sale_num = trade_record.sale_num
            new_record_data.sale_total_price = trade_record.sale_total_price
            new_record_data.last_deal_price = trade_record.last_deal_price
            new_record_data.update_ts = trade_record.update_ts
            new_record_data.yes_sale_num = trade_record.yes_sale_num
            new_record_data.yes_sale_total_price = trade_record.yes_sale_total_price
            new_record_data.yes_average_price = trade_record.yes_average_price
            new_record_data.min_price = trade_record.min_price
            new_record_data.min_price_num = trade_record.min_price_num
            Trademgr.trade_record_infos[new_record_data.trade_config_id] = new_record_data

            local item_conf = GameCfg.Item[new_record_data.trade_config_id]
            if item_conf
                and table.size(item_conf.market) >= 5
                and (trade_record.condition1 ~= item_conf.market[1]
                    or trade_record.condition2 ~= item_conf.market[2]
                    or trade_record.condition3 ~= item_conf.market[3]
                    or trade_record.condition4 ~= item_conf.market[4]
                    or trade_record.condition5 ~= item_conf.market[5]) then
                need_mod_record[new_record_data.trade_config_id] = 1
            end
        end

        if table.size(trade_records) < MAX_SEARCH_NUM then
            break
        end
    end

    -- 从trade_product表中加载trade_record_infos中的price_to_num
    local sold_out_trade_ids = {}
    local start_trade_id = 0
    while true do
        local trade_products = Database.gettradeproductwithnum(context.addr_db_game, start_trade_id,
            TradeDef.StateType.ON_SALE, MAX_SEARCH_NUM)
        if not trade_products or table.size(trade_products) <= 0 then
            moon.error("Trademgr.Start gettradeproductwithnum failed", start_trade_id, MAX_SEARCH_NUM)
            break
        end
        for i = 1, table.size(trade_products) do
            local trade_product = trade_products[i]
            if trade_product.trade_id > start_trade_id then
                start_trade_id = trade_product.trade_id
            end

            if trade_product.trade_data.now_num == 0 then
                -- 数量为0，认为是已售罄
                sold_out_trade_ids[trade_product.trade_id] = {
                    sale_num = trade_product.trade_data.sale_num,
                    now_num = trade_product.trade_data.now_num,
                    state = TradeDef.StateType.CLOSE,
                }
            else
                if now_ts >= trade_product.end_ts then
                    -- 已过期，应该下架
                    Trademgr.take_down_trade_ids[trade_product.trade_id] = {
                        config_id = trade_product.config_id,
                        state = TradeDef.StateType.TAKE_DOWNING,
                    }
                else
                    if not Trademgr.trade_record_infos[trade_product.config_id] then
                        local new_record_data = TradeDef.newTradeRecordInfo()
                        new_record_data.trade_config_id = trade_product.config_id
                        new_record_data.update_ts = now_ts
                        Trademgr.trade_record_infos[trade_product.config_id] = new_record_data
                    end
                    local record_data = Trademgr.trade_record_infos[trade_product.config_id]
                    if not record_data.price_to_num[trade_product.trade_data.single_price] then
                        local new_price_data = TradeDef.newPriceAndNum()
                        new_price_data.price = trade_product.trade_data.single_price
                        new_price_data.now_num = 0
                        record_data.price_to_num[new_price_data.price] = new_price_data
                    end
                    local price_data = record_data.price_to_num[trade_product.trade_data.single_price]
                    price_data.now_num = price_data.now_num + trade_product.trade_data.now_num
                    table.insert(price_data.trade_id_list, trade_product.trade_id)
                    if price_data.price < record_data.min_price then
                        -- 更新最低价
                        record_data.min_price = price_data.price
                        need_mod_record[record_data.trade_config_id] = 1
                    end
                    Trademgr.product_endts[trade_product.trade_id] = trade_product.end_ts
                    if Trademgr.min_endts == 0 or Trademgr.min_endts > trade_product.end_ts then
                        Trademgr.min_endts = trade_product.end_ts
                    end
                    Trademgr.product_list[trade_product.trade_id] = {
                        trade_id = trade_product.trade_id,
                        config_id = trade_product.config_id,
                        total_num = trade_product.total_num,
                        seller_uid = trade_product.seller_uid,
                        end_ts = trade_product.end_ts,
                        trade_data = {
                            single_price = trade_product.trade_data.single_price,
                            sale_num = trade_product.trade_data.sale_num,
                            now_num = trade_product.trade_data.now_num,
                        },
                        state = TradeDef.StateType.ON_SALE,
                    }
                end
            end
        end

        if table.size(trade_products) < MAX_SEARCH_NUM then
            break
        end
    end

    -- moon.info(string.format("1 trade_record_infos=%s", json.pretty_encode(Trademgr.trade_record_infos)))
    local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
    local del_product_ids = {}
    for trade_id, sold_out_data in pairs(sold_out_trade_ids) do
        Database.updatetradeproduct(context.addr_db_game, trade_id, nil, sold_out_data, false)
        table.insert(del_product_ids, trade_id)
    end
    if table.size(del_product_ids) > 0 then
        Database.RedisDelProductData(context.addr_db_redis, del_product_ids)
    end

    for config_id, record_data in pairs(Trademgr.trade_record_infos) do
        if not record_data.price_to_num[record_data.min_price] then
            record_data.min_price = 0
            record_data.min_price_num = 0

            for price, price_data in ipairs(record_data.price_to_num) do
                if record_data.min_price == 0 or price < record_data.min_price then
                    record_data.min_price = price
                    record_data.min_price_num = price_data.now_num
                end
            end
        else
            local price_num = record_data.price_to_num[record_data.min_price]
            if record_data.min_price_num ~= price_num.now_num then
                record_data.min_price_num = price_num.now_num
                need_mod_record[config_id] = 1
            end
        end
        if not datetime.is_same_day(record_data.update_ts, now_ts) then
            Trademgr.UpdateSaleNum(record_data, now_ts)
            need_mod_record[config_id] = 1
        end
    end
    for config_id, _ in pairs(need_mod_record) do
        local item_conf = GameCfg.Item[config_id]
        local record_data = Trademgr.trade_record_infos[config_id]
        if record_data and item_conf and table.size(item_conf.market) >= 5
            and item_conf.market[1] and item_conf.market[2] and item_conf.market[3]
            and item_conf.market[4] and item_conf.market[5] then
            moon.debug(string.format("UpdateTradeRecord config_id=%d record_data=%s", config_id, json.pretty_encode(record_data)))
            Database.updatetraderecord(context.addr_db_game, record_data, item_conf.market[1], item_conf.market[2],
                item_conf.market[3], item_conf.market[4], item_conf.market[5])
        end
    end

    Trademgr.load_finish = true
    -- moon.info(string.format("2 trade_record_infos=%s", json.pretty_encode(Trademgr.trade_record_infos)))
    return true
end

function Trademgr.UpdateSaleNum(record_data, now_ts)
    -- 设置昨日售价和销量,清空今日售价和销量
    record_data.yes_sale_num = 0
    record_data.yes_sale_total_price = 0
    record_data.yes_average_price = 0
    if datetime.past_day(record_data.update_ts, now_ts) == 1 then
        record_data.yes_sale_num = record_data.sale_num
        record_data.yes_sale_total_price = record_data.sale_total_price
        if record_data.sale_num > 0 then
            record_data.yes_average_price = record_data.sale_total_price / record_data.sale_num
        end
    end
    record_data.sale_num = 0
    record_data.sale_total_price = 0
    record_data.update_ts = now_ts
end

function Trademgr.ChangeTradeRecord(product_simple_data)
    if not Trademgr.trade_record_infos[product_simple_data.config_id] then
        return
    end
    local record_data = Trademgr.trade_record_infos[product_simple_data.config_id]
    if not record_data.price_to_num[product_simple_data.trade_data.single_price] then
        moon.error(string.format("Trademgr.ChangeTradeRecord price not exist product_simple_data=%s",
            json.pretty_encode(product_simple_data)))
        moon.error(string.format("Trademgr.ChangeTradeRecord price not exist record_data.price_to_num=%s",
            json.pretty_encode(record_data.price_to_num)))
        return
    end
    local price_data = record_data.price_to_num[product_simple_data.trade_data.single_price]
    for idx, cur_trade_id in pairs(price_data.trade_id_list) do
        if cur_trade_id == product_simple_data.trade_id then
            price_data.now_num = price_data.now_num - product_simple_data.trade_data.now_num
            table.remove(price_data.trade_id_list, idx)
            break
        end
    end
    if record_data.min_price == price_data.price then
        record_data.min_price_num = price_data.now_num
        Trademgr.change_record_ids[record_data.trade_config_id] = 1
    end
    if record_data.min_price_num <= 0 then
        record_data.min_price = 0
        record_data.price_to_num[product_simple_data.trade_data.single_price] = nil
        for price, value in pairs(record_data.price_to_num) do
            if record_data.min_price == 0 or record_data.min_price > price then
                record_data.min_price = price
                record_data.min_price_num = value.now_num
            end
        end
        Trademgr.change_record_ids[record_data.trade_config_id] = 1
    end
end

function Trademgr.CheckEndts()
    local now_ts = moon.time()

    local scope <close> = lock_trade_data()

    if now_ts >= Trademgr.min_endts then
        -- local function change_trade_record(product_simple_data)
        --     if not Trademgr.trade_record_infos[product_simple_data.config_id] then
        --         return
        --     end
        --     local record_data = Trademgr.trade_record_infos[product_simple_data.config_id]
        --     if not record_data.price_to_num[product_simple_data.single_price] then
        --         return
        --     end
        --     local price_data = record_data.price_to_num[product_simple_data.single_price]
        --     for idx, cur_trade_id in pairs(price_data.trade_id_list) do
        --         if cur_trade_id == product_simple_data.trade_id then
        --             price_data.now_num = price_data.now_num - product_simple_data.now_num
        --             table.remove(price_data.trade_id_list, idx)
        --             break
        --         end
        --     end
        --     if record_data.min_price == price_data.price then
        --         record_data.min_price_num = price_data.now_num
        --         Trademgr.change_record_ids[record_data.trade_config_id] = 1
        --     end
        --     if record_data.min_price_num <= 0 then
        --         record_data.price_to_num[product_simple_data.single_price] = nil
        --         for price, value in pairs(record_data.price_to_num) do
        --             if record_data.min_price == 0 or record_data.min_price > price then
        --                 record_data.min_price = price
        --                 record_data.min_price_num = value.now_num
        --             end
        --         end
        --         Trademgr.change_record_ids[record_data.trade_config_id] = 1
        --     end
        -- end

        local remove_trade_ids = {}
        for trade_id, end_ts in pairs(Trademgr.product_endts) do
            if now_ts >= end_ts then
                Trademgr.take_down_trade_ids[trade_id] = {
                    config_id = Trademgr.product_list[trade_id].config_id,
                    state = TradeDef.StateType.TAKE_DOWNING,
                }
                table.insert(remove_trade_ids, trade_id)

                if Trademgr.product_list[trade_id] then
                    local product_simple_data = Trademgr.product_list[trade_id]
                    Trademgr.ChangeTradeRecord(product_simple_data)
                    Trademgr.product_list[trade_id] = nil
                end
            else
                if Trademgr.min_endts < now_ts or Trademgr.min_endts > end_ts then
                    Trademgr.min_endts = end_ts
                end
            end
        end
        if table.size(remove_trade_ids) > 0 then
            -- 从redis中删除商品
            Database.RedisDelProductData(context.addr_db_redis, remove_trade_ids)
            for _, trade_id in pairs(remove_trade_ids) do
                Trademgr.product_endts[trade_id] = nil
            end
        end
    end
end

function Trademgr.UpdateChangeTradeRecords()
    local scope <close> = lock_trade_data()

    if table.size(Trademgr.change_record_ids) <= 0 then
        return
    end

    for config_id, _ in pairs(Trademgr.change_record_ids) do
        local item_conf = GameCfg.Item[config_id]
        local record_data = Trademgr.trade_record_infos[config_id]
        if record_data and item_conf and table.size(item_conf.market) >= 5
            and item_conf.market[1] and item_conf.market[2] and item_conf.market[3]
            and item_conf.market[4] and item_conf.market[5] then
            moon.debug(string.format("UpdateTradeRecord config_id=%d record_data=%s", config_id, json.pretty_encode(record_data)))
            Database.updatetraderecord(context.addr_db_game, record_data, item_conf.market[1], item_conf.market[2],
                item_conf.market[3], item_conf.market[4], item_conf.market[5])
        end
    end
    Trademgr.change_record_ids = {}
end

function Trademgr.TakeDownProduct()
    if table.size(Trademgr.take_down_trade_ids) <= 0 then
        return
    end

    local select_num = 0
    local select_trade_ids = {}
    for trade_id, _ in pairs(Trademgr.take_down_trade_ids) do
        table.insert(select_trade_ids, trade_id)
        select_num = select_num + 1
        if select_num > 100 then
            break
        end
    end
    if select_num > 0 then
        local trade_products = Database.gettradeproductwithids(context.addr_db_game, select_trade_ids)
        if trade_products and table.size(trade_products) > 0 then
            local del_trade_ids = {}
            local close_trade_ids = {}
            local take_down_ids = {}
            local take_down_products = {}
            for _, trade_product in pairs(trade_products) do
                table.insert(del_trade_ids, trade_product.trade_id)
                if trade_product.trade_data.now_num == 0 then
                    -- 数量为0，认为是已售罄
                    table.insert(close_trade_ids, trade_product.trade_id)
                else
                    -- 数量不为0，认为是未售罄, 剩余商品返还给卖家
                    table.insert(take_down_ids, trade_product.trade_id)
                    table.insert(take_down_products, trade_product)
                end
            end
            if table.size(close_trade_ids) > 0 then
                Database.updatetradeproductwithids(context.addr_db_game, close_trade_ids,
                    { state = TradeDef.StateType.ON_SALE }, { state = TradeDef.StateType.CLOSE }
                )
            end
            if table.size(take_down_ids) > 0 then
                Database.updatetradeproductwithids(context.addr_db_game, take_down_ids,
                    { state = TradeDef.StateType.ON_SALE }, { state = TradeDef.StateType.TAKE_DOWNING }
                )
            end
            if table.size(del_trade_ids) > 0 then
                for _, trade_id in pairs(del_trade_ids) do
                    Trademgr.take_down_trade_ids[trade_id] = nil
                end
            end
            for _, trade_product in pairs(take_down_products) do
                -- 通知卖家商品已下架
                if trade_product.seller_uid ~= GM_UID then
                    context.send_user(trade_product.seller_uid, "Trade.OnTradeTakeDownMail", trade_product,
                        TradeDef.StateType.TAKE_DOWNING, false)
                end
            end
        end
    end
end

function Trademgr.UpdateProductNumState()
    local short_scope <close> = lock_trade_log()

    if table.size(Trademgr.change_product_num_state) == 0 then
        return
    end

    for trade_id, change_data in pairs(Trademgr.change_product_num_state) do
        Database.updatetradeproduct(context.addr_db_game, trade_id, nil, change_data, false)
    end
    Trademgr.change_product_num_state = {}
end

function Trademgr.AddTradeLog()
    local short_scope <close> = lock_trade_log()

    if table.size(Trademgr.add_trade_logs) == 0 and table.size(Trademgr.wait_sale_mail_uids) == 0 then
        return
    end

    local now_ts = moon.time()
    for _, trade_log in pairs(Trademgr.add_trade_logs) do
        trade_log.log_id = Trademgr.now_log_id
        Database.addtradelog(context.addr_db_game, trade_log)
        Trademgr.now_log_id = Trademgr.now_log_id + 1
    end
    for _, trade_log in pairs(Trademgr.add_trade_logs) do
        if trade_log.seller_uid ~= GM_UID then
            -- context.send_user(trade_log.seller_uid, "Trade.OnTradeLogSaleMail", trade_log, true)
            if not Trademgr.wait_sale_mail_uids[trade_log.seller_uid] then
                Trademgr.wait_sale_mail_uids[trade_log.seller_uid] = now_ts
            end
        end
        context.send_user(trade_log.buyer_uid, "Trade.OnTradeAddLog", trade_log)
    end
    Trademgr.add_trade_logs = {}

    -- 通知已经等待了60*3秒的卖家发送销售邮件
    local already_send_uids = {}
    for uid, wait_ts in pairs(Trademgr.wait_sale_mail_uids) do
        if now_ts - wait_ts >= 60 * 3 then
            context.send_user(uid, "Trade.OnNotifySaleMail")
            table.insert(already_send_uids, uid)
        end
    end
    for _, uid in ipairs(already_send_uids) do
        Trademgr.wait_sale_mail_uids[uid] = nil
    end
end

function Trademgr.GmAddTradeProduct(req_data)
    local item_conf = GameCfg.Item[req_data.product_data.config_id]
    if not item_conf then
        return 0
    end

    req_data.uid = GM_UID
    req_data.product_data.seller_uid = GM_UID
    if table.size(item_conf.market) >= 1 then
        req_data.condition1 = item_conf.market[1]
    end
    if table.size(item_conf.market) >= 2 then
        req_data.condition2 = item_conf.market[2]
    end
    if table.size(item_conf.market) >= 3 then
        req_data.condition3 = item_conf.market[3]
    end
    if table.size(item_conf.market) >= 4 then
        req_data.condition4 = item_conf.market[4]
    end
    if table.size(item_conf.market) >= 5 then
        req_data.condition5 = item_conf.market[5]
    end

    return Trademgr.AddTradeProduct(req_data)
end

function Trademgr.AddTradeProduct(req_data)
    if not Trademgr.load_finish or Trademgr.now_trade_id <= 0 then
        return 0
    end
    local product_data = req_data.product_data
    product_data.trade_id = Trademgr.now_trade_id
    -- 添加到交易行商品表
    local ret_rows = Database.addtradeproduct(context.addr_db_game, product_data, req_data.condition1, req_data.condition2,
        req_data.condition3, req_data.condition4, req_data.condition5)
    if ret_rows <= 0 then
        return 0
    end

    local scope <close> = lock_trade_data()

    Trademgr.now_trade_id = Trademgr.now_trade_id + 1
    Trademgr.product_endts[product_data.trade_id] = product_data.end_ts
    if Trademgr.min_endts > product_data.end_ts then
        Trademgr.min_endts = product_data.end_ts
    end
    Trademgr.product_list[product_data.trade_id] = {
        trade_id = product_data.trade_id,
        config_id = product_data.config_id,
        total_num = product_data.total_num,
        seller_uid = product_data.seller_uid,
        end_ts = product_data.end_ts,
        trade_data = {
            single_price = product_data.trade_data.single_price,
            sale_num = product_data.trade_data.sale_num,
            now_num = product_data.trade_data.now_num,
        },
        state = TradeDef.StateType.ON_SALE,
    }

    local now_ts = moon.time()
    if not Trademgr.trade_record_infos[product_data.config_id] then
        local new_record_data = TradeDef.newTradeRecordInfo()
        new_record_data.trade_config_id = product_data.config_id
        new_record_data.update_ts = now_ts
        Trademgr.trade_record_infos[product_data.config_id] = new_record_data
    end
    local record_data = Trademgr.trade_record_infos[product_data.config_id]
    if not datetime.is_same_day(record_data.update_ts, now_ts) then
        -- 设置昨日售价和销量,清空今日售价和销量
        Trademgr.UpdateSaleNum(record_data, now_ts)
    end

    if not record_data.price_to_num[product_data.trade_data.single_price] then
        local new_price_data = TradeDef.newPriceAndNum()
        new_price_data.price = product_data.trade_data.single_price
        new_price_data.now_num = 0
        record_data.price_to_num[new_price_data.price] = new_price_data
    end
    local price_data = record_data.price_to_num[product_data.trade_data.single_price]
    price_data.now_num = price_data.now_num + product_data.total_num
    table.insert(price_data.trade_id_list, product_data.trade_id)
    if record_data.min_price == 0 or record_data.min_price > price_data.price then
        record_data.min_price = price_data.price
    end
    if record_data.price_to_num[record_data.min_price] then
        record_data.min_price_num = record_data.price_to_num[record_data.min_price].now_num
    else
        moon.error("AddTradeProduct min_price not found", record_data.min_price)
        moon.error(string.format("AddTradeProduct record_data=%s", json.pretty_encode(record_data)))
    end

    -- 添加到交易行商品分类表
    moon.debug(string.format("AddTradeProduct config_id=%d record_data=%s", product_data.config_id, json.pretty_encode(record_data)))
    Database.updatetraderecord(context.addr_db_game, record_data, req_data.condition1, req_data.condition2,
        req_data.condition3, req_data.condition4, req_data.condition5)
    -- 添加到redis商品表
    Database.RedisSetProductData(context.addr_db_redis, product_data)

    return product_data.trade_id
end

function Trademgr.GetTradeRecordInfo(config_id)
    moon.debug("GetTradeRecordInfo config_id", config_id)
    if not Trademgr.load_finish then
        return nil
    end

    local scope <close> = lock_trade_data()

    if not Trademgr.trade_record_infos[config_id] then
        return nil
    end
    moon.debug(string.format("GetTradeRecordInfo Trademgr.trade_record_infos[config_id]=%s", json.pretty_encode(Trademgr.trade_record_infos[config_id])))
    return Trademgr.trade_record_infos[config_id]
end

function Trademgr.BuyTradeProduct(buyer_uid, config_id, buy_num, buy_max_price, lock_coin_num)
    if not Trademgr.load_finish then
        return {code = ErrorCode.TradeProductNotExist}
    end

    local scope <close> = lock_trade_data()

    if not Trademgr.trade_record_infos[config_id] then
        return { code = ErrorCode.TradeProductNotExist }
    end
    local record_info = Trademgr.trade_record_infos[config_id]
    if record_info.min_price > buy_max_price then
        return { code = ErrorCode.TradePriceTooHigh }
    end
    if table.size(record_info.price_to_num) <= 0 then
        return {code = ErrorCode.TradeProductNumZero}
    end
    -- 将当前价格price_to_num进行从低到高排序
    local price_list = {}
    for price, _ in pairs(record_info.price_to_num) do
        table.insert(price_list, price)
    end
    table.sort(price_list)

    -- 从低到高遍历价格, 凑足buy_num数量, 单价不高于buy_max_price, 总价不高于lock_coin_num
    local remain_coin = lock_coin_num
    local total_real_buy_num = 0
    local buy_list = {}
    for _, price in pairs(price_list) do
        if price > buy_max_price or total_real_buy_num >= buy_num then
            break
        end
        local price_data = record_info.price_to_num[price]
        if price_data.now_num > 0 then
            local can_buy_num = math.min(price_data.now_num, math.floor(remain_coin / price))
            can_buy_num = math.min(can_buy_num, buy_num - total_real_buy_num)
            if can_buy_num > 0 then
                for _, trade_id in pairs(price_data.trade_id_list) do
                    local product_data = Trademgr.product_list[trade_id]
                    if product_data and product_data.trade_data.now_num > 0 then
                        local cur_num = math.min(can_buy_num, product_data.trade_data.now_num)
                        table.insert(buy_list, {
                            trade_id = trade_id,
                            seller_uid = product_data.seller_uid,
                            buyer_uid = buyer_uid,
                            price = price,
                            num = cur_num,
                        })
                        total_real_buy_num = total_real_buy_num + cur_num
                        remain_coin = remain_coin - price * cur_num
                        can_buy_num = can_buy_num - cur_num
                    end
                    if can_buy_num <= 0 then
                        break
                    end
                end
            else
                break
            end
        end
    end

    if remain_coin < 0 or total_real_buy_num > buy_num or table.size(buy_list) <= 0 then
        return {code = ErrorCode.TradeBuyError}
    end

    local function change_trade_record_log(product_data, buy_data, now_ts)
        local short_scope <close> = lock_trade_log()

        -- 添加交易变更数据到Trademgr.change_product_num_state
        local change_data = {
            sale_num = product_data.trade_data.sale_num,
            now_num = product_data.trade_data.now_num,
        }
        if product_data.state == TradeDef.StateType.CLOSE then
            change_data.state = TradeDef.StateType.CLOSE
        end
        Trademgr.change_product_num_state[product_data.trade_id] = change_data

        -- 添加交易日志到Trademgr.trade_logs
        local trade_log = TradeDef.newTradeLogData()
        trade_log.trade_id = product_data.trade_id
        trade_log.config_id = product_data.config_id
        trade_log.deal_num = buy_data.num
        trade_log.deal_price = buy_data.price
        trade_log.seller_uid = product_data.seller_uid
        trade_log.buyer_uid = buyer_uid
        trade_log.trade_ts = now_ts
        -- 计算税费
        local trade_cfg = GameCfg.TransactionConfig[1]
        if trade_cfg and trade_cfg.service_charge then
            -- 向上取整
            trade_log.trade_tax = math.ceil(trade_log.deal_price * trade_log.deal_num * trade_cfg.service_charge / 10000)
        end
        table.insert(Trademgr.add_trade_logs, trade_log)
    end
    -- 根据buy_list修改Trademgr.product_list, Trademgr.product_list和record_info数据
    local now_ts = moon.time()
    local is_min_price_sold_out = false
    for _, buy_data in pairs(buy_list) do
        local product_data = Trademgr.product_list[buy_data.trade_id]
        if product_data then
            product_data.trade_data.sale_num = product_data.trade_data.sale_num + buy_data.num
            product_data.trade_data.now_num = product_data.trade_data.now_num - buy_data.num
            if product_data.trade_data.now_num <= 0 then
                product_data.state = TradeDef.StateType.CLOSE
            end

            change_trade_record_log(product_data, buy_data, now_ts)

            record_info.sale_num = record_info.sale_num + buy_data.num
            record_info.sale_total_price = record_info.sale_total_price + buy_data.price * buy_data.num
            record_info.last_deal_price = buy_data.price
            local price_data = record_info.price_to_num[buy_data.price]
            if price_data then
                price_data.now_num = price_data.now_num - buy_data.num
                if price_data.now_num == 0 then
                    is_min_price_sold_out = true
                    record_info.min_price = 0
                    record_info.min_price_num = 0
                    record_info.price_to_num[buy_data.price] = nil
                else
                    is_min_price_sold_out = false
                    record_info.min_price = price_data.price
                    record_info.min_price_num = price_data.now_num
                    if product_data.state == TradeDef.StateType.CLOSE then
                        for idx, trade_id in pairs(price_data.trade_id_list) do
                            if trade_id == buy_data.trade_id then
                                table.remove(price_data.trade_id_list, idx)
                                break
                            end
                        end
                    end
                end
            end

            if product_data.state == TradeDef.StateType.CLOSE then
                Trademgr.product_endts[buy_data.trade_id] = nil
                Trademgr.product_list[buy_data.trade_id] = nil
                -- 从redis中删除商品
                Database.RedisDelProductData(context.addr_db_redis, { buy_data.trade_id })
            else
                -- 修改redis中的商品，转换为嵌套格式
                -- local redis_product_data = {
                --     trade_id = product_data.trade_id,
                --     config_id = product_data.config_id,
                --     total_num = product_data.total_num,
                --     seller_uid = product_data.seller_uid,
                --     end_ts = product_data.end_ts,
                --     trade_data = {
                --         single_price = product_data.trade_data.single_price,
                --         sale_num = product_data.trade_data.sale_num,
                --         now_num = product_data.trade_data.now_num,
                --     },
                --     state = product_data.state,
                -- }
                -- Database.RedisSetProductData(context.addr_db_redis, redis_product_data)
                Database.RedisSetProductData(context.addr_db_redis, product_data)
            end
        end
    end
    -- 修改交易行商品分类表
    if is_min_price_sold_out then
        for price, price_data in pairs(record_info.price_to_num) do
            if record_info.min_price == 0 or record_info.min_price > price then
                record_info.min_price = price
                record_info.min_price_num = price_data.now_num
            end
        end
    end
    local item_conf = GameCfg.Item[config_id]
    if item_conf and table.size(item_conf.market) >= 5
        and item_conf.market[1] and item_conf.market[2] and item_conf.market[3]
        and item_conf.market[4] and item_conf.market[5] then
        moon.debug(string.format("UpdateTradeRecord config_id=%d record_info=%s", config_id, json.pretty_encode(record_info)))
        Database.updatetraderecord(context.addr_db_game, record_info, item_conf.market[1], item_conf.market[2],
            item_conf.market[3], item_conf.market[4], item_conf.market[5])
    end

    local res = {
        total_real_buy_num = total_real_buy_num,
        remain_coin = remain_coin,
        buy_list = buy_list,
    }
    return {code = ErrorCode.None, data = res}
end

function Trademgr.UserDealTradeLog(log_id)
    Database.updatetradelog(context.addr_db_game, log_id, 1)
end

function Trademgr.UserDealTradeLogList(log_ids)
    Database.updatetradeloglist(context.addr_db_game, log_ids, 1)
end

function Trademgr.NotifyAlreadySendSaleMail(seller_uid)
    local short_scope <close> = lock_trade_log()

    moon.info("NotifyAlreadySendSaleMail seller_uid", seller_uid)
    Trademgr.wait_sale_mail_uids[seller_uid] = nil
end

function Trademgr.TakeOffProduct(uid, trade_id)
    local scope <close> = lock_trade_data()

    if Trademgr.product_list[trade_id] then
        moon.debug(string.format("TakeOffProduct trade_id=%d", trade_id))
        local product_simple_data = Trademgr.product_list[trade_id]
        if product_simple_data.seller_uid ~= uid then
            return ErrorCode.TradeProductNotSeller
        end
        Trademgr.ChangeTradeRecord(product_simple_data)
        Trademgr.product_list[trade_id] = nil
        Trademgr.product_endts[trade_id] = nil
        -- 从redis中删除商品
        Database.RedisDelProductData(context.addr_db_redis, {trade_id})

        local trade_products = Database.gettradeproductwithids(context.addr_db_game, { trade_id })
        if trade_products and #trade_products == 1 then
            local trade_product = trade_products[1]
            -- GM_UID不会主动下架
            context.send_user(trade_product.seller_uid, "Trade.OnTradeTakeDownMail", trade_product,
                TradeDef.StateType.ON_SALE, true)
            return ErrorCode.None
        end
    end
    
    return ErrorCode.TradeProductNotExist
end

-- function Trademgr.AddAuctionProduct(req_data)
--     if Trademgr.now_trade_id <= 0 then
--         return 0
--     end
--     local product_data = req_data.product_data
--     product_data.trade_id = Trademgr.now_trade_id

--     -- 添加到拍卖行商品表
--     local ret_id = Database.addauctionproduct(context.addr_db_game, product_data, req_data.condition1, req_data.condition2,
--         req_data.condition3, req_data.condition4, req_data.condition5, req_data.custome_condition)
--     if ret_id <= 0 then
--         return 0
--     end

--     Trademgr.now_trade_id = Trademgr.now_trade_id + 1
--     Trademgr.product_endts[ret_id] = product_data.end_ts

--     -- 添加到redis商品表
--     Database.RedisSetProductData(context.addr_db_redis, product_data)

--     return product_data.trade_id
-- end

-- function Trademgr.SetSystemTradeDetail(trade_info)
--     Database.RedisSetSystemTradesInfo(context.addr_db_redis, trade_info)
-- end

-- function Trademgr.DelSystemTradeDetail(trade_id)
--     Database.RedisDelSystemTradesInfo(context.addr_db_redis, trade_id)
-- end

-- function Trademgr.AddSystemTrade(system_info)
--     local ret_id = Database.add_system_trade(context.addr_db_game, system_info.trade_data, system_info.all_user,
--     system_info.recv_uids)
--     if ret_id <= 0 then
--         return {success = false, id = ret_id}
--     end

--     system_info.trade_data.simple_data.trade_id = ret_id
--     Trademgr.SetSystemTradeDetail(system_info.trade_data)

--     -- 通知所有Gate
--     context.broadcast_gate("Gate.SendSystemTrade", system_info.trade_data)

--     return { success = true, id = ret_id }
-- end

-- function Trademgr.InvalidSystemTrade(trade_id)
--     local ret = Database.invalid_system_trade(context.addr_db_game, trade_id)
--     if ret <= 0 then
--         return false
--     end

--     Trademgr.DelSystemTradeDetail(trade_id)

--     -- 通知所有Gate
--     context.broadcast_gate("Gate.InvalidSystemTrade", trade_id)

--     return true
-- end

function Trademgr.Shutdown()
    -- for _, n in pairs(context.rooms) do
    --     socket.close(n.fd)
    -- end
    if listenfd then
        socket.close(listenfd)
    end
    moon.quit()
    return true
end

return Trademgr
