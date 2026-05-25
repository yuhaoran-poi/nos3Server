local LuaExt = require "common.LuaExt"

local SeasonDef = {
    SEASON_COIN = 8,
}

local defaultPBSeasonData = {
    season_id = 0,
    battle_num = {},
    battle_complete = {},
    booty_value = 0,
    total_game_ts = 0,
    kill_monster_cnt = 0,
    season_beg_ts = 0,
    season_end_ts = 0,
}

local defaultPBSeasonPlayerData = {
    cur_season_id = 0,
    season_infos = {},
}

---@return PBSeasonData
function SeasonDef.newSeasonData()
    return LuaExt.const(table.copy(defaultPBSeasonData))
end

---@return PBSeasonPlayerData
function SeasonDef.newSeasonPlayerData()
    return LuaExt.const(table.copy(defaultPBSeasonPlayerData))
end

return SeasonDef
