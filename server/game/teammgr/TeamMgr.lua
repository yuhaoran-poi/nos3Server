local moon = require "moon"
local uuid = require("uuid")
local common = require "common"
local CmdCode = common.CmdCode
local ErrorCode = common.ErrorCode

---@type teammgr_context
local context = ...

---@class TeamMgr
local TeamMgr = {}

-- 队伍数据存储
local teams = {
    tidmap = {}, -- 队伍ID -> 队伍信息 map<team_id, team_info>
    uidmap = {} -- 用户ID -> 队伍ID map<uid, team_id>
}

function TeamMgr.Init()
    return true
end

function TeamMgr.Start()
    return true
end

-- 创建队伍
function TeamMgr.CreateTeam(uid, match_type, base_data)
    -- 检查用户是否已在队伍中
    if teams.uidmap[uid] then
        return nil, ErrorCode.TeamAlreadyInTeam
    end
    
    -- 生成唯一队伍ID
    local team_id = uuid.next()
    
    -- 创建队伍数据
    teams.tidmap[team_id] = {
        team_id = team_id,
        master_uid = uid,
        match_type = match_type,
        base_data = base_data,
        members = {[uid] = true}
    }
    -- 更新uidmap
    teams.uidmap[uid] = team_id
    
    -- 广播队伍创建事件
    moon.send("lua", moon.queryservice("user"), "OnTeamCreated", uid, team_id)
    
    return team_id
end

-- 加入队伍
function TeamMgr.JoinTeam(uid, team_id, base_data)
    -- 检查用户是否已在其他队伍中
    if teams.uidmap[uid] then
        return false, ErrorCode.TeamAlreadyInTeam
    end
    
    local team = teams.tidmap[team_id]
    if not team then
        return false, ErrorCode.TeamNotExist
    end
    
    -- 检查队伍是否已满(假设最大5人)
    if #team.members >= 5 then
        return false, ErrorCode.TeamFull
    end
    
    -- 添加成员
    team.members[uid] = true
    -- 更新uidmap
    teams.uidmap[uid] = team_id
    
    -- 广播成员加入事件
    moon.send("lua", moon.queryservice("user"), "OnTeamMemberJoined", team_id, uid)
    
    return true
end

-- 退出队伍
function TeamMgr.ExitTeam(uid)
    -- 查找用户所在的队伍
    local team_id = teams.uidmap[uid]
    if not team_id then
        return false, ErrorCode.TeamNotInTeam
    end
    
    local team = teams.tidmap[team_id]
    if not team then
        teams.uidmap[uid] = nil
        return false, ErrorCode.TeamDataCorrupted
    end
    
    -- 移除成员
    team.members[uid] = nil
    -- 更新uidmap
    teams.uidmap[uid] = nil
    
    -- 如果是队长退出且队伍还有成员，需要转移队长
    if team.master_uid == uid and next(team.members) then
        for new_master_uid, _ in pairs(team.members) do
            team.master_uid = new_master_uid
            break
        end
        -- 广播队长变更事件
        moon.send("lua", moon.queryservice("user"), "OnTeamMasterChanged", team_id, team.master_uid)
    end
    
    -- 如果队伍没有成员了，则删除队伍
    if not next(team.members) then
        teams.tidmap[team_id] = nil
    end
    
    -- 广播成员退出事件
    moon.send("lua", moon.queryservice("user"), "OnTeamMemberExited", team_id, uid)
    
    return true
end

-- 踢出队员
function TeamMgr.KickoutMember(master_uid, target_uid)
    -- 查找队长所在的队伍
    local team_id = teams.uidmap[master_uid]
    local team = teams.tidmap[team_id]
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
    teams.uidmap[target_uid] = nil
    
    -- 广播成员被踢出事件
    moon.send("lua", moon.queryservice("user"), "OnTeamMemberKicked", team_id, target_uid)
    
    return true
end

-- 获取队伍信息
function TeamMgr.GetTeamInfo(team_id)
    local team = teams.tidmap[team_id]
    if not team then
        return nil
    end
    return team
end

return TeamMgr