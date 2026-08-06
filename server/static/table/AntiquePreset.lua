---@class AntiquePreset_cfg
---@field public id integer @词条池ID 10000ID后表示初始化词条
---@field public preset_cost table @古董预设页扩充消耗
return {
[1] = { id=1,preset_cost={} },
[2] = { id=2,preset_cost={[1]=10000000} },
[3] = { id=3,preset_cost={[1]=15000000} },
[4] = { id=4,preset_cost={[1]=20000000} },
[5] = { id=5,preset_cost={[1]=25000000} },
[6] = { id=6,preset_cost={[1]=30000000} },
[7] = { id=7,preset_cost={[1]=40000000} },
[8] = { id=8,preset_cost={[1]=50000000} },
[9] = { id=9,preset_cost={[1]=65000000} },
[10] = { id=10,preset_cost={[1]=80000000} }
}