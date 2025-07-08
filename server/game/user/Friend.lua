local moon = require "moon"
local common = require "common"
local cluster = require("cluster")
local json = require("json")
local GameCfg = common.GameCfg
local ErrorCode = common.ErrorCode
local CmdCode = common.CmdCode
local Database = common.Database
local FriendDef = require("common.def.FriendDef")
local UserAttrLogic = require("common.logic.UserAttrLogic")

---@type user_context
local context = ...
local scripts = context.scripts

---@class Friend
local Friend = {}

function Friend.Init()

end

function Friend.Start()
    --加载好友数据
    local friends_data = Friend.LoadFriends()
    if friends_data then
        scripts.UserModel.SetFriends(friends_data)
    end

    local friends = scripts.UserModel.GetFriends()
    if not friends then
        friends = FriendDef.newUserFriendDatas()
        local friend_group = FriendDef.newFriendGroupData()
        friend_group.group_id = 1
        friend_group.group_name = "普通好友"
        friends.friend_groups[friend_group.group_id] = friend_group
        scripts.UserModel.SetFriends(friends)

        Friend.SaveFriendsNow()
    end
end

function Friend.SaveFriendsNow()
    local friends = scripts.UserModel.GetFriends()
    if not friends then
        return false
    end

    local success = Database.savefriends(context.addr_db_user, context.uid, friends)
    return success
end

function Friend.LoadFriends()
    local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
    local friends_data = Database.loadfriends(context.addr_db_user, context.uid)
    return friends_data
end

function Friend.PBGetFriendInfoReqCmd(req)
    local friends = scripts.UserModel.GetFriends()
    if not friends then
        return context.S2C(context.net_id, CmdCode["PBGetFriendInfoRspCmd"],
            { code = ErrorCode.ServerInternalError, error = "数据加载出错", uid = context.uid }, req.msg_context.stub_id)
    end

    local rsp_msg = {
        code = ErrorCode.None,
        error = "",
        uid = req.msg.uid,
        friend_datas = friends,
    }
    local friend_uids = {}
    for group_id, group_data in pairs(friends.friend_groups) do
        for uid, friend_data in pairs(group_data) do
            table.insert(friend_uids, uid)
        end
    end
    if table.size(friend_uids) > 0 then
        local users_attr = UserAttrLogic.QueryOtherUsersSimpleAttr(context, friend_uids)
        if users_attr then
            moon.warn(string.format("PBGetFriendInfoReqCmd users_attr = %s", json.pretty_encode(users_attr)))
            rsp_msg.friends_simple_attr = users_attr
        end
    end

    return context.S2C(context.net_id, CmdCode["PBGetFriendInfoRspCmd"], rsp_msg, req.msg_context.stub_id)
end

function Friend.PBApplyFriendReqCmd(req)
    local friends = scripts.UserModel.GetFriends()
    if not friends then
        return context.S2C(context.net_id, CmdCode["PBGetFriendInfoRspCmd"],
            { code = ErrorCode.ServerInternalError, error = "数据加载出错", uid = context.uid }, req.msg_context.stub_id)
    end

    local total_cnt = 0
    for group_id, group_data in pairs(friends.friend_groups) do
        
    end
end

return Friend