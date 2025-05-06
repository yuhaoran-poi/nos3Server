---@class PBChannelType
local PBChannelType = {
    CHANNEL_TYPE_NONE = 0, -- 无
    CHANNEL_TYPE_NEARBY = 1, -- 附近
    CHANNEL_TYPE_WORLD = 2, -- 世界
    CHANNEL_TYPE_TEAM = 3, -- 队伍
    CHANNEL_TYPE_GUILD = 4, -- 公会
    CHANNEL_TYPE_PRIVATE = 5, -- 私聊
    CHANNEL_TYPE_SYSTEM = 6, -- 系统
}

---@class enPBGuildStatus
local enPBGuildStatus = {
    eNone = 0,
    eGS_Creating = 1, -- 创建中
    eGS_Init = 2, -- 初始化中
    eGS_Normal = 3, -- 正常
    eGS_Freeze = 4, -- 冻结中
    eGS_Destory = 5, -- 已销毁
}

---@class enGuildRecordType
local enGuildRecordType = {
    eRT_DUTY_CHANGE = 1, -- 身份变更（职位变更）+
    eRT_JOIN = 2, -- 加入 +
    eRT_QUIT = 3, -- 退出 +
    eRT_CHANGE_GUILD_NAME = 4, -- 战队改名 +
    ERT_JUANZENG = 5, -- 战队捐赠 +
    eRT_GUILD_LV_UP = 6, -- 战队升级
    ERT_GUILDBAG = 7, -- 使用战队仓库
    ERT_GUILDRANKRECORD = 8, -- 战队排位积分变更记录
    ERT_GUILDGKD = 9, -- 战队GKD变化记录
    ERT_SPOILS_GRANT = 10, -- 战利品发放记录
    ERT_SEASON_POINT = 11, -- 赛季积分变化记录
    ERT_PLAYER_RECHARGE = 12, -- 玩家充值记录
}

---@class eApplyOpt
local eApplyOpt = {
    AO_NONE = 0,
    AO_ADD = 1,
    AO_DEL = 2,
}

---@class PBSelectionOpType
local PBSelectionOpType = {
    PBSelectionOp_None = 0,
    PBSelectionOp_Disable_Map = 1,
    PBSelectionOp_Disable_Role = 2,
    PBSelectionOp_Selection_Map = 3,
    PBSelectionOp_Selection_Role = 4,
    PBSelectionOp_Setup_Item = 5,
    PBSelectionOp_Setup_Skin = 6,
    PBSelectionOp_Setup_LRSVieItem = 7,
}

---@class PBSelectionStateType
local PBSelectionStateType = {
    PBSelectionState_None = 0,
    PBSelectionState_Disable = 1,
    PBSelectionState_Selection = 2,
    PBSelectionState_Setup = 3,
    PBSelectionState_Succ = 4,
    PBSelectionState_Close = 5,
    PBSelectionState_LRS_SelectionGhost = 6,
    PBSelectionState_LRS_SetupGhost = 7,
    PBSelectionState_SH_Ghost_Select_Skin = 8,
}



return {
    PBChannelType=PBChannelType,
    enPBGuildStatus=enPBGuildStatus,
    enGuildRecordType=enGuildRecordType,
    eApplyOpt=eApplyOpt,
    PBSelectionOpType=PBSelectionOpType,
    PBSelectionStateType=PBSelectionStateType,
}
