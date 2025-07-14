local LuaExt = require "common.LuaExt"

local FriendDef = {
    DefaultGroupId = 1,
    DefaultGroupName = "我的好友",
}

local defaultPBFriendData = {
    uid = 0,
    notes = "",    --备注
}

local defaultPBApplyFriendData = {
    uid = 0,
    head_id = 0,
    nick_name = "",
    account_level = 0,
    head_frame = 0,
    title = 0,
    guild_id = 0,
    guild_name = "",
}

local defaultPBFriendGroupData = {
    group_id = 0,    --分组id
    group_name = "", --分组名称
    group_friends = {}, --分组内的好友
}

local defaultPBUserFriendDatas = {
    friend_groups = {},    --好友分组
    apply_friends = {}, --申请好友
    black_list = {}, --黑名单
}

---@return PBFriendData
function FriendDef.newFriendData()
    return LuaExt.const(table.copy(defaultPBFriendData))
end

---@return PBApplyFriendData
function FriendDef.newApplyFriendData()
    return LuaExt.const(table.copy(defaultPBApplyFriendData))
end

---@return PBFriendGroupData
function FriendDef.newFriendGroupData()
    return LuaExt.const(table.copy(defaultPBFriendGroupData))
end

---@return PBUserFriendDatas
function FriendDef.newUserFriendDatas()
    return LuaExt.const(table.copy(defaultPBUserFriendDatas))
end

return FriendDef
