local moon = require "moon"
local uuid = require "uuid"
local coqueue = require "moon.queue"
local common = require "common"
local GameDef= common.GameDef
local Database = common.Database
local GameCfg = common.GameCfg --游戏配置
local ErrorCode = common.ErrorCode --逻辑错误码
local CmdCode = common.CmdCode --客户端通信消息码

---@type guild_context
local context = ...
local scripts = context.scripts ---方便访问同服务的其它lua模块
 
---@class Guild
local Guild = {}

function Guild.Init()
    context.addr_db_game = moon.queryservice("db_game")
    context.guild_data = {}
    context.members = {}
    context.positions = {
        [1] = {name = "会长", permissions = {"create", "delete", "modify", "kick", "promote"}},
        [2] = {name = "副会长", permissions = {"modify", "kick"}},
        [3] = {name = "成员", permissions = {}}
    }
    return true
end

function Guild.Start()
    return true
end

function Guild.Shutdown()
    moon.quit()
    return true
end

---@param guild_id integer
---@param creator_uid integer
---@param guild_name string
---@param base_data table
---@return integer|nil, ErrorCode?
function Guild.Create(guild_id, creator_uid, guild_name, base_data)
    local scope_lock<close> = lock()
    
    -- 检查公会是否已存在
    if context.guild_data[guild_id] then
        return nil, ErrorCode.GuildAlreadyExist
    end
    
    -- 创建公会基础数据
    local guild_data = {
        guildId = guild_id,
        name = guild_name,
        level = 1,
        president_id = creator_uid,
        member_count = 1,
        member_max_count = GameCfg.guild_init_member_limit or 50,
        members = {[creator_uid] = true},
        base_data = base_data
    }
    
    -- 保存到数据库
    local success = Database.SaveGuildData(context.addr_db_game, guild_id, guild_data)
    if not success then
        return nil, ErrorCode.ServerInternalError
    end
    
    context.guild_data[guild_id] = guild_data
    context.members[creator_uid] = guild_id
    
    return guild_id
end

---@param guild_id integer
---@return table|nil, ErrorCode?
function Guild.Load(guild_id)
    local scope_lock<close> = lock()
    local guild_data = Database.LoadGuildData(context.addr_db_game, guild_id)
    if not guild_data then
        return nil, ErrorCode.GuildNotExist
    end
    
    context.guild_data = guild_data
    
    -- 初始化成员映射
    for uid, _ in pairs(guild_data.members or {}) do
        context.members[uid] = guild_id
    end
    
    return guild_data
end

---@param uid integer
---@param guild_id integer
---@param base_data table
---@return boolean, ErrorCode?
function Guild.Join(uid, guild_id, base_data)
    local scope_lock<close> = lock()
    
    -- 检查用户是否已在其他公会中
    if context.members[uid] then
        return false, ErrorCode.GuildAlreadyInGuild
    end
    
    local guild = context.guild_data[guild_id]
    if not guild then
        return false, ErrorCode.GuildNotExist
    end
    
    -- 检查公会是否已满
    if guild.member_count >= guild.member_max_count then
        return false, ErrorCode.GuildFull
    end
    
    -- 添加成员
    guild.members[uid] = {
        uid = uid,
        position = 3, -- 默认职位为普通成员
        join_time = os.time()
    }
    guild.member_count = guild.member_count + 1
    context.members[uid] = guild_id
    
    -- 保存到数据库
    local success = Database.SaveGuildData(context.addr_db_game, guild_id, guild)
    if not success then
        return false, ErrorCode.ServerInternalError
    end
    
    return true
end

--- 检查用户是否有指定权限
---@param guild_id integer
---@param uid integer
---@param permission string
---@return boolean
local function HasPermission(guild_id, uid, permission)
    local guild = context.guild_data[guild_id]
    if not guild then return false end
    
    local member = guild.members[uid]
    if not member then return false end
    
    local position = context.positions[member.position or 3]
    if not position then return false end
    
    for _, perm in ipairs(position.permissions) do
        if perm == permission then
            return true
        end
    end
    
    return false
end

---@param uid integer
---@return boolean, ErrorCode?
function Guild.Exit(uid)
    local scope_lock<close> = lock()
    
    local guild_id = context.members[uid]
    if not guild_id then
        return false, ErrorCode.GuildNotInGuild
    end
    
    local guild = context.guild_data[guild_id]
    if not guild then
        context.members[uid] = nil
        return false, ErrorCode.GuildDataCorrupted
    end
    
    -- 移除成员
    guild.members[uid] = nil
    guild.member_count = guild.member_count - 1
    context.members[uid] = nil
    
    -- 如果是会长退出且公会还有成员，需要转移会长
    if guild.president_id == uid and next(guild.members) then
        for new_president_uid, _ in pairs(guild.members) do
            guild.president_id = new_president_uid
            break
        end
    end
    
    -- 保存到数据库
    local success = Database.SaveGuildData(context.addr_db_game, guild_id, guild)
    if not success then
        return false, ErrorCode.ServerInternalError
    end
    
    return true
end

--- 变更成员职位
---@param operator_uid integer 操作者UID
---@param target_uid integer 目标成员UID
---@param new_position integer 新职位(1:会长, 2:副会长, 3:成员)
---@return boolean, ErrorCode?
function Guild.ChangePosition(operator_uid, target_uid, new_position)
    local scope_lock<close> = lock()
    
    -- 检查操作者是否有权限
    local guild_id = context.members[operator_uid]
    if not guild_id then
        return false, ErrorCode.GuildNotInGuild
    end
    
    -- 检查目标成员是否存在
    local target_guild_id = context.members[target_uid]
    if not target_guild_id or target_guild_id ~= guild_id then
        return false, ErrorCode.GuildMemberNotExist
    end
    
    local guild = context.guild_data[guild_id]
    if not guild then
        return false, ErrorCode.GuildDataCorrupted
    end
    
    -- 检查职位是否有效
    if not context.positions[new_position] then
        return false, ErrorCode.GuildInvalidPosition
    end
    
    -- 检查操作者是否有权限变更职位
    if not HasPermission(guild_id, operator_uid, "promote") then
        return false, ErrorCode.GuildNoPermission
    end
    
    -- 检查不能给自己变更职位
    if operator_uid == target_uid then
        return false, ErrorCode.GuildCannotChangeSelfPosition
    end
    
    -- 获取目标成员当前职位
    local target_member = guild.members[target_uid]
    if not target_member then
        return false, ErrorCode.GuildMemberNotExist
    end
    
    -- 特殊处理会长职位变更
    if new_position == 1 then
        -- 会长只能由当前会长指定
        if guild.president_id ~= operator_uid then
            return false, ErrorCode.GuildNoPermission
        end
        
        -- 更新会长
        guild.president_id = target_uid
        
        -- 发送职位变更通知
        scripts.guild_event.NotifyPositionChange(guild_id, target_uid, new_position)
        
        -- 记录职位变更日志
        Database.LogGuildEvent(context.addr_db_game, guild_id, 
            string.format("职位变更: %s -> %s", 
                context.positions[target_member.position or 3].name,
                context.positions[new_position].name),
            operator_uid, target_uid)
    end
    
    -- 更新职位
    target_member.position = new_position
    
    -- 如果降职为普通成员，移除特殊权限
    if new_position == 3 then
        target_member.special_permissions = nil
    end
    
    -- 保存到数据库
    local success = Database.SaveGuildData(context.addr_db_game, guild_id, guild)
    if not success then
        return false, ErrorCode.ServerInternalError
    end
    
    return true
end
-- 处理客户端请求
return Guild