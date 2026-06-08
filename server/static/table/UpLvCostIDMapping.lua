---@class UpLvCostIDMapping_cfg
---@field public id integer @唯一ID 需要和各个升级表（末尾UpLv的表）对应
---@field public cnt integer @可以获得的经验
---@field public cost table @获得经验所需的资源消耗 资源ID：数量
return {
[100] = { id=100,cnt=1,cost={[1]=1} },
[33] = { id=33,cnt=1,cost={[1]=1} },
[34] = { id=34,cnt=1,cost={[1]=1} },
[35] = { id=35,cnt=1,cost={[1]=1} },
[101] = { id=101,cnt=1,cost={[36]=1} },
[102] = { id=102,cnt=1,cost={[37]=1} },
[103] = { id=103,cnt=1,cost={[38]=1} }
}