 -- 公会相关枚举定义

local GuildEnum = {
    -- 公会记录类型
    EGuildRecordType = {
    --所有记录
	eRT_ALL_RECORD = 0,
	--身份变更（职位变更）+
	eRT_DUTY_CHANGE = 1,
	--加入 +
	eRT_JOIN = 2,
	--退出 +
	eRT_QUIT = 3,
	--战队改名 +
	eRT_CHANGE_GUILD_NAME = 4,
	--战队捐赠 +
	eRT_JUANZENG = 5,
	--战队升级
	eRT_GUILD_LV_UP = 6,
	--使用战队仓库
	eRT_GUILDBAG = 7,
	--战队排位积分变更记录
	eRT_GUILDRANKRECORD = 8,
	--战队GKD变化记录
	eRT_GUILDGKD = 9,
	--战利品发放记录
	eRT_SPOILS_GRANT = 10,
	--赛季积分变化记录
	eRT_SEASON_POINT = 11,
	--玩家充值记录
    eRT_PLAYER_RECHARGE = 12,
    -- 踢人记录
    eRT_KICKOUT = 13,
    },

	-- 公会状态
	EGuildStatus = {
		eNone = 0,			-- 无状态
	    eGS_Creating = 1,	-- 创建中
	    eGS_Init = 2,		-- 初始化中
	    eGS_Normal = 3,		-- 正常
	    eGS_Freeze = 4,	    -- 冻结中
	    eGS_Destory = 5;	-- 已销毁
	},
 

}

return GuildEnum
