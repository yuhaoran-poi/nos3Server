local moon = require("moon")
local socket = require("moon.socket")
local common = require("common")
local CmdCode = common.CmdCode
local GameCfg = common.GameCfg --游戏配置
local Database = common.Database
local ErrorCode = common.ErrorCode
local lock = require("moon.queue")()
local httpc = require("moon.http.client")
local json = require("json")
local crypt = require("crypt")
local protocol = require("common.protocol_pb")
local RoomDef = require("common.def.RoomDef")
local jencode = json.encode
local jdecode = json.decode

---@type roommgr_context
local context = ...

local listenfd
local maxplayers = 10

---@class Roommgr
local Roommgr = {}

function Roommgr.Init()
    context.rooms = {}          -- 全量房间数据存储
    context.waitds_roomids = {} -- 等待中房间ID列表
    context.addr_db_server = moon.queryservice("db_server")

    -- 新增定时器轮询
    moon.async(function()
        while true do
            moon.sleep(1000) -- 每秒检查一次
            local allocated_rooms, fail_rooms = Roommgr.CheckWaitDSRooms()
            Roommgr.NotifyDsRooms(allocated_rooms, fail_rooms)
        end
    end)
    return true
end

function Roommgr.CheckWaitDSRooms()
    local now = moon.time()
    local scope <close> = lock()

    local function allocate_cb(rsp_data)
        if not rsp_data or not rsp_data.error or rsp_data.error ~= "success" then
            return false
        end

        if not rsp_data.allocationresponse then
            return false
        end

        local ret = {}
        if not rsp_data.allocationresponse.address
            or not rsp_data.allocationresponse.gameServerName
            or not rsp_data.allocationresponse.nodeName then
            return false
        end

        ret.ds_ip = rsp_data.allocationresponse.address
        ret.region = rsp_data.allocationresponse.gameServerName
        ret.serverssion = rsp_data.allocationresponse.nodeName

        return true, ret
    end
    
    local function query_cb(rsp_data)
        if not rsp_data or not rsp_data.gameservers or #rsp_data.gameservers ~= 1 then
            return false
        end

        local gameserver = rsp_data.gameservers[1]
        if not gameserver.labels
            or not gameserver.labels["agones.dev/sdk-loadmap"]
            or gameserver.labels["agones.dev/sdk-loadmap"] ~= "true"
            or not gameserver.labels["agones.dev/sdk-clb_address"] then
            return false
        end

        return true, gameserver.labels["agones.dev/sdk-clb_address"]
    end
    
    for k, v in pairs(context.waitds_roomids) do
        if now - v.lasttime >= 10 then
            v.lasttime = now
            
            if v.status == 0 then
                local response = httpc.post(context.conf.allocate_url, v.allocate_data)
                --
                print_r(response)
                local rsp_data = json.decode(response.body)
                local success, ret = allocate_cb(rsp_data)
                if not success or not ret then
                    v.failcnt = v.failcnt + 1
                else
                    v.ds_ip = ret.ds_ip
                    v.region = ret.region
                    v.serverssion = ret.serverssion

                    v.status = 1
                    v.failcnt = 0
                end
            elseif v.status == 1 then
                local get_url = context.conf.query_url .. "?name=" .. v.region
                print_r(get_url)
                local response = httpc.get(get_url)
                --
                print_r(response)
                local rsp_data = json.decode(response.body)
                local success, ret = query_cb(rsp_data)
                if not success or not ret then
                    v.failcnt = v.failcnt + 1
                else
                    v.ds_address = ret
                    
                    v.status = 2
                    v.failcnt = 0
                end
            else
                v.failcnt = v.failcnt + 1
            end
        end
    end

    local allocated_rooms = {}
    local fail_rooms = {}
    for k, v in pairs(context.waitds_roomids) do
        
        if v.status == 2 then
            allocated_rooms[k] = v
        elseif v.failcnt > 5 then
            table.insert(fail_rooms, k)
        end
    end
    for roomid, _ in pairs(allocated_rooms) do
        context.waitds_roomids[roomid] = nil
    end
    for roomid, _ in pairs(fail_rooms) do
        context.waitds_roomids[roomid] = nil
    end
    --print("allocated_rooms")
    --print_r(allocated_rooms)

    return allocated_rooms, fail_rooms
