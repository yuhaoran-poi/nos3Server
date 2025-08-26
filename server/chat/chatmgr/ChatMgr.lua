--[[
* @file : ChatMgr.lua
* @type: single service
* @brief : 聊天相关管理服务
* @author : yq
]]

local moon = require "moon"
local uuid = require "uuid"
local coqueue = require "moon.queue"
local common = require "common"
local GameDef= common.GameDef
local Database = common.Database
local GameCfg = common.GameCfg --游戏配置
local ErrorCode = common.ErrorCode --逻辑错误码
local CmdCode = common.CmdCode --客户端通信消息码
local ChatEnum = require("common.Enum.ChatEnum") --聊天枚举
local serverconf = require("serverconf")
---@type chatmgr_context
local context = ...
local scripts = context.scripts ---方便访问同服务的其它lua模块
 
---@class ChatMgr
local ChatMgr = {}

function ChatMgr.Init()
    context.Channels = {} --频道列表
    context.Channels[ChatEnum.EChannelType.CHANNEL_TYPE_NEARBY] = {} --附近频道
    context.Channels[ChatEnum.EChannelType.CHANNEL_TYPE_WORLD] = {}  --世界频道
    context.Channels[ChatEnum.EChannelType.CHANNEL_TYPE_TEAM] = {}   -- 队伍频道
    context.Channels[ChatEnum.EChannelType.CHANNEL_TYPE_GUILD] = {}  -- 公会频道
    context.Channels[ChatEnum.EChannelType.CHANNEL_TYPE_PRIVATE] = {} -- 私聊频道
    context.Channels[ChatEnum.EChannelType.CHANNEL_TYPE_SYSTEM] = {}  -- 系统频道
    context.Channels[ChatEnum.EChannelType.CHANNEL_TYPE_ROOM] = {}  -- 房间频道
    return true
end

function ChatMgr.Start()
    -- 创建系统聊天频道
    ChatMgr.CreateSystemChannel()
    -- 创建世界聊天频道
    ChatMgr.CreateWorldChannel(serverconf.WORLD_ID)
    return true
end

 
function ChatMgr.Shutdown()
    moon.quit()
    return true
end
-- 新增附近频道
function ChatMgr.CreateNearbyChannel(city_id)
    -- local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
    -- 判断是否已经存在
    local channel = context.Channels[ChatEnum.EChannelType.CHANNEL_TYPE_NEARBY][city_id]
    if channel then
        return { code = ErrorCode.ChannelAlreadyExists, error = "nearby chat channel already exists!" }
    end
    local channel_id = uuid.next()
    local conf = {
        name = "channel_nearby".. city_id,
        file = "chat/service_chatchannel.lua"
    }
    local addr_channel = moon.new_service(conf)
    if addr_channel == 0 then
        return { code = ErrorCode.CreateChatChannelServiceErr, error = "create nearby chat channel service failed!" }
    end
    -- 初始化频道数据
    local res, err = moon.call("lua", addr_channel, "ChatChannel.InitData", channel_id,
    ChatEnum.EChannelType.CHANNEL_TYPE_NEARBY, addr_channel)
    if not res then
        moon.error("init nearby chat channel data failed: ", err)
        return { code = ErrorCode.InitChatChannelDataErr, error = err }
    end

    context.Channels[ChatEnum.EChannelType.CHANNEL_TYPE_NEARBY][city_id] = {
        channel_id = channel_id,
        addr_channel = addr_channel
    }
    return { code = ErrorCode.None, channel_id = channel_id, addr_channel = addr_channel }
end
-- 移除附近频道
function ChatMgr.RemoveNearbyChannel(city_id)
    local channel = context.Channels[ChatEnum.EChannelType.CHANNEL_TYPE_NEARBY][city_id]
    if not channel then
        moon.warn("remove nearby chat channel failed: channel not found! city_id =", city_id)
        return { code = ErrorCode.ChannelNotExists, error = "nearby chat channel not found!" }
    end
    moon.send("lua", channel.addr_channel, "ChatChannel.Shutdown")
    context.Channels[ChatEnum.EChannelType.CHANNEL_TYPE_NEARBY][city_id] = nil
    return { code = ErrorCode.None }
end
-- 附近频道加入玩家
function ChatMgr.AddNearbyChannelPlayer(city_id, uid)
    local channel = context.Channels[ChatEnum.EChannelType.CHANNEL_TYPE_NEARBY][city_id]
    if not channel then
        moon.warn("add nearby chat channel player failed: channel not found! city_id = ", city_id,",uid = ",uid)
        return { code = ErrorCode.ChannelNotExists, error = "nearby chat channel not found!" }
    end
    moon.send("lua", channel.addr_channel, "ChatChannel.AddPlayer", uid)
    return { code = ErrorCode.None }
