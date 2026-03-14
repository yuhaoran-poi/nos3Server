local LuaExt = require "common.LuaExt"

local BillDef = {
    orderStatus = {
        WAIT  = 0,
        PAID  = 1,
        DONE  = 2,
        FAIL  = 3,
        CLOSE = 4,
        REFUND = 5,
    }
}

local defaultPBBillData = {
    day_bill_amount = 0,
    week_bill_amount = 0,
    month_bill_amount = 0,
    year_bill_amount = 0,
    total_bill_amount = 0,
    update_ts = 0,
    on_order_id = 0,
}

---@return PBBillData
function BillDef.newBillData()
    return LuaExt.const(table.copy(defaultPBBillData))
end

return BillDef
