local moon = require("moon")
local socket = require("moon.socket")
local common = require("common")
local CmdCode = common.CmdCode
local GameCfg = common.GameCfg --游戏配置
local ErrorCode = common.ErrorCode

---@type roommgr_context
local context = ...

local listenfd

---@class Roommgr
local Roommgr = {}

function Roommgr.Init()
    context.rooms = {} -- 全量房间数据存储
    return true
end

-- 生成唯一房间ID（保留原逻辑）
local function generate_roomid()
    context.room_nowid = context.room_nowid + 1
    return context.room_nowid
end

function Roommgr.CreateRoom(req)
    if context.uid_roomid[req.msg.uid] then
        return { code = ErrorCode.RoomAlreadyInRoom, error = "用户已经在房间中", roomid = context.uid_roomid[req.msg.uid] }
    end

    local roomid = generate_roomid()
    local room = {
        roomid = roomid,
        isopen = req.msg.isopen,
        needpwd = req.msg.needpwd,
        pwd = req.msg.pwd,
        chapter = req.msg.chapter,
        difficulty = req.msg.difficulty,
        master_id = req.msg.uid,
        master_name = req.self_info.nick_name,
        players = {},
        apply_list = {},
    }
    table.insert(room.players, { is_ready = 1, mem_info = req.self_info })

    context.rooms[roomid] = room
    context.uid_roomid[req.msg.uid] = roomid
    return { code = ErrorCode.None, error = "创建房间成功", roomid = roomid }
end

function Roommgr.SearchRooms(req)
    local result = {}

    if req.roomid then
        local room = context.rooms[req.roomid]
        if room and room.isopen == 1 then
            table.insert(result, {
                roomid = room.roomid,
                chapter = room.chapter,
                difficulty = room.difficulty,
                playercnt = #room.players,
                master_id = room.master_id,
                master_name = room.master_name,
                needpwd = room.needpwd
            })
        end
    end

    return { code = ErrorCode.None, error = "搜索完成", search_data = result }
end

function Roommgr.ModRoom(req)
    local room = context.rooms[req.roomid]
    -- 房间不存在
    if not room then
        return { code = ErrorCode.RoomNotFound, error = "房间不存在" }
    end

    -- 验证房主权限
    if room.master_id ~= req.uid then
        return {
            code = ErrorCode.RoomPermissionDenied,
            error = "无修改权限",
            isopen = room.isopen,
            needpwd = room.needpwd,
            pwd = room.pwd,
            chapter = room.chapter,
            difficulty = room.difficulty
        }
    end

    room.isopen = req.isopen or room.isopen
    room.needpwd = req.needpwd or room.needpwd
    room.pwd = req.pwd or room.pwd
    room.chapter = req.chapter or room.chapter
    room.difficulty = req.difficulty or room.difficulty

    local notify_uids = {}
    for _, player in ipairs(room.players) do
        if player.mem_info.uid ~= req.uid then
            table.insert(notify_uids, player.uid)
        end
    end
    context.send_users(notify_uids, {}, "Room.OnRoomInfoSync", {
        roomid = room.roomid,
        isopen = room.isopen,
        needpwd = room.needpwd,
        pwd = room.pwd,
        chapter = room.chapter,
        difficulty = room.difficulty
    })

    return {
        code = ErrorCode.None,
        error = "修改完成",
        isopen = room.isopen,
        needpwd = room.needpwd,
        pwd = room.pwd,
        chapter = room.chapter,
        difficulty = room.difficulty
    }
end

function Roommgr.ApplyToRoom(req)
    local room = context.rooms[req.msg.roomid]
    if not room then
        return { code = ErrorCode.RoomNotFound, error = "房间不存在", roomid = req.msg.roomid }
    end

    -- 检查是否已在房间
    if context.uid_roomid[req.msg.uid] then
        return { code = ErrorCode.RoomAlreadyInRoom, error = "已在其他房间", roomid = context.uid_roomid[req.msg.uid] }
    end

    -- 检查重复申请
    for _, apply in ipairs(room.apply_list) do
        if apply.uid == req.msg.uid then
            return { code = ErrorCode.RoomDuplicateApply, error = "已提交过申请", roomid = req.msg.roomid }
        end
    end

    -- 记录申请信息
    table.insert(room.apply_list, {
        uid = req.msg.uid,
        apply_info = req.apply_info,
        apply_time = moon.time()
    })

    -- 通知房主有新申请
    context.send_user(room.master_id, "Room.OnApplyNotify", {
        roomid = req.msg.roomid,
        apply_info = req.apply_info
    })

    return { code = ErrorCode.None, error = "申请已提交", roomid = req.msg.roomid }
end

function Roommgr.DealApply(req)
    local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
    local room = context.rooms[req.roomid]
    if not room then
        return { code = ErrorCode.RoomNotFound, error = "房间不存在" }
    end

    -- 验证房主身份
    if room.master_id ~= req.master_uid then
        return { code = ErrorCode.RoomPermissionDenied, error = "无操作权限" }
    end

    -- 查找对应申请
    local apply_index = nil
    for i, apply in ipairs(room.apply_list) do
        if apply.uid == req.deal_uid then
            apply_index = i
            break
        end
    end

    if not apply_index then
        return { code = ErrorCode.RoomApplyNotFound, error = "申请不存在" }
    end

    local apply_data = table.remove(room.apply_list, apply_index)

    -- 处理申请
    if req.deal_op == 1 then -- 同意申请
        -- 检查是否已在其他房间
        if context.uid_roomid[req.deal_uid] then
            return { code = ErrorCode.RoomAlreadyInRoom, error = "玩家已在其他房间" }
        end

        -- 添加玩家到房间
        table.insert(room.players, { is_ready = 0, mem_info = apply_data.apply_info })
        context.uid_roomid[req.deal_uid] = req.roomid

        -- 广播新成员加入
        local notify_uids = {}
        for _, player in ipairs(room.players) do
            table.insert(notify_uids, player.mem_info.uid)
        end
        context.send_users(notify_uids, {}, "Room.OnMemberEnter", {
            roomid = req.roomid,
            member_data = {
                seat_idx = #room.players,
                is_ready = 0,
                mem_info = apply_data.apply_info
            }
        })
    end

    local res = { code = ErrorCode.None, error = "操作成功", deal_uid = req.deal_uid, deal_op = req.deal_op }
    return res
