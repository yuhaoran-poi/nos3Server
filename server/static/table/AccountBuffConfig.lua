---@class AccountBuffConfig_cfg
---@field public id integer @账户 buff id
---@field public buff_effect integer @buff的效果：（配置生效后不可更改） 1 = 结算加成_角色经验； 2 = 结算加成_账户经验； 3 = 结算加成_货币加成 1（货币 id = 1）；
---@field public buff_coefficient integer @buff的加成系数（%万分比）
---@field public period_type integer @buff生效周期类型：（配置生效后不可更改） 1 = 次数生效； 2 = 时长生效（秒）； 3 = 赛季生效（镇山之宝专用）
return {
[1] = { id=1,buff_effect=1,buff_coefficient=20000,period_type=1 },
[2] = { id=2,buff_effect=3,buff_coefficient=20000,period_type=2 },
[3] = { id=3,buff_effect=3,buff_coefficient=30000,period_type=3 },
[4] = { id=4,buff_effect=3,buff_coefficient=40000,period_type=3 },
[5] = { id=5,buff_effect=3,buff_coefficient=50000,period_type=3 },
[6] = { id=6,buff_effect=3,buff_coefficient=60000,period_type=3 },
[7] = { id=7,buff_effect=3,buff_coefficient=70000,period_type=3 }
}