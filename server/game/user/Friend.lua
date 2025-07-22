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

local apply_fields = {
    ProtoEnum.UserAttrType.uid,
    ProtoEnum.UserAttrType.nick_name,
    ProtoEnum.UserAttrType.head_icon,
    ProtoEnum.UserAttrType.head_frame,
    ProtoEnum.UserAttrType.account_level,
    ProtoEnum.UserAttrType.guild_id,
    ProtoEnum.UserAttrType.guild_name,
    ProtoEnum.UserAttrType.title,
}

---@class Friend
local Friend = {}

function Friend.Init()

end

function Friend.Start()
    --加载好友数据
    --local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
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
    end

    Friend.DealRelations()
    Friend.SaveFriendsNow()
end

function Friend.Online()
    local friends = scripts.UserModel.GetFriends()
    if not friends then
        return
    end

    clusterd.send(3999, "friendmgr", "Friendmgr.FriendOnline", context.uid)
end

function Friend.Offline()
    local friends = scripts.UserModel.GetFriends()
    if not friends then
        return
    end

    clusterd.send(3999, "friendmgr", "Friendmgr.FriendOffline", context.uid)
end

function Friend.OtherOnline(uid)
    context.S2C(context.net_id, CmdCode["PBFriendOnlineSyncCmd"], {change_uid = uid, is_online = 1}, 0)
end

function Friend.OtherOffline(uid)
    context.S2C(context.net_id, CmdCode["PBFriendOnlineSyncCmd"], {change_uid = uid, is_online = 0}, 0)
end

function Friend.DealRelations()
    --local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
    local friends = scripts.UserModel.GetFriends()
    if not friends then
        return
    end

    local relations, err = clusterd.call(3999, "friendmgr", "Friendmgr.GetRelations", context.uid)
    --local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
    if err then
        moon.error("Friend.DealOfflineMsg Friendmgr.GetRelations err:%s", err)
    end

    if relations then
        for group_id, group_data in pairs(friends.friend_groups) do
            local del_friends = {}
            for friend_uid, _ in pairs(group_data.group_friends) do
                if not relations[friend_uid]
                    or relations[friend_uid] < FriendDef.FriendRelationValue.FriendStart
                    or relations[friend_uid] > FriendDef.FriendRelationValue.FriendEnd then
                    table.insert(del_friends, friend_uid)
                else
                    relations[friend_uid] = nil
                end
            end
            for _, friend_uid in pairs(del_friends) do
                group_data.group_friends[friend_uid] = nil
            end
        end

        local del_applys = {}
        for apply_uid, _ in pairs(friends.apply_friends) do
            if not relations[apply_uid]
                or relations[apply_uid] ~= FriendDef.FriendRelationValue.Apply then
                table.insert(del_applys, apply_uid)
            else
                relations[apply_uid] = nil
            end
        end
        for _, apply_uid in pairs(del_applys) do
            friends.apply_friends[apply_uid] = nil
        end

        local del_blacks = {}
        for black_uid, _ in pairs(friends.black_list) do
            if not relations[black_uid]
                or relations[black_uid] ~= FriendDef.FriendRelationValue.Black then
                table.insert(del_blacks, black_uid)
            else
                relations[black_uid] = nil
            end
        end
        for _, black_uid in pairs(del_blacks) do
            friends.black_list[black_uid] = nil
        end

        for rela_uid, relation_value in pairs(relations) do
            if relation_value >= FriendDef.FriendRelationValue.FriendStart
                and relation_value <= FriendDef.FriendRelationValue.FriendEnd then
                local newfriend = FriendDef.newFriendData()
                newfriend.uid = rela_uid
                newfriend.notes = ""
                friends.friend_groups[FriendDef.DefaultGroupId].group_friends[rela_uid] = newfriend
            elseif relation_value == FriendDef.FriendRelationValue.Apply then
                local user_attr = UserAttrLogic.QueryOtherUserAttr(context, rela_uid, apply_fields)
                if user_attr then
                    local apply_friend = FriendDef.newApplyFriendData()
                    apply_friend.uid = user_attr.uid
                    apply_friend.head_icon = user_attr.head_id
                    apply_friend.nick_name = user_attr.nick_name
                    apply_friend.account_level = user_attr.account_level
                    apply_friend.head_frame = user_attr.head_frame
                    apply_friend.title = user_attr.title
                    apply_friend.guild_id = user_attr.guild_id
                    apply_friend.guild_name = user_attr.guild_name
                    friends.apply_friends[rela_uid] = apply_friend
                end
            elseif relation_value == FriendDef.FriendRelationValue.Black then
                local newfriend = FriendDef.newFriendData()
                newfriend.uid = rela_uid
                newfriend.notes = ""
                friends.black_list[rela_uid] = newfriend
            end
        end
    end

    Friend.SaveRelations(friends)
