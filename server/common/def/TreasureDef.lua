local LuaExt = require "common.LuaExt"

local TreasureDef = {
    ChestType = {
        NOLIMIT = 1,
        CONSUME = 2,
    },
}

local defaultPBTreasureSingle = {
    config_id = 0,
    now_count = 0,
    open_count = 0,
    no_guarantee_cnt = 0,
    already_guarantee_cnt = 0,
    get_count = 0,
}

local defaultPBTreasurePlayerData = {
    treasure_list = {},
    total_get_count = 0,
    total_open_count = 0,
}

---@return PBTreasureSingle
function TreasureDef.newTreasureSingle()
    return LuaExt.const(table.copy(defaultPBTreasureSingle))
end

---@return PBTreasurePlayerData
function TreasureDef.newTreasurePlayerData()
    return LuaExt.const(table.copy(defaultPBTreasurePlayerData))
end

return TreasureDef