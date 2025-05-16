---@class HumanRole_cfg
---@field public id integer @灵探角色id 1000000 ~ 1001000
---@field public magic_slot integer @法器槽类型 101-剑 102-拂尘 103-伞 104-鞭 105-弹弓 106-双枪 107-关刀 108-长枪 109-弓箭 110-刀 111-扇子 112-重剑
---@field public init_main_skill integer @初始装备的大招
---@field public main_skill integer[] @全部大招
---@field public init_q_skill integer @初始Q技能
---@field public q_skill integer[] @全部Q技能
---@field public init_e_skill integer @初始E技能
---@field public e_skill integer[] @全部E技能
---@field public disable_match integer @禁用模式（后续可能增加） 0-不禁用 1-全模式禁用 2-主线模式禁用
return {
[1000000] = { id=1000000,magic_slot=101,init_main_skill=1001000,main_skill={1001000,1001001},init_q_skill=1001000,q_skill={1001000,1001001,1001002},init_e_skill=1001000,e_skill={1001000,1001001,1001002},disable_match=0 },
[1000001] = { id=1000001,magic_slot=101,init_main_skill=1001000,main_skill={1001000,1001002},init_q_skill=1001000,q_skill={1001000,1001001,1001003},init_e_skill=1001000,e_skill={1001000,1001001,1001003},disable_match=0 },
[1000002] = { id=1000002,magic_slot=101,init_main_skill=1001000,main_skill={1001000,1001003},init_q_skill=1001000,q_skill={1001000,1001001,1001004},init_e_skill=1001000,e_skill={1001000,1001001,1001004},disable_match=0 },
[1000003] = { id=1000003,magic_slot=101,init_main_skill=1001000,main_skill={1001000,1001004},init_q_skill=1001000,q_skill={1001000,1001001,1001005},init_e_skill=1001000,e_skill={1001000,1001001,1001005},disable_match=0 },
[1000004] = { id=1000004,magic_slot=101,init_main_skill=1001000,main_skill={1001000,1001005},init_q_skill=1001000,q_skill={1001000,1001001,1001006},init_e_skill=1001000,e_skill={1001000,1001001,1001006},disable_match=0 }
}