--[[
* @file : ClientLogin.lua
* @brief : ds登陆相关
]]
local moon = require("moon")
---@class Client
local Client = require "robot.logic.Client"

function Client:dslogin()
   
    if not self.ok then
        print("connect failed, err = ", err)
        return
    end
    local login_msg = {
        login_data = {
            authkey = self.username .. 1,
            auth_ticket = "TicketCityDS",
            ds_type = 1,
            ds_id = 1,
        },
       
    }
    self:send("PBDSLoginReqCmd", login_msg, function(msg)
        print("rpc PBDSLoginRspCmd ret = ", self.index, msg)
        print_r(msg)
        if msg.code == 0 then
            self.login_ok = true
            self.uid = msg.uid
       end
   end)
  
end

function Client:enter_city()
    if not self.ok then
        print("connect failed, err = ", err)
        return
    end
    local req_msg = {
        uid = 10001,
        cityid = 1
    }
    local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
    self:send("PBEnterCityReqCmd", req_msg, function(msg)
        print("rpc PBEnterCityRspCmd ret = ", self.index, msg)
        print_r(msg)
        if msg.code == 0 then
            self.login_ok = true
            self.uid = msg.uid
        end
    end)
end

function Client:add_items_city_player(uid, cityid)
    if not self.ok then
        print("connect failed, err = ", err)
        return
    end
    local req_msg = {
        uid = uid,
        cityid = cityid,
        simple_items = {},
    }
    local item_1 = {
        config_id = 2,
        item_count = 10000,
        uniqid = 0
    }
    local item_3 = {
        config_id = 51002,
        item_count = 777,
        uniqid = 0
    }
    local item_2 = {
        config_id = 51001,
        item_count = 777,
        uniqid = 0
    }
    local item_5 = {
        config_id = 600001,
        item_count = 1,
        uniqid = 1100003934210
    }
    local item_4 = {
        config_id = 600003,
        item_count = 1,
        uniqid = 1100003934211
    }
    local item_6 = {
        config_id = 600002,
        item_count = 1,
        uniqid = 1100003934212
    }
    local item_7 = {
        config_id = 630000,
        item_count = 1,
        uniqid = 1100004196359
    }
    
    -- table.insert(req_msg.simple_items, item_1)
    -- table.insert(req_msg.simple_items, item_2)
    -- table.insert(req_msg.simple_items, item_3)
    -- table.insert(req_msg.simple_items, item_4)
    -- table.insert(req_msg.simple_items, item_5)
    -- table.insert(req_msg.simple_items, item_6)
    table.insert(req_msg.simple_items, item_7)

    local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
    self:send("PBAddItemsCityPlayerReqCmd", req_msg, function(msg)
        print("rpc PBAddItemsCityPlayerRspCmd ret = ", self.index, msg)
        print_r(msg)
    end)
end

function Client:get_ds_user_attr(uid)
    if not self.ok then
        print("connect failed, err = ", err)
        return
    end
    local req_msg = {
        dsid = 1,
        quest_uid = uid,
    }
    self:send("PBGetDsUserAttrReqCmd", req_msg, function(msg)
        print("rpc PBGetDsUserAttrReqCmd ret = ", self.index, msg)
        print_r(msg)
    end)
end

function Client:get_ds_user_bags(uid)
    if not self.ok then
        print("connect failed, err = ", err)
        return
    end
    local req_msg = {
        dsid = 1,
        quest_uid = uid,
    }
    self:send("PBGetDsUserBagsReqCmd", req_msg, function(msg)
        print("rpc PBGetDsUserBagsReqCmd ret = ", self.index, msg)
        print_r(msg)
    end)
end

function Client:get_ds_user_roles(uid, roleid)
    if not self.ok then
        print("connect failed, err = ", err)
        return
    end
    local req_msg = {
        dsid = 1,
        quest_uid = uid,
        roleids = {}
    }
    table.insert(req_msg.roleids, roleid)
    self:send("PBGetDsUserRolesReqCmd", req_msg, function(msg)
        print("rpc PBGetDsUserRolesReqCmd ret = ", self.index, msg)
        print_r(msg)
    end)
end

function Client:get_ds_user_images(uid)
    if not self.ok then
        print("connect failed, err = ", err)
        return
    end
    local req_msg = {
        dsid = 1,
        quest_uid = uid,
    }
    self:send("PBGetDsUserImageReqCmd", req_msg, function(msg)
        print("rpc PBGetDsUserImageRspCmd ret = ", self.index, msg)
        print_r(msg)
    end)
end

function Client:get_ds_user_gods(uid)
    if not self.ok then
        print("connect failed, err = ", err)
        return
    end
    local req_msg = {
        dsid = 1,
        quest_uid = uid,
    }
    self:send("PBGetDsUserBattleGodsReqCmd", req_msg, function(msg)
        print("rpc PBGetDsUserBattleGodsReqCmd ret = ", self.index, msg)
        print_r(msg)
    end)
end
