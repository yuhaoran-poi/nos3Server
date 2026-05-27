--require("common.LuaPanda").start("127.0.0.1", 8818)
local moon = require "moon"
local common = require "common"
local protocol = require("common.protocol_pb")
local clusterd = require("cluster")
local GameCfg = common.GameCfg
local ErrorCode = common.ErrorCode
local CmdCode = common.CmdCode
local Database = common.Database
local RankDef = require "common.def.RankDef"
local ItemDefine = require("common.logic.ItemDefine")
local BagDef = require("common.def.BagDef")
local ItemDef = require("common.def.ItemDef")

---@type user_context
local context = ...
local scripts = context.scripts

---@class Rank
local Rank = {}

function Rank.Init()
    -- 初始化排行榜数据
    -- 这里可以加载玩家的排行榜相关数据
end

-- 获取玩家出战信息（角色、鬼怪）- 从 cur_show_role 和 cur_show_ghost 获取
local function getPlayerBattleInfo()
    local user_attr = scripts.UserModel.GetUserAttr()
    local cur_show_role = user_attr.cur_show_role or {}
    local cur_show_ghost = user_attr.cur_show_ghost or {}

    -- 获取角色所有穿戴的皮肤（map转数组）
    local role_skins = {}
    if cur_show_role.skins then
        for _, skin_id in pairs(cur_show_role.skins) do
            table.insert(role_skins, skin_id)
        end
    end

    return {
        chr = cur_show_role.config_id or 0,     -- 出战角色配置ID
        chs = role_skins,                       -- 出战角色所有时装（数组）
        gho = cur_show_ghost.config_id or 0,   -- 出战鬼怪配置ID
        ghs = cur_show_ghost.skin_id or 0,      -- 出战鬼怪时装
    }
end

function Rank.Start(isnew)
    -- 启动时的处理
    -- 检查并分配玩家到各种排行榜
    Rank.AssignPlayerToAllRanks()
    print("Player assigned to all ranks")
end

-- 分配玩家到所有排行榜
function Rank.AssignPlayerToAllRanks()
    local rank_types = {
        RankDef.RankType.Duanwei_Weekly,
        RankDef.RankType.Duanwei_Season,
        RankDef.RankType.Mainline,
        RankDef.RankType.Fengta,
        RankDef.RankType.Fadian_Total,
        RankDef.RankType.Fadian_Weekly,
        RankDef.RankType.Fadian_Monthly,
        RankDef.RankType.Player,
        RankDef.RankType.Role,
        RankDef.RankType.Antique,
        RankDef.RankType.GuildActive,
        RankDef.RankType.GuildMoney,
        RankDef.RankType.GuildScore_Weekly,
        RankDef.RankType.GuildScore_Season,
    }

    local battle_info = getPlayerBattleInfo()
    for _, rank_type in ipairs(rank_types) do
        local player_data = {
            uid = context.uid,
            name = scripts.UserModel.GetUserAttr().nick_name or "",
            avatar = scripts.UserModel.GetUserAttr().head_icon or 0,
            af = scripts.UserModel.GetUserAttr().head_frame or 0,
            gn = scripts.UserModel.GetUserAttr().guild_name or "",
            gid = scripts.UserModel.GetUserAttr().guild_id or 0,
            value = 0, -- 初始分数为0
            ed = {},
            -- 出战角色和鬼怪信息（初始化时也要记录）
            chr = battle_info.chr,
            chs = battle_info.chs,
            gho = battle_info.gho,
            ghs = battle_info.ghs,
        }
        -- force=false: 初始化模式，不覆盖已有非零分数
        Rank.UpdatePlayerRank(rank_type, player_data, false)
    end
end

