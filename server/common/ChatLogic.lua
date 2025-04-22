local moon = require "moon"
local common = require "common"
local ErrorCode = common.ErrorCode --逻辑错误码
local CmdEnum = common.CmdEnum
 
local cluster = require("cluster")

local ChatLogic = {}
-- 创建公会聊天频道
function ChatLogic.newGuildChannel(guild_id)
    local res, err = cluster.call(CmdEnum.FixedNodeId.CHAT, "chatmgr", "ChatMgr.CreateGuildChannel", guild_id)
    if not res then
        return { code = ErrorCode.CreateGuildChannelErr }
    end
    if res.code ~= ErrorCode.None then
        return { code = res.code, error = res.error }
    end
    return { code = ErrorCode.None, channel_id = res.channel_id }
end

-- 成员加入公会聊天频道
function ChatLogic.JoinGuildChannel(guild_id,uid)
    local res, err = cluster.call(CmdEnum.FixedNodeId.CHAT, "chatmgr", "ChatMgr.AddGuildChannelPlayer",
          guild_id, uid)
    if not res then
        return { code = ErrorCode.JoinGuildChannelErr }
    end
    if res.code ~= ErrorCode.None then
        return { code = res.code, error = res.error }
    end
    return { code = ErrorCode.None }
end

-- 成员退出公会聊天频道
function ChatLogic.LeaveGuildChannel(guild_id,uid)
    local res, err = cluster.call(CmdEnum.FixedNodeId.CHAT, "chatmgr", "ChatMgr.RemoveGuildChannelPlayer",
          guild_id, uid)
    if not res then
        return { code = ErrorCode.LeaveGuildChannelErr }
    end
    if res.code ~= ErrorCode.None then
        return { code = res.code, error = res.error }
    end
    return { code = ErrorCode.None }
end
-- 发送消息到频道
function ChatLogic.SendMsgToChannel(channel_addr, msg)
    cluster.send(CmdEnum.FixedNodeId.CHAT, channel_addr, "ChatChannel.AddMsg", msg)
end
    
return ChatLogic
