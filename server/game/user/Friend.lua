local moon = require "moon"
local common = require "common"
local clusterd = require("cluster")
local json = require("json")
local GameCfg = common.GameCfg
local ErrorCode = common.ErrorCode
local CmdCode = common.CmdCode
local Database = common.Database
local ProtoEnum = require("tools.ProtoEnum")
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
        friend_group.group_id = FriendDef.DefaultGroupId
        friend_group.group_name = FriendDef.DefaultGroupName
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

function Friend.SyncFriends(friends, sync_friend, sync_apply, sync_black, update_uids)
    if not friends then
        return
    end

    local update_msg = {
        friend_datas = {},
        friends_simple_attr = {},
    }

    if sync_friend then
        update_msg.friend_datas.friend_groups = friends.friend_groups
        if table.size(update_uids) > 0 then
            local users_attr = UserAttrLogic.QueryOtherUsersSimpleAttr(context, update_uids)
            if users_attr then
                moon.warn(string.format("PBGetFriendInfoReqCmd users_attr = %s", json.pretty_encode(users_attr)))
                update_msg.friends_simple_attr = users_attr
            end
        end
    end

    if sync_apply then
        update_msg.friend_datas.apply_friends = friends.apply_friends
    end

    if sync_black then
        update_msg.friend_datas.black_list = friends.black_list
    end

    context.S2C(context.net_id, CmdCode["PBFriendSyncCmd"], update_msg, 0)
end

function Friend.AddFriend(friends, apply_uid)
    local query_field = {
        ProtoEnum.UserAttrType.is_online,
    }
    local user_attr = UserAttrLogic.QueryOtherUserAttr(context, apply_uid, query_field)
    if not user_attr or not user_attr[ProtoEnum.UserAttrType.is_online] then
        return ErrorCode.UserNotExist
    end
    if user_attr[ProtoEnum.UserAttrType.is_online] == 1 then
        local res_code, err = context.call_user(apply_uid, "Friend.OtherAddFriend", context.uid)
        if err or not res_code then
            moon.error("Friend.OtherAddFriend err:%s", err)
            return ErrorCode.FriendAddErr
        end

        if res_code ~= ErrorCode.None then
            return res_code
        end
    else
        -- 发送到FriendMgr,等待对方上线处理
        local add_data = {
            uid = apply_uid,
            from_uid = context.uid,
        }
        clusterd.send(3999, "friendmgr", "Friendmgr.AddOfflineApply", add_data)
    end

    local newfriend = FriendDef.newFriendData()
    newfriend.uid = apply_uid
    newfriend.notes = ""
    friends.friend_groups[FriendDef.DefaultGroupId].group_friends[apply_uid] = newfriend

    return ErrorCode.None
end

function Friend.OtherAddFriend(add_uid)
    local friends = scripts.UserModel.GetFriends()
    if not friends then
        return ErrorCode.FrienAddErr
    end

    local friend_cfg = GameCfg.FriendConfig[1]
    if not friend_cfg then
        return ErrorCode.ConfigError
    end

    local total_cnt = 0
    for group_id, group_data in pairs(friends.friend_groups) do
        total_cnt = total_cnt + table.size(group_data.group_friends)
        if group_data.group_friends[add_uid] then
            return ErrorCode.FriendInFriendList
        end
    end
    if total_cnt >= friend_cfg.Friend_limit then
        return ErrorCode.FriendLimit
    end

    for black_uid, _ in pairs(friends.black_list) do
        if black_uid == add_uid then
            return ErrorCode.FriendInBlackList
        end
    end

    local newfriend = FriendDef.newFriendData()
    newfriend.uid = add_uid
    newfriend.notes = ""
    friends.friend_groups[FriendDef.DefaultGroupId].group_friends[add_uid] = newfriend

    Friend.SaveFriendsNow()

    Friend.SyncFriends(friends, true, false, false, { add_uid })

    return ErrorCode.None
end

function Friend.RefuseFriend(refuse_uid)
    local query_field = {
        ProtoEnum.UserAttrType.is_online,
    }
    local user_attr = UserAttrLogic.QueryOtherUserAttr(context, refuse_uid, query_field)
    if not user_attr or not user_attr[ProtoEnum.UserAttrType.is_online] then
        return ErrorCode.UserNotExist
    end
    if user_attr[ProtoEnum.UserAttrType.is_online] == 1 then
        local res_code, err = context.send_user(refuse_uid, "Friend.OtherRefuseFriend", context.uid)
        if err or not res_code then
            moon.error("Friend.OtherAddFriend err:%s", err)
            return ErrorCode.FriendAddErr
        end

        if res_code ~= ErrorCode.None then
            return res_code
        end
    end
