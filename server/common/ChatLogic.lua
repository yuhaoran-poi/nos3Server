local moon = require "moon"
local common = require "common"
local ErrorCode = common.ErrorCode --逻辑错误码
local CmdEnum = common.CmdEnum
local ChatEnum = require("common.ChatEnum")
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
function ChatLogic.LeaveTeamChannel(team_id, uid)
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

-- game节点加入系统聊天频道
function ChatLogic.AddSystemChannelGameNode(node_id, addr_gate)
    local res, err = cluster.call(CmdEnum.FixedNodeId.CHAT, "chatmgr", "ChatMgr.AddSystemChannelGameNode", node_id,
    addr_gate)
    if not res then
        return { code = ErrorCode.AddSystemChannelGameNodeErr }
    end
    if res.code ~= ErrorCode.None then
        return { code = res.code, error = res.error }
    end
    return { code = ErrorCode.None }
end
-- game节点退出系统聊天频道
function ChatLogic.RemoveSystemChannelGameNode(node_id)
    local res, err = cluster.call(CmdEnum.FixedNodeId.CHAT, "chatmgr", "ChatMgr.RemoveSystemChannelGameNode", node_id)
    if not res then
        return { code = ErrorCode.RemoveSystemChannelGameNodeErr }
    end
    if res.code ~= ErrorCode.None then
        return { code = res.code, error = res.error }
    end
    return { code = ErrorCode.None }
end
-- 发送系统频道消息
function ChatLogic.SendMsgToSystemChannel(msg_content)
    
    local PBChatMsgInfo = {
        channel_type = ChatEnum.EChannelType.CHANNEL_TYPE_SYSTEM, -- 系统频道类型
        uid = 0, -- 系统消息的发送者UID
        name = "系统", -- 系统消息的发送者名称
        msg_content = msg_content, -- 消息内容
        send_time = moon.time(), -- 发送时间
        to_uid = 0, -- 目标UID，对于系统消息通常为0
    }
    cluster.send(CmdEnum.FixedNodeId.CHAT, "chatmgr", "ChatMgr.SendSystemChannelMsg", PBChatMsgInfo)
end
return ChatLogic
