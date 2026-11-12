---@class WeekRotation_cfg
---@field public id integer @任务 id
---@field public activity_type integer @1=主线 2=副模式
---@field public bind_mode integer @1=主线 2=鬼王入侵 3=封魔塔 4=鬼门关
---@field public cycle_week integer @周顺序
---@field public max_round integer @轮次上限
---@field public full_score integer @单轮满分
---@field public tier_scores integer[] @各档积分线
---@field public tier_rewards integer[] @各档奖励数量
---@field public rewards_id integer @奖励道具ID
---@field public chapterid integer[] @模式ID (chapterid)
---@field public difficulty1 integer[] @难度档位1 (difficulty)
---@field public score1 integer @难度1积分
---@field public difficulty2 integer[] @难度档位2
---@field public score2 integer @难度2积分
---@field public difficulty3 integer[] @难度档位3
---@field public score3 integer @难度3积分
---@field public difficulty4 integer[] @难度档位4
---@field public score4 integer @难度4积分
---@field public difficulty5 integer[] @难度档位5
---@field public score5 integer @难度5积分
---@field public open_time integer @首次活动开始时间
return {
[7001] = { id=7001,activity_type=1,bind_mode=1,cycle_week=1,max_round=7,full_score=400,tier_scores={80,160,240,320,400},tier_rewards={1,2,3,4,5},rewards_id=354035,chapterid={1,2},difficulty1={1},score1=8,difficulty2={2},score2=9,difficulty3={3},score3=10,difficulty4={4},score4=12,difficulty5={5},score5=15,open_time=1794348000 },
[7002] = { id=7002,activity_type=1,bind_mode=1,cycle_week=2,max_round=7,full_score=400,tier_scores={80,160,240,320,400},tier_rewards={1,2,3,4,5},rewards_id=354036,chapterid={1,2},difficulty1={1},score1=8,difficulty2={2},score2=9,difficulty3={3},score3=10,difficulty4={4},score4=12,difficulty5={5},score5=15,open_time=0 },
[7003] = { id=7003,activity_type=1,bind_mode=1,cycle_week=3,max_round=7,full_score=400,tier_scores={80,160,240,320,400},tier_rewards={1,2,3,4,5},rewards_id=354037,chapterid={1,2},difficulty1={1},score1=8,difficulty2={2},score2=9,difficulty3={3},score3=10,difficulty4={4},score4=12,difficulty5={5},score5=15,open_time=0 },
[7004] = { id=7004,activity_type=2,bind_mode=2,cycle_week=1,max_round=7,full_score=300,tier_scores={80,160,240,320,400},tier_rewards={1,2,3,4,5},rewards_id=354038,chapterid={2001},difficulty1={1},score1=10,difficulty2={2},score2=11,difficulty3={3},score3=12,difficulty4={4},score4=13,difficulty5={5},score5=15,open_time=0 },
[7005] = { id=7005,activity_type=2,bind_mode=3,cycle_week=2,max_round=7,full_score=300,tier_scores={80,160,240,320,400},tier_rewards={1,2,3,4,5},rewards_id=354039,chapterid={3001},difficulty1={1,2},score1=10,difficulty2={3,4},score2=11,difficulty3={5,6},score3=12,difficulty4={7,8},score4=13,difficulty5={9,10},score5=15,open_time=0 },
[7006] = { id=7006,activity_type=2,bind_mode=4,cycle_week=3,max_round=7,full_score=300,tier_scores={80,160,240,320,400},tier_rewards={1,2,3,4,5},rewards_id=354040,chapterid={1001},difficulty1={1},score1=10,difficulty2={2},score2=11,difficulty3={3},score3=12,difficulty4={4},score4=13,difficulty5={5},score5=15,open_time=0 }
}