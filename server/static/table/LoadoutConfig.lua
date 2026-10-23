---@class LoadoutConfig_cfg
---@field public id integer @配置槽ID
---@field public num integer @槽位数量
---@field public type1 integer @槽位1装备类型 (UniqueItem表type5)
---@field public type2 integer @槽位2装备类型 (UniqueItem表type5)
---@field public type3 integer @槽位3装备类型 (UniqueItem表type5)
---@field public type4 integer @槽位4装备类型 (UniqueItem表type5)
---@field public type5 integer @槽位5装备类型 (UniqueItem表type5)
---@field public type6 integer @槽位6装备类型 (UniqueItem表type5)
---@field public type7 integer @槽位7装备类型 (UniqueItem表type5)
---@field public type8 integer @槽位8装备类型 (UniqueItem表type5)
---@field public type9 integer @槽位9装备类型 (UniqueItem表type1）
---@field public type10 integer @槽位10装备类型 (UniqueItem表type1）
---@field public unlock integer @是否初始解锁 0-是 1-否
---@field public unlock_cost table @解锁所需
return {
[1] = { id=1,num=10,type1=1,type2=2,type3=3,type4=4,type5=5,type6=6,type7=7,type8=8,type9=2,type10=3,unlock=0,unlock_cost={} },
[2] = { id=2,num=10,type1=1,type2=2,type3=3,type4=4,type5=5,type6=6,type7=7,type8=8,type9=2,type10=3,unlock=1,unlock_cost={[1]=5000000} },
[3] = { id=3,num=10,type1=1,type2=2,type3=3,type4=4,type5=5,type6=6,type7=7,type8=8,type9=2,type10=3,unlock=1,unlock_cost={[1]=10000000} }
}