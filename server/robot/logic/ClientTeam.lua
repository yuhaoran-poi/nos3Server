---@class Client
local Client = require "robot.logic.Client"

function Client:TestTeam()
    
end

-- 申请创建队伍
function Client:create_team()
    if not self.ok then
        print("connect failed, err = ", err)
        return
    end
    local req_msg = {
        uid = self.uid
    }
    self:send("PBTeamCreateReqCmd", req_msg, function(msg)
        print("rpc PBTeamCreateReqCmd ret = ", self.index,msg)
        print_r(msg)
        if msg.code == 0 then
            self.team_id = msg.team_id
        end
       
    end)
end


-- 申请加入队伍
function Client:join_team(teamId, master_id)
    teamId = tonumber(teamId)
    master_id = tonumber(master_id)
    if not self.ok then
        print("connect failed, err = ", err)
        return
    end
    local req_msg = {
        uid = self.uid,
        master_uid = master_id,
        team_id = teamId,
    }
    self:send("PBTeamJoinReqCmd", req_msg, function(msg)
        print("rpc PBTeamJoinReqCmd ret = ", self.index,msg)
        print_r(msg)
    end)
     
end

-- 申请退出队伍
function Client:exit_team()
    if not self.ok then
        print("connect failed, err = ", err)
        return
    end
    local req_msg = {
        uid = self.uid
    }
    self:send("PBTeamExitReqCmd", req_msg, function(msg)
        print("rpc PBTeamExitReqCmd ret = ", self.index,msg)
        print_r(msg)
    end)
end

-- 踢人
function Client:kick_team(target_uid)
    target_uid = tonumber(target_uid)
 
    if not self.ok then
        print("connect failed, err = ", err)
        return
    end
    local req_msg = {
        uid = self.uid,
        target_uid = target_uid
    }
    self:send("PBTeamKickoutReqCmd", req_msg, function(msg)
        print("rpc PBTeamKickoutReqCmd ret = ",self.index, msg)
        print_r(msg)
    end)
end

-- 解散队伍
function Client:destroy_team()
    if not self.ok then
        print("connect failed, err = ", err)
        return
    end
    local req_msg = {
        uid = self.uid, 
    }
    self:send("PBTeamDestroyReqCmd", req_msg, function(msg)
        print("rpc PBTeamDestroyReqCmd ret = ", self.index,msg)
        print_r(msg)
    end)
end

 