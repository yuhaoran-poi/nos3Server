local moon = require "moon"
local uuid = require "uuid"
local coqueue = require "moon.queue"
local common = require "common"
local GameDef= common.GameDef
local Database = common.Database
local GameCfg = common.GameCfg --游戏配置
local ErrorCode = common.ErrorCode --逻辑错误码
local CmdCode = common.CmdCode --客户端通信消息码
local LuaExt = common.LuaExt
---@type guild_context
local context = ...
local scripts = context.scripts ---方便访问同服务的其它lua模块
 
---@class Guild
local Guild = {}

---@class defaultGuildInfoDBClass
local defaultGuildInfoDB = {
    guild_id = 0,               --公会id
    name = "",                  --公会名
    level = 1,                  --公会等级
    president_id = 0,           --公会长ID
    president_name = "",        --公会长名称
    build_time = 0,             --创建时间
    exp = 0,                    --公会经验
    contribute = 0,             --公会贡献值
    activeness = 0,             --公会活跃度
    status = 0,                 --公会状态（正常，冻结或者销毁）
    master_ids = {},            --公会管理员列表
    members = {},                  --玩家列表
    member_count = 0,              --公会成员人数（当前）
    member_num_level = 0,          --成员人数等级(第几等级）
    member_max_num = 0,            --最大成员人数
    accouncenment = "",         --公会公告
    apply_list = {},            --公会申请列表
    freeze_time = 0,            --冻结开始时间
    apply_count = 0,            --公会申请数量
    destory_time = 0,           --销毁时间
    duty_list = {},             --职位列表
    announcenment_modify_time = 0, --公告上次修改时间
    season_activeness = 0,      --本赛季活跃度
    join_con = {},              --公会加入条件
    name_modify_time = 0,       --公会名字上次修改时间
    spoilsmgr_ids = {},         --公会战利品管理员
    recommend_endtime = 0,      --公会推荐到期时间
    item_headid = 0,            --公会头像ID
    item_frameid = 0,           --公会头像框ID
    open_juanzeng = 0,          --打开捐赠
    ---------------------------------------以下数据不落地-------------------------
}
---@class defaultGuildShopDBClass
local defaultGuildShopDB = {
    guild_id = 0, --公会id
    shop_item_list = {}, --商品列表
    last_refresh_time = 0, --上次刷新时间
}
---@class defaultGuildBagDBClass
local defaultGuildBagDB = {
    guild_id = 0, --公会id
    bag_item_list = {}, --背包物品列表
}

---@class defaultGuildRecordDBClass
local defaultGuildRecordDB = {
    guild_id = 0, --公会id
    record_list = {}, --记录列表 
}

function Guild.Init()
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
---@return {}
function Guild.Create(guild_id, guild_name, creator_uid)
    context.guild_id = guild_id
    local guild_db = scripts.GuildModel.Get()
    if not guild_db then
        local data = 
        {
            GuildInfo = LuaExt.const(table.copy(defaultGuildInfoDB)),
            GuildShop = LuaExt.const(table.copy(defaultGuildShopDB)),
            GuildBag = LuaExt.const(table.copy(defaultGuildBagDB)),
            GuildRecord = LuaExt.const(table.copy(defaultGuildRecordDB)),
          
        }
        -- 初始化公会信息
        local guild_info = data.GuildInfo
        guild_info.guild_id = guild_id
        guild_info.name = guild_name
        guild_info.president_id = creator_uid
        guild_info.president_name = Database.GetUserSimpleF(context.addr_db_redis, creator_uid, "nickname") or ""
        guild_info.build_time = os.time()
        --guild_info.member_max_num = GameCfg.GuildMaxNum
        --guild_info.member_num_level = GameCfg.GuildMaxNumLevel
        -- 初始化公会商店
        local guild_shop = data.GuildShop
        guild_shop.guild_id = guild_id
        -- 初始化公会背包
        local guild_bag = data.GuildBag
        guild_bag.guild_id = guild_id
        -- 初始化公会记录
        local guild_record = data.GuildRecord
        guild_record.guild_id = guild_id
        -- 创建数据模型
        scripts.GuildModel.Create(data)
        Guild.AddMemeber(creator_uid)
    end

    -- 保存到数据库

    xpcall(function()
        scripts.GuildModel.Save()
    end, function(err)
        print("GuildModel.Save:", err)
        return { code = ErrorCode.CreateGuildDataSaveErr, error = err }
    end)
    
    return {code = ErrorCode.None}
end

function Guild.AddMemeber(uid)
    local guild_data = scripts.GuildModel.MutGetGuildInfoDB()
    if not guild_data then
        return false, ErrorCode.GuildNotExist
    end
    if guild_data.member_count >= guild_data.member_max_num then
        return false, ErrorCode.GuildFull
    end
    local nickname = Database.GetUserSimpleF(context.addr_db_redis, uid, "nickname")
    guild_data.members[uid] = {
          uid = uid,                                      --玩家uID
          nickname = nickname or "",                        --玩家昵称
	      duty_id = 0,		   --玩家职务Id
	      contribute = 0,      --玩家贡献
	      week_contribute = 0, --玩家本周贡献
	      online = true,		   --玩家在线状态
	      last_get_salary_time = 0,	--上一次获取工资的时间戳
	      join_time = os.time(),	--加入公会时间
	      dkp = 0,              --个人的DKP值
          b_spoils_mgr = uid == guild_data.president_id,      --是否战利品管理员
          last_send_spoil=0,    --上次发放战利品的时间戳
    }
    guild_data.member_count = table.count(guild_data.members)
    --scripts.GuildModel.Save()
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