local moon = require("moon")
local common = require("common")
local CmdCode = common.CmdCode
local GameCfg = common.GameCfg
local Database = common.Database
local ErrorCode = common.ErrorCode
local cluster = require("cluster")
local uuid = require("uuid")
---@type guildmgr_context
local context = ...
local scripts = context.scripts



---@class GuildMgr
local GuildMgr = {}

function GuildMgr.Init()
    return true
end
function GuildMgr.Start()
    return true
end
-- 从c_guild表读取所有公会id,根据负载均衡算法选择节点，并将其分配给该节点
function GuildMgr.LoadGuilds()
    local guild_ids = Database.GetAllGuildIds()
    if not guild_ids then
        return false
    end
    local node_guilds = {}
    for _, guild_id in ipairs(guild_ids) do
        local guild = Database.GetGuildById(guild_id)
        if guild then
            local node_id = context.node_guilds[guild.guild_node] or {}
            table.insert(node_id, guild.guild_id)
            context.node_guilds[guild.guild_node] = node_id
            context.guilds[guild.guild_id] = guild
            context.uid_to_guild[guild.creator_uid] = guild.guild_id
        end
    end
    return true
end
-- 查找node_guilds表中公会数量最少的节点
function GuildMgr.FindLeastLoadedNode()
    local min_node = nil
    local min_count = math.huge
    for nid, guild_ids in pairs(context.node_guilds) do
        local count = #guild_ids
        if count < min_count then
            min_count = count
            min_node = nid
        end
    end
    return min_node
end
---@param creator_uid integer
---@param guild_name string
---@return  {}
function GuildMgr.CreateGuild(creator_uid, guild_name)
    -- 检查用户是否已有公会
    if context.uid_to_guild[creator_uid] then
        return { code = ErrorCode.GuildAlreadyInGuild }
    end
    
    -- 生成唯一公会ID
    local guild_id = uuid.next()
    -- 查找node_guilds表中公会数量最少的节点
    local min_node =  GuildMgr.FindLeastLoadedNode()
    if not min_node then
        return { code = ErrorCode.AgentNotAvailable }
    end
    local ret = LuaPanda and LuaPanda.BP and LuaPanda.BP()
 
     
    -- 调用agent服务创建公会
    local res, err = cluster.call(min_node, "agent", "Agent.CreateGuild", guild_id, guild_name,creator_uid)
    if not res then
        print("CreateGuild failed:", err)
        return { code = ErrorCode.AgentCreateFailed,error = err}
    end
    if res.code ~= ErrorCode.None then
        return { code = res.code } -- 返回错误码，不继续执行后续操作，直接retur
    end
    -- 记录公会ID到节点的映射
    context.node_guilds[min_node][guild_id] = res.addr_guild
    
    
    context.guilds[guild_id] = {
        guild_id = guild_id,
        creator_uid = creator_uid,
        guild_name = guild_name,
        guild_node = min_node,
        addr_guild = res.addr_guild,
    }
    context.uid_to_guild[creator_uid] = guild_id
    
    return { code = ErrorCode.None, guild_id = guild_id,guild_name = guild_name ,addr_guild = res.addr_guild ,guild_node = min_node}
end




---@param nid integer 节点ID
---@param addr_agent integer agent服务地址
---@return boolean
function GuildMgr.AgentOnline(nid, addr_agent)
    context.node_agents[nid] = addr_agent
    context.node_guilds[nid] = {}
    return true
end

---@param nid integer 节点ID
---@return boolean
function GuildMgr.AgentOffline(nid)
    context.node_agents[nid] = nil
    context.node_guilds[nid] = nil
    return true
end

---@param guild_id integer
---@return {code:integer, guild_node:integer, addr_guild:integer}
function GuildMgr.GetGuildNodeAndAddr(guild_id)
    local guild = context.guilds[guild_id]
    if not guild then
        return { code = ErrorCode.GuildNotExist }
    end
    
    return { 
        code = ErrorCode.None, 
        guild_node = guild.guild_node, 
        addr_guild = guild.addr_guild 
    }
end

return GuildMgr
