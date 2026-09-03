---@class AchievementAward_cfg
---@field public id integer @奖励档位id
---@field public award_target integer @成就点阈值
---@field public award table @奖励配置
return {
[1] = { id=1,award_target=1000,award={[1]=30000,[36]=8000,[37]=8000} },
[2] = { id=2,award_target=2000,award={[1]=30000,[36]=8000,[37]=8000} },
[3] = { id=3,award_target=3000,award={[1]=30000,[36]=8000,[37]=8000} },
[4] = { id=4,award_target=4000,award={[1]=30000,[36]=8000,[37]=8000} }
}