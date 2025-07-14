local moon = require "moon"
local common = require "common"
local cluster = require("cluster")
local ChatEnum = require("common.Enum.ChatEnum")
local GameCfg = common.GameCfg
local ErrorCode = common.ErrorCode
local CmdCode = common.CmdCode
local CmdEnum = common.CmdEnum
local ChatLogic = require("common.logic.ChatLogic")
---@type user_context
local context = ...
local scripts = context.scripts

---@class ChatProxy
local ChatProxy = {}

function ChatProxy.Init()
    local user_info = scripts.UserModel.MutGet()
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
    local user_attr = scripts.UserModel.GetUserAttr()
    local DB = scripts.UserModel.Get()
    --是否处于禁言状态
     
    if user_attr.chat_ban and user_attr.chat_ban_time > moon.time() then
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
        name = user_attr.nick_name,
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
        if user_attr.guild_id == 0 then
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
    local last_send_time = user_attr.last_send_time or 0
    local send_interval = 1 -- 发送间隔，单位秒
    if moon.time() - last_send_time < send_interval then
        context.R2C(CmdCode.PBChatRspCmd, { code = ErrorCode.ChatSendInterval }, req)
        return { code = ErrorCode.ChatSendInterval }
    end
    -- 记录发送时间
    user_attr.last_send_time = moon.time()
    -- 发送消息
    if channel_type == ChatEnum.EChannelType.CHANNEL_TYPE_PRIVATE then --私聊
        local private_msg = {}
        table.insert(private_msg, PBChatMsgInfo)
        context.send_user(to_uid, "ChatProxy.OnChatMsg", private_msg)
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
    local DB = scripts.UserModel.GetUserAttr()
    if DB.guild_id ~= 0 then
        ChatLogic.JoinGuildChannel(DB.guild_id, context.uid)
    end
end
function ChatProxy.Offline()
    local DB = scripts.UserModel.GetUserAttr()
    if DB.guild_id ~= 0 then
        ChatLogic.LeaveGuildChannel(DB.guild_id, context.uid)
    end
end
return ChatProxy
