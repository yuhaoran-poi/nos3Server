local moon = require("moon")
local datetime = require("moon.datetime")
local socket = require("moon.socket")
local common = require("common")
local CmdCode = common.CmdCode
local GameCfg = common.GameCfg --游戏配置
local Database = common.Database
local ErrorCode = common.ErrorCode
local lock_trade = require("moon.queue")()
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

---@class Trademgr
local Trademgr = {
    now_trade_id = 0,
    product_list = {},          -- 交易行商品简要信息
    trade_record_infos = {},  -- 交易行商品记录
    change_record_ids = {},   -- 交易行商品记录变更
    product_endts = {},       -- 商品id-过期时间
    min_endts = 0,             -- 最近过期时间
    take_down_trade_ids = {},   -- 交易行下架商品id
}

function Trademgr.Init()
    return 123
end

function Trademgr.Start()
    -- local now_ts = moon.time()
    -- -- 从trade_record表中加载trade_record_infos
    -- local need_mod_record = {}
    -- local start_config_id = 0
    -- while true do
    --     local trade_records = Database.gettraderecordseq(context.addr_db_game, start_config_id, MAX_SEARCH_NUM)
    --     if not trade_records or table.size(trade_records) <= 0 then
    --         moon.error("Trademgr.Start gettraderecordseq failed", start_config_id, MAX_SEARCH_NUM)
    --         break
    --     end
    --     for i = 1, table.size(trade_records) do
    --         local trade_record = trade_records[i]
    --         if trade_record.trade_config_id > start_config_id then
    --             start_config_id = trade_record.trade_config_id
    --         end

    --         local new_record_data = TradeDef.newTradeRecordInfo()
    --         new_record_data.trade_config_id = trade_record.trade_config_id
    --         new_record_data.sale_num = trade_record.sale_num
    --         new_record_data.sale_total_price = trade_record.sale_total_price
    --         new_record_data.last_deal_price = trade_record.last_deal_price
    --         new_record_data.update_ts = trade_record.update_ts
    --         new_record_data.yes_sale_num = trade_record.yes_sale_num
    --         new_record_data.yes_sale_total_price = trade_record.yes_sale_total_price
    --         new_record_data.yes_average_price = trade_record.yes_average_price
    --         new_record_data.min_price = trade_record.min_price
    --         new_record_data.min_price_num = trade_record.min_price_num
    --         Trademgr.trade_record_infos[new_record_data.trade_config_id] = new_record_data

    --         local item_conf = GameCfg.Item[new_record_data.trade_config_id]
    --         if item_conf
    --             and (trade_record.condition1 ~= item_conf.type1
    --                 or trade_record.condition2 ~= item_conf.type2
    --                 or trade_record.condition3 ~= item_conf.type3
    --                 or trade_record.condition4 ~= item_conf.type4
    --                 or trade_record.condition5 ~= item_conf.type5) then
    --             need_mod_record[new_record_data.trade_config_id] = 1
    --         end
    --     end

    --     if table.size(trade_records) < MAX_SEARCH_NUM then
    --         break
    --     end
    -- end

    -- -- 从trade_product表中加载trade_record_infos中的price_to_num
    -- local sold_out_trade_ids = {}
    -- local start_trade_id = 0
    -- while true do
    --     local trade_products = Database.gettradeproductnoitemdata(context.addr_db_game, start_trade_id,
    --         TradeDef.StateType.ON_SALE, MAX_SEARCH_NUM)
    --     if not trade_products or table.size(trade_products) <= 0 then
    --         moon.error("Trademgr.Start gettradeproductnoitemdata failed", start_trade_id, MAX_SEARCH_NUM)
    --         break
    --     end
    --     for i = 1, table.size(trade_products) do
    --         local trade_product = trade_products[i]
    --         if trade_product.trade_id > start_trade_id then
    --             start_trade_id = trade_product.trade_id
    --         end

    --         if trade_product.trade_data.now_num == 0 then
    --             -- 数量为0，认为是已售罄
    --             sold_out_trade_ids[trade_product.trade_id] = {
    --                 sale_num = trade_product.trade_data.sale_num,
    --                 now_num = trade_product.trade_data.now_num,
    --                 state = TradeDef.StateType.CLOSE,
    --             }
    --         else
    --             if now_ts >= trade_product.trade_data.end_ts then
    --                 -- 已过期，应该下架
    --                 Trademgr.take_down_trade_ids[trade_product.trade_id] = {
    --                     config_id = trade_product.config_id,
    --                     state = TradeDef.StateType.TAKE_DOWN,
    --                 }
    --             else
    --                 if not Trademgr.trade_record_infos[trade_product.config_id] then
    --                     local new_record_data = TradeDef.newTradeRecordInfo()
    --                     new_record_data.trade_config_id = trade_product.config_id
    --                     new_record_data.update_ts = now_ts
    --                     Trademgr.trade_record_infos[trade_product.config_id] = new_record_data
    --                 end
    --                 local record_data = Trademgr.trade_record_infos[trade_product.config_id]
    --                 if not record_data.price_to_num[trade_product.trade_data.single_price] then
    --                     local new_price_data = TradeDef.newPriceAndNum()
    --                     new_price_data.price = trade_product.trade_data.single_price
    --                     new_price_data.now_num = 0
    --                     record_data.price_to_num[new_price_data.price] = new_price_data
    --                 end
    --                 local price_data = record_data.price_to_num[trade_product.trade_data.single_price]
    --                 price_data.now_num = price_data.now_num + trade_product.trade_data.now_num
    --                 table.insert(price_data.trade_id_list, trade_product.trade_id)
    --                 if price_data.price < record_data.min_price then
    --                     -- 更新最低价
    --                     record_data.min_price = price_data.price
    --                     need_mod_record[record_data.trade_config_id] = 1
    --                 end
    --                 Trademgr.product_endts[trade_product.trade_id] = trade_product.end_ts
    --                 Trademgr.product_list[trade_product.trade_id] = {
    --                     trade_id = trade_product.trade_id,
    --                     config_id = trade_product.config_id,
    --                     end_ts = trade_product.end_ts,
    --                     single_price = trade_product.trade_data.single_price,
    --                     sale_num = trade_product.trade_data.sale_num,
    --                     now_num = trade_product.trade_data.now_num,
    --                     state = TradeDef.StateType.ON_SALE,
    --                 }
    --             end
    --         end
    --     end

    --     if table.size(trade_products) < MAX_SEARCH_NUM then
    --         break
    --     end
    -- end

    -- local del_product_ids = {}
    -- for trade_id, sold_out_data in pairs(sold_out_trade_ids) do
    --     Database.updatetradeproduct(context.addr_db_game, trade_id, sold_out_data)
    --     table.insert(del_product_ids, trade_id)
    -- end
    -- if table.size(del_product_ids) > 0 then
    --     Database.RedisDelProductData(context.addr_db_redis, del_product_ids)
    -- end

    -- for config_id, record_data in pairs(Trademgr.trade_record_infos) do
    --     local price_num = record_data.price_to_num[record_data.min_price]
    --     if record_data.min_price_num ~= price_num.now_num then
    --         record_data.min_price_num = price_num.now_num
    --         need_mod_record[config_id] = 1
    --     end
    --     if not datetime.is_same_day(record_data.update_ts, now_ts) then
    --         record_data.yes_sale_num = 0
    --         record_data.yes_sale_total_price = 0
    --         record_data.yes_average_price = 0
    --         if datetime.past_day(record_data.update_ts, now_ts) == 1 then
    --             record_data.yes_sale_num = record_data.sale_num
    --             record_data.yes_sale_total_price = record_data.sale_total_price
    --             record_data.yes_average_price = record_data.sale_total_price / record_data.sale_num
    --         end
    --         record_data.sale_num = 0
    --         record_data.sale_total_price = 0
    --         record_data.update_ts = now_ts
    --         need_mod_record[config_id] = 1
    --     end
    -- end
    -- for config_id, _ in pairs(need_mod_record) do
    --     local item_conf = GameCfg.Item[config_id]
    --     local record_data = Trademgr.trade_record_infos[config_id]
    --     if record_data and item_conf and item_conf.type1 and item_conf.type2
    --         and item_conf.type3 and item_conf.type4 and item_conf.type5 then
    --         Database.updatetraderecord(context.addr_db_game, record_data, item_conf.type1, item_conf.type2,
    --             item_conf.type3, item_conf.type4, item_conf.type5)
    --     end
    -- end

    return true
