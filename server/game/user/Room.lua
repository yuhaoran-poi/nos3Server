local moon = require("moon")
local common = require("common")
local clusterd = require("cluster")
local json = require "json"
local CmdCode = common.CmdCode
local GameCfg = common.GameCfg
local Database = common.Database
local protocol = common.protocol
local ErrorCode = common.ErrorCode
local ProtoEnum = require("tools.ProtoEnum")
local RoomDef = require("common.def.RoomDef")
local UserAttrDef = require("common.def.UserAttrDef")
local ChatLogic = require("common.logic.ChatLogic")
local BagDef = require("common.def.BagDef")
local ItemDef = require("common.def.ItemDef")
local ItemDefine = require("common.logic.ItemDefine")
local CommonCfgDef = require("common.def.CommonCfgDef")

---@type user_context
local context = ...
local scripts = context.scripts

---@class Room
local Room = {}

function Room.ForceExitRoom()
    if not context.roomid or not context.uid then
        return
    end

    local chat_ret = ChatLogic.LeaveRoomChannel(context.roomid, context.uid)
    if chat_ret.code ~= ErrorCode.None then
        moon.error(string.format("LeaveRoomChannel uid:%d, roomid:%d, code:%d, error:%s", context.uid, context.roomid,
            chat_ret.code, chat_ret.error))
    end

    -- clusterd.send(3999, "roommgr", "Roommgr.ExitRoom", { uid = context.uid, roomid = context.roomid, is_force = true })
    -- context.roomid = nil
    clusterd.send(3999, "roommgr", "Roommgr.AwayRoom", { uid = context.uid, roomid = context.roomid })
end

function Room.PBCreateRoomReqCmd(req)
    if context.roomid then
        return context.S2C(context.net_id, CmdCode["PBCreateRoomRspCmd"], {
            code = ErrorCode.RoomAlreadyInRoom,
            error = "你已在房间中房间",
        }, req.msg_context.stub_id)
    end

    local brief_data = scripts.User.GetUsrRoomBriefData()
    if not brief_data or table.size(brief_data) <= 0 then
        return context.S2C(context.net_id, CmdCode["PBCreateRoomRspCmd"], {
            code = ErrorCode.ServerInternalError,
            error = "用户不存在",
        }, req.msg_context.stub_id)
    end
    moon.debug(string.format("brief_data err:\n%s", json.pretty_encode(brief_data)))
    local res, err = clusterd.call(3999, "roommgr", "Roommgr.CreateRoom", {
        msg = req.msg,
        self_info = brief_data,
    })
    if err then
        moon.error(string.format("Roommgr.CreateRoom err:\n%s", json.pretty_encode(err)))
        return context.S2C(context.net_id, CmdCode["PBCreateRoomRspCmd"], {
            code = ErrorCode.ServerInternalError,
            error = "system error",
        }, req.msg_context.stub_id)
    end
    if res.code == ErrorCode.None then
        context.roomid = res.roomid
        -- 加入队伍频道
        local chat_ret = ChatLogic.JoinRoomChannel(context.roomid, context.uid)
        if chat_ret.code ~= ErrorCode.None then
            moon.error(string.format("JoinRoomChannel uid:%d, roomid:%d, code:%d, error:%s", context.uid,
                context.roomid, chat_ret.code, chat_ret.error))
        end
        -- 同步进入房间状态
        local update_user_attr = {}
        update_user_attr[ProtoEnum.UserAttrType.is_online] = UserAttrDef.ONLINE_STATE.IN_ROOM
        scripts.User.SetUserAttr(update_user_attr, true)
    end

    return context.S2C(context.net_id, CmdCode["PBCreateRoomRspCmd"], res, req.msg_context.stub_id)
end

