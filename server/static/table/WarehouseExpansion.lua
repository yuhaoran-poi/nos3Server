---@class WarehouseExpansion_cfg
---@field public id integer @扩充等级
---@field public warehouse_grids integer @仓库格子数量
---@field public warehouse_cost table @仓库扩充消耗
return {
[1] = { id=1,warehouse_grids=100,warehouse_cost={[1]=100} },
[2] = { id=2,warehouse_grids=200,warehouse_cost={[1]=101} },
[3] = { id=3,warehouse_grids=300,warehouse_cost={[1]=102} },
[4] = { id=4,warehouse_grids=400,warehouse_cost={[1]=103} },
[5] = { id=5,warehouse_grids=500,warehouse_cost={[1]=104} }
}