end

function Roommgr.NotifyDsRooms(allocated_rooms, fail_rooms)
    for roomid, allocate_info in pairs(allocated_rooms) do
        
        local room = context.rooms[roomid]
        if room then
            local notify_uids = {}
            for _, player in pairs(room.players) do
                table.insert(notify_uids, player.mem_info.uid)
            end
            context.send_users(notify_uids, {}, "Room.OnEnterDs", {
                roomid = roomid,
                ds_address = allocate_info.ds_address,
                ds_ip = allocate_info.ds_ip,
            })
        end
    end

    for roomid, fail_info in pairs(fail_rooms) do
        local room = context.rooms[roomid]
        if room then
            local notify_uids = {}
            for _, player in pairs(room.players) do
                table.insert(notify_uids, player.mem_info.uid)
            end
            context.send_users(notify_uids, {}, "Room.OnEnterDs", {
                roomid = roomid,
                ds_address = fail_info.ds_address,
                ds_ip = fail_info.ds_ip,
            })

            room.room_data.state = 0
            room.room_data.isopen = 0
        end
    end
end

function Roommgr.AddWaitDSRooms(roomid, allocate_data)
    local scope <close> = lock()

    context.waitds_roomids[roomid] = {
        status = 0,
        lasttime = 0,
        failcnt = 0,
        ds_ip = "",
        region = "",
        serverssion = "",
        ds_address = "",
        allocate_data = allocate_data,
    }
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
    --moon.info(string.format("Roommgr.CreateRoom self_info:\n%s", json.pretty_encode(req.self_info)))
    local room = RoomDef.newRoomWholeInfo()
    local roomid = generate_roomid()
    -- local roomid = 10001
    room.room_data.roomid = roomid
    room.room_data.isopen = req.msg.isopen
    room.room_data.needpwd = req.msg.needpwd
    room.room_data.pwd = req.msg.pwd
    room.room_data.chapter = req.msg.chapter
    room.room_data.difficulty = req.msg.difficulty
    room.room_data.describe = req.msg.describe
    room.room_data.master_id = req.msg.uid
    room.master_id = req.msg.uid
    room.master_name = req.self_info.nick_name
    table.insert(room.players, { is_ready = 1, mem_info = req.self_info })
    -- moon.info(string.format("Roommgr.CreateRoom mem_info:\n%s", json.pretty_encode(room.players[1].mem_info)))
    
    local room_tags = {
        isopen = room.room_data.isopen,
        chapter = room.room_data.chapter,
        difficulty = room.room_data.difficulty,
    }
    local redis_data = table.copy(room.room_data, true)
    redis_data.pwd = nil
    redis_data.playercnt = #room.players
    redis_data.master_id = room.master_id
    redis_data.master_name = room.master_name
    --
    Database.upsert_room(context.addr_db_server, roomid, room_tags, redis_data)

    context.rooms[roomid] = room
    context.uid_roomid[req.msg.uid] = roomid
    return { code = ErrorCode.None, error = "创建房间成功", roomid = roomid }
end

