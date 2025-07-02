---@class UniqueItem_cfg
---@field public id integer @唯一道具id
---@field public type1 integer @资源大类型 其他：0 讳字：1 卦象：2 主星：3 法印：4 辅星：5 鬼宠装备：6
---@field public type2 integer @品质 1.白 2.蓝 3.紫 4.金 5.红
---@field public tagcost integer @属性 0.无 1.金 2.水 3.木 4.火 5.土
---@field public type4 integer @自定义类型1 0.无
---@field public type5 integer @自定义类型2 0.无
---@field public type6 integer @自定义类型3 0.无
---@field public removecost table @卸下消耗
---@field public decompose table @分解可获得的资源
---@field public durability integer @耐久值
---@field public sturdy integer @坚固值
return {
[600000] = { id=600000,type1=0,type2=1,tagcost=0,type4=101,type5=0,type6=0,removecost={[1]=1000},decompose={[1]=1000},durability=50,sturdy=100 },
[600001] = { id=600001,type1=0,type2=1,tagcost=0,type4=101,type5=0,type6=0,removecost={[1]=1000},decompose={[1]=1000},durability=50,sturdy=100 },
[600002] = { id=600002,type1=0,type2=2,tagcost=0,type4=101,type5=0,type6=0,removecost={[1]=1000},decompose={[1]=1000},durability=50,sturdy=100 },
[600003] = { id=600003,type1=0,type2=3,tagcost=0,type4=101,type5=0,type6=0,removecost={[1]=1000},decompose={[1]=1000},durability=50,sturdy=100 },
[600500] = { id=600500,type1=0,type2=1,tagcost=0,type4=102,type5=0,type6=0,removecost={[1]=1000},decompose={[1]=1000},durability=50,sturdy=100 },
[600501] = { id=600501,type1=0,type2=1,tagcost=0,type4=102,type5=0,type6=0,removecost={[1]=1000},decompose={[1]=1000},durability=50,sturdy=100 },
[600502] = { id=600502,type1=0,type2=2,tagcost=0,type4=102,type5=0,type6=0,removecost={[1]=1000},decompose={[1]=1000},durability=50,sturdy=100 },
[600503] = { id=600503,type1=0,type2=3,tagcost=0,type4=102,type5=0,type6=0,removecost={[1]=1000},decompose={[1]=1000},durability=50,sturdy=100 },
[601000] = { id=601000,type1=0,type2=1,tagcost=0,type4=103,type5=0,type6=0,removecost={[1]=1000},decompose={[1]=1000},durability=50,sturdy=100 },
[601001] = { id=601001,type1=0,type2=1,tagcost=0,type4=103,type5=0,type6=0,removecost={[1]=1000},decompose={[1]=1000},durability=50,sturdy=100 },
[601002] = { id=601002,type1=0,type2=2,tagcost=0,type4=103,type5=0,type6=0,removecost={[1]=1000},decompose={[1]=1000},durability=50,sturdy=100 },
[601003] = { id=601003,type1=0,type2=3,tagcost=0,type4=103,type5=0,type6=0,removecost={[1]=1000},decompose={[1]=1000},durability=50,sturdy=100 },
[601500] = { id=601500,type1=0,type2=1,tagcost=0,type4=104,type5=0,type6=0,removecost={[1]=1000},decompose={[1]=1000},durability=50,sturdy=100 },
[601501] = { id=601501,type1=0,type2=1,tagcost=0,type4=104,type5=0,type6=0,removecost={[1]=1000},decompose={[1]=1000},durability=50,sturdy=100 },
[601502] = { id=601502,type1=0,type2=2,tagcost=0,type4=104,type5=0,type6=0,removecost={[1]=1000},decompose={[1]=1000},durability=50,sturdy=100 },
[601503] = { id=601503,type1=0,type2=3,tagcost=0,type4=104,type5=0,type6=0,removecost={[1]=1000},decompose={[1]=1000},durability=50,sturdy=100 },
[601504] = { id=601504,type1=0,type2=3,tagcost=0,type4=104,type5=0,type6=0,removecost={[1]=1000},decompose={[1]=1000},durability=50,sturdy=100 },
[602000] = { id=602000,type1=0,type2=1,tagcost=0,type4=105,type5=0,type6=0,removecost={[1]=1000},decompose={[1]=1000},durability=25,sturdy=1000 },
[602001] = { id=602001,type1=0,type2=1,tagcost=0,type4=105,type5=0,type6=0,removecost={[1]=1000},decompose={[1]=1000},durability=50,sturdy=100 },
[602500] = { id=602500,type1=0,type2=1,tagcost=0,type4=106,type5=0,type6=0,removecost={[1]=1000},decompose={[1]=1000},durability=50,sturdy=100 },
[602501] = { id=602501,type1=0,type2=1,tagcost=0,type4=106,type5=0,type6=0,removecost={[1]=1000},decompose={[1]=1000},durability=50,sturdy=100 },
[603000] = { id=603000,type1=0,type2=1,tagcost=0,type4=107,type5=0,type6=0,removecost={[1]=1000},decompose={[1]=1000},durability=50,sturdy=100 },
[603001] = { id=603001,type1=0,type2=1,tagcost=0,type4=107,type5=0,type6=0,removecost={[1]=1000},decompose={[1]=1000},durability=50,sturdy=100 },
[603500] = { id=603500,type1=0,type2=1,tagcost=0,type4=108,type5=0,type6=0,removecost={[1]=1000},decompose={[1]=1000},durability=50,sturdy=100 },
[603501] = { id=603501,type1=0,type2=1,tagcost=0,type4=108,type5=0,type6=0,removecost={[1]=1000},decompose={[1]=1000},durability=50,sturdy=100 },
[604000] = { id=604000,type1=0,type2=1,tagcost=0,type4=109,type5=0,type6=0,removecost={[1]=1000},decompose={[1]=1000},durability=50,sturdy=100 },
[604001] = { id=604001,type1=0,type2=1,tagcost=0,type4=109,type5=0,type6=0,removecost={[1]=1000},decompose={[1]=1000},durability=50,sturdy=100 },
[604500] = { id=604500,type1=0,type2=1,tagcost=0,type4=110,type5=0,type6=0,removecost={[1]=1000},decompose={[1]=1000},durability=50,sturdy=100 },
[604501] = { id=604501,type1=0,type2=1,tagcost=0,type4=110,type5=0,type6=0,removecost={[1]=1000},decompose={[1]=1000},durability=50,sturdy=100 },
[605000] = { id=605000,type1=0,type2=1,tagcost=0,type4=111,type5=0,type6=0,removecost={[1]=1000},decompose={[1]=1000},durability=50,sturdy=100 },
[605001] = { id=605001,type1=0,type2=1,tagcost=0,type4=111,type5=0,type6=0,removecost={[1]=1000},decompose={[1]=1000},durability=50,sturdy=100 },
[605500] = { id=605500,type1=0,type2=1,tagcost=0,type4=112,type5=0,type6=0,removecost={[1]=1000},decompose={[1]=1000},durability=50,sturdy=100 },
[605501] = { id=605501,type1=0,type2=1,tagcost=0,type4=112,type5=0,type6=0,removecost={[1]=1000},decompose={[1]=1000},durability=50,sturdy=100 },
[521000] = { id=521000,type1=0,type2=1,tagcost=1,type4=0,type5=0,type6=0,removecost={[1]=10113},decompose={[1]=123},durability=0,sturdy=0 },
[521001] = { id=521001,type1=0,type2=2,tagcost=2,type4=0,type5=0,type6=0,removecost={[1]=10113},decompose={[1]=123},durability=0,sturdy=0 },
[521002] = { id=521002,type1=0,type2=3,tagcost=3,type4=0,type5=0,type6=0,removecost={[1]=10113},decompose={[1]=123},durability=0,sturdy=0 },
[521003] = { id=521003,type1=0,type2=4,tagcost=4,type4=0,type5=0,type6=0,removecost={[1]=10113},decompose={[1]=123},durability=0,sturdy=0 },
[521004] = { id=521004,type1=0,type2=5,tagcost=5,type4=0,type5=0,type6=0,removecost={[1]=10113},decompose={[1]=123},durability=0,sturdy=0 },
[523000] = { id=523000,type1=0,type2=1,tagcost=0,type4=0,type5=0,type6=0,removecost={[1]=100},decompose={[1]=100},durability=0,sturdy=0 },
[523001] = { id=523001,type1=0,type2=1,tagcost=0,type4=0,type5=0,type6=0,removecost={[1]=100},decompose={[1]=100},durability=0,sturdy=0 },
[523002] = { id=523002,type1=0,type2=1,tagcost=0,type4=0,type5=0,type6=0,removecost={[1]=100},decompose={[1]=100},durability=0,sturdy=0 },
[523003] = { id=523003,type1=0,type2=1,tagcost=0,type4=0,type5=0,type6=0,removecost={[1]=100},decompose={[1]=100},durability=0,sturdy=0 },
[523004] = { id=523004,type1=0,type2=1,tagcost=0,type4=0,type5=0,type6=0,removecost={[1]=100},decompose={[1]=100},durability=0,sturdy=0 },
[523005] = { id=523005,type1=0,type2=1,tagcost=0,type4=0,type5=0,type6=0,removecost={[1]=100},decompose={[1]=100},durability=0,sturdy=0 },
[523006] = { id=523006,type1=0,type2=1,tagcost=0,type4=0,type5=0,type6=0,removecost={[1]=100},decompose={[1]=100},durability=0,sturdy=0 },
[523007] = { id=523007,type1=0,type2=1,tagcost=0,type4=0,type5=0,type6=0,removecost={[1]=100},decompose={[1]=100},durability=0,sturdy=0 },
[523008] = { id=523008,type1=0,type2=1,tagcost=0,type4=0,type5=0,type6=0,removecost={[1]=100},decompose={[1]=100},durability=0,sturdy=0 },
[523009] = { id=523009,type1=0,type2=1,tagcost=0,type4=0,type5=0,type6=0,removecost={[1]=100},decompose={[1]=100},durability=0,sturdy=0 },
[630000] = { id=630000,type1=0,type2=1,tagcost=0,type4=1000,type5=1,type6=0,removecost={[1]=100},decompose={[1]=100},durability=50,sturdy=100 },
[630001] = { id=630001,type1=0,type2=1,tagcost=0,type4=1000,type5=2,type6=0,removecost={[1]=100},decompose={[1]=100},durability=50,sturdy=100 },
[630002] = { id=630002,type1=0,type2=1,tagcost=0,type4=1000,type5=3,type6=0,removecost={[1]=100},decompose={[1]=100},durability=50,sturdy=100 },
[630003] = { id=630003,type1=0,type2=1,tagcost=0,type4=1000,type5=4,type6=0,removecost={[1]=100},decompose={[1]=100},durability=50,sturdy=100 },
[630004] = { id=630004,type1=0,type2=1,tagcost=0,type4=1000,type5=5,type6=0,removecost={[1]=100},decompose={[1]=100},durability=50,sturdy=100 },
[630005] = { id=630005,type1=0,type2=1,tagcost=0,type4=1000,type5=6,type6=0,removecost={[1]=100},decompose={[1]=100},durability=50,sturdy=100 },
[630006] = { id=630006,type1=0,type2=1,tagcost=0,type4=1000,type5=7,type6=0,removecost={[1]=100},decompose={[1]=100},durability=50,sturdy=100 },
[630007] = { id=630007,type1=0,type2=1,tagcost=0,type4=1000,type5=8,type6=0,removecost={[1]=100},decompose={[1]=100},durability=50,sturdy=100 },
[640000] = { id=640000,type1=0,type2=1,tagcost=0,type4=1001,type5=1,type6=0,removecost={[1]=100},decompose={[1]=100},durability=50,sturdy=100 },
[640001] = { id=640001,type1=0,type2=1,tagcost=0,type4=1001,type5=2,type6=0,removecost={[1]=100},decompose={[1]=100},durability=50,sturdy=100 },
[640002] = { id=640002,type1=0,type2=1,tagcost=0,type4=1001,type5=3,type6=0,removecost={[1]=100},decompose={[1]=100},durability=50,sturdy=100 },
[640003] = { id=640003,type1=0,type2=1,tagcost=0,type4=1001,type5=4,type6=0,removecost={[1]=100},decompose={[1]=100},durability=50,sturdy=100 },
[640004] = { id=640004,type1=0,type2=1,tagcost=0,type4=1001,type5=5,type6=0,removecost={[1]=100},decompose={[1]=100},durability=50,sturdy=100 },
[640005] = { id=640005,type1=0,type2=1,tagcost=0,type4=1001,type5=6,type6=0,removecost={[1]=100},decompose={[1]=100},durability=50,sturdy=100 },
[640006] = { id=640006,type1=0,type2=1,tagcost=0,type4=1001,type5=7,type6=0,removecost={[1]=100},decompose={[1]=100},durability=50,sturdy=100 },
[640007] = { id=640007,type1=0,type2=1,tagcost=0,type4=1001,type5=8,type6=0,removecost={[1]=100},decompose={[1]=100},durability=50,sturdy=100 }
}