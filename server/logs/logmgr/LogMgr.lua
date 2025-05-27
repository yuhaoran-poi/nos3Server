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
function LogMgr.ItemChangeLog(uid, item_id, change_num, before_num, after_num, reason, reason_detail)
    -- 参数有效性检查
    if not uid or not item_id or not change_num or not before_num or not after_num then
        moon.error("ItemChangeLog invalid params:", uid, item_id, change_num, before_num, after_num)
        return
    end
    Database.ItemChangeLog(context.addr_db_log, uid, item_id, change_num, before_num, after_num, reason, reason_detail or "")  
end

return LogMgr