---@class AweItem_cfg
---@field public id integer @镇山之宝 id
---@field public lv_up integer[] @每一级升级所需的材料 id
---@field public unlock_item table @解锁需要的材料
---@field public account_buff integer[] @每一级对应的账户 buff id
return {
[1] = { id=1,lv_up={1},unlock_item={[1]=10},account_buff={1} },
[2] = { id=2,lv_up={2},unlock_item={[1]=10},account_buff={1} }
}