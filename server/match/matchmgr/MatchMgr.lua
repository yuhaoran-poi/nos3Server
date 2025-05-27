--[[
* @file : MatchMgr.lua
* @type: single service
* @brief : 匹配管理服务
* @author : yq
]]

local moon = require "moon"
local uuid = require "uuid"
local coqueue = require "moon.queue"
local common = require "common"
local cluster = require("cluster")
local MatchEnum = require("common.Enum.MatchEnum")
local MatchRoomDef = require("common.def.MatchRoomDef")
local CmdEnum = common.CmdEnum
local ErrorCode = common.ErrorCode  --逻辑错误码
---@type matchmgr_context
local context = ...
local scripts = context.scripts ---方便访问同服务的其它lua模块
 
---@class MatchMgr
local MatchMgr = {}

function MatchMgr.Init()
    context.level_pool = { 0, 9, 51, MatchEnum.MATCH_MAX_STAR }
    context.rank_score_pool = { 0, 19, MatchEnum.MATCH_MAX_STAR }
     
    for i = MatchEnum.MATCH_TYPE_DEF.MATCH_TYPE_NORMAL, MatchEnum.MATCH_TYPE_DEF.MATCH_TYPE_MAX do
        context.matching_teams[i] = {}
    end
    return true
end

function MatchMgr.Start()
    --[[
        moon.async(function()
        while true do
            moon.sleep(3000) -- 每3秒
            MatchMgr.DoMatch()
        end
    end)
    ]]

    return true
end

 
function MatchMgr.Shutdown()
    moon.quit()
    return true
end
 
function MatchMgr.DoMatch()
    MatchMgr.DoNormalMatch()
    MatchMgr.DoRankingMatch()
    MatchMgr.DoLRSMatch()
    MatchMgr.DoQLMatch()
    MatchMgr.DoJDZMatch()
    return true
end
-- 分装队伍
---@param mapMatching table<number, number> 匹配队伍列表，key为队伍ID，value为队伍开始匹配的时间
function MatchMgr.WrapTeam(mapMatching)
    -- 一共6个队列，按人数划分开。1~5放人的队列 6放鬼的队列
    local all_teams = MatchRoomDef.newMatchTeamQueue()
    local human_count = 0
    local ghost_count = 0
    for k, _ in pairs(mapMatching) do
        local team_id = k
        local team_info = context.all_teams[team_id]
        if team_info then
            local camp_type = team_info.match_data.camp_type
            local member_count = table.size(team_info.members)
            -- 输出成员信息
            moon.info("team_id = ", team_id, " camp_type = ", camp_type, " member_count = ", member_count)
            if camp_type == MatchEnum.MATCH_CAMP_DEF.MATCH_CAMP_HUMAN then
                human_count = human_count + member_count
                if member_count >= 1 and member_count <= MatchEnum.HUMAN_COUNT then
                    if team_info.match_data.is_camer then
                        table.insert(all_teams[member_count], 1, team_id)
                    else
                        table.insert(all_teams[member_count], team_id)
                    end
                end
            elseif camp_type == MatchEnum.MATCH_CAMP_DEF.MATCH_CAMP_GHOST then
                ghost_count = ghost_count + member_count
                if member_count == 1 then
                    if team_info.match_data.is_camer then
                        table.insert(all_teams[6], 1, team_id)
                    else
                        table.insert(all_teams[6], team_id)
                    end
                end
            end
        end
    end
    return human_count, ghost_count, all_teams
end
-- 排序匹配队伍
function MatchMgr.SortTeam(all_teams)
    for i = 1, 6 do
        if all_teams[i] then
            table.sort(all_teams[i], function(a, b)
                local team_a = context.all_teams[a]
                local team_b = context.all_teams[b]
                if team_a.match_data.is_camer and not team_b.match_data.is_camer then
                    return true
                elseif not team_a.match_data.is_camer and team_b.match_data.is_camer then
                    return false
                end
                return team_a.match_data.match_time < team_b.match_data.match_time
            end)
        end
    end
