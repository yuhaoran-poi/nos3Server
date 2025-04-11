---@class Client
local Client = require "robot.logic.Client"

function Client:TestGuild()

end

-- 创建公会请求
function Client:create_guild(guild_name)
    if not self.ok then
        print("connect failed, err = ", err)
        return
    end
    local req_msg = {
        uid = self.uid,
        guild_name = guild_name or ("公会名" .. self.index), -- 公会名称，由客户端输入或由服务器生成，这里假设由客户端输入
    }
    self:send("PBGuildCreateGuildReqCmd", req_msg, function(msg)
        print("rpc PBGuildCreateGuildReqCmd ret = ", self.index, msg)
        print_r(msg)
        if msg.code == 0 then
            self.guild_id = msg.guild_id
        end
    end)
end
