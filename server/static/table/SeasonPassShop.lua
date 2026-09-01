---@class SeasonPassShop_cfg
---@field public id integer @通行证id
---@field public default_unlock integer @是否默认解锁 1-解锁 0-不解锁
---@field public unlock_cost table @解锁消耗
---@field public group table @通行证内容 页数：奖励ID组
---@field public time integer @允许购买时间戳
return {
[1] = { id=1,default_unlock=1,unlock_cost={},group={[1]=1001,[2]=1002,[3]=1003,[4]=1004,[5]=1005,[6]=1006,[7]=1007,[8]=1008,[9]=1009,[10]=1010},time=1777543093 },
[2] = { id=2,default_unlock=0,unlock_cost={[3]=6800},group={[1]=2001,[2]=2002,[3]=2003},time=1777543094 },
[3] = { id=3,default_unlock=0,unlock_cost={[1]=1001},group={[1]=3001,[2]=3002},time=1777543095 },
[4] = { id=4,default_unlock=0,unlock_cost={[1]=1002},group={[1]=4001,[2]=4002},time=1777543096 }
}