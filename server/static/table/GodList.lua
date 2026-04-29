---@class GodList_cfg
---@field public id integer @神明id
---@field public default_unlock integer @是否默认解锁
---@field public unlock_cost table @解锁神明消耗的材料
---@field public pool table @该神明的赐福池 主要是给上香随机赐福点数使用 赐福ID（查询AllTag表）：等级限制（大于等于）
return {
[1016500] = { id=1016500,default_unlock=1,unlock_cost={},pool={[100]=1,[20]=1} },
[1016501] = { id=1016501,default_unlock=0,unlock_cost={[22003]=10,[22010]=5},pool={[100]=1,[20]=2} }
}