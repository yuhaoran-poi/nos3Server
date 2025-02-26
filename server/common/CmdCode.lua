--- Automatically generated，do not modify.

local M={
    ["dsgatepb.Packet"] = 1,
    ["dsgatepb.AuthCmd"] = 2,
    ["dsgatepb.AuthResultCmd"] = 3,
    ["dsgatepb.ClientForwardCmd"] = 4,
    ["dsgatepb.ClientLoginCmd"] = 5,
    ["dsgatepb.ClientLoginResultCmd"] = 6,
    ["dsgatepb.DisconnectCmd"] = 7,
    ["dsgatepb.DisconnectGateCmd"] = 8,
    ["dsgatepb.ForwardCmd"] = 9,
    ["dsgatepb.MigrationAuthorityCmd"] = 10,
    ["dsgatepb.MigrationDiagnosticRequestCmd"] = 11,
    ["dsgatepb.MigrationDiagnosticResponseCmd"] = 12,
    ["dsgatepb.NotifyRegisterCmd"] = 13,
    ["dsgatepb.PingCmd"] = 14,
    ["dsgatepb.PongCmd"] = 15,
    ["dsgatepb.QueryDSCmd"] = 16,
    ["dsgatepb.QueryDSResultCmd"] = 17,
    ["dsgatepb.QueryMapInfoCmd"] = 18,
    ["dsgatepb.QueryMapInfoResultCmd"] = 19,
    ["dsgatepb.QuerySubBorderCmd"] = 20,
    ["dsgatepb.QuerySubBorderResultCmd"] = 21,
    ["dsgatepb.RegisterDsCmd"] = 22,
    ["dsgatepb.RegisterDsResultCmd"] = 23,
    ["dsgatepb.RpcGmCreateEntityCmd"] = 24,
    ["dsgatepb.ServerForwardCmd"] = 25,
    ["dsgatepb.StartDataChannelCmd"] = 26,
    ["dsgatepb.SubBorderCmd"] = 27,
    ["dsgatepb.SubBorderResultCmd"] = 28,
    ["dsgatepb.SubDSCmd"] = 29,
    ["dsgatepb.SubDSResultCmd"] = 30,
    ["dsgatepb.SynLoginAuthCmd"] = 31,
    ["dsgatepb.UnSubBorderCmd"] = 32,
    ["dsgatepb.UpdateConnToCmd"] = 33,
    ["dsgatepb.UpdateMapInfoCmd"] = 34,
    ["google.protobuf.Any"] = 35,
    ["C2SMatch"] = 100,
    ["S2CGameOver"] = 101,
    ["S2CMatch"] = 102,
    ["S2CMatchSuccess"] = 103,
    ["mailpb.C2SMailDel"] = 104,
    ["mailpb.C2SMailList"] = 105,
    ["mailpb.C2SMailLock"] = 106,
    ["mailpb.C2SMailMark"] = 107,
    ["mailpb.C2SMailRead"] = 108,
    ["mailpb.C2SMailReward"] = 109,
    ["mailpb.S2CMailDel"] = 110,
    ["mailpb.S2CMailList"] = 111,
    ["mailpb.S2CUpdateMail"] = 112,
    ["userpb.S2CErrorCode"] = 113,

}

local forward = {

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
