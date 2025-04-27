--用于proto中可能会用到的枚举
--注意本文件要和插件中的CmdEnum.h同步修改

local CmdEnum = {
-- 广播类型
BroadcastType = {
    NO_BROADCAST = 0,
    SINGLE_CONNECTION = 1,
    ALL = 2,
    ALL_BUT_SENDER = 4,
    ALL_BUT_OWNER = 8,
    ALL_BUT_CLIENT = 16,
    ALL_BUT_SERVER = 32,
    ADJACENT_CHANNELS = 64,
},
-- 连接类型
ConnectionType = {
    NO_CONNECTION = 0,
    SERVER = 1,
    CLIENT = 2,
},

ChannelType = {
    UNKNOWN = 0,
    GLOBAL = 1,
    PRIVATE = 2,
    SUBWORLD = 3,
    SPATIAL = 4,
    ENTITY = 5,
},
-- DS类型
DSType = {
    Client = 0,
    Global = 1,
    Master = 2,
    BigGrid = 3,
    HotGrid = 4,
},
-- 消息类型
MessageType = {
    INVALID = 0,
    USER_SPACE_START = 100
},
-- 加密类型
CompressionType = {
    NO_COMPRESSION = 0,
},
-- 固定节点ID
FixedNodeId = {
    INVALID = 0,
    CHAT = 3001,
    MATCH = 3002,
    MANAGER = 3999,
    HUB = 10000,
}

}

return CmdEnum