local LuaExt = require "common.LuaExt"
local common = require("common")
local GameCfg = common.GameCfg

local CommonCfgDef = {}

function CommonCfgDef.loadCfg()
    CommonCfgDef.confs = {}
    if table.size(GameCfg.CommonConfig) > 0 then
        for k, v in pairs(GameCfg.CommonConfig) do
            CommonCfgDef.confs[v.name] = v
        end
    end
end

function CommonCfgDef.getConf(name)
    return CommonCfgDef.confs[name]
end

--CommonCfgDef.loadCfg()

return CommonCfgDef