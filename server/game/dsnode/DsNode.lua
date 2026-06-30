local moon = require("moon")
local common = require("common")
local CmdCode = common.CmdCode
local GameCfg = common.GameCfg
local ErrorCode = common.ErrorCode
local Database = common.Database
local clusterd = require("cluster")
local json = require "json"
local UserAttrLogic = require("common.logic.UserAttrLogic")

---@type user_context
local context = ...
local scripts = context.scripts

--- 内存中的状态
local state = { 
    online = false,
    ismatching = false
}
---@class DsNode
local DsNode = {}
function DsNode.Load(req)
    local function fn()
        --local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
        if req.msg.login_data.ds_type == 1 then
            local res, err = clusterd.call(3999, "citymgr", "Citymgr.ConnectCity", {
                cityid = req.dsid,
                nid = moon.env("NODE"),
                addr_dsnode = req.addr_dsnode,
            })
            if err or res.code ~= ErrorCode.None then
                return res
            end
        else
            -- 暂时采用与city不同的处理方式
            clusterd.send(3999, "roommgr", "Roommgr.ConnectRoomDS", {
                roomid = req.dsid,
                nid = moon.env("NODE"),
                addr_dsnode = req.addr_dsnode,
            })
        end

        local isnew = false
        local data = {
            dsid = req.dsid,
            net_id = req.net_id,
            name = req.dsid,
        }

        context.ds_type = req.msg.login_data.ds_type
        context.dsid = req.dsid
        context.addr_dsnode = req.addr_dsnode
        --scripts.UserModel.Create(data)
        ---初始化自己数据
        context.batch_invoke("Init", isnew)
        ---初始化互相引用的数据
        context.batch_invoke("Start")
        return { code = ErrorCode.None, error = "", data = data }
    end

    -- local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
    local ok, res = xpcall(fn, debug.traceback, req)
    if not ok then
        return ok, res
    end

    if not res or res.code ~= ErrorCode.None then
        local errmsg = string.format("ds init failed, can not find ds %d", req.dsid)
        moon.error(errmsg)
        return false, errmsg
    end

    context.net_id = res.data.net_id
    return true
end

function DsNode.Login(req)
    if state.online then
        context.batch_invoke("Offline")
    end
    context.batch_invoke("Online")

    return context.dsid
    --return scripts.UserModel.Get().openid
end

function DsNode.Logout()
    context.batch_invoke("Offline")
    return true
end

function DsNode.Init()
    GameCfg.Load()
end

function DsNode.Start()

end

function DsNode.Online()
    state.online = true
    --scripts.UserModel.MutGet().logintime = moon.time()
end

function DsNode.Offline()
    if not state.online then
        return
    end

    print(context.net_id, "offline")
    state.online = false

	if state.ismatching then
        state.ismatching = false
        moon.send("lua", context.addr_center, "Center.UnMatch", context.net_id)
    end
end

-- local ok, err = xpcall(scripts.UserModel.Save, debug.traceback)
-- if not ok then
--     moon.error("user exit save db error", err)
-- end

-- -- 退出房间
-- scripts.Room.ForceExitRoom()
-- -- 退出游戏中的副本ds(如果有的话)
-- User.ExitPlayDs()

-- -- 同步离线状态到redis
-- local update_user_attr = {}
-- update_user_attr[ProtoEnum.UserAttrType.is_online] = UserAttrDef.ONLINE_STATE.OFFLINE
-- User.SetUserAttr(update_user_attr, false)

-- User.Logout()

-- -- 通知usermgr
-- local res, err = clusterd.call(3999, "usermgr", "Usermgr.NotifyLogout", { uid = context.uid, nid = moon.env("NODE") })
-- if err then
--     moon.error(string.format("User.Exit err = %s", json.pretty_encode(err)))
-- end
-- if res.error ~= "success" then
--     moon.error(string.format("User.Exit res = %s", json.pretty_encode(res)))
-- end

-- moon.quit()
-- return true
function DsNode.Exit()
    -- 如果是副本则通知RoomMgr
    if context.dsid > 10000 then
        clusterd.send(3999, "roommgr", "Roommgr.PlayEnd",
            { roomid = context.dsid, nid = moon.env("NODE"), addr_dsnode = context.addr_dsnode })
    else
        clusterd.send(3999, "citymgr", "Citymgr.SetCityDestroy", context.dsid)
    end

    moon.quit()
    return true
