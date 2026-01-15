---@class ExchangeStoreWaresConfig_cfg
---@field public id integer @商品id （角色的商品ID使用角色ID，其他商品ID不可占用）
---@field public price table @价格（现价）
---@field public prop table @商品包含的道具
---@field public validity_time_stamp integer[] @上架时间戳
---@field public quota_type integer @限购类型： 1=不限购； 2=账户永久限购； 3=每日限购； 4=每周限购； 5=每月限购； 确定后不可修改
---@field public quota_num integer @限购数量 确定后不可修改
---@field public limited_type integer @全服限量类型： 1=不限量 2=全服限量
---@field public limited_num integer @全服限量数量
---@field public default_price table @原价
return {
[1000000] = { id=1000000,price={[1]=1},prop={[1000000]=1},validity_time_stamp={1764570414,1806560814},quota_type=2,quota_num=1,limited_type=1,limited_num=0,default_price={} },
[1000001] = { id=1000001,price={[1]=2},prop={[1000001]=1},validity_time_stamp={1764570414,1806560814},quota_type=0,quota_num=0,limited_type=0,limited_num=0,default_price={} },
[1000002] = { id=1000002,price={[1]=3},prop={[1000002]=1},validity_time_stamp={1764570414,1806560814},quota_type=0,quota_num=0,limited_type=0,limited_num=0,default_price={} },
[1000003] = { id=1000003,price={[1]=4},prop={[1000003]=1},validity_time_stamp={1764570414,1806560814},quota_type=0,quota_num=0,limited_type=0,limited_num=0,default_price={} },
[1000004] = { id=1000004,price={[1]=5},prop={[1000004]=1},validity_time_stamp={1764570414,1806560814},quota_type=0,quota_num=0,limited_type=0,limited_num=0,default_price={} },
[1] = { id=1,price={[1]=1},prop={[154000]=1},validity_time_stamp={1764570414,1806560814},quota_type=1,quota_num=0,limited_type=1,limited_num=0,default_price={[1]=10} },
[2] = { id=2,price={[1]=1},prop={[164000]=1},validity_time_stamp={1764570414,1806560814},quota_type=1,quota_num=0,limited_type=1,limited_num=0,default_price={[1]=1} },
[3] = { id=3,price={[1]=1},prop={[174000]=1},validity_time_stamp={1764570414,1806560814},quota_type=1,quota_num=0,limited_type=1,limited_num=0,default_price={[1]=1} },
[4] = { id=4,price={[1]=1},prop={[194000]=1},validity_time_stamp={1764570414,1806560814},quota_type=1,quota_num=0,limited_type=1,limited_num=0,default_price={[1]=1} },
[5] = { id=5,price={[1]=1},prop={[164001]=1},validity_time_stamp={1764570414,1806560814},quota_type=1,quota_num=0,limited_type=1,limited_num=0,default_price={[1]=1} },
[6] = { id=6,price={[1]=1},prop={[174001]=1},validity_time_stamp={1764570414,1806560814},quota_type=1,quota_num=0,limited_type=1,limited_num=0,default_price={[1]=1} },
[7] = { id=7,price={[1]=1},prop={[194001]=1},validity_time_stamp={1764570414,1806560814},quota_type=1,quota_num=0,limited_type=1,limited_num=0,default_price={[1]=1} },
[8] = { id=8,price={[1]=1},prop={[144000]=1},validity_time_stamp={1764570414,1806560814},quota_type=1,quota_num=0,limited_type=1,limited_num=0,default_price={[1]=1} },
[9] = { id=9,price={[1]=1},prop={[194002]=1},validity_time_stamp={1764570414,1806560814},quota_type=1,quota_num=0,limited_type=1,limited_num=0,default_price={[1]=1} },
[10] = { id=10,price={[1]=1},prop={[164002]=1},validity_time_stamp={1764570414,1806560814},quota_type=1,quota_num=0,limited_type=1,limited_num=0,default_price={[1]=1} },
[11] = { id=11,price={[1]=1},prop={[174002]=1},validity_time_stamp={1764570414,1806560814},quota_type=1,quota_num=0,limited_type=1,limited_num=0,default_price={[1]=1} },
[12] = { id=12,price={[1]=1},prop={[184000]=1},validity_time_stamp={1764570414,1806560814},quota_type=1,quota_num=0,limited_type=1,limited_num=0,default_price={[1]=1} },
[13] = { id=13,price={[1]=1},prop={[194003]=1},validity_time_stamp={1764570414,1806560814},quota_type=1,quota_num=0,limited_type=1,limited_num=0,default_price={[1]=1} },
[14] = { id=14,price={[1]=1},prop={[164000]=1,[174000]=1,[194000]=1},validity_time_stamp={1764570414,1806560814},quota_type=1,quota_num=0,limited_type=1,limited_num=0,default_price={[1]=1} },
[15] = { id=15,price={[1]=1},prop={[164001]=1,[174001]=1,[194001]=1},validity_time_stamp={1764570414,1806560814},quota_type=1,quota_num=0,limited_type=1,limited_num=0,default_price={[1]=1} },
[16] = { id=16,price={[1]=1},prop={[144000]=1,[194002]=1},validity_time_stamp={1764570414,1806560814},quota_type=1,quota_num=0,limited_type=1,limited_num=0,default_price={[1]=1} },
[17] = { id=17,price={[1]=1},prop={[164002]=1,[174002]=1,[184000]=1,[194003]=1},validity_time_stamp={1764570414,1806560814},quota_type=1,quota_num=0,limited_type=1,limited_num=0,default_price={[1]=1} }
}