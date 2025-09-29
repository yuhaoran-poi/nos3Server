local LuaExt = require "common.LuaExt"

local BagDef = {
    BagType = {
        Cangku = "Cangku",
        Consume = "Consume",
        Booty = "Booty",
        Coins = "Coins"
    },
    LogType = {
        ChangeNum = 1,  --变更道具数量
        ChangeInfo = 2, --变更道具信息
        StackItem = 3,  --不同背包堆叠道具
        SplitItem = 4,  --不同背包拆分道具
        MoveItem = 5,   --不同背包移动道具
    },
    -- init_cangku_capacity = 75,
    -- init_consume_capacity = 25,
    -- init_booty_capacity = 20,
    -- max_cangku_capacity = 150,
    -- max_consume_capacity = 50,
    -- max_booty_capacity = 40,
}

local defaultPBBags = {
    [BagDef.BagType.Cangku] = { bag_item_type = 1, capacity = 1, items = {} },
    [BagDef.BagType.Consume] = { bag_item_type = 2, capacity = 1, items = {} },
    [BagDef.BagType.Booty] = { bag_item_type = 3, capacity = 1, items = {} },
}

local defaultPBUserCoins = {
    coins = {}
}

local defaultPBBagLog = {
    uid = 0,
    config_id = 0,
    old_num = 0,
    new_num = 0,
    mod_uniqid = 0,
    del_uniqids = {},
    add_uniqids = {},
    old_item_data = {},
    new_item_data = {},
    change_type = 0,
    change_reason = 0,
    log_ts = 0,
}

---@return PBBags
function BagDef.newBags()
    return LuaExt.const(table.copy(defaultPBBags))
end

---@return PBUserCoins
function BagDef.newPBUserCoins()
    return LuaExt.const(table.copy(defaultPBUserCoins))
end

---@return PBBagLog
function BagDef.newPBBagLog()
    return LuaExt.const(table.copy(defaultPBBagLog))
end

return BagDef
