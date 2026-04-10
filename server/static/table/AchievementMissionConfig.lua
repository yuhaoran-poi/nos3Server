---@class AchievementMissionConfig_cfg
---@field public id integer @任务 id
---@field public type integer @用于给任务的UI和埋点分类 （非功能分类）
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
---@field public rewards table @任务奖励 （仅可配置进入仓库的道具和货币）
---@field public treasure_chest table @宝箱奖励（局外宝箱系统）
---@field public vitality integer @活跃度奖励值
return {
[10001] = { id=10001,type=0,target1=1,target1_data=10,target1_param1=0,target1_param2=0,target1_arr={},target2=3,target2_data=10,target2_param1=0,target2_param2=0,target2_arr={},rewards={[1]=1},treasure_chest={},vitality=0 },
[10002] = { id=10002,type=0,target1=2,target1_data=10,target1_param1=0,target1_param2=0,target1_arr={},target2=4,target2_data=10,target2_param1=0,target2_param2=0,target2_arr={},rewards={[1]=1},treasure_chest={},vitality=0 }
}