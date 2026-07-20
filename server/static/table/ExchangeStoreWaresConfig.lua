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
[1] = { id=1,price1={[1]=100},price2={},prop={[661000]=1},treasurechest={},validity_time_stamp={1764570414,1806560814},quota_type=1,quota_num=0,limited_type=1,limited_num=0,default_price1={},default_price2={} },
[2] = { id=2,price1={[1]=100},price2={},prop={[661001]=1},treasurechest={},validity_time_stamp={1764570414,1806560814},quota_type=1,quota_num=0,limited_type=1,limited_num=0,default_price1={},default_price2={} },
[3] = { id=3,price1={[1]=100},price2={},prop={[661002]=1},treasurechest={},validity_time_stamp={1764570414,1806560814},quota_type=1,quota_num=0,limited_type=1,limited_num=0,default_price1={},default_price2={} },
[4] = { id=4,price1={[1]=100},price2={},prop={[661003]=1},treasurechest={},validity_time_stamp={1764570414,1806560814},quota_type=1,quota_num=0,limited_type=1,limited_num=0,default_price1={},default_price2={} },
[5] = { id=5,price1={[1]=100},price2={},prop={[661004]=1},treasurechest={},validity_time_stamp={1764570414,1806560814},quota_type=1,quota_num=0,limited_type=1,limited_num=0,default_price1={},default_price2={} },
[6] = { id=6,price1={[1]=100},price2={},prop={[661005]=1},treasurechest={},validity_time_stamp={1764570414,1806560814},quota_type=1,quota_num=0,limited_type=1,limited_num=0,default_price1={},default_price2={} },
[7] = { id=7,price1={[1]=100},price2={[3]=100},prop={[661006]=1},treasurechest={},validity_time_stamp={1764570414,1806560814},quota_type=1,quota_num=0,limited_type=1,limited_num=0,default_price1={},default_price2={} },
[8] = { id=8,price1={[1]=100},price2={[3]=100},prop={[661007]=1},treasurechest={},validity_time_stamp={1764570414,1806560814},quota_type=1,quota_num=0,limited_type=1,limited_num=0,default_price1={},default_price2={} },
[9] = { id=9,price1={[1]=100},price2={[3]=100},prop={[661008]=1},treasurechest={},validity_time_stamp={1764570414,1806560814},quota_type=1,quota_num=0,limited_type=1,limited_num=0,default_price1={},default_price2={} },
[10] = { id=10,price1={[1]=100},price2={[3]=100},prop={[661009]=1},treasurechest={},validity_time_stamp={1764570414,1806560814},quota_type=1,quota_num=0,limited_type=1,limited_num=0,default_price1={},default_price2={} },
[11] = { id=11,price1={[4]=188},price2={[3]=100},prop={[661010]=1},treasurechest={},validity_time_stamp={1764570414,1806560814},quota_type=1,quota_num=0,limited_type=1,limited_num=0,default_price1={},default_price2={} },
[12] = { id=12,price1={[4]=48},price2={[3]=100},prop={[661011]=1},treasurechest={},validity_time_stamp={1764570414,1806560814},quota_type=1,quota_num=0,limited_type=1,limited_num=0,default_price1={},default_price2={} },
[13] = { id=13,price1={[4]=38},price2={[3]=100},prop={[661012]=1},treasurechest={},validity_time_stamp={1764570414,1806560814},quota_type=1,quota_num=0,limited_type=1,limited_num=0,default_price1={},default_price2={} },
[14] = { id=14,price1={[4]=38},price2={[3]=100},prop={[661013]=1},treasurechest={},validity_time_stamp={1764570414,1806560814},quota_type=1,quota_num=0,limited_type=1,limited_num=0,default_price1={},default_price2={} },
[15] = { id=15,price1={[4]=38},price2={[3]=100},prop={[661014]=1},treasurechest={},validity_time_stamp={1764570414,1806560814},quota_type=1,quota_num=0,limited_type=1,limited_num=0,default_price1={},default_price2={} },
[16] = { id=16,price1={[4]=38},price2={[3]=100},prop={[661015]=1},treasurechest={},validity_time_stamp={1764570414,1806560814},quota_type=1,quota_num=0,limited_type=1,limited_num=0,default_price1={},default_price2={} },
[17] = { id=17,price1={[1]=100},price2={[3]=100},prop={[661016]=1},treasurechest={},validity_time_stamp={1764570414,1806560814},quota_type=1,quota_num=0,limited_type=1,limited_num=0,default_price1={},default_price2={} },
[18] = { id=18,price1={[1]=100},price2={[3]=100},prop={[661017]=1},treasurechest={},validity_time_stamp={1764570414,1806560814},quota_type=1,quota_num=0,limited_type=1,limited_num=0,default_price1={[100]=1},default_price2={[3]=1} },
[19] = { id=19,price1={[1]=100},price2={[3]=100},prop={[661018]=1},treasurechest={},validity_time_stamp={1764570414,1806560814},quota_type=1,quota_num=0,limited_type=1,limited_num=0,default_price1={[101]=1},default_price2={[3]=1} },
[20] = { id=20,price1={[1]=100},price2={[3]=100},prop={[661019]=1},treasurechest={},validity_time_stamp={1764570414,1806560814},quota_type=1,quota_num=0,limited_type=1,limited_num=0,default_price1={[102]=1},default_price2={[3]=1} },
[21] = { id=21,price1={[1]=100},price2={[3]=100},prop={[661020]=1},treasurechest={},validity_time_stamp={1764570414,1806560814},quota_type=2,quota_num=0,limited_type=1,limited_num=0,default_price1={[1000]=1},default_price2={[3]=1} },
[22] = { id=22,price1={[1]=100},price2={[3]=100},prop={[661021]=1},treasurechest={},validity_time_stamp={1764570414,1806560814},quota_type=1,quota_num=0,limited_type=1,limited_num=0,default_price1={},default_price2={} },
[23] = { id=23,price1={[1]=100},price2={[3]=100},prop={[661022]=1},treasurechest={},validity_time_stamp={1764570414,1806560814},quota_type=1,quota_num=0,limited_type=1,limited_num=0,default_price1={},default_price2={} },
[24] = { id=24,price1={[1]=100},price2={[3]=100},prop={[661023]=1},treasurechest={},validity_time_stamp={1764570414,1806560814},quota_type=1,quota_num=0,limited_type=1,limited_num=0,default_price1={},default_price2={} },
[25] = { id=25,price1={[4]=88},price2={},prop={[661024]=1},treasurechest={},validity_time_stamp={1764570414,1806560814},quota_type=1,quota_num=0,limited_type=1,limited_num=0,default_price1={},default_price2={} },
[26] = { id=26,price1={[4]=38},price2={},prop={[661025]=1},treasurechest={},validity_time_stamp={1764570414,1806560814},quota_type=1,quota_num=0,limited_type=1,limited_num=0,default_price1={},default_price2={} },
[27] = { id=27,price1={[4]=38},price2={},prop={[661026]=1},treasurechest={},validity_time_stamp={1764570414,1806560814},quota_type=1,quota_num=0,limited_type=1,limited_num=0,default_price1={},default_price2={} },
[28] = { id=28,price1={[4]=218},price2={[3]=188},prop={[661027]=1},treasurechest={},validity_time_stamp={1764570414,1806560814},quota_type=1,quota_num=0,limited_type=1,limited_num=0,default_price1={},default_price2={} },
[29] = { id=29,price1={[4]=88},price2={[3]=38},prop={[661028]=1},treasurechest={},validity_time_stamp={1764570414,1806560814},quota_type=1,quota_num=0,limited_type=1,limited_num=0,default_price1={},default_price2={} },
[30] = { id=30,price1={[4]=38},price2={[3]=28},prop={[661029]=1},treasurechest={},validity_time_stamp={1764570414,1806560814},quota_type=1,quota_num=0,limited_type=1,limited_num=0,default_price1={},default_price2={} },
[31] = { id=31,price1={[1]=100},price2={[3]=100},prop={[661030]=1},treasurechest={},validity_time_stamp={1764570414,1806560814},quota_type=1,quota_num=0,limited_type=1,limited_num=0,default_price1={},default_price2={} },
[32] = { id=32,price1={[1]=100},price2={[3]=100},prop={[661031]=1},treasurechest={},validity_time_stamp={1764570414,1806560814},quota_type=1,quota_num=0,limited_type=1,limited_num=0,default_price1={},default_price2={} },
[33] = { id=33,price1={[1]=100},price2={[3]=100},prop={[661032]=1},treasurechest={},validity_time_stamp={1764570414,1806560814},quota_type=1,quota_num=0,limited_type=1,limited_num=0,default_price1={},default_price2={} },
[34] = { id=34,price1={[1]=100},price2={[3]=100},prop={[661033]=1},treasurechest={},validity_time_stamp={1764570414,1806560814},quota_type=1,quota_num=0,limited_type=1,limited_num=0,default_price1={},default_price2={} },
[35] = { id=35,price1={[1]=100},price2={[3]=100},prop={[661034]=1},treasurechest={},validity_time_stamp={1764570414,1806560814},quota_type=1,quota_num=0,limited_type=1,limited_num=0,default_price1={},default_price2={} },
[36] = { id=36,price1={[1]=100},price2={[3]=100},prop={[661035]=1},treasurechest={},validity_time_stamp={1764570414,1806560814},quota_type=3,quota_num=1,limited_type=1,limited_num=0,default_price1={[4]=168},default_price2={} },
[37] = { id=37,price1={[1]=100},price2={[3]=100},prop={[661036]=1},treasurechest={},validity_time_stamp={1764570414,1806560814},quota_type=3,quota_num=1,limited_type=1,limited_num=0,default_price1={[4]=68},default_price2={} },
[38] = { id=38,price1={[1]=100},price2={[3]=100},prop={[661037]=1},treasurechest={},validity_time_stamp={1764570414,1806560814},quota_type=3,quota_num=1,limited_type=1,limited_num=0,default_price1={[4]=68},default_price2={} },
[39] = { id=39,price1={[1]=100},price2={[3]=100},prop={[661038]=1},treasurechest={},validity_time_stamp={1764570414,1806560814},quota_type=2,quota_num=1,limited_type=1,limited_num=0,default_price1={},default_price2={} },
[40] = { id=40,price1={[1]=100},price2={[3]=100},prop={[661039]=1},treasurechest={},validity_time_stamp={1764570414,1806560814},quota_type=2,quota_num=1,limited_type=1,limited_num=0,default_price1={},default_price2={} },
[41] = { id=41,price1={[1]=100},price2={[3]=100},prop={[661040]=1},treasurechest={},validity_time_stamp={1764570414,1806560814},quota_type=2,quota_num=1,limited_type=1,limited_num=0,default_price1={},default_price2={} },
[42] = { id=42,price1={[1]=100},price2={[3]=100},prop={[661041]=1},treasurechest={},validity_time_stamp={1764570414,1806560814},quota_type=1,quota_num=0,limited_type=1,limited_num=0,default_price1={},default_price2={} },
[43] = { id=43,price1={[1]=100},price2={[3]=100},prop={[661042]=1},treasurechest={},validity_time_stamp={1764570414,1806560814},quota_type=1,quota_num=0,limited_type=1,limited_num=0,default_price1={},default_price2={} },
[44] = { id=44,price1={[1]=100},price2={[3]=100},prop={[661043]=1},treasurechest={},validity_time_stamp={1764570414,1806560814},quota_type=1,quota_num=0,limited_type=1,limited_num=0,default_price1={},default_price2={} },
[45] = { id=45,price1={[1]=100},price2={[3]=100},prop={[661044]=1},treasurechest={},validity_time_stamp={1764570414,1806560814},quota_type=1,quota_num=0,limited_type=1,limited_num=0,default_price1={},default_price2={} },
[46] = { id=46,price1={[1]=100},price2={[3]=100},prop={[661045]=1},treasurechest={},validity_time_stamp={1764570414,1806560814},quota_type=1,quota_num=0,limited_type=1,limited_num=0,default_price1={},default_price2={} },
[47] = { id=47,price1={[1]=100},price2={[3]=100},prop={[661046]=1},treasurechest={},validity_time_stamp={1764570414,1806560814},quota_type=1,quota_num=0,limited_type=1,limited_num=0,default_price1={},default_price2={} },
[48] = { id=48,price1={[1]=100},price2={[3]=100},prop={[661047]=1},treasurechest={},validity_time_stamp={1764570414,1806560814},quota_type=1,quota_num=0,limited_type=1,limited_num=0,default_price1={},default_price2={} },
[49] = { id=49,price1={[1]=100},price2={[3]=100},prop={[661048]=1},treasurechest={},validity_time_stamp={1764570414,1806560814},quota_type=1,quota_num=0,limited_type=1,limited_num=0,default_price1={},default_price2={} },
[50] = { id=50,price1={[1]=100},price2={[3]=100},prop={[661049]=1},treasurechest={},validity_time_stamp={1764570414,1806560814},quota_type=1,quota_num=0,limited_type=1,limited_num=0,default_price1={},default_price2={} },
[1000] = { id=1000,price1={[3]=19800},price2={[2]=19800},prop={[354003]=1},treasurechest={},validity_time_stamp={1764570414,1806560814},quota_type=1,quota_num=0,limited_type=1,limited_num=0,default_price1={},default_price2={} },
[1001] = { id=1001,price1={[3]=19800},price2={[2]=19800},prop={[354004]=1},treasurechest={},validity_time_stamp={1764570414,1806560814},quota_type=1,quota_num=0,limited_type=1,limited_num=0,default_price1={},default_price2={} },
[1002] = { id=1002,price1={[3]=19800},price2={[2]=19800},prop={[354005]=1},treasurechest={},validity_time_stamp={1764570414,1806560814},quota_type=1,quota_num=0,limited_type=1,limited_num=0,default_price1={},default_price2={} },
[1003] = { id=1003,price1={[3]=19800},price2={[2]=19800},prop={[354006]=1},treasurechest={},validity_time_stamp={1764570414,1806560814},quota_type=1,quota_num=0,limited_type=1,limited_num=0,default_price1={},default_price2={} },
[1004] = { id=1004,price1={[1]=28},price2={[3]=1},prop={[354007]=1},treasurechest={},validity_time_stamp={1764570414,1806560814},quota_type=1,quota_num=0,limited_type=1,limited_num=0,default_price1={[1]=100},default_price2={[3]=100} },
[1005] = { id=1005,price1={[1]=29},price2={[3]=1},prop={[354008]=1},treasurechest={},validity_time_stamp={1764570414,1806560814},quota_type=1,quota_num=0,limited_type=1,limited_num=0,default_price1={[1]=100},default_price2={[3]=100} },
[1006] = { id=1006,price1={[1]=32},price2={[3]=1},prop={[354009]=1},treasurechest={},validity_time_stamp={1764570414,1806560814},quota_type=1,quota_num=0,limited_type=1,limited_num=0,default_price1={[1]=100},default_price2={[3]=100} },
[1007] = { id=1007,price1={[1]=33},price2={[3]=1},prop={[354010]=1},treasurechest={},validity_time_stamp={1764570414,1806560814},quota_type=1,quota_num=0,limited_type=1,limited_num=0,default_price1={[1]=100},default_price2={[3]=100} },
[1008] = { id=1008,price1={[1]=36},price2={[3]=1},prop={[354011]=1},treasurechest={},validity_time_stamp={1764570414,1806560814},quota_type=1,quota_num=0,limited_type=1,limited_num=0,default_price1={[1]=100},default_price2={[3]=100} },
[1009] = { id=1009,price1={[1]=37},price2={[3]=1},prop={[354012]=1},treasurechest={},validity_time_stamp={1764570414,1806560814},quota_type=1,quota_num=0,limited_type=1,limited_num=0,default_price1={[1]=100},default_price2={[3]=100} },
[1010] = { id=1010,price1={[1]=40},price2={[3]=1},prop={[354013]=1},treasurechest={},validity_time_stamp={1764570414,1806560814},quota_type=1,quota_num=0,limited_type=1,limited_num=0,default_price1={[1]=100},default_price2={[3]=100} },
[1011] = { id=1011,price1={[1]=41},price2={[3]=1},prop={[354014]=1},treasurechest={},validity_time_stamp={1764570414,1806560814},quota_type=1,quota_num=0,limited_type=1,limited_num=0,default_price1={[1]=100},default_price2={[3]=100} },
[1000000] = { id=1000000,price1={[1]=1},price2={[3]=1},prop={[1000000]=1},treasurechest={},validity_time_stamp={1764570414,1806560814},quota_type=2,quota_num=1,limited_type=1,limited_num=0,default_price1={},default_price2={} },
[1000001] = { id=1000001,price1={[1]=2},price2={[3]=1},prop={[1000001]=1},treasurechest={},validity_time_stamp={1764570414,1806560814},quota_type=2,quota_num=1,limited_type=1,limited_num=0,default_price1={},default_price2={} },
[1000002] = { id=1000002,price1={[1]=3},price2={[3]=1},prop={[1000002]=1},treasurechest={},validity_time_stamp={1764570414,1806560814},quota_type=2,quota_num=1,limited_type=1,limited_num=0,default_price1={},default_price2={} },
[1000003] = { id=1000003,price1={[1]=4},price2={[3]=1},prop={[1000003]=1},treasurechest={},validity_time_stamp={1764570414,1806560814},quota_type=2,quota_num=1,limited_type=1,limited_num=0,default_price1={},default_price2={} },
[1000004] = { id=1000004,price1={[1]=5},price2={[3]=1},prop={[1000004]=1},treasurechest={},validity_time_stamp={1764570414,1806560814},quota_type=2,quota_num=1,limited_type=1,limited_num=0,default_price1={},default_price2={} },
[1000005] = { id=1000005,price1={[1]=5},price2={[3]=1},prop={[1000004]=1},treasurechest={},validity_time_stamp={1764570414,1806560814},quota_type=2,quota_num=1,limited_type=1,limited_num=0,default_price1={},default_price2={} }
}