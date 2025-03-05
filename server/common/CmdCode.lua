--- Automatically generated,do not modify.

local M={
    ["PBPacketCmd"] = 1,
    ["google.protobuf.Any"] = 2,
    ["PBClientLoginReqCmd"] = 100,
    ["PBClientLoginRspCmd"] = 101,
    ["PBPingCmd"] = 102,
    ["PBPongCmd"] = 103,

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
