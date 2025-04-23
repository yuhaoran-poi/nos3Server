---@class Client
local Client = require "robot.logic.Client"

function Client:TestChat()
    
end

function Client:chat(channel_type, msg, to_uid)
    if not self.ok then
        print("connect failed, err = ", err)
        return
    end
    local req_msg = {
        channel_type = tonumber(channel_type),
        msg_content = msg,
        to_uid = to_uid and tonumber(to_uid) or nil
    }
    self:send("PBChatReqCmd", req_msg, function(msg)
        print("rpc PBChatReqCmd ret = ", self.index, msg)
        print_r(msg)
        if msg.code == 0 then
            print("send chat success")
        end
    end)
end

function Client:OnPBChatSynCmd(msg)
    print("OnPBChatSynCmd = ", self.index, msg)
    print_r(msg)
end

