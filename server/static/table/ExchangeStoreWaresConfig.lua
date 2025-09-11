---@class ExchangeStoreWaresConfig_cfg
---@field public id integer @商品id
---@field public price table @价格（现价）
---@field public prop table @商品包含的道具
---@field public validity_time_stamp integer[] @上架时间戳
---@field public quota_type integer @限购类型： 1=不限购； 2=账户永久限购； 3=每日限购； 4=每周限购； 5=每月限购； 确定后不可修改
---@field public quota_num integer @限购数量 确定后不可修改
---@field public Limited_sales integer @全服限量销售： -1 = 不限量
return {
[1] = { id=1,price={[1]=1000,[2]=2000},prop={[1001]=10,[1002]=5},validity_time_stamp={1754020800,1756500000},quota_type=1,quota_num=0,Limited_sales=1000 },
[2] = { id=2,price={[1]=1000,[2]=2000},prop={[1001]=10,[1002]=5},validity_time_stamp={1754020800,1756500000},quota_type=1,quota_num=0,Limited_sales=1000 },
[3] = { id=3,price={[1]=1000,[2]=2000},prop={[1001]=10,[1002]=5},validity_time_stamp={1754020800,1756500000},quota_type=1,quota_num=0,Limited_sales=1000 },
[4] = { id=4,price={[1]=1000,[2]=2000},prop={[1001]=10,[1002]=5},validity_time_stamp={1754020800,1756500000},quota_type=3,quota_num=5,Limited_sales=1000 },
[5] = { id=5,price={[1]=1000,[2]=2000},prop={[1001]=10,[1002]=5},validity_time_stamp={1754020800,1756500000},quota_type=3,quota_num=5,Limited_sales=1000 }
}