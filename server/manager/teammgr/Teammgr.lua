local moon = require "moon"
local cluster = require("cluster")
local uuid = require("uuid")
local common = require "common"
local ChatLogic = require("common.logic.ChatLogic") --聊天逻辑
local MatchEnum = require("common.Enum.MatchEnum") --匹配类型枚举
local CmdCode = common.CmdCode
local ErrorCode = common.ErrorCode

---@type teammgr_context
local context = ...

---@class Teammgr
local Teammgr = {}

 
function Teammgr.Init()
    return true
end

function Teammgr.Start()
    return true
end
 
-- 创建队伍
function Teammgr.CreateTeam(uid, match_type, simple_data)
    -- 检查用户是否已在队伍中
    if context.user_team[uid] then
        return nil, ErrorCode.TeamAlreadyInTeam
    end
    
    -- 生成唯一队伍ID
    local team_id = uuid.next()
    -- 创建队伍数据
    context.team_info[team_id] = {
        team_id = team_id,
        master_uid = uid,
        match_type = match_type,
        members = { [uid] = simple_data }
    }
    -- 更新uidmap
    context.user_team[uid] = team_id
    
    context.send_user(uid, "Team.OnTeamCreated", uid, team_id)
    ChatLogic.newTeamChannel(team_id)
    ChatLogic.JoinTeamChannel(team_id, uid)
    return team_id
end

-- 加入队伍
function Teammgr.JoinTeam(uid, team_id, simple_data)
    -- 检查用户是否已在其他队伍中
    if context.user_team[uid] then
        return false, ErrorCode.TeamAlreadyInTeam
    end
    
    local team = context.team_info[team_id]
    if not team then
        return false, ErrorCode.TeamNotExist
    end
    
    -- 检查队伍是否已满(假设最大5人)a
    if #team.members >= 5 then
        return false, ErrorCode.TeamFull
    end
    
    -- 添加成员
    team.members[uid] = simple_data
    -- 更新uidmap
    context.user_team[uid] = team_id
   
    -- 广播成员加入事件
    local member_keys = {}
    for k,_ in pairs(team.members) do
        table.insert(member_keys, k)
    end
    context.send_users(member_keys, {}, "Team.OnTeamMemberJoined", team_id, uid)

    ChatLogic.JoinTeamChannel(team_id, uid)
    return true
end

-- 退出队伍
function Teammgr.ExitTeam(uid)
    -- 查找用户所在的队伍
    local team_id = context.user_team[uid]
    if not team_id then
        return false, ErrorCode.TeamNotInTeam
    end
    
    local team = context.team_info[team_id]
    if not team then
        context.user_team[uid] = nil
        return false, ErrorCode.TeamDataCorrupted
    end
    
    -- 移除成员
    team.members[uid] = nil
    -- 更新uidmap
    context.user_team[uid] = nil
    
    -- 如果是队长退出且队伍还有成员，需要转移队长
    if team.master_uid == uid and next(team.members) then
        for new_master_uid, _ in pairs(team.members) do
            team.master_uid = new_master_uid
            break
        end
        -- 广播队长变更事件
        local member_keys = {}
        for k,_ in pairs(team.members) do
            table.insert(member_keys, k)
        end
        context.send_users(member_keys, {}, "Team.OnTeamMasterChanged", team_id, team.master_uid)
    end
    
    -- 如果队伍没有成员了，则删除队伍
    if not next(team.members) then
        context.team_info[team_id] = nil
        context.send_user(uid, "Team.OnTeamMemberExited", team_id, uid)
        ChatLogic.LeaveTeamChannel(team_id, uid)
        ChatLogic.RemoveTeamChannel(team_id)
    else
        -- 广播成员退出事件
        local member_keys = {}
        for k,_ in pairs(team.members) do
            table.insert(member_keys, k)
        end
        context.send_users(member_keys, {}, "Team.OnTeamMemberExited", team_id, uid)
        ChatLogic.LeaveTeamChannel(team_id, uid)
    end
    return true
end

-- 踢出队员
function Teammgr.KickoutMember(master_uid, target_uid)
    -- 查找队长所在的队伍
    local team_id = context.user_team[master_uid]
    local team = context.team_info[team_id]
    if not team then
        return false, ErrorCode.TeamNotExist
    end

    -- 检查是否队长
    if team.master_uid ~= master_uid then
        return false, ErrorCode.TeamNotMaster
    end
      
    -- 移除目标成员
    team.members[target_uid] = nil
    -- 更新uidmap
    context.user_team[target_uid] = nil
    ChatLogic.LeaveTeamChannel(team_id, target_uid)
    -- 广播成员被踢出事件
    context.send_user(target_uid, "Team.OnTeamMemberKicked", team_id, target_uid)
    
    return true
end

-- 获取队伍信息
function Teammgr.GetTeamInfo(team_id)
    local team = context.team_info[team_id]
    if not team then
        return nil
    end
    return team
end
-- 获取队伍匹配信息
function Teammgr.GetTeamMatchInfo(team_id, match_type)
    local team = context.team_info[team_id]
    if not team then
        return nil
    end
    team.match_type = match_type

    return team.match_info
end
-- 计算队伍分数
function Teammgr.CalcTeamScore(team_id)
    local RankScore = 0
    local team = context.team_info[team_id]
    if not team then
        return RankScore
    end
    if team.match_type ~= MatchEnum.MATCH_TYPE_DEF.MATCH_TYPE_NORMAL and
        team.match_type ~= MatchEnum.MATCH_TYPE_DEF.MATCH_TYPE_RANKING then
        return RankScore
    end
    

end
 
return Teammgr