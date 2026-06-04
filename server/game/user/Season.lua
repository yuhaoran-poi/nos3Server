local moon = require "moon"
local datetime = require("moon.datetime")
local common = require "common"
local clusterd = require("cluster")
local GameCfg = common.GameCfg
local ErrorCode = common.ErrorCode
local CmdCode = common.CmdCode
local Database = common.Database
local SeasonDef = require("common.def.SeasonDef")
local ItemDefine = require("common.logic.ItemDefine")
local BagDef = require("common.def.BagDef")
local ItemDef = require("common.def.ItemDef")
local RoomDef = require("common.def.RoomDef")
local ProtoEnum = require("tools.ProtoEnum")

---@type user_context
local context = ...
local scripts = context.scripts

---@class Season
local Season = {}

function Season.Init()
    --加载段位数据
    local Season_player_data = Season.LoadSeasonInfo()
    if Season_player_data then
        scripts.UserModel.SetSeasons(Season_player_data)
    end

    local Seasons = scripts.UserModel.GetSeasons()
    if not Seasons then
        local res, err = clusterd.call(3999, "seasonmgr", "Seasonmgr.GetSeasonid")
        if err or not res then
            moon.error(string.format("Season.Init err: %s", err))
            return
        end
        Seasons = SeasonDef.newSeasonPlayerData()
        local cur_season_id = res
        local season_data = SeasonDef.newSeasonData()
        season_data.season_id = cur_season_id
        season_data.season_beg_ts = moon.time()
        Seasons.season_infos[cur_season_id] = season_data
        scripts.UserModel.SetSeasons(Seasons)
    end
end

function Season.Start()
    local Seasons = scripts.UserModel.GetSeasons()
    if not Seasons then
        return
    end

    -- 校验当前赛季
    local res, err = clusterd.call(3999, "seasonmgr", "Seasonmgr.GetSeasonid")
    if err or not res then
        moon.error(string.format("Season.Start err: %s", err))
        return
    end

    if res ~= Seasons.cur_season_id then
        -- 赛季切换
        Season.ChangeSeason(res)
    end

    Season.SaveSeasonsNow()
end

function Season.SaveSeasonsNow()
    local Seasons = scripts.UserModel.GetSeasons()
    if not Seasons then
        return false
    end

    local success = Database.saveseasonsinfo(context.addr_db_user, context.uid, Seasons)
    return success
end

function Season.LoadSeasonInfo()
    local trade_info = Database.loadseasonsinfo(context.addr_db_user, context.uid)
    return trade_info
end

function Season.ChangeSeason(new_season_id)
    local Seasons = scripts.UserModel.GetSeasons()
    if not Seasons or not Seasons.season_infos then
        return
    end
    if Seasons.cur_season_id == new_season_id then
        return
    end

    -- 清空货币
    local coin_count = scripts.Bag.GetCoinCount(SeasonDef.SEASON_COIN)
    if coin_count > 0 then
        local cost_coins = {}
        cost_coins[SeasonDef.SEASON_COIN] = {
            coin_id = SeasonDef.SEASON_COIN,
            coin_count = -coin_count,
        }

        local bag_change_logs = {}
        local err_code_coins = scripts.Bag.DealCoins(cost_coins, bag_change_logs)
        if err_code_coins ~= ErrorCode.None then
            scripts.Bag.RollBackWithChange(bag_change_logs)
            moon.error("Season.ChangeSeason err_code_coins: ", err_code_coins)
        else
            scripts.Bag.SaveAndLog(bag_change_logs, ItemDef.ChangeReason.SeasonEndClear)
        end
    end

    -- 清空镇山之宝
    scripts.AweItem.ResetAllAweItemLevel()

    -- 清空神明等级
    scripts.Gods.SeasonChange()

    -- 清空赛季段位
    scripts.Grade.SeasonChange(new_season_id)

    Seasons.cur_season_id = new_season_id
    Season.SaveSeasonsNow()
end

