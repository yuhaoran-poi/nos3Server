---@class Skin_cfg
---@field public id integer @皮肤ID 1132000 ~ 1332000 200000 灵探皮肤
---@field public type integer @类型 ----灵探 发型：1 连衣裙：2 连体衣：3 上衣：4 下装：5 袜子：6 鞋子：7 头饰：8 面饰：9 法器：10 腰饰：11 手部：12 特殊 1（大招）：13 特殊 2（处决）：14 表情动作：15
---@field public color integer @品质 1.白 2.蓝 3.紫 4.金 5.红
---@field public belong integer @皮肤所属的角色ID
return {
[1132000] = { id=1132000,type=1,color=1,belong=1000000 },
[1132001] = { id=1132001,type=2,color=2,belong=1000000 },
[1132002] = { id=1132002,type=3,color=3,belong=1000000 },
[1132003] = { id=1132003,type=4,color=4,belong=1000001 },
[1132004] = { id=1132004,type=5,color=5,belong=1000001 },
[1132005] = { id=1132005,type=6,color=1,belong=1000001 },
[1132006] = { id=1132006,type=7,color=2,belong=1000002 },
[1132007] = { id=1132007,type=8,color=1,belong=1000002 },
[1132008] = { id=1132008,type=8,color=2,belong=1000002 },
[1132009] = { id=1132009,type=9,color=1,belong=1000003 },
[1132010] = { id=1132010,type=9,color=2,belong=1000003 }
}