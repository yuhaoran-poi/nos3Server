---@class TreasureChest_cfg
---@field public id integer @宝箱id
---@field public type integer @宝箱类型： 1 = 无限宝箱； 2 = 消耗宝箱
---@field public open_consume table @开启宝箱消耗的资源
---@field public period_validity integer[] @宝箱有效期（开始，结束时间戳）: -1 = 永久有效
---@field public quality_weight table @品质:权重
---@field public class_weight table @类型：权重
---@field public guarantee_item integer @保底道具池id: 保底道具池id >= 1,000,000
---@field public guarantee_times integer @保底可生效次数： -1 = 无限次 0 = 无保底
---@field public guarantee_trigger integer @触发保底次数： 必须大于 0
return {
[1] = { id=1,type=1,open_consume={[1]=1000},period_validity={-1},quality_weight={[1]=10,[2]=10,[3]=10},class_weight={[1]=5,[2]=5,[3]=5},guarantee_item=1000000,guarantee_times=0,guarantee_trigger=10 },
[2] = { id=2,type=2,open_consume={[1]=1000},period_validity={-1},quality_weight={[1]=10,[2]=10,[3]=10},class_weight={[2]=5,[3]=5,[4]=5},guarantee_item=1000001,guarantee_times=0,guarantee_trigger=0 }
}