end

function DsNode.C2SPing(req)
    req.stime = moon.time()
    context.S2C(CmdCode.S2CPong, req)
end

function DsNode.PBPingCmd(req)
    local ret =
    {
        time = req.msg.time
    }
    context.S2D(context.net_id, CmdCode.PBPongCmd, ret, req.msg_context.stub_id)
end

function DsNode.PBEnterCityReqCmd(req)
    -- local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
    local res, err = clusterd.call(3999, "citymgr", "Citymgr.PlayerEnterCity", {
        cityid = req.msg.cityid,
        uid = req.msg.uid,
    })
    -- local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
    if not err and res then
        local ret = {
            code = res.code,
            error = res.error,
        }
        context.S2D(context.net_id, CmdCode["PBEnterCityRspCmd"], ret, req.msg_context.stub_id) -- body
    else
        --moon.error(err)
        moon.error(string.format("err = %s", json.pretty_encode(res)))
    end
end

function DsNode.PBExitCityReqCmd(req)
    -- local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
    local res, err = clusterd.call(3999, "citymgr", "Citymgr.PlayerExitCity", {
        cityid = req.msg.cityid,
        uid = req.msg.uid,
    })
    -- local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
    if not err and res then
        local ret = {
            code = res.code,
            error = res.error,
        }
        context.S2D(context.net_id, CmdCode["PBExitCityRspCmd"], ret, req.msg_context.stub_id) -- body
    else
        --moon.error(err)
        moon.error(string.format("err = %s", json.pretty_encode(res)))
    end
end

function DsNode.PBUpdateCityReqCmd(req)
    -- local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
    local res, err = clusterd.call(3999, "citymgr", "Citymgr.UpdateCityPlayer", {
        cityid = req.msg.cityid,
        player_num = req.msg.player_num,
    })
    -- local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
    if not err and res then
        local ret = {
            code = res.code,
            error = res.error,
        }
        context.S2D(context.net_id, CmdCode["PBUpdateCityRspCmd"], ret, req.msg_context.stub_id) -- body
    else
        --moon.error(err)
        moon.error(string.format("err = %s", json.pretty_encode(res)))
    end
end

function DsNode.PBAddItemsCityPlayerReqCmd(req)
    -- 暂时省略校验，直接转发给玩家
    local res, err = context.call_user(req.msg.uid, "User.DsAddItems", req.msg.simple_items)
    -- local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
    if err then
        moon.error(string.format("err = %s", json.pretty_encode(err)))
    end

    context.S2D(context.net_id, CmdCode["PBAddItemsCityPlayerRspCmd"], { code = res }, req.msg_context.stub_id)
end

function DsNode.PBGetDsUserAttrReqCmd(req)
    if not req.msg.dsid or not req.msg.quest_uid then
        local ret = {
            code = ErrorCode.CityVerifyFailed,
            error = "no cityid"
        }
        context.S2D(context.net_id, CmdCode["PBGetDsUserAttrRspCmd"], ret, req.msg_context.stub_id)

        return
    end

    local ret = {
        code = ErrorCode.None,
        error = "",
        dsid = req.msg.dsid,
        quest_uid = req.msg.quest_uid,
    }
    local ret_attr = UserAttrLogic.GetOtherUserAttr(context, req.msg.quest_uid)
    if not ret_attr then
        ret.code = ErrorCode.UserOffline
        context.S2D(context.net_id, CmdCode["PBGetDsUserAttrRspCmd"], ret, req.msg_context.stub_id)
    else
        ret.info = ret_attr
        context.S2D(context.net_id, CmdCode["PBGetDsUserAttrRspCmd"], ret, req.msg_context.stub_id)
    end
end

