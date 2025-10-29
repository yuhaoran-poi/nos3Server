---@class AntiqueItem_cfg
---@field public id integer @古董ID
---@field public identifynum integer @鉴定次数
---@field public quality integer @品质
---@field public identifycost table @鉴定消耗
---@field public trueprobability integer @鉴定为真的概率，否则为假 0~10000
---@field public initprice table @初始价格
return {
[625000] = { id=625000,identifynum=4,quality=1,identifycost={[1]=100},trueprobability=5000,initprice={[1]=100} },
[625001] = { id=625001,identifynum=5,quality=1,identifycost={[1]=101},trueprobability=5000,initprice={[1]=101} },
[625002] = { id=625002,identifynum=4,quality=2,identifycost={[1]=102},trueprobability=5000,initprice={[1]=102} },
[625003] = { id=625003,identifynum=4,quality=2,identifycost={[1]=103},trueprobability=5000,initprice={[1]=103} },
[625004] = { id=625004,identifynum=4,quality=2,identifycost={[1]=104},trueprobability=5000,initprice={[1]=104} },
[625005] = { id=625005,identifynum=5,quality=3,identifycost={[1]=105},trueprobability=5000,initprice={[1]=105} },
[625006] = { id=625006,identifynum=5,quality=3,identifycost={[1]=106},trueprobability=5000,initprice={[1]=106} },
[625007] = { id=625007,identifynum=5,quality=4,identifycost={[1]=107},trueprobability=5000,initprice={[1]=107} },
[625008] = { id=625008,identifynum=5,quality=4,identifycost={[1]=108},trueprobability=5000,initprice={[1]=108} },
[625009] = { id=625009,identifynum=5,quality=5,identifycost={[1]=109},trueprobability=5000,initprice={[1]=109} }
}