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
    if context.cityid then
        return context.S2C(context.net_id, CmdCode["PBApplyLoginCityRspCmd"], {
            code = ErrorCode.CityAlreadyInCity,
            error = "你已在主城中",
        }, req.msg_context.stub_id)
    end

    local res, err = clusterd.call(3999, "citymgr", "Citymgr.ApplyLoginToCity", {
        msg = req.msg,
    })
    local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
    if err then
        return context.S2C(context.net_id, CmdCode["PBApplyLoginCityRspCmd"], {
            code = ErrorCode.ServerInternalError,
            error = "system error",
        }, req.msg_context.stub_id)
    end

    return context.S2C(context.net_id, CmdCode["PBApplyLoginCityRspCmd"], res, req.msg_context.stub_id)
end

return City
