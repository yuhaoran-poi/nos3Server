local moon = require "moon"
local common = require "common"
local LuaExt =  common.LuaExt
local ErrorCode = common.ErrorCode --逻辑错误码
local ChatLogic = require("common.logic.ChatLogic") --聊天逻辑
local MatchEnum = require("common.Enum.MatchEnum")  --匹配类型枚举
local RankScoreDef = require("common.def.RankScoreDef") --排行榜定义
local RankScoreLogic = require("common.logic.RankScoreLogic") --排行榜逻辑
local cluster = require("cluster")
local CmdEnum = require("common.Enum.CmdEnum") --命令枚举
local CmdCode = common.CmdCode   --命令码
local GameCfg = common.GameCfg
---@class Team
---@field team_info TeamDataClass
---@field context teammgr_context
local Team = LuaExt.class()

--- 初始化队伍
--- @param team_info TeamDataClass
--- @param context teammgr_context
function Team:InitData(team_info, context)
    self.team_info = team_info
    self.context = context
end
-- 初始化队伍匹配数据
function Team:InitMatchData(match_type, camp_type, need_ai)
     
    local team_info = self.team_info
    local match_data = team_info.match_data
    match_data.match_type = match_type
    match_data.camp_type = camp_type
    match_data.need_ai = need_ai
    match_data.team_state = MatchEnum.MatchTeamState.MatchTeamState_Confirm
    -- 广播队伍匹配确认请求事件
    self.context.send_users(self:GetTeamMemberKeys(), {}, "TeamProxy.OnPBNotifyMatchConfirmAck", team_info.team_id,
    match_type, camp_type)
    return team_info
end
-- 加入队伍
--- @param uid number
--- @param simple_data PBUserSimpleInfo
function Team:JoinTeam(uid, simple_data)
   
    local context = self.context
    local team_info = self.team_info
    local team_id = team_info.team_id
    -- 检查队伍是否已满(假设最大5人)
    if table.size(team_info.members) >= 5 then
        return {code = ErrorCode.TeamFull}
    end
    -- 检查用户是否已在队伍中
    if team_info.members[uid] then
        return {code = ErrorCode.TeamAlreadyInTeam}
    end
    -- 加入队伍
    team_info.members[uid] = simple_data
    context.user_team[uid] = team_id
    context.send_user(uid, "TeamProxy.OnTeamJoined", team_id, team_info.master_uid)
    -- 广播成员加入事件
    context.send_users(self:GetTeamMemberKeys(), {}, "TeamProxy.OnTeamMemberJoined", team_id, uid)
    ChatLogic.JoinTeamChannel(team_id, uid)
    return {code = ErrorCode.None,master_uid = team_info.master_uid}
end
-- 退出队伍
--- @param uid number
function Team:ExitTeam(uid)
    local context = self.context
    local team_info = self.team_info
    local team_id = team_info.team_id
    -- 移除成员
    team_info.members[uid] = nil
    -- 更新uidmap
    context.user_team[uid] = nil


    -- 如果是队长退出且队伍还有成员，需要转移队长
    if team_info.master_uid == uid and next(team_info.members) then
        for new_master_uid, _ in pairs(team_info.members) do
            team_info.master_uid = new_master_uid
            break
        end
        -- 广播队长变更事件
        context.send_users(self:GetTeamMemberKeys(), {}, "TeamProxy.OnTeamMasterChanged", team_id, team_info.master_uid)
    end

    -- 如果队伍没有成员了，则删除队伍
    if not next(team_info.members) then
        context.team_class[team_id] = nil
        context.send_user(uid, "TeamProxy.OnTeamMemberExited", team_id, uid)
        ChatLogic.LeaveTeamChannel(team_id, uid)
        ChatLogic.RemoveTeamChannel(team_id)
    else
        -- 广播成员退出事件
        context.send_users(self:GetTeamMemberKeys(), {}, "TeamProxy.OnTeamMemberExited", team_id, uid)
        ChatLogic.LeaveTeamChannel(team_id, uid)
    end
    return true, ErrorCode.None
end

-- 踢出队伍成员
--- @param operater_uid number
--- @param target_uid number
function Team:KickoutMember(operater_uid, target_uid)
    local context = self.context
    local team_info = self.team_info
    local team_id = team_info.team_id
    -- 检查是否有权限踢出成员
    if team_info.master_uid ~= operater_uid then
        return false, ErrorCode.TeamNotMaster
    end
    -- 检查目标用户是否在队伍中
    if not team_info.members[target_uid] then
        return false, ErrorCode.TeamNotInTeam
    end
    -- 踢出成员
    team_info.members[target_uid] = nil
    -- 更新uidmap
    context.user_team[target_uid] = nil
    -- 广播成员退出事件
    context.send_users(self:GetTeamMemberKeys(), {}, "TeamProxy.OnTeamMemberExited", team_id, target_uid)
    ChatLogic.LeaveTeamChannel(team_id, target_uid)
    return true, ErrorCode.None
