---@class ActivityAward_cfg
---@field public id integer @领取奖励id
---@field public type integer @类型（活动id)
---@field public award_target integer @成就点阈值
---@field public award table @奖励配置
return {
[1] = { id=1,type=6,award_target=50,award={[1]=140000,[36]=900,[37]=900} },
[2] = { id=2,type=6,award_target=100,award={[1]=170000,[36]=1200,[37]=1200} },
[3] = { id=3,type=6,award_target=150,award={[1]=200000,[36]=1500,[37]=1500,[354024]=1} },
[4] = { id=4,type=6,award_target=200,award={[1]=230000,[36]=1800,[37]=1800} },
[5] = { id=5,type=6,award_target=250,award={[1]=260000,[36]=2100,[37]=2100,[354024]=1} },
[6] = { id=6,type=6,award_target=300,award={[1]=290000,[36]=2400,[37]=2400} },
[7] = { id=7,type=6,award_target=350,award={[1]=320000,[36]=2700,[37]=2700,[354024]=1} },
[8] = { id=8,type=6,award_target=400,award={[1]=360000,[36]=3000,[37]=3000} },
[9] = { id=9,type=6,award_target=450,award={[1]=380000,[36]=3300,[37]=3300} },
[10] = { id=10,type=6,award_target=500,award={[1]=460000,[36]=4100,[37]=4100} }
}