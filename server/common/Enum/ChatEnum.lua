 -- 聊天相关枚举定义

local ChatEnum = {
	-- 频道类型
	EChannelType = {
       CHANNEL_TYPE_NONE = 0,    --无
       CHANNEL_TYPE_NEARBY = 1,  --附近
       CHANNEL_TYPE_WORLD = 2,   --世界
       CHANNEL_TYPE_TEAM = 3,    --队伍
       CHANNEL_TYPE_GUILD = 4,   --公会
       CHANNEL_TYPE_PRIVATE = 5, --私聊
       CHANNEL_TYPE_SYSTEM = 6, --系统
       CHANNEL_TYPE_ROOM = 7, --房间
    }

}

return ChatEnum
