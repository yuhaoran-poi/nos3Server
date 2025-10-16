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

local WORLD_CHAT_CD_CONFID = 1
local WORLD_CHAT_MAX_SIZE_CONFID = 2
local CHAT_MIN_CD_CONFID = 3
local CHAT_REPEAT_CONFID = 4
local CHAT_TEMP_BAN_CONFID = 5

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
    -- -- 创建附近聊天频道
    -- local res = ChatLogic.NewNearbyChannel(1)
    -- if res.code ~= ErrorCode.None then
    --     moon.error(string.format("NewNearbyChannel cityid:%d, code:%d, error:%s", 1, res.code, res.error))
    -- end
    -- -- 加入附近聊天频道
    -- local chat_ret = ChatLogic.JoinNearbyChannel(1, context.uid)
    -- if chat_ret.code ~= ErrorCode.None then
    --     moon.error(string.format("JoinNearbyChannel uid:%d, cityid:%d, code:%d, error:%s", context.uid, 1,
    --         chat_ret.code, chat_ret.error))
    -- end
end

-- 客户端聊天消息请求
function ChatProxy.PBChatReqCmd(req)
    local channel_type = req.msg.channel_type
    local msg_content = req.msg.msg_content
    local msg_attach = req.msg.msg_attach
    local to_uid = req.msg.to_uid
    local user_attr = scripts.UserModel.GetUserAttr()
    local DB = scripts.UserModel.Get()
    local now_ts = moon.time()
    --是否处于禁言状态
    if user_attr.chat_ban and user_attr.chat_ban_time <= now_ts then
        user_attr.chat_ban = false
    end
    if user_attr.chat_ban then
        context.R2C(CmdCode.PBChatRspCmd, { code = ErrorCode.ChatSilence }, req)
        return { code = ErrorCode.ChatSilence }
    end
    -- 参数检查
    if not channel_type or not msg_content then
        context.R2C(CmdCode.PBChatRspCmd, { code = ErrorCode.ChatInvalidParam }, req)
        return { code = ErrorCode.ChatInvalidParam }
    end
    -- 检查字符限制
    local ChatWordLimit = 1000 -- todo 配置
    if GameCfg.ChatChannelConfig[WORLD_CHAT_MAX_SIZE_CONFID] then
        ChatWordLimit = GameCfg.ChatChannelConfig[WORLD_CHAT_MAX_SIZE_CONFID].value
    end
    if utf8.len(msg_content) + (msg_attach and utf8.len(msg_attach) or 0) > ChatWordLimit then
        context.R2C(CmdCode.PBChatRspCmd, { code = ErrorCode.ChatWordLimit }, req)
        return { code = ErrorCode.ChatWordLimit }
    end

    -- 检测发送间隔
    local last_chat_time = user_attr.last_chat_time or 0
    local send_interval = 1 -- 发送间隔，单位秒
    if GameCfg.ChatChannelConfig[CHAT_MIN_CD_CONFID] then
        send_interval = GameCfg.ChatChannelConfig[CHAT_MIN_CD_CONFID].value
    end
    if now_ts - last_chat_time < send_interval then
        context.R2C(CmdCode.PBChatRspCmd, { code = ErrorCode.ChatSendInterval }, req)
        return { code = ErrorCode.ChatSendInterval }
    end

    local PBChatMsgInfo = {
        channel_type = channel_type,
        uid = context.uid,
        name = user_attr.nick_name,
        msg_content = msg_content,
        msg_attach = msg_attach,
        send_time = moon.time(),
        to_uid = to_uid,
    }
    -- 检查频道类型
    if channel_type == ChatEnum.EChannelType.CHANNEL_TYPE_PRIVATE then --私聊
        if not to_uid then
            context.R2C(CmdCode.PBChatRspCmd, { code = ErrorCode.ChatInvalidParam }, req)
            return { code = ErrorCode.ChatInvalidParam }
        end

        if scripts.Friend.IsBlack(to_uid) then
            context.R2C(CmdCode.PBChatRspCmd, { code = ErrorCode.ChatBlack }, req)
            return { code = ErrorCode.ChatBlack }
        end
    elseif channel_type == ChatEnum.EChannelType.CHANNEL_TYPE_WORLD then --世界
        -- 世界聊天cd
        local world_chat_cd = 30 -- todo 配置
        if GameCfg.ChatChannelConfig[WORLD_CHAT_CD_CONFID] then
            world_chat_cd = GameCfg.ChatChannelConfig[WORLD_CHAT_CD_CONFID].value
        end
        if context.world_chat_last_time
            and now_ts - context.world_chat_last_time < world_chat_cd then
            context.R2C(CmdCode.PBChatRspCmd, { code = ErrorCode.ChatSendInterval }, req)
            return { code = ErrorCode.ChatSendInterval }
        end
    elseif channel_type == ChatEnum.EChannelType.CHANNEL_TYPE_NEARBY then --附近频道
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
    elseif channel_type == ChatEnum.EChannelType.CHANNEL_TYPE_ROOM then --房间
        if not context.roomid then
            context.R2C(CmdCode.PBChatRspCmd, { code = ErrorCode.RoomMemberNotFound }, req)
            return { code = ErrorCode.RoomMemberNotFound }
        end
    else
        context.R2C(CmdCode.PBChatRspCmd, { code = ErrorCode.ChannelNotExists }, req)
        return { code = ErrorCode.ChannelNotExists }
    end

    -- 检测重复发送
    local repeat_cnt = 3 -- todo 配置
    if GameCfg.ChatChannelConfig[CHAT_REPEAT_CONFID] then
        repeat_cnt = GameCfg.ChatChannelConfig[CHAT_REPEAT_CONFID].value
    end
    if context.last_chat_msg
        and context.last_chat_msg == (msg_content .. (msg_attach or " ")) then
        if context.re_chat_cnt then
            context.re_chat_cnt = context.re_chat_cnt + 1
        else
            context.re_chat_cnt = 1
        end

        if context.re_chat_cnt > repeat_cnt then
            -- 禁言
            local ban_time = 60 -- 禁言时间，单位秒
            if GameCfg.ChatChannelConfig[CHAT_TEMP_BAN_CONFID] then
                ban_time = GameCfg.ChatChannelConfig[CHAT_TEMP_BAN_CONFID].value
            end
            user_attr.chat_ban = true
            user_attr.chat_ban_time = now_ts + ban_time
            context.R2C(CmdCode.PBChatRspCmd, { code = ErrorCode.ChatRepeat }, req)
            return { code = ErrorCode.ChatRepeat }
        end
    end
    context.last_chat_msg = msg_content .. (msg_attach or " ")
    -- 记录发送时间
    user_attr.last_chat_time = now_ts
    context.world_chat_last_time = now_ts
    -- 发送消息
    if channel_type == ChatEnum.EChannelType.CHANNEL_TYPE_PRIVATE then --私聊
        local private_msg = {}
        table.insert(private_msg, PBChatMsgInfo)
        context.send_user(to_uid, "ChatProxy.OnChatMsg", private_msg)
    else
        local channel_addr = DB.chat_addrs[channel_type]
        -- 检查频道是否存在
        if not channel_addr and channel_type ~= ChatEnum.EChannelType.CHANNEL_TYPE_WORLD then
            context.R2C(CmdCode.PBChatRspCmd, { code = ErrorCode.NotInChannel }, req)
            return { code = ErrorCode.NotInChannel }
        end
        -- 发送消息到频道
        local blacks = scripts.Friend.GetBlacks()
        local to_msg = {
            chat_msg = PBChatMsgInfo,
            blacks = blacks,
        }
        if channel_type == ChatEnum.EChannelType.CHANNEL_TYPE_WORLD then
            ChatLogic.SendMsgToWorld(to_msg)
        else
            ChatLogic.SendMsgToChannel(channel_addr, to_msg)
        end
    end

    context.R2C(CmdCode.PBChatRspCmd, { code = ErrorCode.None }, req)
    return { code = ErrorCode.None }
end

function ChatProxy.OnChatMsg(channel_msgs)
    moon.info("OnChatMsg channel_msgs = ", channel_msgs)

    local msg = { infos = {} }
    for _, v in pairs(channel_msgs) do
        if not v.blacks or not v.blacks[context.uid] then
            table.insert(msg.infos, v.chat_msg)
        end
    end
    if table.size(msg.infos) > 0 then
        context.S2C(context.net_id, CmdCode.PBChatSynCmd, msg, 0)
    end
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
