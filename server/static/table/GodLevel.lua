---@class GodLevel_cfg
---@field public id integer @等级
---@field public unlock_rank integer @神明升星所需的段位积分
---@field public cost table @该等级下升级消耗的资源 （因为神明随着赛季更新，升级消耗赛季货币）
return {
[1] = { id=1,unlock_rank=0,cost={[7]=550} },
[2] = { id=2,unlock_rank=1,cost={[7]=650} },
[3] = { id=3,unlock_rank=2,cost={[7]=750} },
[4] = { id=4,unlock_rank=3,cost={[7]=850} },
[5] = { id=5,unlock_rank=4,cost={[7]=950} },
[6] = { id=6,unlock_rank=5,cost={[7]=1050} },
[7] = { id=7,unlock_rank=6,cost={[7]=1150} },
[8] = { id=8,unlock_rank=7,cost={[7]=1250} },
[9] = { id=9,unlock_rank=8,cost={[7]=1350} },
[10] = { id=10,unlock_rank=9,cost={} }
}