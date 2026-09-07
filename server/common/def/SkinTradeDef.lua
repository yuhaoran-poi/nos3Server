local LuaExt = require "common.LuaExt"

local SkinTradeDef = {
    StateType = {
        UNKNOWN = 0,
        ON_SALE = 1,
        TAKE_DOWNING = 2,
        CLOSE = 3,
        TAKE_DOWNED = 4,
    },
    SortDescribe = {
        [1] = "skin_trade_config_id ASC",
        [2] = "skin_trade_config_id DESC",
        [3] = "yes_average_price ASC",
        [4] = "yes_average_price DESC",
        [5] = "last_deal_price ASC",
        [6] = "last_deal_price DESC",
        [7] = "min_price ASC",
        [8] = "min_price DESC",
        [9] = "min_price_num ASC",
        [10] = "min_price_num DESC",
    },
    GM_UID = {
        [10011] = 1,
        [20011] = 1,
        [30011] = 1,
    }
}

local defaultPBSkinTradeData = {
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

local defaultPBSkinTradeProductBaseData = {
    skin_trade_id = 0,
    seller_uid = 0,
    config_id = 0,
    total_num = 0,
    beg_ts = 0,
    end_ts = 0,
    state = SkinTradeDef.StateType.UNKNOWN,
    skin_trade_data = LuaExt.const(table.copy(defaultPBSkinTradeData)),
}

local defaultPBAuctionProductBaseData = {
    skin_trade_id = 0,
    seller_uid = 0,
    item_data = {},
    beg_ts = 0,
    end_ts = 0,
    state = SkinTradeDef.StateType.UNKNOWN,
    auction_data = LuaExt.const(table.copy(defaultPBAuctionData)),
}

local defaultPBSkinTradeLogData = {
    log_id = 0,
    skin_trade_id = 0,
    config_id = 0,
    deal_num = 0,
    deal_price = 0,
    seller_uid = 0,
    buyer_uid = 0,
    skin_trade_ts = 0,
    skin_trade_tax = 0,
    send_mail = 0,
}

local defaultPBAuctionLogData = {
    log_id = 0,
    auction_id = 0,
    item_data = {},
    deal_price = 0,
    seller_uid = 0,
    buyer_uid = 0,
    skin_trade_ts = 0,
    skin_trade_tax = 0,
}

local defaultPBSelfSkinTradeInfo = {
    box_capacity = 0,
    can_onsale_cnt = 0,
    update_ts = 0,
    skin_trade_ids = {},
    log_ids = {},
    focus_id_ts = {},
}

local defaultPBSelfSkinTradeData = {
    simple_info = LuaExt.const(table.copy(defaultPBSelfSkinTradeInfo)),
    product_list = {},
    log_list = {},
}

local defaultPBPriceAndNum = {
    price = 0,
    now_num = 0,
    skin_trade_id_list = {},
}

local defaultPBSkinTradeRecordInfo = {
    skin_trade_config_id = 0,
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

local defaultPBSkinTradeSearchSimpleData = {
    config_id = 0,
    min_price = 0,
    last_deal_price = 0,
    yes_average_price = 0,
    min_price_num = 0,
    now_total_num = 0,
}

local defaultPBSkinTradeSearchData = {
    skin_trade_sim_data = LuaExt.const(table.copy(defaultPBSkinTradeSearchSimpleData)),
    price_to_num = {},
}

---@return PBSkinTradeData
function SkinTradeDef.newSkinTradeData()
    return LuaExt.const(table.copy(defaultPBSkinTradeData))
end

---@return PBAuctionData
function SkinTradeDef.newAuctionData()
    return LuaExt.const(table.copy(defaultPBAuctionData))
end

---@return PBSkinTradeProductBaseData
function SkinTradeDef.newSkinTradeProductBaseData()
    return LuaExt.const(table.copy(defaultPBSkinTradeProductBaseData))
end

---@return PBAuctionProductBaseData
function SkinTradeDef.newAuctionProductBaseData()
    return LuaExt.const(table.copy(defaultPBAuctionProductBaseData))
end

---@return PBSkinTradeLogData
function SkinTradeDef.newSkinTradeLogData()
    return LuaExt.const(table.copy(defaultPBSkinTradeLogData))
end

---@return PBAuctionLogData
function SkinTradeDef.newAuctionLogData()
    return LuaExt.const(table.copy(defaultPBAuctionLogData))
end

---@return PBSelfSkinTradeInfo
function SkinTradeDef.newSelfSkinTradeInfo()
    return LuaExt.const(table.copy(defaultPBSelfSkinTradeInfo))
end

---@return PBSelfSkinTradeData
function SkinTradeDef.newSelfSkinTradeData()
    return LuaExt.const(table.copy(defaultPBSelfSkinTradeData))
end

---@return PBPriceAndNum
function SkinTradeDef.newPriceAndNum()
    return LuaExt.const(table.copy(defaultPBPriceAndNum))
end

---@return PBSkinTradeRecordInfo
function SkinTradeDef.newSkinTradeRecordInfo()
    return LuaExt.const(table.copy(defaultPBSkinTradeRecordInfo))
end

---@return PBSkinTradeSearchSimpleData
function SkinTradeDef.newSkinTradeSearchSimpleData()
    return LuaExt.const(table.copy(defaultPBSkinTradeSearchSimpleData))
end

---@return PBSkinTradeSearchData
function SkinTradeDef.newSkinTradeSearchData()
    return LuaExt.const(table.copy(defaultPBSkinTradeSearchData))
end

return SkinTradeDef
