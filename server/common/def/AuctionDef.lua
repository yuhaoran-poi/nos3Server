local LuaExt = require "common.LuaExt"

local AuctionDef = {
    StateType = {
        UNKNOWN = 0,
        ON_SALE = 1,    -- 在售
        TAKE_DOWNING = 2, -- 下架中
        CLOSE = 3, -- 已关闭
        TAKE_DOWNED = 4, -- 已下架
    },
    SortDescribe = {
        [1] = "auction_config_id ASC",
        [2] = "auction_config_id DESC",
        [3] = "end_ts ASC",
        [4] = "end_ts DESC",
        [5] = "cur_price ASC",
        [6] = "cur_price DESC",
        [7] = "buyout_price ASC",
        [8] = "buyout_price DESC",
        [9] = "auction_id ASC",
        [10] = "auction_id DESC",
    },
}

local defaultPBAuctionData = {
    start_price = 0,
    buyout_price = 0,
    cur_price = 0,
    buyer_uid = 0,
}

local defaultPBAuctionProductBaseData = {
    auction_id = 0,
    seller_uid = 0,
    config_id = 0,
    uniqid = 0,
    item_data = {},
    beg_ts = 0,
    end_ts = 0,
    delay_cnt = 0,
    state = AuctionDef.StateType.UNKNOWN,
    auction_data = LuaExt.const(table.copy(defaultPBAuctionData)),
}

local defaultPBAuctionLogData = {
    log_id = 0,
    auction_id = 0,
    config_id = 0,
    uniqid = 0,
    item_data = {},
    deal_price = 0,
    seller_uid = 0,
    buyer_uid = 0,
    auction_ts = 0,
    auction_tax = 0,
    send_seller_mail = 0,
    send_buyer_mail = 0,
}

local defaultPBSelfAuctionInfo = {
    box_capacity = 0,
    can_onsale_cnt = 0,
    update_ts = 0,
    auction_ids = {},
    log_ids = {},
    focus_auctionid_ts = {},
}

local defaultPBSelfAuctionData = {
    simple_info = LuaExt.const(table.copy(defaultPBSelfAuctionInfo)),
    product_list = {},
    log_list = {},
}


---@return PBAuctionData
function AuctionDef.newAuctionData()
    return LuaExt.const(table.copy(defaultPBAuctionData))
end

---@return PBAuctionProductBaseData
function AuctionDef.newAuctionProductBaseData()
    return LuaExt.const(table.copy(defaultPBAuctionProductBaseData))
end

---@return PBAuctionLogData
function AuctionDef.newAuctionLogData()
    return LuaExt.const(table.copy(defaultPBAuctionLogData))
end

---@return PBSelfAuctionInfo
function AuctionDef.newSelfAuctionInfo()
    return LuaExt.const(table.copy(defaultPBSelfAuctionInfo))
end

---@return PBSelfAuctionData
function AuctionDef.newSelfAuctionData()
    return LuaExt.const(table.copy(defaultPBSelfAuctionData))
end

return AuctionDef