end
-- 匹配队伍（不带AI）
---@param all_teams table<number, number[]> 匹配队伍列表，key为队伍人数，value为队伍ID列表
---@param match_type number 匹配类型
---@param mapMatching table<number, number> 匹配队伍列表，key为队伍ID，value为队伍开始匹配的时间
---@return table<number, MatchRoomDataClass> 匹配房间列表，key为房间ID，value为房间信息
function MatchMgr.MatchTeam(all_teams, match_type, mapMatching)
    --- @type table<number, MatchRoomDataClass> 匹配房间列表，key为房间ID，value为房间信息
    local mapRoomData = {}
    local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
    -- 没有鬼直接退出
    if table.size(all_teams[6]) == 0 then return mapRoomData end
    local all_teams_bk = table.copy(all_teams, true)
    if not all_teams_bk then return mapRoomData end
    local used_teams = {}       -- 记录已经匹配的人队伍
    local used_ghost_teams = {} -- 记录已经匹配的鬼队伍
    for i = MatchEnum.HUMAN_COUNT, 1, -1 do
        for k, v in ipairs(all_teams_bk[i]) do
            repeat
                local team_id = v
                if used_teams[team_id] then
                    break
                end
                -- 计算分值匹配范围
                local min_score, max_score, min_ghost_score, max_ghost_score, max_ghost_break =
                    MatchMgr.GetRankRange(team_id, match_type)
                -- moon.info("min_score = ", min_score, " max_score = ", max_score, " min_ghost_score = ", min_ghost_score, " max_ghost_score = ", max_ghost_score, " max_ghost_break = ", max_ghost_break)
                local match_teams = {} -- 记录匹配的队伍
                match_teams[team_id] = i
                local now_count = MatchMgr.GetTeamMemberCount(team_id)
                local need_human = MatchEnum.HUMAN_COUNT - now_count
                -- 开始找人
                local ret = MatchMgr.FindFitTeam(now_count, need_human, min_score, max_score, all_teams_bk, used_teams,
                    match_teams, true)
                local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
                if not ret then
                    break
                end
                moon.info("match_teams = ", print_r(match_teams, true))
                -- 开始找鬼
                local ret, ghost_team_id = MatchMgr.FindFitGhostTeam(min_ghost_score, max_ghost_score, all_teams_bk,
                    used_ghost_teams,true)
                if not ret then
                    break
                end
                moon.info("ghost_team_id = ", ghost_team_id)
                -- 匹配成功,开始组装
                local room_id = uuid.next()
                local room_info = MatchRoomDef.newMatchRoomData()
                mapRoomData[room_id] = room_info
                -- 将匹配好的队伍加入已使用队伍列表
                for k, v in pairs(match_teams) do
                    used_teams[k] = v
                    local team_info = context.all_teams[k]
                    if team_info then
                        room_info.teams[k] = team_info
                        if team_info.match_data.is_camer then
                            room_info.is_camer = true
                        end
                        room_info.human_num = room_info.human_num + table.size(team_info.members)
                    end
                end
                used_ghost_teams[ghost_team_id] = 6
                local ghost_team_info = context.all_teams[ghost_team_id]
                if ghost_team_info then
                    room_info.teams[ghost_team_id] = ghost_team_info
                    room_info.ghost_num = table.size(ghost_team_info.members)
                end
                -- 删除已匹配
                for k, v in pairs(match_teams) do
                    table.removevalue(all_teams[v], k)
                    mapMatching[k] = nil
                end
                table.removevalue(all_teams[6], ghost_team_id)
                mapMatching[ghost_team_id] = nil
            until true
        end
    end
    return mapRoomData
end
-- 筛选出可以带AI的队伍
---@param all_teams table<number, number[]> 匹配队伍列表，key为队伍人数，value为队伍ID列表
---@return table<number, number[]> 带AI的队伍列表，key为队伍人数，value为队伍ID列表
function MatchMgr.FilterAI(all_teams)
 
    local ai_teams =  MatchRoomDef.newMatchTeamQueue()
    for i = 1,6 do
        for _, team_id in ipairs(all_teams[i]) do
            repeat
                local team_info = context.all_teams[team_id]
                if not team_info then
                    break
                end
                local match_data = team_info.match_data
                if match_data.need_ai and                             -- 是否需要AI
                    MatchMgr.IsLowLevel(match_data.average_level) and -- 是否低等级
                    moon.time() - match_data.match_time >= MatchEnum.AI_MATCHING_TIME then
                       table.insert(ai_teams[i], team_id)
                end
            until true
        end
        moon.info("ai_teams[%d] = %d", i, table.size(ai_teams[i]))
    end
    return ai_teams
end