function Room.PBSearchRoomReqCmd(req)
    if req.msg.roomid and req.msg.roomid ~= 0 then
        local res, err = clusterd.call(3999, "roommgr", "Roommgr.SearchRooms", {
            roomid = req.msg.roomid,
        })
        --
        if err then
            return context.S2C(context.net_id, CmdCode["PBSearchRoomRspCmd"], {
                code = ErrorCode.ServerInternalError,
                error = "system error",
            }, req.msg_context.stub_id)
        end

        return context.S2C(context.net_id, CmdCode["PBSearchRoomRspCmd"], res, req.msg_context.stub_id)
    else
        local conditions = {
            is_open = 1,
            chapter = req.msg.chapter or 0,
            difficulty = req.msg.difficulty or 0,
        }
        local result = Database.search_rooms(context.addr_db_server, conditions, req.msg.start_idx, 100) -- 按房间类型划分来查询，准备通过redis直接读取
        local res = {
            code = ErrorCode.None,
            error = "搜索完成",
            roomid = req.msg.roomid or 0,
            chapter = req.msg.chapter or 0,
            difficulty = req.msg.difficulty or 0,
            start_idx = req.msg.start_idx or 0,
            search_data = {}
        }
        if result.total > 0 then
            for k, v in pairs(result.data) do
                table.insert(res.search_data, {
                    roomid = v.roomid,
                    chapter = v.chapter,
                    difficulty = v.difficulty,
                    playercnt = v.playercnt,
                    master_id = v.master_id,
                    master_name = v.master_name,
                    is_open = v.is_open,
                    needcheck = v.needcheck,
                    needpwd = v.needpwd,
                    describe = v.describe,
                })
            end
        end
        --
        return context.S2C(context.net_id, CmdCode["PBSearchRoomRspCmd"], res, req.msg_context.stub_id)
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

function Room.OnRoomInfoSync(sync_msg)
    moon.error("OnRoomInfoSync")
    -- print_r(sync_msg)
    local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
    if sync_msg.sync_type == RoomDef.SyncType.PlayerEnter
     and sync_msg.sync_info and sync_msg.sync_info.players then
        for _, player_info in pairs(sync_msg.sync_info.players) do
            if player_info.mem_info and player_info.mem_info.uid == context.uid then
                context.roomid = sync_msg.roomid
                moon.info("OnMemberEnter roomid", context.roomid, sync_msg.roomid)
                -- 加入队伍频道
                local chat_ret = ChatLogic.JoinRoomChannel(sync_msg.roomid, context.uid)
                if chat_ret.code ~= ErrorCode.None then
                    moon.error(string.format("JoinRoomChannel uid:%d, roomid:%d, code:%d, error:%s", context.uid,
                        sync_msg.roomid, chat_ret.code, chat_ret.error))
                end
                -- 同步进入房间状态
                local update_user_attr = {}
                update_user_attr[ProtoEnum.UserAttrType.is_online] = UserAttrDef.ONLINE_STATE.IN_ROOM
                scripts.User.SetUserAttr(update_user_attr, true)
            end
        end
    elseif sync_msg.sync_type == RoomDef.SyncType.PlayerExit
     and sync_msg.sync_info and sync_msg.sync_info.players then
        for _, player_info in pairs(sync_msg.sync_info.players) do
            if player_info.mem_info and player_info.mem_info.uid == context.uid then
                context.roomid = nil
                moon.info("OnMemberExit roomid", context.roomid, sync_msg.roomid)
            end
        end
    elseif sync_msg.sync_type == RoomDef.SyncType.PlayerKick
     and sync_msg.sync_info and sync_msg.sync_info.players then
        for _, player_info in pairs(sync_msg.sync_info.players) do
            if player_info.mem_info and player_info.mem_info.uid == context.uid then
                -- 退出队伍频道
                local chat_ret = ChatLogic.LeaveRoomChannel(context.roomid, context.uid)
                if chat_ret.code ~= ErrorCode.None then
                    moon.error(string.format("LeaveRoomChannel uid:%d, roomid:%d, code:%d, error:%s", context.uid,
                        context.roomid,
                        chat_ret.code, chat_ret.error))
                end
                -- 同步退出房间状态
                local update_user_attr = {}
                update_user_attr[ProtoEnum.UserAttrType.is_online] = UserAttrDef.ONLINE_STATE.ONLINE
                scripts.User.SetUserAttr(update_user_attr, true)

                context.roomid = nil
                moon.info("OnMemberKick roomid", context.roomid, sync_msg.roomid)
            end
        end
    elseif sync_msg.sync_type == RoomDef.SyncType.GameStart then
        if context.roomid ~= sync_msg.roomid then
            moon.error("OnGameStart ERR uid roomid", context.uid, sync_msg.roomid)
        end
        moon.info("OnGameStart uid roomid", context.uid, sync_msg.roomid)
    elseif sync_msg.sync_type == RoomDef.SyncType.GameStartFailed then
        if context.roomid ~= sync_msg.roomid then
            moon.error("OnGameEnd ERR uid roomid", context.uid, sync_msg.roomid)
        end
        moon.info("OnGameEnd uid roomid", context.uid, sync_msg.roomid)
    end
    context.S2C(context.net_id, CmdCode["PBRoomSyncCmd"], sync_msg, 0)
