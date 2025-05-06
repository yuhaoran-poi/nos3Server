local LuaExt = require "common.LuaExt"

local BagDef = {
    BagType = {
        Cangku = "cangku",
        Consume = "consume",
        Booty = "booty",
    },
    init_cangku_capacity = 75,
    init_consume_capacity = 25,
    init_booty_capacity = 20,
    max_cangku_capacity = 150,
    max_consume_capacity = 50,
    max_booty_capacity = 40,
}

local defaultPBBags = {
    [BagDef.BagType.Cangku] = { bag_item_type = 1, capacity = BagDef.init_cangku_capacity, items = {} },
    [BagDef.BagType.Consume] = { bag_item_type = 2, capacity = BagDef.init_consume_capacity, items = {} },
    [BagDef.BagType.Booty] = { bag_item_type = 3, capacity = BagDef.init_booty_capacity, items = {} },
}

---@return PBBags
function BagDef.newBags()
    return LuaExt.const(table.copy(defaultPBBags))
end

return BagDef
