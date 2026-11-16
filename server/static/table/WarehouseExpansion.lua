---@class WarehouseExpansion_cfg
---@field public id integer @扩充等级
---@field public warehouse_grids integer @仓库格子数量
---@field public warehouse_cost table @仓库扩充消耗
return {
[1] = { id=1,warehouse_grids=150,warehouse_cost={} },
[2] = { id=2,warehouse_grids=300,warehouse_cost={[1]=100000} },
[3] = { id=3,warehouse_grids=450,warehouse_cost={[1]=1000000} },
[4] = { id=4,warehouse_grids=600,warehouse_cost={[1]=10000000} },
[5] = { id=5,warehouse_grids=750,warehouse_cost={[1]=50000000} },
[6] = { id=6,warehouse_grids=900,warehouse_cost={[1]=100000000} }
}