-- 获取排行榜数据
function Rank.PBRankGetInfoReqCmd(req)
    local rank_type = req.msg.rank_type
    local rank_id = req.msg.rank_id

    if not rank_type then
        return context.S2C(context.net_id, CmdCode.PBRankGetInfoRspCmd, {
            code = ErrorCode.ParamInvalid,
            error = "无效的请求参数",
            uid = context.uid,
        }, req.msg_context.stub_id)
    end

    -- 调用排行榜服务获取数据
    local rank_addr = moon.queryservice("rank")
    if rank_addr == 0 then
        moon.error("Cannot find rank service")
        return context.S2C(context.net_id, CmdCode.PBRankGetInfoRspCmd, {
            code = ErrorCode.ServerInternalError,
            error = "获取排行榜数据失败",
            uid = context.uid,
        }, req.msg_context.stub_id)
    end
    local rank_data = moon.call("lua", rank_addr, "getRankData", rank_type, rank_id)

    if not rank_data or type(rank_data) ~= "table" then
        moon.error("Failed to get rank data:", rank_data)
        return context.S2C(context.net_id, CmdCode.PBRankGetInfoRspCmd, {
            code = ErrorCode.ServerInternalError,
            error = "获取排行榜数据失败",
            uid = context.uid,
        }, req.msg_context.stub_id)
    end

    -- 构建响应
    local rsp_msg = {
        code = ErrorCode.None,
        error = "",
        uid = context.uid,
        rank_data = rank_data[1] and rank_data or {rank_data},
    }

    return context.S2C(context.net_id, CmdCode.PBRankGetInfoRspCmd, rsp_msg, req.msg_context.stub_id)
end

-- 领取排行榜奖励
function Rank.PBRankGetRewardReqCmd(req)
    local rank_type = req.msg.rank_type

    if not rank_type then
        return context.S2C(context.net_id, CmdCode.PBRankGetRewardRspCmd, {
            code = ErrorCode.ParamInvalid,
            error = "无效的请求参数",
            uid = context.uid
        }, req.msg_context.stub_id)
    end

    -- 调用排行榜服务领取奖励
    local rank_addr = moon.queryservice("rank")
    if rank_addr == 0 then
        moon.error("Cannot find rank service")
        return context.S2C(context.net_id, CmdCode.PBRankGetRewardRspCmd, {
            code = ErrorCode.ServerInternalError,
            error = "领取奖励失败",
            uid = context.uid
        }, req.msg_context.stub_id)
    end
    local code, reward_cfg = moon.call("lua", rank_addr, "getRankReward", rank_type, context.uid)

    if code ~= ErrorCode.None or not reward_cfg then
        return context.S2C(context.net_id, CmdCode.PBRankGetRewardRspCmd, {
            code = code,
            error = "领取奖励失败",
            uid = context.uid
        }, req.msg_context.stub_id)
    end

    -- 发放奖励
    -- 这里需要调用奖励发放相关的函数
    local add_items = {}
    for item_id, item_cnt in pairs(reward_cfg) do
        if not add_items[item_id] then
            add_items[item_id] = {
                id = item_id,
                count = 0,
                pos = 0,
            }
        end
        add_items[item_id].count = add_items[item_id].count + item_cnt
    end

    local stack_items, unstack_items, deal_coins = {}, {}, {}
    if table.size(add_items) > 0 then
        local ok = ItemDefine.GetItemDataFromIdCount(add_items, {}, stack_items, unstack_items, deal_coins)
        if not ok then
            return context.S2C(context.net_id, CmdCode.PBRankGetRewardRspCmd,{
                 code = ErrorCode.ConfigError,
                 error = "排行榜奖励配置不存在",
                 uid = context.uid
            }, req.msg_context.stub_id)
        end
    end
    local bag_err_code = scripts.Bag.CheckEmptyEnough(BagDef.BagType.Cangku, stack_items, table.size(unstack_items))
    if bag_err_code ~= ErrorCode.None then
        return context.S2C(context.net_id, CmdCode.PBRankGetRewardRspCmd,
            { code = bag_err_code, error = "背包空间不足", uid = context.uid }, req.msg_context.stub_id)
    end
    -- 添加道具
    local bag_change_log = {}
    if table.size(stack_items) + table.size(unstack_items) > 0 then
        bag_err_code = scripts.Bag.AddItems(BagDef.BagType.Cangku, stack_items, unstack_items, bag_change_log)
        if bag_err_code ~= ErrorCode.None then
            scripts.Bag.RollBackWithChange(bag_change_log)
            return context.S2C(context.net_id, CmdCode.PBRankGetRewardRspCmd,
                { code = bag_err_code, error = "背包空间不足", uid = context.uid }, req.msg_context.stub_id)
        end
    end
    if table.size(deal_coins) > 0 then
        bag_err_code = scripts.Bag.DealCoins(deal_coins, bag_change_log)
        if bag_err_code ~= ErrorCode.None then
            scripts.Bag.RollBackWithChange(bag_change_log)
            return context.S2C(context.net_id, CmdCode.PBRankGetRewardRspCmd,
                { code = bag_err_code, error = "添加货币失败", uid = context.uid }, req.msg_context.stub_id)
        end
    end

    local rsp_msg = {
        code = ErrorCode.None,
        error = "",
        uid = context.uid,
        success = true,
        reward = reward_cfg,
    }

    scripts.Bag.SaveAndLog(bag_change_log, ItemDef.ChangeReason.RankReward)
    return context.S2C(context.net_id, CmdCode.PBRankGetRewardRspCmd, rsp_msg, req.msg_context.stub_id)
