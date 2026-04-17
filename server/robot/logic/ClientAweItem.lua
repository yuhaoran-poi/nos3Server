--[[
* @file : ClientAweItem.lua
* @brief : 镇山之宝相关测试
]]
local moon = require("moon")
---@class Client
local Client = require "robot.logic.Client"

function Client:get_aweitem()
    if not self.ok then
        print("connect failed, err = ", err)
        return
    end
    local get_msg = {
        uid = self.uid,
    }

    self:send("PBAweItemsGetInfoReqCmd", get_msg, function(msg)
        print("rpc PBAweItemsGetInfoReqCmd ret = ", self.index, msg)
        print_r(msg)
    end)
end

function Client:PBAweItemsSyncCmd(msg)
    print("PBAweItemsSyncCmd")
    print_r(msg)
end

function Client:aweitem_unlock(awe_item_id)
    if not self.ok then
        print("connect failed, err = ", err)
        return
    end
    local req_msg = {
        uid = self.uid,
        composite_id = awe_item_id,
        composite_cnt = 1,
    }

    self:send("PBSureCompositeReqCmd", req_msg, function(msg)
        print("rpc PBSureCompositeReqCmd ret = ", self.index, msg)
        print_r(msg)
    end)
end

function Client:aweitem_uplv(awe_item_id)
    if not self.ok then
        print("connect failed, err = ", err)
        return
    end
    local req_msg = {
        uid = self.uid,
        awe_item_id = awe_item_id,
    }

    self:send("PBAweItemUpLvReqCmd", req_msg, function(msg)
        print("rpc PBAweItemUpLvReqCmd ret = ", self.index, msg)
        print_r(msg)
    end)
end

function Client:aweitem_upstar(awe_item_id)
    if not self.ok then
        print("connect failed, err = ", err)
        return
    end
    local req_msg = {
        uid = self.uid,
        config_id = awe_item_id,
    }

    self:send("PBClientItemUpStarReqCmd", req_msg, function(msg)
        print("rpc PBClientItemUpStarReqCmd ret = ", self.index, msg)
        print_r(msg)
    end)
end