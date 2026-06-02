---@class HumanRole_cfg
---@field public id integer @灵探角色id 1000000 ~ 1001000
---@field public lv integer @最大等级
---@field public star integer @最大星级
---@field public magic_slot_type integer @法器槽类型 101-剑 102-拂尘 103-伞 104-鞭 105-弹弓 106-双枪 107-关刀 108-长枪 109-弓箭 110-刀 111-扇子 112-重剑 113-拳套
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
---@field public Initial_equipment1 integer @初始获得装备（武器）
---@field public Initial_equipment2 table @初始获得装备（八卦牌）
---@field public Initial_equipment3 integer @初始获得装备（戒指）
return {
[1000000] = { id=1000000,lv=50,star=10,magic_slot_type=101,default_faqi=600500,book_slot_num=999,book_study=5,bagua_slot_num=8,skin_slot_num=7,action_slot_type={15},action_slot_num=8,init_passive_skill=2000400,passive_skill={2000400},init_main_skill=2000460,main_skill={2000460},init_q_skill=2000450,q_skill={2000450,2000451,2000452},init_e_skill=2000453,e_skill={2000453,2000454,2000455},disable_match=0,Initial_equipment1=600500,Initial_equipment2={[1]=630000,[2]=630001,[3]=630002,[4]=630003,[5]=630004,[6]=630005,[7]=630006,[8]=630007},Initial_equipment3=650002 },
[1000001] = { id=1000001,lv=50,star=10,magic_slot_type=103,default_faqi=601003,book_slot_num=999,book_study=5,bagua_slot_num=8,skin_slot_num=7,action_slot_type={15},action_slot_num=8,init_passive_skill=2000200,passive_skill={2000200},init_main_skill=2000260,main_skill={2000260},init_q_skill=2000250,q_skill={2000250,2000251,2000252},init_e_skill=2000253,e_skill={2000253,2000254,2000255},disable_match=0,Initial_equipment1=601003,Initial_equipment2={[1]=630000,[2]=630001,[3]=630002,[4]=630003,[5]=630004,[6]=630005,[7]=630006,[8]=630007},Initial_equipment3=650002 },
[1000002] = { id=1000002,lv=50,star=10,magic_slot_type=104,default_faqi=601503,book_slot_num=999,book_study=5,bagua_slot_num=8,skin_slot_num=7,action_slot_type={15},action_slot_num=8,init_passive_skill=2000300,passive_skill={2000300},init_main_skill=2000360,main_skill={2000360},init_q_skill=2000350,q_skill={2000350,2000351,2000352},init_e_skill=2000353,e_skill={2000353,2000354,2000355},disable_match=0,Initial_equipment1=601503,Initial_equipment2={[1]=630000,[2]=630001,[3]=630002,[4]=630003,[5]=630004,[6]=630005,[7]=630006,[8]=630007},Initial_equipment3=650002 },
[1000003] = { id=1000003,lv=50,star=10,magic_slot_type=107,default_faqi=603003,book_slot_num=999,book_study=5,bagua_slot_num=8,skin_slot_num=7,action_slot_type={15},action_slot_num=8,init_passive_skill=2000000,passive_skill={2000000},init_main_skill=2000060,main_skill={2000060},init_q_skill=2000050,q_skill={2000052,2000051,2000050},init_e_skill=2000053,e_skill={2000055,2000054,2000053},disable_match=0,Initial_equipment1=603003,Initial_equipment2={[1]=630000,[2]=630001,[3]=630002,[4]=630003,[5]=630004,[6]=630005,[7]=630006,[8]=630007},Initial_equipment3=650002 },
[1000004] = { id=1000004,lv=50,star=10,magic_slot_type=101,default_faqi=600003,book_slot_num=999,book_study=5,bagua_slot_num=8,skin_slot_num=7,action_slot_type={15},action_slot_num=8,init_passive_skill=2000100,passive_skill={2000100},init_main_skill=2000160,main_skill={2000160},init_q_skill=2000150,q_skill={2000150,2000151,2000152},init_e_skill=2000153,e_skill={2000153,2000155,2000154},disable_match=0,Initial_equipment1=600003,Initial_equipment2={[1]=630000,[2]=630001,[3]=630002,[4]=630003,[5]=630004,[6]=630005,[7]=630006,[8]=630007},Initial_equipment3=650002 },
[1000005] = { id=1000005,lv=50,star=10,magic_slot_type=113,default_faqi=606003,book_slot_num=999,book_study=5,bagua_slot_num=8,skin_slot_num=7,action_slot_type={15},action_slot_num=8,init_passive_skill=2000500,passive_skill={2000500},init_main_skill=2000560,main_skill={2000560},init_q_skill=2000550,q_skill={2000550,2000551,2000552},init_e_skill=2000553,e_skill={2000553,2000554,2000555},disable_match=0,Initial_equipment1=606003,Initial_equipment2={[1]=630000,[2]=630001,[3]=630002,[4]=630003,[5]=630004,[6]=630005,[7]=630006,[8]=630007},Initial_equipment3=650002 }
}