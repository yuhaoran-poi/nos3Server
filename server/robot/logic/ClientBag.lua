--[[
* @file : ClientBag.lua
* @brief : ds登陆相关
]]
local moon = require("moon")
---@class Client
local Client = require "robot.logic.Client"

function Client:get_bags()
   
    if not self.ok then
        print("connect failed, err = ", err)
        return
    end
    local get_msg = {
        uid = self.uid,
        bags_name = {}
    }
    table.insert(get_msg.bags_name, "Cangku")
    table.insert(get_msg.bags_name, "Consume")
    table.insert(get_msg.bags_name, "Booty")

    self:send("PBBagGetDataReqCmd", get_msg, function(msg)
        print("rpc PBBagGetDataRspCmd ret = ", self.index, msg)
        print_r(msg)
   end)
  
end

function Client:operate_bag()
    if not self.ok then
        print("connect failed, err = ", err)
        return
    end
    local req_msg = {
        uid = self.uid,
        operate_type = 1,
        src_bag = "Cangku",
        src_index = 1,
        dst_bag = "Consume",
        dst_index = 1,
        split_count = 1
    }
    self:send("PBBagOperateItemReqCmd", req_msg, function(msg)
        print("rpc PBBagOperateItemRspCmd ret = ", self.index, msg)
        print_r(msg)
    end)
end

function Client:light_item(pos, id)
    if not self.ok then
        print("connect failed, err = ", err)
        return
    end
    local req_msg = {
        uid = self.uid,
        roleid = 0,
        ghostid = 0,
        bag_name = "Cangku",
        pos = pos,
        config_id = id,
        uniqid = 0,
    }
    self:send("PBClientLightReqCmd", req_msg, function(msg)
        print("rpc PBClientLightRspCmd ret = ", self.index, msg)
        print_r(msg)
    end)
end

function Client:get_images()
    if not self.ok then
        print("connect failed, err = ", err)
        return
    end

    local req_msg = {
        uid = self.uid,
    }
    self:send("PBImageGetDataReqCmd", req_msg, function(msg)
        print("rpc PBImageGetDataRspCmd ret = ", self.index, msg)
        print_r(msg)
    end)
end

function Client:del_item(config_id, uniqid, count, pos)
    if not self.ok then
        print("connect failed, err = ", err)
        return
    end

    local req_msg = {
        uid = self.uid,
        decompose_items = {},
    }
    local item = {
        config_id = config_id,
        uniqid = uniqid,
        item_count = count,
        pos = pos,
    }
    table.insert(req_msg.decompose_items, item)
    self:send("PBDecomposeReqCmd", req_msg, function(msg)
        print("rpc PBDecomposeRspCmd ret = ", self.index, msg)
        print_r(msg)
    end)
end

function Client:composite()
    if not self.ok then
        print("connect failed, err = ", err)
        return
    end

    local req_msg = {
        uid = self.uid,
        composite_id = 33999,
        composite_cnt = 1,
    }
    self:send("PBRandomCompositeReqCmd", req_msg, function(msg)
        print("rpc PBRandomCompositeReqCmd ret = ", self.index, msg)
        print_r(msg)
    end)
end

function Client:sortout()
    if not self.ok then
        print("connect failed, err = ", err)
        return
    end

    local req_msg = {
        uid = self.uid,
        bag_name = "Cangku",
    }
    self:send("PBBagSortOutReqCmd", req_msg, function(msg)
        print("rpc PBBagSortOutRspCmd ret = ", self.index, msg)
        print_r(msg)
    end)
end
