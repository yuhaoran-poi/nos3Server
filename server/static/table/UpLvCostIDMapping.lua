---@class UpLvCostIDMapping_cfg
---@field public id integer @唯一ID
---@field public cnt integer @可以获得的经验
---@field public cost table @获得经验所需的资源消耗
return {
[100] = { id=100,cnt=1,cost={[1]=1} },
[33] = { id=33,cnt=1,cost={[1]=1} },
[34] = { id=34,cnt=1,cost={[1]=1} }
}