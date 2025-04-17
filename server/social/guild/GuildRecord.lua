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
local GuildEnum = require("common.GuildEnum") --公会枚举
---@type guild_context
local context = ...
local scripts = context.scripts
local guild_record 
--公会记录信息 
---@class defaultGuildRecordInfoClass
local defaultGuildRecordInfoClass = {
	record_type = 0,		--记录类型
	nickname = "",			--目标玩家昵称
	record_time = 0,		--记录时间;
	duty_name = "",			--只在 eRT_DUTY_CHANGE 有用（表示职位名称)
	guild_level = 0,        --只在 eRT_GUILD_LV_UP 有用
	guild_name = "",	    --只在 eRT_CHANGE_GUILD_NAME 有用
	target_uid = 0,			--目标玩家UID
	duty_id = 0,			--只在 eRT_DUTY_CHANGE 有用 （表示职位ID)
	gkd_change_num = 0,     --eRT_GuildGKD变化记录 ,  
	gkd_cur_num    = 0,     --eRT_GuildGKD GKD当前值
	gkd_desc = "",          --eRT_GuildGKD 备注
	item_id = 0,            --只在ERT_JUANZENG时使用
	gubi_num = 0,           --只在ERT_JUANZENG时使用，古币数量
	contribute = 0,         --贡献值
	spoils_item = {},       --只在战利品发放时使用，物品id
	season_point = 0,       --只在ERT_SEASON_POINT时使用
    op_mgr_name = "",       --发放管理员名字
    rechage_num = 0         --玩家充值的灵石数量 
}

 

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

    GuildRecord.AddRecord({
        uid = uid,
        record_type = GuildEnum.EGuildRecordType.eRT_QUIT,
        time = os.time(),
    })
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