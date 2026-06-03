--require("common.LuaPanda").start("127.0.0.1", 8818)
local moon = require "moon"
local common = require "common"
local GameCfg = common.GameCfg
local ErrorCode = common.ErrorCode
local Database = common.Database
local RankDef = require "common.def.RankDef"
local redisd = require "redisd"
local redis_call = redisd.call
local json = require "json"

local RankLogic = {}

-- 排行榜数据
local rank_data = {}

-- 排行榜奖励数据（用于保存刷新前的排名数据）
local rank_reward_data = {}

-- 排行榜更新队列（待处理的更新请求）
local rank_update_queue = {}

-- 批量处理间隔（秒）
local BATCH_PROCESS_INTERVAL = 10

-- 是否正在处理队列
local is_processing_queue = false

-- 初始化排行榜
function RankLogic.Init()
    -- 加载排行榜数据
    rank_data = {}
    -- 从Redis加载数据
    local _, loaded_rank_types = RankLogic.LoadRankDataFromRedis()
    -- 初始化未加载的流动榜
    RankLogic.InitFlowRanks(loaded_rank_types)
    -- 初始化未加载的总榜
    RankLogic.InitTotalRanks(loaded_rank_types)
end

-- 初始化流动榜
function RankLogic.InitFlowRanks(loaded_rank_types)
    local flow_ranks = {
        RankDef.RankType.Duanwei_Weekly,
        RankDef.RankType.Duanwei_Season,
        RankDef.RankType.Mainline,
        RankDef.RankType.Fengta,
        RankDef.RankType.Fadian_Total,
        RankDef.RankType.Fadian_Weekly,
        RankDef.RankType.Fadian_Monthly,
        RankDef.RankType.Player,
        RankDef.RankType.Role,
        RankDef.RankType.Antique,
    }

    for _, rank_type in ipairs(flow_ranks) do
        -- 只初始化未加载的排行榜
        if not loaded_rank_types[rank_type] then
            rank_data[rank_type] = rank_data[rank_type] or {}
            -- 创建初始流动榜
            local initial_rank = RankDef.newRankData()
            initial_rank.rid = 1
            initial_rank.rt = rank_type
            initial_rank.flow = true
            initial_rank.ct = moon.time()
            initial_rank.lrt = moon.time()
            table.insert(rank_data[rank_type], initial_rank)
        end
    end
end

-- 初始化总榜
function RankLogic.InitTotalRanks(loaded_rank_types)
    local total_ranks = {
        RankDef.RankType.GuildActive,
        RankDef.RankType.GuildMoney,
        RankDef.RankType.GuildScore_Weekly,
        RankDef.RankType.GuildScore_Season,
    }

    for _, rank_type in ipairs(total_ranks) do
        -- 只初始化未加载的排行榜
        if not loaded_rank_types[rank_type] then
            local rank = RankDef.newRankData()
            rank.rid = 1
            rank.rt = rank_type
            rank.flow = false
            rank.ct = moon.time()
            rank.lrt = moon.time()
            rank_data[rank_type] = { rank }
        end
    end
end

-- 获取玩家所在的流动榜
function RankLogic.GetPlayerFlowRank(rank_type, uid)
    if not rank_data[rank_type] then
        return nil
    end

    for _, rank in ipairs(rank_data[rank_type]) do
        if rank.flow and rank.ps[uid] then
            return rank
        end
    end

    return nil
end

-- 分配玩家到流动榜
function RankLogic.AssignPlayerToFlowRank(rank_type, uid)
    if not rank_data[rank_type] then
        return nil
    end

    -- 检查玩家是否已在榜单中
    local existing_rank = RankLogic.GetPlayerFlowRank(rank_type, uid)
    if existing_rank then
        return existing_rank
    end

    -- 找到人数未满的流动榜
    for _, rank in ipairs(rank_data[rank_type]) do
        if rank.flow and table.size(rank.ps) < RankDef.FLOW_RANK_MAX_PLAYERS then
            return rank
        end
    end

    -- 所有榜单都满了，创建新的流动榜
    local new_rank = RankDef.newRankData()
    new_rank.rid = #rank_data[rank_type] + 1
    new_rank.rt = rank_type
    new_rank.flow = true
    new_rank.ct = moon.time()
    new_rank.lrt = moon.time()
    table.insert(rank_data[rank_type], new_rank)

    return new_rank
