local LuaExt = require "common.LuaExt"

local UserSimpleDef = {}

local defaultPBRankNode = {
	grade = 0,--品阶
	level = 0,--品级
	star = 0,--当前星星数量
	score = 0,--隐藏分
	zhu_ji_points = 0,--筑基点（用于升星或抵扣星星）
	all_stars = 0,--所有星星数（记录玩家所有的星星数量，用于换算品阶、品级这些）
}

-- 段位
local defaultPBRankLevel = {
    ghost_rank = LuaExt.const(table.copy(defaultPBRankNode)),
    human_rank = LuaExt.const(table.copy(defaultPBRankNode)),
    ghost_top_rank = LuaExt.const(table.copy(defaultPBRankNode)),
    human_top_rank = LuaExt.const(table.copy(defaultPBRankNode)),
}

--经验卡/灵币卡/亲密度卡的信息
local defaultPBCardInfo = {
	left_count = 0,--剩余次数
	ratio = 0,--倍率
}
 
--vip
local defaultPBVipInfo = {
	begts = 0,--vip开始时间
	endts = 0,--vip结束时间
	buy_gift_ts = 0,--最后一次购买限购礼包时间
}

local defaultPBSimpleRoleData = {
    config_id = 0,
    skins = {},
}

local defaultPBPinchFaceData = {
    setting_data = "",
}

local defaultPBSimpleGhostData = {
    config_id = 0,
    skin_id = 0,
}

local defaultPBUserSimpleInfo = {
    uid = 0,                                                             --用户ID
    plateform_id = "",                                                   --平台ID
    nick_name = "",                                                      --昵称
    head_icon = 0,                                                       --头像
    sex = 0,                                                             --0-未选 1-男 2-女
    praise_num = 0,                                                      --点赞
    head_frame = 0,                                                      --头像框
    account_create_time = 0,                                             --账户创建时间
    account_level = 1,                                                   --账号等级
    account_exp = 0,                                                     --账号经验
    guild_uid = 0,                                                       --公会UID
    guild_name = "",                                                     --公会名称
    rank_level = LuaExt.const(table.copy(defaultPBRankLevel)),           --排名
    cur_show_role = LuaExt.const(table.copy(defaultPBSimpleRoleData)),   --当前展示的角色
    pinch_face_data = LuaExt.const(table.copy(defaultPBPinchFaceData)),  --捏脸数据
    title = 0,                                                           --当前佩戴的称号
    player_flag = 0,                                                     --玩家标签
    online_time = 0,                                                     --最后一次在线时间
    sum_online_time = 0,                                                 --累计在线时长 单位秒
    pa_flag = 0,                                                         --是否禁言等操作
    cur_show_ghost = LuaExt.const(table.copy(defaultPBSimpleGhostData)), --当前展示的鬼宠
}

---@return PBUserSimpleInfo
function UserSimpleDef.newUserSimpleInfo()
    return LuaExt.const(table.copy(defaultPBUserSimpleInfo))
end

return UserSimpleDef