end

function Friend.SaveRelations(friends)
    if not friends then
        return
    end

    local new_relations = {}
    for group_id, group_data in pairs(friends.friend_groups) do
        for friend_uid, _ in pairs(group_data.group_friends) do
            new_relations[friend_uid] = group_id
        end
    end
    for apply_uid, _ in pairs(friends.apply_friends) do
        new_relations[apply_uid] = FriendDef.FriendRelationValue.Apply
    end
    for black_uid, _ in pairs(friends.black_list) do
        new_relations[black_uid] = FriendDef.FriendRelationValue.Black
    end
    local user_relations = {}
    user_relations[context.uid] = new_relations
    clusterd.send(3999, "friendmgr", "Friendmgr.SetRelations", user_relations)
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
    --local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
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

function Friend.DelFriend(friends, del_uid)
    local del_success = false
    local cur_group_id = 0
    for group_id, group_data in pairs(friends.friend_groups) do
        if group_data.group_friends and group_data.group_friends[del_uid] then
            del_success = true
            cur_group_id = group_id
        end
    end
    if not del_success then
        return ErrorCode.FriendNotExist
    end

    local del_data = {
        from_uid = context.uid,
        del_uid = del_uid,
    }
    clusterd.send(3999, "friendmgr", "Friendmgr.DelFriend", del_data)

    friends.friend_groups[cur_group_id].group_friends[del_uid] = nil

    return ErrorCode.None
end

function Friend.OtherDelFriend(friend_uid)
    local friends = scripts.UserModel.GetFriends()
    if not friends then
        return
    end

    local del_success = false
    for group_id, group_data in pairs(friends.friend_groups) do
        if group_data.group_friends and group_data.group_friends[friend_uid] then
            group_data.group_friends[friend_uid] = nil
            del_success = true
        end
    end
    if not del_success then
        return
    end

    Friend.SaveFriendsNow()
    Friend.SyncFriends(friends, true, false, false, {})
end

function Friend.AgreeApply(friends, apply_uid)
    -- 删除好友申请
    Friend.DelFriendApply(friends, apply_uid)

    if friends.black_list[apply_uid] then
        return ErrorCode.FriendInBlackList
    end

    local friend_cfg = GameCfg.FriendConfig[1]
    if not friend_cfg then
        return ErrorCode.ConfigError
    end

    local total_cnt = 0
    for group_id, group_data in pairs(friends.friend_groups) do
        total_cnt = total_cnt + table.size(group_data.group_friends)
        if group_data.group_friends[apply_uid] then
            return ErrorCode.FriendInFriendList
        end
    end
    if total_cnt >= friend_cfg.Friend_limit then
        return ErrorCode.FriendLimit
    end

    local agree_data = {
        from_uid = context.uid,
        apply_uid = apply_uid,
    }
    local res, err = clusterd.call(3999, "friendmgr", "Friendmgr.AgreeApply", agree_data)
    if err or not res then
        moon.error("Friendmgr.AgreeApply err:%s", err)
        return ErrorCode.FriendAddErr
    end
    if res ~= ErrorCode.None then
        -- 同意添加失败则拒绝申请
        local refuse_data = {
            from_uid = context.uid,
            apply_uid = apply_uid,
        }
        clusterd.send(3999, "friendmgr", "Friendmgr.RefuseApply", refuse_data)

        return res
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
        return
    end

    for group_id, group_data in pairs(friends.friend_groups) do
        if group_data.group_friends[add_uid] then
            return
        end
    end

    local newfriend = FriendDef.newFriendData()
    newfriend.uid = add_uid
    newfriend.notes = ""
    friends.friend_groups[FriendDef.DefaultGroupId].group_friends[add_uid] = newfriend

    Friend.SaveFriendsNow()
    Friend.SyncFriends(friends, true, false, false, { add_uid })
