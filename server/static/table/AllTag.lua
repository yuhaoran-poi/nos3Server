---@class AllTag_cfg
---@field public id integer @词条ID 同一种属性可以有多个id 每隔100个id表示一种属性 1000000后的ID表示能力词条
---@field public color integer @词条品质 1.白 2.蓝 3.紫 4.金 5.红
---@field public min integer @词条数值最小值
---@field public max integer @词条数值最大值
---@field public exclusion integer[] @互斥id
---@field public attribute string @属性
return {
[1] = { id=1,color=1,min=100,max=200,exclusion={1,2,3,4,5},attribute="MaxHealth_F" },
[2] = { id=2,color=2,min=1,max=10000,exclusion={1,2,3,4,5},attribute="MaxHealth_P" },
[3] = { id=3,color=3,min=2,max=10001,exclusion={1,2,3,4,5},attribute="MaxHealth_P" },
[4] = { id=4,color=4,min=500,max=1000,exclusion={1,2,3,4,5},attribute="MaxHealth_F" },
[5] = { id=5,color=5,min=750,max=1000,exclusion={1,2,3,4,5},attribute="MaxHealth_F" },
[6] = { id=6,color=1,min=100,max=200,exclusion={6,7,8,9,10},attribute="MaxHealth_F" },
[7] = { id=7,color=2,min=200,max=300,exclusion={6,7,8,9,10},attribute="MaxHealth_F" },
[8] = { id=8,color=3,min=300,max=400,exclusion={6,7,8,9,10},attribute="MaxHealth_F" },
[9] = { id=9,color=4,min=500,max=1000,exclusion={6,7,8,9,10},attribute="MaxHealth_F" },
[10] = { id=10,color=5,min=750,max=1000,exclusion={6,7,8,9,10},attribute="MaxHealth_F" },
[11] = { id=11,color=1,min=1,max=1,exclusion={},attribute="MaxHealth_F" },
[12] = { id=12,color=1,min=1,max=1,exclusion={},attribute="MaxHealth_F" },
[13] = { id=13,color=1,min=1,max=1,exclusion={},attribute="MaxHealth_F" },
[14] = { id=14,color=1,min=1,max=1,exclusion={},attribute="MaxHealth_F" },
[15] = { id=15,color=1,min=1,max=1,exclusion={},attribute="MaxHealth_F" },
[16] = { id=16,color=1,min=1,max=1,exclusion={},attribute="MaxHealth_F" },
[17] = { id=17,color=1,min=1,max=1,exclusion={},attribute="MaxHealth_F" },
[18] = { id=18,color=1,min=1,max=1,exclusion={},attribute="MaxHealth_F" },
[19] = { id=19,color=1,min=1,max=1,exclusion={},attribute="MaxHealth_F" },
[20] = { id=20,color=1,min=1,max=1,exclusion={},attribute="MaxHealth_F" },
[21] = { id=21,color=1,min=1,max=1,exclusion={},attribute="MaxHealth_F" },
[22] = { id=22,color=1,min=1,max=1,exclusion={},attribute="MaxHealth_F" },
[23] = { id=23,color=1,min=1,max=1,exclusion={},attribute="MaxHealth_F" },
[24] = { id=24,color=1,min=1,max=1,exclusion={},attribute="MaxHealth_F" },
[25] = { id=25,color=1,min=1,max=1,exclusion={},attribute="MaxHealth_F" },
[26] = { id=26,color=1,min=1,max=1,exclusion={},attribute="MaxHealth_F" },
[27] = { id=27,color=1,min=1,max=1,exclusion={},attribute="MaxHealth_F" },
[28] = { id=28,color=1,min=1,max=1,exclusion={},attribute="MaxHealth_F" },
[29] = { id=29,color=1,min=1,max=1,exclusion={},attribute="MaxHealth_F" },
[30] = { id=30,color=1,min=1,max=1,exclusion={},attribute="MaxHealth_F" },
[31] = { id=31,color=1,min=1,max=1,exclusion={},attribute="MaxHealth_F" },
[32] = { id=32,color=1,min=1,max=1,exclusion={},attribute="MaxHealth_F" },
[33] = { id=33,color=1,min=1,max=1,exclusion={},attribute="MaxHealth_F" },
[34] = { id=34,color=1,min=1,max=1,exclusion={},attribute="MaxHealth_F" },
[35] = { id=35,color=1,min=1,max=1,exclusion={},attribute="MaxHealth_F" },
[1000000] = { id=1000000,color=1,min=1,max=6,exclusion={},attribute="" },
[1000001] = { id=1000001,color=2,min=2,max=7,exclusion={},attribute="" },
[1000002] = { id=1000002,color=3,min=3,max=8,exclusion={},attribute="" },
[1000003] = { id=1000003,color=4,min=4,max=9,exclusion={},attribute="" },
[1000004] = { id=1000004,color=5,min=5,max=10,exclusion={},attribute="" }
}