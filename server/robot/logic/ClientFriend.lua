---@class Client
local Client = require "robot.logic.Client"

function Client:get_friend()
    if not self.ok then
        print("connect failed, err = ", err)
        return
    end
    local get_msg = {
        uid = self.uid,
    }

    self:send("PBGetFriendInfoReqCmd", get_msg, function(msg)
        print("rpc PBGetFriendInfoRspCmd ret = ", self.index, msg)
        print_r(msg)
    end)
end

function Client:PBFriendSyncCmd(msg)
    print("PBFriendSyncCmd")
    print_r(msg)
end

function Client:apply_friend(target_uid)
    if not self.ok then
        print("connect failed, err = ", err)
        return
    end
    local get_msg = {
        uid = self.uid,
        target_uid = target_uid,
    }

    self:send("PBApplyFriendReqCmd", get_msg, function(msg)
        print("rpc PBApplyFriendRspCmd ret = ", self.index, msg)
        print_r(msg)
    end)
end

function Client:deal_apply_friend(quest_uid, deal_op)
    if not self.ok then
        print("connect failed, err = ", err)
        return
    end
    local get_msg = {
        uid = self.uid,
        quest_uid = quest_uid,
        deal_type = deal_op,
    }

    self:send("PBFriendDealApplyReqCmd", get_msg, function(msg)
        print("rpc PBFriendDealApplyRspCmd ret = ", self.index, msg)
        print_r(msg)
    end)
end

function Client:PBFriendOtherRefuseSyncCmd(msg)
    print("PBFriendOtherRefuseSyncCmd")
    print_r(msg)
end

function Client:del_friend(del_uid)
    if not self.ok then
        print("connect failed, err = ", err)
        return
    end
    local get_msg = {
        uid = self.uid,
        del_uid = del_uid,
    }

    self:send("PBFriendDelReqCmd", get_msg, function(msg)
        print("rpc PBFriendDelRspCmd ret = ", self.index, msg)
        print_r(msg)
    end)
end

function Client:black_friend(black_uid)
    if not self.ok then
        print("connect failed, err = ", err)
        return
    end
    local get_msg = {
        uid = self.uid,
        black_uid = black_uid,
    }

    self:send("PBFriendAddBlackReqCmd", get_msg, function(msg)
        print("rpc PBFriendAddBlackRspCmd ret = ", self.index, msg)
        print_r(msg)
    end)
end

function Client:del_black_friend(black_uid)
    if not self.ok then
        print("connect failed, err = ", err)
        return
    end
    local get_msg = {
        uid = self.uid,
        black_uid = black_uid,
    }

    self:send("PBFriendDelBlackReqCmd", get_msg, function(msg)
        print("rpc PBFriendDelBlackRspCmd ret = ", self.index, msg)
        print_r(msg)
    end)
end

function Client:notes_friend(notes_uid, notes)
    if not self.ok then
        print("connect failed, err = ", err)
        return
    end
    local get_msg = {
        uid = self.uid,
        target_uid = notes_uid,
        notes = notes,
    }

    self:send("PBFriendSetNotesReqCmd", get_msg, function(msg)
        print("rpc PBFriendSetNotesRspCmd ret = ", self.index, msg)
        print_r(msg)
    end)
end

function Client:new_group_friend(group_name)
    if not self.ok then
        print("connect failed, err = ", err)
        return
    end
    local get_msg = {
        uid = self.uid,
        group_name = group_name,
    }

    self:send("PBFriendCreateGroupReqCmd", get_msg, function(msg)
        print("rpc PBFriendCreateGroupRspCmd ret = ", self.index, msg)
        print_r(msg)
    end)
end

function Client:del_group_friend(group_id)
    if not self.ok then
        print("connect failed, err = ", err)
        return
    end
    local get_msg = {
        uid = self.uid,
        group_id = group_id,
    }

    self:send("PBFriendDeleteGroupReqCmd", get_msg, function(msg)
        print("rpc PBFriendDeleteGroupRspCmd ret = ", self.index, msg)
        print_r(msg)
    end)
end

function Client:move_group_friend(move_uid, old_group_id, new_group_id)
    if not self.ok then
        print("connect failed, err = ", err)
        return
    end
    local get_msg = {
        uid = self.uid,
        target_uid = move_uid,
        old_group_id = old_group_id,
        new_group_id = new_group_id,
    }

    self:send("PBFriendMoveReqCmd", get_msg, function(msg)
        print("rpc PBFriendMoveRspCmd ret = ", self.index, msg)
        print_r(msg)
    end)
end