end

-- 更新玩家排行数据（放入队列，批量处理）
-- force: true=强制更新（即使分数降低）, false=初始化模式（不覆盖已有非零分数）
function RankLogic.UpdatePlayerRank(rank_type, uid, player_data, force)
    -- 默认force=true，允许分数降低时更新排名
    -- 正确处理 false 值：只有当 force 显式为 false 时才为 false
    if force == nil then
        force = true
    end
    return RankLogic.EnqueueRankUpdate(rank_type, uid, player_data, force)
end

-- 对榜单进行排序
function RankLogic.SortRank(rank)
    local players = {}
    for uid, data in pairs(rank.ps) do
        table.insert(players, data)
    end

    -- 排序规则：先按value降序，再按update_time升序
    table.sort(players, function(a, b)
        if a.value ~= b.value then
            return a.value > b.value
        else
            return a.ut < b.ut
        end
    end)

    -- 更新排名
    for i, data in ipairs(players) do
        data.rank = i
        rank.ps[data.uid] = data
    end
end

-- 检查是否为流动榜
function RankLogic.IsFlowRank(rank_type)
    local flow_ranks = {
        [RankDef.RankType.Duanwei_Weekly] = true,
        [RankDef.RankType.Duanwei_Season] = true,
        [RankDef.RankType.Mainline] = true,
        [RankDef.RankType.Fengta] = true,
        [RankDef.RankType.Fadian_Total] = true,
        [RankDef.RankType.Fadian_Weekly] = true,
        [RankDef.RankType.Fadian_Monthly] = true,
        [RankDef.RankType.Player] = true,
        [RankDef.RankType.Role] = true,
        [RankDef.RankType.Antique] = true,
    }
    return flow_ranks[rank_type] or false
end

-- 刷新排行榜数据
function RankLogic.RefreshRankData(rank_type)
    if not rank_data[rank_type] then
        return ErrorCode.ConfigError
    end

    -- 保存刷新前的排名数据，用于奖励领取
    local reward_data = RankDef.newRankRewardData()
    reward_data.rt = rank_type
    reward_data.rt_ref = moon.time()
    reward_data.sr = {}

    for _, rank in ipairs(rank_data[rank_type]) do
        -- 创建子榜奖励数据
        local sub_rank_reward = RankDef.newSubRankRewardData()
        sub_rank_reward.rid = rank.rid
        sub_rank_reward.ps = {}

        -- 保存该子榜下所有玩家的排名数据
        for uid, player_data in pairs(rank.ps) do
            sub_rank_reward.ps[uid] = table.copy(player_data)
        end

        reward_data.sr[rank.rid] = sub_rank_reward
    end

    rank_reward_data[rank_type] = reward_data

    -- 清空排行榜数据
    for _, rank in ipairs(rank_data[rank_type]) do
        rank.ps = {}
        rank.lrt = moon.time()
    end

    -- 同步到Redis（排行榜数据和奖励数据）
    RankLogic.SaveRankDataToRedis(rank_type)
    RankLogic.SaveRankRewardToRedis(rank_type)

    return ErrorCode.None
end

-- 合并流动榜
function RankLogic.MergeFlowRanks(rank_type)
    if not RankLogic.IsFlowRank(rank_type) or not rank_data[rank_type] then
        return ErrorCode.ConfigError
    end

    local ranks = rank_data[rank_type]
    local merged_ranks = {}

    -- 按照rid排序
    table.sort(ranks, function(a, b)
        return a.rid < b.rid
    end)

    -- 合并相邻的两个榜单
    for i = 1, #ranks, 2 do
        local rank1 = ranks[i]
        local rank2 = ranks[i + 1]

        local merged_rank = RankDef.newRankData()
        merged_rank.rid = math.floor((i + 1) / 2)
        merged_rank.rt = rank_type
        merged_rank.flow = true
        merged_rank.ct = moon.time()
        merged_rank.lrt = moon.time()

        -- 合并第一个榜单的玩家数据
        if rank1 then
            for uid, data in pairs(rank1.ps) do
                merged_rank.ps[uid] = data
            end
        end

        -- 合并第二个榜单的玩家数据
        if rank2 then
            for uid, data in pairs(rank2.ps) do
                merged_rank.ps[uid] = data
            end
        end

        -- 重新排序
        RankLogic.SortRank(merged_rank)
        table.insert(merged_ranks, merged_rank)
    end

    -- 替换为合并后的榜单
    rank_data[rank_type] = merged_ranks

    return ErrorCode.None