end

-- 处理玩家上榜
function Rank.UpdatePlayerRank(rank_type, player_data, force)
    player_data.uid = context.uid
    local rank_addr = moon.queryservice("rank")
    if rank_addr == 0 then
        moon.error("Cannot find rank service")
        return ErrorCode.ServerInternalError
    end
    return moon.call("lua", rank_addr, "handlePlayerRankUpdate", rank_type, context.uid, player_data, force)
end

-- 段位榜更新
function Rank.UpdateRank_Duanwei(duanwei_level)
    local battle_info = getPlayerBattleInfo()
    local player_data = {
        name = scripts.UserModel.GetUserAttr().nick_name,
        avatar = scripts.UserModel.GetUserAttr().head_icon,
        af = scripts.UserModel.GetUserAttr().head_frame,
        gn = scripts.UserModel.GetUserAttr().guild_name or "",
        gid = scripts.UserModel.GetUserAttr().guild_id or 0,
        value = duanwei_level,
        ed = {
            d = duanwei_level, -- duanwei
        },
        chr = battle_info.chr,
        chs = battle_info.chs,
        gho = battle_info.gho,
        ghs = battle_info.ghs,
    }
    -- 更新周段位榜和赛季段位榜
    Rank.UpdatePlayerRank(RankDef.RankType.Duanwei_Weekly, player_data)
    return Rank.UpdatePlayerRank(RankDef.RankType.Duanwei_Season, player_data)
end

-- 主线榜更新
function Rank.UpdateRank_Mainline(chapterid, difficulty, clear_time)
    local battle_info = getPlayerBattleInfo()
    local player_data = {
        name = scripts.UserModel.GetUserAttr().nick_name,
        avatar = scripts.UserModel.GetUserAttr().head_icon,
        af = scripts.UserModel.GetUserAttr().head_frame,
        gn = scripts.UserModel.GetUserAttr().guild_name or "",
        gid = scripts.UserModel.GetUserAttr().guild_id or 0,
        value = difficulty * 1000000 + (1000000 - clear_time), -- 难度优先级高于时间
        ed = {
            cid = chapterid, -- chapterid
            df = difficulty, -- difficulty
            ct = clear_time, -- clear_time
        },
        chr = battle_info.chr,
        chs = battle_info.chs,
        gho = battle_info.gho,
        ghs = battle_info.ghs,
    }
    return Rank.UpdatePlayerRank(RankDef.RankType.Mainline, player_data)
end

-- 封塔榜更新
function Rank.UpdateRank_Fengta(chapterid, difficulty, clear_time)
    local battle_info = getPlayerBattleInfo()
    local player_data = {
        name = scripts.UserModel.GetUserAttr().nick_name,
        avatar = scripts.UserModel.GetUserAttr().head_icon,
        af = scripts.UserModel.GetUserAttr().head_frame,
        gn = scripts.UserModel.GetUserAttr().guild_name or "",
        gid = scripts.UserModel.GetUserAttr().guild_id or 0,
        value = difficulty * 1000000 + (1000000 - clear_time), -- 难度优先级高于时间
        ed = {
            cid = chapterid, -- chapterid
            df = difficulty, -- difficulty
            ct = clear_time, -- clear_time
        },
        chr = battle_info.chr,
        chs = battle_info.chs,
        gho = battle_info.gho,
        ghs = battle_info.ghs,
    }
    return Rank.UpdatePlayerRank(RankDef.RankType.Fengta, player_data)
end

