---@class LinearMissionConfig_cfg
---@field public id integer @任务 id
---@field public type integer @用于给任务的UI和埋点分类 （非功能分类）
---@field public unlock_level integer @解锁账户等级（没有则配空）
---@field public front_mission integer[] @前置需求任务 （没有则配空，前置任务类型只能是“线性任务”或“成就任务”）
---@field public back_mission integer @后续任务 （没有则配空）
---@field public target1 integer @任务条件类型1
---@field public target1_data integer @条件1需求进度
---@field public target1_param1 integer @条件类型1 参数1
---@field public target1_param2 integer @条件类型1 参数2
---@field public target1_arr integer[] @条件类型1 数组参数
---@field public target2 integer @任务条件类型2
---@field public target2_data integer @条件2需求进度
---@field public target2_param1 integer @条件类型2 参数1
---@field public target2_param2 integer @条件类型2 参数2
---@field public target2_arr integer[] @条件类型2 数组参数
---@field public start_time integer @任务有效期开始时间戳： 永久有效为 0
---@field public end_time integer @任务有效期结束时间戳： 永久有效为 0
---@field public rewards table @任务奖励 （仅可配置进入仓库的道具和货币）
---@field public treasure_chest table @宝箱奖励（局外宝箱系统）
---@field public vitality integer @活跃度奖励值
return {
[1] = { id=1,type=0,unlock_level=1,front_mission={},back_mission=2,target1=1,target1_data=10,target1_param1=0,target1_param2=0,target1_arr={},target2=3,target2_data=10,target2_param1=0,target2_param2=0,target2_arr={},start_time=0,end_time=0,rewards={[1]=1},treasure_chest={},vitality=0 },
[2] = { id=2,type=0,unlock_level=1,front_mission={1},back_mission=0,target1=2,target1_data=10,target1_param1=0,target1_param2=0,target1_arr={},target2=4,target2_data=10,target2_param1=0,target2_param2=0,target2_arr={},start_time=0,end_time=0,rewards={[1]=1},treasure_chest={},vitality=0 }
}