end

function Room.PBApplyRoomReqCmd(req)
    if context.roomid and context.roomid > 0 then
        return context.S2C(context.net_id, CmdCode["PBApplyRoomRspCmd"], {
            code = ErrorCode.RoomAlreadyInRoom,
            error = "你已在房间中",
            roomid = context.roomid,
        }, req.msg_context.stub_id)
    end

    --local user_data = scripts.UserModel.Get()
    local brief_data = scripts.User.GetUsrRoomBriefData()
    if not brief_data or table.size(brief_data) <= 0 then
        return context.S2C(context.net_id, CmdCode["PBApplyRoomRspCmd"], {
            code = ErrorCode.ServerInternalError,
            error = "用户不存在",
        }, req.msg_context.stub_id)
    end

    local res, err = clusterd.call(3999, "roommgr", "Roommgr.ApplyToRoom", {
        msg = req.msg,
        apply_info = brief_data,
    })
    if err then
        return context.S2C(context.net_id, CmdCode["PBApplyRoomRspCmd"], {
            code = ErrorCode.ServerInternalError,
            error = "system error",
        }, req.msg_context.stub_id)
    end
    
    return context.S2C(context.net_id, CmdCode["PBApplyRoomRspCmd"], res, req.msg_context.stub_id)
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

function Room.OnDealApplyRoomSync(sync_msg)
    context.S2C(context.net_id, CmdCode["PBDealApplyRoomSyncCmd"], sync_msg, 0)
end

function Room.PBEnterRoomReqCmd(req)
    if context.roomid and context.roomid > 0 then
        return context.S2C(context.net_id, CmdCode["PBEnterRoomRspCmd"], {
            code = ErrorCode.RoomAlreadyInRoom,
            error = "你已在房间中",
            uid = context.uid,
            roomid = context.roomid,
        }, req.msg_context.stub_id)
    end

    ----local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
    local brief_data = scripts.User.GetUsrRoomBriefData()
    if not brief_data or table.size(brief_data) <= 0 then
        return context.S2C(context.net_id, CmdCode["PBEnterRoomRspCmd"], {
            code = ErrorCode.ServerInternalError,
            error = "用户不存在",
            uid = context.uid,
        }, req.msg_context.stub_id)
    end

    local res, err = clusterd.call(3999, "roommgr", "Roommgr.EnterRoom", {
        msg = req.msg,
        mem_info = brief_data,
    })
    if err then
        moon.error(string.format("Roommgr.EnterRoom err:\n%s", json.pretty_encode(err)))
        return context.S2C(context.net_id, CmdCode["PBEnterRoomRspCmd"], {
            code = ErrorCode.ServerInternalError,
            error = "system error",
        }, req.msg_context.stub_id)
    end
    if res.code == ErrorCode.None then
        context.roomid = res.roomid
    end

    return context.S2C(context.net_id, CmdCode["PBEnterRoomRspCmd"], res, req.msg_context.stub_id)
end

