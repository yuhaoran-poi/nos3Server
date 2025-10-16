---@class GodSlot_cfg
---@field public id integer @神龛编号
---@field public default_unlock integer @是否默认解锁
---@field public unlock_level integer @需求等级
---@field public unlock_godnum integer @需求已解锁神明数量
---@field public cost table @解锁神龛消耗的道具
return {
[1] = { id=1,default_unlock=1,unlock_level=0,unlock_godnum=0,cost={} },
[2] = { id=2,default_unlock=0,unlock_level=10,unlock_godnum=3,cost={[22003]=10,[22010]=5} },
[3] = { id=3,default_unlock=0,unlock_level=20,unlock_godnum=5,cost={[22003]=10,[22010]=5} }
}