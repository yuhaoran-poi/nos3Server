---@class EquipmentTagPool_cfg
---@field public id integer @词条ID
---@field public lightpooltype integer[] @词条池（对应Item表的lightPoolType） 1-法器 2-剑3-拂尘4-伞5-鞭6-弹弓7-双枪8-关刀9-长枪10-弓箭11-刀12-扇子13-重剑 100-八卦牌 101-灵探八卦牌 102-乾（☰）103-巽（☴）104-坎（☵）105-艮（☶）106-坤（☷）107-震（☳）108-离（☲）109-兑（☱） 150-鬼宠八卦牌 151-乾（☰）152-巽（☴）153-坎（☵）154-艮（☶）155-坤（☷）156-震（☳）157-离（☲）158-兑（☱）
---@field public color integer @词条品质 1.白 2.蓝 3.紫 4.金 5.红
---@field public weight integer @池子权重 0~10000
return {
[1] = { id=1,lightpooltype={1,2,3,4,5,6,7,8,9,10,11,12,13},color=1,weight=10000 },
[2] = { id=2,lightpooltype={1},color=1,weight=10000 },
[3] = { id=3,lightpooltype={2},color=1,weight=10000 },
[4] = { id=4,lightpooltype={3},color=1,weight=10000 },
[5] = { id=5,lightpooltype={4},color=1,weight=10000 },
[6] = { id=6,lightpooltype={5},color=1,weight=10000 },
[7] = { id=7,lightpooltype={6},color=1,weight=10000 },
[8] = { id=8,lightpooltype={7},color=1,weight=10000 },
[9] = { id=9,lightpooltype={8},color=1,weight=10000 },
[10] = { id=10,lightpooltype={9},color=1,weight=10000 },
[11] = { id=11,lightpooltype={10},color=1,weight=10000 },
[12] = { id=12,lightpooltype={11},color=1,weight=10000 },
[13] = { id=13,lightpooltype={12},color=1,weight=10000 },
[14] = { id=14,lightpooltype={13},color=1,weight=10000 },
[15] = { id=15,lightpooltype={100,101,102,103,104,105,106,107,108,109},color=1,weight=10000 },
[16] = { id=16,lightpooltype={100},color=1,weight=10000 },
[17] = { id=17,lightpooltype={101},color=1,weight=10000 },
[18] = { id=18,lightpooltype={102},color=1,weight=10000 },
[19] = { id=19,lightpooltype={103},color=1,weight=10000 },
[20] = { id=20,lightpooltype={104},color=1,weight=10000 },
[21] = { id=21,lightpooltype={105},color=1,weight=10000 },
[22] = { id=22,lightpooltype={106},color=1,weight=10000 },
[23] = { id=23,lightpooltype={107},color=1,weight=10000 },
[24] = { id=24,lightpooltype={108},color=1,weight=10000 },
[25] = { id=25,lightpooltype={109},color=1,weight=10000 },
[26] = { id=26,lightpooltype={150,151,152,153,154,155,156,157,158},color=1,weight=10000 },
[27] = { id=27,lightpooltype={150},color=1,weight=10000 },
[28] = { id=28,lightpooltype={151},color=1,weight=10000 },
[29] = { id=29,lightpooltype={152},color=1,weight=10000 },
[30] = { id=30,lightpooltype={153},color=1,weight=10000 },
[31] = { id=31,lightpooltype={154},color=1,weight=10000 },
[32] = { id=32,lightpooltype={155},color=1,weight=10000 },
[33] = { id=33,lightpooltype={156},color=1,weight=10000 },
[34] = { id=34,lightpooltype={157},color=1,weight=10000 },
[35] = { id=35,lightpooltype={158},color=1,weight=10000 }
}