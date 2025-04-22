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
local jencode = json.encode
local jdecode = json.decode

---@type roommgr_context
local context = ...

local listenfd

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

            room.state = 0
            room.isopen = 0
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
        state = 0, -- 0: 等待中, 1: 游戏中, 2: 已关闭
        players = {},
        apply_list = {},
    }
    table.insert(room.players, { is_ready = 1, mem_info = req.self_info })
    
    local room_tags = {
        isopen = room.isopen,
        chapter = room.chapter,
        difficulty = room.difficulty,
    }
    local redis_data = {
        roomid = room.roomid,
        isopen = room.isopen,
        chapter = room.chapter,
	    difficulty = room.difficulty,
	    playercnt = #room.players,
	    master_id = room.master_id,
        master_name = room.master_name,
        needpwd = room.needpwd,
        state = room.state,
    }
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
        if room and room.isopen == 1 then
            table.insert(result, {
                roomid = room.roomid,
                chapter = room.chapter,
                difficulty = room.difficulty,
                playercnt = #room.players,
                master_id = room.master_id,
                master_name = room.master_name,
                needpwd = room.needpwd,
                state = room.state,
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

    local room_tags = {
        isopen = room.isopen,
        chapter = room.chapter,
        difficulty = room.difficulty,
    }
    local redis_data = {
        roomid = room.roomid,
        isopen = room.isopen,
        chapter = room.chapter,
        difficulty = room.difficulty,
        playercnt = #room.players,
        master_id = room.master_id,
        master_name = room.master_name,
        needpwd = room.needpwd,
        state = room.state,
    }
    Database.upsert_room(context.addr_db_server, room.roomid, room_tags, redis_data)

    local notify_uids = {}
    for _, player in pairs(room.players) do
        -- if player.mem_info.uid ~= req.uid then
        --     table.insert(notify_uids, player.mem_info.uid)
        -- end
        table.insert(notify_uids, player.mem_info.uid)
    end
    
    context.send_users(notify_uids, {}, "Room.OnRoomInfoSync", {
        roomid = room.roomid,
        isopen = room.isopen,
        needpwd = room.needpwd,
        pwd = room.pwd,
        chapter = room.chapter,
        difficulty = room.difficulty,
        state = room.state,
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
    context.send_user(room.master_id, "Room.OnApplyNotify", {
        roomid = req.msg.roomid,
        apply_info = req.apply_info
    })

    return { code = ErrorCode.None, error = "申请已提交", roomid = req.msg.roomid }
end

function Roommgr.DealApply(req)
    --
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
            isopen = room.isopen,
            chapter = room.chapter,
            difficulty = room.difficulty,
        }
        local redis_data = {
            roomid = room.roomid,
            isopen = room.isopen,
            chapter = room.chapter,
            difficulty = room.difficulty,
            playercnt = #room.players,
            master_id = room.master_id,
            master_name = room.master_name,
            needpwd = room.needpwd,
            state = room.state,
        }
        Database.upsert_room(context.addr_db_server, room.roomid, room_tags, redis_data)

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

    -- 房主退出特殊处理
    if req.uid == room.master_id then
        -- 转移房主给下一个玩家或解散房间
        if #room.players > 1 then
            room.master_id = room.players[2].mem_info.uid
            room.master_name = room.players[2].mem_info.nick_name
        else
            context.rooms[req.roomid] = nil
            Database.delete_room(context.addr_db_server, req.roomid)
        end
    end

    -- 移除玩家数据
    table.remove(room.players, member_index)
    context.uid_roomid[req.uid] = nil

    -- 广播玩家退出
    local notify_uids = {}
    for _, player in pairs(room.players) do
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
    room.players[member_index].is_ready = req.is_ready

    -- 广播状态更新
    local notify_uids = {}
    for _, player in pairs(room.players) do
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
        room_data = {
            roomid = room.roomid,
            isopen = room.isopen,
            needpwd = room.needpwd,
            pwd = room.pwd,
            chapter = room.chapter,
            difficulty = room.difficulty,
            state = room.state,
        },
        member_datas = {}
    }

    -- 填充成员数据
    for i, member in pairs(room.players) do
        table.insert(res.member_datas, {
            seat_idx = i,
            is_ready = member.is_ready,
            mem_info = member.mem_info
        })
    end

    return res
end

function Roommgr.StartGame(req)
    local room = context.rooms[req.roomid]
    if not room then
        return { code = ErrorCode.RoomNotFound, error = "房间不存在" }
    end

    -- 验证房主身份
    if room.master_id ~= req.uid or room.state ~= 0 then
        return { code = ErrorCode.RoomPermissionDenied, error = "无开始游戏权限" }
    end

    -- 检查所有玩家准备状态
    for _, player in pairs(room.players) do
        if player.is_ready ~= 1 then
            return { code = ErrorCode.RoomNotAllReady, error = "存在未准备玩家" }
        end
    end

    -- 准备进入DS
    local room_info = {
        room_id = room.roomid,
        chapter = room.chapter,
        difficulty = room.difficulty,
        map_id = 1,
        boss_id = 1,
        redis_ip = context.conf.redis_nginx_ip,
        redis_port = context.conf.redis_nginx_port,
        redis_authkey = context.conf.redis_nginx_authkey,
        redis_listkey = context.conf.redis_nginx_title,
        users = room.players,
    }
    local room_str = crypt.base64encode(json.encode(room_info))
    local allocate_data = {
        fleet = context.conf.fleet,
        room = room_str,
    }
    Roommgr.AddWaitDSRooms(room.roomid, json.encode(allocate_data))

    -- 更新房间状态
    room.state = 1 -- 游戏中状态
    room.isopen = 0 -- 游戏开始后关闭房间
    local room_tags = {
        isopen = room.isopen, -- 游戏开始后关闭房间
        chapter = room.chapter,
        difficulty = room.difficulty,
    }
    local redis_data = {
        roomid = room.roomid,
        isopen = room.isopen,
        chapter = room.chapter,
        difficulty = room.difficulty,
        playercnt = #room.players,
        master_id = room.master_id,
        master_name = room.master_name,
        needpwd = room.needpwd,
        state = room.state,
    }
    Database.upsert_room(context.addr_db_server, req.roomid, room_tags, redis_data)

    return { code = ErrorCode.None, error = "游戏开始成功" }
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
