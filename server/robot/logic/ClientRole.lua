--[[
* @file : ClientBag.lua
* @brief : ds登陆相关
]]
local moon = require("moon")
---@class Client
local Client = require "robot.logic.Client"

function Client:get_roles()
    if not self.ok then
        print("connect failed, err = ", err)
        return
    end
    local get_msg = {
        uid = self.uid,
    }

    self:send("PBClientGetUsrRolesInfoReqCmd", get_msg, function(msg)
        print("rpc PBClientGetUsrRolesInfoReqCmd ret = ", self.index, msg)
        print_r(msg)
    end)
end

function Client:PBRoleInfoSyncCmd(msg)
    print("PBRoleInfoSyncCmd")
    print_r(msg)
end

function Client:wear_equip(roleid, pos, equip_config_id, equip_uniqid, equip_idx)
    if not self.ok then
        print("connect failed, err = ", err)
        return
    end
    local req_msg = {
        uid = self.uid,
        roleid = roleid,
        bag_name = "Cangku",
        pos = pos,
        equip_config_id = equip_config_id,
        equip_uniqid = equip_uniqid,
        equip_idx = equip_idx,
    }

    self:send("PBRoleWearEquipReqCmd", req_msg, function(msg)
        print("rpc PBRoleWearEquipReqCmd ret = ", self.index, msg)
        print_r(msg)
    end)
end

function Client:takeoff_equip(roleid, takeoff_config_id, takeoff_uniqid, takeoff_idx)
    if not self.ok then
        print("connect failed, err = ", err)
        return
    end
    local req_msg = {
        uid = self.uid,
        roleid = roleid,
        bag_name = "Cangku",
        takeoff_config_id = takeoff_config_id,
        takeoff_uniqid = takeoff_uniqid,
        takeoff_idx = takeoff_idx,
    }

    self:send("PBRoleTakeOffEquipReqCmd", req_msg, function(msg)
        print("rpc PBRoleTakeOffEquipRspCmd ret = ", self.index, msg)
        print_r(msg)
    end)
end
