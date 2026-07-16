---@class WarehouseExpansion_cfg
---@field public id integer @扩充等级
---@field public warehouse_grids integer @仓库格子数量
---@field public warehouse_cost table @仓库扩充消耗
return {
[1] = { id=1,warehouse_grids=100,warehouse_cost={[1]=10000000} },
[2] = { id=2,warehouse_grids=200,warehouse_cost={[1]=20000000} },
[3] = { id=3,warehouse_grids=300,warehouse_cost={[1]=40000000} },
[4] = { id=4,warehouse_grids=400,warehouse_cost={[1]=80000000} },
[5] = { id=5,warehouse_grids=500,warehouse_cost={[1]=120000000} }
}