end
-- 计算队伍平均分数
--- @return number
function Team:CalcAverageScore()
    local team_info = self.team_info
    local RankScore = 0
    local match_data = team_info.match_data
    if match_data.match_type ~= MatchEnum.MATCH_TYPE_DEF.MATCH_TYPE_NORMAL and
        match_data.match_type ~= MatchEnum.MATCH_TYPE_DEF.MATCH_TYPE_RANKING then
        return RankScore
    end
    local TotalScore = 0
    if match_data.match_type == MatchEnum.MATCH_TYPE_DEF.MATCH_TYPE_RANKING then
        for _, simple_data in pairs(team_info.members) do
            local RankData = RankScoreDef.newRankScoreData()
            RankData.nCampType = match_data.camp_type
            if match_data.camp_type == MatchEnum.MATCH_CAMP_DEF.MATCH_CAMP_GHOST then
                RankData.nGrade = simple_data.rank_level.ghost_rank.grade
                RankData.nLevel = simple_data.rank_level.ghost_rank.level
                RankData.nStarNum = simple_data.rank_level.ghost_rank.star
            else
                RankData.nGrade = simple_data.rank_level.human_rank.grade
                RankData.nLevel = simple_data.rank_level.human_rank.level
                RankData.nStarNum = simple_data.rank_level.human_rank.star
            end
            TotalScore = TotalScore + RankScoreLogic:GetRankScore(RankData)
        end
        RankScore = TotalScore / table.size(team_info.members)
        match_data.average_level = self:CalcAverageLevel()
    else
        RankScore = self:CalcAverageLevel()
        match_data.average_level = RankScore
    end
    match_data.rank_score = RankScore
    return RankScore
end

-- 计算队伍平均等级
--- @return number
function Team:CalcAverageLevel()
    local team_info = self.team_info
    local TotalLevel = 0
    for _, simple_data in pairs(team_info.members) do
        TotalLevel = TotalLevel + simple_data.account_level
    end
    return TotalLevel / table.size(team_info.members)
end

-- 获取队伍匹配类型
--- @return number
function Team:GetMatchType()
    local team_info = self.team_info
    local match_data = team_info.match_data
    return match_data.match_type
end

-- 检查是否主播队伍
--- @return boolean
function Team:IsCamerTeam()
    local team_info = self.team_info
    local match_data = team_info.match_data
    for k, _ in pairs(team_info.members) do
        local cfg = GameCfg.Carmer[k]
        if cfg then
            match_data.is_camer = true
            return true
        end
    end
    return false
end

-- 开始匹配
--- @return TeamDataClass
function Team:StartMatch()
    local context = self.context
    local team_info = self.team_info
    local match_data = team_info.match_data
    -- 设置匹配时间
    match_data.match_time = moon.time()
    -- 计算排位分
    self:CalcAverageScore()
    -- 判断是否是主播队伍
    self:IsCamerTeam()
    -- 设置流程状态
    match_data.team_state = MatchEnum.MatchTeamState.MatchTeamState_Matching
    -- 广播匹配开始事件
    context.send_users(self:GetTeamMemberKeys(), {}, "TeamProxy.OnTeamStatus", team_info.team_id, match_data.team_state)
    return team_info
end
 
-- 确认匹配
 
function Team:ConfirmMatch(uid, is_agree)
    local context = self.context
    local team_info = self.team_info
    local match_data = team_info.match_data
    -- 是否成员
    if not team_info.members[uid] then
        return { code = ErrorCode.TeamNotInTeam }
    end
    -- 检查是否已经确认
    if match_data.team_state ~= MatchEnum.MatchTeamState.MatchTeamState_Confirm then
        return { code = ErrorCode.MatchNotInConfirm }
    end
    if not is_agree then
        -- 取消匹配
        -- 通知匹配管理器删除队伍
        local res, err = cluster.call(CmdEnum.FixedNodeId.MATCH, "matchmgr", "MatchMgr.DeleteTeam", team_info.team_id)
        if not res then
            moon.error("delete team failed! err = %s", err)
            return { code = ErrorCode.DeleteMatchTeamErr, error = err }
        end
        if res.code ~= ErrorCode.None then
            return { code = res.code, error = res.error }
        end
        -- 广播匹配取消事件
        local PBMatchNotifyFailCmd = {
            code = ErrorCode.MatchCanceled,
            uid = uid,
        }
        self:BroadcastMsg(CmdCode["PBMatchNotifyFailCmd"], PBMatchNotifyFailCmd)

        return { code = ErrorCode.None }
    end
    match_data.members_confirm[uid] = is_agree
    -- 广播确认事件
    self:BroadcastMsg(CmdCode["PBMatchNotifyConfirmCmd"], { uid = uid})
    -- 检查是否所有成员都确认
    if table.size(match_data.members_confirm) == table.size(team_info.members) then
        -- 检查是否所有成员都同意
        for _, v in pairs(match_data.members_confirm) do
            if not v then
                return { code = ErrorCode.None }
            end
        end
        -- 所有成员都同意，通知匹配管理器开始匹配
        local res, err = cluster.call(CmdEnum.FixedNodeId.MATCH, "matchmgr", "MatchMgr.StartMatch", team_info.team_id)
        if not res then
            moon.error("MatchMgr.StartMatch failed! err =", err)
            return { code = ErrorCode.StartMatchErr, error = err }
        end
        if res.code ~= ErrorCode.None then
            return { code = res.code, error = res.error }
        end
    end
    return { code = ErrorCode.None } 
end

-- 广播消息
function Team:BroadcastMsg(msg_type, msg)
    local context = self.context
    context.send_users(self:GetTeamMemberKeys(), {}, "User.OnMsgS2C", msg_type, msg)
end
-- 广播消息到User
function Team:GetTeamMemberKeys()
    local team_info = self.team_info
    local member_keys = {}
    for k, _ in pairs(team_info.members) do
        table.insert(member_keys, k)
    end
    return member_keys
end

return Team