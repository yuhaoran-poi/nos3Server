
local moon = require("moon")
---@class Client
local Client = require "robot.logic.Client"

function Client:get_all_mail()
    if not self.ok then
        print("connect failed, err = ", err)
        return
    end
    local get_msg = {
        uid = self.uid,
    }

    self:send("PBGetAllMailReqCmd", get_msg, function(msg)
        print("rpc PBGetAllMailReqCmd ret = ", self.index, msg)
        print_r(msg)
    end)
end

function Client:get_mail_detail(mail_id)
    if not self.ok then
        print("connect failed, err = ", err)
        return
    end
    local get_msg = {
        uid = self.uid,
        mail_ids = { mail_id },
    }

    self:send("PBGetMailDetailReqCmd", get_msg, function(msg)
        print("rpc PBGetMailDetailReqCmd ret = ", self.index, msg)
        print_r(msg)
    end)
end

function Client:read_mail(mail_id)
    if not self.ok then
        print("connect failed, err = ", err)
        return
    end
    local read_msg = {
        uid = self.uid,
        mail_id = mail_id,
    }

    self:send("PBReadMailReqCmd", read_msg, function(msg)
        print("rpc PBReadMailReqCmd ret = ", self.index, msg)
        print_r(msg)
    end)
end

function Client:get_mail_reward(mail_id)
    if not self.ok then
        print("connect failed, err = ", err)
        return
    end
    local reward_msg = {
        uid = self.uid,
        mail_ids = { mail_id },
    }

    self:send("PBGetRewardReqCmd", reward_msg, function(msg)
        print("rpc PBGetRewardReqCmd ret = ", self.index, msg)
        print_r(msg)
    end)
end

function Client:del_mail(mail_id)
    if not self.ok then
        print("connect failed, err = ", err)
        return
    end
    local del_msg = {
        uid = self.uid,
        mail_ids = { mail_id },
    }

    self:send("PBDelMailReqCmd", del_msg, function(msg)
        print("rpc PBDelMailReqCmd ret = ", self.index, msg)
        print_r(msg)
    end)
end