end

function Trademgr.CheckEndts()
    local now_ts = moon.time()

    local scope <close> = lock_trade()
    if now_ts >= Trademgr.min_endts then
        local function change_trade_record(product_simple_data)
            if not Trademgr.trade_record_infos[product_simple_data.config_id] then
                return
            end
            local record_data = Trademgr.trade_record_infos[product_simple_data.config_id]
            if not record_data.price_to_num[product_simple_data.single_price] then
                return
            end
            local price_data = record_data.price_to_num[product_simple_data.single_price]
            for idx, cur_trade_id in pairs(price_data.trade_id_list) do
                if cur_trade_id == product_simple_data.trade_id then
                    price_data.now_num = price_data.now_num - product_simple_data.now_num
                    table.remove(price_data.trade_id_list, idx)
                    break
                end
            end
            if record_data.min_price == price_data.price then
                record_data.min_price_num = price_data.now_num
                record_data.update_ts = now_ts
                Trademgr.change_record_ids[record_data.trade_config_id] = 1
            end
            if record_data.min_price_num <= 0 then
                record_data.price_to_num[product_simple_data.single_price] = nil
                for price, value in pairs(record_data.price_to_num) do
                    if record_data.min_price == 0 or record_data.min_price > price then
                        record_data.min_price = price
                        record_data.min_price_num = value.now_num
                    end
                end
                record_data.update_ts = now_ts
                Trademgr.change_record_ids[record_data.trade_config_id] = 1
            end
        end

        local del_trade_ids = {}
        for trade_id, end_ts in pairs(Trademgr.product_endts) do
            if now_ts >= end_ts then
                Trademgr.take_down_trade_ids[trade_id] = {
                    config_id = Trademgr.product_list[trade_id].config_id,
                    state = TradeDef.StateType.TAKE_DOWN,
                }
                table.insert(del_trade_ids, trade_id)

                if Trademgr.product_list[trade_id] then
                    local product_simple_data = Trademgr.product_list[trade_id]
                    change_trade_record(product_simple_data)
                    Trademgr.product_list[trade_id] = nil
                end
            else
                if Trademgr.min_endts < now_ts or Trademgr.min_endts > end_ts then
                    Trademgr.min_endts = end_ts
                end
            end
        end
        for _, trade_id in pairs(del_trade_ids) do
            Trademgr.product_endts[trade_id] = nil
        end
    end
