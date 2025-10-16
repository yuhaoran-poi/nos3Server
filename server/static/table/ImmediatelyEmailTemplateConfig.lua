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
[2000003] = { id=2000003,icon=1,type=1,title=1002,content=5002,signature=9001,validity_period=2592000,read_validity_period=604800,is_active=true }
}