end

function Friend.RefuseApply(friends, apply_uid)
    -- 删除好友申请
    Friend.DelFriendApply(friends, apply_uid)

    local refuse_data = {
        from_uid = context.uid,
        apply_uid = apply_uid,
    }
    clusterd.send(3999, "friendmgr", "Friendmgr.RefuseApply", refuse_data)
end

function Friend.OtherRefuseFriend(refuse_uid)
    context.S2C(context.net_id, CmdCode["PBFriendOtherRefuseSyncCmd"], { refuse_uid = refuse_uid }, 0)
end

function Friend.DelFriendApply(friends, apply_uid)
    friends.apply_friends[apply_uid] = nil
end

function Friend.OtherApplyFriend(apply_data)
    local friends = scripts.UserModel.GetFriends()
    if not friends then
        return
    end

    local apply_friend = FriendDef.newApplyFriendData()
    apply_friend.uid = apply_data.uid
    apply_friend.head_icon = apply_data.head_id
    apply_friend.nick_name = apply_data.nick_name
    apply_friend.account_level = apply_data.account_level
    apply_friend.head_frame = apply_data.head_frame
    apply_friend.title = apply_data.title
    apply_friend.guild_id = apply_data.guild_id
    apply_friend.guild_name = apply_data.guild_name
    friends.apply_friends[apply_data.uid] = apply_friend

    Friend.SaveFriendsNow()
    Friend.SyncFriends(friends, false, true, false, {})
end

function Friend.AddBlack(friends, black_uid)
    local friend_cfg = GameCfg.FriendConfig[1]
    if not friend_cfg then
        return ErrorCode.ConfigError
    end

    if table.size(friends.black_list) >= friend_cfg.Blacklist_limit then
        return ErrorCode.FriendLimit
    end

    if friends.black_list[black_uid] then
        return ErrorCode.FriendInBlackList
    end

    for _, group_data in pairs(friends.friend_groups) do
        if group_data.group_friends[black_uid] then
            return ErrorCode.FriendInFriendList
        end
    end

    local query_field = {
        ProtoEnum.UserAttrType.uid,
    }
    local user_attr = UserAttrLogic.QueryOtherUserAttr(context, black_uid, query_field)
    if not user_attr or user_attr[ProtoEnum.UserAttrType.uid] ~= black_uid then
        return ErrorCode.UserNotExist
    end

    local newblack = FriendDef.newFriendData()
    newblack.uid = black_uid
    newblack.notes = ""
    friends.black_list[black_uid] = newblack

    local black_data = {
        from_uid = context.uid,
        black_uid = black_uid,
    }
    clusterd.send(3999, "friendmgr", "Friendmgr.AddBlack", black_data)

    return ErrorCode.None
end

function Friend.DelBlack(friends, black_uid)
    if not friends.black_list[black_uid] then
        return ErrorCode.FriendNotInBlackList
    end
    friends.black_list[black_uid] = nil

    local black_data = {
        from_uid = context.uid,
        black_uid = black_uid,
    }
    clusterd.send(3999, "friendmgr", "Friendmgr.DelBlack", black_data)

    return ErrorCode.None
end

