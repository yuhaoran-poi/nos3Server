--[[
* @file : MatchMgr.lua
* @type: single service
* @brief : 匹配管理服务
* @author : yq
]]

local moon = require "moon"
local uuid = require "uuid"
local coqueue = require "moon.queue"
local common = require "common"
 
---@type matchmgr_context
local context = ...
local scripts = context.scripts ---方便访问同服务的其它lua模块
 
---@class MatchMgr
local MatchMgr = {}

function MatchMgr.Init()
 
    return true
end

function MatchMgr.Start()
 
    return true
end

 
function MatchMgr.Shutdown()
    moon.quit()
    return true
end

-- 创建匹配房间
function MatchMgr.CreateMatchRoom(uid, team_id, match_type, camp_type, need_ai)
    -- 生成唯一房间ID
    local room_id = uuid.generate()
    
    -- 创建房间数据
    local room = {
        id = room_id,
        uid = uid,
        team_id = team_id,
        match_type = match_type,
        camp_type = camp_type,
        need_ai = need_ai,
        members = {},
        created_time = moon.time(),
        status = 0 -- 0:等待中 1:匹配中 2:已取消 3:已完成
    }
    
    -- 保存房间数据
    scripts.RoomModel.Set(room_id, room)
    
    -- 返回成功响应
    return {
        code = common.ErrorCode.None,
        room_id = room_id
    }
end
 
 
return MatchMgr