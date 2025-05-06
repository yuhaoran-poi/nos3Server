--[[
* @file : GuildRecord.lua
* @brief : 公会记录
* @author : yq
]]

local moon = require "moon"
local common = require "common"
local cluster = require("cluster")
local GameCfg = common.GameCfg
local ErrorCode = common.ErrorCode
local CmdCode = common.CmdCode
local GuildEnum = require("common.Enum.GuildEnum") --公会枚举
local GuildDef = require("common.def.GuildDef") --公会定义
---@type guild_context
local context = ...
local scripts = context.scripts
local guild_record 
 
 

---@class GuildRecord
local GuildRecord = {}

function GuildRecord.Init()
     return true
end

function GuildRecord.Start()
    return true
end
-- 成员退出公会记录
---@param uid integer 成员UID
function GuildRecord.MemberQuit(uid)
    local record = GuildDef.newPBGuildRecordInfo()
    record.operater_uid = uid
    record.record_type = GuildEnum.EGuildRecordType.eRT_QUIT
    record.record_time = os.time()
    GuildRecord.AddRecord(record)
end
-- 踢出公会成员记录
---@param operater_uid integer 操作人UID
---@param target_uid integer 目标UID
function GuildRecord.ExpelQuit(operater_uid, target_uid)
    local record = GuildDef.newPBGuildRecordInfo()
    record.operater_uid = operater_uid
    record.target_uid = target_uid
    record.record_type = GuildEnum.EGuildRecordType.eRT_EXPEL
    record.record_time = os.time()
    GuildRecord.AddRecord(record)
end
 
-- 成员加入公会记录
---@param uid integer 成员UID
function GuildRecord.MemberJoin(uid)
    local record = GuildDef.newPBGuildRecordInfo()
    record.operater_uid = uid
    record.record_type = GuildEnum.EGuildRecordType.eRT_JOIN
    record.record_time = os.time()
    GuildRecord.AddRecord(record)
    
end

function GuildRecord.AddRecord(record)
    local guild_record = scripts.GuildModel.MutGetGuildRecordDB()
    -- 只保留最新1000条记录
    if #guild_record.record_list >= 1000 then
        table.remove(guild_record.record_list, 1)
    end
    guild_record.record_list[#guild_record.record_list + 1] = record
end

return GuildRecord