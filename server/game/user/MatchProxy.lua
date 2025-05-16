local moon = require "moon"
local common = require "common"
local cluster = require("cluster")
local GameCfg = common.GameCfg
local ErrorCode = common.ErrorCode
local CmdCode = common.CmdCode
local CmdEnum = common.CmdEnum
local MatchEnum = require("common.Enum.MatchEnum")
---@type user_context
local context = ...
local scripts = context.scripts

---@class MatchProxy
local MatchProxy = {}

function MatchProxy.Init()
    
end

function MatchProxy.Start()
    local DB = scripts.UserModel.Get()
    DB.match_info = {
        room_id = 0, -- 房间ID
    }
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
            code = ErrorCode.MatchInvalidParam
        }, req)
        return ErrorCode.MatchInvalidParam
    end
    -- 匹配类型检查
    if match_type < MatchEnum.MATCH_TYPE_DEF.MATCH_TYPE_NORMAL or match_type >= MatchEnum.MATCH_TYPE_DEF.MATCH_TYPE_MAX then
        context.R2C(CmdCode.PBMatchRspCmd, {
            code = ErrorCode.MatchInvalidMatchType
        }, req)
        return ErrorCode.MatchInvalidMatchType
    end
    -- 阵营类型检查
    if camp_type < MatchEnum.MATCH_CAMP_DEF.MATCH_CAMP_NULL or camp_type >= MatchEnum.MATCH_CAMP_DEF.MATCH_CAMP_MAX then
        context.R2C(CmdCode.PBMatchRspCmd, {
            code = ErrorCode.MatchInvalidCampType
        }   , req)
        return ErrorCode.MatchInvalidCampType
    end
    -- 狼人杀、驱灵模式和据点战模式只能选人
    if match_type == MatchEnum.MATCH_TYPE_DEF.MATCH_TYPE_LRS or match_type == MatchEnum.MATCH_TYPE_DEF.MATCH_TYPE_QL or match_type == MatchEnum.MATCH_TYPE_DEF.MATCH_TYPE_JDZ then
        if camp_type ~= MatchEnum.MATCH_CAMP_DEF.MATCH_CAMP_HUMAN then
            context.R2C(CmdCode.PBMatchRspCmd, {
                code = ErrorCode.MatchInvalidCampType
            }  , req)
            return ErrorCode.MatchInvalidCampType
        end
    end
    -- 队伍判断
    local team_id = DB.team.team_id
    if team_id == 0 then
        context.R2C(CmdCode.PBMatchRspCmd, {
            code = ErrorCode.TeamNotMaster
        }, req)
        return ErrorCode.TeamNotMaster
    else
        -- 有队伍，判断是否是队长
        local team_info = DB.teams[team_id]
        if team_info.leader_uid ~= context.uid then
            context.R2C(CmdCode.PBMatchRspCmd, {
                code = ErrorCode.TeamNotMaster
            }, req)
            return ErrorCode.TeamNotMaster
        end
        -- 如果选择鬼阵营，队伍人数不能超过1人
        if camp_type == MatchEnum.MATCH_CAMP_DEF.MATCH_CAMP_GHOST and table.size(team_info.members) > 1 then
            context.R2C(CmdCode.PBMatchRspCmd, {
                code = ErrorCode.MatchGhostTeamMemberCountLimit
            }, req)
            return ErrorCode.MatchGhostTeamMemberCountLimit -- 鬼阵营队伍人数不能超过1人
        end
    end
    -- 调用matchmgr服务创建匹配房间
    local res, err = cluster.call(CmdEnum.FixedNodeId.MATCH, "matchmgr", "MatchMgr.MatchReq",
                                  context.uid,team_id, match_type, camp_type, need_ai)
    if not res then
        print("MatchReq failed:", err)
        context.R2C(CmdCode.PBMatchRspCmd, {
            code = ErrorCode.MatchReqFailed
        }, req)
        return ErrorCode.MatchReqFailed
    end
    if res.code ~= ErrorCode.None then
        context.R2C(CmdCode.PBMatchRspCmd, {
            code = res.code
        }, req)
        return res.code
    end
    -- 返回匹配成功
    context.R2C(CmdCode.PBMatchRspCmd, {
        code = ErrorCode.None
    }, req)
end
 

function MatchProxy.Online()
    
end
function MatchProxy.Offline()
   
end
return MatchProxy
