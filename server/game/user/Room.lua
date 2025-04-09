local moon = require("moon")
local common = require("common")
local clusterd = require("cluster")
local json = require "json"
local CmdCode = common.CmdCode
local GameCfg = common.GameCfg
local Database = common.Database
local protocol = common.protocol
local ErrorCode = common.ErrorCode

---@type user_context
local context = ...
local scripts = context.scripts

---@class Room
local Room = {}

function Room.PBCreateRoomReqCmd(req)
    if context.roomid then
        return context.S2C(context.net_id, CmdCode["PBCreateRoomRspCmd"], {
            code = ErrorCode.RoomAlreadyInRoom,
            error = "你已在房间中房间",
        }, req.msg_context.stub_id)
    end

    local user_data = scripts.UserModel.Get()
    if not user_data or not user_data.simple then
        return context.S2C(context.net_id, CmdCode["PBCreateRoomRspCmd"], {
            code = ErrorCode.ServerInternalError,
            error = "用户不存在",
        }, req.msg_context.stub_id)
    end

    local res, err = clusterd.call(3999, "roommgr", "Roommgr.CreateRoom", {
        msg = req.msg,
        self_info = user_data.simple,
    })
    --local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
    if err then
        return context.S2C(context.net_id, CmdCode["PBCreateRoomRspCmd"], {
            code = ErrorCode.ServerInternalError,
            error = "system error",
        }, req.msg_context.stub_id)
    end

    context.roomid = res.roomid

    return context.S2C(context.net_id, CmdCode["PBCreateRoomRspCmd"], res, req.msg_context.stub_id)
end

function Room.PBSearchRoomReqCmd(req)
    if req.msg.roomid then
        local res, err = clusterd.call(3999, "roommgr", "Roommgr.SearchRooms", {
            roomid = req.msg.roomid,
        })
        if err then
            return context.S2C(context.net_id, CmdCode["PBSearchRoomRspCmd"], {
                code = ErrorCode.ServerInternalError,
                error = "system error",
            }, req.msg_context.stub_id)
        end

        return context.S2C(context.net_id, CmdCode["PBSearchRoomRspCmd"], res, req.msg_context.stub_id)
    else
        -- 按房间类型划分来查询，准备通过redis直接读取
    end
end

function Room.PBModRoomReqCmd(req)
    if not context.roomid then
        return context.S2C(context.net_id, CmdCode["PBModRoomRspCmd"], {
            code = ErrorCode.RoomNotCreated,
            error = "你还未创建房间",
        }, req.msg_context.stub_id)
    end

    local res, err = clusterd.call(3999, "roommgr", "Roommgr.ModRoom", req.msg)
    if err then
        return context.S2C(context.net_id, CmdCode["PBModRoomRspCmd"], {
            code = ErrorCode.ServerInternalError,
            error = "system error",
        }, req.msg_context.stub_id)
    end

    return context.S2C(context.net_id, CmdCode["PBModRoomRspCmd"], res, req.msg_context.stub_id)
end

function Room.OnRoomInfoSync(room_data)
    context.S2C(context.net_id, CmdCode["PBOnRoomInfoSyncCmd"], { room_data = room_data }, 0)
end

function Room.PBApplyRoomReqCmd(req)
    if context.roomid and context.roomid > 0 then
        return context.S2C(context.net_id, CmdCode["PBApplyRoomRspCmd"], {
            code = ErrorCode.RoomAlreadyInRoom,
            error = "你已在房间中",
            roomid = context.roomid,
        }, req.msg_context.stub_id)
    end

    local user_data = scripts.UserModel.Get()
    if not user_data or not user_data.simple then
        return context.S2C(context.net_id, CmdCode["PBApplyRoomRspCmd"], {
            code = ErrorCode.ServerInternalError,
            error = "用户不存在",
        }, req.msg_context.stub_id)
    end

    local res, err = clusterd.call(3999, "roommgr", "Roommgr.ApplyToRoom", {
        msg = req.msg,
        apply_info = user_data.simple,
    })
    if err then
        return context.S2C(context.net_id, CmdCode["PBApplyRoomRspCmd"], {
            code = ErrorCode.ServerInternalError,
            error = "system error",
        }, req.msg_context.stub_id)
    end
    
    return context.S2C(context.net_id, CmdCode["PBApplyRoomRspCmd"], res, req.msg_context.stub_id)
end

-- 新增申请通知回调
function Room.OnApplyNotify(data)
    context.S2C(context.net_id, CmdCode["PBApplyRoomSyncCmd"], {
        uid = data.apply_info.uid,
        roomid = data.roomid,
        apply_info = data.apply_info
    }, 0)
end

function Room.PBDealApplyRoomReqCmd(req)
    if not context.roomid then
        return context.S2C(context.net_id, CmdCode["PBDealApplyRoomRspCmd"], {
            code = ErrorCode.RoomNotCreated,
            error = "你还未创建房间",
        }, req.msg_context.stub_id)
    end

    local res, err = clusterd.call(3999, "roommgr", "Roommgr.DealApply", {
        roomid = context.roomid,
        master_uid = context.uid,
        deal_uid = req.msg.deal_uid,
        deal_op = req.msg.deal_op
    })
    if err then
        return context.S2C(context.net_id, CmdCode["PBDealApplyRoomRspCmd"], {
            code = ErrorCode.ServerInternalError,
            error = "system error",
        }, req.msg_context.stub_id)
    end

    return context.S2C(context.net_id, CmdCode["PBDealApplyRoomRspCmd"], {
        code = res.code,
        error = res.error or "",
        deal_uid = req.msg.deal_uid,
        deal_op = req.msg.deal_op
    }, req.msg_context.stub_id)