end

function Trademgr.UpdateChangeTradeRecords()
    if table.size(Trademgr.change_record_ids) <= 0 then
        return
    end

    for config_id, _ in pairs(Trademgr.change_record_ids) do
        local item_conf = GameCfg.Item[config_id]
        local scope <close> = lock_trade()
        local record_data = Trademgr.trade_record_infos[config_id]
        if record_data and item_conf and item_conf.type1 and item_conf.type2
            and item_conf.type3 and item_conf.type4 and item_conf.type5 then
            Database.updatetraderecord(context.addr_db_game, record_data, item_conf.type1, item_conf.type2,
                item_conf.type3, item_conf.type4, item_conf.type5)
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
            for _, trade_product in pairs(trade_products) do
                table.insert(del_trade_ids, trade_product.trade_id)
                if trade_product.trade_data.now_num == 0 then
                    -- 数量为0，认为是已售罄
                    Database.updatetradeproduct(context.addr_db_game, trade_product.trade_id, {
                        state = TradeDef.StateType.CLOSE,
                    })
                else
                    -- 数量不为0，认为是未售罄, 剩余商品返还给卖家
                    Database.updatetradeproduct(context.addr_db_game, trade_product.trade_id, {
                        state = TradeDef.StateType.TAKE_DOWN,
                    })

                    -- 发送邮件

                end
            end
            if table.size(del_trade_ids) > 0 then
                for _, trade_id in pairs(del_trade_ids) do
                    Trademgr.take_down_trade_ids[trade_id] = nil
                end
                Database.RedisDelProductData(context.addr_db_redis, del_trade_ids)
            end
        end
    end
end

function Trademgr.GetPlayerTradeLog()

end

