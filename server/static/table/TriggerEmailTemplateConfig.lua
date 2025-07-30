---@class TriggerEmailTemplateConfig_cfg
---@field public id integer @ID
---@field public icon integer @邮件图标ID
---@field public type integer @邮件类型(UI标记)
---@field public title integer @邮件标题
---@field public content integer @邮件正文
---@field public signature integer @邮件署名
---@field public attachment table @附件
---@field public validity_period integer @邮件保存期（秒）
---@field public read_validity_period integer @已读邮件保存期（秒）
---@field public is_active boolean @该邮件是否有效
return {
[1] = { id=1,icon=1,type=1,title=1000,content=1001,signature=1002,attachment={[40001]=1,[40003]=3,[1]=1000},validity_period=2592000,read_validity_period=604800,is_active=true },
[2] = { id=2,icon=1,type=2,title=1003,content=1004,signature=1005,attachment={[40001]=1,[40003]=3,[1]=1000},validity_period=2592000,read_validity_period=604800,is_active=true }
}