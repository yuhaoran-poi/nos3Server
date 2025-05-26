local moon = require("moon")
local common = require("common")
local CmdCode = common.CmdCode
local GameCfg = common.GameCfg
local ErrorCode = common.ErrorCode
local clusterd = require("cluster")
local json = require "json"

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
                return false, err
            end
        end

        local isnew = false
        local data = {
                dsid = req.dsid,
                net_id = req.net_id,
                name = req.dsid,
        }

        context.dsid = req.dsid
        --scripts.UserModel.Create(data)
        ---初始化自己数据
        context.batch_invoke("Init", isnew)
        ---初始化互相引用的数据
        context.batch_invoke("Start")
        return data
    end

    local ok, res = xpcall(fn, debug.traceback, req)
    if not ok then
        return ok, res
    end

    if not res then
        local errmsg = string.format("ds init failed, can not find ds %d", req.dsid)
        moon.error(errmsg)
        return false, errmsg
    end

    context.net_id = res.net_id
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

return DsNode
