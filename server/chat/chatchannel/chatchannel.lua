--[[
* @file : ChatChannel.lua
* @type: multi service
* @brief : 聊天频道服务
* @author : yq
]]

local moon = require "moon"
local common = require "common"
local cluster = require("cluster")
local queue = require "moon.queue"
local GameCfg = common.GameCfg
local ErrorCode = common.ErrorCode
local CmdCode = common.CmdCode
local lock = queue()
---@type guild_context
local context = ...
local scripts = context.scripts




---@class ChatChannel
local ChatChannel = {}

function ChatChannel.Init()
    return true
     
end

function ChatChannel.Start()
    -- 创建一个协程，每秒发送并清空频道消息
    moon.async(function()
        while true do
            moon.sleep(1000) -- 每秒发送一次
            local scope <close> = lock()
            if #context.channel_msgs > 0 then
                local msgs = context.channel_msgs
                context.send_users(ChatChannel.GetMembers(), {}, "ChatProxy.OnChatMsg", context.channel_msgs)
                context.channel_msgs = {} -- 清空消息列表
            end
        end
    end)
    return true
end
function ChatChannel.InitData(channel_id, channel_type, channel_addr)
    context.channel_id = channel_id
    context.channel_type = channel_type
    context.channel_addr = channel_addr
    return {code = ErrorCode.None}
end

function ChatChannel.AddPlayer(uid)
    local scope <close> = lock()
    context.memember_uids[uid] = 1
    return true
end

function ChatChannel.RemovePlayer(uid)
    local scope <close> = lock()
    context.memember_uids[uid] = nil
    return true
end
function ChatChannel.GetMembers()
    local member_keys = {}
    for k, _ in pairs(context.memember_uids.memember_uids) do
        table.insert(member_keys, k)
    end
    return member_keys
end
-- 添加频道消息
function ChatChannel.AddMsg(msg)
    local scope <close> = lock()
    table.insert(context.channel_msgs, msg)
    return true
end
return ChatChannel