function Trademgr.AddTradeProduct(req_data)
    if Trademgr.now_trade_id <= 0 then
        return 0
    end
    local product_data = req_data.product_data
    product_data.trade_id = Trademgr.now_trade_id
    -- 添加到交易行商品表
    local ret_id = Database.addtradeproduct(context.addr_db_game, product_data, req_data.condition1, req_data.condition2,
        req_data.condition3, req_data.condition4, req_data.condition5)
    if ret_id <= 0 then
        return 0
    end

    local scope <close> = lock_trade()

    Trademgr.now_trade_id = Trademgr.now_trade_id + 1
    Trademgr.product_endts[ret_id] = product_data.end_ts
    Trademgr.product_list[ret_id] = {
        trade_id = ret_id,
        config_id = product_data.config_id,
        end_ts = product_data.end_ts,
        single_price = product_data.trade_data.single_price,
        sale_num = product_data.trade_data.sale_num,
        now_num = product_data.trade_data.now_num,
        state = TradeDef.StateType.ON_SALE,
    }

    local now_ts = moon.time()
    if not Trademgr.trade_record_infos[product_data.item_data.common_info.config_id] then
        local new_record_data = TradeDef.newTradeRecordInfo()
        new_record_data.trade_config_id = product_data.item_data.common_info.config_id
        new_record_data.update_ts = now_ts
        Trademgr.trade_record_infos[product_data.item_data.common_info.config_id] = new_record_data
    end
    local record_data = Trademgr.trade_record_infos[product_data.item_data.common_info.config_id]
    if not datetime.is_same_day(record_data.update_ts, now_ts) then
        -- 设置昨日售价和销量,清空今日售价和销量
        record_data.yes_sale_num = 0
        record_data.yes_sale_total_price = 0
        record_data.yes_average_price = 0
        if datetime.past_day(record_data.update_ts, now_ts) == 1 then
            record_data.yes_sale_num = record_data.sale_num
            record_data.yes_sale_total_price = record_data.sale_total_price
            record_data.yes_average_price = record_data.sale_total_price / record_data.sale_num
        end
        record_data.sale_num = 0
        record_data.sale_total_price = 0
    end
    record_data.update_ts = now_ts

    if not record_data.price_to_num[product_data.trade_data.single_price] then
        local new_price_data = TradeDef.newPriceAndNum()
        new_price_data.price = product_data.trade_data.single_price
        new_price_data.now_num = 0
        record_data.price_to_num[new_price_data.price] = new_price_data
    end
    local price_data = record_data.price_to_num[product_data.trade_data.single_price]
    price_data.now_num = price_data.now_num + product_data.item_data.item_count
    table.insert(price_data.trade_id_list, product_data.trade_id)
    if record_data.min_price == 0 or record_data.min_price > price_data.price then
        record_data.min_price = price_data.price
    end
    record_data.min_price_num = record_data.price_to_num[record_data.min_price].now_num

    -- 添加到交易行商品分类表
    Database.updatetraderecord(context.addr_db_game, record_data, req_data.condition1, req_data.condition2,
        req_data.condition3, req_data.condition4, req_data.condition5)
    -- 添加到redis商品表
    Database.RedisSetProductData(context.addr_db_redis, product_data)

    return product_data.trade_id
end

function Trademgr.AddAuctionProduct(req_data)
    if Trademgr.now_trade_id <= 0 then
        return 0
    end
    local product_data = req_data.product_data
    product_data.trade_id = Trademgr.now_trade_id

    -- 添加到拍卖行商品表
    local ret_id = Database.addauctionproduct(context.addr_db_game, product_data, req_data.condition1, req_data.condition2,
        req_data.condition3, req_data.condition4, req_data.condition5, req_data.custome_condition)
    if ret_id <= 0 then
        return 0
    end

    Trademgr.now_trade_id = Trademgr.now_trade_id + 1
    Trademgr.product_endts[ret_id] = product_data.end_ts

    -- 添加到redis商品表
    Database.RedisSetProductData(context.addr_db_redis, product_data)

    return product_data.trade_id
end

function Trademgr.SetSystemTradeDetail(trade_info)
    Database.RedisSetSystemTradesInfo(context.addr_db_redis, trade_info)
end

function Trademgr.DelSystemTradeDetail(trade_id)
    Database.RedisDelSystemTradesInfo(context.addr_db_redis, trade_id)
end

function Trademgr.AddSystemTrade(system_info)
    local ret_id = Database.add_system_trade(context.addr_db_game, system_info.trade_data, system_info.all_user,
    system_info.recv_uids)
    if ret_id <= 0 then
        return {success = false, id = ret_id}
    end

    system_info.trade_data.simple_data.trade_id = ret_id
    Trademgr.SetSystemTradeDetail(system_info.trade_data)

    -- 通知所有Gate
    context.broadcast_gate("Gate.SendSystemTrade", system_info.trade_data)

    return { success = true, id = ret_id }
end

function Trademgr.InvalidSystemTrade(trade_id)
    local ret = Database.invalid_system_trade(context.addr_db_game, trade_id)
    if ret <= 0 then
        return false
    end

    Trademgr.DelSystemTradeDetail(trade_id)

    -- 通知所有Gate
    context.broadcast_gate("Gate.InvalidSystemTrade", trade_id)

    return true
end

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
