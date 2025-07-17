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
local FriendDef = require("common.def.FriendDef")
local ProtoEnum = require("tools.ProtoEnum")
local UserAttrLogic = require("common.logic.UserAttrLogic")
local jencode = json.encode
local jdecode = json.decode

---@type friendmgr_context
local context = ...

local listenfd
local maxplayers = 10

---@class Friendmgr
local Friendmgr = {}

function Friendmgr.Init()

end

function Friendmgr.Start()
    context.user_relations = {}

    return true
end

function Friendmgr.GetFriendRelation(uids)
    local res = Database.RedisGetFriendRelation(context.addr_db_redis, uids)
    if table.size(res) > 0 then
        for uid, relations in pairs(res) do
            context.user_relations[uid] = relations
        end
    end
end

function Friendmgr.SetFriendRelation(user_relations)
    local need_save = {}
    for uid, relations in pairs(user_relations) do
        context.user_relations[uid] = relations
        need_save[uid] = relations
    end
    if table.size(need_save) > 0 then
        Database.RedisSetFriendRelation(context.addr_db_redis, need_save)
    end
end

function Friendmgr.FriendOnline(uid)
    local relations = Friendmgr.GetRelations(uid)
    if not relations then
        return
    end

    local notify_uids = {}
    for friend_uid, relation_value in pairs(relations) do
        if relation_value >= FriendDef.FriendRelationValue.FriendStart
            and relation_value <= FriendDef.FriendRelationValue.FriendEnd then
            table.insert(notify_uids, friend_uid)
        elseif relation_value == FriendDef.FriendRelationValue.Black then
            table.insert(notify_uids, friend_uid)
        end
    end
    context.send_users(notify_uids, "Friend.OtherOnline", uid)
end

function Friendmgr.FriendOffline(uid)
    local relations = Friendmgr.GetRelations(uid)
    if not relations then
        return
    end

    local notify_uids = {}
    for friend_uid, relation_value in pairs(relations) do
        if relation_value >= FriendDef.FriendRelationValue.FriendStart
            and relation_value <= FriendDef.FriendRelationValue.FriendEnd then
            table.insert(notify_uids, friend_uid)
        elseif relation_value == FriendDef.FriendRelationValue.Black then
            table.insert(notify_uids, friend_uid)
        end
    end
    context.send_users(notify_uids, "Friend.OtherOffline", uid)
end

function Friendmgr.GetRelations(uid)
    if not context.user_relations[uid] then
        Friendmgr.GetFriendRelation({ uid })
    end
    if not context.user_relations[uid] then
        return nil
    else
        return context.user_relations[uid]
    end
end

function Friendmgr.SetRelations(user_relations)
    Friendmgr.SetFriendRelation(user_relations)
end

function Friendmgr.AddApply(data)
    local relations = Friendmgr.GetRelations(data.target_uid)
    if not relations then
        relations = {}
    end

    local friend_cfg = GameCfg.FriendConfig[1]
    if not friend_cfg then
        return ErrorCode.ConfigError
    end

    local relation_value = relations[data.apply_data.uid]
    if relation_value then
        if relation_value >= FriendDef.FriendRelationValue.FriendStart
            and relation_value <= FriendDef.FriendRelationValue.FriendEnd then
            return ErrorCode.FriendInFriendList
        elseif relation_value == FriendDef.FriendRelationValue.Black then
            return ErrorCode.FriendInBlackList
        else
            return ErrorCode.None
        end
    end

    local friend_num = 0
    local apply_num = 0
    for _, value in pairs(relations) do
        if value >= FriendDef.FriendRelationValue.FriendStart
            and value <= FriendDef.FriendRelationValue.FriendEnd then
            friend_num = friend_num + 1
        elseif value == FriendDef.FriendRelationValue.Apply then
            apply_num = apply_num + 1
        end
    end
    if friend_num >= friend_cfg.Friend_limit then
        return ErrorCode.FriendLimit
    end
    if apply_num >= friend_cfg.apply_limit then
        return ErrorCode.FriendApplyLimit
    end

    local query_field = {
        ProtoEnum.UserAttrType.is_online,
    }
    local user_attr = UserAttrLogic.QueryOtherUserAttr(context, data.target_uid, query_field)
    if not user_attr or not user_attr[ProtoEnum.UserAttrType.is_online] then
        return ErrorCode.UserNotExist
    end
    if user_attr[ProtoEnum.UserAttrType.is_online] == 1 then
        context.send_user(data.target_uid, "Friend.OtherApplyFriend", data.apply_data)
    end

    relations[data.apply_data.uid] = FriendDef.FriendRelationValue.Apply

    local save_relastions = {}
    save_relastions[data.target_uid] = relations
    Friendmgr.SetRelations(save_relastions)

    return ErrorCode.None
end

