---@class MaintenanceInfo_cfg
---@field public id integer @不同品质类型维修相关信息 1.灰 2.白 3.蓝 4.紫 5.金 6.红 7.粉
---@field public Durability integer @耐久度
---@field public sturdy integer @坚固值
---@field public sturdy_reset_count integer @坚固值恢复次数
---@field public fall_cost integer @倒地耐久扣除
---@field public fail_cost integer @撤离失败耐久扣除
---@field public time_cost table @随时间扣除<秒：扣除点>
return {
[2] = { id=2,Durability=180,sturdy=375,sturdy_reset_count=5,fall_cost=18,fail_cost=54,time_cost={[60]=1} },
[3] = { id=3,Durability=210,sturdy=440,sturdy_reset_count=5,fall_cost=21,fail_cost=63,time_cost={[60]=1} },
[4] = { id=4,Durability=240,sturdy=500,sturdy_reset_count=5,fall_cost=24,fail_cost=72,time_cost={[60]=1} },
[5] = { id=5,Durability=270,sturdy=560,sturdy_reset_count=5,fall_cost=27,fail_cost=81,time_cost={[60]=1} },
[6] = { id=6,Durability=300,sturdy=625,sturdy_reset_count=5,fall_cost=30,fail_cost=90,time_cost={[60]=1} }
}