--[[
* @file : ClientLogin.lua
* @brief : 客户端登陆相关
]]
local moon = require("moon")
---@class Client
local Client = require "robot.logic.Client"

function Client:login()
   
    if not self.ok then
        print("connect failed, err = ", err)
        return
    end
    local login_msg = {
        login_data = {
            authkey = self.username..self.index,
        },
        is_register = false,
        password = moon.md5("123456"),
    }
    self:send("PBClientLoginReqCmd", login_msg, function(msg)
        print("rpc PBClientLoginReqCmd ret = ", self.index,msg)
        print_r(msg)
        if msg.code == 0 then
            self.login_ok = true
            self.uid = msg.uid
       end
   end)
  
end

function Client:register()
    if not self.ok then
        print("connect failed, err = ", err)
        return
    end
    local login_msg = {
        login_data = {
            authkey = self.username .. self.index,
        },
        is_register = true,
        password = moon.md5("123456"),
    }
    self:send("PBClientLoginReqCmd", login_msg, function(msg)
        print("rpc PBClientLoginReqCmd ret = ", msg)
        print_r(msg)
        if msg.code == 0 then
            self.login_ok = true
            self.uid = msg.uid
        end
    end)
end

function Client:simple_data()
    if not self.ok then
        print("connect failed, err = ", err)
        return
    end
    local req_msg = {
        uid = self.uid,
    }
    self:send("PBClientGetUsrSimInfoReqCmd", req_msg, function(msg)
        print("rpc PBClientGetUsrSimInfoReqCmd ret = ", msg)
        print_r(msg)
        if msg.code == 0 then
            --self.login_ok = true
        end
    end)
end