end
-- 附近频道移除玩家
function ChatMgr.RemoveNearbyChannelPlayer(city_id, uid)
    local channel = context.Channels[ChatEnum.EChannelType.CHANNEL_TYPE_NEARBY][city_id]
    if not channel then
        moon.warn("remove nearby chat channel player failed: channel not found! city_id = ", city_id,",uid = ",uid)
        return { code = ErrorCode.ChannelNotExists, error = "nearby chat channel not found!" }
    end
    moon.send("lua", channel.addr_channel, "ChatChannel.RemovePlayer", uid)
    return { code = ErrorCode.None }
end
-- 新增世界频道
function ChatMgr.CreateWorldChannel(world_id)
    -- 判断是否已经存在
    local channel = context.Channels[ChatEnum.EChannelType.CHANNEL_TYPE_WORLD][world_id]
    if channel then
        moon.error("create world chat channel failed: channel already exists! world_id = ", world_id)
        return { code = ErrorCode.ChannelAlreadyExists, error = "world chat channel already exists!" }
    end
    local channel_id = uuid.next()
    local conf = {
        name = "channel_world".. world_id,
        file = "chat/service_chatchannel.lua"
    }
    local addr_channel = moon.new_service(conf)
    if addr_channel == 0 then
        moon.error("create world chat channel failed: create chat channel service failed! world_id = ", world_id)
        return { code = ErrorCode.CreateChatChannelServiceErr, error = "create world chat channel service failed!" }
    end
    -- 初始化频道数据
    local res,err = moon.call("lua", addr_channel, "ChatChannel.InitData", channel_id, ChatEnum.EChannelType.CHANNEL_TYPE_WORLD, addr_channel)
    if not res then
        moon.error("init world chat channel data failed: ", err)
        return { code = ErrorCode.InitChatChannelDataErr, error = err }
    end
     
    context.Channels[ChatEnum.EChannelType.CHANNEL_TYPE_WORLD][world_id] = {
        channel_id = channel_id,
        addr_channel = addr_channel
    }
    return { code = ErrorCode.None, channel_id = channel_id, addr_channel = addr_channel }
end
-- 移除世界频道
function ChatMgr.RemoveWorldChannel(world_id)
    local channel = context.Channels[ChatEnum.EChannelType.CHANNEL_TYPE_WORLD][world_id]
    if not channel then
        moon.warn("remove world chat channel failed: channel not found! world_id = ", world_id)
        return { code = ErrorCode.ChannelNotExists, error = "world chat channel not found!" }
    end
    moon.send("lua", channel.addr_channel, "ChatChannel.Shutdown")
    context.Channels[ChatEnum.EChannelType.CHANNEL_TYPE_WORLD][world_id] = nil
    return { code = ErrorCode.None }
end
-- 世界频道加入玩家
function ChatMgr.AddWorldChannelPlayer(world_id, uid)
    local channel = context.Channels[ChatEnum.EChannelType.CHANNEL_TYPE_WORLD][world_id]
    if not channel then
        moon.warn("add world chat channel player failed: channel not found! world_id = ", world_id,",uid = ",uid)
        return { code = ErrorCode.ChannelNotExists, error = "world chat channel not found!" }
    end
    moon.send("lua", channel.addr_channel, "ChatChannel.AddPlayer", uid)
    return { code = ErrorCode.None }
end
-- 世界频道移除玩家
function ChatMgr.RemoveWorldChannelPlayer(world_id, uid)
    local channel = context.Channels[ChatEnum.EChannelType.CHANNEL_TYPE_WORLD][world_id]
    if not channel then
        moon.warn("remove world chat channel player failed: channel not found! world_id = ", world_id, ",uid = ", uid)
        return { code = ErrorCode.ChannelNotExists, error = "world chat channel not found!" }
    end
    moon.send("lua", channel.addr_channel, "ChatChannel.RemovePlayer", uid)
    return { code = ErrorCode.None }
end

-- 世界频道加入game节点
function ChatMgr.AddWorldChannelGameNode(node_id, addr_gate, world_id)
    local channel = context.Channels[ChatEnum.EChannelType.CHANNEL_TYPE_WORLD][world_id]
    if not channel then
        return { code = ErrorCode.ChannelNotExists, error = "world chat channel not found!" }
    end
    moon.send("lua", channel.addr_channel, "ChatChannel.AddGameNode", node_id, addr_gate)
    return { code = ErrorCode.None }
