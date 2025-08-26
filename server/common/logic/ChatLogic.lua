local moon = require "moon"
local common = require "common"
local ErrorCode = common.ErrorCode --逻辑错误码
local CmdEnum = common.CmdEnum
local ChatEnum = require("common.Enum.ChatEnum")
local cluster = require("cluster")
local serverconf = require("serverconf")
local ChatLogic = {}
-- 创建公会聊天频道
function ChatLogic.newGuildChannel(guild_id)
    local res, err = cluster.call(CmdEnum.FixedNodeId.CHAT, "chatmgr", "ChatMgr.CreateGuildChannel", guild_id)
    if not res then
        moon.error("create guild channel failed: ", err)
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
        moon.error("remove guild channel failed: ", err)
        return { code = ErrorCode.RemoveGuildChannelErr }
    end
    if res.code ~= ErrorCode.None then
        return { code = res.code, error = res.error }
    end
    return { code = ErrorCode.None }
end

-- 成员加入公会聊天频道
function ChatLogic.JoinGuildChannel(guild_id, uid)
    local res, err = cluster.call(CmdEnum.FixedNodeId.CHAT, "chatmgr", "ChatMgr.AddGuildChannelPlayer",
        guild_id, uid)
    if not res then
        moon.error("join guild channel failed: ", err)
        return { code = ErrorCode.JoinGuildChannelErr }
    end
    if res.code ~= ErrorCode.None then
        return { code = res.code, error = res.error }
    end
    return { code = ErrorCode.None }
end

-- 成员退出公会聊天频道
function ChatLogic.LeaveGuildChannel(guild_id, uid)
    local res, err = cluster.call(CmdEnum.FixedNodeId.CHAT, "chatmgr", "ChatMgr.RemoveGuildChannelPlayer",
        guild_id, uid)
    if not res then
        moon.error("leave guild channel failed: ", err)
        return { code = ErrorCode.LeaveGuildChannelErr }
    end
    if res.code ~= ErrorCode.None then
        return { code = res.code, error = res.error }
    end
    return { code = ErrorCode.None }
end

-- 发送消息到频道
function ChatLogic.SendMsgToChannel(channel_addr, to_msg)
    cluster.send(CmdEnum.FixedNodeId.CHAT, channel_addr, "ChatChannel.AddMsg", to_msg)
end

function ChatLogic.SendMsgToWorld(to_msg)
    cluster.send(CmdEnum.FixedNodeId.CHAT, "chatmgr", "ChatMgr.SendWorldChannelMsg", to_msg, serverconf.WORLD_ID)
end

-- 创建队伍频道
function ChatLogic.newTeamChannel(team_id)
    local res, err = cluster.call(CmdEnum.FixedNodeId.CHAT, "chatmgr", "ChatMgr.CreateTeamChannel", team_id)
    if not res then
        moon.error("create team channel failed: ", err)
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
        moon.error("remove team channel failed: ", err)
        return { code = ErrorCode.RemoveTeamChannelErr }
    end
    if res.code ~= ErrorCode.None then
        return { code = res.code, error = res.error }
    end
    return { code = ErrorCode.None }
end

-- 成员加入队伍聊天频道
function ChatLogic.JoinTeamChannel(team_id, uid)
    local res, err = cluster.call(CmdEnum.FixedNodeId.CHAT, "chatmgr", "ChatMgr.AddTeamChannelPlayer",
        team_id, uid)
    if not res then
        moon.error("join team channel failed: ", err)
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
        moon.error("leave team channel failed: ", err)
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
        moon.error("add system channel game node failed: ", err)
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
        moon.error("remove system channel game node failed: ", err)
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

-- game节点加入世界聊天频道
function ChatLogic.AddWorldChannelGameNode(node_id, addr_gate, world_id)
    local res, err = cluster.call(CmdEnum.FixedNodeId.CHAT, "chatmgr", "ChatMgr.AddWorldChannelGameNode", node_id,
        addr_gate, world_id)
    if not res then
        moon.error("add world channel game node failed: ", err)
        return { code = ErrorCode.AddWorldChannelGameNodeErr }
    end
    if res.code ~= ErrorCode.None then
        return { code = res.code, error = res.error }
    end
    return { code = ErrorCode.None }
end

-- game节点退出世界聊天频道
function ChatLogic.RemoveWorldChannelGameNode(node_id, world_id)
    local res, err = cluster.call(CmdEnum.FixedNodeId.CHAT, "chatmgr", "ChatMgr.RemoveWorldChannelGameNode", node_id,
    world_id)
    if not res then
        moon.error("remove world channel game node failed: ", err)
        return { code = ErrorCode.RemoveWorldChannelGameNodeErr }
    end
    if res.code ~= ErrorCode.None then
        return { code = res.code, error = res.error }
    end
    return { code = ErrorCode.None }