end

-- 将玩家字典转换为数组并转换字段名为客户端期望的格式
local function convertPlayersToArray(rank)
    moon.info(string.format("[RankLogic] convertPlayersToArray: rank=%s, rank.ps=%s, rank.rid=%s", 
        tostring(rank), tostring(rank and rank.ps), tostring(rank and rank.rid)))
    if not rank or not rank.ps then
        return rank
    end

    -- 创建新的排行榜数据，使用客户端期望的字段名
    local new_rank = {
        rank_id = rank.rid or rank.id or 1,
        rank_type = rank.rt or rank.rank_type or 0,
        is_flow = rank.flow or rank.is_flow or false,
        players = {},
        create_time = rank.ct or rank.create_time or 0,
        last_refresh_time = rank.lrt or rank.last_refresh_time or 0,
    }

    for uid, player_data in pairs(rank.ps) do
        -- 复制玩家数据并转换字段名为客户端期望的格式
        local new_player_data = {
            uid = player_data.uid or 0,
            name = player_data.name or "",
            avatar = player_data.avatar or 0,
            avatar_frame = player_data.af or 0,
            guild_name = player_data.gn or "",
            guild_id = player_data.gid or 0,
            value = player_data.value or 0,
            extra_data = {},
            rank = player_data.rank or 0,
            update_time = player_data.ut or 0,
            -- 出战角色和鬼怪信息
            character_id = player_data.chr or 0,
            -- 处理新旧数据兼容：旧数据是单个数字，新数据是数组
            character_skins = type(player_data.chs) == "table" and player_data.chs or (player_data.chs and {player_data.chs} or {}),
            ghost_id = player_data.gho or 0,
            ghost_skin = player_data.ghs or 0,
            -- 宗门榜宗主信息
            guild_leader = player_data.gl or "",
            gl_char_id = player_data.gl_chr or 0,
            gl_char_skins = type(player_data.gl_chs) == "table" and player_data.gl_chs or (player_data.gl_chs and {player_data.gl_chs} or {}),
            gl_ghost_id = player_data.gl_gho or 0,
            gl_ghost_skin = player_data.gl_ghs or 0,
        }

        -- 转换 ed 中的值并使用客户端期望的字段名
        if player_data.ed then
            for k, v in pairs(player_data.ed) do
                -- 如果是数组，保持原样；否则转为字符串
                new_player_data.extra_data[k] = type(v) == "table" and v or tostring(v)
            end
        end

        table.insert(new_rank.players, new_player_data)
    end

    table.sort(new_rank.players, function(a, b)
        if a.rank and b.rank then
            return a.rank < b.rank
        end
        return false
    end)

    return new_rank
end

-- 获取排行榜数据
function RankLogic.GetRankData(rank_type, rank_id)
    -- 处理枚举值可能是字符串的情况
    if type(rank_type) == "string" then
        local rank_type_name = string.gsub(rank_type, "RankType_", "")
        rank_type = RankDef.RankType[rank_type_name]
    end

    if not rank_type or not rank_data[rank_type] then
        return nil
    end

    if rank_id then
        for _, rank in ipairs(rank_data[rank_type]) do
            if rank.rid == rank_id then
                return convertPlayersToArray(rank)
            end
        end
    else
        local result = {}
        for _, rank in ipairs(rank_data[rank_type]) do
            table.insert(result, convertPlayersToArray(rank))
        end
        return result
    end

    return nil
end