-- 发电榜更新
function Rank.UpdateRank_Fadian(week_bill_amount, month_bill_amount, total_bill_amount)
    local battle_info = getPlayerBattleInfo()
    local player_data = {
        name = scripts.UserModel.GetUserAttr().nick_name,
        avatar = scripts.UserModel.GetUserAttr().head_icon,
        af = scripts.UserModel.GetUserAttr().head_frame,
        gn = scripts.UserModel.GetUserAttr().guild_name or "",
        gid = scripts.UserModel.GetUserAttr().guild_id or 0,
        chr = battle_info.chr,
        chs = battle_info.chs,
        gho = battle_info.gho,
        ghs = battle_info.ghs,
    }

    -- 更新发电周榜、月榜、总榜
    player_data.value = week_bill_amount
    player_data.ed = {
        w = week_bill_amount, -- week_bill_amount
    }
    Rank.UpdatePlayerRank(RankDef.RankType.Fadian_Weekly, player_data)

    player_data.value = month_bill_amount
    player_data.ed = {}
    player_data.ed = {
        m = month_bill_amount, -- month_bill_amount
    }
    Rank.UpdatePlayerRank(RankDef.RankType.Fadian_Monthly, player_data)

    player_data.value = total_bill_amount
    player_data.ed = {}
    player_data.ed = {
        t = total_bill_amount, -- total_bill_amount
    }
    Rank.UpdatePlayerRank(RankDef.RankType.Fadian_Total, player_data)
end

-- 玩家榜更新
function Rank.UpdateRank_Player(level)
    local battle_info = getPlayerBattleInfo()
    local player_data = {
        name = scripts.UserModel.GetUserAttr().nick_name,
        avatar = scripts.UserModel.GetUserAttr().head_icon,
        af = scripts.UserModel.GetUserAttr().head_frame,
        gn = scripts.UserModel.GetUserAttr().guild_name or "",
        gid = scripts.UserModel.GetUserAttr().guild_id or 0,
        value = level,
        ed = {
            l = level, -- level
        },
        chr = battle_info.chr,
        chs = battle_info.chs,
        gho = battle_info.gho,
        ghs = battle_info.ghs,
    }
    return Rank.UpdatePlayerRank(RankDef.RankType.Player, player_data)
end

-- 角色榜更新
function Rank.UpdateRank_Role(role_id, role_level, role_skin)
    local player_data = {
        name = scripts.UserModel.GetUserAttr().nick_name,
        avatar = scripts.UserModel.GetUserAttr().head_icon,
        af = scripts.UserModel.GetUserAttr().head_frame,
        gn = scripts.UserModel.GetUserAttr().guild_name or "",
        gid = scripts.UserModel.GetUserAttr().guild_id or 0,
        value = role_level,
        ed = {
            rid = role_id,     -- role_id
            rl = role_level,   -- role_level
            rs = role_skin,    -- role_skin
        },
    }
    return Rank.UpdatePlayerRank(RankDef.RankType.Role, player_data)
end

-- 古董榜更新
function Rank.UpdateRank_Antique(antique_id, value)
    local player_data = {
        name = scripts.UserModel.GetUserAttr().nick_name,
        avatar = scripts.UserModel.GetUserAttr().head_icon,
        af = scripts.UserModel.GetUserAttr().head_frame,
        gn = scripts.UserModel.GetUserAttr().guild_name or "",
        gid = scripts.UserModel.GetUserAttr().guild_id or 0,
        value = value,
        ed = {
            aid = antique_id, -- antique_id
            v = value,       -- value
        },
    }
    return Rank.UpdatePlayerRank(RankDef.RankType.Antique, player_data)
end

-- 获取宗主信息（名称、出战角色、出战鬼怪）
local function getGuildLeaderInfo()
    local user_attr = scripts.UserModel.GetUserAttr()
    local guild_info = user_attr.guild_info or {}
    local leader_info = guild_info.leader_info or {}

    local leader_show_role = leader_info.cur_show_role or {}
    local leader_show_ghost = leader_info.cur_show_ghost or {}

    -- 获取宗主角色所有穿戴的皮肤（map转数组）
    local leader_skins = {}
    if leader_show_role.skins then
        for _, skin_id in pairs(leader_show_role.skins) do
            table.insert(leader_skins, skin_id)
        end
    end

    return {
        gl = leader_info.name or "",                           -- 宗主名称
        gl_chr = leader_show_role.config_id or 0,              -- 宗主出战角色配置ID
        gl_chs = leader_skins,                                 -- 宗主出战角色时装（数组）
        gl_gho = leader_show_ghost.config_id or 0,            -- 宗主出战鬼怪配置ID
        gl_ghs = leader_show_ghost.skin_id or 0,              -- 宗主出战鬼怪时装
    }
end

