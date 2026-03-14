---@class TreasureChestRewards_cfg
---@field public id integer @道具池id： 普通道具池id = 道具类型*10+品质类型 保底道具池id >= 1,000,000
---@field public item_weight table @道具id：权重
---@field public item_num table @道具id：数量
return {
[11] = { id=11,item_weight={[1]=10},item_num={[1]=1000} },
[12] = { id=12,item_weight={[1]=10},item_num={[1]=1000} },
[13] = { id=13,item_weight={[1]=10},item_num={[1]=1000} },
[14] = { id=14,item_weight={[1]=10},item_num={[1]=1000} },
[21] = { id=21,item_weight={[1]=10,[2]=100},item_num={[1]=1000,[2]=10} },
[22] = { id=22,item_weight={[1]=10},item_num={[1]=1000} },
[23] = { id=23,item_weight={[1]=10},item_num={[1]=1000} },
[24] = { id=24,item_weight={[1]=10},item_num={[1]=1000} },
[31] = { id=31,item_weight={[1]=10},item_num={[1]=1000} },
[32] = { id=32,item_weight={[1]=10},item_num={[1]=1000} },
[33] = { id=33,item_weight={[1]=10},item_num={[1]=1000} },
[34] = { id=34,item_weight={[1]=10},item_num={[1]=1000} },
[1000000] = { id=1000000,item_weight={[1]=10},item_num={[1]=1000} },
[1000001] = { id=1000001,item_weight={[1]=10},item_num={[1]=1000} }
}