function Friend.SetNotes(friends, target_uid, notes)
    local success_code = 0
    for _, group_data in pairs(friends.friend_groups) do
        if group_data.group_friends[target_uid] then
            group_data.group_friends[target_uid].notes = notes
            success_code = 1
            break
        end
    end

    if success_code == 0 then
        if friends.black_list[target_uid] then
            success_code = 2
            friends.black_list[target_uid].notes = notes
        end
    end

    return success_code
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

    if friends.black_list[req.msg.target_uid] then
        return context.S2C(context.net_id, CmdCode["PBApplyFriendRspCmd"],
            { code = ErrorCode.FriendInBlackList, error = "好友已在黑名单" }, req.msg_context.stub_id)
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

    local query_res = scripts.User.QueryUserAttr(apply_fields)
    --local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
    if query_res.code ~= ErrorCode.None then
        return context.S2C(context.net_id, CmdCode["PBApplyFriendRspCmd"],
            { code = query_res.code, error = query_res.error }, req.msg_context.stub_id)
    end

    local res, err = clusterd.call(3999, "friendmgr", "Friendmgr.AddApply", {
        target_uid = req.msg.target_uid,
        apply_data = query_res.user_attr,
    })
    --local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
    if err or not res then
        return context.S2C(context.net_id, CmdCode["PBApplyFriendRspCmd"],
            { code = ErrorCode.FriendApplyErr, error = "申请好友错误" }, req.msg_context.stub_id)
    end

    return context.S2C(context.net_id, CmdCode["PBApplyFriendRspCmd"],
        { code = res, error = "", uid = req.msg.uid, target_uid = req.msg.target_uid }, req.msg_context.stub_id)
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
        local ret_code = Friend.AgreeApply(friends, req.msg.quest_uid)
        rsp_msg.code = ret_code

        Friend.SaveFriendsNow()
        if ret_code == ErrorCode.None then
            Friend.SyncFriends(friends, true, true, false, { req.msg.quest_uid })
        else
            Friend.SyncFriends(friends, false, true, false, {})
        end

        return context.S2C(context.net_id, CmdCode["PBFriendDealApplyRspCmd"], rsp_msg, req.msg_context.stub_id)
    elseif req.msg.deal_type == 2 then
        -- 拒绝好友申请
        Friend.RefuseApply(friends, req.msg.quest_uid)

        Friend.SaveFriendsNow()
        Friend.SyncFriends(friends, false, true, false, {})

        return context.S2C(context.net_id, CmdCode["PBFriendDealApplyRspCmd"], rsp_msg, req.msg_context.stub_id)
    else
        rsp_msg.code = ErrorCode.ParamInvalid
        rsp_msg.error = "无效请求参数"
        return context.S2C(context.net_id, CmdCode["PBFriendDealApplyRspCmd"], rsp_msg, req.msg_context.stub_id)
    end
end

function Friend.PBFriendDelReqCmd(req)
    if context.uid ~= req.msg.uid
        or req.msg.del_uid == 0 then
        return context.S2C(context.net_id, CmdCode.PBFriendDelRspCmd, {
            code = ErrorCode.ParamInvalid,
            error = "无效请求参数",
            uid = context.uid,
            del_uid = req.msg.del_uid or 0,
        }, req.msg_context.stub_id)
    end

    local friends = scripts.UserModel.GetFriends()
    if not friends then
        return context.S2C(context.net_id, CmdCode["PBFriendDelRspCmd"],
            { code = ErrorCode.ServerInternalError, error = "数据加载出错", uid = context.uid }, req.msg_context.stub_id)
    end

    local rsp_msg = {
        code = ErrorCode.None,
        error = "",
        uid = context.uid,
        del_uid = req.msg.del_uid or 0,
    }
    local ret_code = Friend.DelFriend(friends, req.msg.del_uid)
    if ret_code ~= ErrorCode.None then
        rsp_msg.code = ret_code
        rsp_msg.error = "删除好友失败"
        return context.S2C(context.net_id, CmdCode["PBFriendDelRspCmd"], rsp_msg, req.msg_context.stub_id)
    end

    Friend.SaveFriendsNow()
    Friend.SyncFriends(friends, true, false, false, {})

    return context.S2C(context.net_id, CmdCode["PBFriendDelRspCmd"], rsp_msg, req.msg_context.stub_id)
