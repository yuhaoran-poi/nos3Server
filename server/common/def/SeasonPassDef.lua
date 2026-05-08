local LuaExt = require "common.LuaExt"

local SeasonPassDef = {
}

local defaultPBSeasonPassData = {
    pass_id = 0,
    cost_coin = 0,
    get_reward_id = {},
}

local defaultPBSeasonPassPlayerData = {
    uid = 0,
    season_pass_infos = {},
}

---@return PBSeasonPassData
function SeasonPassDef.newSeasonPassData()
    return LuaExt.const(table.copy(defaultPBSeasonPassData))
end

---@return PBSeasonPassPlayerData
function SeasonPassDef.newSeasonPassPlayerData()
    return LuaExt.const(table.copy(defaultPBSeasonPassPlayerData))
end

return SeasonPassDef
