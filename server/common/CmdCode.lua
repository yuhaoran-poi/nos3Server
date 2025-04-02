--- Automatically generated,do not modify.

local M={
    ["PBPacketCmd"] = 1,
    ["PBClientLoginReqCmd"] = 2,
    ["google.protobuf.Any"] = 3,
    ["PBApplyFriendReqCmd"] = 100,
    ["PBApplyFriendRspCmd"] = 101,
    ["PBApplyGuildReqCmd"] = 102,
    ["PBApplyGuildRspCmd"] = 103,
    ["PBApplyTeamReqCmd"] = 104,
    ["PBApplyTeamRspCmd"] = 105,
    ["PBApplyTeamSyncCmd"] = 106,
    ["PBClientGetUsrSimInfoReqCmd"] = 107,
    ["PBClientGetUsrSimInfoRspCmd"] = 108,
    ["PBClientLoginRspCmd"] = 109,
    ["PBGetActivityInfoReqCmd"] = 110,
    ["PBGetActivityInfoRspCmd"] = 111,
    ["PBGetFriendInfoReqCmd"] = 112,
    ["PBGetFriendInfoRspCmd"] = 113,
    ["PBGetMailItemReqCmd"] = 114,
    ["PBGetMailItemRspCmd"] = 115,
    ["PBGetOpenBoxReqCmd"] = 116,
    ["PBGetOpenBoxRspCmd"] = 117,
    ["PBGetRankInfoReqCmd"] = 118,
    ["PBGetRankInfoRspCmd"] = 119,
    ["PBGetTradeBankInfoReqCmd"] = 120,
    ["PBGetTradeBankInfoRspCmd"] = 121,
    ["PBPingCmd"] = 122,
    ["PBPongCmd"] = 123,
    ["PBUpdateMissionClientSyncCmd"] = 124,
    ["PBUpdateMissionSeverSyncCmd"] = 125,

}

local forward = {
    PBGetActivityInfoReqCmd = 'addr_activity',
    PBGetActivityInfoRspCmd = 'addr_activity',
    PBClientLoginReqCmd = 'addr_auth',
    PBClientLoginRspCmd = 'addr_auth',
    PBGetFriendInfoReqCmd = 'addr_friend',
    PBGetFriendInfoRspCmd = 'addr_friend',
    PBApplyFriendReqCmd = 'addr_friend',
    PBApplyFriendRspCmd = 'addr_friend',
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
    PBClientGetUsrSimInfoReqCmd = 'addr_user',
    PBClientGetUsrSimInfoRspCmd = 'addr_user',

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