function DsNode.PBGetDsUserBagsReqCmd(req)
    -- local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
    if not req.msg.dsid or not req.msg.quest_uid then
        local ret = {
            code = ErrorCode.CityVerifyFailed,
            error = "no cityid"
        }
        return context.S2D(context.net_id, CmdCode["PBGetDsUserBagsRspCmd"], ret, req.msg_context.stub_id)
    end

    local res, err = context.call_user(req.msg.quest_uid, "Bag.GetBagdata", req.msg.bags_name)
    if not res then
        moon.error("GetDsUserBags failed:", err)
        local ret = {
            code = ErrorCode.UserOffline,
            error = "no user"
        }
        return context.S2D(context.net_id, CmdCode["PBGetDsUserBagsRspCmd"], ret, req.msg_context.stub_id)
    end

    local ret = {
        code = res.errcode,
        error = "",
        dsid = context.dsid,
        quest_uid = req.msg.quest_uid,
    }
    if res.bag_datas and table.size(res.bag_datas) >= 0 then
        ret.bag_datas = res.bag_datas
        return context.S2D(context.net_id, CmdCode["PBGetDsUserBagsRspCmd"], ret, req.msg_context.stub_id)
    else
        ret.code = res.errcode
        return context.S2D(context.net_id, CmdCode["PBGetDsUserBagsRspCmd"], ret, req.msg_context.stub_id)
    end
end

function DsNode.PBGetDsUserRolesReqCmd(req)
    if not req.msg.dsid
        or not req.msg.quest_uid
        or not req.msg.roleids
        or table.size(req.msg.roleids) <= 0 then
        local ret = {
            code = ErrorCode.CityVerifyFailed,
            error = "no cityid"
        }
        return context.S2D(context.net_id, CmdCode["PBGetDsUserRolesRspCmd"], ret, req.msg_context.stub_id)
    end

    local res, err = context.call_user(req.msg.quest_uid, "Role.GetRolesInfo", req.msg.roleids)
    if not res then
        moon.error("GetDsUserRoles failed:", err)
        local ret = {
            code = ErrorCode.UserOffline,
            error = "no user"
        }
        return context.S2D(context.net_id, CmdCode["PBGetDsUserRolesRspCmd"], ret, req.msg_context.stub_id)
    end

    local ret = {
        code = res.errcode,
        error = "",
        dsid = context.dsid,
        quest_uid = req.msg.quest_uid,
    }
    if res.roles_info and table.size(res.roles_info) >= 0 then
        ret.role_datas = res.roles_info
        return context.S2D(context.net_id, CmdCode["PBGetDsUserRolesRspCmd"], ret, req.msg_context.stub_id)
    else
        ret.code = res.errcode
        return context.S2D(context.net_id, CmdCode["PBGetDsUserRolesRspCmd"], ret, req.msg_context.stub_id)
    end
end

function DsNode.PBGetDsCreateDataReqCmd(req)
    if not req.msg.roomid then
        local ret = {
            code = ErrorCode.CityVerifyFailed,
            error = "no roomid"
        }
        context.S2D(context.net_id, CmdCode["PBGetDsCreateDataRspCmd"], ret, req.msg_context.stub_id)

        return
    end

    local res, err = clusterd.call(3999, "roommgr", "Roommgr.GetRoomCreateData", {
        roomid = req.msg.roomid,
    })
    if res then
        moon.warn(string.format("res = %s", json.pretty_encode(res)))
    end
    if err then
        moon.warn(string.format("err = %s", json.pretty_encode(err)))
    end
    if res.code == ErrorCode.None then
        local ret = {
            code = res.code,
            error = res.error,
            roomid = req.msg.roomid,
            room_str = res.room_str,
        }
        context.S2D(context.net_id, CmdCode["PBGetDsCreateDataRspCmd"], ret, req.msg_context.stub_id)
    else
        local ret = {
            code = res.code,
            error = res.error,
            roomid = req.msg.roomid,
        }
        context.S2D(context.net_id, CmdCode["PBGetDsCreateDataRspCmd"], ret, req.msg_context.stub_id)
    end
end

