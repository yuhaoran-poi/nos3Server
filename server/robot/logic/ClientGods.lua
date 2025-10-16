--[[
* @file : ClientBag.lua
* @brief : ds登陆相关
]]
local moon = require("moon")
---@class Client
local Client = require "robot.logic.Client"

function Client:get_gods()
    if not self.ok then
        print("connect failed, err = ", err)
        return
    end
    local get_msg = {
        uid = self.uid,
    }

    self:send("PBGodsGetInfoReqCmd", get_msg, function(msg)
        print("rpc PBGodsGetInfoReqCmd ret = ", self.index, msg)
        print_r(msg)
    end)
end

function Client:PBGodsInfoSyncCmd(msg)
    print("PBGodsInfoSyncCmd")
    print_r(msg)
end

function Client:god_unlock(god_id)
    if not self.ok then
        print("connect failed, err = ", err)
        return
    end
    local req_msg = {
        uid = self.uid,
        god_id = god_id,
    }

    self:send("PBGodsUnlockReqCmd", req_msg, function(msg)
        print("rpc PBGodsUnlockReqCmd ret = ", self.index, msg)
        print_r(msg)
    end)
end

function Client:god_uplv(god_id)
    if not self.ok then
        print("connect failed, err = ", err)
        return
    end
    local req_msg = {
        uid = self.uid,
        god_id = god_id,
    }

    self:send("PBGodsUpLvReqCmd", req_msg, function(msg)
        print("rpc PBGodsUpLvReqCmd ret = ", self.index, msg)
        print_r(msg)
    end)
end

function Client:block_unlock(unlock_idx)
    if not self.ok then
        print("connect failed, err = ", err)
        return
    end
    local req_msg = {
        uid = self.uid,
        unlock_idx = unlock_idx,
    }

    self:send("PBGodsBlockUnlockReqCmd", req_msg, function(msg)
        print("rpc PBGodsBlockUnlockReqCmd ret = ", self.index, msg)
        print_r(msg)
    end)
end

function Client:god_wear(block_idx, god_id)
    if not self.ok then
        print("connect failed, err = ", err)
        return
    end
    local req_msg = {
        uid = self.uid,
        block_idx = block_idx,
        god_id = god_id,
    }

    self:send("PBGodsWearOrTakeoffReqCmd", req_msg, function(msg)
        print("rpc PBGodsWearOrTakeoffReqCmd ret = ", self.index, msg)
        print_r(msg)
    end)
end
