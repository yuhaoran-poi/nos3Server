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
[1] = { id=1,consumables_bag={[40030]=5,[40034]=5,[40035]=5,[40039]=5,[40040]=5,[40044]=5,[40050]=5},warehouse_bag={[1]=999999,[40030]=50,[40034]=30,[40035]=40,[40039]=30,[40040]=40,[40044]=50,[40050]=50,[46001]=4,[41112]=4,[41027]=8,[41085]=4,[41035]=6,[41033]=8,[41034]=4,[41108]=10,[41082]=4,[41060]=10,[41083]=12,[41011]=20,[41052]=20,[41029]=6,[41109]=8,[41130]=20,[41115]=8,[41111]=4,[41114]=4,[41110]=8,[44001]=4,[41062]=8,[44011]=4,[44016]=4,[41008]=40,[44006]=4,[41087]=20,[41028]=8},exp=0,collection={1015000,1015500,1016600},head=1015000,head_box=1015500,title=1016600,unlock_role={1000001,1000002,1000003,1000004},battle_role=1000003,battle_ghost=0,named_item=34012 }
}