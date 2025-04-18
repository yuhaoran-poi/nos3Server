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
            authkey = self.username .. self.index,
            auth_ticket = "123456",
        },
       
    }
    self:send("PBDSLoginReqCmd", login_msg, function(msg)
        print("rpc PBDSLoginReqCmd ret = ", self.index, msg)
        print_r(msg)
        if msg.code == 0 then
            self.login_ok = true
            self.uid = msg.uid
       end
   end)
  
end

 
