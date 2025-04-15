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
    -- 判断是否已经加载过
    if context.load_guild_start then
        moon.error("LoadGuilds already started")
        return false
    end
    local guild_ids = Database.load_guildids(context.addr_db_game)
    if not guild_ids then
        moon.error("LoadGuilds failed")
        return false
    end
    if context.allguild_load then
        moon.error("All guilds already loaded")
        return false
    end
    -- 判断node_agents数量是否小于（公会数量/1000,向上取整），如果是则返回错误
    local node_count = #context.node_agents
    if node_count < math.ceil(#guild_ids / 1000) then
        moon.error("Node count is less than guild count / 1000")
        return false
    end
    for _, guild_id in ipairs(guild_ids) do
        local guild = Database.GetGuildById(guild_id)
        local node = GuildMgr.FindLeastLoadedNode()
        if guild and node then
            context.guilds[guild_id] = {
                guild_id = guild_id,
                guild_node = node,
                addr_guild = 0,
                status = 0, -- 0: loading, 1: online, 2: offline, 3: error, 4: database error_message
            }
            context.node_guilds[node][guild_id] = true
            -- 通知agent服务加载公会
            cluster.send(node, "agent", "Agent.LoadGuild", guild_id)
        else
            moon.error("LoadGuild failed:", guild_id)
            return false
        end
    end
    context.load_guild_start = true
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

--- 处理公会加载完成通知
--- @param node_id integer 节点ID
---@param guild_id integer
---@param addr_guild integer
function GuildMgr.GuildLoad(guild_id, addr_guild)
    local guild = context.guilds[guild_id]
    if not guild then
        moon.error("Guild not found:", guild_id)
        return
    end
    guild.addr_guild = addr_guild
    guild.status = 1
    -- 判断所有公会是否加载完成
    local all_loaded = true
    for _, guild in pairs(context.guilds) do
        if guild.status ~= 1 then
            all_loaded = false
            break
        end
    end
    if all_loaded and not context.allguild_load then
        context.allguild_load = true
        moon.info("All guilds loaded")
    end
    moon.info("Guild loaded:", guild_id)
     
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
    -- 加载所有的guild
    --GuildMgr.LoadGuilds()
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
