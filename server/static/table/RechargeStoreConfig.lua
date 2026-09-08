---@class RechargeStoreConfig_cfg
---@field public id integer @商品id
---@field public price integer @价格（现价）*100
---@field public price_record integer @累充价格*100
---@field public prop table @商品包含的货币
return {
[1] = { id=1,price=600,price_record=600,prop={[2]=600} },
[2] = { id=2,price=1200,price_record=1200,prop={[2]=1200} },
[3] = { id=3,price=3200,price_record=3200,prop={[2]=3200} },
[4] = { id=4,price=6800,price_record=6800,prop={[2]=6800} },
[5] = { id=5,price=12800,price_record=12800,prop={[2]=12800} },
[6] = { id=6,price=32800,price_record=32800,prop={[2]=32800} },
[7] = { id=7,price=64800,price_record=64800,prop={[2]=64800} },
[8] = { id=8,price=120000,price_record=120000,prop={[2]=120000} }
}