-- function Room.OnMemberEnter(res)
--     moon.info("OnMemberEnter uid", context.uid, res.member_data.mem_info.uid)
--     --local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
--     if res.member_data.mem_info.uid == context.uid then
--         context.roomid = res.roomid
--         moon.info("OnMemberEnter roomid", context.roomid, res.roomid)
--     end
--     context.S2C(context.net_id, CmdCode["PBEnterRoomSyncCmd"], res, 0)
-- end

function Room.PBExitRoomReqCmd(req)
    if not context.roomid then
        return context.S2C(context.net_id, CmdCode["PBExitRoomRspCmd"], {
            code = ErrorCode.RoomMemberNotFound,
            error = "你还未加入房间",
        }, req.msg_context.stub_id)
    end

    local res, err = clusterd.call(3999, "roommgr", "Roommgr.ExitRoom",
        { uid = context.uid, roomid = context.roomid, is_force = false })
    if err then
        moon.error(string.format("Roommgr.ExitRoom err:\n%s", json.pretty_encode(err)))
        return context.S2C(context.net_id, CmdCode["PBExitRoomRspCmd"], {
            code = ErrorCode.ServerInternalError,
            error = "system error",
        }, req.msg_context.stub_id)
    end
    if res.code == ErrorCode.None then
        -- 退出队伍频道
        local chat_ret = ChatLogic.LeaveRoomChannel(context.roomid, context.uid)
        if chat_ret.code ~= ErrorCode.None then
            moon.error(string.format("LeaveRoomChannel uid:%d, roomid:%d, code:%d, error:%s", context.uid, context
                .roomid, chat_ret.code, chat_ret.error))
        end
        -- 同步退出房间状态
        local update_user_attr = {}
        update_user_attr[ProtoEnum.UserAttrType.is_online] = UserAttrDef.ONLINE_STATE.ONLINE
        scripts.User.SetUserAttr(update_user_attr, true)

        context.roomid = nil
    end

    return context.S2C(context.net_id, CmdCode["PBExitRoomRspCmd"], {
        code = res.code,
        error = res.error or "",
        uid = req.msg.uid,
        roomid = req.msg.roomid
    }, req.msg_context.stub_id)
end

-- function Room.OnMemberExit(res)
--     --local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
--     if res.uid == context.uid then
--         context.roomid = nil -- body
--     end
--     context.S2C(context.net_id, CmdCode["PBExitRoomSyncCmd"], res, 0)
-- end

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

-- function Room.OnMemberKick(res)
--     if res.kick_uid == context.uid then
--         context.roomid = nil -- body
--     end
--     context.S2C(context.net_id, CmdCode["PBKickRoomSyncCmd"], res, 0)
-- end

function Room.PBInviteRoomReqCmd(req)
    if not context.roomid or context.roomid ~= req.msg.roomid then
        return context.S2C(context.net_id, CmdCode["PBInviteRoomRspCmd"], {
            code = ErrorCode.RoomNotFound,
            error = "不在目标房间内",
        }, req.msg_context.stub_id)
    end

    local res, err = clusterd.call(3999, "roommgr", "Roommgr.InviteMember", req.msg)
    if err then
        moon.err("Roommgr.InviteMember err:\n%s", json.pretty_encode(err))
        return context.S2C(context.net_id, CmdCode["PBInviteRoomRspCmd"], {
            code = ErrorCode.ServerInternalError,
            error = "system error",
        }, req.msg_context.stub_id)
    end
    -- 检查req.msg传递
    return context.S2C(context.net_id, CmdCode["PBInviteRoomRspCmd"], res, req.msg_context.stub_id)
end

function Room.OnInviteRoomSync(res)
    context.S2C(context.net_id, CmdCode["PBInviteRoomSyncCmd"], res, 0)
end

