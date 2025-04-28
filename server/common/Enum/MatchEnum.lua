 -- 匹配相关枚举定义

local MatchEnum = {
    -- 匹配类型定义
    MATCH_TYPE_DEF = {
        -- 匹配
        MATCH_TYPE_NORMAL   = 0,
        -- 排位                
        MATCH_TYPE_RANKING  = 1,
        --狼人杀模式           
        MATCH_TYPE_LRS		= 2,
	    --驱灵模式           
        MATCH_TYPE_QL		= 3,
	    -- 据点战模式
        MATCH_TYPE_JDZ = 4,
        -- 匹配类型最大
        MATCH_TYPE_MAX		= 5
    },
    -- 阵营类型
    MATCH_CAMP_DEF = {
    	MATCH_CAMP_NULL = 0,
        MATCH_CAMP_GHOST = 1,
        MATCH_CAMP_HUMAN = 2,
	    MATCH_CAMP_RED = 3,
	    MATCH_CAMP_BLUE = 4,
	    MATCH_CAMP_STRONGHLOD_MATCH = 5,
        MATCH_CAMP_MAX = 6,
        -- OB位比较特殊 设成100 以后加非特殊的阵营放置在MATCH_CAMP_MAX之前
	    MATCH_CAMP_OB = 100
    },
    -- 坂选禁用阶段
    PBSelectionStateType = {
        PBSelectionState_Disable    = 1, -- 禁用阶段
        PBSelectionState_Selection  = 2, -- 选择阶段
        PBSelectionState_Setup      = 3, -- 装配 道具 和技能 皮肤阶段
        PBSelectionState_Succ        = 4, -- 流程正常结束(开始创建ds房间)
        PBSelectionState_Close      = 5, -- bp错误情况，房间关闭
	    PBSelectionState_LRS_SelectionGhost      = 6, -- 狼人杀鬼选择阶段
	    PBSelectionState_LRS_SetupGhost      = 7, -- 狼人杀选鬼装配阶段
	    PBSelectionState_SH_Ghost_Select_Skin = 8, -- 据点战选鬼皮肤阶段
    },
    -- 操作类型
    PBSelectionOpType = {
         PBSelectionOp_Disable_Map       = 1, -- 禁用
         PBSelectionOp_Disable_Role      = 2,
         PBSelectionOp_Selection_Map     = 3, -- 选用
         PBSelectionOp_Selection_Role    = 4,
         -- 装配
         PBSelectionOp_Setup_Item        = 5, -- 道具
         PBSelectionOp_Setup_Skin        = 6, -- 皮肤
	     PBSelectionOp_Setup_LRSVieItem  = 7, -- 狼人杀争抢道具
    },
    -- 匹配状态
    MatchRoomState = {
        -- 初始化
        MatchRoomState_Init = 0,
        -- 匹配中
        MatchRoomState_Matching = 1,
        -- 坂选状态
        MatchRoomState_Selection = 2,
        -- 创建DS房间
        MatchRoomState_CreateDSRoom = 3,
        -- 等待DS房间创建
        MatchRoomState_WaitDSRoom = 4,
        -- 战斗中
        MatchRoomState_Fight = 5,
        -- 结算中
        MatchRoomState_Settle = 6,
        -- 房间关闭
        MatchRoomState_Close = 7,
        -- 房间销毁
        MatchRoomState_Destroy = 8,
        
    }
}

return MatchEnum