function DsNode.PBGetDsUserImageReqCmd(req)
    if not req.msg.dsid or not req.msg.quest_uid then
        local ret = {
            code = ErrorCode.CityVerifyFailed,
            error = "no cityid"
        }
        return context.S2D(context.net_id, CmdCode["PBGetDsUserImageRspCmd"], ret, req.msg_context.stub_id)
    end

    local res, err = context.call_user(req.msg.quest_uid, "ItemImage.GetImagesInfo")
    if not res then
        moon.error("GetDsUserRoles failed:", err)
        local ret = {
            code = ErrorCode.UserOffline,
            error = "no user"
        }
        return context.S2D(context.net_id, CmdCode["PBGetDsUserImageRspCmd"], ret, req.msg_context.stub_id)
    end

    --moon.warn(string.format("GetImagesInfo res = %s", json.pretty_encode(res)))

    local ret = {
        code = res.errcode,
        error = "",
        dsid = context.dsid,
        quest_uid = req.msg.quest_uid,
    }
    if res.errcode == ErrorCode.None and res.image_data then
        ret.image_data = res.image_data
        --moon.warn(string.format("GetImagesInfo ret = %s", json.pretty_encode(ret)))
        return context.S2D(context.net_id, CmdCode["PBGetDsUserImageRspCmd"], ret, req.msg_context.stub_id)
    else
        return context.S2D(context.net_id, CmdCode["PBGetDsUserImageRspCmd"], ret, req.msg_context.stub_id)
    end
end

function DsNode.CheckUserOnlineInfo(uids)
    local now_ts = moon.time()
    local need_query = false
    for _, uid in pairs(uids) do
        if not context.uid_addr_map[uid]
            or context.uid_addr_map[uid].node == 0
            or context.uid_addr_map[uid].addr_user == 0
            or now_ts - context.uid_addr_map[uid].get_ts > 60 then
            need_query = true
            break
        end
    end

    if need_query then
        --查询在线用户列表
        local online_uids, err = clusterd.call(3999, "usermgr", "Usermgr.getOnlineUsers", uids)
        if not online_uids then
            moon.error(err)
        end
        --更新uid_addr_map
        for uid, info in pairs(online_uids) do
            local node, addr_user = info.nid, info.addr_user
            if node ~= 0 or addr_user ~= 0 then
                context.uid_addr_map[uid] = {
                    node = info.nid,
                    addr_user = info.addr_user,
                    get_ts = now_ts,
                }
            end
        end
    end

    local offline_uids = {}
    for _, uid in pairs(uids) do
        if not context.uid_addr_map[uid]
            or context.uid_addr_map[uid].node == 0
            or context.uid_addr_map[uid].addr_user == 0 then
            table.insert(offline_uids, uid)
        end
    end
    if table.size(offline_uids) > 0 then
        return false, offline_uids
    end

    return true
end

function DsNode.ExitPlayDs(uid)
    if not context.uid_addr_map[uid] then
        return
    end

    context.S2D(context.net_id, CmdCode["PBNotifyDsPlayerOffSyncCmd"], { uid = uid }, 0)
    context.uid_addr_map[uid] = nil
end

function DsNode.PBDsNotifyPlayerEnterReqCmd(req)
    if not req.msg.roomid or not req.msg.uids then
        local ret = {
            code = ErrorCode.CityVerifyFailed,
            error = "no roomid or no uids"
        }
        return context.S2D(context.net_id, CmdCode["PBDsNotifyPlayerEnterRspCmd"], ret, req.msg_context.stub_id)
    end

    local success, offline_uids = DsNode.CheckUserOnlineInfo(req.msg.uids)
    if not success then
        local ret = {
            code = ErrorCode.UserOffline,
            error = "user offline",
            uids = offline_uids,
        }
        return context.S2D(context.net_id, CmdCode["PBDsNotifyPlayerEnterRspCmd"], ret, req.msg_context.stub_id)
    end

    --遍历在线用户列表，发送消息
    local mine_node = math.tointeger(moon.env("NODE"))
    for _, uid in pairs(req.msg.uids) do
        if context.uid_addr_map[uid] then
            local node, addr_user = context.uid_addr_map[uid].node, context.uid_addr_map[uid].addr_user
            if node ~= 0 or addr_user ~= 0 then
                if mine_node == node then
                    moon.send("lua", addr_user, "User.InPlay",
                        { ds_node = mine_node, ds_addr = context.addr_dsnode, roomid = req.msg.roomid })
                else
                    clusterd.send(node, addr_user, "User.InPlay", {ds_node = mine_node, ds_addr = context.addr_dsnode, roomid = req.msg.roomid})
                end
            else
                moon.warn("send_user User.InPlay failed, node = ", node, " uid= ", uid, "addr_user = ", addr_user)
            end
        end
    end

    local ret = {
        code = ErrorCode.None,
        error = "",
        roomid = req.msg.roomid,
        uids = req.msg.uids,
    }
    return context.S2D(context.net_id, CmdCode["PBDsNotifyPlayerEnterRspCmd"], ret, req.msg_context.stub_id)
