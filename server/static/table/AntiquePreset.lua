---@class AntiquePreset_cfg
---@field public id integer @ID
---@field public preset_cost table @古董预设页扩充消耗
return {
[1] = { id=1,preset_cost={} },
[2] = { id=2,preset_cost={[1]=10000000} },
[3] = { id=3,preset_cost={[1]=20000000} },
[4] = { id=4,preset_cost={[1]=40000000} },
[5] = { id=5,preset_cost={[1]=80000000} }
}