-- 匹配队伍（带AI）
---@param all_teams table<number, number[]> 匹配队伍列表，key为队伍人数，value为队伍ID列表
---@param match_type number 匹配类型
---@return table<number, MatchRoomDataClass> 匹配房间列表，key为房间ID，value为房间信息
function MatchMgr.MatchTeamAI(all_teams, match_type)
    --- @type table<number, MatchRoomDataClass> 匹配房间列表，key为房间ID，value为房间信息
    local mapRoomData = {}
    local need_ai_teams = MatchMgr.FilterAI(all_teams)
    local all_teams_bk = table.copy(need_ai_teams, true)
    if not all_teams_bk then return mapRoomData end

    local used_teams = {}       -- 记录已经匹配的人队伍
    local used_ghost_teams = {} -- 记录已经匹配的鬼队伍
    for i = MatchEnum.HUMAN_COUNT, 1, -1 do
        for k, v in ipairs(all_teams_bk[i]) do
            repeat
                local team_id = v
                if used_teams[team_id] then
                    break
                end
               
                local match_teams = {} -- 记录匹配的队伍
                match_teams[team_id] = i
                local now_count = MatchMgr.GetTeamMemberCount(team_id)
                local need_human = MatchEnum.HUMAN_COUNT - now_count
                -- 开始找人
                local ret = MatchMgr.FindFitTeam(now_count, need_human, 0, 0, all_teams_bk, used_teams,
                    match_teams, false)
                if not ret then
                    break
                end
                -- 开始找鬼
                local ret, ghost_team_id = MatchMgr.FindFitGhostTeam(0, 0, all_teams_bk,
                    used_ghost_teams,false)
                if not ret then
                    -- 从AI鬼中找，todo需要鬼的ai默认配置
                    break
                end
                -- 匹配成功,开始组装
                local room_id = uuid.next()
                local room_info = MatchRoomDef.newMatchRoomData()
                mapRoomData[room_id] = room_info
                -- 将匹配好的队伍加入已使用队伍列表
                for k, v in pairs(match_teams) do
                    used_teams[k] = v
                    local team_info = context.all_teams[k]
                    if team_info then
                        room_info.teams[k] = team_info
                        if team_info.match_data.is_camer then
                            room_info.is_camer = true
                        end
                        room_info.human_num = room_info.human_num + table.size(team_info.members)
                    end
                end
                used_ghost_teams[ghost_team_id] = 6
                local ghost_team_info = context.all_teams[ghost_team_id]
                if ghost_team_info then
                    room_info.teams[ghost_team_id] = ghost_team_info
                    room_info.ghost_num = table.size(ghost_team_info.members)
                end
                -- 删除已匹配
                for k, v in pairs(match_teams) do
                    table.removevalue(all_teams[v], k)
                end
                table.removevalue(all_teams[6], ghost_team_id)
            until true
        end
    end
    return mapRoomData
end
-- 取队伍人数
function MatchMgr.GetTeamMemberCount(team_id)
    local team_info = context.all_teams[team_id]
    if team_info then
        return table.size(team_info.members)
    end
    return 0
end
-- 是否低等级
function MatchMgr.IsLowLevel(level)
    if level > 0 and level < MatchEnum.LOWLEVEL_MATCH_AI then
        return true
    end
    return false
end
-- 查找适合的队伍
---@param now_count number 当前人数
---@param need_human number 需要人数
---@param min_score number 最小分数
---@param max_score number 最大分数
---@param all_teams table<number, number[]> 匹配队伍列表，key为队伍人数，value为队伍ID列表
---@param used_teams table<number, number> 已匹配的队伍
---@param match_teams table<number, number> 匹配的队伍
---@param need_score boolean 是否需要分数
---@return boolean 是否找到
function MatchMgr.FindFitTeam(now_count, need_human, min_score, max_score, all_teams, used_teams, match_teams,need_score)
    if now_count == MatchEnum.HUMAN_COUNT then return true end
    if table.size(all_teams[need_human]) <= 0 then
        for i = need_human - 1, 1, -1 do
            if MatchMgr.FindFitTeam(now_count, i, min_score, max_score, all_teams, used_teams, match_teams, need_score) then
                return true
            end
        end
        return false
    end
    for k, v in ipairs(all_teams[need_human]) do
        repeat
            local team_id = v
            -- 过滤掉已经匹配的队伍
            if used_teams[team_id] or match_teams[team_id] then
                break
            end
            if need_score then
                 local team_info = context.all_teams[team_id]
                 if not team_info then
                     break
                 end
                 -- 过滤掉不在积分范围内的队伍
                 local rank_score = team_info.match_data.rank_score
                 if rank_score < min_score or rank_score > max_score then
                     break
                 end
            end
            local cur_team_count = MatchMgr.GetTeamMemberCount(team_id)
            now_count = now_count + cur_team_count
            match_teams[team_id] = need_human
            if now_count == MatchEnum.HUMAN_COUNT then
                return true
            end
            -- 继续找
            for i = MatchEnum.HUMAN_COUNT - now_count, 1, -1 do
                if MatchMgr.FindFitTeam(now_count, i, min_score, max_score, all_teams, used_teams, match_teams,need_score) then
                    return true
                end
            end
            now_count = now_count - cur_team_count
            match_teams[team_id] = nil
        until true
    end
    return false
