local moon = require "moon"
local common = require "common"
local cluster = require("cluster")
local GameCfg = common.GameCfg
local ErrorCode = common.ErrorCode
local CmdCode = common.CmdCode
local CmdEnum = common.CmdEnum
local MatchEnum = require("common.MatchEnum")
---@type user_context
local context = ...
local scripts = context.scripts

---@class MatchProxy
local MatchProxy = {}

function MatchProxy.Init()
    local DB = scripts.UserModel.Get()
    DB.match_info = {
        room_id = 0, -- 房间ID
    }
end

function MatchProxy.Start()
    -- body
end
-- 客户端消息请求
-- 房主发起匹配请求
function MatchProxy.PBMatchReqCmd(req)
    local DB = scripts.UserModel.Get()
    local match_info = DB.match_info
    if match_info.room_id ~= 0 then
        context.R2C(CmdCode.PBMatchRspCmd, {
            code = ErrorCode.MatchRoomAlreadyExist
        }, req)
        return ErrorCode.MatchRoomAlreadyExist
    end
    local match_type = req.msg.match_type
    local camp_type = req.msg.camp_type
    local need_ai = req.msg.need_ai
    -- 参数检查
    if not match_type or not camp_type or not need_ai then
        context.R2C(CmdCode.PBMatchRspCmd, {
            code = ErrorCode.MATCH_INVALID_PARAM
        }, req)
        return ErrorCode.MATCH_INVALID_PARAM
    end
    -- 匹配类型检查
    if match_type < MatchEnum.MATCH_TYPE_DEF.MATCH_TYPE_NORMAL or match_type >= MatchEnum.MATCH_TYPE_DEF.MATCH_TYPE_MAX then
        context.R2C(CmdCode.PBMatchRspCmd, {
            code = ErrorCode.MATCH_INVALID_MATCH_TYPE
        }, req)
        return ErrorCode.MATCH_INVALID_MATCH_TYPE
    end
    -- 阵营类型检查
    if camp_type < MatchEnum.MATCH_CAMP_DEF.MATCH_CAMP_NULL or camp_type >= MatchEnum.MATCH_CAMP_DEF.MATCH_CAMP_MAX then
        context.R2C(CmdCode.PBMatchRspCmd, {
            code = ErrorCode.MATCH_INVALID_CAMP_TYPE
        }   , req)
        return ErrorCode.MATCH_INVALID_CAMP_TYPE
    end
    -- 狼人杀、驱灵模式和据点战模式只能选人
    if match_type == MatchEnum.MATCH_TYPE_DEF.MATCH_TYPE_LRS or match_type == MatchEnum.MATCH_TYPE_DEF.MATCH_TYPE_QL or match_type == MatchEnum.MATCH_TYPE_DEF.MATCH_TYPE_JDZ then
        if camp_type ~= MatchEnum.MATCH_CAMP_DEF.MATCH_CAMP_HUMAN then
            context.R2C(CmdCode.PBMatchRspCmd, {
                code = ErrorCode.MATCH_INVALID_CAMP_TYPE
            }  , req)
            return ErrorCode.MATCH_INVALID_CAMP_TYPE
        end
    end
    -- 队伍判断
    local team_id = DB.team.team_id
    if team_id == 0 then
        context.R2C(CmdCode.PBMatchRspCmd, {
            code = ErrorCode.MATCH_NOT_TEAM_LEADER
        }, req)
        return ErrorCode.MATCH_NOT_TEAM_LEADER
    else
        -- 有队伍，判断是否是队长
        local team_info = DB.teams[team_id]
        if team_info.leader_uid ~= context.uid then
            context.R2C(CmdCode.PBMatchRspCmd, {
                code = ErrorCode.MATCH_NOT_TEAM_LEADER
            }, req)
            return ErrorCode.MATCH_NOT_TEAM_LEADER
        end
        -- 如果选择鬼阵营，队伍人数不能超过1人
        if camp_type == MatchEnum.MATCH_CAMP_DEF.MATCH_CAMP_GHOST and table.size(team_info.members) > 1 then
            context.R2C(CmdCode.PBMatchRspCmd, {
                code = ErrorCode.MATCH_GHOST_TEAM_MEMBER_COUNT_LIMIT
            }, req)
            return ErrorCode.MATCH_GHOST_TEAM_MEMBER_COUNT_LIMIT -- 鬼阵营队伍人数不能超过1人
        end
    end
    -- 调用matchmgr服务创建匹配房间
    local res, err = cluster.call(CmdEnum.FixedNodeId.MATCH, "matchmgr", "MatchMgr.CreateMatchRoom",
                                  context.uid,team_id, match_type, camp_type, need_ai)
    if not res then
        print("CreateMatchRoom failed:", err)
        context.R2C(CmdCode.PBMatchRspCmd, {
            code = ErrorCode.MATCH_CREATE_ROOM_FAILED
        }, req)
        return ErrorCode.MATCH_CREATE_ROOM_FAILED
    end
    if res.code ~= ErrorCode.None then
        context.R2C(CmdCode.PBMatchRspCmd, {
            code = res.code
        }, req)
        return res.code
    end
    -- 返回匹配成功
    context.R2C(CmdCode.PBMatchRspCmd, {
        code = ErrorCode.None,
        room_id = res.room_id
    }, req)
end
 

function MatchProxy.Online()
    
end
function MatchProxy.Offline()
   
end
return MatchProxy
