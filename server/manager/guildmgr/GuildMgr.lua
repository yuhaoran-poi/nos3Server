local moon = require("moon")
local common = require("common")
local CmdCode = common.CmdCode
local GameCfg = common.GameCfg
local Database = common.Database

---@type guildmgr_context
local context = ...
local scripts = context.scripts



---@class GuildMgr
local GuildMgr = {}

function GuildMgr:Init()

    return true
end

---@param creator_uid integer
---@param guild_name string
---@param base_data table
---@return integer|nil, ErrorCode?
function GuildMgr:CreateGuild(creator_uid, guild_name, base_data)
    -- 检查用户是否已有公会
    if context.uid_to_guild[creator_uid] then
        return nil, ErrorCode.GuildAlreadyInGuild
    end
    
    -- 生成公会ID
    local guild_id = moon.new_service("guild", "Guild", creator_uid, guild_name, base_data)
    if not guild_id then
        return nil, ErrorCode.ServerInternalError
    end
    
    -- 初始化公会数据
    local guild_data = {
        id = guild_id,
        name = guild_name,
        creator_uid = creator_uid,
        create_time = moon.time(),
        base_data = base_data
    }
    
    context.guilds[guild_id] = guild_data
    context.uid_to_guild[creator_uid] = guild_id
    
    return guild_id
end

---@param uid integer
---@param guild_id integer
---@return boolean, ErrorCode?
function GuildMgr:JoinGuild(uid, guild_id)
    -- 检查用户是否已有公会
    if context.uid_to_guild[uid] then
        return false, ErrorCode.GuildAlreadyInGuild
    end
    
    -- 检查公会是否存在
    local guild = context.guilds[guild_id]
    if not guild then
        return false, ErrorCode.GuildNotExist
    end
    
    -- 调用公会服务加入
    local success, err = moon.call(guild_id, "Guild", "Join", uid, guild_id)
    if not success then
        return false, err or ErrorCode.ServerInternalError
    end
    
    context.uid_to_guild[uid] = guild_id
    return true
end

---@param uid integer
---@return boolean, ErrorCode?
function GuildMgr:ExitGuild(uid)
    local guild_id = context.uid_to_guild[uid]
    if not guild_id then
        return false, ErrorCode.GuildNotInGuild
    end
    
    -- 调用公会服务退出
    local success, err = moon.call(guild_id, "Guild", "Exit", uid)
    if not success then
        return false, err or ErrorCode.ServerInternalError
    end
    
    context.uid_to_guild[uid] = nil
    return true
end

---@param guild_id integer
---@return table|nil, ErrorCode?
function GuildMgr:GetGuildInfo(guild_id)
    local guild = context.guilds[guild_id]
    if not guild then
        return nil, ErrorCode.GuildNotExist
    end
    
    return guild
end

---@param guild_id integer
---@param uid integer
---@param new_duty integer
---@return boolean, ErrorCode?
function GuildMgr:ChangeMemberDuty(guild_id, uid, new_duty)
    -- 检查公会是否存在
    local guild = context.guilds[guild_id]
    if not guild then
        return false, ErrorCode.GuildNotExist
    end
    
    -- 调用公会服务变更职位
    local success, err = moon.call(guild_id, "Guild", "ChangeDuty", uid, new_duty)
    if not success then
        return false, err or ErrorCode.ServerInternalError
    end
    
    return true
end

---@param guild_id integer
---@return boolean, ErrorCode?
function GuildMgr:UpgradeGuild(guild_id)
    -- 检查公会是否存在
    local guild = context.guilds[guild_id]
    if not guild then
        return false, ErrorCode.GuildNotExist
    end
    
    -- 调用公会服务升级
    local success, err = moon.call(guild_id, "Guild", "Upgrade")
    if not success then
        return false, err or ErrorCode.ServerInternalError
    end
    
    return true
end

return GuildMgr