end

function Friend.PBFriendAddBlackReqCmd(req)
    if context.uid ~= req.msg.uid
        or req.msg.black_uid == 0 then
        return context.S2C(context.net_id, CmdCode.PBFriendAddBlackRspCmd, {
            code = ErrorCode.ParamInvalid,
            error = "无效请求参数",
            uid = context.uid,
            black_uid = req.msg.black_uid or 0,
        }, req.msg_context.stub_id)
    end

    local friends = scripts.UserModel.GetFriends()
    if not friends then
        return context.S2C(context.net_id, CmdCode["PBFriendAddBlackRspCmd"],
            { code = ErrorCode.ServerInternalError, error = "数据加载出错", uid = context.uid }, req.msg_context.stub_id)
    end

    local rsp_msg = {
        code = ErrorCode.None,
        error = "",
        uid = context.uid,
        black_uid = req.msg.black_uid or 0,
    }
    local ret_code = Friend.AddBlack(friends, req.msg.black_uid)
    if ret_code ~= ErrorCode.None then
        rsp_msg.code = ret_code
        rsp_msg.error = "添加黑名单失败"
        return context.S2C(context.net_id, CmdCode["PBFriendAddBlackRspCmd"], rsp_msg, req.msg_context.stub_id)
    end

    Friend.SaveFriendsNow()
    Friend.SyncFriends(friends, false, false, true, {})

    return context.S2C(context.net_id, CmdCode["PBFriendAddBlackRspCmd"], rsp_msg, req.msg_context.stub_id)
end

function Friend.PBFriendDelBlackReqCmd(req)
    if context.uid ~= req.msg.uid
        or req.msg.black_uid == 0 then
        return context.S2C(context.net_id, CmdCode.PBFriendDelBlackRspCmd, {
            code = ErrorCode.ParamInvalid,
            error = "无效请求参数",
            uid = context.uid,
            black_uid = req.msg.black_uid or 0,
        }, req.msg_context.stub_id)
    end

    local friends = scripts.UserModel.GetFriends()
    if not friends then
        return context.S2C(context.net_id, CmdCode["PBFriendDelBlackRspCmd"],
            { code = ErrorCode.ServerInternalError, error = "数据加载出错", uid = context.uid }, req.msg_context.stub_id)
    end

    local rsp_msg = {
        code = ErrorCode.None,
        error = "",
        uid = context.uid,
        black_uid = req.msg.black_uid or 0,
    }
    local ret_code = Friend.DelBlack(friends, req.msg.black_uid)
    if ret_code ~= ErrorCode.None then
        rsp_msg.code = ret_code
        rsp_msg.error = "删除黑名单失败"
        return context.S2C(context.net_id, CmdCode["PBFriendDelBlackRspCmd"], rsp_msg, req.msg_context.stub_id)
    end

    Friend.SaveFriendsNow()
    Friend.SyncFriends(friends, false, false, true, {})

    return context.S2C(context.net_id, CmdCode["PBFriendDelBlackRspCmd"], rsp_msg, req.msg_context.stub_id)
end

