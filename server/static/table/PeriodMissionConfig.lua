---@class PeriodMissionConfig_cfg
---@field public id integer @任务 id
---@field public type integer @用于给任务的UI和埋点分类 （非功能分类）
---@field public unlock_level integer @解锁账户等级（没有则配空）
---@field public front_mission integer[] @前置需求任务 （没有则配空）
---@field public target1 table @任务条件类型1:进度
---@field public target1_param1 integer @条件类型1 参数1
---@field public target1_param2 integer @条件类型1 参数2
---@field public target1_arr integer[] @条件类型1 数组参数
---@field public target2 table @任务条件类型2:进度
---@field public target2_param1 integer @条件类型2 参数1
---@field public target2_param2 integer @条件类型2 参数2
---@field public target2_arr integer[] @条件类型2 数组参数
---@field public period integer[] @任务有效期时间戳： 永久有效为 0
---@field public rewards table @任务奖励
---@field public cyclical_type integer @周期任务类型： 1 = 固定任务 2 = 随机任务
---@field public cyclical_date integer @周期类型： 1 = 每日 2 = 每周 3 = 每月
---@field public is_loop integer @是否循环： 1 = 循环 2 = 不循环
---@field public weigh integer @随机权重
return {
[20001] = { id=20001,type=0,unlock_level=1,front_mission={},target1={[1]=10},target1_param1=0,target1_param2=0,target1_arr={},target2={[1]=10},target2_param1=0,target2_param2=0,target2_arr={},period={0},rewards={[1]=1},cyclical_type=1,cyclical_date=1,is_loop=1,weigh=0 },
[20002] = { id=20002,type=0,unlock_level=1,front_mission={},target1={[2]=11},target1_param1=0,target1_param2=0,target1_arr={},target2={[2]=11},target2_param1=0,target2_param2=0,target2_arr={},period={0},rewards={[1]=1},cyclical_type=2,cyclical_date=1,is_loop=0,weigh=50 },
[20003] = { id=20003,type=0,unlock_level=1,front_mission={},target1={},target1_param1=0,target1_param2=0,target1_arr={},target2={},target2_param1=0,target2_param2=0,target2_arr={},period={0},rewards={[1]=1},cyclical_type=2,cyclical_date=1,is_loop=0,weigh=50 },
[20004] = { id=20004,type=0,unlock_level=1,front_mission={},target1={},target1_param1=0,target1_param2=0,target1_arr={},target2={},target2_param1=0,target2_param2=0,target2_arr={},period={0},rewards={[1]=1},cyclical_type=1,cyclical_date=2,is_loop=1,weigh=0 },
[20005] = { id=20005,type=0,unlock_level=1,front_mission={},target1={},target1_param1=0,target1_param2=0,target1_arr={},target2={},target2_param1=0,target2_param2=0,target2_arr={},period={0},rewards={[1]=1},cyclical_type=1,cyclical_date=2,is_loop=1,weigh=0 },
[20006] = { id=20006,type=0,unlock_level=1,front_mission={},target1={},target1_param1=0,target1_param2=0,target1_arr={},target2={},target2_param1=0,target2_param2=0,target2_arr={},period={0},rewards={[1]=1},cyclical_type=1,cyclical_date=3,is_loop=1,weigh=0 }
}