end

function Roommgr.ExitRoom(req)
    local room = context.rooms[req.roomid]
    if not room then
        return { code = ErrorCode.RoomNotFound, error = "房间不存在" }
    end

    -- 验证玩家是否在房间内
    local member_index = nil
    for i, member in ipairs(room.players) do
        if member.mem_info.uid == req.uid then
            member_index = i
            break
        end
    end
    if not member_index then
        return { code = ErrorCode.RoomMemberNotFound, error = "不在该房间内" }
    end

    -- 房主退出特殊处理
    if req.uid == room.master_id then
        -- 转移房主给下一个玩家或解散房间
        if #room.players > 1 then
            room.master_id = room.players[2].mem_info.uid
            room.master_name = room.players[2].mem_info.nick_name
        else
            context.rooms[req.roomid] = nil
        end
    end

    -- 移除玩家数据
    table.remove(room.players, member_index)
    context.uid_roomid[req.uid] = nil

    -- 广播玩家退出
    local notify_uids = {}
    for _, player in ipairs(room.players) do
        table.insert(notify_uids, player.mem_info.uid)
    end
    context.send_users(notify_uids, {}, "Room.OnMemberExit", {
        uid = req.uid,
        roomid = req.roomid,
    })

    return { code = ErrorCode.None, error = "退出成功", uid = req.uid, roomid = req.roomid }
end

function Roommgr.KickMember(req)
    local room = context.rooms[req.roomid]
    if not room then
        return { code = ErrorCode.RoomNotFound, error = "房间不存在" }
    end

    -- 验证房主身份
    if room.master_id ~= req.self_uid then
        return { code = ErrorCode.RoomPermissionDenied, error = "无踢人权限" }
    end

    -- 查找被踢玩家
    local kick_index = nil
    for i, member in ipairs(room.players) do
        if member.mem_info.uid == req.kick_uid then
            kick_index = i
            break
        end
    end

    if not kick_index then
        return { code = ErrorCode.RoomMemberNotFound, error = "目标玩家不在房间" }
    end

    -- 移除玩家
    table.remove(room.players, kick_index)
    context.uid_roomid[req.kick_uid] = nil

    -- 广播踢人通知
    local notify_uids = {}
    for _, player in ipairs(room.players) do
        table.insert(notify_uids, player.mem_info.uid)
    end
    context.send_users(notify_uids, {}, "Room.OnMemberKick", {
        roomid = req.roomid,
        kick_uid = req.kick_uid,
    })

    return { code = ErrorCode.None, error = "踢出成功", roomid = req.roomid, kick_uid = req.kick_uid }
end

function Roommgr.UpdateReadyStatus(req)
    local room = context.rooms[req.roomid]
    if not room then
        return { code = ErrorCode.RoomNotFound, error = "房间不存在" }
    end

    -- 查找玩家在房间中的位置
    local member_index = nil
    for i, member in ipairs(room.players) do
        if member.mem_info.uid == req.uid then
            member_index = i
            break
        end
    end

    if not member_index then
        return { code = ErrorCode.RoomMemberNotFound, error = "玩家不在房间内" }
    end

    -- 更新准备状态（1-准备 2-取消准备）
    room.players[member_index].is_ready = req.is_ready

    -- 广播状态更新
    local notify_uids = {}
    for _, player in ipairs(room.players) do
        table.insert(notify_uids, player.mem_info.uid)
    end
    context.send_users(notify_uids, {}, "Room.OnReadyStatusUpdate", {
        uid = req.uid,
        roomid = req.roomid,
        is_ready = req.is_ready,
    })

    return { code = ErrorCode.None, error = "更新准备状态", uid = req.uid, roomid = req.roomid, is_ready = req.is_ready }
end

function Roommgr.GetRoomInfo(req)
    local room = context.rooms[req.roomid]
    if not room then
        return { code = ErrorCode.RoomNotFound, error = "房间不存在" }
    end

    -- 验证请求者是否在房间内
    local in_room = false
    for _, member in ipairs(room.players) do
        if member.mem_info.uid == req.uid then
            in_room = true
            break
        end
    end

    if not in_room then
        return { code = ErrorCode.RoomPermissionDenied, error = "无查看权限" }
    end

    -- 构造房间信息返回结构
    local res = {
        code = ErrorCode.None,
        error = "房间信息查询成功",
        room_data = {
            roomid = room.roomid,
            isopen = room.isopen,
            needpwd = room.needpwd,
            pwd = room.pwd,
            chapter = room.chapter,
            difficulty = room.difficulty
        },
        member_datas = {}
    }

    -- 填充成员数据
    for i, member in ipairs(room.players) do
        table.insert(res.member_datas, {
            seat_idx = i,
            is_ready = member.is_ready,
            mem_info = member.mem_info
        })
    end

    return res
end

function Roommgr.Start()
    return true
end

function Roommgr.Shutdown()
    -- for _, n in pairs(context.rooms) do
    --     socket.close(n.fd)
    -- end
    if listenfd then
        socket.close(listenfd)
    end
    moon.quit()
    return true
end

return Roommgr