function Room.PBDealInviteRoomReqCmd(req)
    if context.roomid then
        return context.S2C(context.net_id, CmdCode["PBDealInviteRoomRspCmd"], {
            code = ErrorCode.RoomNotFound,
            error = "你已在房间中",
        }, req.msg_context.stub_id)
    end

    local brief_data = scripts.User.GetUsrRoomBriefData()
    if not brief_data or table.size(brief_data) <= 0 then
        return context.S2C(context.net_id, CmdCode["PBDealInviteRoomRspCmd"], {
            code = ErrorCode.ServerInternalError,
            error = "用户不存在",
        }, req.msg_context.stub_id)
    end
    local res, err = clusterd.call(3999, "roommgr", "Roommgr.DealInvite", {
        msg = req.msg,
        invite_info = brief_data,
    })
    if err then
        return context.S2C(context.net_id, CmdCode["PBDealInviteRoomRspCmd"], {
            code = ErrorCode.ServerInternalError,
            error = "system error",
        }, req.msg_context.stub_id)
    end

    return context.S2C(context.net_id, CmdCode["PBDealInviteRoomRspCmd"], res, req.msg_context.stub_id)
end

function Room.OnDealInviteRoomSync(res)
    context.S2C(context.net_id, CmdCode["PBDealInviteRoomSyncCmd"], res, 0)
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
    --
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
    if res.member_datas and res.member_datas[1] and res.member_datas[1].mem_info then
        if res.member_datas[1].mem_info.guild_id then
            moon.warn(string.format("Roommgr.GetRoomInfo guild_id:%d", res.member_datas[1].mem_info.guild_id))
        else
            moon.warn(string.format("Roommgr.GetRoomInfo not guild_id"))
        end
    end
    --print_r(res)
    --moon.info(string.format("Roommgr.GetRoomInfo res:\n%s", json.pretty_encode(res)))
    -- 返回查询结果
    return context.S2C(context.net_id, CmdCode["PBGetRoomInfoRspCmd"], res, req.msg_context.stub_id)
end

function Room.PBStartGameRoomReqCmd(req)
    if not context.roomid or context.roomid ~= req.msg.roomid then
        return context.S2C(context.net_id, CmdCode["PBStartGameRoomRspCmd"], {
            code = ErrorCode.RoomNotFound,
            error = "不在目标房间内"
        }, req.msg_context.stub_id)
    end

    local res, err = clusterd.call(3999, "roommgr", "Roommgr.StartGame", req.msg)
    if err then
        moon.error(string.format("Roommgr.StartGame err:\n%s", json.pretty_encode(err)))
        return context.S2C(context.net_id, CmdCode["PBStartGameRoomRspCmd"], {
            code = ErrorCode.ServerInternalError,
            error = "system error",
        }, req.msg_context.stub_id)
    end

    return context.S2C(context.net_id, CmdCode["PBStartGameRoomRspCmd"], res, req.msg_context.stub_id)
end

function Room.OnEnterDs(res)
    -- 加入DS广播
    moon.warn("OnEnterDs ", context.net_id, context.uid)
    context.S2C(context.net_id, CmdCode["PBEnterDsRoomSyncCmd"], res, 0)
end

function Room.PBCheckReturnRoomReqCmd(req)
    if not req.msg.uid or req.msg.uid ~= context.uid then
        return context.S2C(context.net_id, CmdCode["PBCheckReturnRoomRspCmd"], {
            code = ErrorCode.ParamInvalid,
            error = "uid is nil",
        }, req.msg_context.stub_id)
    end

    local res, err = clusterd.call(3999, "roommgr", "Roommgr.ReturnRoom", req.msg)
    if err then
        return context.S2C(context.net_id, CmdCode["PBCheckReturnRoomRspCmd"], {
            code = ErrorCode.ServerInternalError,
            error = "system error",
        }, req.msg_context.stub_id)
    end
    if res.code == ErrorCode.None then
        context.roomid = res.room_data.roomid
    end
    return context.S2C(context.net_id, CmdCode["PBCheckReturnRoomRspCmd"], res, req.msg_context.stub_id)
end

