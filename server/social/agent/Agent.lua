local moon = require "moon"
local uuid = require "uuid"
local coqueue = require "moon.queue"
local common = require "common"
local GameDef= common.GameDef
local Database = common.Database
local GameCfg = common.GameCfg --游戏配置
local ErrorCode = common.ErrorCode --逻辑错误码
local CmdCode = common.CmdCode --客户端通信消息码

---@type agent_context
local context = ...
local scripts = context.scripts ---方便访问同服务的其它lua模块
 
---@class Agent
local Agent = {}

function Agent.Init()
   
    return true
end

function Agent.Start()
    return true
end

-- 创建Guild服务并初始化
function Agent.CreateGuild(guild_data)
    local conf = {
        name = "guild" .. guild_data.guild_id,
        file = "social/service_guild.lua"
    }
    local addr_guild = moon.new_service(conf)
    if addr_guild == 0 then
        return { code = ErrorCode.CreateGuildServiceErr, error = "create guild service failed!" }
    end
    local ok, err = moon.call("lua", addr_guild, "Guild.Create", guild_data.guild_id, guild_data.creator_uid,
        guild_data.guild_name)
    if not ok then
        return { code = ErrorCode.CreateGuildServiceErr, error = err }
    end
    return { code = ErrorCode.None, guild_id = guild_data.guild_id, guild_node = guild_data.guild_node,addr_guild = addr_guild }
end

-- 从数据库加载并创建公会服务
function Agent.LoadGuild(guild_ids)
end



function Agent.Shutdown()
    moon.quit()
    return true
end

 
return Agent