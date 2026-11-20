---@class RankingListReward_cfg
---@field public id integer @
---@field public ranking_range table @排名范围(包含最大值最小值) key-最小排名，value-最大排名
---@field public reward_id integer[] @奖励id 读取RankingListRewardPool表
return {
[1] = { id=1,ranking_range={[1]=1},reward_id={1} },
[2] = { id=2,ranking_range={[2]=10},reward_id={2} },
[3] = { id=3,ranking_range={[11]=50},reward_id={3} },
[4] = { id=4,ranking_range={[51]=100},reward_id={4} }
}