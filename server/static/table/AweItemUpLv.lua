---@class AweItemUpLv_cfg
---@field public id integer @等级
---@field public cost table @每一级升级所需的材料 id：数量 直接消耗，没有经验值的概念
---@field public condition integer @升级条件：赛季通行证等级 达到该等级后才能升级到该等级
---@field public max_star integer @该等级允许提升的最大星级
return {
[1] = { id=1,cost={[1]=10},condition=0,max_star=1 },
[2] = { id=2,cost={[1]=11},condition=0,max_star=1 },
[3] = { id=3,cost={[1]=12},condition=0,max_star=1 },
[4] = { id=4,cost={[1]=13},condition=10,max_star=2 },
[5] = { id=5,cost={[1]=14},condition=10,max_star=2 },
[6] = { id=6,cost={[1]=15},condition=10,max_star=2 },
[7] = { id=7,cost={[1]=16},condition=20,max_star=3 },
[8] = { id=8,cost={[1]=17},condition=20,max_star=3 },
[9] = { id=9,cost={[1]=18},condition=20,max_star=3 },
[10] = { id=10,cost={[1]=19},condition=30,max_star=4 },
[11] = { id=11,cost={[1]=20},condition=30,max_star=4 },
[12] = { id=12,cost={[1]=21},condition=30,max_star=4 },
[13] = { id=13,cost={[1]=22},condition=40,max_star=5 },
[14] = { id=14,cost={[1]=23},condition=40,max_star=5 },
[15] = { id=15,cost={[1]=24},condition=40,max_star=5 }
}