--[[
* @file : ClientBag.lua
* @brief : ds登陆相关
]]
local moon = require("moon")
---@class Client
local Client = require "robot.logic.Client"

function Client:get_shops()
    if not self.ok then
        print("connect failed, err = ", err)
        return
    end
    local get_msg = {
        uid = self.uid,
    }

    self:send("PBGetShopDataReqCmd", get_msg, function(msg)
        print("rpc PBGetShopDataReqCmd ret = ", self.index, msg)
        print_r(msg)
    end)
end

function Client:add_buy_car(product_id, product_num)
    if not self.ok then
        print("connect failed, err = ", err)
        return
    end
    local req_msg = {
        uid = self.uid,
        product_id = product_id,
        product_num = product_num,
    }

    self:send("PBShopAddBuyCarReqCmd", req_msg, function(msg)
        print("rpc PBShopAddBuyCarReqCmd ret = ", self.index, msg)
        print_r(msg)
    end)
end

function Client:del_buy_car(product_id, product_num)
    if not self.ok then
        print("connect failed, err = ", err)
        return
    end
    local req_msg = {
        uid = self.uid,
        product_id_num = {},
    }
    req_msg.product_id_num[product_id] = product_num

    self:send("PBShopDelBuyCarReqCmd", req_msg, function(msg)
        print("rpc PBShopDelBuyCarReqCmd ret = ", self.index, msg)
        print_r(msg)
    end)
end

function Client:shop_buy(with_car, product_id, product_num)
    if not self.ok then
        print("connect failed, err = ", err)
        return
    end
    local req_msg = {
        uid = self.uid,
        with_car = with_car,
        buy_id_num = {},
    }
    req_msg.buy_id_num[product_id] = product_num

    self:send("PBShopBuyReqCmd", req_msg, function(msg)
        print("rpc PBShopBuyReqCmd ret = ", self.index, msg)
        print_r(msg)
    end)
end
