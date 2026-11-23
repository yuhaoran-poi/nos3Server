local LuaExt = require "common.LuaExt"

local RankDef = {
}

-- (旧RankType枚举 1~14 已删除: 旧14榜随新三榜上线整体下线, 榜实例现由 static/table/RankBoard.lua
--  配置注册, id 即 rank_type, 采用百位分段: 1xx竞速周 2xx竞速总 3xx摸金周 4xx摸金总 5xx古董周 6xx古董总)

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

-- 新三榜(鬼王竞速/摸金/古董): 榜实例由 static/table/RankBoard.lua 配置注册, id 即 rank_type(101+)
-- 旧14种榜(RankType枚举)已屏蔽: RankLogic 入口过滤, 更新静默丢弃, 不再初始化/刷新/列举
-- 一级标签(领奖聚合粒度: 同标签下多子榜取最高名次档位, 每标签一期各领一次)
RankDef.Category = {
    SPEED = 1,      -- 鬼王竞速
    GOLD = 2,       -- 摸金
    ANTIQUE = 3,    -- 古董
}
-- 成绩合并方式
RankDef.MergeType = {
    MAX = 1,        -- 取最高(最好一次/最高一件, 不涨只更新形象)
    SUM = 2,        -- 累加(每次上报为增量, 榜值=旧值+增量)
}
-- 统计窗口
RankDef.WindowType = {
    WEEKLY = 1,     -- 周榜: 周一刷新, 快照保留一期(本周只能领上周奖励)
    SEASON = 2,     -- 总榜: 赛季结束刷新, 快照保留一期
}

-- 排行榜数据结构 (使用短字段名节省存储)
local defaultRankData = {
    rid = 0,               -- rank_id: 排行榜ID
    rt = 0,                -- rank_type: 排行榜类型
    flow = false,          -- is_flow: 是否为流动榜
    ps = {},               -- players: 玩家数据
    ct = 0,                -- create_time: 创建时间
    lrt = 0,               -- last_refresh_time: 上次刷新时间
}

-- 排行项数据结构 (使用短字段名节省存储)
local defaultRankItemData = {
    id = 0,                -- 通用ID（玩家榜为uid，宗门榜为guild_id）
    name = "",             -- 名称（玩家榜为玩家名称，宗门榜为宗门名称）
    avatar = 0,            -- 头像（玩家榜为玩家头像，宗门榜为宗门头像）
    af = 0,                -- avatar_frame: 头像框（玩家榜为玩家头像框，宗门榜为宗门头像框）
    gn = "",               -- guild_name: 所属宗门名称（玩家榜用）
    gid = 0,               -- guild_id: 所属宗门ID（玩家榜用）
    value = 0,             -- 排行值
    ed = {},               -- extra_data: 额外数据
    rank = 0,              -- 排名
    ut = 0,                -- update_time: 更新时间
    chr = 0,               -- character_id: 出战角色ID（玩家榜用）
    chs = 0,               -- character_skin: 出战角色时装（玩家榜用）
    gho = 0,               -- ghost_id: 出战鬼怪ID（玩家榜用）
    ghs = 0,               -- ghost_skin: 出战鬼怪时装（玩家榜用）
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
    period = 0,            -- period: 期数（用于多期管理）
}

---@return table
function RankDef.newRankData()
    return LuaExt.const(table.copy(defaultRankData))
end

---@return table
function RankDef.newRankItemData()
    return LuaExt.const(table.copy(defaultRankItemData))
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
