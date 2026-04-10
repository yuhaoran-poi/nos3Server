---@class UniqueItem_cfg
---@field public id integer @唯一道具id
---@field public type1 integer @资源大类型 其他：0 八卦牌：1 法器：2 戒指：3
---@field public type2 integer @品质 1.白 2.蓝 3.紫 4.金 5.红
---@field public type3 integer @属性 0.无 1.金 2.水 3.木 4.火 5.土
---@field public type4 integer @自定义类型1 0.无
---@field public type5 integer @自定义类型2 0.无
---@field public type6 integer @自定义类型3 0.无
---@field public market integer[] @交易行/拍卖行分类
---@field public removecost table @卸下消耗
---@field public decompose table @分解可获得的资源
---@field public durability integer @耐久值
---@field public sturdy integer @坚固值
---@field public item_weight integer @负重值/10000
---@field public deal_num integer @可交易次数
---@field public could_sell integer @是否能上架到交易行/拍卖行 0=不可上架 1=可以上架
---@field public sell_value table @出售价格（NPC回收）： 配置为空 = 不可出售
---@field public Text_type integer[] @可镶嵌的讳字类型 item的type4
return {
[600000] = { id=600000,type1=0,type2=1,type3=0,type4=101,type5=0,type6=0,market={1,0,0,0,0,0},removecost={[1]=1000},decompose={[1]=1000},durability=50,sturdy=100,item_weight=1,deal_num=3,could_sell=1,sell_value={},Text_type={1,2} },
[600001] = { id=600001,type1=0,type2=1,type3=0,type4=101,type5=0,type6=0,market={1,0,0,0,0,0},removecost={[1]=1000},decompose={[1]=1000},durability=50,sturdy=100,item_weight=1,deal_num=3,could_sell=1,sell_value={},Text_type={3,4} },
[600002] = { id=600002,type1=0,type2=2,type3=0,type4=101,type5=0,type6=0,market={1,0,0,0,0,0},removecost={[1]=1000},decompose={[1]=1000},durability=50,sturdy=100,item_weight=1,deal_num=3,could_sell=1,sell_value={},Text_type={5,6} },
[600003] = { id=600003,type1=0,type2=3,type3=0,type4=101,type5=0,type6=0,market={1,0,0,0,0,0},removecost={[1]=1000},decompose={[1]=1000},durability=50,sturdy=100,item_weight=1,deal_num=3,could_sell=1,sell_value={},Text_type={} },
[600500] = { id=600500,type1=0,type2=1,type3=0,type4=102,type5=0,type6=0,market={1,0,0,0,0,0},removecost={[1]=1000},decompose={[1]=1000},durability=50,sturdy=100,item_weight=1,deal_num=3,could_sell=1,sell_value={},Text_type={} },
[600501] = { id=600501,type1=0,type2=1,type3=0,type4=102,type5=0,type6=0,market={1,0,0,0,0,0},removecost={[1]=1000},decompose={[1]=1000},durability=50,sturdy=100,item_weight=1,deal_num=3,could_sell=1,sell_value={},Text_type={} },
[600502] = { id=600502,type1=0,type2=2,type3=0,type4=102,type5=0,type6=0,market={1,0,0,0,0,0},removecost={[1]=1000},decompose={[1]=1000},durability=50,sturdy=100,item_weight=1,deal_num=3,could_sell=1,sell_value={},Text_type={} },
[600503] = { id=600503,type1=0,type2=3,type3=0,type4=102,type5=0,type6=0,market={1,0,0,0,0,0},removecost={[1]=1000},decompose={[1]=1000},durability=50,sturdy=100,item_weight=1,deal_num=3,could_sell=1,sell_value={},Text_type={} },
[601000] = { id=601000,type1=0,type2=1,type3=0,type4=103,type5=0,type6=0,market={1,0,0,0,0,0},removecost={[1]=1000},decompose={[1]=1000},durability=50,sturdy=100,item_weight=1,deal_num=3,could_sell=1,sell_value={},Text_type={} },
[601001] = { id=601001,type1=0,type2=1,type3=0,type4=103,type5=0,type6=0,market={1,0,0,0,0,0},removecost={[1]=1000},decompose={[1]=1000},durability=50,sturdy=100,item_weight=1,deal_num=3,could_sell=1,sell_value={},Text_type={} },
[601002] = { id=601002,type1=0,type2=2,type3=0,type4=103,type5=0,type6=0,market={1,0,0,0,0,0},removecost={[1]=1000},decompose={[1]=1000},durability=50,sturdy=100,item_weight=1,deal_num=3,could_sell=1,sell_value={[1]=100},Text_type={} },
[601003] = { id=601003,type1=0,type2=3,type3=0,type4=103,type5=0,type6=0,market={1,0,0,0,0,0},removecost={[1]=1000},decompose={[1]=1000},durability=50,sturdy=100,item_weight=1,deal_num=3,could_sell=1,sell_value={[1]=100},Text_type={} },
[601500] = { id=601500,type1=0,type2=1,type3=0,type4=104,type5=0,type6=0,market={1,0,0,0,0,0},removecost={[1]=1000},decompose={[1]=1000},durability=50,sturdy=100,item_weight=1,deal_num=3,could_sell=1,sell_value={[1]=100},Text_type={} },
[601501] = { id=601501,type1=0,type2=1,type3=0,type4=104,type5=0,type6=0,market={1,0,0,0,0,0},removecost={[1]=1000},decompose={[1]=1000},durability=50,sturdy=100,item_weight=1,deal_num=3,could_sell=1,sell_value={[1]=100},Text_type={} },
[601502] = { id=601502,type1=0,type2=2,type3=0,type4=104,type5=0,type6=0,market={1,0,0,0,0,0},removecost={[1]=1000},decompose={[1]=1000},durability=50,sturdy=100,item_weight=1,deal_num=3,could_sell=1,sell_value={[1]=100},Text_type={} },
[601503] = { id=601503,type1=0,type2=3,type3=0,type4=104,type5=0,type6=0,market={1,0,0,0,0,0},removecost={[1]=1000},decompose={[1]=1000},durability=50,sturdy=100,item_weight=1,deal_num=3,could_sell=1,sell_value={[1]=100},Text_type={} },
[601504] = { id=601504,type1=0,type2=3,type3=0,type4=104,type5=0,type6=0,market={1,0,0,0,0,0},removecost={[1]=1000},decompose={[1]=1000},durability=50,sturdy=100,item_weight=1,deal_num=3,could_sell=1,sell_value={[1]=100},Text_type={} },
[602000] = { id=602000,type1=0,type2=1,type3=0,type4=105,type5=0,type6=0,market={1,0,0,0,0,0},removecost={[1]=1000},decompose={[1]=1000},durability=25,sturdy=1000,item_weight=1,deal_num=3,could_sell=1,sell_value={[1]=100},Text_type={} },
[602001] = { id=602001,type1=0,type2=1,type3=0,type4=105,type5=0,type6=0,market={1,0,0,0,0,0},removecost={[1]=1000},decompose={[1]=1000},durability=50,sturdy=100,item_weight=1,deal_num=3,could_sell=1,sell_value={[1]=100},Text_type={} },
[602500] = { id=602500,type1=0,type2=1,type3=0,type4=106,type5=0,type6=0,market={1,0,0,0,0,0},removecost={[1]=1000},decompose={[1]=1000},durability=50,sturdy=100,item_weight=1,deal_num=3,could_sell=1,sell_value={[1]=100},Text_type={} },
[602501] = { id=602501,type1=0,type2=1,type3=0,type4=106,type5=0,type6=0,market={1,0,0,0,0,0},removecost={[1]=1000},decompose={[1]=1000},durability=50,sturdy=100,item_weight=1,deal_num=3,could_sell=1,sell_value={[1]=100},Text_type={} },
[603000] = { id=603000,type1=0,type2=1,type3=0,type4=107,type5=0,type6=0,market={1,0,0,0,0,0},removecost={[1]=1000},decompose={[1]=1000},durability=50,sturdy=100,item_weight=1,deal_num=3,could_sell=1,sell_value={[1]=100},Text_type={} },
[603001] = { id=603001,type1=0,type2=1,type3=0,type4=107,type5=0,type6=0,market={1,0,0,0,0,0},removecost={[1]=1000},decompose={[1]=1000},durability=50,sturdy=100,item_weight=1,deal_num=3,could_sell=1,sell_value={[1]=100},Text_type={} },
[603500] = { id=603500,type1=0,type2=1,type3=0,type4=108,type5=0,type6=0,market={1,0,0,0,0,0},removecost={[1]=1000},decompose={[1]=1000},durability=50,sturdy=100,item_weight=1,deal_num=3,could_sell=1,sell_value={[1]=100},Text_type={} },
[603501] = { id=603501,type1=0,type2=1,type3=0,type4=108,type5=0,type6=0,market={1,0,0,0,0,0},removecost={[1]=1000},decompose={[1]=1000},durability=50,sturdy=100,item_weight=1,deal_num=3,could_sell=1,sell_value={[1]=100},Text_type={} },
[604000] = { id=604000,type1=0,type2=1,type3=0,type4=109,type5=0,type6=0,market={1,0,0,0,0,0},removecost={[1]=1000},decompose={[1]=1000},durability=50,sturdy=100,item_weight=1,deal_num=3,could_sell=1,sell_value={[1]=100},Text_type={} },
[604001] = { id=604001,type1=0,type2=1,type3=0,type4=109,type5=0,type6=0,market={1,0,0,0,0,0},removecost={[1]=1000},decompose={[1]=1000},durability=50,sturdy=100,item_weight=1,deal_num=3,could_sell=1,sell_value={[1]=100},Text_type={} },
[604500] = { id=604500,type1=0,type2=1,type3=0,type4=110,type5=0,type6=0,market={1,0,0,0,0,0},removecost={[1]=1000},decompose={[1]=1000},durability=50,sturdy=100,item_weight=1,deal_num=3,could_sell=1,sell_value={[1]=100},Text_type={} },
[604501] = { id=604501,type1=0,type2=1,type3=0,type4=110,type5=0,type6=0,market={1,0,0,0,0,0},removecost={[1]=1000},decompose={[1]=1000},durability=50,sturdy=100,item_weight=1,deal_num=3,could_sell=1,sell_value={[1]=100},Text_type={} },
[605000] = { id=605000,type1=0,type2=1,type3=0,type4=111,type5=0,type6=0,market={1,0,0,0,0,0},removecost={[1]=1000},decompose={[1]=1000},durability=50,sturdy=100,item_weight=1,deal_num=3,could_sell=1,sell_value={[1]=100},Text_type={} },
[605001] = { id=605001,type1=0,type2=1,type3=0,type4=111,type5=0,type6=0,market={1,0,0,0,0,0},removecost={[1]=1000},decompose={[1]=1000},durability=50,sturdy=100,item_weight=1,deal_num=3,could_sell=1,sell_value={[1]=100},Text_type={} },
[605500] = { id=605500,type1=0,type2=1,type3=0,type4=112,type5=0,type6=0,market={1,0,0,0,0,0},removecost={[1]=1000},decompose={[1]=1000},durability=50,sturdy=100,item_weight=1,deal_num=3,could_sell=1,sell_value={[1]=100},Text_type={} },
[605501] = { id=605501,type1=0,type2=1,type3=0,type4=112,type5=0,type6=0,market={1,0,0,0,0,0},removecost={[1]=1000},decompose={[1]=1000},durability=50,sturdy=100,item_weight=1,deal_num=3,could_sell=1,sell_value={[1]=100},Text_type={} },
[521000] = { id=521000,type1=0,type2=1,type3=1,type4=0,type5=0,type6=0,market={1,0,0,0,0,0},removecost={[1]=10113},decompose={[1]=123},durability=0,sturdy=0,item_weight=1,deal_num=3,could_sell=1,sell_value={[1]=100},Text_type={} },
[521001] = { id=521001,type1=0,type2=2,type3=2,type4=0,type5=0,type6=0,market={1,0,0,0,0,0},removecost={[1]=10113},decompose={[1]=123},durability=0,sturdy=0,item_weight=1,deal_num=3,could_sell=1,sell_value={[1]=100},Text_type={} },
[521002] = { id=521002,type1=0,type2=3,type3=3,type4=0,type5=0,type6=0,market={1,0,0,0,0,0},removecost={[1]=10113},decompose={[1]=123},durability=0,sturdy=0,item_weight=1,deal_num=3,could_sell=1,sell_value={[1]=100},Text_type={} },
[521003] = { id=521003,type1=0,type2=4,type3=4,type4=0,type5=0,type6=0,market={1,0,0,0,0,0},removecost={[1]=10113},decompose={[1]=123},durability=0,sturdy=0,item_weight=1,deal_num=3,could_sell=1,sell_value={[1]=100},Text_type={} },
[521004] = { id=521004,type1=0,type2=5,type3=5,type4=0,type5=0,type6=0,market={1,0,0,0,0,0},removecost={[1]=10113},decompose={[1]=123},durability=0,sturdy=0,item_weight=1,deal_num=3,could_sell=1,sell_value={[1]=100},Text_type={} },
[625000] = { id=625000,type1=0,type2=1,type3=0,type4=0,type5=0,type6=0,market={1,0,0,0,0,0},removecost={[1]=100},decompose={[1]=100},durability=0,sturdy=0,item_weight=1,deal_num=3,could_sell=1,sell_value={[1]=100},Text_type={} },
[625001] = { id=625001,type1=0,type2=1,type3=0,type4=0,type5=0,type6=0,market={1,0,0,0,0,0},removecost={[1]=100},decompose={[1]=100},durability=0,sturdy=0,item_weight=1,deal_num=3,could_sell=1,sell_value={[1]=100},Text_type={} },
[625002] = { id=625002,type1=0,type2=1,type3=0,type4=0,type5=0,type6=0,market={1,0,0,0,0,0},removecost={[1]=100},decompose={[1]=100},durability=0,sturdy=0,item_weight=1,deal_num=3,could_sell=1,sell_value={[1]=100},Text_type={} },
[625003] = { id=625003,type1=0,type2=1,type3=0,type4=0,type5=0,type6=0,market={1,0,0,0,0,0},removecost={[1]=100},decompose={[1]=100},durability=0,sturdy=0,item_weight=1,deal_num=3,could_sell=1,sell_value={[1]=100},Text_type={} },
[625004] = { id=625004,type1=0,type2=1,type3=0,type4=0,type5=0,type6=0,market={1,0,0,0,0,0},removecost={[1]=100},decompose={[1]=100},durability=0,sturdy=0,item_weight=1,deal_num=3,could_sell=1,sell_value={[1]=100},Text_type={} },
[625005] = { id=625005,type1=0,type2=1,type3=0,type4=0,type5=0,type6=0,market={1,0,0,0,0,0},removecost={[1]=100},decompose={[1]=100},durability=0,sturdy=0,item_weight=1,deal_num=3,could_sell=1,sell_value={[1]=100},Text_type={} },
[625006] = { id=625006,type1=0,type2=1,type3=0,type4=0,type5=0,type6=0,market={1,0,0,0,0,0},removecost={[1]=100},decompose={[1]=100},durability=0,sturdy=0,item_weight=1,deal_num=3,could_sell=1,sell_value={[1]=100},Text_type={} },
[625007] = { id=625007,type1=0,type2=1,type3=0,type4=0,type5=0,type6=0,market={1,0,0,0,0,0},removecost={[1]=100},decompose={[1]=100},durability=0,sturdy=0,item_weight=1,deal_num=3,could_sell=1,sell_value={[1]=100},Text_type={} },
[625008] = { id=625008,type1=0,type2=1,type3=0,type4=0,type5=0,type6=0,market={1,0,0,0,0,0},removecost={[1]=100},decompose={[1]=100},durability=0,sturdy=0,item_weight=1,deal_num=3,could_sell=1,sell_value={[1]=100},Text_type={} },
[625009] = { id=625009,type1=0,type2=1,type3=0,type4=0,type5=0,type6=0,market={1,0,0,0,0,0},removecost={[1]=100},decompose={[1]=100},durability=0,sturdy=0,item_weight=1,deal_num=3,could_sell=1,sell_value={[1]=100},Text_type={} },
[630000] = { id=630000,type1=0,type2=1,type3=0,type4=1000,type5=1,type6=0,market={1,0,0,0,0,0},removecost={[1]=100},decompose={[1]=100},durability=50,sturdy=100,item_weight=1,deal_num=3,could_sell=1,sell_value={[1]=100},Text_type={} },
[630001] = { id=630001,type1=0,type2=1,type3=0,type4=1000,type5=2,type6=0,market={1,0,0,0,0,0},removecost={[1]=100},decompose={[1]=100},durability=50,sturdy=100,item_weight=1,deal_num=3,could_sell=1,sell_value={[1]=100},Text_type={} },
[630002] = { id=630002,type1=0,type2=1,type3=0,type4=1000,type5=3,type6=0,market={1,0,0,0,0,0},removecost={[1]=100},decompose={[1]=100},durability=50,sturdy=100,item_weight=1,deal_num=3,could_sell=1,sell_value={[1]=100},Text_type={} },
[630003] = { id=630003,type1=0,type2=1,type3=0,type4=1000,type5=4,type6=0,market={1,0,0,0,0,0},removecost={[1]=100},decompose={[1]=100},durability=50,sturdy=100,item_weight=1,deal_num=3,could_sell=1,sell_value={[1]=100},Text_type={} },
[630004] = { id=630004,type1=0,type2=1,type3=0,type4=1000,type5=5,type6=0,market={1,0,0,0,0,0},removecost={[1]=100},decompose={[1]=100},durability=50,sturdy=100,item_weight=1,deal_num=3,could_sell=1,sell_value={[1]=100},Text_type={} },
[630005] = { id=630005,type1=0,type2=1,type3=0,type4=1000,type5=6,type6=0,market={1,0,0,0,0,0},removecost={[1]=100},decompose={[1]=100},durability=50,sturdy=100,item_weight=1,deal_num=3,could_sell=1,sell_value={[1]=100},Text_type={} },
[630006] = { id=630006,type1=0,type2=1,type3=0,type4=1000,type5=7,type6=0,market={1,0,0,0,0,0},removecost={[1]=100},decompose={[1]=100},durability=50,sturdy=100,item_weight=1,deal_num=3,could_sell=1,sell_value={[1]=100},Text_type={} },
[630007] = { id=630007,type1=0,type2=1,type3=0,type4=1000,type5=8,type6=0,market={1,0,0,0,0,0},removecost={[1]=100},decompose={[1]=100},durability=50,sturdy=100,item_weight=1,deal_num=3,could_sell=1,sell_value={[1]=100},Text_type={} },
[640000] = { id=640000,type1=0,type2=1,type3=0,type4=1001,type5=1,type6=0,market={1,0,0,0,0,0},removecost={[1]=100},decompose={[1]=100},durability=50,sturdy=100,item_weight=1,deal_num=3,could_sell=1,sell_value={[1]=100},Text_type={} },
[640001] = { id=640001,type1=0,type2=1,type3=0,type4=1001,type5=2,type6=0,market={1,0,0,0,0,0},removecost={[1]=100},decompose={[1]=100},durability=50,sturdy=100,item_weight=1,deal_num=3,could_sell=1,sell_value={[1]=100},Text_type={} },
[640002] = { id=640002,type1=0,type2=1,type3=0,type4=1001,type5=3,type6=0,market={1,0,0,0,0,0},removecost={[1]=100},decompose={[1]=100},durability=50,sturdy=100,item_weight=1,deal_num=3,could_sell=1,sell_value={[1]=100},Text_type={} },
[640003] = { id=640003,type1=0,type2=1,type3=0,type4=1001,type5=4,type6=0,market={1,0,0,0,0,0},removecost={[1]=100},decompose={[1]=100},durability=50,sturdy=100,item_weight=1,deal_num=3,could_sell=1,sell_value={[1]=100},Text_type={} },
[640004] = { id=640004,type1=0,type2=1,type3=0,type4=1001,type5=5,type6=0,market={1,0,0,0,0,0},removecost={[1]=100},decompose={[1]=100},durability=50,sturdy=100,item_weight=1,deal_num=3,could_sell=1,sell_value={[1]=100},Text_type={} },
[640005] = { id=640005,type1=0,type2=1,type3=0,type4=1001,type5=6,type6=0,market={1,0,0,0,0,0},removecost={[1]=100},decompose={[1]=100},durability=50,sturdy=100,item_weight=1,deal_num=3,could_sell=1,sell_value={[1]=100},Text_type={} },
[640006] = { id=640006,type1=0,type2=1,type3=0,type4=1001,type5=7,type6=0,market={1,0,0,0,0,0},removecost={[1]=100},decompose={[1]=100},durability=50,sturdy=100,item_weight=1,deal_num=3,could_sell=1,sell_value={[1]=100},Text_type={} },
[640007] = { id=640007,type1=0,type2=1,type3=0,type4=1001,type5=8,type6=0,market={1,0,0,0,0,0},removecost={[1]=100},decompose={[1]=100},durability=50,sturdy=100,item_weight=1,deal_num=3,could_sell=1,sell_value={[1]=100},Text_type={} },
[650000] = { id=650000,type1=0,type2=1,type3=0,type4=1001,type5=8,type6=0,market={1,0,0,0,0,0},removecost={[1]=100},decompose={[1]=100},durability=50,sturdy=100,item_weight=1,deal_num=3,could_sell=1,sell_value={[1]=100},Text_type={} },
[501000] = { id=501000,type1=0,type2=1,type3=0,type4=1001,type5=8,type6=0,market={1,0,0,0,0,0},removecost={[1]=100},decompose={[1]=100},durability=50,sturdy=100,item_weight=1,deal_num=3,could_sell=1,sell_value={[1]=100},Text_type={} },
[501001] = { id=501001,type1=0,type2=1,type3=0,type4=1001,type5=8,type6=0,market={1,0,0,0,0,0},removecost={[1]=100},decompose={[1]=100},durability=50,sturdy=100,item_weight=1,deal_num=3,could_sell=1,sell_value={[1]=100},Text_type={} },
[501002] = { id=501002,type1=0,type2=1,type3=0,type4=1001,type5=8,type6=0,market={1,0,0,0,0,0},removecost={[1]=100},decompose={[1]=100},durability=50,sturdy=100,item_weight=1,deal_num=3,could_sell=1,sell_value={[1]=100},Text_type={} }
}