end

-- 世界频道移除game节点
function ChatMgr.RemoveWorldChannelGameNode(node_id, world_id)
    local channel = context.Channels[ChatEnum.EChannelType.CHANNEL_TYPE_WORLD][world_id]
    if not channel then
        return { code = ErrorCode.ChannelNotExists, error = "world chat channel not found!" }
    end
    moon.send("lua", channel.addr_channel, "ChatChannel.RemoveGameNode", node_id)
    return { code = ErrorCode.None }
end

-- 发送世界频道消息
function ChatMgr.SendWorldChannelMsg(to_msg, world_id)
    local channel = context.Channels[ChatEnum.EChannelType.CHANNEL_TYPE_WORLD][world_id]
    if not channel then
        moon.error("send world chat channel msg failed: channel not found! world_id = ", world_id)
        return { code = ErrorCode.ChannelNotExists, error = "world chat channel not found!" }
    end

    moon.send("lua", channel.addr_channel, "ChatChannel.AddMsg", to_msg)
    return { code = ErrorCode.None }
end
 
-- 新增公会频道
function ChatMgr.CreateGuildChannel(guild_id)
    -- 判断是否已经存在
    local channel = context.Channels[ChatEnum.EChannelType.CHANNEL_TYPE_GUILD][guild_id]
    if channel then
        moon.warn("create guild chat channel failed: channel already exists! guild_id = ", guild_id)
        return { code = ErrorCode.ChannelAlreadyExists, error = "guild chat channel already exists!" }
    end
    local channel_id = uuid.next()
    local conf = {
        name = "channel_guild" .. guild_id,
        file = "chat/service_chatchannel.lua"
    }
    local addr_channel = moon.new_service(conf)
    if addr_channel == 0 then
        moon.warn("create guild chat channel failed: create guild chat channel service failed! guild_id = ", guild_id)
        return { code = ErrorCode.CreateChatChannelServiceErr, error = "create guild chat channel service failed!" }
    end
    -- 初始化频道数据
    local res, err = moon.call("lua", addr_channel, "ChatChannel.InitData", channel_id,
    ChatEnum.EChannelType.CHANNEL_TYPE_GUILD, addr_channel)
    if not res then
        moon.error("init guild chat channel data failed: ", err)
        return { code = ErrorCode.InitChatChannelDataErr, error = err }
    end
    context.Channels[ChatEnum.EChannelType.CHANNEL_TYPE_GUILD][guild_id] = {
        channel_id = channel_id,
        addr_channel = addr_channel
    }
    return { code = ErrorCode.None, channel_id = channel_id, addr_channel = addr_channel }
end
-- 移除公会频道
function ChatMgr.RemoveGuildChannel(guild_id)
    local channel = context.Channels[ChatEnum.EChannelType.CHANNEL_TYPE_GUILD][guild_id]
    if not channel then
        moon.warn("remove guild chat channel failed: channel not found! guild_id = ", guild_id)
        return { code = ErrorCode.ChannelNotExists, error = "guild chat channel not found!" }
    end
    moon.send("lua", channel.addr_channel, "ChatChannel.Shutdown")
    context.Channels[ChatEnum.EChannelType.CHANNEL_TYPE_GUILD][guild_id] = nil
    return { code = ErrorCode.None }
end
-- 公会频道加入玩家
function ChatMgr.AddGuildChannelPlayer(guild_id, uid)
    local channel = context.Channels[ChatEnum.EChannelType.CHANNEL_TYPE_GUILD][guild_id]
    if not channel then
        moon.warn("add guild chat channel player failed: channel not found! guild_id = ", guild_id,",uid = ",uid)
        return { code = ErrorCode.ChannelNotExists, error = "guild chat channel not found!" }
    end
    moon.send("lua", channel.addr_channel, "ChatChannel.AddPlayer", uid)
    return { code = ErrorCode.None }
end
-- 公会频道移除玩家
function ChatMgr.RemoveGuildChannelPlayer(guild_id, uid)
    local channel = context.Channels[ChatEnum.EChannelType.CHANNEL_TYPE_GUILD][guild_id]
    if not channel then
        moon.warn("remove guild chat channel player failed: channel not found! guild_id = ", guild_id, ",uid = ", uid)
        return { code = ErrorCode.ChannelNotExists, error = "guild chat channel not found!" }
    end
    moon.send("lua", channel.addr_channel, "ChatChannel.RemovePlayer", uid)
    return { code = ErrorCode.None }
