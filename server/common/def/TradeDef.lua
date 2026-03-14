local LuaExt = require "common.LuaExt"

local TradeDef = {
    StateType = {
        UNKNOWN = 0,
        ON_SALE = 1,
        TAKE_DOWNING = 2,
        CLOSE = 3,
        TAKE_DOWNED = 4,
    },
    SortDescribe = {
        [1] = "trade_config_id ASC",
        [2] = "trade_config_id DESC",
        [3] = "yes_average_price ASC",
        [4] = "yes_average_price DESC",
        [5] = "last_deal_price ASC",
        [6] = "last_deal_price DESC",
        [7] = "min_price ASC",
        [8] = "min_price DESC",
        [9] = "min_price_num ASC",
        [10] = "min_price_num DESC",
    },
}

local defaultPBTradeData = {
    single_price = 0,
    sale_num = 0,
    now_num = 0,
}

local defaultPBAuctionData = {
    start_price = 0,
    buyout_price = 0,
    cur_price = 0,
    buyer_uid = 0,
}

local defaultPBTradeProductBaseData = {
    trade_id = 0,
    seller_uid = 0,
    config_id = 0,
    total_num = 0,
    beg_ts = 0,
    end_ts = 0,
    state = TradeDef.StateType.UNKNOWN,
    trade_data = LuaExt.const(table.copy(defaultPBTradeData)),
}

local defaultPBAuctionProductBaseData = {
    trade_id = 0,
    seller_uid = 0,
    item_data = {},
    beg_ts = 0,
    end_ts = 0,
    state = TradeDef.StateType.UNKNOWN,
    auction_data = LuaExt.const(table.copy(defaultPBAuctionData)),
}

local defaultPBTradeLogData = {
    log_id = 0,
    trade_id = 0,
    config_id = 0,
    deal_num = 0,
    deal_price = 0,
    seller_uid = 0,
    buyer_uid = 0,
    trade_ts = 0,
    trade_tax = 0,
    send_mail = 0,
}

local defaultPBAuctionLogData = {
    log_id = 0,
    auction_id = 0,
    item_data = {},
    deal_price = 0,
    seller_uid = 0,
    buyer_uid = 0,
    trade_ts = 0,
    trade_tax = 0,
}

local defaultPBSelfTradeInfo = {
    box_capacity = 0,
    can_onsale_cnt = 0,
    update_ts = 0,
    trade_ids = {},
    log_ids = {},
    focus_id_ts = {},
}

local defaultPBSelfTradeData = {
    simple_info = LuaExt.const(table.copy(defaultPBSelfTradeInfo)),
    product_list = {},
    log_list = {},
}

local defaultPBPriceAndNum = {
    price = 0,
    now_num = 0,
    trade_id_list = {},
}

local defaultPBTradeRecordInfo = {
    trade_config_id = 0,
    sale_num = 0,
    sale_total_price = 0,
    last_deal_price = 0,
    update_ts = 0,
    yes_sale_num = 0,
    yes_sale_total_price = 0,
    yes_average_price = 0,
    min_price = 0,
    min_price_num = 0,
    price_to_num = {},
}

local defaultPBTradeSearchSimpleData = {
    config_id = 0,
    min_price = 0,
    last_deal_price = 0,
    yes_average_price = 0,
    min_price_num = 0,
}

local defaultPBTradeSearchData = {
    trade_sim_data = LuaExt.const(table.copy(defaultPBTradeSearchSimpleData)),
    price_to_num = {},
}

---@return PBTradeData
function TradeDef.newTradeData()
    return LuaExt.const(table.copy(defaultPBTradeData))
end

---@return PBAuctionData
function TradeDef.newAuctionData()
    return LuaExt.const(table.copy(defaultPBAuctionData))
end

---@return PBTradeProductBaseData
function TradeDef.newTradeProductBaseData()
    return LuaExt.const(table.copy(defaultPBTradeProductBaseData))
end

---@return PBAuctionProductBaseData
function TradeDef.newAuctionProductBaseData()
    return LuaExt.const(table.copy(defaultPBAuctionProductBaseData))
end

---@return PBTradeLogData
function TradeDef.newTradeLogData()
    return LuaExt.const(table.copy(defaultPBTradeLogData))
end

---@return PBAuctionLogData
function TradeDef.newAuctionLogData()
    return LuaExt.const(table.copy(defaultPBAuctionLogData))
end

---@return PBSelfTradeInfo
function TradeDef.newSelfTradeInfo()
    return LuaExt.const(table.copy(defaultPBSelfTradeInfo))
end

---@return PBSelfTradeData
function TradeDef.newSelfTradeData()
    return LuaExt.const(table.copy(defaultPBSelfTradeData))
end

---@return PBPriceAndNum
function TradeDef.newPriceAndNum()
    return LuaExt.const(table.copy(defaultPBPriceAndNum))
end

---@return PBTradeRecordInfo
function TradeDef.newTradeRecordInfo()
    return LuaExt.const(table.copy(defaultPBTradeRecordInfo))
end

---@return PBTradeSearchSimpleData
function TradeDef.newTradeSearchSimpleData()
    return LuaExt.const(table.copy(defaultPBTradeSearchSimpleData))
end

---@return PBTradeSearchData
function TradeDef.newTradeSearchData()
    return LuaExt.const(table.copy(defaultPBTradeSearchData))
end

return TradeDef
