local LuaExt = require "common.LuaExt"

local RoomDef = {
    SyncType = {
        ModRoomData = 1,    -- 修改房间信息
        PlayerEnter = 2,    -- 玩家加入
        PlayerExit = 3,     -- 玩家退出
        PlayerKick = 4,     -- 玩家被踢出
        PlayerReady = 5,    -- 玩家改变准备状态
        PlayerApply = 6,    -- 有玩家申请加入
    }
}

local defaultPBRoomSearchInfo = {
    roomid = 0,
    chapter = 0,
    difficulty = 0,
    playercnt = 0,
    master_id = 0,
    master_name = "",
    is_open = 0,
    needpwd = 0,
    describe = "",
}

local defaultPBRoomInfo = {
    roomid = 0,
    is_open = 0,
    needpwd = 0,
    pwd = "",
    chapter = 0,
    difficulty = 0,
    state = 0,
    describe = "",
    map_id = 0,
    boss_id = 0,
    master_id = 0,
}

local defaultPBRoomWholeInfo = {
    room_data = LuaExt.const(table.copy(defaultPBRoomInfo)),
    master_id = 0,
    master_name = "",
    players = {},
    apply_list = {},
    invite_list = {},
}

---@return PBRoomSearchInfo
function RoomDef.newRoomSearchInfo()
    return LuaExt.const(table.copy(defaultPBRoomSearchInfo))
end

---@return PBRoomInfo
function RoomDef.newRoomInfo()
    return LuaExt.const(table.copy(defaultPBRoomInfo))
end

---@return PBRoomWholeInfo
function RoomDef.newRoomWholeInfo()
    return LuaExt.const(table.copy(defaultPBRoomWholeInfo))
end

return RoomDef
