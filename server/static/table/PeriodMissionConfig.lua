---@class PeriodMissionConfig_cfg
---@field public id integer @任务 id
---@field public type integer @用于给任务的UI和埋点分类 （非功能分类）
---@field public unlock_level integer @解锁账户等级（没有则配空）
---@field public front_mission integer[] @前置需求任务 （没有则配空，前置任务类型只能是“线性任务”或“成就任务”）
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
---@field public start_time integer @任务有效期开始时间戳： 永久有效为 0 **周期刷新时，任务若无效，则不会被刷新，配置时有效开始时间最好和周期时间节点一致
---@field public end_time integer @任务有效期结束时间戳： 永久有效为 0 **周期未结束时，任务若失效，不会被立即移除，而是等周期结束移除，配置时有效结束时间最好和周期时间节点一致
---@field public rewards table @任务奖励 （仅可配置进入仓库的道具和货币）
---@field public treasure_chest table @宝箱奖励（局外宝箱系统）
---@field public vitality integer @活跃度奖励值
---@field public cyclical_type integer @周期任务类型： 1 = 固定任务 2 = 随机任务
---@field public cyclical_date integer @周期类型： 1 = 每日 2 = 每周 3 = 每月
---@field public is_loop integer @是否循环： 1 = 循环 2 = 不循环
---@field public weight integer @随机权重
---@field public is_refresh integer @每日任务是否可重随： 1 = 不可以 2 = 可以
return {
[20001] = { id=20001,type=0,unlock_level=1,front_mission={},target1=1,target1_data=1,target1_param1=0,target1_param2=0,target1_arr={},target2=0,target2_data=0,target2_param1=0,target2_param2=0,target2_arr={},start_time=0,end_time=0,rewards={[1]=1000,[39]=10},treasure_chest={},vitality=15,cyclical_type=2,cyclical_date=1,is_loop=1,weight=100,is_refresh=2 },
[20002] = { id=20002,type=0,unlock_level=1,front_mission={},target1=44,target1_data=3,target1_param1=0,target1_param2=0,target1_arr={},target2=0,target2_data=0,target2_param1=0,target2_param2=0,target2_arr={},start_time=0,end_time=0,rewards={[1]=2000,[39]=10},treasure_chest={},vitality=15,cyclical_type=2,cyclical_date=1,is_loop=1,weight=100,is_refresh=2 },
[20003] = { id=20003,type=0,unlock_level=1,front_mission={},target1=45,target1_data=2,target1_param1=0,target1_param2=0,target1_arr={},target2=0,target2_data=0,target2_param1=0,target2_param2=0,target2_arr={},start_time=0,end_time=0,rewards={[1]=3000,[39]=10},treasure_chest={},vitality=15,cyclical_type=2,cyclical_date=1,is_loop=1,weight=100,is_refresh=2 },
[20004] = { id=20004,type=0,unlock_level=5,front_mission={},target1=7,target1_data=1,target1_param1=5,target1_param2=0,target1_arr={},target2=0,target2_data=0,target2_param1=0,target2_param2=0,target2_arr={},start_time=0,end_time=0,rewards={[1]=5000,[39]=40},treasure_chest={},vitality=15,cyclical_type=2,cyclical_date=1,is_loop=1,weight=80,is_refresh=2 },
[20005] = { id=20005,type=0,unlock_level=5,front_mission={},target1=83,target1_data=1,target1_param1=0,target1_param2=0,target1_arr={},target2=0,target2_data=0,target2_param1=0,target2_param2=0,target2_arr={},start_time=0,end_time=0,rewards={[1]=5000,[39]=40},treasure_chest={},vitality=15,cyclical_type=2,cyclical_date=1,is_loop=1,weight=80,is_refresh=2 },
[20006] = { id=20006,type=0,unlock_level=1,front_mission={},target1=13,target1_data=2,target1_param1=1,target1_param2=0,target1_arr={1,2},target2=0,target2_data=0,target2_param1=0,target2_param2=0,target2_arr={},start_time=0,end_time=0,rewards={[1]=1500,[39]=10},treasure_chest={},vitality=15,cyclical_type=2,cyclical_date=1,is_loop=1,weight=100,is_refresh=2 },
[21001] = { id=21001,type=0,unlock_level=1,front_mission={},target1=44,target1_data=8,target1_param1=0,target1_param2=0,target1_arr={},target2=0,target2_data=0,target2_param1=0,target2_param2=0,target2_arr={},start_time=0,end_time=0,rewards={[39]=30},treasure_chest={[7]=80},vitality=0,cyclical_type=1,cyclical_date=2,is_loop=1,weight=0,is_refresh=0 },
[21002] = { id=21002,type=0,unlock_level=1,front_mission={},target1=45,target1_data=5,target1_param1=0,target1_param2=0,target1_arr={},target2=0,target2_data=0,target2_param1=0,target2_param2=0,target2_arr={},start_time=0,end_time=0,rewards={[39]=35},treasure_chest={[7]=90},vitality=0,cyclical_type=1,cyclical_date=2,is_loop=1,weight=0,is_refresh=0 },
[21003] = { id=21003,type=0,unlock_level=1,front_mission={},target1=7,target1_data=150,target1_param1=0,target1_param2=0,target1_arr={},target2=0,target2_data=0,target2_param1=0,target2_param2=0,target2_arr={},start_time=0,end_time=0,rewards={[39]=40},treasure_chest={[7]=100},vitality=0,cyclical_type=1,cyclical_date=2,is_loop=1,weight=0,is_refresh=0 },
[21004] = { id=21004,type=0,unlock_level=1,front_mission={},target1=8,target1_data=80000,target1_param1=0,target1_param2=49999,target1_arr={0},target2=0,target2_data=0,target2_param1=0,target2_param2=0,target2_arr={},start_time=0,end_time=0,rewards={[39]=40},treasure_chest={[7]=110},vitality=0,cyclical_type=1,cyclical_date=2,is_loop=1,weight=0,is_refresh=0 },
[21005] = { id=21005,type=0,unlock_level=1,front_mission={},target1=54,target1_data=15,target1_param1=0,target1_param2=0,target1_arr={},target2=0,target2_data=0,target2_param1=0,target2_param2=0,target2_arr={},start_time=0,end_time=0,rewards={[39]=45},treasure_chest={[7]=120},vitality=0,cyclical_type=1,cyclical_date=2,is_loop=1,weight=0,is_refresh=0 },
[21006] = { id=21006,type=0,unlock_level=1,front_mission={},target1=61,target1_data=30,target1_param1=0,target1_param2=1,target1_arr={},target2=0,target2_data=0,target2_param1=0,target2_param2=0,target2_arr={},start_time=0,end_time=0,rewards={[39]=50},treasure_chest={[7]=130},vitality=0,cyclical_type=1,cyclical_date=2,is_loop=1,weight=0,is_refresh=0 },
[21007] = { id=21007,type=0,unlock_level=1,front_mission={},target1=13,target1_data=5,target1_param1=0,target1_param2=0,target1_arr={1,2},target2=0,target2_data=0,target2_param1=0,target2_param2=0,target2_arr={},start_time=0,end_time=0,rewards={[39]=55},treasure_chest={[7]=140},vitality=0,cyclical_type=1,cyclical_date=2,is_loop=1,weight=0,is_refresh=0 }
}