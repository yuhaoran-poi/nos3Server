---@class AccountBuffConfig_cfg
---@field public id integer @账户 buff id
---@field public buff_effect integer @buff的效果：（配置生效后不可更改） 1 = 结算加成_角色经验； 2 = 结算加成_账户经验； 3 = 结算加成_货币加成 1（货币 id = 1）；
---@field public buff_coefficient integer @buff的加成系数（%万分比）
---@field public period_type integer @buff生效周期类型：（配置生效后不可更改） 1 = 次数生效； 2 = 时长生效（秒）；
return {
[1] = { id=1,buff_effect=1,buff_coefficient=20000,period_type=1 },
[2] = { id=2,buff_effect=3,buff_coefficient=20000,period_type=2 }
}