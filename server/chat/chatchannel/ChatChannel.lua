--[[
* @file : ChatChannel.lua
* @type: multi service
* @brief : 聊天频道服务1
* @author : yq
]]

local moon = require "moon"
local common = require "common"
local ChatEnum = require("common.Enum.ChatEnum") --聊天频道类型枚举
local cluster = require("cluster")
local queue = require "moon.queue"
local GameCfg = common.GameCfg
local ErrorCode = common.ErrorCode
local CmdCode = common.CmdCode
local lock = queue()
---@type chatchannel_context
local context = ...
local scripts = context.scripts




---@class ChatChannel
local ChatChannel = {}

function ChatChannel.Init()
    return true
     
end

function ChatChannel.Start()
    
    return true
end
function ChatChannel.InitData(channel_id, channel_type, channel_addr)
    context.channel_id = channel_id
    context.channel_type = channel_type
    context.channel_addr = channel_addr
    -- 创建一个协程，每秒发送并清空频道消息
    moon.async(function()
        while true do
            moon.sleep(1000) -- 每秒发送一次
            local scope <close> = lock()
            if #context.channel_msgs > 0 then
                -- 判断是否系统消息频道
                if context.channel_type == ChatEnum.EChannelType.CHANNEL_TYPE_SYSTEM
                    or context.channel_type == ChatEnum.EChannelType.CHANNEL_TYPE_WORLD then
                    -- 遍历所有游戏节点，发送消息到游戏节点的gate服务
                    for node_id, gate_addr in pairs(context.game_nodes) do
                        cluster.send(node_id, gate_addr, "Gate.BroadcastSysChat", context.channel_msgs)
                    end
                else
                    context.send_users(ChatChannel.GetMembers(), {}, "ChatProxy.OnChatMsg", context.channel_msgs)
                end
                
                context.channel_msgs = {} -- 清空消息列表
            end
        end
    end)
    return {code = ErrorCode.None}
end
function ChatChannel.Shutdown()
    moon.quit()
    return true
end
function ChatChannel.AddPlayer(uid)
    local scope <close> = lock()
    context.memember_uids[uid] = 1
    context.send_user(uid,"ChatProxy.OnJoinChannel",context.channel_type,context.channel_addr)
    moon.info("ChatChannel.AddPlayer uid = ", uid, " channel_id = ", context.channel_id, " channel_type = ", context.channel_type)
    return true
end

function ChatChannel.RemovePlayer(uid)
    local scope <close> = lock()
    context.memember_uids[uid] = nil
    context.send_user(uid, "ChatProxy.OnLeaveChannel",context.channel_type)
    moon.info("ChatChannel.RemovePlayer uid = ", uid, " channel_id = ", context.channel_id, " channel_type = ", context.channel_type)
    return true
end
function ChatChannel.GetMembers()
    local member_keys = {}
    for k, _ in pairs(context.memember_uids) do
        table.insert(member_keys, k)
    end
    return member_keys
end
-- 添加频道消息
function ChatChannel.AddMsg(msg)
    local scope <close> = lock()
    table.insert(context.channel_msgs, msg)
    moon.info("ChatChannel.AddMsg msg = ", msg, " channel_id = ", context.channel_id, " channel_type = ",
    context.channel_type)
    return true
end
function ChatChannel.AddGameNode(node_id,gate_addr)
    local scope <close> = lock()
    context.game_nodes[node_id] = gate_addr
    moon.info("ChatChannel.AddGameNode node_id = ", node_id, " gate_addr = ", gate_addr, " channel_id = ", context.channel_id, " channel_type = ", context.channel_type)
    return true
end
function ChatChannel.RemoveGameNode(node_id)
    local scope <close> = lock()
    context.game_nodes[node_id] = nil
    moon.info("ChatChannel.RemoveGameNode node_id = ", node_id, " channel_id = ", context.channel_id, " channel_type = ",
    context.channel_type)
    return true
end

return ChatChannel