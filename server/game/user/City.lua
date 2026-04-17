local moon = require("moon")
local common = require("common")
local clusterd = require("cluster")
local json = require "json"
local CmdCode = common.CmdCode
local GameCfg = common.GameCfg
local Database = common.Database
local protocol = common.protocol
local ErrorCode = common.ErrorCode

---@type user_context
local context = ...
local scripts = context.scripts

---@class City
local City = {}

function City.PBApplyLoginCityReqCmd(req)
    -- if context.cityid then
    --     return context.S2C(context.net_id, CmdCode["PBApplyLoginCityRspCmd"], {
    --         code = ErrorCode.CityAlreadyInCity,
    --         error = "你已在主城中",
    --     }, req.msg_context.stub_id)
    -- end

    local res, err = clusterd.call(3999, "citymgr", "Citymgr.ApplyLoginToCity", {
        msg = req.msg,
    })
    --local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
    if err then
        return context.S2C(context.net_id, CmdCode["PBApplyLoginCityRspCmd"], {
            code = ErrorCode.ServerInternalError,
            error = "system error",
        }, req.msg_context.stub_id)
    end

    return context.S2C(context.net_id, CmdCode["PBApplyLoginCityRspCmd"], res, req.msg_context.stub_id)
end

function City.PBApplySwitchCityReqCmd(req)
    -- 参数验证
    if not req.msg.uid or not req.msg.cityid then
        return context.S2C(context.net_id, CmdCode.PBApplySwitchCityRspCmd, {
            code = ErrorCode.ParamInvalid,
            error = "无效请求参数",
            cityid = req.msg.cityid or 0,
        }, req.msg_context.stub_id)
    end

    local res, err = clusterd.call(3999, "citymgr", "Citymgr.ApplySwitchCity", req.msg.uid, req.msg.cityid)
    if err then
        moon.error(string.format("City.PBApplySwitchCityReqCmd err:%s", err))
        return context.S2C(context.net_id, CmdCode.PBApplySwitchCityRspCmd, {
            code = ErrorCode.ServerInternalError,
            error = "system error",
            cityid = req.msg.cityid or 0,
        }, req.msg_context.stub_id)
    end

    return context.S2C(context.net_id, CmdCode.PBApplySwitchCityRspCmd, res, req.msg_context.stub_id)
end

function City.PBGetAllCityPlayersReqCmd(req)
    -- 参数验证
    if not req.msg.uid then
        return context.S2C(context.net_id, CmdCode.PBGetAllCityPlayersRspCmd, {
            code = ErrorCode.ParamInvalid,
            error = "无效请求参数",
        }, req.msg_context.stub_id)
    end

    local res, err = clusterd.call(3999, "citymgr", "Citymgr.GetAllCityNum")
    if err then
        moon.error(string.format("City.PBGetAllCityPlayersRspCmd err:%s", err))
        return context.S2C(context.net_id, CmdCode.PBGetAllCityPlayersRspCmd, {
            code = ErrorCode.ServerInternalError,
            error = "system error",
        }, req.msg_context.stub_id)
    end

    return context.S2C(context.net_id, CmdCode.PBGetAllCityPlayersRspCmd, res, req.msg_context.stub_id)
end

function City.OnDsDestory(res)
    -- 通知玩家主城链接断开
    context.S2C(context.net_id, CmdCode.PBNotifyDsDestorySyncCmd, {
        uid = context.uid,
        cityid = res.cityid,
    }, 0)
end

return City
