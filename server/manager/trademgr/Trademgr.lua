local moon = require("moon")
local datetime = require("moon.datetime")
local socket = require("moon.socket")
local common = require("common")
local CmdCode = common.CmdCode
local GameCfg = common.GameCfg --游戏配置
local Database = common.Database
local ErrorCode = common.ErrorCode
local lock = require("moon.queue")()
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
local maxplayers = 10

---@class Trademgr
local Trademgr = {
    now_trade_id = 0,
    product_list = {},
    trade_record_infos = {},
}

function Trademgr.Init()
    return 123
end

function Trademgr.Start()
    return true
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

    Trademgr.now_trade_id = Trademgr.now_trade_id + 1
    Trademgr.product_list[ret_id] = product_data.trade_id

    local now_ts = moon.time()
    if not Trademgr.trade_record_infos[product_data.item_data.common_info.config_id] then
        local new_record_data = TradeDef.newTradeRecordInfo()
        new_record_data.trade_config_id = product_data.item_data.common_info.config_id
        new_record_data.update_ts = now_ts
        Trademgr.trade_record_infos[product_data.item_data.common_info.config_id] = new_record_data
    end
    local record_data = Trademgr.trade_record_infos[product_data.item_data.common_info.config_id]
    if not datetime.is_same_day(record_data.update_ts, now_ts) then
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
    Database.updatetraderecord(context.addr_db_game, record_data)
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
    Trademgr.product_list[ret_id] = product_data.trade_id

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
