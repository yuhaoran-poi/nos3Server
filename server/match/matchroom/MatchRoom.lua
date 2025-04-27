--[[
* @file : MatchRoom.lua
* @type: multi service
* @brief : 比赛房间流程服务
* @author : yq
]]

local moon = require "moon"
local common = require "common"
local cluster = require("cluster")
local queue = require "moon.queue"
local lock = queue()
---@type matchroom_context
local context = ...
local scripts = context.scripts




---@class MatchRoom
local MatchRoom = {}

function MatchRoom.Init()
    return true
     
end

function MatchRoom.Start()
    
    return true
end
function MatchRoom.InitData()
    
end
function MatchRoom.Shutdown()
    moon.quit()
    return true
end
function MatchRoom.AddPlayer(uid)
    local scope <close> = lock()
    --context.memember_uids[uid] = 1
    --context.send_user(uid,"ChatProxy.OnJoinChannel",context.channel_type,context.channel_addr)
    --moon.info("MatchRoom.AddPlayer uid = ", uid, " channel_id = ", context.channel_id, " channel_type = ", context.channel_type)
    return true
end

function MatchRoom.RemovePlayer(uid)
    local scope <close> = lock()
    --context.memember_uids[uid] = nil
    --context.send_user(uid, "ChatProxy.OnLeaveChannel",context.channel_type)
    --moon.info("MatchRoom.RemovePlayer uid = ", uid, " channel_id = ", context.channel_id, " channel_type = ", context.channel_type)
    return true
end
function MatchRoom.GetMembers()
    local member_keys = {}
    for k, _ in pairs(context.memember_uids) do
        table.insert(member_keys, k)
    end
    return member_keys
end
 
 
 
return MatchRoom