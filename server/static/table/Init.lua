---@class Init_cfg
---@field public id integer @唯一ID(必须为第一列且名称为id，类型为INT)
---@field public consumables_bag table @账户消耗品背包初始化拥有的内容<id,数量>
---@field public warehouse_bag table @账户仓库初始化拥有的内容<id,数量>
---@field public exp integer @经验值
---@field public head integer @头像
---@field public head_box integer @头像框
---@field public title integer @称号
---@field public unlock_role integer[] @解锁角色
---@field public battle_role integer @出战角色
---@field public battle_ghost integer @出战鬼宠
---@field public named_item integer @改名卡道具ID
return {
[1] = { id=1,consumables_bag={[40001]=10,[40002]=1},warehouse_bag={[1015000]=1,[1015500]=1,[1000000]=1,[1000001]=1,[1016000]=1,[1016500]=1,[1016501]=1,[600000]=1,[1]=1000,[2]=1000,[3]=1000,[4]=1000,[1000003]=1},exp=0,head=1015000,head_box=1015500,title=0,unlock_role={1000000,1000001,1000002,1000003,1000004},battle_role=1000003,battle_ghost=0,named_item=40001 }
}