end

function DsNode.PBDsNotifyPlayerExitReqCmd(req)
    local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
    if not req.msg.roomid or not req.msg.uid then
        local ret = {
            code = ErrorCode.CityVerifyFailed,
            error = "no roomid or no uid"
        }
        return context.S2D(context.net_id, CmdCode["PBDsNotifyPlayerExitRspCmd"], ret, req.msg_context.stub_id)
    end

    local success, offline_uids = DsNode.CheckUserOnlineInfo({req.msg.uid})
    if not success then
        moon.warn(string.format("PBDsNotifyPlayerExitReqCmd user offline, uid = %s", json.pretty_encode(offline_uids)))
    end

    local mine_node = math.tointeger(moon.env("NODE"))
    local node, addr_user = 0, 0
    if context.uid_addr_map[req.msg.uid] then
        node, addr_user = context.uid_addr_map[req.msg.uid].node, context.uid_addr_map[req.msg.uid].addr_user
    end

    --寻找在线用户列表，发送消息
    if node ~= 0 or addr_user ~= 0 then
        local send_data = {
            roomid = req.msg.roomid,
            need_exit_room = false,
            -- need_settle = req.msg.need_settle,
            -- player_settle = req.msg.player_settle,
        }
        if req.msg.need_settle and req.msg.need_settle == 1 then
            send_data.need_exit_room = true
        end
        if mine_node == node then
            moon.send("lua", addr_user, "User.OutPlay", send_data)
        else
            clusterd.send(node, addr_user, "User.OutPlay", send_data)
        end
    else
        moon.warn("send_user User.OutPlay failed, node = ", node, " uid= ", req.msg.uid, "addr_user = ", addr_user)
    end

    -- 往数据库中写入结算信息并通知User
    if req.msg.need_settle and req.msg.need_settle == 1 then
        moon.warn(string.format("PBDsNotifyPlayerExitReqCmd settle uid = %d, player_settle = %s", req.msg.uid, json.pretty_encode(req.msg.player_settle)))
        Database.BattleListPushRight(context.addr_db_redis, Database.GetBattleSettleKey(), req.msg.uid,
            req.msg.player_settle)

        if node ~= 0 or addr_user ~= 0 then
            if mine_node == node then
                moon.send("lua", addr_user, "User.NotifyGameSettle")
            else
                clusterd.send(node, addr_user, "User.NotifyGameSettle")
            end
        end
    end

    context.uid_addr_map[req.msg.uid] = nil

    local ret = {
        code = ErrorCode.None,
        error = "",
        roomid = req.msg.roomid,
        uid = req.msg.uid,
    }
    return context.S2D(context.net_id, CmdCode["PBDsNotifyPlayerExitRspCmd"], ret, req.msg_context.stub_id)
end

function DsNode.PBDsNotifyPlayEndReqCmd(req)
    moon.warn("PBDsNotifyPlayEndReqCmd roomid = ", req.msg.roomid)
    if not req.msg.roomid then
        moon.error("PBDsNotifyPlayEndReqCmd no roomid")
        local ret = {
            code = ErrorCode.CityVerifyFailed,
            error = "no roomid or no uids"
        }
        return context.S2D(context.net_id, CmdCode["PBDsNotifyPlayEndRspCmd"], ret, req.msg_context.stub_id)
    end

    -- 先往数据库中写入结算信息
    if req.msg.need_settle == 1 then
        for uid, settle_info in pairs(req.msg.players_settle) do
            moon.warn(string.format("PBDsNotifyPlayEndReqCmd settle uid = %d, settle_info = %s", uid, json.pretty_encode(settle_info)))
            Database.BattleListPushRight(context.addr_db_redis, Database.GetBattleSettleKey(), uid, settle_info)
        end
    end

    clusterd.send(3999, "roommgr", "Roommgr.PlayEnd",
        { roomid = req.msg.roomid, nid = moon.env("NODE"), addr_dsnode = context.addr_dsnode })

    local ret = {
        code = ErrorCode.None,
        error = "success end"
    }
    return context.S2D(context.net_id, CmdCode["PBDsNotifyPlayEndRspCmd"], ret, req.msg_context.stub_id)
