---@class PeriodAward_cfg
---@field public id integer @领取奖励id
---@field public type integer @奖励类型 1-每日 2-每周
---@field public award_target integer @活跃度阈值
---@field public award table @奖励配置
---@field public treasure_chest table @宝箱奖励（局外宝箱系统）
return {
[1] = { id=1,type=1,award_target=25,award={[1]=5000,[39]=20},treasure_chest={[1120191]=1} },
[2] = { id=2,type=1,award_target=50,award={[1]=10000,[39]=50},treasure_chest={[1120192]=1} },
[3] = { id=3,type=1,award_target=75,award={[1]=30000,[39]=100},treasure_chest={[1120193]=1} },
[4] = { id=4,type=2,award_target=60,award={[1]=10000,[39]=50},treasure_chest={[1120191]=1} },
[5] = { id=5,type=2,award_target=120,award={[1]=20000,[39]=100},treasure_chest={[1120191]=1} },
[6] = { id=6,type=2,award_target=180,award={[1]=40000,[39]=200},treasure_chest={[1120192]=1} },
[7] = { id=7,type=2,award_target=240,award={[1]=70000,[39]=300},treasure_chest={[1120192]=1} },
[8] = { id=8,type=2,award_target=300,award={[1]=120000,[39]=500},treasure_chest={[1120193]=1} }
}