end
-- 查找适合的鬼的队伍
---@param min_ghost_score number 最小分数
---@param max_ghost_score number 最大分数
---@param all_teams table<number, number[]> 匹配队伍列表，key为队伍人数，value为队伍ID列表
---@param used_ghost_teams table<number, boolean> 已匹配的鬼队伍
---@param need_score boolean 是否需要分数
---@return boolean 是否找到
---@return number 鬼队伍ID
function MatchMgr.FindFitGhostTeam(min_ghost_score, max_ghost_score, all_teams, used_ghost_teams,need_score)
    if table.size(all_teams[6]) > 0 then
        for k, v in ipairs(all_teams[6]) do
            repeat
                local ghost_team_id = v
                -- 过滤掉已经匹配的鬼队伍
                if used_ghost_teams[ghost_team_id] then
                    break
                end
                if need_score then
                    local team_info = context.all_teams[ghost_team_id]
                    if not team_info then
                        break
                    end
                    -- 过滤掉不在分值范围内的队伍
                    local rank_score = team_info.match_data.rank_score
                    if rank_score < min_ghost_score or rank_score > max_ghost_score then
                        break
                    end
                    return true, ghost_team_id
                else
                    return true, ghost_team_id
                end
            until true
        end
    end
    return false,0
end
-- 取得队伍的分数范围
function MatchMgr.GetRankRange(team_id, match_type)
    local min_score, max_score, min_ghost_score, max_ghost_score, max_ghost_break = 0, 0, 0, 0, 0
    local now_time = moon.time()
    
    local curIdx = 1
    local team_info = context.all_teams[team_id]
    if team_info then
        local camp_type = team_info.match_data.camp_type
        local match_data = team_info.match_data
        local expand_num = (now_time - match_data.match_time) / MatchEnum.MATCH_EXPAND_TIME
        local rank_score = team_info.match_data.rank_score
        if match_type == MatchEnum.MATCH_TYPE_DEF.MATCH_TYPE_NORMAL then
            for i = 1, #context.level_pool do
                if rank_score >= context.level_pool[i] then
                    curIdx = i
                else
                    break
                end
            end
            min_score = context.level_pool[curIdx]
            max_score = context.level_pool[curIdx + 1] or MatchEnum.MATCH_MAX_STAR
            min_ghost_score = context.level_pool[curIdx]
            max_ghost_score = context.level_pool[curIdx + 1] or MatchEnum.MATCH_MAX_STAR
            max_ghost_break = context.level_pool[curIdx + 2] or MatchEnum.MATCH_MAX_STAR
            if table.size(team_info.members) == MatchEnum.HUMAN_COUNT and
                now_time - match_data.match_time > MatchEnum.MATCH_FIVE_TIMEOUT then
                min_ghost_score = context.level_pool[curIdx - 1] or 0
            end
        elseif match_type == MatchEnum.MATCH_TYPE_DEF.MATCH_TYPE_RANKING then
            for i = 1, #context.rank_score_pool do
                if rank_score >= context.rank_score_pool[i] then
                    curIdx = i
                else
                    break
                end
            end
            min_score = context.rank_score_pool[curIdx]
            max_score = context.rank_score_pool[curIdx + 1] or MatchEnum.MATCH_MAX_STAR
            min_ghost_score = context.rank_score_pool[curIdx]
            max_ghost_score = context.rank_score_pool[curIdx + 1] or MatchEnum.MATCH_MAX_STAR
            max_ghost_break = context.rank_score_pool[curIdx + 2] or MatchEnum.MATCH_MAX_STAR
            if table.size(team_info.members) == MatchEnum.HUMAN_COUNT and
                now_time - match_data.match_time > MatchEnum.MATCH_FIVE_TIMEOUT then
                min_ghost_score = context.rank_score_pool[curIdx - 1] or 0
            end
        end
    end
    return min_score, max_score, min_ghost_score, max_ghost_score,max_ghost_break