function Roommgr.SearchRooms(req)
    local result = {}

    if req.roomid then
        local room = context.rooms[req.roomid]
        if room then
            local search_data = RoomDef.newRoomSearchInfo()
            search_data.roomid = room.room_data.roomid
            search_data.chapter = room.room_data.chapter
            search_data.difficulty = room.room_data.difficulty
            search_data.playercnt = #room.players
            search_data.master_id = room.master_id
            search_data.master_name = room.master_name
            search_data.isopen = room.room_data.isopen
            search_data.needpwd = room.room_data.needpwd
            search_data.describe = room.room_data.describe
            table.insert(result, search_data)
        end
    end

    return { code = ErrorCode.None, error = "搜索完成", roomid = req.roomid, search_data = result }
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
            isopen = room.room_data.isopen,
            needpwd = room.room_data.needpwd,
            pwd = room.room_data.pwd,
            chapter = room.room_data.chapter,
            difficulty = room.room_data.difficulty,
            describe = room.room_data.describe,
        }
    end

    room.room_data.isopen = req.isopen or room.room_data.isopen
    room.room_data.needpwd = req.needpwd or room.room_data.needpwd
    room.room_data.pwd = req.pwd or room.room_data.pwd
    room.room_data.chapter = req.chapter or room.room_data.chapter
    room.room_data.difficulty = req.difficulty or room.room_data.difficulty
    room.room_data.describe = req.describe or room.room_data.describe

    local room_tags = {
        isopen = room.room_data.isopen,
        chapter = room.room_data.chapter,
        difficulty = room.room_data.difficulty,
    }
    local redis_data = table.copy(room.room_data, true)
    redis_data.pwd = nil
    redis_data.playercnt = #room.players
    redis_data.master_id = room.master_id
    redis_data.master_name = room.master_name
    Database.upsert_room(context.addr_db_server, room.room_data.roomid, room_tags, redis_data)

    local notify_uids = {}
    for _, player in pairs(room.players) do
        -- if player.mem_info.uid ~= req.uid then
        --     table.insert(notify_uids, player.mem_info.uid)
        -- end
        table.insert(notify_uids, player.mem_info.uid)
    end
    
    context.send_users(notify_uids, {}, "Room.OnRoomInfoSync", {
        roomid = room.room_data.roomid,
        sync_info = {
            room_data = room.room_data,
        },
    })

    return {
        code = ErrorCode.None,
        error = "修改完成",
        isopen = room.room_data.isopen,
        needpwd = room.room_data.needpwd,
        pwd = room.room_data.pwd,
        chapter = room.room_data.chapter,
        difficulty = room.room_data.difficulty
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

    -- 检查是否可以申请
    if room.room_data.isopen == 0 then
        return { code = ErrorCode.RoomNotOpen, error = "房间未开放" }
    end
    if room.room_data.needpwd == 1 then
        return { code = ErrorCode.RoomPwdError, error = "密码错误" }
    end

    -- 检查重复申请
    for _, apply in pairs(room.apply_list) do
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
    local notify_uids = {}
    table.insert(notify_uids, room.master_id)
    context.send_users(notify_uids, {}, "Room.OnRoomInfoSync", {
        roomid = room.room_data.roomid,
        sync_info = {
            apply_list = room.apply_list,
        },
    })

    return { code = ErrorCode.None, error = "申请已提交", roomid = req.msg.roomid }
end

function Roommgr.DealApply(req)
    local room = context.rooms[req.roomid]
    if not room then
        return { code = ErrorCode.RoomNotFound, error = "房间不存在" }
    end

    -- 检查是否可以申请
    if room.room_data.isopen == 0 or room.room_data.needpwd == 1 then
        return { code = ErrorCode.RoomPermissionDenied, error = "无操作权限" }
    end

    -- 验证房主身份
    if room.master_id ~= req.master_uid then
        return { code = ErrorCode.RoomPermissionDenied, error = "无操作权限" }
    end

    -- 查找对应申请
    local apply_index = nil
    for i, apply in pairs(room.apply_list) do
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

        local room_tags = {
            isopen = room.room_data.isopen,
            chapter = room.room_data.chapter,
            difficulty = room.room_data.difficulty,
        }
        local redis_data = table.copy(room.room_data, true)
        redis_data.pwd = nil
        redis_data.playercnt = #room.players
        redis_data.master_id = room.master_id
        redis_data.master_name = room.master_name
        Database.upsert_room(context.addr_db_server, room.room_data.roomid, room_tags, redis_data)

        -- 广播新成员加入
        local notify_uids = {}
        for _, player in pairs(room.players) do
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

function Roommgr.EnterRoom(req)
    --local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
    local room = context.rooms[req.msg.roomid]
    if not room then
        return { code = ErrorCode.RoomNotFound, error = "房间不存在" }
    end

    -- 检查是否已在房间 
    if context.uid_roomid[req.msg.uid] then
        return { code = ErrorCode.RoomAlreadyInRoom, error = "已在其他房间", roomid = context.uid_roomid[req.msg.uid] }
    end

    -- 检查是否可以直接加入
    if room.room_data.isopen == 0 then
        return { code = ErrorCode.RoomNotOpen, error = "房间未开放" }
    end

    -- 检查密码
    if room.room_data.needpwd == 1 and room.room_data.pwd ~= req.msg.pwd then
        return { code = ErrorCode.RoomPwdError, error = "密码错误" }
    end

    -- 添加玩家到房间
    table.insert(room.players, { is_ready = 0, mem_info = req.mem_info })
    context.uid_roomid[req.msg.uid] = req.roomid

    local room_tags = {
        isopen = room.room_data.isopen,
        chapter = room.room_data.chapter,
        difficulty = room.room_data.difficulty,
    }
    local redis_data = table.copy(room.room_data, true)
    redis_data.pwd = nil
    redis_data.playercnt = #room.players
    redis_data.master_id = room.master_id
    redis_data.master_name = room.master_name
    Database.upsert_room(context.addr_db_server, room.room_data.roomid, room_tags, redis_data)

    -- 广播新成员加入
    local notify_uids = {}
    for _, player in pairs(room.players) do
        table.insert(notify_uids, player.mem_info.uid)
    end
    context.send_users(notify_uids, {}, "Room.OnMemberEnter", {
        roomid = room.room_data.roomid,
        member_data = {
            seat_idx = #room.players,
            is_ready = 0,
            mem_info = req.mem_info
        }
    })

    return { code = ErrorCode.None, error = "操作成功", uid = req.msg.uid, roomid = req.msg.roomid }
end

function Roommgr.ExitRoom(req)
    local room = context.rooms[req.roomid]
    if not room then
        return { code = ErrorCode.RoomNotFound, error = "房间不存在" }
    end

    -- 验证玩家是否在房间内
    local member_index = nil
    for i, member in pairs(room.players) do
        if member.mem_info.uid == req.uid then
            member_index = i
            break
        end
    end
    if not member_index then
        return { code = ErrorCode.RoomMemberNotFound, error = "不在该房间内" }
    end

    -- 移除玩家数据
    table.remove(room.players, member_index)
    context.uid_roomid[req.uid] = nil

    local room_tags = {
        isopen = room.room_data.isopen,
        chapter = room.room_data.chapter,
        difficulty = room.room_data.difficulty,
    }
    local redis_data = table.copy(room.room_data, true)
    redis_data.pwd = nil
    redis_data.playercnt = #room.players
    redis_data.master_id = room.master_id
    redis_data.master_name = room.master_name
    Database.upsert_room(context.addr_db_server, room.room_data.roomid, room_tags, redis_data)

    -- 广播玩家退出
    local notify_uids = {}
    for _, player in pairs(room.players) do
        table.insert(notify_uids, player.mem_info.uid)
    end
    context.send_users(notify_uids, {}, "Room.OnMemberExit", {
        uid = req.uid,
        roomid = req.roomid,
    })

    -- 房主退出特殊处理
    if req.uid == room.master_id then
        -- 转移房主给下一个玩家或解散房间
        if #room.players > 0 then
            room.room_data.master_id = room.players[1].mem_info.uid
            room.master_id = room.players[1].mem_info.uid
            room.master_name = room.players[1].mem_info.nick_name
        else
            context.rooms[req.roomid] = nil
            local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
            Database.delete_room(context.addr_db_server, req.roomid)
        end
    end

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
    for i, member in pairs(room.players) do
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
    for _, player in pairs(room.players) do
        table.insert(notify_uids, player.mem_info.uid)
    end
    context.send_users(notify_uids, {}, "Room.OnMemberKick", {
        roomid = req.roomid,
        kick_uid = req.kick_uid,
    })

    return { code = ErrorCode.None, error = "踢出成功", roomid = req.roomid, kick_uid = req.kick_uid }
end

-- 新增邀请功能
function Roommgr.InviteMember(req)
    local room = context.rooms[req.roomid]
    if not room then
        return { code = ErrorCode.RoomNotFound, error = "房间不存在" }
    end

    -- 查找玩家在房间中的位置
    local self_index, invite_index = nil, nil
    local mem_name = ""
    for i, member in pairs(room.players) do
        if member.mem_info.uid == req.uid then
            self_index = i
            mem_name = member.mem_info.nick_name
        end
        if member.mem_info.uid == req.invite_uid then
            invite_index = i
        end
    end
    if not self_index then
        return { code = ErrorCode.RoomMemberNotFound, error = "自己不在房间内" }
    end
    if invite_index then
        return { code = ErrorCode.RoomMemberNotFound, error = "玩家已在房间内" }
    end

    -- 记录申请信息
    local had_invite = false
    for _, invite in pairs(room.invite_list) do
        if invite.invite_uid == req.invite_uid then
            invite.mem_uid = req.uid
            had_invite = true
            break
        end
    end
    if not had_invite then
        table.insert(room.invite_list, {
            mem_uid = req.uid,
            invite_uid = req.invite_uid,
            invite_time = moon.time()
        })
    end

    -- 通知被邀请方
    local notify_uids = {}
    table.insert(notify_uids, req.invite_uid)
    context.send_users(notify_uids, {}, "Room.OnInviteRoomSync", {
        roomid = room.room_data.roomid,
        mem_uid = req.invite_uid,
        mem_name = req.invite_name,
        room_info = room.room_data,
    })

    return { code = ErrorCode.None, error = "邀请已提交", uid = req.uid, roomid = req.roomid, invite_uid = req.invite_uid }
end

function Roommgr.DealInvite(req)
    local room = context.rooms[req.msg.roomid]
    if not room then
        return { code = ErrorCode.RoomNotFound, error = "房间不存在" }
    end

    -- 检查是否已在其他房间
    if context.uid_roomid[req.msg.uid] then
        return { code = ErrorCode.RoomAlreadyInRoom, error = "你已在其他房间" }
    end

    -- 查找对应申请
    local invite_index = nil
    for i, invite in pairs(room.invite_list) do
        if invite.invite_uid == req.msg.uid then
            invite_index = i
            break
        end
    end
    
    if not invite_index then
        return { code = ErrorCode.RoomInviteNotFound, error = "邀请不存在" }
    end
    local invite_data = table.remove(room.invite_list, invite_index)

    -- 处理邀请
    if req.msg.deal_op == 1 then -- 同意邀请
        if table.size(room.players) >= maxplayers then
            return { code = ErrorCode.RoomFull, error = "房间已满" }
        end
        -- 添加玩家到房间
        table.insert(room.players, { is_ready = 0, mem_info = req.invite_info })
        context.uid_roomid[req.msg.uid] = req.roomid

        local room_tags = {
            isopen = room.room_data.isopen,
            chapter = room.room_data.chapter,
            difficulty = room.room_data.difficulty,
        }
        local redis_data = table.copy(room.room_data, true)
        redis_data.pwd = nil
        redis_data.playercnt = #room.players
        redis_data.master_id = room.master_id
        redis_data.master_name = room.master_name
        Database.upsert_room(context.addr_db_server, room.room_data.roomid, room_tags, redis_data)

        -- 广播新成员加入
        local notify_uids = {}
        for _, player in pairs(room.players) do
            table.insert(notify_uids, player.mem_info.uid)
        end
        context.send_users(notify_uids, {}, "Room.OnMemberEnter", {
            roomid = req.msg.roomid,
            member_data = {
                seat_idx = #room.players,
                is_ready = 0,
                mem_info = req.invite_info
            }
        })
    else
        local notify_uids = {}
        table.insert(notify_uids, invite_data.mem_info)
        context.send_users(notify_uids, {}, "Room.OnDealInviteRoomSync", {
            invite_uid = invite_data.inviter_uid,
            deal_op = req.msg.deal_op,
        })
    end

    return { code = ErrorCode.None, error = "", uid = req.msg.uid, roomid = req.msg.roomid, deal_op = req.msg.deal_op }
end

function Roommgr.UpdateReadyStatus(req)
    local room = context.rooms[req.roomid]
    if not room then
        return { code = ErrorCode.RoomNotFound, error = "房间不存在" }
    end

    -- 查找玩家在房间中的位置
    local member_index = nil
    for i, member in pairs(room.players) do
        if member.mem_info.uid == req.uid then
            member_index = i
            break
        end
    end

    if not member_index then
        return { code = ErrorCode.RoomMemberNotFound, error = "玩家不在房间内" }
    end

    -- 更新准备状态（1-准备 2-取消准备）
    room.players[member_index].is_ready = req.ready_op

    -- 广播状态更新
    local notify_uids = {}
    for _, player in pairs(room.players) do
        table.insert(notify_uids, player.mem_info.uid)
    end
    context.send_users(notify_uids, {}, "Room.OnReadyStatusUpdate", {
        uid = req.uid,
        roomid = req.roomid,
        is_ready = req.ready_op,
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
    for _, member in pairs(room.players) do
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
        room_data = room.room_data,
        member_datas = {}
    }

    -- 填充成员数据
    for i, member in pairs(room.players) do
        --moon.info(string.format("Roommgr.GetRoomInfo member.mem_info:\n%s", json.pretty_encode(member.mem_info)))
        table.insert(res.member_datas, {
            seat_idx = i,
            is_ready = member.is_ready,
            mem_info = member.mem_info
        })
    end
    --moon.info(string.format("Roommgr.GetRoomInfo res:\n%s", json.pretty_encode(res)))
    return res
end

function Roommgr.RandomMapAndBoss(room_data)
    if table.size(GameCfg.GameChapter) <= 0 then
        return ErrorCode.ConfigError
    end

    local cur_idx = 0
    for idx, tmp_conf in pairs(GameCfg.GameChapter) do
        if tmp_conf.chapterid == room_data.chapter
            and tmp_conf.difficulty == room_data.difficulty then
            cur_idx = idx
            break
        end
    end
    if cur_idx == 0 then
        return ErrorCode.ConfigError
    end

    local tmp_conf = GameCfg.GameChapter[cur_idx]

    local map_total_weight = 0
    for id, weight in pairs(tmp_conf.mapid) do
        map_total_weight = map_total_weight + weight
    end
    local map_rand = math.random(map_total_weight)
    for id, weight in pairs(tmp_conf.mapid) do
        map_rand = map_rand - weight
        if map_rand <= 0 then
            room_data.map_id = id
            break
        end
    end

    local boss_total_weight = 0
    for id, weight in pairs(tmp_conf.bossid) do
        boss_total_weight = boss_total_weight + weight
    end
    local boss_rand = math.random(boss_total_weight)
    for id, weight in pairs(tmp_conf.bossid) do
        boss_rand = boss_rand - weight
        if boss_rand <= 0 then
            room_data.boss_id = id
            break
        end
    end

    return ErrorCode.None
end

function Roommgr.StartGame(req)
    local room = context.rooms[req.roomid]
    if not room then
        return { code = ErrorCode.RoomNotFound, error = "房间不存在" }
    end

    -- 验证房主身份
    if room.master_id ~= req.uid or room.room_data.state ~= 0 then
        return { code = ErrorCode.RoomPermissionDenied, error = "无开始游戏权限" }
    end

    -- 检查所有玩家准备状态
    for _, player in pairs(room.players) do
        if player.is_ready ~= 1 then
            return { code = ErrorCode.RoomNotAllReady, error = "存在未准备玩家" }
        end
    end

    local map_errcode = Roommgr.RandomMapAndBoss(room.room_data)
    if map_errcode ~= ErrorCode.None then
        return { code = map_errcode, error = "随机地图失败" }
    end

    -- 准备进入DS
    local room_info = {
        ds_id = room.room_data.roomid,
        chapter = room.room_data.chapter,
        difficulty = room.room_data.difficulty,
        map_id = room.room_data.map_id,
        boss_id = room.room_data.boss_id,
        redis_ip = context.conf.redis_nginx_ip,
        redis_port = context.conf.redis_nginx_port,
        uids = {},
    }
    for _, player in pairs(room.players) do
        table.insert(room_info.uids, player.mem_info.uid)
    end
    local _, pbdata = protocol.encodewithname("PBDsCreateData", room_info)
    local room_str = crypt.base64encode(pbdata)
    local allocate_data = {
        fleet = context.conf.fleet,
        room = room_str,
    }
    Roommgr.AddWaitDSRooms(room.room_data.roomid, json.encode(allocate_data))

    -- 更新房间状态
    room.room_data.state = 1  -- 游戏中状态
    room.room_data.isopen = 0 -- 游戏开始后关闭房间

    local room_tags = {
        isopen = room.room_data.isopen, -- 游戏开始后关闭房间
        chapter = room.room_data.chapter,
        difficulty = room.room_data.difficulty,
    }
    local redis_data = table.copy(room.room_data, true)
    redis_data.pwd = nil
    redis_data.playercnt = #room.players
    redis_data.master_id = room.master_id
    redis_data.master_name = room.master_name
    Database.upsert_room(context.addr_db_server, req.roomid, room_tags, redis_data)

    -- -----临时通知所有玩家进入DS------------
    -- local notify_uids = {}
    -- for _, player in pairs(room.players) do
    --     table.insert(notify_uids, player.mem_info.uid)
    --     moon.error("OnEnterDs ", player.mem_info.uid)
    -- end
    -- context.send_users(notify_uids, {}, "Room.OnEnterDs", {
    --     roomid = req.roomid,
    --     ds_address = "ds_address",
    --     ds_ip = "192.168.2.38-7800",
    -- })
    -- -----临时通知所有玩家进入DS------------

    return { code = ErrorCode.None, error = "游戏开始成功", roomid = req.roomid }
end

function Roommgr.GetRoomCreateData(req)
    local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
    if not req.roomid then
        return { code = ErrorCode.RoomNotFound, error = "房间不存在" }
    end

    local room = context.rooms[req.roomid]
    if not room then
        return { code = ErrorCode.RoomNotFound, error = "房间不存在" }
    end
    local room_info = {
        ds_id = room.room_data.roomid,
        chapter = room.room_data.chapter,
        difficulty = room.room_data.difficulty,
        map_id = room.room_data.map_id,
        boss_id = room.room_data.boss_id,
        redis_ip = context.conf.redis_nginx_ip,
        redis_port = context.conf.redis_nginx_port,
        uids = {},
    }
    for _, player in pairs(room.players) do
        table.insert(room_info.uids, player.mem_info.uid)
    end
    local _, pbdata = protocol.encodewithname("PBDsCreateData", room_info)
    local room_str = crypt.base64encode(pbdata)
    return { code = ErrorCode.None, error = "success", roomid = req.roomid, room_str = room_str }
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
