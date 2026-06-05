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
[1] = { id=1,consumables_bag={[500001]=1,[500002]=1,[40003]=1,[40004]=1,[40008]=3,[40015]=3,[500007]=1},warehouse_bag={[1]=10000000,[2]=1000000,[41001]=30,[41002]=30,[41003]=30,[41004]=30,[41005]=30,[41006]=30,[41007]=30,[41008]=30,[41009]=30,[41010]=30,[41011]=30,[41012]=30,[41013]=30,[41014]=30,[41015]=30,[41016]=30,[41017]=30,[41018]=30,[41019]=30,[41022]=30},exp=0,collection={1015000,1015500,1016600},head=1015000,head_box=1015500,title=1016600,unlock_role={1000000,1000001,1000002,1000003,1000004},battle_role=1000003,battle_ghost=0,named_item=34012 }
}