--[[
* @file : ClientBag.lua
* @brief : ds登陆相关
]]
local moon = require("moon")
---@class Client
local Client = require "robot.logic.Client"

function Client:get_ghost()
    if not self.ok then
        print("connect failed, err = ", err)
        return
    end
    local get_msg = {
        uid = self.uid,
    }

    self:send("PBClientGetUsrGhostsInfoReqCmd", get_msg, function(msg)
        print("rpc PBClientGetUsrGhostsInfoReqCmd ret = ", self.index, msg)
        print_r(msg)
    end)
end

function Client:PBGhostInfoSyncCmd(msg)
    print("PBGhostInfoSyncCmd")
    print_r(msg)
end

function Client:ghost_wear_equip(ghost_uniqid, pos, equip_config_id, equip_uniqid, equip_idx)
    if not self.ok then
        print("connect failed, err = ", err)
        return
    end
    local req_msg = {
        uid = self.uid,
        ghost_uniqid = ghost_uniqid,
        bag_name = "Cangku",
        pos = pos,
        equip_config_id = equip_config_id,
        equip_uniqid = equip_uniqid,
        equip_idx = equip_idx,
    }

    self:send("PBGhostWearEquipReqCmd", req_msg, function(msg)
        print("rpc PBGhostWearEquipReqCmd ret = ", self.index, msg)
        print_r(msg)
    end)
end

function Client:ghost_takeoff_equip(ghost_uniqid, takeoff_config_id, takeoff_uniqid, takeoff_idx)
    if not self.ok then
        print("connect failed, err = ", err)
        return
    end
    local req_msg = {
        uid = self.uid,
        ghost_uniqid = ghost_uniqid,
        bag_name = "Cangku",
        takeoff_config_id = takeoff_config_id,
        takeoff_uniqid = takeoff_uniqid,
        takeoff_idx = takeoff_idx,
    }

    self:send("PBGhostTakeOffEquipReqCmd", req_msg, function(msg)
        print("rpc PBGhostTakeOffEquipRspCmd ret = ", self.index, msg)
        print_r(msg)
    end)
end
