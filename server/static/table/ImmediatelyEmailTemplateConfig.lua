---@class ImmediatelyEmailTemplateConfig_cfg
---@field public id integer @ID
---@field public icon integer @邮件图标ID
---@field public type integer @邮件类型(UI标记)
---@field public title integer @邮件标题
---@field public content integer @邮件正文
---@field public signature integer @邮件署名
---@field public validity_period integer @邮件保存期（秒）
---@field public read_validity_period integer @已读邮件保存期（秒）
---@field public is_active boolean @该邮件是否有效
return {
[2000001] = { id=2000001,icon=1,type=1,title=1000,content=5000,signature=9000,validity_period=2592000,read_validity_period=604800,is_active=true },
[2000002] = { id=2000002,icon=1,type=1,title=1001,content=5001,signature=9001,validity_period=2592000,read_validity_period=604800,is_active=true },
[2000003] = { id=2000003,icon=1,type=1,title=1002,content=5002,signature=9001,validity_period=2592000,read_validity_period=604800,is_active=true },
[2000010] = { id=2000010,icon=3,type=3,title=2000,content=5001,signature=9001,validity_period=2592000,read_validity_period=604800,is_active=true },
[2000011] = { id=2000011,icon=3,type=3,title=2001,content=5002,signature=9001,validity_period=2592000,read_validity_period=604800,is_active=true },
[2000012] = { id=2000012,icon=3,type=3,title=2002,content=5003,signature=9001,validity_period=2592000,read_validity_period=604800,is_active=true },
[2000013] = { id=2000013,icon=3,type=3,title=2003,content=5004,signature=9001,validity_period=2592000,read_validity_period=604800,is_active=true },
[2000014] = { id=2000014,icon=4,type=4,title=2004,content=5005,signature=9002,validity_period=2592000,read_validity_period=604800,is_active=true },
[2000015] = { id=2000015,icon=4,type=4,title=2005,content=5006,signature=9002,validity_period=2592000,read_validity_period=604800,is_active=true },
[2000016] = { id=2000016,icon=4,type=4,title=2006,content=5007,signature=9002,validity_period=2592000,read_validity_period=604800,is_active=true },
[2000017] = { id=2000017,icon=4,type=4,title=2007,content=5008,signature=9002,validity_period=2592000,read_validity_period=604800,is_active=true },
[2000018] = { id=2000018,icon=4,type=4,title=2008,content=5009,signature=9002,validity_period=2592000,read_validity_period=604800,is_active=true }
}