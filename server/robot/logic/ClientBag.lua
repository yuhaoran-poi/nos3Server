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
    table.insert(get_msg.bags_name, "cangku")
    table.insert(get_msg.bags_name, "consume")
    table.insert(get_msg.bags_name, "booty")

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
        src_bag = "cangku",
        src_index = 1,
        dst_bag = "consume",
        dst_index = 1,
        splitCount = 1
    }
    self:send("PBBagOperateItemReqCmd", req_msg, function(msg)
        print("rpc PBBagOperateItemRspCmd ret = ", self.index, msg)
        print_r(msg)
    end)
end
