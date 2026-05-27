local LuaExt = require "common.LuaExt"

local RankDef = {
}

-- 排行榜类型
RankDef.RankType = {
    -- 流动榜
    Duanwei_Weekly = 1,     -- 周段位榜
    Duanwei_Season = 2,     -- 赛季段位榜
    Mainline = 3,           -- 主线榜
    Fengta = 4,             -- 封塔榜
    Fadian_Total = 5,       -- 发电总榜
    Fadian_Weekly = 6,      -- 发电周榜
    Fadian_Monthly = 7,     -- 发电月榜
    Player = 8,             -- 玩家榜
    Role = 9,               -- 角色榜
    Antique = 10,           -- 古董榜
    -- 总榜
    GuildActive = 11,        -- 宗门活跃榜
    GuildMoney = 12,         -- 宗门资金榜
    GuildScore_Weekly = 13,  -- 宗门周赛季积分榜
    GuildScore_Season = 14,  -- 宗门赛季积分榜
}

-- 排行榜刷新类型
RankDef.RefreshType = {
    Daily = 1,     -- 每日
    Weekly = 2,    -- 每周
    Monthly = 3,   -- 每月
    Season = 4,    -- 赛季
    NoRefresh = 5, -- 不刷新
}

-- 流动榜默认最大人数
RankDef.FLOW_RANK_MAX_PLAYERS = 1000

-- 排行榜数据结构 (使用短字段名节省存储)
local defaultRankData = {
    rid = 0,               -- rank_id: 排行榜ID
    rt = 0,                -- rank_type: 排行榜类型
    flow = false,          -- is_flow: 是否为流动榜
    ps = {},               -- players: 玩家数据
    ct = 0,                -- create_time: 创建时间
    lrt = 0,               -- last_refresh_time: 上次刷新时间
}

-- 玩家排行数据结构 (使用短字段名节省存储)
local defaultPlayerRankData = {
    uid = 0,               -- 玩家ID
    name = "",             -- 玩家名称
    avatar = 0,            -- 头像
    af = 0,                -- avatar_frame: 头像框
    gn = "",               -- guild_name: 所属宗门名称
    gid = 0,               -- guild_id: 所属宗门ID
    value = 0,             -- 排行值
    ed = {},               -- extra_data: 额外数据
    rank = 0,              -- 排名
    ut = 0,                -- update_time: 更新时间
    chr = 0,               -- character_id: 出战角色ID
    chs = 0,               -- character_skin: 出战角色时装
    gho = 0,               -- ghost_id: 出战鬼怪ID
    ghs = 0,               -- ghost_skin: 出战鬼怪时装
    -- 宗门榜专用字段（宗主信息）
    gl = "",               -- guild_leader: 宗主名称
    gl_chr = 0,            -- guild_leader_character: 宗主出战角色ID
    gl_chs = 0,            -- guild_leader_character_skin: 宗主出战角色时装（数组）
    gl_gho = 0,            -- guild_leader_ghost: 宗主出战鬼怪ID
    gl_ghs = 0,            -- guild_leader_ghost_skin: 宗主出战鬼怪时装
}

-- 子榜奖励数据结构 (使用短字段名节省存储)
local defaultSubRankRewardData = {
    rid = 0,               -- rank_id: 子榜ID
    ps = {},               -- players: 玩家排名数据（key为uid，value为排名信息）
}

-- 排行榜奖励数据结构 (使用短字段名节省存储)
local defaultRankRewardData = {
    rt = 0,                -- rank_type: 排行榜类型
    sr = {},               -- sub_ranks: 子榜数据（key为rank_id）
    rt_ref = 0,            -- refresh_time: 刷新时间
}

---@return table
function RankDef.newRankData()
    return LuaExt.const(table.copy(defaultRankData))
end

---@return table
function RankDef.newPlayerRankData()
    return LuaExt.const(table.copy(defaultPlayerRankData))
end

---@return table
function RankDef.newRankRewardData()
    return LuaExt.const(table.copy(defaultRankRewardData))
end

---@return table
function RankDef.newSubRankRewardData()
    return LuaExt.const(table.copy(defaultSubRankRewardData))
end

return RankDef
