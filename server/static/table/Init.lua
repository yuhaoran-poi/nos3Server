---@class Init_cfg
---@field public id integer @唯一ID(必须为第一列且名称为id，类型为INT)
---@field public consumables_bag table @账户消耗品背包初始化拥有的内容<id,数量>
---@field public warehouse_bag table @账户仓库初始化拥有的内容<id,数量>
---@field public exp integer @经验值
---@field public collection integer[] @初始解锁图鉴
---@field public head integer @默认装备头像
---@field public head_box integer @默认装备头像框
---@field public title integer @默认装备称号
---@field public unlock_role integer[] @解锁角色
---@field public battle_role integer @出战角色
---@field public battle_ghost integer @出战鬼宠
---@field public named_item integer @改名卡道具ID
return {
[1] = { id=1,consumables_bag={[40030]=5,[40034]=5,[40035]=5,[40039]=5,[40040]=5,[40044]=5,[40050]=5},warehouse_bag={[1]=999999,[46001]=2,[41112]=2,[41027]=4,[41085]=2,[41035]=3,[41033]=4,[41034]=2,[41108]=5,[41082]=5,[41060]=5,[41083]=6,[41011]=10,[41052]=10,[41029]=3,[41109]=4,[41130]=10,[41115]=4,[41111]=2,[41114]=2,[41110]=4,[44001]=2,[41062]=4,[44011]=2,[44016]=2,[41008]=5,[44006]=2,[41087]=10,[41028]=4,[44051]=2,[41113]=1,[41104]=4,[41058]=10,[41107]=5,[41000]=10,[41026]=4,[41061]=4,[41063]=1,[41057]=20,[41059]=10,[41030]=4,[41088]=10,[41038]=2,[41005]=20,[51001]=1,[52001]=1,[52501]=1,[54001]=1,[96000]=1,[96001]=1,[96002]=1,[96003]=1,[96004]=1,[96005]=1,[96006]=1,[96007]=1},exp=0,collection={1015000,1015500,1016600},head=1015000,head_box=1015500,title=1016600,unlock_role={1000001,1000002,1000003,1000004},battle_role=1000003,battle_ghost=0,named_item=34012 }
}