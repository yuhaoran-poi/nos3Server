---@class Init_cfg
---@field public id integer @唯一ID(必须为第一列且名称为id，类型为INT)
---@field public item table @账户初始化拥有的内容<id,数量>
---@field public exp integer @经验值
---@field public head integer @头像
---@field public head_box integer @头像框
---@field public title integer @称号
---@field public battle_role integer @出战角色
---@field public battle_ghost integer @出战鬼宠
---@field public god1 integer @神明1
---@field public god2 integer @神明2
return {
[1] = { id=1,item={[1015000]=1,[1015500]=1,[1000000]=1,[1000001]=1,[1016000]=1,[1016500]=1,[1016501]=1},exp=0,head=1015000,head_box=1015500,title=0,battle_role=1000000,battle_ghost=0,god1=1016500,god2=1016501 }
}