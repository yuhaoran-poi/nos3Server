---@class Skin_cfg
---@field public id integer @皮肤ID 1132000 ~ 1302000 170000 灵探皮肤 1015000 ~ 1015500 500 头像 1015500 ~ 1016000 500 头像框
---@field public type integer @类型 ----灵探 发型：1 连衣裙：2 连体衣：3 上衣：4 下装：5 袜子：6 鞋子：7 头饰：8 面饰：9 法器：10 腰饰：11 手部：12 特殊 1（大招）：13 特殊 2（处决）：14 表情动作：15 出场动画：16 背饰：17 道具：18(另建表里了) 头像：19 头像框：20 称号：21
---@field public color integer @品质 1.白 2.蓝 3.紫 4.金 5.红
---@field public belong integer @皮肤所属的角色ID
return {
[1015000] = { id=1015000,type=19,color=2,belong=0 },
[1015001] = { id=1015001,type=19,color=3,belong=0 },
[1015002] = { id=1015002,type=19,color=4,belong=0 },
[1015500] = { id=1015500,type=20,color=2,belong=0 },
[1015501] = { id=1015501,type=20,color=3,belong=0 },
[1015502] = { id=1015502,type=20,color=4,belong=0 },
[1016600] = { id=1016600,type=21,color=3,belong=0 },
[1016601] = { id=1016601,type=21,color=4,belong=0 },
[1016602] = { id=1016602,type=21,color=5,belong=0 },
[1132006] = { id=1132006,type=1,color=4,belong=1000005 },
[1142000] = { id=1142000,type=2,color=3,belong=1000001 },
[1142005] = { id=1142005,type=2,color=5,belong=1000001 },
[1152000] = { id=1152000,type=1,color=1,belong=1000004 },
[1162000] = { id=1162000,type=4,color=2,belong=1000000 },
[1162001] = { id=1162001,type=4,color=5,belong=1000003 },
[1162002] = { id=1162002,type=4,color=5,belong=1000002 },
[1162003] = { id=1162003,type=4,color=1,belong=1000001 },
[1162006] = { id=1162006,type=4,color=4,belong=1000005 },
[1172000] = { id=1172000,type=5,color=3,belong=1000000 },
[1172001] = { id=1172001,type=5,color=1,belong=1000003 },
[1172002] = { id=1172002,type=5,color=1,belong=1000002 },
[1172003] = { id=1172003,type=5,color=1,belong=1000001 },
[1172006] = { id=1172006,type=5,color=4,belong=1000005 },
[1182000] = { id=1182000,type=6,color=2,belong=1000002 },
[1182005] = { id=1182005,type=6,color=4,belong=1000001 },
[1192000] = { id=1192000,type=7,color=4,belong=1000000 },
[1192001] = { id=1192001,type=7,color=2,belong=1000003 },
[1192002] = { id=1192002,type=7,color=4,belong=1000001 },
[1192003] = { id=1192003,type=7,color=3,belong=1000002 },
[1192004] = { id=1192004,type=7,color=1,belong=1000001 },
[1192005] = { id=1192005,type=7,color=3,belong=1000001 },
[1192006] = { id=1192006,type=7,color=4,belong=1000005 },
[1202005] = { id=1202005,type=8,color=3,belong=1000001 },
[1202006] = { id=1202006,type=8,color=4,belong=1000005 },
[1212005] = { id=1212005,type=9,color=2,belong=1000001 },
[1232005] = { id=1232005,type=11,color=1,belong=1000001 }
}