end

function DsNode.PBGetDsUserBattleGodsReqCmd(req)
    if not req.msg.dsid
        or not req.msg.quest_uid then
        local ret = {
            code = ErrorCode.CityVerifyFailed,
            error = "no dsid or no quest_uid"
        }
        return context.S2D(context.net_id, CmdCode.PBGetDsUserBattleGodsRspCmd, ret, req.msg_context.stub_id)
    end

    local res, err = context.call_user(req.msg.quest_uid, "Gods.GetBattleGods")
    if not res then
        moon.error("GetDsUserBattleGods failed:", err)
        local ret = {
            code = ErrorCode.UserOffline,
            error = "no user"
        }
        return context.S2D(context.net_id, CmdCode.PBGetDsUserBattleGodsRspCmd, ret, req.msg_context.stub_id)
    end

    local ret = {
        code = res.errcode,
        error = "",
        dsid = context.dsid,
        quest_uid = req.msg.quest_uid,
        gods_info = res,
    }
    return context.S2D(context.net_id, CmdCode.PBGetDsUserBattleGodsRspCmd, ret, req.msg_context.stub_id)
end

function DsNode.PBDsNotifyRemainItemsReqCmd(req)
    if not req.msg.roomid or not req.msg.belong_uid or not req.msg.remain_items then
        local ret = {
            code = ErrorCode.CityVerifyFailed,
            error = "no roomid or no belong_uid or no remain_items"
        }
        return context.S2D(context.net_id, CmdCode.PBDsNotifyRemainItemsRspCmd, ret, req.msg_context.stub_id)
    end

    -- 先往数据库中写入退还信息
    if table.size(req.msg.remain_items) > 0 then
        Database.BattleListPushRight(context.addr_db_redis, Database.GetBattleReturnKey(), req.msg.belong_uid,
            req.msg.remain_items)

        local mine_node = math.tointeger(moon.env("NODE"))
        if context.uid_addr_map[req.msg.belong_uid] then
            local node, addr_user = context.uid_addr_map[req.msg.belong_uid].node,
            context.uid_addr_map[req.msg.belong_uid].addr_user
            if mine_node == node then
                moon.send("lua", addr_user, "User.NotifyGameReturnItems")
            else
                clusterd.send(node, addr_user, "User.NotifyGameReturnItems")
            end
        end
    end
    local ret = {
        code = ErrorCode.None,
        error = "",
    }
    return context.S2D(context.net_id, CmdCode.PBDsNotifyRemainItemsRspCmd, ret, req.msg_context.stub_id)
end

function DsNode.PBGetDsUserAntiqueReqCmd(req)
    if not req.msg.dsid or not req.msg.quest_uid then
        local ret = {
            code = ErrorCode.CityVerifyFailed,
            error = "no cityid"
        }
        return context.S2D(context.net_id, CmdCode["PBGetDsUserAntiqueRspCmd"], ret, req.msg_context.stub_id)
    end

    local res, err = context.call_user(req.msg.quest_uid, "AntiqueShowcase.GetAntiqueShowcaseInfo")
    if not res then
        moon.error("GetDsUserRoles failed:", err)
        local ret = {
            code = ErrorCode.UserOffline,
            error = "no user"
        }
        return context.S2D(context.net_id, CmdCode["PBGetDsUserAntiqueRspCmd"], ret, req.msg_context.stub_id)
    end

    --moon.warn(string.format("GetImagesInfo res = %s", json.pretty_encode(res)))

    local ret = {
        code = res.errcode,
        error = "",
        dsid = context.dsid,
        quest_uid = req.msg.quest_uid,
    }
    if res.errcode == ErrorCode.None and res.antique_showcase_data then
        ret.antique_showcase_data = res.antique_showcase_data
        --moon.warn(string.format("GetImagesInfo ret = %s", json.pretty_encode(ret)))
        return context.S2D(context.net_id, CmdCode["PBGetDsUserAntiqueRspCmd"], ret, req.msg_context.stub_id)
    else
        return context.S2D(context.net_id, CmdCode["PBGetDsUserAntiqueRspCmd"], ret, req.msg_context.stub_id)
    end
