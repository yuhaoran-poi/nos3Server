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
   
    context.addr_db_game = moon.queryservice("db_game")
    -- 没有c_guild就创建
    local ok, err = moon.call("lua", context.addr_db_game, [[
        CREATE TABLE IF NOT EXISTS c_guild (
            guildId BIGINT NOT NULL,
            value MEDIUMBLOB NOT NULL,
            json JSON DEFAULT NULL,
            PRIMARY KEY (guildId)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 ROW_FORMAT=DYNAMIC;
    ]])
    assert(ok, "Failed to create c_guild table: " .. tostring(err)) -- 增强错误提示
    -- 没有c_guild_shop就创建
    ok, err = moon.call("lua", context.addr_db_game, [[
        CREATE TABLE IF NOT EXISTS c_guild_shop (
            guildId BIGINT  NOT NULL,
            value MEDIUMBLOB NOT NULL,
            json JSON DEFAULT NULL,
            PRIMARY KEY (guildId)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 ROW_FORMAT=DYNAMIC;
    ]])
    assert(ok, "Failed to create c_guild_shop table: " .. tostring(err)) -- 增强错误提示
    -- 没有c_guild_bag就创建
    ok, err = moon.call("lua", context.addr_db_game, [[
        CREATE TABLE IF NOT EXISTS c_guild_bag (
            guildId BIGINT  NOT NULL,
            value MEDIUMBLOB NOT NULL,
            json JSON DEFAULT NULL,
            PRIMARY KEY (guildId)
        )  ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 ROW_FORMAT=DYNAMIC;
    ]])
    assert(ok, "Failed to create c_guild_bag table: " .. tostring(err)) -- 增强错误提示
    -- 没有c_guild_record就创建
    ok, err = moon.call("lua", context.addr_db_game, [[
        CREATE TABLE IF NOT EXISTS c_guild_record (
            guildId BIGINT  NOT NULL,
            value MEDIUMBLOB NOT NULL,
            json JSON DEFAULT NULL,
            PRIMARY KEY (guildId)
        )  ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 ROW_FORMAT=DYNAMIC;
    ]])
    assert(ok, "Failed to create c_guild_record table: ".. tostring(err)) -- 增强错误提示
    return true
end

function Agent.Start()


    return true
end

-- 创建Guild服务并初始化
function Agent.CreateGuild(guild_id, guild_name, creator_uid)
    local conf = {
        name = "guild" .. guild_id,
        file = "social/service_guild.lua"
    }
    local addr_guild = moon.new_service(conf)
    if addr_guild == 0 then
        return { code = ErrorCode.CreateGuildServiceErr, error = "create guild service failed!" }
    end
    local res, err = moon.call("lua", addr_guild, "Guild.Create", guild_id, guild_name, creator_uid)
    if not res then
        return { code = ErrorCode.CreateGuildDataErr, error = err }
    end
    if res.code ~= ErrorCode.None then
        return { code = res.code, error = res.error }
    end
    -- 保存到数据库
    return { code = ErrorCode.None, guild_id = guild_id,addr_guild = addr_guild }
end

-- 创建Guild服务并从数据库加载数据
function Agent.LoadGuild(guild_id)
    local conf = {
        name = "guild" .. guild_id,
        file = "social/service_guild.lua"
    }
    local addr_guild = moon.new_service(conf)
    if addr_guild == 0 then
        moon.error("create guild service failed!") -- 使用moon.error而不是get_logger的error方法
        return
    end
    moon.send("lua", addr_guild, "Guild.Load", guild_id, addr_guild)
end



function Agent.Shutdown()
    moon.quit()
    return true
end

 
return Agent