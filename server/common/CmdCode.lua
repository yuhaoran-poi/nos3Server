--- Automatically generated,do not modify.

local M={
    ["PBPacketCmd"] = 1,
    ["google.protobuf.Any"] = 2,
    ["PBApplyGuildReqCmd"] = 100,
    ["PBApplyGuildRspCmd"] = 101,
    ["PBApplyTeamReqCmd"] = 102,
    ["PBApplyTeamRspCmd"] = 103,
    ["PBApplyTeamSyncCmd"] = 104,
    ["PBClientLoginReqCmd"] = 105,
    ["PBClientLoginRspCmd"] = 106,
    ["PBGetActivityInfoReqCmd"] = 107,
    ["PBGetActivityInfoRspCmd"] = 108,
    ["PBGetFriendInfoReqCmd"] = 109,
    ["PBGetFriendInfoRspCmd"] = 110,
    ["PBGetMailItemReqCmd"] = 111,
    ["PBGetMailItemRspCmd"] = 112,
    ["PBGetOpenBoxReqCmd"] = 113,
    ["PBGetOpenBoxRspCmd"] = 114,
    ["PBGetRankInfoReqCmd"] = 115,
    ["PBGetRankInfoRspCmd"] = 116,
    ["PBGetTradeBankInfoReqCmd"] = 117,
    ["PBGetTradeBankInfoRspCmd"] = 118,
    ["PBPingCmd"] = 119,
    ["PBPongCmd"] = 120,
    ["PBUpdateMissionClientSyncCmd"] = 121,
    ["PBUpdateMissionSeverSyncCmd"] = 122,

}

local forward = {
    PBGetActivityInfoReqCmd = 'addr_activity',
    PBGetActivityInfoRspCmd = 'addr_activity',
    PBClientLoginReqCmd = 'addr_auth',
    PBClientLoginRspCmd = 'addr_auth',
    PBGetFriendInfoReqCmd = 'addr_friend',
    PBGetFriendInfoRspCmd = 'addr_friend',
    PBApplyGuildReqCmd = 'addr_guild',
    PBApplyGuildRspCmd = 'addr_guild',
    PBGetMailItemReqCmd = 'addr_mail',
    PBGetMailItemRspCmd = 'addr_mail',
    PBUpdateMissionSeverSyncCmd = 'addr_mission',
    PBUpdateMissionClientSyncCmd = 'addr_mission',
    PBGetRankInfoReqCmd = 'addr_rank',
    PBGetRankInfoRspCmd = 'addr_rank',
    PBApplyTeamReqCmd = 'addr_team',
    PBApplyTeamRspCmd = 'addr_team',
    PBApplyTeamSyncCmd = 'addr_team',
    PBGetTradeBankInfoReqCmd = 'addr_trade',
    PBGetTradeBankInfoRspCmd = 'addr_trade',
    PBGetOpenBoxReqCmd = 'addr_user',
    PBGetOpenBoxRspCmd = 'addr_user',

}

local mt = { forward = forward }

mt.__newindex = function(_, name, _)
    local msg = "attemp index unknown message: " .. tostring(name)
    error(debug.traceback(msg, 2))
end

mt.__index = function(_, name)
    if name == "forward" then
        return forward
    end
    local msg = "attemp index unknown message: " .. tostring(name)
    error(debug.traceback(msg, 2))
end

return setmetatable(M,mt)
