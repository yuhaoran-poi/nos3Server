---@class BroadcastType
local BroadcastType = {
    NO_BROADCAST = 0,
    SINGLE_CONNECTION = 1,
    ALL = 2,
    ALL_BUT_SENDER = 4,
    ALL_BUT_OWNER = 8,
    ALL_BUT_CLIENT = 16,
    ALL_BUT_SERVER = 32,
    ADJACENT_CHANNELS = 64,
}

---@class ConnectionType
local ConnectionType = {
    NO_CONNECTION = 0,
    SERVER = 1,
    CLIENT = 2,
}

---@class ChannelType
local ChannelType = {
    UNKNOWN = 0,
    GLOBAL = 1,
    PRIVATE = 2,
    SUBWORLD = 3,
    SPATIAL = 4,
    ENTITY = 5,
    TEST = 100,
    TEST1 = 101,
    TEST2 = 102,
    TEST3 = 103,
    TEST4 = 104,
}

---@class MessageType
local MessageType = {
    INVALID = 0,
    AUTH = 1,
    CREATE_CHANNEL = 3,
    REMOVE_CHANNEL = 4,
    LIST_CHANNEL = 5,
    SUB_TO_CHANNEL = 6,
    UNSUB_FROM_CHANNEL = 7,
    CHANNEL_DATA_UPDATE = 8,
    DISCONNECT = 9,
    CREATE_SPATIAL_CHANNEL = 10,
    QUERY_SPATIAL_CHANNEL = 11,
    CHANNEL_DATA_HANDOVER = 12,
    SPATIAL_REGIONS_UPDATE = 13,
    UPDATE_SPATIAL_INTEREST = 14,
    CREATE_ENTITY_CHANNEL = 15,
    ENTITY_GROUP_ADD = 16,
    ENTITY_GROUP_REMOVE = 17,
    DEBUG_GET_SPATIAL_REGIONS = 99,
    USER_SPACE_START = 100,
}

---@class CompressionType
local CompressionType = {
    NO_COMPRESSION = 0,
    SNAPPY = 1,
}

---@class AuthResult
local AuthResult = {
    SUCCESSFUL = 0,
    INVALID_PIT = 1,
    INVALID_LT = 2,
}

---@class ChannelDataAccess
local ChannelDataAccess = {
    NO_ACCESS = 0,
    READ_ACCESS = 1,
    WRITE_ACCESS = 2,
}

---@class EntityGroupType
local EntityGroupType = {
    HANDOVER = 0,
    LOCK = 1,
}

---@class MessageType
local MessageType = {
    INVALID = 0,
    LOW_LEVEL = 100,
    ANY = 101,
    RPC = 102,
    SPAWN = 103,
    DESTROY = 104,
    SYNC_NET_ID = 107,
    SERVER_PLAYER_SPAWNED = 201,
    SERVER_PLAYER_LEAVE = 202,
}

---@class UnrealObjectType
local UnrealObjectType = {
    UOT_Unknown = 0,
    UOT_GameState = 1,
    UOT_Actor = 2,
    UOT_Pawn = 3,
    UOT_Character = 4,
    UOT_PlayerState = 5,
    UOT_Controller = 6,
    UOT_PlayerController = 7,
}



return {
    BroadcastType=BroadcastType,
    ConnectionType=ConnectionType,
    ChannelType=ChannelType,
    MessageType=MessageType,
    CompressionType=CompressionType,
    AuthResult=AuthResult,
    ChannelDataAccess=ChannelDataAccess,
    EntityGroupType=EntityGroupType,
    MessageType=MessageType,
    UnrealObjectType=UnrealObjectType,
}