end

-- 创建附近聊天频道
function ChatLogic.NewNearbyChannel(city_id)
    local res, err = cluster.call(CmdEnum.FixedNodeId.CHAT, "chatmgr", "ChatMgr.CreateNearbyChannel", city_id)
    if not res then
        moon.error("create nearby channel failed: ", err)
        return { code = ErrorCode.CreateNearbyChannelErr }
    end
    if res.code ~= ErrorCode.None then
        return { code = res.code, error = res.error }
    end
    return { code = ErrorCode.None, channel_id = res.channel_id }
end

-- 删除附近聊天频道
function ChatLogic.RemoveNearbyChannel(city_id)
    local res, err = cluster.call(CmdEnum.FixedNodeId.CHAT, "chatmgr", "ChatMgr.RemoveNearbyChannel", city_id)
    if not res then
        moon.error("remove nearby channel failed: ", err)
        return { code = ErrorCode.RemoveNearbyChannelErr }
    end
    if res.code ~= ErrorCode.None then
        return { code = res.code, error = res.error }
    end
    return { code = ErrorCode.None }
end

-- 玩家加入附近聊天频道
function ChatLogic.JoinNearbyChannel(city_id, uid)
    local res, err = cluster.call(CmdEnum.FixedNodeId.CHAT, "chatmgr", "ChatMgr.AddNearbyChannelPlayer",
        city_id, uid)
    if not res then
        moon.error("join nearby channel failed: ", err)
        return { code = ErrorCode.JoinNearbyChannelErr }
    end
    if res.code ~= ErrorCode.None then
        return { code = res.code, error = res.error }
    end
    return { code = ErrorCode.None }
end

-- 玩家退出附近聊天频道
function ChatLogic.LeaveNearbyChannel(city_id, uid)
    local res, err = cluster.call(CmdEnum.FixedNodeId.CHAT, "chatmgr", "ChatMgr.RemoveNearbyChannelPlayer",
        city_id, uid)
    if not res then
        moon.error("leave nearby channel failed: ", err)
        return { code = ErrorCode.LeaveNearbyChannelErr }
    end
    if res.code ~= ErrorCode.None then
        return { code = res.code, error = res.error }
    end
    return { code = ErrorCode.None }
end

-- 创建房间聊天频道
function ChatLogic.NewRoomChannel(room_id)
    local res, err = cluster.call(CmdEnum.FixedNodeId.CHAT, "chatmgr", "ChatMgr.CreateRoomChannel", room_id)
    if not res then
        moon.error("create room channel failed: ", err)
        return { code = ErrorCode.CreateRoomChannelErr }
    end
    if res.code ~= ErrorCode.None then
        return { code = res.code, error = res.error }
    end
    return { code = ErrorCode.None, channel_id = res.channel_id }
end

-- 删除附近聊天频道
function ChatLogic.RemoveRoomChannel(room_id)
    local res, err = cluster.call(CmdEnum.FixedNodeId.CHAT, "chatmgr", "ChatMgr.RemoveRoomChannel", room_id)
    if not res then
        moon.error("remove nearby channel failed: ", err)
        return { code = ErrorCode.RemoveRoomChannelErr }
    end
    if res.code ~= ErrorCode.None then
        return { code = res.code, error = res.error }
    end
    return { code = ErrorCode.None }
end

-- 玩家加入房间聊天频道
function ChatLogic.JoinRoomChannel(room_id, uid)
    local res, err = cluster.call(CmdEnum.FixedNodeId.CHAT, "chatmgr", "ChatMgr.AddRoomChannelPlayer",
        room_id, uid)
    if not res then
        moon.error("join room channel failed: ", err)
        return { code = ErrorCode.JoinRoomChannelErr }
    end
    if res.code ~= ErrorCode.None then
        return { code = res.code, error = res.error }
    end
    return { code = ErrorCode.None }
end

-- 玩家退出房间聊天频道
function ChatLogic.LeaveRoomChannel(room_id, uid)
    moon.info("LeaveRoomChannel room_id:", room_id, "uid:", uid)
    local res, err = cluster.call(CmdEnum.FixedNodeId.CHAT, "chatmgr", "ChatMgr.RemoveRoomChannelPlayer",
        room_id, uid)
    if not res then
        moon.error("leave room channel failed: ", err)
        return { code = ErrorCode.LeaveRoomChannelErr }
    end
    if res.code ~= ErrorCode.None then
        return { code = res.code, error = res.error }
    end
    return { code = ErrorCode.None }
end

return ChatLogic
