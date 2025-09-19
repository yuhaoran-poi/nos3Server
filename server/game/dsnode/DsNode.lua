local moon = require("moon")
local common = require("common")
local CmdCode = common.CmdCode
local GameCfg = common.GameCfg
local ErrorCode = common.ErrorCode
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
        end

        local isnew = false
        local data = {
                dsid = req.dsid,
                net_id = req.net_id,
                name = req.dsid,
        }

        context.ds_type = req.msg.login_data.ds_type
        context.dsid = req.dsid
        --scripts.UserModel.Create(data)
        ---初始化自己数据
        context.batch_invoke("Init", isnew)
        ---初始化互相引用的数据
        context.batch_invoke("Start")
        return { code = ErrorCode.None, error = "", data = data }
    end

    local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
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


function DsNode.Exit()
    local ok, err = xpcall(scripts.UserModel.Save, debug.traceback)
    if not ok then
        moon.error("user exit save db error", err)
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
    context.S2C(context.net_id, CmdCode.PBPongCmd, ret, req.msg_context.stub_id)
end

function DsNode.PBEnterCityReqCmd(req)
    local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
    local res, err = clusterd.call(3999, "citymgr", "Citymgr.PlayerEnterCity", {
        cityid = req.msg.cityid,
        uid = req.msg.uid,
    })
    local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
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
    local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
    local res, err = clusterd.call(3999, "citymgr", "Citymgr.PlayerExitCity", {
        cityid = req.msg.cityid,
        uid = req.msg.uid,
    })
    local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
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
    local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
    local res, err = clusterd.call(3999, "citymgr", "Citymgr.UpdateCityPlayer", {
        cityid = req.msg.cityid,
        player_num = req.msg.player_num,
    })
    local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
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
    local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
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
    local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
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

function DsNode.PBDsNotifyPlayerEnterReqCmd(req)
    if not req.msg.roomid or not req.msg.uids then
        local ret = {
            code = ErrorCode.CityVerifyFailed,
            error = "no roomid or no uids"
        }
        return context.S2D(context.net_id, CmdCode["PBDsNotifyPlayerEnterRspCmd"], ret, req.msg_context.stub_id)
    end

    context.send_users(req.msg.uids, CmdCode["User.InPlay"], req.msg.roomid)

    local ret = {
        code = ErrorCode.None,
        error = "",
        roomid = req.msg.roomid,
        uids = req.msg.uids,
    }
    return context.S2D(context.net_id, CmdCode["PBDsNotifyPlayerEnterRspCmd"], ret, req.msg_context.stub_id)
end

function DsNode.PBDsNotifyPlayerExitReqCmd(req)
    if not req.msg.roomid or not req.msg.uids then
        local ret = {
            code = ErrorCode.CityVerifyFailed,
            error = "no roomid or no uids"
        }
        return context.S2D(context.net_id, CmdCode["PBDsNotifyPlayerExitRspCmd"], ret, req.msg_context.stub_id)
    end

    context.send_users(req.msg.uids, CmdCode["User.OutPlay"], req.msg.roomid)

    local ret = {
        code = ErrorCode.None,
        error = "",
        roomid = req.msg.roomid,
        uids = req.msg.uids,
    }
    return context.S2D(context.net_id, CmdCode["PBDsNotifyPlayerExitRspCmd"], ret, req.msg_context.stub_id)
end

function DsNode.PBDsNotifyPlayEndReqCmd(req)
    if not req.msg.roomid then
        local ret = {
            code = ErrorCode.CityVerifyFailed,
            error = "no roomid or no uids"
        }
        return context.S2D(context.net_id, CmdCode["PBDsNotifyPlayEndRspCmd"], ret, req.msg_context.stub_id)
    end

    clusterd.send(3999, "roommgr", "Roommgr.PlayEnd", { roomid = req.msg.roomid })
end

return DsNode
