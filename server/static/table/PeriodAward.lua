---@class PeriodAward_cfg
---@field public id integer @类型 id
---@field public type1 integer @活跃度奖励类型 1-每日活跃 2-每周活跃
---@field public type2 integer @重置时间 1-每日 2-每周
---@field public award_target1 integer @活跃度目标值1
---@field public award1 table @奖励配置1
---@field public award_target2 integer @活跃度目标值2
---@field public award2 table @奖励配置2
---@field public award_target3 integer @活跃度目标值3
---@field public award3 table @奖励配置3
---@field public award_target4 integer @活跃度目标值4
---@field public award4 table @奖励配置4
---@field public award_target5 integer @活跃度目标值5
---@field public award5 table @奖励配置5
return {
[1] = { id=1,type1=1,type2=1,award_target1=25,award1={[1]=5000,[39]=20},award_target2=50,award2={[1]=10000,[39]=50},award_target3=75,award3={[1]=30000,[39]=100},award_target4=0,award4={},award_target5=0,award5={} },
[2] = { id=2,type1=2,type2=2,award_target1=60,award1={[1]=10000,[39]=50},award_target2=120,award2={[1]=20000,[39]=100},award_target3=180,award3={[1]=40000,[39]=200},award_target4=240,award4={[1]=70000,[39]=300},award_target5=300,award5={[1]=120000,[39]=500} }
}