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
local ErrorCode = common.ErrorCode  --逻辑错误码
---@type matchmgr_context
local context = ...
local scripts = context.scripts ---方便访问同服务的其它lua模块
 
---@class MatchMgr
local MatchMgr = {}

function MatchMgr.Init()
 
    return true
end

function MatchMgr.Start()
    moon.async(function()
        while true do
            moon.sleep(3000) -- 每3秒
            MatchMgr.DoMatch()
        end
    end)
    return true
end

 
function MatchMgr.Shutdown()
    moon.quit()
    return true
end
function MatchMgr.DoMatch()
    MatchMgr.DoNormalMatch()
    MatchMgr.DoRankingMatch()
    MatchMgr.DoLRSMatch()
    MatchMgr.DoQLMatch()
    MatchMgr.DoJDZMatch()
end
--普通匹配
function MatchMgr.DoNormalMatch()
    -- 一共6个队列，按人数划分开。1~5放人的队列 6放鬼的队列
    local all_teams = {}

end
-- 排位匹配
function MatchMgr.DoRankingMatch()
end
-- 狼人杀匹配
function MatchMgr.DoLRSMatch()
end
-- 驱灵匹配
function MatchMgr.DoQLMatch()
end
-- 据点战匹配
function MatchMgr.DoJDZMatch()
end
-- 创建匹配房间
function MatchMgr.CreateMatchRoom(uid, team_id, match_type, camp_type, need_ai)
     
    local room_id = uuid.next()
    local conf = {
        name = "matchroom" .. room_id,
        file = "matchroom/service_matchroom.lua"
    }
    local addr_room = moon.new_service(conf)
    if addr_room == 0 then
        return { code = ErrorCode.CreateMatchRoomServiceErr, error = "create matchroom service failed!" }
    end
    -- 初始化房间数据
    local res, err = moon.call("lua", addr_room, "MatchRoom.InitData", room_id,
        match_type, addr_room)
    if not res then
        return { code = ErrorCode.InitChatChannelDataErr, error = err }
    end
    context.rooms[match_type][room_id] = {
        room_id = room_id,
        addr_room = addr_room
    }
    return { code = ErrorCode.None, room_id = room_id, addr_room = addr_room }
end

-- 房子请求开始匹配
function MatchMgr.MatchReq(uid, team_id, match_type, camp_type, need_ai)
    -- 向队伍管理器请求队伍匹配数据
    
    context.teams[match_type][team_id] = {
        team_id = team_id,
        match_type = match_type,
        camp_type = camp_type,
        need_ai = need_ai,
        uids = {}
    }
end
 
return MatchMgr