-- 获取所有可用的排行榜类型和子榜信息
function RankLogic.GetAllRankTypes()
    moon.info("[RankLogic] GetAllRankTypes called")

    local result = {}
    for name, rank_type in pairs(RankDef.RankType) do
        local rank_info = {
            rank_type = rank_type,
            name = name,
            is_flow = RankLogic.IsFlowRank(rank_type),
            sub_ranks = {}
        }

        -- 如果是流动榜，获取所有子榜ID
        if rank_data[rank_type] then
            for _, rank in ipairs(rank_data[rank_type]) do
                table.insert(rank_info.sub_ranks, {
                    rank_id = rank.rid,
                    create_time = rank.ct,
                    last_refresh_time = rank.lrt
                })
            end
        end

        table.insert(result, rank_info)
    end

    moon.info(string.format("[RankLogic] GetAllRankTypes: returned %d rank types", #result))
    return ErrorCode.None, result
end

-- 获取玩家在排行榜中的信息或整个排行榜数据
function RankLogic.GetRankInfo(rank_type, rank_id, uid)
    moon.info(string.format("[RankLogic] GetRankInfo called: rank_type=%d, rank_id=%s, uid=%s", 
        rank_type, tostring(rank_id), tostring(uid)))

    if not rank_type or not rank_data[rank_type] then
        moon.info(string.format("[RankLogic] GetRankInfo: no rank data for type %d", rank_type))
        return ErrorCode.ConfigError, nil
    end

    moon.info(string.format("[RankLogic] GetRankInfo: rank_data[%d] has %d sub ranks", rank_type, #rank_data[rank_type]))
    if rank_data[rank_type][1] then
        moon.info(string.format("[RankLogic] GetRankInfo: first rank - rid=%s, rt=%s, ps_count=%d", 
            tostring(rank_data[rank_type][1].rid), tostring(rank_data[rank_type][1].rt), 
            table.size(rank_data[rank_type][1].ps or {})))
    end

    -- 如果指定了uid（大于0），获取玩家个人信息（可能在多个子榜中）
    if uid and uid > 0 then
        moon.info(string.format("[RankLogic] GetRankInfo: entering player info branch for uid=%d", uid))
        local results = {}
        for _, rank in ipairs(rank_data[rank_type]) do
            moon.info(string.format("[RankLogic] GetRankInfo: checking rank.rid=%d, rank_id=%s, rank.ps[uid]=%s", 
                rank.rid or 0, tostring(rank_id), tostring(rank.ps[uid])))
            -- rank_id=0 表示查询所有子榜，否则只查询指定的子榜
            if not (rank_id and rank_id > 0 and rank.rid ~= rank_id) then
                if rank.ps[uid] then
                    moon.info(string.format("[RankLogic] GetRankInfo: found player %d in rank %d", uid, rank.rid))
                    local player_data = rank.ps[uid]
                    -- 转换 extra_data，确保值都是字符串类型
                    local extra_data = {}
                    if player_data.ed then
                        for k, v in pairs(player_data.ed) do
                            extra_data[k] = type(v) == "table" and json.encode(v) or tostring(v)
                        end
                    end
                    table.insert(results, {
                        rank_type = rank_type,
                        sub_rank_id = rank.rid,
                        is_flow = rank.flow or false,
                        create_time = rank.ct or 0,
                        last_refresh_time = rank.lrt or 0,
                        uid = player_data.uid or 0,
                        name = player_data.name or "",
                        avatar = player_data.avatar or 0,
                        avatar_frame = player_data.af or 0,
                        guild_name = player_data.gn or "",
                        guild_id = player_data.gid or 0,
                        value = player_data.value or 0,
                        extra_data = extra_data,
                        rank = player_data.rank or 0,
                        update_time = player_data.ut or 0,
                        character_id = player_data.chr or 0,
                        character_skins = type(player_data.chs) == "table" and player_data.chs or (player_data.chs and {player_data.chs} or {}),
                        ghost_id = player_data.gho or 0,
                        ghost_skin = player_data.ghs or 0,
                        guild_leader = player_data.gl or "",
                        gl_char_id = player_data.gl_chr or 0,
                        gl_char_skins = type(player_data.gl_chs) == "table" and player_data.gl_chs or (player_data.gl_chs and {player_data.gl_chs} or {}),
                        gl_ghost_id = player_data.gl_gho or 0,
                        gl_ghost_skin = player_data.gl_ghs or 0,
                    })
                end
            else
                moon.info(string.format("[RankLogic] GetRankInfo: rank.rid=%d doesn't match rank_id=%s", rank.rid or 0, tostring(rank_id)))
            end
        end

        if #results > 0 then
            -- 如果只找到一个，返回单个对象；否则返回数组
            return ErrorCode.None, #results == 1 and results[1] or results
        end

        moon.info(string.format("[RankLogic] GetRankInfo: player %d not found in rank %d", uid, rank_type))
        return ErrorCode.None, nil
    end

    -- 否则获取整个排行榜数据
    local result = {}
    for _, rank in ipairs(rank_data[rank_type]) do
        -- rank_id=0 表示查询所有子榜，否则只查询指定的子榜
        if not (rank_id and rank_id > 0 and rank.rid ~= rank_id) then
            table.insert(result, convertPlayersToArray(rank))
        end
    end

    moon.info(string.format("[RankLogic] GetRankInfo: loaded %d sub ranks for type %d", #result, rank_type))
    return ErrorCode.None, result
end

-- 保存排行榜数据到Redis
function RankLogic.SaveRankDataToRedis(rank_type)
    moon.info(string.format("[RankLogic] SaveRankDataToRedis called: rank_type=%d", rank_type))
    if not rank_data[rank_type] then
        moon.info(string.format("[RankLogic] SaveRankDataToRedis: no data for rank_type=%d", rank_type))
        return ErrorCode.ConfigError
    end

    local addr_db = moon.queryservice("db_server")
    if not addr_db or addr_db == 0 then
        moon.info(string.format("[RankLogic] SaveRankDataToRedis: db_server not found"))
        return ErrorCode.ServerInternalError
    end

    -- 保存排行榜数据
    local rank_key = string.format("rank:%d", rank_type)
    local rank_json = json.encode(rank_data[rank_type])
    local res, err = pcall(Database.saveserverdata_with_key, addr_db, rank_key, rank_json)
    if not res then
        moon.error(string.format("[RankLogic] SaveRankDataToRedis failed: rank_type=%d, err=%s", rank_type, err))
        return ErrorCode.ServerInternalError
    end
    moon.info(string.format("[RankLogic] SaveRankDataToRedis success: rank_type=%d, key=%s", rank_type, rank_key))
    return ErrorCode.None
end

-- 保存奖励数据到Redis
function RankLogic.SaveRankRewardToRedis(rank_type)
    local addr_db = moon.queryservice("db_server")
    if not addr_db or addr_db == 0 then
        return ErrorCode.ServerInternalError
    end

    local reward_key = string.format("rank_reward:%d", rank_type)
    if rank_reward_data[rank_type] then
        local reward_json = json.encode(rank_reward_data[rank_type])
        local res, err = pcall(Database.saveserverdata_with_key, addr_db, reward_key, reward_json)
        if not res then
            moon.error("Save rank reward data to redis failed:", err)
            return ErrorCode.ServerInternalError
        end
    else
        -- 如果没有奖励数据，删除对应的键
        local res, err = pcall(redis_call, addr_db, "del", reward_key)
        if not res then
            moon.error("Delete rank reward key failed:", err)
        end
    end

    return ErrorCode.None
end

-- 保存所有排行榜数据到Redis
function RankLogic.SaveAllRankDataToRedis()
    for _, rank_type in pairs(RankDef.RankType) do
        RankLogic.SaveRankDataToRedis(rank_type)
    end
end

-- 从Redis加载排行榜数据
function RankLogic.LoadRankDataFromRedis()
    local addr_db = moon.queryservice("db_server")
    if not addr_db or addr_db == 0 then
        moon.error("LoadRankDataFromRedis: db_server not found")
        return ErrorCode.ServerInternalError, {}
    end

    local loaded_rank_types = {}
    local loaded_count = 0

    -- 遍历 RankDef.RankType 表的值，而不是键
    for _, rank_type in pairs(RankDef.RankType) do
        -- 加载排行榜数据
        local rank_key = string.format("rank:%d", rank_type)
        local res, rank_json = pcall(Database.loadserverdata_with_key, addr_db, rank_key)
        if res and rank_json and rank_json ~= nil and rank_json ~= "" then
            local ok, decoded = pcall(json.decode, rank_json)
            if ok then
                -- 补全缺失的字段
                for i, rank in ipairs(decoded) do
                    rank.rid = rank.rid or rank.id or i
                    rank.rt = rank.rt or rank.rank_type or rank_type
                    rank.flow = rank.flow or rank.is_flow or false
                    rank.ct = rank.ct or rank.create_time or moon.time()
                    rank.lrt = rank.lrt or rank.last_refresh_time or moon.time()
                    rank.ps = rank.ps or rank.players or {}
                end
                rank_data[rank_type] = decoded
                loaded_rank_types[rank_type] = true
                loaded_count = loaded_count + 1
                moon.info(string.format("[RankLogic] Loaded rank data for type %d", rank_type))
            else
                moon.error(string.format("[RankLogic] Failed to decode rank data for type %d: %s", rank_type, decoded))
            end
        else
            moon.info(string.format("[RankLogic] No rank data found for type %d", rank_type))
        end

        -- 加载奖励数据
        local reward_key = string.format("rank_reward:%d", rank_type)
        local res_ex, reward_json = pcall(Database.loadserverdata_with_key, addr_db, reward_key)
        if res_ex and reward_json and reward_json ~= nil and reward_json ~= "" then
            local ok, decoded = pcall(json.decode, reward_json)
            if ok then
                rank_reward_data[rank_type] = decoded
            else
                moon.error(string.format("[RankLogic] Failed to decode reward data for type %d", rank_type))
            end
        end
    end

    moon.info(string.format("[RankLogic] Loaded %d rank types from Redis", loaded_count))
    return ErrorCode.None, loaded_rank_types
end

-- 玩家领取排行榜奖励
function RankLogic.GetRankReward(rank_type, uid)
    if not rank_reward_data[rank_type] then
        return ErrorCode.RankRewardNotExist
    end

    local reward_data = rank_reward_data[rank_type]

    -- 查找玩家所在的子榜
    local sub_rank_reward = nil
    local player_data = nil
    for _, sub_rank in pairs(reward_data.sr) do
        if sub_rank.ps[uid] then
            sub_rank_reward = sub_rank
            player_data = sub_rank.ps[uid]
            break
        end
    end

    if not sub_rank_reward or not player_data then
        return ErrorCode.RankRewardNotExist
    end

    -- 获取该排行榜的奖励配置
    local rank_reward_cfg = GameCfg.RankingListReward[rank_type]
    if not rank_reward_cfg then
        return ErrorCode.RankRewardNotExist
    end

    -- 根据玩家排名查找对应的奖励ID
    local player_rank = player_data.rank
    local reward_id = nil
    local ranking_range = rank_reward_cfg.ranking_range
    local reward_ids = rank_reward_cfg.reward_id

    -- 排序区间的最小排名
    local sorted_min_ranks = {}
    for min_rank, _ in pairs(ranking_range) do
        table.insert(sorted_min_ranks, min_rank)
    end
    table.sort(sorted_min_ranks)

    -- 遍历查找玩家排名所在的区间
    for i, min_rank in ipairs(sorted_min_ranks) do
        local max_rank = ranking_range[min_rank]
        if player_rank >= min_rank and player_rank <= max_rank then
            reward_id = reward_ids[i]
            break
        end
    end

    if not reward_id then
        return ErrorCode.RankRewardNotExist
    end

    -- 根据奖励ID从奖励池中获取具体奖励
    local reward_pool_cfg = GameCfg.RankingListRewardPool[reward_id]
    if not reward_pool_cfg then
        return ErrorCode.RankRewardNotExist
    end

    -- 发放奖励
    -- 这里需要调用奖励发放相关的函数

    -- 标记奖励已领取（从子榜奖励数据中移除）
    sub_rank_reward.ps[uid] = nil

    -- 如果该子榜所有奖励都已领取，清除子榜数据
    if table.empty(sub_rank_reward.ps) then
        reward_data.sr[sub_rank_reward.rid] = nil
    end

    -- 如果所有子榜奖励都已领取，清除奖励数据
    if table.empty(reward_data.sr) then
        rank_reward_data[rank_type] = nil
    end

    -- 同步到Redis
    RankLogic.SaveRankDataToRedis(rank_type)

    return ErrorCode.None, reward_pool_cfg.reward
end

-- 将排行榜更新请求放入队列（不立即处理）
-- force: 是否强制更新（true=强制更新，即使分数降低；false=初始化时使用，不覆盖已有分数）
function RankLogic.EnqueueRankUpdate(rank_type, uid, player_data, force)
    local key = rank_type .. "_" .. uid
    rank_update_queue[key] = {
        rank_type = rank_type,
        uid = uid,
        player_data = player_data,
        force = force or false,
        enqueue_time = moon.time()
    }
    moon.info(string.format("[RankLogic] EnqueueRankUpdate: rank_type=%d, uid=%d, queue_size=%d", rank_type, uid, table.size(rank_update_queue)))
    return ErrorCode.None
end

-- 批量处理更新队列
function RankLogic.ProcessRankUpdateQueue()
    if is_processing_queue then
        return
    end

    is_processing_queue = true

    local count = 0
    for key, update_req in pairs(rank_update_queue) do
        -- 直接更新内存数据（传递force参数）
        local ret = RankLogic.UpdatePlayerRankInternal(update_req.rank_type, update_req.uid, update_req.player_data, update_req.force)
        if ret == ErrorCode.None then
            rank_update_queue[key] = nil
            count = count + 1
        end
    end

    is_processing_queue = false

    if count > 0 then
        moon.info(string.format("[RankLogic] Processed %d rank updates from queue", count))
    end
end

-- 内部更新方法（不放入队列，直接更新）
-- force: true=强制更新（即使分数降低）, false=初始化模式（不覆盖已有非零分数）
function RankLogic.UpdatePlayerRankInternal(rank_type, uid, player_data, force)
    local rank
    if RankLogic.IsFlowRank(rank_type) then
        rank = RankLogic.AssignPlayerToFlowRank(rank_type, uid)
    else
        rank = rank_data[rank_type][1] -- 总榜只有一个
    end

    if not rank then
        return ErrorCode.ConfigError
    end

    local existing_data = rank.ps[uid]

    -- 主线榜(RankType_Mainline=3)和封塔榜(RankType_Fengta=4)：只有分数上涨才更新排名
    local is_mainline_or_fengta = rank_type == RankDef.RankType.Mainline or rank_type == RankDef.RankType.Fengta
    if is_mainline_or_fengta and existing_data then
        local new_value = player_data.value or 0
        local old_value = existing_data.value or 0
        if new_value <= old_value then
            -- 分数没有上涨，只更新出战信息，不更新排名
            moon.info(string.format("[RankLogic] Mainline/Fengta rank: player %d value %d <= %d, update battle info only", 
                uid, new_value, old_value))
            if player_data.chr then existing_data.chr = player_data.chr end
            if player_data.chs then existing_data.chs = player_data.chs end
            if player_data.gho then existing_data.gho = player_data.gho end
            if player_data.ghs then existing_data.ghs = player_data.ghs end
            return ErrorCode.None
        end
    end

    -- 根据force参数决定更新策略
    if existing_data then
        moon.info(string.format("[RankLogic] Player %d already exists in rank %d, force=%s, existing value=%d",
            uid, rank_type, tostring(force), existing_data.value or 0))
        if force then
            -- force=true: 强制更新，即使分数降低也更新排名
            -- 始终更新
            moon.info(string.format("[RankLogic] Force update for player %d in rank %d", uid, rank_type))
        else
            -- force=false (初始化模式):
            -- 如果已有数据，只更新出战信息（chr, chs, gho, ghs），不覆盖分数相关字段
            -- 保留：value, ed, rank, ut 等分数相关字段
            moon.info(string.format("[RankLogic] Init mode: updating battle info only for player %d in rank %d", uid, rank_type))
            if player_data.chr then existing_data.chr = player_data.chr end
            if player_data.chs then existing_data.chs = player_data.chs end
            if player_data.gho then existing_data.gho = player_data.gho end
            if player_data.ghs then existing_data.ghs = player_data.ghs end
            return ErrorCode.None
        end
    else
        moon.info(string.format("[RankLogic] Player %d not found in rank %d, adding new data with value=%d", 
            uid, rank_type, player_data.value or 0))
    end

    rank.ps[uid] = player_data
    player_data.ut = moon.time()

    RankLogic.SortRank(rank)

    return ErrorCode.None
end

-- 启动队列处理器（定时批量处理）
function RankLogic.StartQueueProcessor()
    moon.info(string.format("[RankLogic] StartQueueProcessor: BATCH_PROCESS_INTERVAL=%ds", BATCH_PROCESS_INTERVAL))
    moon.async(function()
        while true do
            moon.sleep(BATCH_PROCESS_INTERVAL * 1000)
            moon.info(string.format("[RankLogic] ProcessRankUpdateQueue triggered, queue_size=%d", table.size(rank_update_queue)))
            RankLogic.ProcessRankUpdateQueue()
        end
    end)
end

return RankLogic