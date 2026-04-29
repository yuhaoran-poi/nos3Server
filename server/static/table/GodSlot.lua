---@class GodSlot_cfg
---@field public id integer @神龛编号
---@field public default_unlock integer @是否默认解锁
---@field public unlock_level integer @账户需求等级
---@field public unlock_cost table @解锁神龛消耗的道具
---@field public incense_cost table @上香的消耗
---@field public incense_time integer @上香的持续时间（单位秒）
return {
[1] = { id=1,default_unlock=1,unlock_level=0,unlock_cost={},incense_cost={[1]=100},incense_time=300 },
[2] = { id=2,default_unlock=0,unlock_level=10,unlock_cost={[22003]=10,[22010]=5},incense_cost={[1]=101},incense_time=300 },
[3] = { id=3,default_unlock=0,unlock_level=20,unlock_cost={[22003]=10,[22010]=5},incense_cost={[1]=102},incense_time=300 }
}