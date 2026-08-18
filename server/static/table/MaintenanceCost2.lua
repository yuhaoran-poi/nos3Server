---@class MaintenanceCost2_cfg
---@field public id integer @
---@field public type1 integer @八卦牌：1 法器：2 戒指：3
---@field public type2 integer @1.灰 2.白 3.蓝 4.紫 5.金 6.红 7.粉
---@field public sturdy_reset_count integer @坚固值恢复次数
---@field public cost1 table @第1次坚固值恢复消耗
---@field public cost2 table @第2次坚固值恢复消耗
---@field public cost3 table @第3次坚固值恢复消耗
---@field public cost4 table @第4次坚固值恢复消耗
---@field public cost5 table @第4次坚固值恢复消耗
return {
[1] = { id=1,type1=1,type2=2,sturdy_reset_count=5,cost1={[102]=25},cost2={[102]=50},cost3={[102]=75},cost4={[102]=100},cost5={[102]=125} },
[2] = { id=2,type1=1,type2=3,sturdy_reset_count=5,cost1={[102]=60},cost2={[102]=120},cost3={[102]=180},cost4={[102]=240},cost5={[102]=350} },
[3] = { id=3,type1=1,type2=4,sturdy_reset_count=5,cost1={[102]=115},cost2={[102]=230},cost3={[102]=345},cost4={[102]=460},cost5={[102]=575} },
[4] = { id=4,type1=1,type2=5,sturdy_reset_count=5,cost1={[102]=275},cost2={[102]=550},cost3={[102]=825},cost4={[102]=1100},cost5={[102]=1375} },
[5] = { id=5,type1=1,type2=6,sturdy_reset_count=5,cost1={[102]=650},cost2={[102]=1300},cost3={[102]=1950},cost4={[102]=2600},cost5={[102]=3250} },
[6] = { id=6,type1=2,type2=2,sturdy_reset_count=5,cost1={[101]=100},cost2={[101]=200},cost3={[101]=300},cost4={[101]=400},cost5={[101]=500} },
[7] = { id=7,type1=2,type2=3,sturdy_reset_count=5,cost1={[101]=240},cost2={[101]=480},cost3={[101]=720},cost4={[101]=960},cost5={[101]=1200} },
[8] = { id=8,type1=2,type2=4,sturdy_reset_count=5,cost1={[101]=460},cost2={[101]=920},cost3={[101]=1380},cost4={[101]=1840},cost5={[101]=2300} },
[9] = { id=9,type1=2,type2=5,sturdy_reset_count=5,cost1={[101]=1100},cost2={[101]=2200},cost3={[101]=3300},cost4={[101]=4400},cost5={[101]=5500} },
[10] = { id=10,type1=2,type2=6,sturdy_reset_count=5,cost1={[101]=2600},cost2={[101]=5200},cost3={[101]=7800},cost4={[101]=10400},cost5={[101]=13000} },
[11] = { id=11,type1=3,type2=2,sturdy_reset_count=5,cost1={[101]=100},cost2={[101]=200},cost3={[101]=300},cost4={[101]=400},cost5={[101]=500} },
[12] = { id=12,type1=3,type2=3,sturdy_reset_count=5,cost1={[101]=240},cost2={[101]=480},cost3={[101]=720},cost4={[101]=960},cost5={[101]=1200} },
[13] = { id=13,type1=3,type2=4,sturdy_reset_count=5,cost1={[101]=460},cost2={[101]=920},cost3={[101]=1380},cost4={[101]=1840},cost5={[101]=2300} },
[14] = { id=14,type1=3,type2=5,sturdy_reset_count=5,cost1={[101]=1100},cost2={[101]=2200},cost3={[101]=3300},cost4={[101]=4400},cost5={[101]=5500} },
[15] = { id=15,type1=3,type2=6,sturdy_reset_count=5,cost1={[101]=2600},cost2={[101]=5200},cost3={[101]=7800},cost4={[101]=10400},cost5={[101]=13000} }
}