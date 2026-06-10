---@class TransactionConfig_cfg
---@field public id integer @ID，不能重复
---@field public refresh_time integer @上架次数刷新时间(从每日零点计，单位：秒）
---@field public unsell_time integer @可下架时间（当上架剩余时间大于或等于该时间时，可以下架该商品，单位：秒
---@field public service_charge_type integer @上架手续费和上架管理费货币类型
---@field public bid_percentage integer @竞拍：最低出价系数（最低出价 = 当前最高出价 * 系数），万分比
---@field public auction_deadline integer @竞拍：临近截至时间（秒）
---@field public postpone_extratime integer @竞拍：单次延期时间（秒）
---@field public auction_postpone_maxtime integer @竞拍：最大延期次数
---@field public account_market integer @账户每日上架次数
---@field public collection_num integer @最大收藏（关注）数量
---@field public order_num integer @上架容量
---@field public order_time table @上架时间配置 【上架时间（秒）：对应管理费】
---@field public order_currency integer @买卖结算货币类型
---@field public service_charge integer @结算服务费系数（万分比）
---@field public shipments_email integer @发货邮件id（发给买家）
---@field public sell_email integer @售出通知邮件id（发给卖家）
---@field public unsell_email integer @主动下架邮件id
---@field public expire_email integer @到期强制下架邮件id
---@field public failed_email integer @拍卖行竞拍失败邮件id
return {
[1] = { id=1,refresh_time=18000,unsell_time=300,service_charge_type=1,bid_percentage=0,auction_deadline=0,postpone_extratime=0,auction_postpone_maxtime=0,account_market=10,collection_num=20,order_num=5,order_time={[43200]=300,[86400]=600,[172800]=1200},order_currency=1,service_charge=1500,shipments_email=2000010,sell_email=2000011,unsell_email=2000012,expire_email=2000013,failed_email=0 },
[2] = { id=2,refresh_time=0,unsell_time=0,service_charge_type=1,bid_percentage=11000,auction_deadline=120,postpone_extratime=300,auction_postpone_maxtime=10,account_market=5,collection_num=10,order_num=3,order_time={[43200]=300,[86400]=600,[172800]=1200},order_currency=2,service_charge=1500,shipments_email=2000014,sell_email=2000015,unsell_email=2000016,expire_email=2000017,failed_email=2000018 }
}