end

function DsNode.PBDsGetAllYesAveragePriceReqCmd(req)
    if not req.msg.dsid then
        local ret = {
            code = ErrorCode.CityVerifyFailed,
            error = "no cityid"
        }
        return context.S2D(context.net_id, CmdCode.PBDsGetAllYesAveragePriceRspCmd, ret, req.msg_context.stub_id)
    end

    local start_config_id = 0
    local id_price_list = {}
    while true do
        local records = Database.gettraderecordaveragepriceseq(context.addr_db_user, start_config_id, 1000)
        if not records or table.size(records) <= 0 then
            moon.error("Trademgr.Start gettraderecordaveragepriceseq failed", start_config_id, 1000)
            break
        end
        for id, price in pairs(records) do
            if id > start_config_id then
                start_config_id = id
            end
            id_price_list[id] = price
        end

        if table.size(records) < 1000 then
            break
        end
    end

    --moon.warn(string.format("GetImagesInfo res = %s", json.pretty_encode(res)))

    local ret = {
        code = ErrorCode.None,
        error = "",
        dsid = context.dsid,
        id_price_list = id_price_list,
    }
    return context.S2D(context.net_id, CmdCode.PBDsGetAllYesAveragePriceRspCmd, ret, req.msg_context.stub_id)
end

-- 获取玩家账户buff数据
function DsNode.PBGetDsUserAccountBuffReqCmd(req)
    if not req.msg.dsid or not req.msg.quest_uid then
        local ret = {
            code = ErrorCode.CityVerifyFailed,
            error = "param error",
            dsid = req.msg.dsid,
            quest_uid = req.msg.quest_uid,
        }
        return context.S2D(context.net_id, CmdCode.PBGetDsUserAccountBuffRspCmd, ret, req.msg_context.stub_id)
    end

    local buff_datas, err = context.call_user(req.msg.quest_uid, "User.GetAccountBuff")
    if not buff_datas then
        moon.error("PBGetDsUserAccountBuffReqCmd failed:", err)
        local ret = {
            code = err or ErrorCode.ServerInternalError,
            error = tostring(err),
            dsid = req.msg.dsid,
            quest_uid = req.msg.quest_uid,
        }
        return context.S2D(context.net_id, CmdCode.PBGetDsUserAccountBuffRspCmd, ret, req.msg_context.stub_id)
    end

    local ret = {
        code = ErrorCode.None,
        error = "",
        dsid = req.msg.dsid,
        quest_uid = req.msg.quest_uid,
        buff_datas = buff_datas,
    }
    return context.S2D(context.net_id, CmdCode.PBGetDsUserAccountBuffRspCmd, ret, req.msg_context.stub_id)
end

-- 获取玩家镇山之宝数据
function DsNode.PBGetDsUserAweItemReqCmd(req)
    if not req.msg.dsid or not req.msg.quest_uid then
        local ret = {
            code = ErrorCode.CityVerifyFailed,
            error = "param error",
            dsid = req.msg.dsid,
            quest_uid = req.msg.quest_uid,
        }
        return context.S2D(context.net_id, CmdCode.PBGetDsUserAweItemRspCmd, ret, req.msg_context.stub_id)
    end

    local res, err = context.call_user(req.msg.quest_uid, "AweItem.GetAweItemInfo")
    if not res then
        moon.error("PBGetDsUserAweItemReqCmd failed:", err)
        local ret = {
            code = err or ErrorCode.ServerInternalError,
            error = tostring(err),
            dsid = req.msg.dsid,
            quest_uid = req.msg.quest_uid,
        }
        return context.S2D(context.net_id, CmdCode.PBGetDsUserAweItemRspCmd, ret, req.msg_context.stub_id)
    end

    local ret = {
        code = ErrorCode.None,
        error = "",
        dsid = req.msg.dsid,
        quest_uid = req.msg.quest_uid,
        awe_items = res,
    }
    return context.S2D(context.net_id, CmdCode.PBGetDsUserAweItemRspCmd, ret, req.msg_context.stub_id)
end

return DsNode
