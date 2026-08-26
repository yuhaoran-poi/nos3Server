---@class GameMode_cfg
---@field public id integer @模式ID
---@field public begin_id integer @模式开始ID(包含)
---@field public end_id integer @模式结束ID(包含)
---@field public cost1 table @队长消耗1
---@field public cost2 table @队长消耗2
---@field public recover_week integer @周几
---@field public recover_time integer @补票时间 从凌晨开始计算的秒数
---@field public recover_num table @补票张数
return {
[1] = { id=1,begin_id=1,end_id=1000,cost1={[108]=1},cost2={[107]=1},recover_week=3,recover_time=18000,recover_num={[108]=3} },
[2] = { id=2,begin_id=1001,end_id=2000,cost1={[102]=1},cost2={[101]=1},recover_week=3,recover_time=18000,recover_num={[102]=3} },
[3] = { id=3,begin_id=2001,end_id=3000,cost1={[104]=1},cost2={[103]=1},recover_week=3,recover_time=18000,recover_num={[104]=3} },
[4] = { id=4,begin_id=3001,end_id=4000,cost1={[106]=1},cost2={[105]=1},recover_week=3,recover_time=18000,recover_num={[106]=3} }
}