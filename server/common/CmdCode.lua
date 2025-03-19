--- Automatically generated,do not modify.

local M={
    ["PBPacketCmd"] = 1,
    ["PBClientLoginReqCmd"] = 2,
    ["google.protobuf.Any"] = 3,
    ["PBApplyGuildReqCmd"] = 100,
    ["PBApplyGuildRspCmd"] = 101,
    ["PBApplyTeamReqCmd"] = 102,
    ["PBApplyTeamRspCmd"] = 103,
    ["PBApplyTeamSyncCmd"] = 104,
    ["PBClientLoginRspCmd"] = 105,
    ["PBGetActivityInfoReqCmd"] = 106,
    ["PBGetActivityInfoRspCmd"] = 107,
    ["PBGetFriendInfoReqCmd"] = 108,
    ["PBGetFriendInfoRspCmd"] = 109,
    ["PBGetMailItemReqCmd"] = 110,
    ["PBGetMailItemRspCmd"] = 111,
    ["PBGetOpenBoxReqCmd"] = 112,
    ["PBGetOpenBoxRspCmd"] = 113,
    ["PBGetRankInfoReqCmd"] = 114,
    ["PBGetRankInfoRspCmd"] = 115,
    ["PBGetTradeBankInfoReqCmd"] = 116,
    ["PBGetTradeBankInfoRspCmd"] = 117,
    ["PBPingCmd"] = 118,
    ["PBPongCmd"] = 119,
    ["PBUpdateMissionClientSyncCmd"] = 120,
    ["PBUpdateMissionSeverSyncCmd"] = 121,

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
