local sharetable = require("sharetable")

---@class GameCfg : static_conf
local M = {}

---@type static_conf
local static

function M.Load()
    static = sharetable.queryall()
    --local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
    static.__index = static
    setmetatable(M, static)
end

function M.Reload(names)
    local res = sharetable.queryall(names)
    for k,v in pairs(res) do
        static[k] = v
    end
end

return M
