---@class ChosenTreasureChest_cfg
---@field public id integer @宝匣ID
---@field public ticket_id integer @令ID
---@field public ticket_price table @令价格
---@field public start_time integer @开售时间戳
---@field public end_time integer @下线时间戳
---@field public step_prices table @九档价格
---@field public slot_items table @九格物件
---@field public slot_weights table @九格权重(合计10000)
---@field public gift_lv integer @赠礼需求账户等级
---@field public type integer @类型 1=皮肤 2=法器 3=道具
return {
[1] = { id=1,ticket_id=200,ticket_price={[3]=100},start_time=1794908494,end_time=1798322400,step_prices={[1]=10,[2]=20,[3]=30,[4]=40,[5]=60,[6]=80,[7]=100,[8]=140,[9]=180},slot_items={[1]=360014,[2]=360040,[3]=851013,[4]=661105,[5]=661107,[6]=661106,[7]=862039,[8]=861516,[9]=861023},slot_weights={[1]=50,[2]=150,[3]=500,[4]=500,[5]=1000,[6]=1000,[7]=1400,[8]=1900,[9]=3500},gift_lv=30,type=1 }
}