end

function Friend.OtherRefuseFriend(refuse_uid)
    context.S2C(context.net_id, CmdCode["PBFriendOtherRefuseSyncCmd"], { refuse_uid = refuse_uid }, 0)
end

function Friend.DelFriendApply(friends, apply_uid)
    friends.apply_friends[apply_uid] = nil
end

function Friend.OtherApplyFriend(msg)
    local friends = scripts.UserModel.GetFriends()
    if not friends then
        return ErrorCode.FriendApplyErr
    end

    local friend_cfg = GameCfg.FriendConfig[1]
    if not friend_cfg then
        return ErrorCode.ConfigError
    end

    local total_cnt = 0
    for group_id, group_data in pairs(friends.friend_groups) do
        total_cnt = total_cnt + table.size(group_data.group_friends)
        if group_data.group_friends[msg.uid] then
            return ErrorCode.FriendInFriendList
        end
    end
    if total_cnt >= friend_cfg.Friend_limit then
        return ErrorCode.FriendLimit
    end

    if table.size(friends.apply_friends) >= friend_cfg.apply_limit then
        return ErrorCode.FriendApplyLimit
    end
    for apply_uid, _ in pairs(friends.apply_friends) do
        if apply_uid == msg.uid then
            return ErrorCode.FriendInApplyList
        end
    end

    for black_uid, _ in pairs(friends.black_list) do
        if black_uid == msg.uid then
            return ErrorCode.FriendInBlackList
        end
    end

    local apply_friend = FriendDef.newApplyFriendData()
    apply_friend.uid = msg.uid
    apply_friend.head_id = msg.apply_data.head_id
    apply_friend.nick_name = msg.apply_data.nick_name
    apply_friend.account_level = msg.apply_data.account_level
    apply_friend.head_frame = msg.apply_data.head_frame
    apply_friend.title = msg.apply_data.title
    apply_friend.guild_id = msg.apply_data.guild_id
    apply_friend.guild_name = msg.apply_data.guild_name
    friends.apply_friends[msg.uid] = apply_friend

    Friend.SaveFriendsNow()
    Friend.SyncFriends(friends, false, true, false, {})

    return ErrorCode.None
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
        return context.S2C(context.net_id, CmdCode["PBApplyFriendRspCmd"],
            { code = ErrorCode.ServerInternalError, error = "数据加载出错", uid = context.uid }, req.msg_context.stub_id)
    end

    local friend_cfg = GameCfg.FriendConfig[1]
    if not friend_cfg then
        return context.S2C(context.net_id, CmdCode["PBApplyFriendRspCmd"],
            { code = ErrorCode.ConfigError, error = "no friend_cfg" }, req.msg_context.stub_id)
    end

    local total_cnt = 0
    for group_id, group_data in pairs(friends.friend_groups) do
        total_cnt = total_cnt + table.size(group_data.group_friends)
        if group_data.group_friends[req.msg.target_uid] then
            return context.S2C(context.net_id, CmdCode["PBApplyFriendRspCmd"],
                { code = ErrorCode.FriendInFriendList, error = "好友已在好友列表" }, req.msg_context.stub_id)
        end
    end
    if total_cnt >= friend_cfg.Friend_limit then
        return context.S2C(context.net_id, CmdCode["PBApplyFriendRspCmd"],
            { code = ErrorCode.FriendLimit, error = "好友数量已达上限" }, req.msg_context.stub_id)
    end

    for uid, _ in pairs(friends.black_list) do
        if uid == req.msg.uid then
            return ErrorCode.FriendInBlackList
        end
    end

    local query_field = {
        ProtoEnum.UserAttrType.is_online,
    }
    local user_attr = UserAttrLogic.QueryOtherUserAttr(context, req.msg.target_uid, query_field)
    if not user_attr or not user_attr[ProtoEnum.UserAttrType.is_online] then
        return context.S2C(context.net_id, CmdCode["PBApplyFriendRspCmd"],
            { code = ErrorCode.UserNotExist, error = "用户不存在" }, req.msg_context.stub_id)
    end
    if user_attr[ProtoEnum.UserAttrType.is_online] == 1 then
        local res_code, err = context.call_user(req.msg.target_uid, "Friend.OtherApplyFriend", req.msg)
        if err or not res_code then
            moon.error("Friend.ApplyFriend err:%s", err)
            return context.S2C(context.net_id, CmdCode["PBApplyFriendRspCmd"],
                { code = ErrorCode.FriendApplyErr, error = "好友申请错误" }, req.msg_context.stub_id)
        end

        if res_code ~= ErrorCode.None then
            return context.S2C(context.net_id, CmdCode["PBApplyFriendRspCmd"],
                { code = res_code, error = "", uid = req.msg.uid, target_uid = req.msg.target_uid },
                req.msg_context.stub_id)
        end
    else
        -- 发送到FriendMgr,等待对方上线处理
        clusterd.send(3999, "friendmgr", "Friendmgr.AddOfflineApply", req.msg)
    end

    return context.S2C(context.net_id, CmdCode["PBApplyFriendRspCmd"],
        { code = ErrorCode.None, error = "", uid = req.msg.uid, target_uid = req.msg.target_uid },
        req.msg_context.stub_id)
