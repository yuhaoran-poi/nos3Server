local moon = require "moon"
local uuid = require "uuid"
local queue = require "moon.queue"
local common = require "common"
local GameDef= common.GameDef
local Database = common.Database
local GameCfg = common.GameCfg --游戏配置
local ErrorCode = common.ErrorCode --逻辑错误码
local CmdCode = common.CmdCode     --客户端通信消息码
local CmdEnum = common.CmdEnum     
local LuaExt = common.LuaExt
local GuildEnum = require("common.GuildEnum") --公会枚举
local cluster = require("cluster")
local ChatLogic = require("common.ChatLogic") --聊天逻辑
---@type guild_context
local context = ...
local scripts = context.scripts ---方便访问同服务的其它lua模块
local lock = queue() -- 定义一个队列锁，用于保证线程安全
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
    member_num_level = 1,          --成员人数等级(第几等级）
    member_max_num = 10,            --最大成员人数
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
        local res = Guild.AddMemeber(creator_uid)
        if res.code ~= ErrorCode.None then
            return res
        end
    end

    -- 保存到数据库

    xpcall(function()
        scripts.GuildModel.Save()
    end, function(err)
        print("GuildModel.Save:", err)
        return { code = ErrorCode.CreateGuildDataSaveErr, error = err }
    end)
    -- 创建公会聊天频道
    local res = ChatLogic.newGuildChannel(context.guild_id)
    if res.code ~= ErrorCode.None then
        return res
    end
    return {code = ErrorCode.None}
end

function Guild.AddMemeber(uid)
    local guild_data = scripts.GuildModel.MutGetGuildInfoDB()
    if not guild_data then
        return {code = ErrorCode.GuildNotExist}
    end
    if guild_data.member_count >= guild_data.member_max_num then
        return {code = ErrorCode.GuildFull}
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
    -- 加入公会频道
    local res = ChatLogic.joinGuildChannel(context.guild_id, uid)
    if res.code ~= ErrorCode.None then
        return res
    end
    return {code = ErrorCode.None}
end

---@param guild_id integer
---@return table|nil, ErrorCode?
function Guild.Load(guild_id, addr_guild)
    local scope_lock <close> = lock()
    context.guild_id = guild_id
    local guild_db = scripts.GuildModel.Get()
    if not guild_db then
        local data =
        {
            GuildInfo = Database.load_guildinfo(context.addr_db_game, guild_id),
            GuildShop = Database.load_guildshop(context.addr_db_game, guild_id),
            GuildBag = Database.load_guildbag(context.addr_db_game, guild_id),
            GuildRecord = Database.load_guildrecord(context.addr_db_game, guild_id),
        }
        if not data.GuildInfo then
            moon.error("LoadGuild failed: GuildInfo not found,guild_id:", guild_id);
            return nil, ErrorCode.GuildDataCorrupted
        end
        if not data.GuildShop then
            moon.error("LoadGuild failed: GuildShop not found,guild_id:", guild_id);
            return nil, ErrorCode.GuildDataCorrupted
        end
        if not data.GuildBag then
            moon.error("LoadGuild failed: GuildBag not found,guild_id:", guild_id);
            return nil, ErrorCode.GuildDataCorrupted
        end
        if not data.GuildRecord then
            moon.error("LoadGuild failed: GuildRecord not found,guild_id:", guild_id);
            return nil, ErrorCode.GuildDataCorrupted
        end
        -- 创建数据模型
        scripts.GuildModel.Create(data)
        ---初始化自己数据
        context.batch_invoke_throw("Init")
        ---初始化互相引用的数据
        context.batch_invoke_throw("Start")
        --- 创建公会聊天频道
        local res = ChatLogic.newGuildChannel(context.guild_id)
        if res.code ~= ErrorCode.None then
            return nil,res.code
        end
        -- 通知guildmgr
        cluster.send(CmdEnum.FixedNodeId.MANAGER, "guildmgr", "GuildMgr.GuildLoad", guild_id, addr_guild)
    end
    return guild_db
end

 
--- 成员退出公会
---@param uid integer 成员UID
---@return ErrorCode?
function Guild.MemberQuit(uid)
    local guild_db = scripts.GuildModel.Get()
    if not guild_db then
        return ErrorCode.GuildDataCorrupted
    end
    if not guild_db.GuildInfo then
        return ErrorCode.GuildDataCorrupted
    end
    -- 判断是否是会长
    if guild_db.GuildInfo.president_id == uid then
        return ErrorCode.GuildPresidentCannotQuit
    end
    -- 判断是否是公会成员
    if not guild_db.GuildInfo.members[uid] then
        return ErrorCode.GuildMemberNotExist
    end
    local guild_info = scripts.GuildModel.MutGetGuildInfoDB()
    if not guild_info then
        return ErrorCode.GuildDataCorrupted
    end
    guild_info.members[uid] = nil
    guild_info.member_count = table.count(guild_db.GuildInfo.members)
    -- 添加公会记录
    scripts.GuildRecord.MemberQuit(uid)
    -- 通知在线成员
    Guild.NotifyMemberQuit(uid)
    ChatLogic.LeaveGuildChannel(context.guild_id,uid)
    return  ErrorCode.None
end

--- 踢出公会成员
---@param operator_uid integer 操作者UID
---@param target_uid integer 目标成员UID
---@return ErrorCode?
function Guild.MemberExpel(operator_uid, target_uid)
    local guild_db = scripts.GuildModel.Get()
    if not guild_db then
        return ErrorCode.GuildDataCorrupted
    end
    if not guild_db.GuildInfo then
        return ErrorCode.GuildDataCorrupted
    end
    
    -- 检查操作者权限
    if operator_uid ~= guild_db.GuildInfo.president_id and 
       not guild_db.GuildInfo.members[operator_uid].b_spoils_mgr then
        return ErrorCode.GuildNoPermission
    end
    
    -- 检查目标成员是否存在
    if not guild_db.GuildInfo.members[target_uid] then
        return ErrorCode.GuildMemberNotExist
    end
    
    -- 不能踢出会长
    if target_uid == guild_db.GuildInfo.president_id then
        return ErrorCode.GuildCannotExpelPresident
    end
    
    local guild_info = scripts.GuildModel.MutGetGuildInfoDB()
    if not guild_info then
        return ErrorCode.GuildDataCorrupted
    end
    
    -- 移除成员
    guild_info.members[target_uid] = nil
    guild_info.member_count = table.count(guild_db.GuildInfo.members)
    
    -- 添加公会记录
    scripts.GuildRecord.ExpelQuit(operator_uid, target_uid)
    
    -- 通知在线成员
    Guild.NotifyMemberExpel(target_uid)
    
    return ErrorCode.None
end
function Guild.GetMembers()
    local guild_info = scripts.GuildModel.GetGuildInfoDB()
    local member_keys = {}
    for k, _ in pairs(guild_info.members) do
        table.insert(member_keys, k)
    end
    return member_keys
end
function Guild.NotifyMemberQuit(uid)
     
    context.send_users(Guild.GetMembers, {}, "GuildProxy.OnGuildMemberQuit", context.guild_id, uid)
end

function Guild.NotifyMemberExpel(uid)
    context.send_users(Guild.GetMembers, {}, "GuildProxy.OnGuildMemberExpel", context.guild_id, uid)
end

--- 处理玩家申请加入公会
---@param uid integer 玩家UID
---@param guild_id integer 公会ID
---@return ErrorCode?
function Guild.ApplyJoinGuild(uid, guild_id)
    local guild_info = scripts.GuildModel.GetGuildInfoDB()
    if not guild_info then
        return ErrorCode.GuildDataCorrupted
    end
    
    -- 检查公会状态
    if guild_info.status ~= GuildEnum.EGuildStatus.eGS_Normal then
        return ErrorCode.GuildStatusAbnormal
    end
    
    -- 检查成员数量
    if guild_info.member_count >= guild_info.member_max_num then
        return ErrorCode.GuildFull
    end
    
    -- 检查是否已在公会
    if guild_info.members[uid] then
        return ErrorCode.GuildAlreadyInGuild
    end
    
    -- 检查是否已在申请列表
    if guild_info.apply_list[uid] then
        return ErrorCode.GuildAlreadyApplied
    end
    
    -- 添加申请
    guild_info.apply_list[uid] = {
        uid = uid,
        apply_time = os.time(),
        nickname = Database.GetUserSimpleF(context.addr_db_redis, uid, "nickname") or ""
    }
    guild_info.apply_count = table.count(guild_info.apply_list)
    
    -- 通知会长和管理员
    local notify_members = {guild_info.president_id}
    for _, mid in ipairs(guild_info.master_ids) do
        table.insert(notify_members, mid)
    end
    context.send_users(notify_members, "GuildProxy.OnGuildApplyJoin", guild_id, uid)
    
    return ErrorCode.None
end

--- 处理公会申请加入回复
---@param uid integer 处理人UID
---@param applyer_uid integer 申请人UID
---@param agree boolean 是否同意
---@return ErrorCode?
function Guild.AnswerApplyJoinGuild(uid,applyer_uid, agree)
    local guild_info = scripts.GuildModel.MutGetGuildInfoDB()
    if not guild_info then
        return ErrorCode.GuildDataCorrupted
    end
    
    -- 检查申请是否存在
    if not guild_info.apply_list[applyer_uid] then
        return ErrorCode.GuildApplyNotExist
    end
    
    -- 移除申请
    guild_info.apply_list[applyer_uid] = nil
    guild_info.apply_count = table.count(guild_info.apply_list)
    
    if agree then
        -- 检查成员数量
        if guild_info.member_count >= guild_info.member_max_num then
            return ErrorCode.GuildFull
        end
        
        -- 添加成员
        local res = Guild.AddMemeber(applyer_uid)
        if res.code ~= ErrorCode.None then
            return res.code
        end
        
        -- 通知申请人
        context.send_users({ applyer_uid }, "GuildProxy.OnGuildApplyJoinResult", context.guild_id, true)
    else
        -- 拒绝申请
        context.send_users({ applyer_uid }, "GuildProxy.OnGuildApplyJoinResult", context.guild_id, false)
    end
    
    return ErrorCode.None
end


--- 处理公会邀请加入
---@param inviter_uid integer 邀请人UID
---@param target_uid integer 目标玩家UID
---@return ErrorCode?
function Guild.InviteJoinGuild(inviter_uid, target_uid)
    local guild_info = scripts.GuildModel.MutGetGuildInfoDB()
    if not guild_info then
        return ErrorCode.GuildDataCorrupted
    end
    
    -- 检查邀请人是否在公会中
    if not guild_info.members[inviter_uid] then
        return ErrorCode.GuildNotInGuild
    end
    
    -- 检查邀请人是否有权限
    if inviter_uid ~= guild_info.president_id and not guild_info.members[inviter_uid].b_spoils_mgr then
        return ErrorCode.GuildNoPermission
    end
    
    -- 检查目标玩家是否已在公会中
    if guild_info.members[target_uid] then
        return ErrorCode.GuildAlreadyInGuild
    end
    
    -- 检查公会成员数量
    if guild_info.member_count >= guild_info.member_max_num then
        return ErrorCode.GuildFull
    end
    
    -- 发送邀请通知给目标玩家
    context.send_users({target_uid}, "GuildProxy.OnGuildInviteJoin", context.guild_id, inviter_uid)
    
    return ErrorCode.None
end

--- 处理公会邀请加入回复
---@param uid integer 玩家UID
---@param inviter_uid integer 邀请人UID
---@param agree boolean 是否同意
---@return ErrorCode?
function Guild.AnswerInviteJoinGuild(uid, inviter_uid, agree)
    local guild_info = scripts.GuildModel.MutGetGuildInfoDB()
    if not guild_info then
        return ErrorCode.GuildDataCorrupted
    end
    
    -- 检查玩家是否已在公会中
    if guild_info.members[uid] then
        return ErrorCode.GuildAlreadyInGuild
    end
    
    -- 检查公会成员数量
    if guild_info.member_count >= guild_info.member_max_num then
        return ErrorCode.GuildFull
    end
    
    if agree then
        -- 添加成员
        local res = Guild.AddMemeber(uid)
        if res.code ~= ErrorCode.None then
            return res.code
        end
        
        -- 通知邀请人
        context.send_users({inviter_uid}, "GuildProxy.OnGuildInviteJoinResult", context.guild_id, uid, true)
    else
        -- 通知邀请人
        context.send_users({inviter_uid}, "GuildProxy.OnGuildInviteJoinResult", context.guild_id, uid, false)
    end
    
    return ErrorCode.None
end

--- 解散公会
---@param operator_uid integer 操作者UID
---@return ErrorCode?
function Guild.DismissGuild(operator_uid)
    local guild_db = scripts.GuildModel.Get()
    if not guild_db then
        return ErrorCode.GuildDataCorrupted
    end
    if not guild_db.GuildInfo then
        return ErrorCode.GuildDataCorrupted
    end
    
    -- 检查操作者是否是会长
    if operator_uid ~= guild_db.GuildInfo.president_id then
        return ErrorCode.GuildNoPermission
    end
    
    -- 更新公会状态为解散
    local guild_info = scripts.GuildModel.MutGetGuildInfoDB()
    guild_info.status = GuildEnum.EGuildStatus.eGS_Dismiss
    guild_info.destory_time = os.time()
    
    -- 通知所有成员公会解散
    context.send_users(Guild.GetMembers, {}, "GuildProxy.OnGuildDismiss", context.guild_id)
    
    -- 保存数据
    scripts.GuildModel.Save()
    
    return ErrorCode.None
end

return Guild