function Friendmgr.AgreeApply(data)
    local relations_apply = Friendmgr.GetRelations(data.apply_uid)
    if not relations_apply then
        relations_apply = {}
    end

    local friend_cfg = GameCfg.FriendConfig[1]
    if not friend_cfg then
        return ErrorCode.ConfigError
    end

    local relation_value = relations_apply[data.from_uid]
    if relation_value then
        if relation_value >= FriendDef.FriendRelationValue.FriendStart
            and relation_value <= FriendDef.FriendRelationValue.FriendEnd then
            return ErrorCode.None
        elseif relation_value == FriendDef.FriendRelationValue.Black then
            return ErrorCode.FriendInBlackList
        end
    end

    local friend_num = 0
    for _, value in pairs(relations_apply) do
        if value >= FriendDef.FriendRelationValue.FriendStart
            and value <= FriendDef.FriendRelationValue.FriendEnd then
            friend_num = friend_num + 1
        end
    end
    if friend_num >= friend_cfg.Friend_limit then
        return ErrorCode.FriendLimit
    end

    local query_field = {
        ProtoEnum.UserAttrType.is_online,
    }
    local user_attr = UserAttrLogic.QueryOtherUserAttr(context, data.target_uid, query_field)
    if not user_attr or not user_attr[ProtoEnum.UserAttrType.is_online] then
        return ErrorCode.UserNotExist
    end
    if user_attr[ProtoEnum.UserAttrType.is_online] == 1 then
        context.send_user(data.apply_uid, "Friend.OtherAddFriend", data.from_uid)
    end

    local save_relastions = {}
    relations_apply[data.from_uid] = FriendDef.FriendRelationValue.FriendStart
    save_relastions[data.apply_uid] = relations_apply

    local relations_from = Friendmgr.GetRelations(data.from_uid)
    if not relations_from then
        relations_from = {}
    end
    relations_from[data.apply_uid] = FriendDef.FriendRelationValue.FriendStart
    save_relastions[data.from_uid] = relations_from

    Friendmgr.SetRelations(save_relastions)
    return ErrorCode.None
end

function Friendmgr.RefuseApply(data)
    local relations_from = Friendmgr.GetRelations(data.from_uid)
    if not relations_from then
        relations_from = {}
    end

    if not relations_from[data.apply_uid]
        or relations_from[data.apply_uid] ~= FriendDef.FriendRelationValue.Apply then
        return
    end

    local query_field = {
        ProtoEnum.UserAttrType.is_online,
    }
    local user_attr = UserAttrLogic.QueryOtherUserAttr(context, data.target_uid, query_field)
    if user_attr and user_attr[ProtoEnum.UserAttrType.is_online] == 1 then
        context.send_user(data.apply_uid, "Friend.OtherRefuseFriend", data.from_uid)
    end

    local save_relastions = {}
    relations_from[data.apply_uid] = nil
    save_relastions[data.from_uid] = relations_from

    Friendmgr.SetRelations(save_relastions)
end

function Friendmgr.DelFriend(data)
    local relations_from = Friendmgr.GetRelations(data.from_uid)
    if not relations_from then
        relations_from = {}
    end
    if relations_from[data.del_uid]
        and relations_from[data.del_uid] >= FriendDef.FriendRelationValue.FriendStart
        and relations_from[data.del_uid] <= FriendDef.FriendRelationValue.FriendEnd then
        relations_from[data.del_uid] = nil
    end
    local relations_del = Friendmgr.GetRelations(data.del_uid)
    if not relations_del then
        relations_del = {}
    end
    if relations_del[data.from_uid]
        and relations_del[data.from_uid] >= FriendDef.FriendRelationValue.FriendStart
        and relations_del[data.from_uid] <= FriendDef.FriendRelationValue.FriendEnd then
        relations_del[data.from_uid] = nil

        local query_field = {
            ProtoEnum.UserAttrType.is_online,
        }
        local user_attr = UserAttrLogic.QueryOtherUserAttr(context, data.target_uid, query_field)
        if user_attr and user_attr[ProtoEnum.UserAttrType.is_online] == 1 then
            context.send_user(data.apply_uid, "Friend.OtherDelFriend", data.from_uid)
        end
    end

    local save_relastions = {}
    save_relastions[data.from_uid] = relations_from
    save_relastions[data.del_uid] = relations_del
    Friendmgr.SetRelations(save_relastions)
end

function Friendmgr.AddBlack(data)
    local relations_from = Friendmgr.GetRelations(data.from_uid)
    if not relations_from then
        relations_from = {}
    end
    relations_from[data.black_uid] = FriendDef.FriendRelationValue.Black

    local save_relastions = {}
    save_relastions[data.from_uid] = relations_from
    Friendmgr.SetRelations(save_relastions)
end

function Friendmgr.DelBlack(data)
    local relations_from = Friendmgr.GetRelations(data.from_uid)
    if not relations_from then
        relations_from = {}
    end
    relations_from[data.black_uid] = nil

    local save_relastions = {}
    save_relastions[data.from_uid] = relations_from
    Friendmgr.SetRelations(save_relastions)
end

function Friendmgr.Shutdown()
    -- for _, n in pairs(context.rooms) do
    --     socket.close(n.fd)
    -- end
    if listenfd then
        socket.close(listenfd)
    end
    moon.quit()
    return true
end

return Friendmgr
