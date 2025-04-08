local moon = require "moon"
local common = require "common"
local cluster = require("cluster")
local GameCfg = common.GameCfg
local ErrorCode = common.ErrorCode
local CmdCode = common.CmdCode

---@type user_context
local context = ...
local scripts = context.scripts

---@class Team
local Team = {}

function Team.Init()
    local data = scripts.UserModel.Get()
    if not data.team then
        data.team = {
            team_id = 0,
            master_id = 0,
            members = {},
            match_type = 0,
            user_list = {},
            is_del = false
        }
    end
end

function Team.Start()
    -- body
end

-- 创建队伍
function Team.PBTeamCreateReqCmd(req)
    -- 如果已经在队伍中则不能创建
   
    local DB = scripts.UserModel.Get()
    if DB.team.team_id ~= 0 then
        context.R2C(CmdCode.PBTeamCreateRspCmd, {
            code = ErrorCode.TeamAlreadyInTeam
        })
        return ErrorCode.TeamAlreadyInTeam
    end
    
    -- 调用teammgr服务创建队伍
    local team_id, err = cluster.call(3999, "teammgr", "Teammgr.CreateTeam", context.uid, req.msg.match_type, DB.simple)
    if not team_id then
        print("CreateTeam failed:", err)
        context.R2C(CmdCode.PBTeamCreateRspCmd, {
            code = err or ErrorCode.TeamCreateFailed
        })
        return err or ErrorCode.TeamCreateFailed
    end
    
    -- 返回队伍ID
    context.R2C(CmdCode.PBTeamCreateRspCmd, {
        code = ErrorCode.None,
        teamId = team_id
    },req)
    
    return ErrorCode.None
end

-- 加入队伍
function Team.PBTeamJoinReqCmd(req)
    -- 如果已经在队伍中则不能加入
    local DB = scripts.UserModel.Get()
    if DB.team.team_id ~= 0 then
        context.R2C(CmdCode.PBTeamJoinRspCmd, {
            code = ErrorCode.TeamAlreadyInTeam
        },req)
        return ErrorCode.TeamAlreadyInTeam
    end
    
    -- 调用teammgr服务加入队伍
    local success, err = cluster.call(3999, "teammgr", "Teammgr.JoinTeam", req.uid, req.team_id, req.base_data)
    if not success then
        print("JoinTeam failed:", err)
        context.R2C(CmdCode.PBTeamJoinRspCmd, {
            code = err or ErrorCode.TeamJoinFailed
        },req)
        return err or ErrorCode.TeamJoinFailed
    end
    
    -- 返回加入成功
    context.R2C(CmdCode.PBTeamJoinRspCmd, {
        code = ErrorCode.None,
        master_uid = req.master_uid,
        team_id = req.team_id
    },req)
    
    return ErrorCode.None
end

-- 退出队伍
function Team.PBTeamExitReqCmd(req)
    -- 如果不在队伍中则不能退出
    local DB = scripts.UserModel.Get()
    if DB.team.team_id == 0 then
        context.R2C(CmdCode.PBTeamExitRspCmd, {
            code = ErrorCode.TeamNotInTeam
        },req)
        return ErrorCode.TeamNotInTeam
    end
    
    -- 调用teammgr服务退出队伍
    local success, err = cluster.call(3999, "teammgr", "Teammgr.ExitTeam", req.uid)
    if not success then
        print("ExitTeam failed:", err)
        context.R2C(CmdCode.PBTeamExitRspCmd, {
            code = err or ErrorCode.TeamExitFailed
        },req)
        return err or ErrorCode.TeamExitFailed
    end
    
    -- 返回退出成功
    context.R2C(CmdCode.PBTeamExitRspCmd, {
        code = ErrorCode.None
    },req)
    
    return ErrorCode.None
end

-- 踢出队员
function Team.PBTeamKickoutReqCmd(req)
    -- 如果不是队长则不能踢人
    local DB = scripts.UserModel.Get()
    if DB.team.master_id ~= req.uid then
        context.R2C(CmdCode.PBTeamKickoutRspCmd, {
            code = ErrorCode.TeamNotMaster
        },req)
        return ErrorCode.TeamNotMaster
    end
    
    -- 调用teammgr服务踢出队员
    local success, err = cluster.call(3999, "teammgr", "Teammgr.KickoutMember", req.uid, req.target_uid)
    if not success then
        print("KickoutMember failed:", err)
        context.R2C(CmdCode.PBTeamKickoutRspCmd, {
            code = err or ErrorCode.TeamKickoutFailed
        },req)
        return err or ErrorCode.TeamKickoutFailed
    end
    
    -- 返回踢出成功
    context.R2C(CmdCode.PBTeamKickoutRspCmd, {
        target_uid = req.target_uid,
        code = ErrorCode.None
    },req)
    
    return ErrorCode.None
end

-- 获取队伍信息
function Team.PBTeamInfoReqCmd(req)
    local DB = scripts.UserModel.Get()
    
    -- 如果不在队伍中则返回错误码
    if DB.team.team_id == 0 then
        context.R2C(CmdCode.PBTeamInfoRspCmd, {
            code = ErrorCode.TeamNotInTeam,
            team_info = nil
        },req)
        return
    end
    
    -- 从teammgr服务获取队伍信息
    local team_info, err = cluster.call(3999, "teammgr", "Teammgr.GetTeamInfo", DB.team.team_id)
    if not team_info then
        print("GetTeamInfo failed:", err)
        context.R2C(CmdCode.PBTeamInfoRspCmd, {
            code = err or ErrorCode.TeamGetInfoFailed,
            team_info = nil
        },req)
        return
    end
    
    -- 返回队伍信息
    context.R2C(CmdCode.PBTeamInfoRspCmd, {
        code = ErrorCode.None,
        team_info = team_info
    },req)
end

-- 队伍创建事件
function Team.OnTeamCreated(uid, team_id)
    local DB = scripts.UserModel.Get()
    DB.team.team_id = team_id
    DB.team.master_id = uid
    DB.team.members = {[uid] = true}
    DB.team.is_del = false
end

-- 队员加入事件
function Team.OnTeamMemberJoined(team_id, uid)
    local DB = scripts.UserModel.Get()
    if DB.team.team_id == team_id then
        DB.team.members[uid] = true
    end
end

-- 队长变更事件
function Team.OnTeamMasterChanged(team_id, new_master_uid)
    local DB = scripts.UserModel.Get()
    if DB.team.team_id == team_id then
        DB.team.master_id = new_master_uid
    end
end

-- 队员退出事件
function Team.OnTeamMemberExited(team_id, uid)
    local DB = scripts.UserModel.Get()
    if DB.team.team_id == team_id then
        DB.team.members[uid] = nil
        
        -- 如果退出的是自己，则清除队伍信息
        if uid == DB.uid then
            DB.team.team_id = 0
            DB.team.master_id = 0
            DB.team.members = {}
            DB.team.is_del = true
        end
    end
end

-- 队员被踢出事件
function Team.OnTeamMemberKicked(team_id, target_uid)
    local DB = scripts.UserModel.Get()
    if DB.team.team_id == team_id then
        DB.team.members[target_uid] = nil
        
        -- 如果被踢的是自己，则清除队伍信息
        if target_uid == DB.uid then
            DB.team.team_id = 0
            DB.team.master_id = 0
            DB.team.members = {}
            DB.team.is_del = true
        end
    end
end

return Team