end

function Room.OnMemberEnter(res)
    --local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
    moon.info("OnMemberEnter uid", context.uid, res.member_data.mem_info.uid)
    if res.member_data.mem_info.uid == context.uid then
        context.roomid = res.roomid
        moon.info("OnMemberEnter roomid", context.roomid, res.roomid)
    end
    context.S2C(context.net_id, CmdCode["PBEnterRoomSyncCmd"], res, 0)
end

function Room.PBExitRoomReqCmd(req)
    if not context.roomid then
        return context.S2C(context.net_id, CmdCode["PBExitRoomRspCmd"], {
            code = ErrorCode.RoomMemberNotFound,
            error = "你还未加入房间",
        }, req.msg_context.stub_id)
    end

    local res, err = clusterd.call(3999, "roommgr", "Roommgr.ExitRoom", req.msg)
    if err then
        return context.S2C(context.net_id, CmdCode["PBExitRoomRspCmd"], {
            code = ErrorCode.ServerInternalError,
            error = "system error",
        }, req.msg_context.stub_id)
    end

    return context.S2C(context.net_id, CmdCode["PBExitRoomRspCmd"], {
        code = res.code,
        error = res.error or "",
        uid = req.msg.uid,
        roomid = req.msg.roomid
    }, req.msg_context.stub_id)
end

function Room.OnMemberExit(res)
    if res.uid == context.uid then
        context.roomid = nil -- body
    end
    context.S2C(context.net_id, CmdCode["PBExitRoomSyncCmd"], res, 0)
end

function Room.PBKickRoomReqCmd(req)
    if not context.roomid then
        return context.S2C(context.net_id, CmdCode["PBKickRoomRspCmd"], {
            code = ErrorCode.RoomNotCreated,
            error = "你还未创建房间",
        }, req.msg_context.stub_id)
    end

    if context.uid == req.msg.kick_uid then
        return context.S2C(context.net_id, CmdCode["PBKickRoomRspCmd"], {
            code = ErrorCode.RoomPermissionDenied,
            error = "不能踢出自己",
        }, req.msg_context.stub_id)
    end

    local res, err = clusterd.call(3999, "roommgr", "Roommgr.KickMember", req.msg)
    if err then
        return context.S2C(context.net_id, CmdCode["PBExitRoomRspCmd"], {
            code = ErrorCode.ServerInternalError,
            error = "system error",
        }, req.msg_context.stub_id)
    end

    return context.S2C(context.net_id, CmdCode["PBExitRoomRspCmd"], {
        code = res.code,
        error = res.error or "",
        self_uid = req.msg.self_uid,
        roomid = req.msg.roomid,
        kick_uid = req.msg.kick_uid
    }, req.msg_context.stub_id)
end

function Room.OnMemberKick(res)
    if res.kick_uid == context.uid then
        context.roomid = nil -- body
    end
    context.S2C(context.net_id, CmdCode["PBKickRoomSyncCmd"], res, 0)
end

function Room.PBReadyRoomReqCmd(req)
    if not context.roomid or context.roomid ~= req.msg.roomid then
        return context.S2C(CmdCode.PBReadyRoomRspCmd, {
            code = ErrorCode.RoomNotFound,
            error = "不在目标房间内"
        })
    end

    local res, err = clusterd.call(3999, "roommgr", "Roommgr.UpdateReadyStatus", req.msg)
    if err then
        return context.S2C(context.net_id, CmdCode["PBReadyRoomRspCmd"], {
            code = ErrorCode.ServerInternalError,
            error = "system error",
        }, req.msg_context.stub_id)
    end

    return context.S2C(context.net_id, CmdCode["PBReadyRoomRspCmd"], res, req.msg_context.stub_id)
end

function Room.OnReadyStatusUpdate(res)
    -- 更新准备状态并广播同步
    context.S2C(context.net_id, CmdCode["PBReadyRoomSyncCmd"], res, 0)
end

function Room.PBGetRoomInfoReqCmd(req)
    --local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
    if not context.roomid or context.roomid ~= req.msg.roomid then
        return context.S2C(CmdCode.PBReadyRoomRspCmd, {
            code = ErrorCode.RoomMemberNotFound,
            error = "不在目标房间内"
        })
    end

    local res, err = clusterd.call(3999, "roommgr", "Roommgr.GetRoomInfo", req.msg)
    if err or not res then
        return context.S2C(context.net_id, CmdCode["PBGetRoomInfoRspCmd"], {
            code = ErrorCode.ServerInternalError,
            error = "system error",
        }, req.msg_context.stub_id)
    end

    -- 返回查询结果
    return context.S2C(context.net_id, CmdCode["PBGetRoomInfoRspCmd"], res, req.msg_context.stub_id)
end

return Room
