---@class Client
local Client = require "robot.logic.Client"

function Client:TestRoom()
    
end

-- 申请创建房间
function Client:create_room()
    if not self.ok then
        print("connect failed, err = ", err)
        return
    end
    local req_msg = {
        uid = self.uid,
        isopen = 1,
        needpwd = 0,
        pwd = "",
        chapter = 1,
        difficulty = 1,
    }
    self:send("PBCreateRoomReqCmd", req_msg, function(msg)
        print("rpc PBCreateRoomReqCmd ret = ", self.index, msg)
        print_r(msg)
        if msg.code == 0 then
            self.roomid = msg.roomid
        end
    end)
end

function Client:search_room(search_roomid)
    if not self.ok then
        print("connect failed, err = ", err)
        return
    end

    local req_msg = {
        uid = self.uid,
        roomid = search_roomid,
        chapter = 1,
        difficulty = 1,
        start_idx = 1,
    }
    self:send("PBSearchRoomReqCmd", req_msg, function(msg)
        print("rpc PBSearchRoomReqCmd ret = ", self.index, msg)
        print_r(msg)
        if msg.code == 0 then

        end
    end)
end

function Client:mod_room()
    if not self.ok then
        print("connect failed, err = ", err)
        return
    end

    local req_msg = {
        uid = self.uid,
        roomid = self.roomid,
        isopen = 1,
        needpwd = 0,
        pwd = "",
        chapter = 2,
        difficulty = 2,
    }
    self:send("PBModRoomReqCmd", req_msg, function(msg)
        print("rpc PBModRoomReqCmd ret = ", self.index, msg)
        print_r(msg)
        if msg.code == 0 then

        end
    end)
end

function Client:apply_room(apply_roomid)
    if not self.ok then
        print("connect failed, err = ", err)
        return
    end

    local req_msg = {
        uid = self.uid,
        roomid = apply_roomid,
    }
    self:send("PBApplyRoomReqCmd", req_msg, function(msg)
        print("rpc PBApplyRoomReqCmd ret = ", self.index, msg)
        print_r(msg)
        if msg.code == 0 then

        end
    end)
end

function Client:deal_apply_room(deal_uid, deal_op)
    if not self.ok then
        print("connect failed, err = ", err)
        return
    end

    local req_msg = {
        deal_uid = deal_uid,
        deal_op = deal_op,
    }
    self:send("PBDealApplyRoomReqCmd", req_msg, function(msg)
        print("rpc PBDealApplyRoomReqCmd ret = ", self.index, msg)
        print_r(msg)
        if msg.code == 0 then

        end
    end)
end

-- message
-- PBEnterRoomReqCmd
-- {
--     int64 uid = 1,
--     int64 roomid = 2,
--     string pwd = 3,
-- }
function Client:enter_room(enter_roomid)
    if not self.ok then
        print("connect failed, err = ", err)
        return
    end

    local req_msg = {
        uid = self.uid,
        roomid = enter_roomid or 0,
        pwd = "",
    }
    self:send("PBEnterRoomReqCmd", req_msg, function(msg)
        print("rpc PBEnterRoomReqCmd ret = ", self.index, msg)
        print_r(msg)
        if msg.code == 0 then
            self.roomid = msg.roomid
        end
    end)
end

function Client:exit_room(exit_roomid)
    if not self.ok then
        print("connect failed, err = ", err)
        return
    end

    local req_msg = {
        uid = self.uid,
        roomid = self.roomid or exit_roomid,
    }
    self:send("PBExitRoomReqCmd", req_msg, function(msg)
        print("rpc PBExitRoomReqCmd ret = ", self.index, msg)
        print_r(msg)
        if msg.code == 0 then

        end
    end)
end

function Client:kick_room(kick_uid)
    if not self.ok then
        print("connect failed, err = ", err)
        return
    end

    local req_msg = {
        self_uid = self.uid,
        roomid = self.roomid,
        kick_uid = kick_uid,
    }
    self:send("PBKickRoomReqCmd", req_msg, function(msg)
        print("rpc PBKickRoomReqCmd ret = ", self.index, msg)
        print_r(msg)
        if msg.code == 0 then

        end
    end)
end

function Client:get_room_info(get_roomid)
    if not self.ok then
        print("connect failed, err = ", err)
        return
    end

    local req_msg = {
        uid = self.uid,
        roomid = self.roomid or get_roomid,
    }
    self:send("PBGetRoomInfoReqCmd", req_msg, function(msg)
        if msg.member_datas and msg.member_datas[1] and msg.member_datas[1].mem_info then
            if msg.member_datas[1].mem_info.guild_id then
                print("guild " .. msg.member_datas[1].mem_info.guild_id)
            else
                print("not guild_id")
            end
        end
        print("rpc PBGetRoomInfoReqCmd ret = ", self.index, msg)
        print_r(msg)
        if msg.code == 0 then

        end
    end)
end

function Client:ready_room(ready_op)
    if not self.ok then
        print("connect failed, err = ", err)
        return
    end

    local req_msg = {
        uid = self.uid,
        roomid = self.roomid,
        ready_op = ready_op or 1,
    }
    self:send("PBReadyRoomReqCmd", req_msg, function(msg)
        print("rpc PBReadyRoomReqCmd ret = ", self.index, msg)
        print_r(msg)
        if msg.code == 0 then

        end
    end)
end

function Client:start_room()
    if not self.ok then
        print("connect failed, err = ", err)
        return
    end

    local req_msg = {
        uid = self.uid,
        roomid = self.roomid,
    }
    self:send("PBStartGameRoomReqCmd", req_msg, function(msg)
        print("rpc PBStartGameRoomReqCmd ret = ", self.index, msg)
        print_r(msg)
        if msg.code == 0 then

        end
    end)
end

function Client:OnPBEnterDsRoomSyncCmd(msg)
    print("OnPBEnterDsRoomSyncCmd")
    print_r(msg)
end

function Client:apply_city()
    if not self.ok then
        print("connect failed, err = ", err)
        return
    end

    local req_msg = {
        uid = self.uid,
    }
    self:send("PBApplyLoginCityReqCmd", req_msg, function(msg)
        print("rpc PBApplyLoginCityRspCmd ret = ", self.index, msg)
        print_r(msg)
        if msg.code == 0 then

        end
    end)
end