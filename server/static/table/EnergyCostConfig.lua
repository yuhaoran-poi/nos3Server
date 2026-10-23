---@class EnergyCostConfig_cfg
---@field public id integer @ID
---@field public max_num integer @精力值上限
---@field public cost1 integer @主线地狱每次消耗
---@field public cost2 integer @鬼门关每次消耗
---@field public cost3 integer @封魔塔每次消耗
---@field public cost4 integer @鬼王入侵每次消耗
---@field public pill_restore integer @丹药回复精力数值
---@field public recover_time integer @自然恢复精力时间
return {
[1] = { id=1,max_num=100,cost1=10,cost2=10,cost3=10,cost4=10,pill_restore=10,recover_time=6 }
}