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
---@field public custom integer @是否需要数据拼接(0不需要、1需要)
return {
[2000001] = { id=2000001,icon=1,type=1,title=2001,content=5001,signature=9000,validity_period=2592000,read_validity_period=604800,is_active=true,custom=0 },
[2000002] = { id=2000002,icon=1,type=1,title=2002,content=5002,signature=9001,validity_period=2592000,read_validity_period=604800,is_active=true,custom=0 },
[2000003] = { id=2000003,icon=1,type=1,title=2003,content=5003,signature=9001,validity_period=2592000,read_validity_period=604800,is_active=true,custom=0 },
[2000010] = { id=2000010,icon=3,type=3,title=2010,content=5010,signature=9001,validity_period=2592000,read_validity_period=604800,is_active=true,custom=1 },
[2000011] = { id=2000011,icon=3,type=3,title=2011,content=5011,signature=9001,validity_period=2592000,read_validity_period=604800,is_active=true,custom=1 },
[2000012] = { id=2000012,icon=3,type=3,title=2012,content=5012,signature=9001,validity_period=2592000,read_validity_period=604800,is_active=true,custom=1 },
[2000013] = { id=2000013,icon=3,type=3,title=2013,content=5013,signature=9001,validity_period=2592000,read_validity_period=604800,is_active=true,custom=1 },
[2000014] = { id=2000014,icon=4,type=4,title=2014,content=5014,signature=9002,validity_period=2592000,read_validity_period=604800,is_active=true,custom=1 },
[2000015] = { id=2000015,icon=4,type=4,title=2015,content=5015,signature=9002,validity_period=2592000,read_validity_period=604800,is_active=true,custom=1 },
[2000016] = { id=2000016,icon=4,type=4,title=2016,content=5016,signature=9002,validity_period=2592000,read_validity_period=604800,is_active=true,custom=1 },
[2000017] = { id=2000017,icon=4,type=4,title=2017,content=5017,signature=9002,validity_period=2592000,read_validity_period=604800,is_active=true,custom=1 },
[2000018] = { id=2000018,icon=4,type=4,title=2018,content=5018,signature=9002,validity_period=2592000,read_validity_period=604800,is_active=true,custom=1 },
[2000020] = { id=2000020,icon=0,type=1,title=2020,content=5020,signature=9000,validity_period=2592000,read_validity_period=604800,is_active=true,custom=0 },
[2000021] = { id=2000021,icon=0,type=1,title=2021,content=5021,signature=9000,validity_period=2592000,read_validity_period=604800,is_active=true,custom=0 },
[2000022] = { id=2000022,icon=0,type=1,title=2022,content=5022,signature=9000,validity_period=2592000,read_validity_period=604800,is_active=true,custom=0 }
}