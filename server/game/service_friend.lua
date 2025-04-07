local moon = require "moon"
local common = require "common"
local GameDef = common.GameDef
local Database = common.Database
local ErrorCode = common.ErrorCode
local CmdCode = common.CmdCode

---@type friend_context
local context = ...
local scripts = context.scripts

local FriendService = {}

function FriendService.Init()
    -- 初始化好友关系维护定时器
    moon.async(function()
        while true do
            moon.sleep(30000)  -- 每30秒同步好友状态
            scripts.FriendService.SyncFriendStatus()
        end
    end)
end

function FriendService.HandleAddFriend(uid, target_uid)
    -- 检查双向好友关系
    if Database.CheckMutualFriend(uid, target_uid) then
        return ErrorCode.AlreadyFriends
    end

    -- 写入关系数据库
    Database.AddFriendRelation(uid, target_uid)
    Database.AddFriendRelation(target_uid, uid)

    -- 更新内存数据
    scripts.UserModel.MutGet(uid).friends[target_uid] = true
    scripts.UserModel.MutGet(target_uid).friends[uid] = true

    return ErrorCode.Success
end

function FriendService.SyncFriendStatus()
    -- 批量同步在线状态
    local online_users = context.call_gate(context.addr_gate, "GetOnlineUsers")
    for uid, _ in pairs(scripts.UserModel.GetAll()) do
        local is_online = online_users[uid] ~= nil
        scripts.UserModel.MutGet(uid).friend_status = is_online and 0 or 3
    end
    
    -- 广播状态更新
    context.broadcast_gate("FriendStatusUpdate", {
        update_time = moon.time(),
        status_list = online_users
    })
end

return FriendService