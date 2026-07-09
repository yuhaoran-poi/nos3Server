local moon = require("moon")
local socket = require("moon.socket")
local common = require("common")
local cluster = require("cluster")
local CmdCode = common.CmdCode
local GameCfg = common.GameCfg --游戏配置
local Database = common.Database
local ErrorCode = common.ErrorCode
local lock_bill_check = require("moon.queue")()
local httpc = require("moon.http.client")
local json = require("json")
local crypt = require("crypt")
local protocol = require("common.protocol_pb")
local ProtoEnum = require("tools.ProtoEnum")
local UserAttrLogic = require("common.logic.UserAttrLogic")
local BillDef = require("common.def.BillDef")
local jencode = json.encode
local jdecode = json.decode

---@type seasonmgr_context
local context = ...

local listenfd

local function escape(s)
    return (string.gsub(s, "([^A-Za-z0-9_])", function(c)
        return string.format("%%%02X", string.byte(c))
    end))
end

---@class Seasonmgr
local Seasonmgr = {}

function Seasonmgr.Init()
    -- -- 新增定时器轮询
    moon.async(function()
        while true do
            moon.sleep(10000) -- 每10秒检查一次
            Seasonmgr.CheckSeason()
        end
    end)

    return true
end

function Seasonmgr.Start()
    Seasonmgr.now_season_id = Database.getmaxseasonid(context.addr_db_game)

    return true
end

function Seasonmgr.CheckSeason()
    if not Seasonmgr.now_season_id then
        return
    end
    local now_ts = moon.time()
    local next_season_cfg = GameCfg.Season[Seasonmgr.now_season_id + 1]
    if next_season_cfg and next_season_cfg.open == 1 and now_ts >= next_season_cfg.time then
        if Seasonmgr.now_season_id > 0 and GameCfg.Season[Seasonmgr.now_season_id] then
            local old_season_cfg = GameCfg.Season[Seasonmgr.now_season_id]
            Database.setseasonserverdata(context.addr_db_game, Seasonmgr.now_season_id, old_season_cfg.time, now_ts)
        end

        Seasonmgr.now_season_id = Seasonmgr.now_season_id + 1
        Database.setseasonserverdata(context.addr_db_game, Seasonmgr.now_season_id, now_ts, 0)

        -- 通知排行榜管理器
        moon.info("Seasonmgr.CheckSeason, now_season_id = %d", Seasonmgr.now_season_id)
        cluster.send(3004, "rank", "RankMgr.RefreshSeasonRanks")

        -- 通知所有Gate
        context.broadcast_gate("Gate.SendSeasonChange", Seasonmgr.now_season_id)
    end
end

function Seasonmgr.GetSeasonid()
    if not Seasonmgr.now_season_id then
        return 0
    end
    return Seasonmgr.now_season_id
end

function Seasonmgr.Shutdown()
    -- for _, n in pairs(context.rooms) do
    --     socket.close(n.fd)
    -- end
    if listenfd then
        socket.close(listenfd)
    end
    moon.quit()
    return true
end

return Seasonmgr
