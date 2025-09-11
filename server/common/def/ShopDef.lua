local LuaExt = require "common.LuaExt"

local ShopDef = {
    ShopQuotaType = {
        NoQuota = 1,
        Forever = 2,
        Day = 3,
        Week = 4,
        Month = 5,
    },
}

local defaultPBShopBuySingle = {
    product_id = 0,
    product_num = 0,
    single_price = {},
    total_price = {},
}

local defaultPBShopBuyLog = {
    log_id = 0,
    buyer_uid = 0,
    buy_ts = 0,
    log_total_price = {},
    buy_data = {},
}

local defaultPBShopPlayerData = {
    uid = 0,
    last_check_ts = 0,
    buy_product_list = {},
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
