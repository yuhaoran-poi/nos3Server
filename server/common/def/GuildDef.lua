local LuaExt = require "common.LuaExt"
local ItemDef = require "common.def.ItemDef"
local GuildDef = {}


-- 公会成员信息
local defaultPBGuildMemberData = {
    uid = 0,                  --玩家uID
    nickname = "",            --玩家昵称
    duty_id = 0,              --玩家职务Id
    contribute = 0,           --玩家贡献
    week_contribute = 0,      --玩家本周贡献
    online = false,           --玩家在线状态 true 在线 false 不在线
    last_get_salary_time = 0, --上一次获取工资的时间戳
    join_time = 0,            --加入公会时间
    dkp = 0,                  --个人的DKP值
    b_spoils_mgr = false,     --是否战利品管理员
    last_send_spoil = 0,      --上次发放战利品的时间戳
}

-- 公会记录信息
local defaultPBGuildInfoDB = {
    guild_id = 0,                  --公会id
    name = "",                     --公会名
    level = 1,                     --公会等级
    president_id = 0,              --公会长ID
    president_name = "",           --公会长名称
    build_time = 0,                --创建时间
    exp = 0,                       --公会经验
    contribute = 0,                --公会贡献值
    activeness = 0,                --公会活跃度
    status = 0,                    --公会状态（正常，冻结或者销毁）
    master_ids = {},               --公会管理员列表
    members = {},                  --玩家列表
    member_count = 0,              --公会成员人数（当前）
    member_num_level = 1,          --成员人数等级(第几等级）
    member_max_num = 10,           --最大成员人数
    accouncenment = "",            --公会公告
    apply_list = {},               --公会申请列表
    freeze_time = 0,               --冻结开始时间
    apply_count = 0,               --公会申请数量
    destory_time = 0,              --销毁时间
    duty_list = {},                --职位列表
    announcenment_modify_time = 0, --公告上次修改时间
    season_activeness = 0,         --本赛季活跃度
    join_con = {},                 --公会加入条件
    name_modify_time = 0,          --公会名字上次修改时间
    spoilsmgr_ids = {},            --公会战利品管理员
    recommend_endtime = 0,         --公会推荐到期时间
    item_headid = 0,               --公会头像ID
    item_frameid = 0,              --公会头像框ID
    open_juanzeng = 0,             --打开捐赠
}
 
 
local defaultPBGuildShopDB = {
    guild_id = 0,          --公会id
    shop_item_list = {},   --商品列表
    last_refresh_time = 0, --上次刷新时间
}
 
 
local defaultPBGuildBagDB = {
    guild_id = 0,       --公会id
    bag_item_list = {}, --背包物品列表
}
 
 
 
local defaultPBGuildRecordInfo = {
    record_type = 0,             --记录类型
    nickname = "",               --目标玩家昵称
    record_time = 0,             --记录时间
    duty_name = "",              --只在 eRT_DUTY_CHANGE 有用（表示职位名称) 
    guild_level = 0,             --只在 eRT_GUILD_LV_UP 有用（表示职位名称) 
    guild_name = "",             --只在 eRT_CHANGE_GUILD_NAME 有用（表示职位名称)
    target_uid = 0,              --目标玩家UID
    duty_id = 0,                 --只在 eRT_DUTY_CHANGE 有用 （表示职位ID)
    gkd_change_num = 0,          --eRT_GuildGKD变化记录,
    gkd_cur_num = 0,             --eRT_GuildGKD GKD当前值
    gkd_desc = "",               --eRT_GuildGKD 备注
    item_id = 0,                 --只在ERT_JUANZENG时使用
    gubi_num = 0,                --只在ERT_JUANZENG时使用，古币数量
    contribute = 0,              --贡献值
    spoils_item = {},            --只在战利品发放时使用，物品id
    season_point = 0,            --只在ERT_SEASON_POINT时使用
    op_mgr_name = "",            --发放管理员名字
    rechage_num = 0,             --玩家充值的灵石数量
    operater_uid = 0,            --操作玩家UID
}
 
local defaultPBGuildRecordDB = {
    guild_id = 0,     --公会id
    record_list = {}, --记录列表
}
 


--- @return PBGuildInfoDB
function GuildDef.newPBGuildInfoDB()
    return LuaExt.const(table.copy(defaultPBGuildInfoDB))
end
--- @return PBGuildShopDB
function GuildDef.newPBGuildShopDB()
    return LuaExt.const(table.copy(defaultPBGuildShopDB))
end

--- @return PBGuildBagDB
function GuildDef.newPBGuildBagDB()
    return LuaExt.const(table.copy(defaultPBGuildBagDB))
end

--- @return PBGuildRecordInfo
function GuildDef.newPBGuildRecordInfo()
    return LuaExt.const(table.copy(defaultPBGuildRecordInfo))
end
--- @return PBGuildRecordDB
function GuildDef.newPBGuildRecordDB()
    return LuaExt.const(table.copy(defaultPBGuildRecordDB))
end

--- @return PBGuildMemberData
function GuildDef.newPBGuildMemberData()
    return LuaExt.const(table.copy(defaultPBGuildMemberData))
end

 

return GuildDef