function Friend.PBFriendSetNotesReqCmd(req)
    if context.uid ~= req.msg.uid
        or req.msg.target_uid == 0 then
        return context.S2C(context.net_id, CmdCode.PBFriendSetNotesRspCmd, {
            code = ErrorCode.ParamInvalid,
            error = "无效请求参数",
            uid = context.uid,
            target_uid = req.msg.target_uid or 0,
        }, req.msg_context.stub_id)
    end

    local friends = scripts.UserModel.GetFriends()
    if not friends then
        return context.S2C(context.net_id, CmdCode["PBFriendSetNotesRspCmd"],
            { code = ErrorCode.ServerInternalError, error = "数据加载出错", uid = context.uid }, req.msg_context.stub_id)
    end

    local success_code = Friend.SetNotes(friends, req.msg.target_uid, req.msg.notes)
    if success_code == 0 then
        return context.S2C(context.net_id, CmdCode["PBFriendSetNotesRspCmd"],
            { code = ErrorCode.FriendNotExist, error = "好友不存在", uid = context.uid, target_uid = req.msg.target_uid or 0 },
            req.msg_context.stub_id)
    end

    Friend.SaveFriendsNow()
    if success_code == 1 then
        Friend.SyncFriends(friends, true, false, false, {})
    else
        Friend.SyncFriends(friends, false, false, true, {})
    end

    return context.S2C(context.net_id, CmdCode["PBFriendSetNotesRspCmd"],
        { code = ErrorCode.None, error = "", uid = context.uid, target_uid = req.msg.target_uid or 0 },
        req.msg_context.stub_id)
end

function Friend.PBFriendCreateGroupReqCmd(req)
    if context.uid ~= req.msg.uid then
        return context.S2C(context.net_id, CmdCode.PBFriendCreateGroupRspCmd, {
            code = ErrorCode.ParamInvalid,
            error = "无效请求参数",
            uid = context.uid,
            group_name = req.msg.group_name or "",
        }, req.msg_context.stub_id)
    end

    local friends = scripts.UserModel.GetFriends()
    if not friends then
        return context.S2C(context.net_id, CmdCode["PBFriendCreateGroupRspCmd"],
            { code = ErrorCode.ServerInternalError, error = "数据加载出错", uid = context.uid }, req.msg_context.stub_id)
    end

    local friend_cfg = GameCfg.FriendConfig[1]
    if not friend_cfg then
        return context.S2C(context.net_id, CmdCode["PBFriendCreateGroupRspCmd"],
            { code = ErrorCode.ConfigError, error = "配置加载出错", uid = context.uid }, req.msg_context.stub_id)
    end
    if table.size(friends.friend_groups) >= friend_cfg.Group_limit then
        return context.S2C(context.net_id, CmdCode["PBFriendCreateGroupRspCmd"],
            { code = ErrorCode.ParamInvalid, error = "超出最大分组数量", uid = context.uid }, req.msg_context.stub_id)
    end

    for group_id, group_name in pairs(friends.friend_groups) do
        if group_name == req.msg.group_name then
            return context.S2C(context.net_id, CmdCode["PBFriendCreateGroupRspCmd"],
                { code = ErrorCode.ParamInvalid, error = "分组名称重复", uid = context.uid }, req.msg_context.stub_id)
        end
    end

    local new_group_id = 0
    for i = 1, friend_cfg.Group_limit do
        if not friends.friend_groups[i] then
            new_group_id = i
            local new_friend_group = FriendDef.newFriendGroupData()
            new_friend_group.group_id = i
            new_friend_group.group_name = req.msg.group_name or ""
            friends.friend_groups[new_friend_group.group_id] = new_friend_group

            break
        end
    end
    Friend.SaveFriendsNow()

    return context.S2C(context.net_id, CmdCode["PBFriendCreateGroupRspCmd"],
        { code = ErrorCode.None, error = "", uid = context.uid, group_id = new_group_id, group_name = req.msg.group_name or
        "" }, req.msg_context.stub_id)
end

