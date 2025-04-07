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
        context.S2C(CmdCode.PBTeamCreateRspCmd, {
            code = ErrorCode.TeamAlreadyInTeam
        })
        return ErrorCode.TeamAlreadyInTeam
    end
    
    -- 调用teammgr服务创建队伍
    local team_id, err = cluster.call(9999, "teammgr", "Teammgr.CreateTeam", req.uid, req.match_type, req.base_data)
    if not team_id then
        context.S2C(CmdCode.PBTeamCreateRspCmd, {
            code = err or ErrorCode.TeamCreateFailed
        })
        return err or ErrorCode.TeamCreateFailed
    end
    
    -- 返回队伍ID
    context.S2C(CmdCode.PBTeamCreateRspCmd, {
        code = ErrorCode.None,
        teamId = team_id
    })
    
    return ErrorCode.None
end

-- 加入队伍
function Team.PBTeamJoinReqCmd(req)
    -- 如果已经在队伍中则不能加入
    local DB = scripts.UserModel.Get()
    if DB.team.team_id ~= 0 then
        context.S2C(CmdCode.PBTeamJoinRspCmd, {
            code = ErrorCode.TeamAlreadyInTeam
        })
        return ErrorCode.TeamAlreadyInTeam
    end
    
    -- 调用teammgr服务加入队伍
    local success, err = cluster.call(9999, "teammgr", "Teammgr.JoinTeam", req.uid, req.team_id, req.base_data)
    if not success then
        context.S2C(CmdCode.PBTeamJoinRspCmd, {
            code = err or ErrorCode.TeamJoinFailed
        })
        return err or ErrorCode.TeamJoinFailed
    end
    
    -- 返回加入成功
    context.S2C(CmdCode.PBTeamJoinRspCmd, {
        code = ErrorCode.None,
        master_uid = req.master_uid,
        team_id = req.team_id
    })
    
    return ErrorCode.None
end

-- 退出队伍
function Team.PBTeamExitReqCmd(req)
    -- 如果不在队伍中则不能退出
    local DB = scripts.UserModel.Get()
    if DB.team.team_id == 0 then
        context.S2C(CmdCode.PBTeamExitRspCmd, {
            code = ErrorCode.TeamNotInTeam
        })
        return ErrorCode.TeamNotInTeam
    end
    
    -- 调用teammgr服务退出队伍
    local success, err = cluster.call(9999, "teammgr", "Teammgr.ExitTeam", req.uid)
    if not success then
        context.S2C(CmdCode.PBTeamExitRspCmd, {
            code = err or ErrorCode.TeamExitFailed
        })
        return err or ErrorCode.TeamExitFailed
    end
    
    -- 返回退出成功
    context.S2C(CmdCode.PBTeamExitRspCmd, {
        code = ErrorCode.None
    })
    
    return ErrorCode.None
end

-- 踢出队员
function Team.PBTeamKickoutReqCmd(req)
    -- 如果不是队长则不能踢人
    local DB = scripts.UserModel.Get()
    if DB.team.master_id ~= req.uid then
        context.S2C(CmdCode.PBTeamKickoutRspCmd, {
            code = ErrorCode.TeamNotMaster
        })
        return ErrorCode.TeamNotMaster
    end
    
    -- 调用teammgr服务踢出队员
    local success, err = cluster.call(9999, "teammgr", "Teammgr.KickoutMember", req.uid, req.target_uid)
    if not success then
        context.S2C(CmdCode.PBTeamKickoutRspCmd, {
            code = err or ErrorCode.TeamKickoutFailed
        })
        return err or ErrorCode.TeamKickoutFailed
    end
    
    -- 返回踢出成功
    context.S2C(CmdCode.PBTeamKickoutRspCmd, {
        target_uid = req.target_uid,
        code = ErrorCode.None
    })
    
    return ErrorCode.None
end

-- 获取队伍信息
function Team.PBTeamInfoReqCmd()
    local DB = scripts.UserModel.Get()
    
    -- 如果不在队伍中则返回错误码
    if DB.team.team_id == 0 then
        context.S2C(CmdCode.PBTeamInfoRspCmd, {
            code = ErrorCode.TeamNotInTeam,
            team_info = nil
        })
        return
    end
    
    -- 从teammgr服务获取队伍信息
    local team_info, err = cluster.call(9999, "teammgr", "Teammgr.GetTeamInfo", DB.team.team_id)
    if not team_info then
        context.S2C(CmdCode.PBTeamInfoRspCmd, {
            code = err or ErrorCode.TeamGetInfoFailed,
            team_info = nil
        })
        return
    end
    
    -- 返回队伍信息
    context.S2C(CmdCode.PBTeamInfoRspCmd, {
        code = ErrorCode.None,
        team_info = team_info
    })
end

return Team