---@class ChosenTreasureChest_cfg
---@field public id integer @宝匣ID
---@field public ticket_id integer @令ID
---@field public start_time integer @开售时间戳
---@field public end_time integer @下线时间戳
---@field public step_prices table @九档价格
---@field public slot_items table @九格物件
---@field public slot_weights table @九格权重(合计10000)
---@field public gift_lv integer @赠礼需求账户等级
---@field public type integer @类型 1=皮肤 2=法器 3=道具
return {
[1] = { id=1,ticket_id=200,start_time=1794908494,end_time=1795772494,step_prices={[1]=16,[2]=30,[3]=44,[4]=58,[5]=72,[6]=86,[7]=100,[8]=114,[9]=128},slot_items={[1]=661012,[2]=661013,[3]=661014,[4]=661015,[5]=661016,[6]=661017,[7]=661018,[8]=661019,[9]=661020},slot_weights={[1]=50,[2]=150,[3]=500,[4]=500,[5]=1000,[6]=1000,[7]=1400,[8]=1900,[9]=3500},gift_lv=30,type=1 }
}