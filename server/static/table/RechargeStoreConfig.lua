---@class RechargeStoreConfig_cfg
---@field public id integer @商品id
---@field public price integer @价格（现价）*100
---@field public price_record integer @累充价格*100
---@field public prop table @商品包含的货币
return {
[1] = { id=1,price=990,price_record=990,prop={[1]=100} },
[2] = { id=2,price=1990,price_record=1990,prop={[1]=1000} },
[3] = { id=3,price=2990,price_record=2990,prop={[1]=3000} },
[4] = { id=4,price=3990,price_record=3990,prop={[1]=6000} }
}