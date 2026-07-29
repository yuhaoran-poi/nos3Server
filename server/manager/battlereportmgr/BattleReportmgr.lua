local moon = require("moon")
local socket = require("moon.socket")
local common = require("common")
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

---@type battlereportmgr_context
local context = ...

local listenfd

local function escape(s)
    return (string.gsub(s, "([^A-Za-z0-9_])", function(c)
        return string.format("%%%02X", string.byte(c))
    end))
end

---@class BattleReportmgr
local BattleReportmgr = {}

function BattleReportmgr.Init()
    return true
end

function BattleReportmgr.Start()
    return true
end

function BattleReportmgr.SaveSimpleReport(report_id, report_data)
    Database.RedisSetBattleReportSimple(context.addr_db_redis, report_id, report_data)
end

function BattleReportmgr.DeleteSimpleReport(report_id)
    Database.RedisDelBattleReportSimple(context.addr_db_redis, report_id)
end

function BattleReportmgr.SaveDetailReport(uid, report_id, start_ts, report_data)
    Database.addbattlereport(context.addr_db_game, report_id, uid, start_ts, report_data)
end

function BattleReportmgr.SaveTotalSettleInfo(uid, report_id, start_ts, settle_info)
    settle_info.settle_simple_data = nil
    settle_info.settle_data = nil
    Database.addsettleinfo(context.addr_db_game, report_id, uid, start_ts, settle_info)
end

function BattleReportmgr.Shutdown()
    -- for _, n in pairs(context.rooms) do
    --     socket.close(n.fd)
    -- end
    if listenfd then
        socket.close(listenfd)
    end
    moon.quit()
    return true
end

return BattleReportmgr
