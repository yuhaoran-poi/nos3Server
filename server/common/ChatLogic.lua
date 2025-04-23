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
-- 删除公会聊天频道
function ChatLogic.RemoveGuildChannel(guild_id)
    local res, err = cluster.call(CmdEnum.FixedNodeId.CHAT, "chatmgr", "ChatMgr.RemoveGuildChannel", guild_id)
    if not res then
        return { code = ErrorCode.RemoveGuildChannelErr }
    end
    if res.code ~= ErrorCode.None then
        return { code = res.code, error = res.error }
    end
    return { code = ErrorCode.None }
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

-- 创建队伍频道
function ChatLogic.newTeamChannel(team_id)
    local res, err = cluster.call(CmdEnum.FixedNodeId.CHAT, "chatmgr", "ChatMgr.CreateTeamChannel", team_id)
    if not res then
        return { code = ErrorCode.CreateTeamChannelErr }
    end
    if res.code ~= ErrorCode.None then
        return { code = res.code, error = res.error }
    end
    return { code = ErrorCode.None, channel_id = res.channel_id }
end
-- 删除队伍频道
function ChatLogic.RemoveTeamChannel(team_id)
    local res, err = cluster.call(CmdEnum.FixedNodeId.CHAT, "chatmgr", "ChatMgr.RemoveTeamChannel", team_id)
    if not res then
        return { code = ErrorCode.RemoveTeamChannelErr }
    end
    if res.code ~= ErrorCode.None then
        return { code = res.code, error = res.error }
    end
    return { code = ErrorCode.None }
end

-- 成员加入队伍聊天频道
function ChatLogic.JoinTeamChannel(team_id,uid)
    local res, err = cluster.call(CmdEnum.FixedNodeId.CHAT, "chatmgr", "ChatMgr.AddTeamChannelPlayer",
          team_id, uid)
    if not res then
        return { code = ErrorCode.JoinTeamChannelErr }
    end
    if res.code ~= ErrorCode.None then
        return { code = res.code, error = res.error }
    end
    return { code = ErrorCode.None }
end

-- 成员退出队伍聊天频道
function ChatLogic.LeaveTeamChannel(team_id,uid)
    local res, err = cluster.call(CmdEnum.FixedNodeId.CHAT, "chatmgr", "ChatMgr.RemoveTeamChannelPlayer",
          team_id, uid)
    if not res then
        return { code = ErrorCode.LeaveTeamChannelErr }
    end
    if res.code ~= ErrorCode.None then
        return { code = res.code, error = res.error }
    end
    return { code = ErrorCode.None }
end
    
return ChatLogic