end
--普通匹配
function MatchMgr.DoNormalMatch()
  
    local now_time = moon.clock()
    local mapMatching = context.matching_teams[MatchEnum.MATCH_TYPE_DEF.MATCH_TYPE_NORMAL]
    if table.size(mapMatching) == 0 then return end
    -- 分装队伍
    local human_count, ghost_count, all_teams = MatchMgr.WrapTeam(mapMatching)
     
    -- 排序
    MatchMgr.SortTeam(all_teams)
    moon.info(string.format("NormalMatch human_count = %d, ghost_count = %d,cost=%.3f", human_count, ghost_count, moon.clock() - now_time)) 
    -- 没有玩家退出匹配
    if human_count == 0 and ghost_count == 0 then return end
    -- 匹配队伍(不带AI)
    now_time = moon.clock()
    local mapRoom = MatchMgr.MatchTeam(all_teams, MatchEnum.MATCH_TYPE_DEF.MATCH_TYPE_NORMAL, mapMatching)
    moon.info(string.format("NormalMatch MatchTeam match_num=%d, cost=%.3f", table.size(mapRoom), moon.clock() - now_time))
    -- 匹配队伍（带AI）
    --[[
    now_time = moon.clock()
    local mapRoomAI = MatchMgr.MatchTeamAI(all_teams, MatchEnum.MATCH_TYPE_DEF.MATCH_TYPE_NORMAL)
    moon.info(string.format("NormalMatch MatchTeamAI match_num=%d, cost=%.3f", table.size(mapRoomAI), moon.clock() - now_time))
    ]]


end
-- 排位匹配
function MatchMgr.DoRankingMatch()
end
-- 狼人杀匹配
function MatchMgr.DoLRSMatch()
end
-- 驱灵匹配
function MatchMgr.DoQLMatch()
end
-- 据点战匹配
function MatchMgr.DoJDZMatch()
end
-- 创建匹配房间
function MatchMgr.CreateMatchRoom(uid, team_id, match_type, camp_type, need_ai)
     
    local room_id = uuid.next()
    local conf = {
        name = "matchroom" .. room_id,
        file = "matchroom/service_matchroom.lua"
    }
    local addr_room = moon.new_service(conf)
    if addr_room == 0 then
        return { code = ErrorCode.CreateMatchRoomServiceErr, error = "create matchroom service failed!" }
    end
    -- 初始化房间数据
    local res, err = moon.call("lua", addr_room, "MatchRoom.InitData", room_id,
        match_type, addr_room)
    if not res then
        return { code = ErrorCode.InitChatChannelDataErr, error = err }
    end
    context.rooms[match_type][room_id] = {
        room_id = room_id,
        addr_room = addr_room
    }
    return { code = ErrorCode.None, room_id = room_id, addr_room = addr_room }
end

-- 房主请求开始匹配
function MatchMgr.MatchReq(uid, team_id, match_type, camp_type, need_ai)
    -- 检查队伍是否在申请队列中
    local apply_time = context.applying_teams[team_id]
    if apply_time then
        return { code = ErrorCode.TeamAlreadyInApplyMatch, error = "Team already in apply!" }
    end
    -- 检查队伍是否存在
    local team_info = context.all_teams[team_id]
    if team_info then
        return { code = ErrorCode.TeamAlreadyInMatch, error = "Team already in match!" }
    end
    -- 向队伍管理器初始化队伍匹配数据
    local res, err = cluster.call(CmdEnum.FixedNodeId.MANAGER, "teammgr", "Teammgr.InitMatchData",
        team_id, match_type, camp_type, need_ai)
    if not res then
        return { code = ErrorCode.InitMatchDataErr, error = err }
    end
    context.all_teams[team_id] = res.team_info
    context.applying_teams[team_id] = moon.time()
    return { code = ErrorCode.None }
end
-- 删除匹配队伍
function MatchMgr.DeleteTeam(team_id)
    context.all_teams[team_id] = nil
    context.applying_teams[team_id] = nil
    return { code = ErrorCode.None }
end
-- 开始匹配
function MatchMgr.StartMatch(team_id)
    local team_info = context.all_teams[team_id]
    if not team_info then
        return { code = ErrorCode.TeamNotExist, error = "Team not exist!" }
    end
    -- 移除申请匹配的队伍的列表
    context.applying_teams[team_id] = nil
    -- 通知队伍管理器开始匹配
    local res, err = cluster.call(CmdEnum.FixedNodeId.MANAGER, "teammgr", "Teammgr.StartMatch", team_id)
    if not res then
        moon.error("StartMatch failed:", err)
        return { code = ErrorCode.StartMatchErr, error = err }
    end
    if res.code ~= ErrorCode.None then
        return { code = res.code, error = res.error }
    end
    -- 更新队伍数据
    context.all_teams[team_id] = res.team_info
    -- 添加到对应模式的匹配队列
    context.matching_teams[team_info.match_data.match_type][team_id] = moon.time()
    return { code = ErrorCode.None, team_info = res.team_info }
end
 
return MatchMgr