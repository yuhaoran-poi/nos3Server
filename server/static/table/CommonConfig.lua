---@class CommonConfig_cfg
---@field public id integer @ID，不能重复
---@field public name string @查找名称
---@field public value integer @配置数据
---@field public items table @
return {
[1] = { id=1,name="BPSystem_Max",value=300,items={} },
[2] = { id=2,name="BPSystem_Protect",value=100,items={} },
[3] = { id=3,name="MatchMaxTime",value=500,items={} },
[4] = { id=4,name="VIP_LingMoney",value=30,items={} },
[5] = { id=5,name="VIP_Intimacy",value=30,items={} },
[6] = { id=6,name="VIP_Exp",value=30,items={} },
[7] = { id=7,name="VIP_TreasureBox",value=30,items={} },
[8] = { id=8,name="VIP_SeasonPass",value=1,items={} },
[9] = { id=9,name="VIP_SuiYu",value=10,items={} },
[10] = { id=10,name="VIP_BuyGiftNum",value=1,items={} },
[11] = { id=11,name="VIP_GiftPrice",value=100,items={} },
[12] = { id=12,name="BP_OnceBanTime",value=2,items={} },
[13] = { id=13,name="BP_MaxBanTime",value=10,items={} },
[14] = { id=14,name="BP_ItemID",value=70232,items={} },
[15] = { id=15,name="ZL_Coin",value=7,items={} },
[16] = { id=16,name="ZL_ReCoin",value=8,items={} },
[17] = { id=17,name="S_Coin",value=6,items={} },
[18] = { id=18,name="S2_Coin",value=28,items={} },
[19] = { id=19,name="Blessing_RefreshPrice",value=0,items={[1]=1000} },
[20] = { id=20,name="Initialweapon_LV",value=1,items={} },
[21] = { id=21,name="Initialhuman_LV",value=1,items={} },
[22] = { id=22,name="Initialitem_LV",value=1,items={} },
[23] = { id=23,name="ChangeGhostNameCost",value=0,items={[1]=1000} },
[24] = { id=24,name="MaintenanceCost",value=1,items={[1]=10,[2]=1} }
}