-- 宗门活跃榜更新
function Rank.UpdateRank_GuildActive(active_value)
    --local leader_info = getGuildLeaderInfo()
    local player_data = {
        name = scripts.UserModel.GetUserAttr().guild_name or "",
        avatar = 0,  -- 宗门没有头像，使用默认值
        af = 0,
        gn = scripts.UserModel.GetUserAttr().guild_name or "",
        gid = scripts.UserModel.GetUserAttr().guild_id or 0,
        value = active_value,
        ed = {
            a = active_value, -- active_value
        },
        -- 宗主信息
        --gl = leader_info.gl,
        --gl_chr = leader_info.gl_chr,
        --gl_chs = leader_info.gl_chs,
        --gl_gho = leader_info.gl_gho,
        --gl_ghs = leader_info.gl_ghs,
    }
    return Rank.UpdatePlayerRank(RankDef.RankType.GuildActive, player_data)
end

-- 宗门资金榜更新
function Rank.UpdateRank_GuildMoney(money_value)
    --local leader_info = getGuildLeaderInfo()
    local player_data = {
        name = scripts.UserModel.GetUserAttr().guild_name or "",
        avatar = 0,  -- 宗门没有头像，使用默认值
        af = 0,
        gn = scripts.UserModel.GetUserAttr().guild_name or "",
        gid = scripts.UserModel.GetUserAttr().guild_id or 0,
        value = money_value,
        ed = {
            m = money_value, -- money_value
        },
        -- 宗主信息
        --gl = leader_info.gl,
        --gl_chr = leader_info.gl_chr,
        --gl_chs = leader_info.gl_chs,
        --gl_gho = leader_info.gl_gho,
        --gl_ghs = leader_info.gl_ghs,
    }
    return Rank.UpdatePlayerRank(RankDef.RankType.GuildMoney, player_data)
end

-- 宗门积分榜更新（周榜和赛季榜）
function Rank.UpdateRank_GuildScore(score_value)
    --local leader_info = getGuildLeaderInfo()
    local player_data = {
        name = scripts.UserModel.GetUserAttr().guild_name or "",
        avatar = 0,  -- 宗门没有头像，使用默认值
        af = 0,
        gn = scripts.UserModel.GetUserAttr().guild_name or "",
        gid = scripts.UserModel.GetUserAttr().guild_id or 0,
        value = score_value,
        ed = {
            s = score_value, -- score_value
        },
        -- 宗主信息
        --gl = leader_info.gl,
        --gl_chr = leader_info.gl_chr,
        --gl_chs = leader_info.gl_chs,
        --gl_gho = leader_info.gl_gho,
        --gl_ghs = leader_info.gl_ghs,
    }
    -- 更新宗门积分周榜和赛季榜
    Rank.UpdatePlayerRank(RankDef.RankType.GuildScore_Weekly, player_data)
    return Rank.UpdatePlayerRank(RankDef.RankType.GuildScore_Season, player_data)
end

-- 段位榜更新请求处理
function Rank.PBRankUpdateDuanweiReqCmd(req)
    local duanwei = req.msg.duanwei
    if not duanwei then
        return context.S2C(context.net_id, CmdCode.PBRankUpdateDuanweiRspCmd, {
            code = ErrorCode.ParamInvalid,
            error = "无效的请求参数",
            uid = context.uid,
        }, req.msg_context.stub_id)
    end
    local code = Rank.UpdateRank_Duanwei(duanwei)
    return context.S2C(context.net_id, CmdCode.PBRankUpdateDuanweiRspCmd, {
        code = code,
        error = code == ErrorCode.None and "" or "更新失败",
        uid = context.uid,
        success = code == ErrorCode.None,
    }, req.msg_context.stub_id)
end

-- 主线榜更新请求处理
function Rank.PBRankUpdateMainlineReqCmd(req)
    local chapterid = req.msg.character_id
    local difficulty difficulty = req.msg.difficulty
    local clear_time = req.msg.clear_time
    if not chapterid or not difficulty or not clear_time then
        return context.S2C(context.net_id, CmdCode.PBRankUpdateMainlineRspCmd, {
            code = ErrorCode.ParamInvalid,
            error = "无效的请求参数",
            uid = context.uid,
        }, req.msg_context.stub_id)
    end
    local code = Rank.UpdateRank_Mainline(chapterid, difficulty, clear_time)
    return context.S2C(context.net_id, CmdCode.PBRankUpdateMainlineRspCmd, {
        code = code,
        error = code == ErrorCode.None and "" or "更新失败",
        uid = context.uid,
        success = code == ErrorCode.None,
    }, req.msg_context.stub_id)
