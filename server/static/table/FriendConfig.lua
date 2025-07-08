---@class FriendConfig_cfg
---@field public id integer @唯一ID(必须为第一列且名称为id，类型为INT)
---@field public Friend_limit integer @好友列表上限
---@field public apply_limit integer @申请列表上限
---@field public Group_limit integer @分组上限
---@field public Blacklist_limit integer @黑名单上限
return {
[1] = { id=1,Friend_limit=50,apply_limit=10,Group_limit=10,Blacklist_limit=50 }
}