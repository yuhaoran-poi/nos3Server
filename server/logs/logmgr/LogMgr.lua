--[[
* @file : LogMgr.lua
* @type: single service
* @brief : 日志相关管理服务
* @author : yq
]]

local moon = require "moon"
local uuid = require "uuid"
local coqueue = require "moon.queue"
local common = require "common"
local json = require("json")
local GameDef= common.GameDef
local Database = common.Database
local GameCfg = common.GameCfg --游戏配置
local ErrorCode = common.ErrorCode --逻辑错误码
local CmdCode = common.CmdCode     --客户端通信消息码
 

---@type logmgr_context
local context = ...
local scripts = context.scripts ---方便访问同服务的其它lua模块
 
---@class LogMgr
local LogMgr = {}

function LogMgr.Init()
   context.addr_db_log = moon.queryservice("db_log")
    return true
end

function LogMgr.Start()
   
    return true
end

 
function LogMgr.Shutdown()
    moon.quit()
    return true
end

-- 记录道具变更日志
-- function LogMgr.ItemChangeLog(uid, item_id, change_num, before_num, after_num, reason, reason_detail)
--     -- 参数有效性检查
--     if not uid or not item_id or not change_num or not before_num or not after_num then
--         moon.error("ItemChangeLog invalid params:", uid, item_id, change_num, before_num, after_num)
--         return
--     end
--     Database.ItemChangeLog(context.addr_db_log, uid, item_id, change_num, before_num, after_num, reason, reason_detail or "")  
-- end
function LogMgr.ItemChangeLog(write_log_datas)
    if not write_log_datas then
        moon.error("LogMgr.ItemChangeLog invalid params: no write_log_datas")
        return
    end
    if table.size(write_log_datas) <= 0 then
        moon.error(string.format("LogMgr.ItemChangeLog invalid params: %s", json.pretty_encode(write_log_datas)))
        return
    end
    moon.warn(string.format("LogMgr.ItemChangeLog write_log_datas = %s", json.pretty_encode(write_log_datas)))
    -- write_log_datas 是 dict 形式,转成 list 喂给批量函数(Database.ItemChangeLogList 用 ipairs)
    local list = {}
    for _, log_data in pairs(write_log_datas) do
        list[#list + 1] = log_data
    end
    Database.ItemChangeLogList(context.addr_db_log, list)
end

function LogMgr.RoleChangeLog(write_log_datas)
    if not write_log_datas then
        moon.error("LogMgr.RoleChangeLog invalid params: no write_log_datas")
        return
    end
    if table.size(write_log_datas) <= 0 then
        moon.error(string.format("LogMgr.RoleChangeLog invalid params: %s", json.pretty_encode(write_log_datas)))
        return
    end
    moon.warn(string.format("LogMgr.RoleChangeLog write_log_datas = %s", json.pretty_encode(write_log_datas)))
    local list = {}
    for _, log_data in pairs(write_log_datas) do
        list[#list + 1] = log_data
    end
    Database.RoleChangeLogList(context.addr_db_log, list)
end

return LogMgr