function Room.GameSettle(settle_info)
    moon.info(string.format("Room.GameSettle settle_info:\n%s", json.pretty_encode(settle_info)))
    -- 游戏结算
    local mail_id_cfg = CommonCfgDef.getConf("DungeonAwardEmailId")
    if not mail_id_cfg then
        moon.error("CommonCfgDef.getConf err")
        return
    end

    local bag_change_log = {}
    if settle_info.booty_bag then
        -- 获取战利品
        local item_list = {}
        for pos, itemdata in pairs(settle_info.booty_bag.items) do
            local item_id = itemdata.common_info.config_id
            if not item_list[item_id] then
                item_list[item_id] = {
                    id = item_id,
                    count = 0,
                    pos = 0,
                }
            end
            item_list[item_id].count = item_list[item_id].count + itemdata.common_info.item_count
        end
        if table.size(item_list) > 0 then
            local stack_items, unstack_items, deal_coins = {}, {}, {}
            local ok = ItemDefine.GetItemDataFromIdCount(item_list, {}, stack_items, unstack_items, deal_coins)
            if not ok then
                moon.error(string.format("GameSettle GetItemDataFromIdCount err:\n%s", json.pretty_encode(item_list)))
                return
            end

            local bag_code = scripts.Bag.CheckEmptyEnough(BagDef.BagType.Cangku, item_list, 0)
            if bag_code ~= ErrorCode.None then
                -- 仓库已满 发送邮件
                local item_datas = {}
                for _, item_data in pairs(stack_items) do
                    table.insert(item_datas, item_data)
                end
                for _, item_data in pairs(unstack_items) do
                    table.insert(item_datas, item_data)
                end
                local mail_ret = scripts.Mail.RecvImmediateMail(mail_id_cfg.value, {}, item_datas, {})
                if mail_ret ~= ErrorCode.None then
                    moon.error(string.format("GameSettle RecvImmediateMail err:\n%s", json.pretty_encode(item_datas)))
                    return
                end
            else
                -- 添加道具
                if table.size(stack_items) + table.size(unstack_items) > 0 then
                    bag_code = scripts.Bag.AddItems(BagDef.BagType.Cangku, stack_items, unstack_items, bag_change_log)
                    if bag_code ~= ErrorCode.None then
                        scripts.Bag.RollBackWithChange(bag_change_log)
                        moon.error(string.format("GameSettle AddItems stack_items err:\n%s",
                            json.pretty_encode(stack_items)))
                        moon.error(string.format("GameSettle AddItems unstack_items err:\n%s",
                            json.pretty_encode(unstack_items)))
                        return
                    end
                end
            end
        end
    end

    if settle_info.consume_bag then
        -- 同步消耗品背包
        local sync_baginfo = {
            capacity = 0,
            items = {}
        }
        local capacitys = scripts.Bag.GetBagCapacity({ BagDef.BagType.Consume })
        if capacitys and capacitys[BagDef.BagType.Consume] then
            sync_baginfo.capacity = capacitys[BagDef.BagType.Consume]
        end
        for pos, itemdata in pairs(settle_info.consume_bag.items) do
            if itemdata and itemdata.common_info and itemdata.common_info.config_id then
                local itype = ItemDefine.GetItemType(itemdata.common_info.config_id)
                local item_type = 0
                local item_cfg = GameCfg.Item[itemdata.common_info.config_id]
                if item_cfg then
                    item_type = item_cfg.type1
                end
                sync_baginfo.items[pos] = ItemDef.newItemDataFromData(itemdata, itype, item_type)
            end
        end

        local errcode = scripts.Bag.SyncBagInfo(BagDef.BagType.Consume, sync_baginfo, bag_change_log)
        if errcode ~= ErrorCode.None then
            scripts.Bag.RollBackWithChange(bag_change_log)
            moon.error(string.format("GameSettle SyncBagInfo err:\n%s", json.pretty_encode(sync_baginfo)))
            return
        end
    end

    if table.size(bag_change_log) > 0 then
        scripts.Bag.SaveAndLog(bag_change_log, ItemDef.ChangeReason.BattleSettle)
    end

    if settle_info.account_experience and settle_info.account_experience > 0 then
        -- 增加账户经验
        scripts.User.AddAccountExp(settle_info.account_experience)
    end

    if settle_info.game_role_exp and table.size(settle_info.game_role_exp) > 0 then
        -- 增加角色经验
        local change_roles = {}
        for _, role_exp in pairs(settle_info.game_role_exp) do
            if role_exp.roleid and role_exp.roleid > 0
                and role_exp.add_role_exp and role_exp.add_role_exp > 0 then
                local err, new_exp = scripts.Role.GameAddExp(role_exp.roleid, role_exp.add_role_exp)
                if err == ErrorCode.None then
                    change_roles[role_exp.roleid] = "UpLv"
                end
            end
        end
        if table.size(change_roles) > 0 then
            scripts.Role.SaveAndLog(change_roles)
        end
    end

    if settle_info.grade_id and settle_info.change_score then
        -- 变更段位积分
        scripts.Grade.ChangeScore(settle_info.grade_id, settle_info.change_score)
    end

    if settle_info.reward_boxs and table.size(settle_info.reward_boxs) > 0 then
        local box_list = {}
        for _, item_simple in pairs(settle_info.reward_boxs) do
            local item_id = item_simple.config_id
            if not box_list[item_id] then
                box_list[item_id] = {
                    id = item_id,
                    count = 0,
                    pos = 0,
                }
            end
            box_list[item_id].count = box_list[item_id].count + item_simple.item_count
        end
        if table.size(box_list) > 0 then
            local stack_items, unstack_items, deal_coins = {}, {}, {}
            local ok = ItemDefine.GetItemDataFromIdCount(box_list, {}, stack_items, unstack_items, deal_coins)
            if not ok then
                moon.error(string.format("GameSettle GetItemDataFromIdCount err:\n%s", json.pretty_encode(box_list)))
                return
            end

            local bag_code = scripts.Bag.CheckEmptyEnough(BagDef.BagType.Cangku, box_list, 0)
            if bag_code ~= ErrorCode.None then
                -- 仓库已满 发送邮件
                local item_datas = {}
                for _, item_data in pairs(stack_items) do
                    table.insert(item_datas, item_data)
                end
                for _, item_data in pairs(unstack_items) do
                    table.insert(item_datas, item_data)
                end
                local mail_ret = scripts.Mail.RecvImmediateMail(mail_id_cfg.value, {}, item_datas, {})
                if mail_ret ~= ErrorCode.None then
                    moon.error(string.format("GameSettle RecvImmediateMail err:\n%s", json.pretty_encode(item_datas)))
                    return
                end
            else
                -- 添加道具
                if table.size(stack_items) + table.size(unstack_items) > 0 then
                    bag_code = scripts.Bag.AddItems(BagDef.BagType.Cangku, stack_items, unstack_items, bag_change_log)
                    if bag_code ~= ErrorCode.None then
                        scripts.Bag.RollBackWithChange(bag_change_log)
                        moon.error(string.format("GameSettle AddItems stack_items err:\n%s",
                            json.pretty_encode(stack_items)))
                        moon.error(string.format("GameSettle AddItems unstack_items err:\n%s",
                            json.pretty_encode(unstack_items)))
                        return
                    end
                end
            end
        end
    end
end

function Room.GameReturnItems(return_info)
    local mail_id_cfg = CommonCfgDef.getConf("DungeonAwardEmailId")
    if not mail_id_cfg then
        moon.error("CommonCfgDef.getConf err")
        return
    end

    -- 发送邮件
    local item_datas = {}
    for _, item_data in pairs(return_info) do
        table.insert(item_datas, item_data)
    end

    local mail_ret = scripts.Mail.RecvImmediateMail(mail_id_cfg.value, {}, item_datas, {})
    if mail_ret ~= ErrorCode.None then
        moon.error(string.format("GameReturnItems mail_ret err:\n%s", json.pretty_encode(item_datas)))
    end
end

return Room
