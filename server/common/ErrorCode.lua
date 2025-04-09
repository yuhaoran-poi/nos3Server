
---@enum ErrorCode
local ErrorCode = {
    None = 0,
    ServerInternalError = 1,
    ParamInvalid = 2,
    ConfigError =3,
    OperationNotPermit = 4,

    ---没有这个装备
    EquipNotFound = 101,
    ---这个部位没有装备
    EquipSlotEmpty = 102,
    ---无效的装备槽位
    EquipInvalidSlot = 103,
    ---分解不存在的装备或者穿戴中的装备
    EquipInvalidDecompose = 104,

    ---正在战斗中
    FightAlreadyStart = 201,

    ---道具不足
    ItemNotEnough = 301,
    ---道具不存在
    ItemNotExist = 302,

    ---宝物相关错误码
    ---没有拥有该宝物
    TreasureNotFound = 401,
    ---宝物CD中
    TreasureInCD = 402,

    ---没有这个商品ID
    ShopItemNotExist = 501,

    ---商品已售
    ShopItemSoldOut = 502,

    ---兑换次数不够
    ExchangeNotEnough = 503,


    ---奖励已经领取过
    DailyTaskReceived = 701,

    ---队伍相关错误码
    ---已经在队伍中
    TeamAlreadyInTeam = 801,
    ---不在队伍中
    TeamNotInTeam = 802,
    ---不是队长
    TeamNotMaster = 803,
    ---创建队伍失败
    TeamCreateFailed = 804,
    ---加入队伍失败
    TeamJoinFailed = 805,
    ---退出队伍失败
    TeamExitFailed = 806,
    ---踢出队员失败
    TeamKickoutFailed = 807,
    ---获取队伍信息失败
    TeamGetInfoFailed = 808,
    ---队伍不存在
    TeamNotExist = 809,
    ---队伍已满
    TeamFull = 810,
    ---队伍数据损坏
    TeamDataCorrupted = 811,

    ---房间系统错误码（900-910）
    ---未创建房间
    RoomNotCreated = 901,
    ---房间不存在
    RoomNotFound = 902,
    ---无房间操作权限
    RoomPermissionDenied = 903,
    ---玩家不在房间内
    RoomMemberNotFound = 904,
    ---重复的房间申请
    RoomDuplicateApply = 905,
    ---无效的准备操作
    RoomInvalidReadyOp = 906,
    ---房间人数已满
    RoomFull = 907,
    ---已在房间内
    RoomAlreadyInRoom = 908,
    ---房间状态错误
    RoomInvalidState = 909,
    ---房间申请不存在
    RoomApplyNotFound = 910,
}

return ErrorCode