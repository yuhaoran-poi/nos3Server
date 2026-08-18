---@class MaintenanceCost1_cfg
---@field public id integer @
---@field public type1 integer @八卦牌：1 法器：2 戒指：3
---@field public type2 integer @1.灰 2.白 3.蓝 4.紫 5.金 6.红 7.粉
---@field public cost table @每点耐久的维修费用
return {
[1] = { id=1,type1=1,type2=2,cost={[1]=26} },
[2] = { id=2,type1=1,type2=3,cost={[1]=67} },
[3] = { id=3,type1=1,type2=4,cost={[1]=117} },
[4] = { id=4,type1=1,type2=5,cost={[1]=260} },
[5] = { id=5,type1=1,type2=6,cost={[1]=750} },
[6] = { id=6,type1=2,type2=2,cost={[1]=260} },
[7] = { id=7,type1=2,type2=3,cost={[1]=670} },
[8] = { id=8,type1=2,type2=4,cost={[1]=1172} },
[9] = { id=9,type1=2,type2=5,cost={[1]=2604} },
[10] = { id=10,type1=2,type2=6,cost={[1]=6250} },
[11] = { id=11,type1=3,type2=2,cost={[1]=174} },
[12] = { id=12,type1=3,type2=3,cost={[1]=446} },
[13] = { id=13,type1=3,type2=4,cost={[1]=781} },
[14] = { id=14,type1=3,type2=5,cost={[1]=1736} },
[15] = { id=15,type1=3,type2=6,cost={[1]=4167} }
}