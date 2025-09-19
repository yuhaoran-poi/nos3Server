local LuaExt = require "common.LuaExt"

local ShopDef = {
    ShopQuotaType = {
        NoQuota = 1,
        Forever = 2,
        Day = 3,
        Week = 4,
        Month = 5,
    },
    ShopLimitType = {
        NoLimit = 1,
        ServerLimit = 2,
    },
    ShopConfigId = {
        DayFreshSeconds = 1,
        WeekFreshSeconds = 2,
        MonthFreshSeconds = 3,
        BuyCarKindMax = 4,
        ShopMailId = 5,
        RechargeMailId = 6,
        BuyLogMax = 7,
        BuyCarNumMax = 8,
    }
}

local defaultPBShopBuySingle = {
    product_id = 0,
    product_num = 0,
    single_price = {},
    total_price = {},
}

local defaultPBShopBuyLog = {
    order_id = 0,
    buyer_uid = 0,
    buy_ts = 0,
    log_total_price = {},
    buy_data = {},
}

local defaultPBShopPlayerData = {
    uid = 0,
    last_check_ts = 0,
    self_order_id = 0,
    buy_product_list = {},
    buy_car_data = {},
    shop_logs = {},
}

---@return PBShopBuySingle
function ShopDef.newShopBuySingle()
    return LuaExt.const(table.copy(defaultPBShopBuySingle))
end

---@return PBShopBuyLog
function ShopDef.newShopBuyLog()
    return LuaExt.const(table.copy(defaultPBShopBuyLog))
end

---@return PBShopPlayerData
function ShopDef.newShopPlayerData()
    return LuaExt.const(table.copy(defaultPBShopPlayerData))
end

return ShopDef