end

-- 新增队伍频道
function ChatMgr.CreateTeamChannel(team_id)
    -- 判断是否已经存在
    local channel = context.Channels[ChatEnum.EChannelType.CHANNEL_TYPE_TEAM][team_id]
    if channel then
        return { code = ErrorCode.ChannelAlreadyExists, error = "team chat channel already exists!" }
    end
    local channel_id = uuid.next()
    local conf = {
        name = "channel_team".. team_id,
        file = "chat/service_chatchannel.lua"
    }
    local addr_channel = moon.new_service(conf)
    if addr_channel == 0 then
        return { code = ErrorCode.CreateChatChannelServiceErr, error = "create team chat channel service failed!" }
    end
    -- 初始化频道数据
    local res, err = moon.call("lua", addr_channel, "ChatChannel.InitData", channel_id, ChatEnum.EChannelType.CHANNEL_TYPE_TEAM, addr_channel)
    if not res then
        return { code = ErrorCode.InitChatChannelDataErr, error = err }
    end
    context.Channels[ChatEnum.EChannelType.CHANNEL_TYPE_TEAM][team_id] = {
        channel_id = channel_id,
        addr_channel = addr_channel
    }
    return { code = ErrorCode.None, channel_id = channel_id, addr_channel = addr_channel }
end
-- 移除队伍频道
function ChatMgr.RemoveTeamChannel(team_id)
    local channel = context.Channels[ChatEnum.EChannelType.CHANNEL_TYPE_TEAM][team_id]
    if not channel then
        return { code = ErrorCode.ChannelNotExists, error = "team chat channel not found!" }
    end
    moon.send("lua", channel.addr_channel, "ChatChannel.Shutdown")
    context.Channels[ChatEnum.EChannelType.CHANNEL_TYPE_TEAM][team_id] = nil
    return { code = ErrorCode.None }
end
-- 队伍频道加入玩家
function ChatMgr.AddTeamChannelPlayer(team_id, uid)
    local channel = context.Channels[ChatEnum.EChannelType.CHANNEL_TYPE_TEAM][team_id]
    if not channel then
        return { code = ErrorCode.ChannelNotExists, error = "team chat channel not found!" }
    end
    moon.send("lua", channel.addr_channel, "ChatChannel.AddPlayer", uid)
    return { code = ErrorCode.None }
end
-- 队伍频道移除玩家
function ChatMgr.RemoveTeamChannelPlayer(team_id, uid)
    local channel = context.Channels[ChatEnum.EChannelType.CHANNEL_TYPE_TEAM][team_id]
    if not channel then
        return { code = ErrorCode.ChannelNotExists, error = "team chat channel not found!" }
    end
    moon.send("lua", channel.addr_channel, "ChatChannel.RemovePlayer", uid)
    return { code = ErrorCode.None }
end

-- 新增系统频道
function ChatMgr.CreateSystemChannel()
    local system_id = 0
    -- 判断是否已经存在
    local channel = context.Channels[ChatEnum.EChannelType.CHANNEL_TYPE_SYSTEM][system_id]
    if channel then
        return { code = ErrorCode.ChannelAlreadyExists, error = "system chat channel already exists!" }
    end
    local channel_id = uuid.next()
    local conf = {
        name = "channel_system".. system_id,
        file = "chat/service_chatchannel.lua"
    }
    local addr_channel = moon.new_service(conf)
    if addr_channel == 0 then
        return { code = ErrorCode.CreateChatChannelServiceErr, error = "create system chat channel service failed!" }
    end
    -- 初始化频道数据
    local res, err = moon.call("lua", addr_channel, "ChatChannel.InitData", channel_id, ChatEnum.EChannelType.CHANNEL_TYPE_SYSTEM, addr_channel)
    if not res then
        return { code = ErrorCode.InitChatChannelDataErr, error = err }
    end
    context.Channels[ChatEnum.EChannelType.CHANNEL_TYPE_SYSTEM][system_id] = {
        channel_id = channel_id,
        addr_channel = addr_channel
    }
    return { code = ErrorCode.None, channel_id = channel_id, addr_channel = addr_channel }
end
-- 移除系统频道
function ChatMgr.RemoveSystemChannel()
    local system_id = 0
    local channel = context.Channels[ChatEnum.EChannelType.CHANNEL_TYPE_SYSTEM][system_id]
    if not channel then
        return { code = ErrorCode.ChannelNotExists, error = "system chat channel not found!" }
    end
    moon.send("lua", channel.addr_channel, "ChatChannel.Shutdown")
    context.Channels[ChatEnum.EChannelType.CHANNEL_TYPE_SYSTEM][system_id] = nil
    return { code = ErrorCode.None }