function Friend.PBFriendDeleteGroupReqCmd(req)
    if context.uid ~= req.msg.uid
        or req.msg.group_id == 0 then
        return context.S2C(context.net_id, CmdCode.PBFriendDeleteGroupRspCmd, {
            code = ErrorCode.ParamInvalid,
            error = "无效请求参数",
            uid = context.uid,
            group_id = req.msg.group_id or 0,
        }, req.msg_context.stub_id)
    end
    
    local friends = scripts.UserModel.GetFriends()
    if not friends then
        return context.S2C(context.net_id, CmdCode["PBFriendDeleteGroupRspCmd"],
            { code = ErrorCode.ServerInternalError, error = "数据加载出错", uid = context.uid }, req.msg_context.stub_id)
    end

    if req.msg.group_id == FriendDef.DefaultGroupId then
        return context.S2C(context.net_id, CmdCode.PBFriendDeleteGroupRspCmd, {
            code = ErrorCode.ParamInvalid,
            error = "默认分组不能删除",
            uid = context.uid,
            group_id = req.msg.group_id or 0,
        }, req.msg_context.stub_id)
    end

    if not friends.friend_groups[req.msg.group_id] then
        return context.S2C(context.net_id, CmdCode["PBFriendDeleteGroupRspCmd"],
            { code = ErrorCode.ParamInvalid, error = "分组不存在", uid = context.uid }, req.msg_context.stub_id)
    end

    local friend_list = friends.friend_groups[req.msg.group_id].group_friends
    for friend_uid, friend_data in pairs(friend_list) do
        friends.friend_groups[FriendDef.DefaultGroupId].group_friends[friend_uid] = friend_data
    end
    friends.friend_groups[req.msg.group_id] = nil

    Friend.SaveFriendsNow()
    Friend.SaveRelations(friends)
    Friend.SyncFriends(friends, true, false, false, {})

    return context.S2C(context.net_id, CmdCode["PBFriendDeleteGroupRspCmd"],
        { code = ErrorCode.None, error = "", uid = context.uid, group_id = req.msg.group_id or 0 },
        req.msg_context.stub_id)
end

function Friend.PBFriendMoveReqCmd(req)
    if context.uid ~= req.msg.uid
        or req.msg.target_uid == 0
        or req.msg.old_group_id == 0
        or req.msg.new_group_id == 0 then
        return context.S2C(context.net_id, CmdCode.PBFriendMoveRspCmd, {
            code = ErrorCode.ParamInvalid,
            error = "无效请求参数",
            uid = context.uid,
            target_uid = req.msg.target_uid or 0,
            old_group_id = req.msg.old_group_id or 0,
            new_group_id = req.msg.new_group_id or 0,
        }, req.msg_context.stub_id)
    end

    local friends = scripts.UserModel.GetFriends()
    if not friends then
        return context.S2C(context.net_id, CmdCode.PBFriendMoveRspCmd,
            { code = ErrorCode.ServerInternalError, error = "数据加载出错", uid = context.uid }, req.msg_context.stub_id)
    end

    if not friends.friend_groups[req.msg.old_group_id]
        or not friends.friend_groups[req.msg.old_group_id].group_friends[req.msg.target_uid] then
        return context.S2C(context.net_id, CmdCode.PBFriendMoveRspCmd,
            { code = ErrorCode.ParamInvalid, error = "旧分组不存在", uid = context.uid }, req.msg_context.stub_id)
    end

    if not friends.friend_groups[req.msg.new_group_id] then
        return context.S2C(context.net_id, CmdCode.PBFriendMoveRspCmd,
            { code = ErrorCode.ParamInvalid, error = "新分组不存在", uid = context.uid }, req.msg_context.stub_id)
    end

    local friend_data = friends.friend_groups[req.msg.old_group_id].group_friends[req.msg.target_uid]
    friends.friend_groups[req.msg.new_group_id].group_friends[req.msg.target_uid] = friend_data
    friends.friend_groups[req.msg.old_group_id].group_friends[req.msg.target_uid] = nil

    Friend.SaveFriendsNow()
    Friend.SaveRelations(friends)
    Friend.SyncFriends(friends, true, false, false, {})

    return context.S2C(context.net_id, CmdCode.PBFriendMoveRspCmd,
        { code = ErrorCode.None, error = "", uid = context.uid, target_uid = req.msg.target_uid or 0,
            old_group_id = req.msg.old_group_id or 0, new_group_id = req.msg.new_group_id or 0 },
        req.msg_context.stub_id)
end

return Friend