function Season.AddBattleNum(type_id, battle_num, complete_num, booty_value, game_ts, kill_monster_cnt, chapterid, difficulty)
    local Seasons = scripts.UserModel.GetSeasons()
    if not Seasons or not Seasons.season_infos then
        return
    end
    local season_data = Seasons.season_infos[Seasons.cur_season_id]
    if not season_data then
        return
    end
    if not season_data.battle_num[type_id] then
        season_data.battle_num[type_id] = battle_num
    else
        season_data.battle_num[type_id] = season_data.battle_num[type_id] + battle_num
    end
    if not season_data.battle_complete[type_id] then
        season_data.battle_complete[type_id] = complete_num
    else
        season_data.battle_complete[type_id] = season_data.battle_complete[type_id] + complete_num
    end
    season_data.booty_value = season_data.booty_value + booty_value
    season_data.total_game_ts = season_data.total_game_ts + game_ts
    season_data.kill_monster_cnt = season_data.kill_monster_cnt + kill_monster_cnt

    if complete_num > 0 then
        local now_mode = RoomDef.GameMode.STORY_MODE
        local game_mode_cfgs = GameCfg.GameMode
        if game_mode_cfgs and table.size(game_mode_cfgs) > 0 then
            for _, game_mode_cfg in pairs(game_mode_cfgs) do
                if game_mode_cfg.begin_id <= chapterid and chapterid <= game_mode_cfg.end_id then
                    now_mode = game_mode_cfg.id
                    break
                end
            end

            local is_change = false
            if now_mode == RoomDef.GameMode.STORY_MODE then
                if not Seasons.story_line_record[chapterid] then
                    Seasons.story_line_record[chapterid] = difficulty
                    is_change = true
                else
                    if difficulty > Seasons.story_line_record[chapterid] then
                        Seasons.story_line_record[chapterid] = difficulty
                        is_change = true
                    end
                end
            elseif now_mode == RoomDef.GameMode.GHOST_GATE_MODE then
                if not Seasons.ghost_gate_record[chapterid] then
                    Seasons.ghost_gate_record[chapterid] = difficulty
                    is_change = true
                else
                    if difficulty > Seasons.ghost_gate_record[chapterid] then
                        Seasons.ghost_gate_record[chapterid] = difficulty
                        is_change = true
                    end
                end
            elseif now_mode == RoomDef.GameMode.BOSS_MODE then
                if not Seasons.boss_battle_record[chapterid] then
                    Seasons.boss_battle_record[chapterid] = difficulty
                    is_change = true
                else
                    if difficulty > Seasons.boss_battle_record[chapterid] then
                        Seasons.boss_battle_record[chapterid] = difficulty
                        is_change = true
                    end
                end
            elseif now_mode == RoomDef.GameMode.TOWER_MODE then
                if not Seasons.tower_battle_record[chapterid] then
                    Seasons.tower_battle_record[chapterid] = difficulty
                    is_change = true
                else
                    if difficulty > Seasons.tower_battle_record[chapterid] then
                        Seasons.tower_battle_record[chapterid] = difficulty
                        is_change = true
                    end
                end
            end

            if is_change and context.roomid and context.roomid > 0 then
                clusterd.send(3999, "roommgr", "Roommgr.UpdatePlayerRecord", {
                    roomid = context.roomid,
                    uid = context.uid,
                    records = {
                        story_line_record = Seasons.story_line_record or {},
                        ghost_gate_record = Seasons.ghost_gate_record or {},
                        boss_battle_record = Seasons.boss_battle_record or {},
                        tower_battle_record = Seasons.tower_battle_record or {},
                    },
                })
            end
        end
    end

    Season.SaveSeasonsNow()
end

function Season.GetBattleRecord()
    local Seasons = scripts.UserModel.GetSeasons()
    if not Seasons or not Seasons.season_infos then
        return {
            story_line_record = {},
            ghost_gate_record = {},
            boss_battle_record = {},
            tower_battle_record = {},
        }
    end

    return {
        story_line_record = Seasons.story_line_record,
        ghost_gate_record = Seasons.ghost_gate_record,
        boss_battle_record = Seasons.boss_battle_record,
        tower_battle_record = Seasons.tower_battle_record,
    }
end

function Season.PBGetSeasonPlayerReqCmd(req)
    local Seasons = scripts.UserModel.GetSeasons()
    if not Seasons or not Seasons.season_infos then
        return context.S2C(context.net_id, CmdCode.PBGetSeasonPlayerRspCmd,
            { code = ErrorCode.ServerInternalError, error = "数据加载出错", uid = context.uid }, req.msg_context.stub_id)
    end

    local rsp = {
        code = ErrorCode.None,
        error = "",
        uid = context.uid,
        now_sys_ts = moon.time(),
        season_datas = Seasons,
    }
    return context.S2C(context.net_id, CmdCode.PBGetSeasonPlayerRspCmd, rsp, req.msg_context.stub_id)
end

return Season