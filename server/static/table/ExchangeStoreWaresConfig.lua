---@class ExchangeStoreWaresConfig_cfg
---@field public id integer @商品id （角色的商品ID使用角色ID，其他商品ID不可占用）
---@field public price1 table @价格1（现价） 当可以使用绑定货币时，填绑定货币id，结算时优先使用绑定货币，不足时使用关联的非绑定货币
---@field public price2 table @价格2（现价） 当可以使用绑定货币时，填绑定货币id，结算时优先使用绑定货币，不足时使用关联的非绑定货币
---@field public prop table @商品包含的道具
---@field public treasurechest table @商品包含的宝箱
---@field public validity_time_stamp integer[] @上架时间戳
---@field public quota_type integer @限购类型： 1=不限购； 2=账户永久限购； 3=每日限购； 4=每周限购； 5=每月限购； 确定后不可修改
---@field public quota_num integer @限购数量 确定后不可修改
---@field public limited_type integer @全服限量类型： 1=不限量 2=全服限量
---@field public limited_num integer @全服限量数量
---@field public default_price1 table @原价1
---@field public default_price2 table @原价2
return {
[1] = { id=1,price1={[1]=1},price2={[3]=1},prop={[154000]=1},treasurechest={},validity_time_stamp={1764570414,1806560814},quota_type=1,quota_num=0,limited_type=1,limited_num=0,default_price1={[1]=10},default_price2={[1]=10} },
[2] = { id=2,price1={[1]=1},price2={[3]=1},prop={[164000]=1},treasurechest={},validity_time_stamp={1764570414,1806560814},quota_type=1,quota_num=0,limited_type=1,limited_num=0,default_price1={[1]=1},default_price2={[1]=1} },
[3] = { id=3,price1={[1]=1},price2={[3]=1},prop={[174000]=1},treasurechest={},validity_time_stamp={1764570414,1806560814},quota_type=1,quota_num=0,limited_type=1,limited_num=0,default_price1={[1]=1},default_price2={[1]=1} },
[4] = { id=4,price1={[1]=1},price2={[3]=1},prop={[194000]=1},treasurechest={},validity_time_stamp={1764570414,1806560814},quota_type=1,quota_num=0,limited_type=1,limited_num=0,default_price1={[1]=1},default_price2={[1]=1} },
[5] = { id=5,price1={[1]=1},price2={[3]=1},prop={[164001]=1},treasurechest={},validity_time_stamp={1764570414,1806560814},quota_type=1,quota_num=0,limited_type=1,limited_num=0,default_price1={[1]=1},default_price2={[1]=1} },
[6] = { id=6,price1={[1]=1},price2={[3]=1},prop={[174001]=1},treasurechest={},validity_time_stamp={1764570414,1806560814},quota_type=1,quota_num=0,limited_type=1,limited_num=0,default_price1={[1]=1},default_price2={[1]=1} },
[7] = { id=7,price1={[1]=1},price2={[3]=1},prop={[194001]=1},treasurechest={},validity_time_stamp={1764570414,1806560814},quota_type=1,quota_num=0,limited_type=1,limited_num=0,default_price1={[1]=1},default_price2={[1]=1} },
[8] = { id=8,price1={[1]=1},price2={[3]=1},prop={[144000]=1},treasurechest={},validity_time_stamp={1764570414,1806560814},quota_type=1,quota_num=0,limited_type=1,limited_num=0,default_price1={[1]=1},default_price2={[1]=1} },
[9] = { id=9,price1={[1]=1},price2={[3]=1},prop={[194002]=1},treasurechest={},validity_time_stamp={1764570414,1806560814},quota_type=1,quota_num=0,limited_type=1,limited_num=0,default_price1={[1]=1},default_price2={[1]=1} },
[10] = { id=10,price1={[1]=1},price2={[3]=1},prop={[164002]=1},treasurechest={},validity_time_stamp={1764570414,1806560814},quota_type=1,quota_num=0,limited_type=1,limited_num=0,default_price1={[1]=1},default_price2={[1]=1} },
[11] = { id=11,price1={[1]=1},price2={[3]=1},prop={[174002]=1},treasurechest={},validity_time_stamp={1764570414,1806560814},quota_type=1,quota_num=0,limited_type=1,limited_num=0,default_price1={[1]=1},default_price2={[1]=1} },
[12] = { id=12,price1={[1]=1},price2={[3]=1},prop={[184000]=1},treasurechest={},validity_time_stamp={1764570414,1806560814},quota_type=1,quota_num=0,limited_type=1,limited_num=0,default_price1={[1]=1},default_price2={[1]=1} },
[13] = { id=13,price1={[1]=1},price2={[3]=1},prop={[194003]=1},treasurechest={},validity_time_stamp={1764570414,1806560814},quota_type=1,quota_num=0,limited_type=1,limited_num=0,default_price1={[1]=1},default_price2={[1]=1} },
[14] = { id=14,price1={[1]=1},price2={[3]=1},prop={[164000]=1,[174000]=1,[194000]=1},treasurechest={},validity_time_stamp={1764570414,1806560814},quota_type=1,quota_num=0,limited_type=1,limited_num=0,default_price1={[1]=1},default_price2={[1]=1} },
[15] = { id=15,price1={[1]=1},price2={[3]=1},prop={[164001]=1,[174001]=1,[194001]=1},treasurechest={},validity_time_stamp={1764570414,1806560814},quota_type=1,quota_num=0,limited_type=1,limited_num=0,default_price1={[1]=1},default_price2={[1]=1} },
[16] = { id=16,price1={[1]=1},price2={[3]=1},prop={[144000]=1,[194002]=1},treasurechest={},validity_time_stamp={1764570414,1806560814},quota_type=1,quota_num=0,limited_type=1,limited_num=0,default_price1={[1]=1},default_price2={[1]=1} },
[17] = { id=17,price1={[1]=1},price2={[3]=1},prop={[164002]=1,[174002]=1,[184000]=1,[194003]=1},treasurechest={},validity_time_stamp={1764570414,1806560814},quota_type=1,quota_num=0,limited_type=1,limited_num=0,default_price1={[1]=1},default_price2={[1]=1} },
[18] = { id=18,price1={[100]=1},price2={[3]=1},prop={[1162003]=1},treasurechest={},validity_time_stamp={1764570414,1806560814},quota_type=1,quota_num=0,limited_type=1,limited_num=0,default_price1={[100]=1},default_price2={[3]=1} },
[19] = { id=19,price1={[101]=1},price2={[3]=1},prop={[1172003]=1},treasurechest={},validity_time_stamp={1764570414,1806560814},quota_type=1,quota_num=0,limited_type=1,limited_num=0,default_price1={[101]=1},default_price2={[3]=1} },
[20] = { id=20,price1={[102]=1},price2={[3]=1},prop={[1192004]=1},treasurechest={},validity_time_stamp={1764570414,1806560814},quota_type=1,quota_num=0,limited_type=1,limited_num=0,default_price1={[102]=1},default_price2={[3]=1} },
[21] = { id=21,price1={[1000]=1},price2={[3]=1},prop={[1162003]=1,[1172003]=1,[1192004]=1},treasurechest={},validity_time_stamp={1764570414,1806560814},quota_type=2,quota_num=0,limited_type=1,limited_num=0,default_price1={[1000]=1},default_price2={[3]=1} },
[22] = { id=22,price1={[1]=10},price2={[3]=2},prop={[134000]=1},treasurechest={},validity_time_stamp={1764570414,1806560814},quota_type=1,quota_num=0,limited_type=1,limited_num=0,default_price1={[1]=100},default_price2={[3]=100} },
[23] = { id=23,price1={[1]=10},price2={[3]=2},prop={[134001]=1},treasurechest={},validity_time_stamp={1764570414,1806560814},quota_type=1,quota_num=0,limited_type=1,limited_num=0,default_price1={[1]=100},default_price2={[3]=100} },
[24] = { id=24,price1={[1]=1},price2={[3]=1},prop={[134002]=1},treasurechest={},validity_time_stamp={1764570414,1806560814},quota_type=2,quota_num=1,limited_type=1,limited_num=0,default_price1={[1]=1},default_price2={[3]=1} },
[25] = { id=25,price1={[1]=1},price2={[3]=1},prop={[134003]=1},treasurechest={},validity_time_stamp={1764570414,1806560814},quota_type=3,quota_num=1,limited_type=1,limited_num=0,default_price1={[1]=1},default_price2={[3]=1} },
[26] = { id=26,price1={[1]=1},price2={[3]=1},prop={[134004]=1},treasurechest={},validity_time_stamp={1764570414,1806560814},quota_type=4,quota_num=1,limited_type=1,limited_num=0,default_price1={[1]=1},default_price2={[3]=1} },
[27] = { id=27,price1={[1]=1},price2={[3]=1},prop={[134005]=1},treasurechest={},validity_time_stamp={1764570414,1806560814},quota_type=5,quota_num=1,limited_type=1,limited_num=0,default_price1={[1]=1},default_price2={[3]=1} },
[28] = { id=28,price1={[1]=1},price2={[3]=1},prop={[134006]=1},treasurechest={},validity_time_stamp={1764570414,1806560814},quota_type=1,quota_num=0,limited_type=1,limited_num=0,default_price1={[1]=1},default_price2={[3]=1} },
[29] = { id=29,price1={[1]=1},price2={[3]=1},prop={[134007]=1},treasurechest={},validity_time_stamp={1764570414,1806560814},quota_type=1,quota_num=0,limited_type=1,limited_num=0,default_price1={[1]=1},default_price2={[3]=1} },
[30] = { id=30,price1={[1]=1},price2={[3]=1},prop={[134008]=1},treasurechest={},validity_time_stamp={1764570414,1806560814},quota_type=1,quota_num=0,limited_type=1,limited_num=0,default_price1={[1]=1},default_price2={[3]=1} },
[31] = { id=31,price1={[1]=1},price2={[3]=1},prop={[134009]=1},treasurechest={},validity_time_stamp={1764570414,1806560814},quota_type=1,quota_num=0,limited_type=1,limited_num=0,default_price1={[1]=1},default_price2={[3]=1} },
[32] = { id=32,price1={[1]=1},price2={[3]=1},prop={[134010]=1},treasurechest={},validity_time_stamp={1764570414,1806560814},quota_type=1,quota_num=0,limited_type=1,limited_num=0,default_price1={[1]=1},default_price2={[3]=1} },
[33] = { id=33,price1={[1]=1},price2={[3]=1},prop={[134011]=1},treasurechest={},validity_time_stamp={1764570414,1806560814},quota_type=1,quota_num=0,limited_type=1,limited_num=0,default_price1={[1]=1},default_price2={[3]=1} },
[34] = { id=34,price1={[1]=1},price2={[3]=1},prop={[134012]=1},treasurechest={},validity_time_stamp={1764570414,1806560814},quota_type=1,quota_num=0,limited_type=1,limited_num=0,default_price1={[1]=1},default_price2={[3]=1} },
[35] = { id=35,price1={[1]=1},price2={[3]=1},prop={[134013]=1},treasurechest={},validity_time_stamp={1764570414,1806560814},quota_type=1,quota_num=0,limited_type=1,limited_num=0,default_price1={[1]=1},default_price2={[3]=1} },
[36] = { id=36,price1={[1]=1},price2={[3]=1},prop={[134014]=1},treasurechest={},validity_time_stamp={1764570414,1806560814},quota_type=1,quota_num=0,limited_type=1,limited_num=0,default_price1={[1]=1},default_price2={[3]=1} },
[37] = { id=37,price1={[1]=1},price2={[3]=1},prop={[134015]=1},treasurechest={},validity_time_stamp={1764570414,1806560814},quota_type=1,quota_num=0,limited_type=1,limited_num=0,default_price1={[1]=1},default_price2={[3]=1} },
[38] = { id=38,price1={[1]=1},price2={[3]=1},prop={[134016]=1},treasurechest={},validity_time_stamp={1764570414,1806560814},quota_type=1,quota_num=0,limited_type=1,limited_num=0,default_price1={[1]=1},default_price2={[3]=1} },
[39] = { id=39,price1={[1]=1},price2={[3]=1},prop={[134017]=1},treasurechest={},validity_time_stamp={1764570414,1806560814},quota_type=1,quota_num=0,limited_type=1,limited_num=0,default_price1={[1]=1},default_price2={[3]=1} },
[40] = { id=40,price1={[1]=1},price2={[3]=1},prop={[134018]=1},treasurechest={},validity_time_stamp={1764570414,1806560814},quota_type=1,quota_num=0,limited_type=1,limited_num=0,default_price1={[1]=1},default_price2={[3]=1} },
[41] = { id=41,price1={[1]=1},price2={[3]=1},prop={[134019]=1},treasurechest={},validity_time_stamp={1764570414,1806560814},quota_type=1,quota_num=0,limited_type=1,limited_num=0,default_price1={[1]=1},default_price2={[3]=1} },
[42] = { id=42,price1={[1]=1},price2={[3]=1},prop={[354003]=1},treasurechest={},validity_time_stamp={1764570414,1806560814},quota_type=1,quota_num=0,limited_type=1,limited_num=0,default_price1={[1]=1},default_price2={[3]=1} },
[43] = { id=43,price1={[1]=1},price2={[3]=1},prop={[354004]=1},treasurechest={},validity_time_stamp={1764570414,1806560814},quota_type=1,quota_num=0,limited_type=1,limited_num=0,default_price1={[1]=1},default_price2={[3]=1} },
[44] = { id=44,price1={[1]=1},price2={[3]=1},prop={[1142005]=1,[1182005]=1,[1192005]=1,[1202005]=1,[1212005]=1,[1232005]=1},treasurechest={},validity_time_stamp={1764570414,1806560814},quota_type=1,quota_num=0,limited_type=1,limited_num=0,default_price1={[1]=1},default_price2={[3]=1} },
[45] = { id=45,price1={[1]=1},price2={[3]=1},prop={[134000]=1,[134001]=1,[134002]=1,[134003]=1,[134004]=1,[134005]=1},treasurechest={},validity_time_stamp={1764570414,1806560814},quota_type=1,quota_num=0,limited_type=1,limited_num=0,default_price1={[1]=1},default_price2={[3]=1} },
[46] = { id=46,price1={[1]=1},price2={[3]=1},prop={[1162008]=1,[1172008]=1,[1192008]=1},treasurechest={},validity_time_stamp={1764570414,1806560814},quota_type=1,quota_num=0,limited_type=1,limited_num=0,default_price1={[1]=1},default_price2={[3]=1} },
[47] = { id=47,price1={[1]=1},price2={[3]=1},prop={[134014]=1,[134015]=1,[134016]=1},treasurechest={},validity_time_stamp={1764570414,1806560814},quota_type=1,quota_num=0,limited_type=1,limited_num=0,default_price1={[1]=1},default_price2={[3]=1} },
[48] = { id=48,price1={[1]=1},price2={[3]=1},prop={[354005]=1},treasurechest={},validity_time_stamp={1764570414,1806560814},quota_type=1,quota_num=0,limited_type=1,limited_num=0,default_price1={[1]=1},default_price2={[3]=1} },
[49] = { id=49,price1={[1]=1},price2={[3]=1},prop={[354006]=1},treasurechest={},validity_time_stamp={1764570414,1806560814},quota_type=1,quota_num=0,limited_type=1,limited_num=0,default_price1={[1]=1},default_price2={[3]=1} },
[1000000] = { id=1000000,price1={[1]=1},price2={[3]=1},prop={[1000000]=1},treasurechest={},validity_time_stamp={1764570414,1806560814},quota_type=2,quota_num=1,limited_type=1,limited_num=0,default_price1={},default_price2={} },
[1000001] = { id=1000001,price1={[1]=2},price2={[3]=1},prop={[1000001]=1},treasurechest={},validity_time_stamp={1764570414,1806560814},quota_type=2,quota_num=1,limited_type=1,limited_num=0,default_price1={},default_price2={} },
[1000002] = { id=1000002,price1={[1]=3},price2={[3]=1},prop={[1000002]=1},treasurechest={},validity_time_stamp={1764570414,1806560814},quota_type=2,quota_num=1,limited_type=1,limited_num=0,default_price1={},default_price2={} },
[1000003] = { id=1000003,price1={[1]=4},price2={[3]=1},prop={[1000003]=1},treasurechest={},validity_time_stamp={1764570414,1806560814},quota_type=2,quota_num=1,limited_type=1,limited_num=0,default_price1={},default_price2={} },
[1000004] = { id=1000004,price1={[1]=5},price2={[3]=1},prop={[1000004]=1},treasurechest={},validity_time_stamp={1764570414,1806560814},quota_type=2,quota_num=1,limited_type=1,limited_num=0,default_price1={},default_price2={} },
[1000005] = { id=1000005,price1={[1]=5},price2={[3]=1},prop={[1000004]=1},treasurechest={},validity_time_stamp={1764570414,1806560814},quota_type=2,quota_num=1,limited_type=1,limited_num=0,default_price1={},default_price2={} }
}