end

function Friend.PBFriendDealApplyReqCmd(req)
    if context.uid ~= req.msg.uid
        or req.msg.quest_uid == 0
        or req.msg.deal_type == 0 then
        return context.S2C(context.net_id, CmdCode.PBFriendDealApplyRspCmd, {
            code = ErrorCode.ParamInvalid,
            error = "无效请求参数",
            uid = context.uid,
            quest_uid = req.msg.quest_uid or 0,
        }, req.msg_context.stub_id)
    end

    local friends = scripts.UserModel.GetFriends()
    if not friends then
        return context.S2C(context.net_id, CmdCode["PBFriendDealApplyRspCmd"],
            { code = ErrorCode.ServerInternalError, error = "数据加载出错", uid = context.uid }, req.msg_context.stub_id)
    end

    local friend_cfg = GameCfg.FriendConfig[1]
    if not friend_cfg then
        return context.S2C(context.net_id, CmdCode["PBFriendDealApplyRspCmd"],
            { code = ErrorCode.ConfigError, error = "no friend_cfg" }, req.msg_context.stub_id)
    end

    local rsp_msg = {
        code = ErrorCode.None,
        error = "",
        uid = context.uid,
        quest_uid = req.msg.quest_uid or 0,
    }
    local apply_friend = friends.apply_friends[req.msg.quest_uid]
    if not apply_friend then
        rsp_msg.code = ErrorCode.FriendApplyNotExist
        rsp_msg.error = "好友申请不存在"
        return context.S2C(context.net_id, CmdCode["PBFriendDealApplyRspCmd"], rsp_msg, req.msg_context.stub_id)
    end

    if req.msg.deal_type == 1 then
        -- 同意添加好友
        -- 删除好友申请
        Friend.DelFriendApply(friends, req.msg.quest_uid)

        local total_cnt = 0
        for group_id, group_data in pairs(friends.friend_groups) do
            total_cnt = total_cnt + table.size(group_data.group_friends)
        end
        if total_cnt >= friend_cfg.Friend_limit then
            Friend.SaveFriendsNow()
            Friend.SyncFriends(friends, false, true, false, {})

            rsp_msg.code = ErrorCode.FriendLimit
            rsp_msg.error = "好友数量已达上限"
            return context.S2C(context.net_id, CmdCode["PBFriendDealApplyRspCmd"], rsp_msg, req.msg_context.stub_id)
        end

        local ret_code = Friend.AddFriend(friends, req.msg.quest_uid)
        if ret_code ~= ErrorCode.None then
            Friend.SaveFriendsNow()
            Friend.SyncFriends(friends, false, true, false, {})

            rsp_msg.code = ret_code
            rsp_msg.error = "添加好友失败"
            return context.S2C(context.net_id, CmdCode["PBFriendDealApplyRspCmd"], rsp_msg, req.msg_context.stub_id)
        end

        Friend.SaveFriendsNow()
        Friend.SyncFriends(friends, true, true, false, { req.msg.quest_uid })

        return context.S2C(context.net_id, CmdCode["PBFriendDealApplyRspCmd"], rsp_msg, req.msg_context.stub_id)
    elseif req.msg.deal_type == 2 then
        -- 拒绝好友申请
        -- 删除好友申请
        Friend.DelFriendApply(friends, req.msg.quest_uid)

        Friend.RefuseFriend(req.msg.quest_uid)

        Friend.SaveFriendsNow()
        Friend.SyncFriends(friends, false, true, false, {})
        return context.S2C(context.net_id, CmdCode["PBFriendDealApplyRspCmd"], rsp_msg, req.msg_context.stub_id)
    else
        rsp_msg.code = ErrorCode.ParamInvalid
        rsp_msg.error = "无效请求参数"
        return context.S2C(context.net_id, CmdCode["PBFriendDealApplyRspCmd"], rsp_msg, req.msg_context.stub_id)
    end
end

return Friend