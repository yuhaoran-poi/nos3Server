---@class UpLvCostIDMapping_cfg
---@field public id integer @唯一ID,升级资源消耗映射ID（ID范围100 ~ 1000）
---@field public cnt integer @可以获得的经验
---@field public cost table @获得经验所需的资源消耗
return {
[100] = { id=100,cnt=1,cost={[1]=1} }
}