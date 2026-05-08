---@class SeasonPassShopItemGroup_cfg
---@field public id integer @赛季通行证商店的物品组ID 通行证ID_第几个奖励(最大999)
---@field public unlock_cost integer @解锁所需的功德铢数量 需要在该通行证累计消耗x功德铢解锁
---@field public group integer[] @该页的物品/奖励ID 设计暂定每页9个奖励 玩家购买无顺序限制
return {
[1001] = { id=1001,unlock_cost=0,group={1,2,3,4,5,6,7,8,9} },
[1002] = { id=1002,unlock_cost=100,group={10,11,12,13,14,15,16,17,18} },
[2001] = { id=2001,unlock_cost=0,group={2000,2001,2002,2003,2004,2005,2006,2007,2008} },
[2002] = { id=2002,unlock_cost=100,group={2010,2011,2012,2013,2014,2015,2016,2017,2018} },
[3001] = { id=3001,unlock_cost=0,group={3000,3001,3002,3003,3004,3005,3006,3007,3008} },
[3002] = { id=3002,unlock_cost=100,group={3010,3011,3012,3013,3014,3015,3016,3017,3018} }
}