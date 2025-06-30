---@class HumanRole_cfg
---@field public id integer @灵探角色id 1000000 ~ 1001000
---@field public lv integer @最大等级
---@field public star integer @最大星级
---@field public magic_slot_type integer @法器槽类型 101-剑 102-拂尘 103-伞 104-鞭 105-弹弓 106-双枪 107-关刀 108-长枪 109-弓箭 110-刀 111-扇子 112-重剑
---@field public default_faqi integer @默认装备法器id
---@field public book_slot_num integer @真经最大学习数量
---@field public book_study integer @正在学习的真经最大数量
---@field public bagua_slot_num integer @八卦牌槽位数量（每种类型1个） 1-乾（☰） 2-巽（☴） 3-坎（☵） 4-艮（☶） 5-坤（☷） 6-震（☳） 7-离（☲） 8-兑（☱）
---@field public skin_slot_num integer @皮肤槽位数量（每种类型1个） 1-角色槽（脸） 2-头饰槽（头饰、帽子、发型、发色） 3-面饰槽（眼睛、面纱） 4-上衣槽 5-下装槽（裤子、鞋子、丝袜） 6-武器槽（特效、武器外观） 7-套装槽（上下装）
---@field public action_slot_type integer[] @表情动作槽可以装配的类型
---@field public action_slot_num integer @表情动作可装配数量
---@field public init_passive_skill integer @初始被动
---@field public passive_skill integer[] @全部被动
---@field public init_main_skill integer @初始装备的大招
---@field public main_skill integer[] @全部大招
---@field public init_q_skill integer @初始Q技能
---@field public q_skill integer[] @全部Q技能
---@field public init_e_skill integer @初始E技能
---@field public e_skill integer[] @全部E技能
---@field public disable_match integer @禁用模式（后续可能增加） 0-不禁用 1-全模式禁用 2-主线模式禁用
return {
[1000000] = { id=1000000,lv=50,star=10,magic_slot_type=101,default_faqi=600000,book_slot_num=999,book_study=5,bagua_slot_num=8,skin_slot_num=7,action_slot_type={8,9},action_slot_num=8,init_passive_skill=1130000,passive_skill={1130000,1130001},init_main_skill=1001000,main_skill={1001000,1001001},init_q_skill=1001000,q_skill={1001000,1001001,1001002},init_e_skill=1001000,e_skill={1001000,1001001,1001002},disable_match=0 },
[1000001] = { id=1000001,lv=50,star=10,magic_slot_type=101,default_faqi=600000,book_slot_num=999,book_study=5,bagua_slot_num=8,skin_slot_num=7,action_slot_type={8,9},action_slot_num=8,init_passive_skill=1130000,passive_skill={1130000,1130001},init_main_skill=1001000,main_skill={1001000,1001002},init_q_skill=1001000,q_skill={1001000,1001001,1001003},init_e_skill=1001000,e_skill={1001000,1001001,1001003},disable_match=0 },
[1000002] = { id=1000002,lv=50,star=10,magic_slot_type=101,default_faqi=600000,book_slot_num=999,book_study=5,bagua_slot_num=8,skin_slot_num=7,action_slot_type={8,9},action_slot_num=8,init_passive_skill=1130000,passive_skill={1130000,1130001},init_main_skill=1001000,main_skill={1001000,1001003},init_q_skill=1001000,q_skill={1001000,1001001,1001004},init_e_skill=1001000,e_skill={1001000,1001001,1001004},disable_match=0 },
[1000003] = { id=1000003,lv=50,star=10,magic_slot_type=101,default_faqi=600000,book_slot_num=999,book_study=5,bagua_slot_num=8,skin_slot_num=7,action_slot_type={8,9},action_slot_num=8,init_passive_skill=1130000,passive_skill={1130000,1130001},init_main_skill=1001000,main_skill={1001000,1001004},init_q_skill=1001000,q_skill={1001000,1001001,1001005},init_e_skill=1001000,e_skill={1001000,1001001,1001005},disable_match=0 },
[1000004] = { id=1000004,lv=50,star=10,magic_slot_type=101,default_faqi=600000,book_slot_num=999,book_study=5,bagua_slot_num=8,skin_slot_num=7,action_slot_type={8,9},action_slot_num=8,init_passive_skill=1130000,passive_skill={1130000,1130001},init_main_skill=1001000,main_skill={1001000,1001005},init_q_skill=1001000,q_skill={1001000,1001001,1001006},init_e_skill=1001000,e_skill={1001000,1001001,1001006},disable_match=0 }
}