end
-- 系统频道加入game节点
function ChatMgr.AddSystemChannelGameNode(node_id,addr_gate)
    local system_id = 0
    local channel = context.Channels[ChatEnum.EChannelType.CHANNEL_TYPE_SYSTEM][system_id]
    if not channel then
        return { code = ErrorCode.ChannelNotExists, error = "system chat channel not found!" }
    end
    moon.send("lua", channel.addr_channel, "ChatChannel.AddGameNode",node_id,addr_gate)
    return { code = ErrorCode.None }
end
-- 系统频道移除game节点
function ChatMgr.RemoveSystemChannelGameNode(node_id)
    local system_id = 0
    local channel = context.Channels[ChatEnum.EChannelType.CHANNEL_TYPE_SYSTEM][system_id]
    if not channel then
        return { code = ErrorCode.ChannelNotExists, error = "system chat channel not found!" }
    end
    moon.send("lua", channel.addr_channel, "ChatChannel.RemoveGameNode",node_id)
    return { code = ErrorCode.None }
end
-- 发送系统频道消息
function ChatMgr.SendSystemChannelMsg(msg)
    local system_id = 0
    local channel = context.Channels[ChatEnum.EChannelType.CHANNEL_TYPE_SYSTEM][system_id]
    if not channel then
        return { code = ErrorCode.ChannelNotExists, error = "system chat channel not found!" }
    end
    local to_msg = {
        chat_msg = msg,
        blacks = {},
    }
    moon.send("lua", channel.addr_channel, "ChatChannel.AddMsg", to_msg)
    return { code = ErrorCode.None }
end

-- 新增房间频道
function ChatMgr.CreateRoomChannel(room_id)
    -- 判断是否已经存在
    local channel = context.Channels[ChatEnum.EChannelType.CHANNEL_TYPE_ROOM][room_id]
    if channel then
        return { code = ErrorCode.ChannelAlreadyExists, error = "room chat channel already exists!" }
    end
    local channel_id = uuid.next()
    local conf = {
        name = "channel_room" .. room_id,
        file = "chat/service_chatchannel.lua"
    }
    local addr_channel = moon.new_service(conf)
    if addr_channel == 0 then
        return { code = ErrorCode.CreateChatChannelServiceErr, error = "create room chat channel service failed!" }
    end
    -- 初始化频道数据
    local res, err = moon.call("lua", addr_channel, "ChatChannel.InitData", channel_id,
        ChatEnum.EChannelType.CHANNEL_TYPE_ROOM, addr_channel)
    if not res then
        return { code = ErrorCode.InitChatChannelDataErr, error = err }
    end
    context.Channels[ChatEnum.EChannelType.CHANNEL_TYPE_ROOM][room_id] = {
        channel_id = channel_id,
        addr_channel = addr_channel
    }
    return { code = ErrorCode.None, channel_id = channel_id, addr_channel = addr_channel }
end

-- 移除房间频道
function ChatMgr.RemoveRoomChannel(room_id)
    local channel = context.Channels[ChatEnum.EChannelType.CHANNEL_TYPE_ROOM][room_id]
    if not channel then
        return { code = ErrorCode.ChannelNotExists, error = "room chat channel not found!" }
    end
    moon.send("lua", channel.addr_channel, "ChatChannel.Shutdown")
    context.Channels[ChatEnum.EChannelType.CHANNEL_TYPE_ROOM][room_id] = nil
    return { code = ErrorCode.None }
end

-- 房间频道加入玩家
function ChatMgr.AddRoomChannelPlayer(room_id, uid)
    local channel = context.Channels[ChatEnum.EChannelType.CHANNEL_TYPE_ROOM][room_id]
    if not channel then
        return { code = ErrorCode.ChannelNotExists, error = "room chat channel not found!" }
    end
    moon.send("lua", channel.addr_channel, "ChatChannel.AddPlayer", uid)
    return { code = ErrorCode.None }
end

-- 房间频道移除玩家
function ChatMgr.RemoveRoomChannelPlayer(room_id, uid)
    local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
    local channel = context.Channels[ChatEnum.EChannelType.CHANNEL_TYPE_ROOM][room_id]
    if not channel then
        return { code = ErrorCode.ChannelNotExists, error = "room chat channel not found!" }
    end
    moon.send("lua", channel.addr_channel, "ChatChannel.RemovePlayer", uid)
    return { code = ErrorCode.None }
end
 
return ChatMgr