end

-- 封塔榜更新请求处理
function Rank.PBRankUpdateFengtaReqCmd(req)
    local chapterid = req.msg.character_id
    local difficulty = req.msg.difficulty
    local clear_time = req.msg.clear_time
    if not chapterid or not difficulty or not clear_time then
        return context.S2C(context.net_id, CmdCode.PBRankUpdateFengtaRspCmd, {
            code = ErrorCode.ParamInvalid,
            error = "无效的请求参数",
            uid = context.uid,
        }, req.msg_context.stub_id)
    end
    local code = Rank.UpdateRank_Fengta(chapterid, difficulty, clear_time)
    return context.S2C(context.net_id, CmdCode.PBRankUpdateFengtaRspCmd, {
        code = code,
        error = code == ErrorCode.None and "" or "更新失败",
        uid = context.uid,
        success = code == ErrorCode.None,
    }, req.msg_context.stub_id)
end

-- 发电榜更新请求处理
function Rank.PBRankUpdateFadianReqCmd(req)
    local week_bill_amount = req.msg.week_bill_amount
    local month_bill_amount = req.msg.month_bill_amount
    local total_bill_amount = req.msg.total_bill_amount
    if week_bill_amount < 0 or month_bill_amount < 0 or total_bill_amount < 0 then
        return context.S2C(context.net_id, CmdCode.PBRankUpdateFadianRspCmd, {
            code = ErrorCode.ParamInvalid,
            error = "无效的请求参数",
            uid = context.uid,
        }, req.msg_context.stub_id)
    end
    local code = Rank.UpdateRank_Fadian(week_bill_amount, month_bill_amount, total_bill_amount)
    return context.S2C(context.net_id, CmdCode.PBRankUpdateFadianRspCmd, {
        code = code,
        error = code == ErrorCode.None and "" or "更新失败",
        uid = context.uid,
        success = code == ErrorCode.None,
    }, req.msg_context.stub_id)
end

-- 玩家榜更新请求处理
function Rank.PBRankUpdatePlayerReqCmd(req)
    local level = req.msg.level
    if not level then
        return context.S2C(context.net_id, CmdCode.PBRankUpdatePlayerRspCmd, {
            code = ErrorCode.ParamInvalid,
            error = "无效的请求参数",
            uid = context.uid,
        }, req.msg_context.stub_id)
    end
    local code = Rank.UpdateRank_Player(level)
    return context.S2C(context.net_id, CmdCode.PBRankUpdatePlayerRspCmd, {
        code = code,
        error = code == ErrorCode.None and "" or "更新失败",
        uid = context.uid,
        success = code == ErrorCode.None,
    }, req.msg_context.stub_id)
end

-- 角色榜更新请求处理
function Rank.PBRankUpdateRoleReqCmd(req)
    local role_id = req.msg.role_id
    local role_level = req.msg.role_level
    local role_skin = req.msg.role_skin
    if not role_id or not role_level then
        return context.S2C(context.net_id, CmdCode.PBRankUpdateRoleRspCmd, {
            code = ErrorCode.ParamInvalid,
            error = "无效的请求参数",
            uid = context.uid,
        }, req.msg_context.stub_id)
    end
    local code = Rank.UpdateRank_Role(role_id, role_level, role_skin)
    return context.S2C(context.net_id, CmdCode.PBRankUpdateRoleRspCmd, {
        code = code,
        error = code == ErrorCode.None and "" or "更新失败",
        uid = context.uid,
        success = code == ErrorCode.None,
    }, req.msg_context.stub_id)
end

-- 古董榜更新请求处理
function Rank.PBRankUpdateAntiqueReqCmd(req)
    local antique_id = req.msg.antique_id
    local value = req.msg.value
    if not antique_id or not value then
        return context.S2C(context.net_id, CmdCode.PBRankUpdateAntiqueRspCmd, {
            code = ErrorCode.ParamInvalid,
            error = "无效的请求参数",
            uid = context.uid,
        }, req.msg_context.stub_id)
    end
    local code = Rank.UpdateRank_Antique(antique_id, value)
    return context.S2C(context.net_id, CmdCode.PBRankUpdateAntiqueRspCmd, {
        code = code,
        error = code == ErrorCode.None and "" or "更新失败",
        uid = context.uid,
        success = code == ErrorCode.None,
    }, req.msg_context.stub_id)
end

return Rank
