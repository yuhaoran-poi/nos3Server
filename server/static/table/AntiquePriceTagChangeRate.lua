---@class AntiquePriceTagChangeRate_cfg
---@field public id integer @唯一ID(必须为第一列且名称为id，类型为INT)
---@field public type integer @品质 1-白 2-蓝 3-紫 4-金 5-红
---@field public pricechange integer @价格变动 1-降 2-平 3-升
---@field public lowlimit integer @下限值（百分比）
---@field public upperlimit integer @上限值（百分比）
---@field public pooltype table @词条池类型 <词条池ID,权重>
return {
[1] = { id=1,type=1,pricechange=1,lowlimit=-50,upperlimit=0,pooltype={[1]=100} },
[2] = { id=2,type=1,pricechange=2,lowlimit=-25,upperlimit=25,pooltype={[1]=100} },
[3] = { id=3,type=1,pricechange=3,lowlimit=10,upperlimit=50,pooltype={[1]=100} },
[4] = { id=4,type=2,pricechange=1,lowlimit=-50,upperlimit=0,pooltype={[1]=100} },
[5] = { id=5,type=2,pricechange=2,lowlimit=-25,upperlimit=25,pooltype={[1]=100} },
[6] = { id=6,type=2,pricechange=3,lowlimit=10,upperlimit=50,pooltype={[1]=100} },
[7] = { id=7,type=3,pricechange=1,lowlimit=-50,upperlimit=0,pooltype={[1]=100} },
[8] = { id=8,type=3,pricechange=2,lowlimit=-25,upperlimit=25,pooltype={[1]=100} },
[9] = { id=9,type=3,pricechange=3,lowlimit=10,upperlimit=50,pooltype={[1]=100} },
[10] = { id=10,type=4,pricechange=1,lowlimit=-50,upperlimit=0,pooltype={[1]=100} },
[11] = { id=11,type=4,pricechange=2,lowlimit=-25,upperlimit=25,pooltype={[1]=100} },
[12] = { id=12,type=4,pricechange=3,lowlimit=10,upperlimit=50,pooltype={[1]=100} },
[13] = { id=13,type=5,pricechange=1,lowlimit=-50,upperlimit=0,pooltype={[1]=100} },
[14] = { id=14,type=5,pricechange=2,lowlimit=-25,upperlimit=25,pooltype={[1]=100} },
[15] = { id=15,type=5,pricechange=3,lowlimit=10,upperlimit=50,pooltype={[1]=100} }
}