---@class GodLevel_cfg
---@field public id integer @等级
---@field public unlock_rank integer @神明升星所需的段位积分
---@field public cost table @该等级下升级消耗的资源 （因为神明随着赛季更新，升级消耗赛季货币）
return {
[1] = { id=1,unlock_rank=0,cost={[1]=1000} },
[2] = { id=2,unlock_rank=1,cost={[1]=1001} },
[3] = { id=3,unlock_rank=2,cost={[1]=1002} },
[4] = { id=4,unlock_rank=3,cost={[1]=1003} },
[5] = { id=5,unlock_rank=4,cost={[1]=1004} },
[6] = { id=6,unlock_rank=5,cost={[1]=1005} },
[7] = { id=7,unlock_rank=6,cost={[1]=1006} },
[8] = { id=8,unlock_rank=7,cost={[1]=1007} },
[9] = { id=9,unlock_rank=8,cost={[1]=1008} },
[10] = { id=10,unlock_rank=9,cost={} }
}