---@class GhostInfo_cfg
---@field public id integer @鬼宠ID
---@field public ghost_id integer @对应鬼怪ID
---@field public fun_type integer @品质 1.白-尸 2.蓝-野鬼 3.紫-恶鬼 4.金-厉鬼 5.红-猛鬼/鬼将/鬼王
---@field public life integer @初始阴寿
---@field public decompose table @分解可获得的资源
---@field public max_lv integer @最大等级
---@field public character string @性格
---@field public attribute_range integer[] @属性初始化词条池，每个池子都要随机一个ID出来
---@field public init_skill_num integer @初始被动技能数量
---@field public max_skill_num integer @最大被动技能数量
---@field public lock_refresh_cost0 table @无锁定技能消耗
---@field public lock_refresh_cost1 table @锁定1个技能消耗
---@field public lock_refresh_cost2 table @锁定2个技能消耗
---@field public lock_refresh_cost3 table @锁定3个技能消耗
return {
[521000] = { id=521000,ghost_id=2001,fun_type=5,life=100,decompose={[31]=200},max_lv=50,character="1,2,3,4,5",attribute_range={10000,10001},init_skill_num=4,max_skill_num=10,lock_refresh_cost0={[1]=10000},lock_refresh_cost1={[1]=10001},lock_refresh_cost2={[1]=10002},lock_refresh_cost3={[1]=10003} },
[521001] = { id=521001,ghost_id=2019,fun_type=1,life=100,decompose={[31]=200},max_lv=50,character="1,2,3,4,5",attribute_range={10000,10001},init_skill_num=2,max_skill_num=10,lock_refresh_cost0={[1]=10000},lock_refresh_cost1={[1]=10001},lock_refresh_cost2={[1]=10002},lock_refresh_cost3={[1]=10003} }
}