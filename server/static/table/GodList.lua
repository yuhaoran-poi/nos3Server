---@class GodList_cfg
---@field public id integer @神明id
---@field public default_unlock integer @是否默认解锁
---@field public unlock_cost table @解锁神明消耗的材料
return {
[1016500] = { id=1016500,default_unlock=1,unlock_cost={} },
[1016501] = { id=1016501,default_unlock=0,unlock_cost={[22003]=10,[22010]=5} }
}