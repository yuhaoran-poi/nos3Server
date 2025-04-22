local moon = require "moon"
local common = require "common"
local cluster = require("cluster")
local ChatEnum = require("common.ChatEnum")
local GameCfg = common.GameCfg
local ErrorCode = common.ErrorCode
local CmdCode = common.CmdCode
local CmdEnum = common.CmdEnum
local ChatLogic = require("common.ChatLogic")
---@type user_context
local context = ...
local scripts = context.scripts

---@class ChatProxy
local ChatProxy = {}

function ChatProxy.Init()
    local user_info = scripts.UserModel.MutGetUserData()
    user_info.chat_info = user_info.chat_info or {}
    local DB = scripts.UserModel.Get()
    DB.chat_addrs = {
    }
end

function ChatProxy.Start()
    -- body
end
-- 客户端聊天消息请求
function ChatProxy.PBChatReqCmd(req)
    local channel_type = req.msg.channel_type
    local msg_content = req.msg.msg_content
    local to_uid = req.msg.to_uid
    local user_data = scripts.UserModel.GetUserData()
    local DB = scripts.UserModel.Get()
    --是否处于禁言状态
    local chat_info = user_data.chat_info
    if chat_info.silence and chat_info.silence_time > moon.time() then
        context.R2C(CmdCode.PBChatRspCmd, { code = ErrorCode.ChatSilence }, req)
        return { code = ErrorCode.ChatSilence }
    end
    -- 参数检查
    if not channel_type or not msg_content then
        context.R2C(CmdCode.PBChatRspCmd, { code = ErrorCode.ChatInvalidParam }, req)
        return { code = ErrorCode.ChatInvalidParam }
    end
    -- 检查字符限制
    local ChatWordLimit = 100 -- todo 配置
    if utf8.len(msg_content) > ChatWordLimit then
        context.R2C(CmdCode.PBChatRspCmd, { code = ErrorCode.ChatWordLimit }, req)
        return { code = ErrorCode.ChatWordLimit }
    end

    local PBChatMsgInfo = {
        channel_type = channel_type,
        uid = context.uid,
        name = user_data.name,
        msg_content = msg_content,
        send_time = moon.time(),
        to_uid = to_uid,
    }
    -- 检查频道类型
    if channel_type == ChatEnum.EChannelType.CHANNEL_TYPE_PRIVATE then --私聊
        if not to_uid then
            context.R2C(CmdCode.PBChatRspCmd, { code = ErrorCode.ChatInvalidParam }, req)
            return { code = ErrorCode.ChatInvalidParam }
        end
    elseif channel_type == ChatEnum.EChannelType.CHANNEL_TYPE_WORLD then --世界
    elseif channel_type == ChatEnum.EChannelType.CHANNEL_TYPE_GUILD then --公会
        -- 公会是否存在
        if user_data.guild.guild_id == 0 then
            context.R2C(CmdCode.PBChatRspCmd, { code = ErrorCode.GuildNotExist }, req)
            return { code = ErrorCode.GuildNotExist }
        end
    elseif channel_type == ChatEnum.EChannelType.CHANNEL_TYPE_TEAM then --队伍
        if DB.team.team_id == 0 then
            context.R2C(CmdCode.PBChatRspCmd, { code = ErrorCode.TeamNotExist }, req)
            return { code = ErrorCode.TeamNotExist }
        end
    else
        context.R2C(CmdCode.PBChatRspCmd, { code = ErrorCode.ChannelNotExists }, req)
        return { code = ErrorCode.ChannelNotExists }
    end

    -- 检测发送间隔
    local last_send_time = chat_info.last_send_time or 0
    local send_interval = 1 -- 发送间隔，单位秒
    if moon.time() - last_send_time < send_interval then
        context.R2C(CmdCode.PBChatRspCmd, { code = ErrorCode.ChatSendInterval }, req)
        return { code = ErrorCode.ChatSendInterval }
    end
    -- 记录发送时间
    chat_info.last_send_time = moon.time()
    -- 发送消息
    if channel_type == ChatEnum.EChannelType.CHANNEL_TYPE_PRIVATE then --私聊
        context.send_user(to_uid, {}, "ChatProxy.OnChatMsg", PBChatMsgInfo)
    else
        local channel_addr = DB.chat_addrs[channel_type]
        -- 检查频道是否存在
        if not channel_addr then
            context.R2C(CmdCode.PBChatRspCmd, { code = ErrorCode.NotInChannel }, req)
            return { code = ErrorCode.NotInChannel }
        end
        -- 发送消息到频道
        ChatLogic.SendMsgToChannel(channel_addr, PBChatMsgInfo)
    end

    context.R2C(CmdCode.PBChatRspCmd, { code = ErrorCode.None }, req)
    return { code = ErrorCode.None }
end


function ChatProxy.OnChatMsg(channel_msgs)
    moon.info("OnChatMsg channel_msgs = ", channel_msgs)
    
    local msg = { infos = {} }
    for _, v in ipairs(channel_msgs) do
        table.insert(msg.infos, v)
    end
    context.S2C(context.net_id, CmdCode.PBChatSynCmd, msg, 0)
end
function ChatProxy.OnJoinChannel(channel_type, channel_addr)
    local DB = scripts.UserModel.Get()
    DB.chat_addrs = DB.chat_addrs or {}
    DB.chat_addrs[channel_type] = channel_addr
end
function ChatProxy.OnLeaveChannel(channel_type)
    local DB = scripts.UserModel.Get()
    DB.chat_addrs = DB.chat_addrs or {}
    DB.chat_addrs[channel_type] = nil
end

function ChatProxy.Online()
    local DB = scripts.UserModel.GetUserData()
    if DB.guild.guild_id ~= 0 then
        ChatLogic.JoinGuildChannel(DB.guild.guild_id, context.uid)
    end
end
function ChatProxy.Offline()
    local DB = scripts.UserModel.GetUserData()
    if DB.guild.guild_id ~= 0 then
        ChatLogic.LeaveGuildChannel(DB.guild.guild_id, context.uid)
    end
end
return ChatProxy
