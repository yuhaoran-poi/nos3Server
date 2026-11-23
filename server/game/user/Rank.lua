--require("common.LuaPanda").start("127.0.0.1", 8818)
local moon = require "moon"
local common = require "common"
local clusterd = require("cluster")
local ErrorCode = common.ErrorCode
local CmdCode = common.CmdCode
local RankDef = require "common.def.RankDef"
local GameCfg = common.GameCfg
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
    -- 旧榜登录预热已删除(旧14榜下线); 新三榜为服务端结算触发, 无需登录初始化
end

-- (getGuildInfo 与 AssignPlayerToAllRanks 已删除: 旧14榜下线, 无登录预热需求)

-- 获取排行榜数据
function Rank.PBRankGetInfoReqCmd(req)
    local rank_type = req.msg.rank_type
    local rank_id = req.msg.rank_id
    local query_uid = req.msg.uid

    if not rank_type then
        return context.S2C(context.net_id, CmdCode.PBRankGetInfoRspCmd, {
            code = ErrorCode.ParamInvalid,
            error = "无效的请求参数",
            uid = query_uid,
        }, req.msg_context.stub_id)
    end

    -- 调用排行榜服务获取数据
    local err, rank_data = clusterd.call(3004, "rank", "RankMgr.GetRankInfo", {rank_type = rank_type, rank_id = rank_id, uid = query_uid})
    if err ~= ErrorCode.None then
        moon.info("Failed to get rank data: uid=%d type=%d err=%s nowtime:%d", query_uid, rank_type, err, moon.time())
        return context.S2C(context.net_id, CmdCode.PBRankGetInfoRspCmd, {
            code = ErrorCode.ServerInternalError,
            error = "获取排行榜数据失败",
            uid = query_uid,
        }, req.msg_context.stub_id)
    end

    if not rank_data or type(rank_data) ~= "table" then
        -- 玩家不在该排行榜中属于正常情况（如宗门榜未收录、古董榜无数据等），返回成功+空数据
        return context.S2C(context.net_id, CmdCode.PBRankGetInfoRspCmd, {
            code = ErrorCode.None,
            error = "",
            uid = query_uid,
            rank_data = {},
        }, req.msg_context.stub_id)
    end

    -- 检查是否是玩家数据（包含 sub_rank_id 字段）
    -- GetRankInfo 返回：单个玩家对象 或 玩家对象数组 或 排行榜数据
    local is_player_data = false
    local player_info = nil

    if rank_data.sub_rank_id then
        -- 单个玩家对象
        is_player_data = true
        player_info = rank_data
    elseif rank_data[1] and rank_data[1].sub_rank_id then
        -- 玩家对象数组
        is_player_data = true
        player_info = rank_data[1]
    end

    local rsp_msg
    if is_player_data and player_info then
        -- 玩家数据，构建为排行榜格式
        rsp_msg = {
            code = ErrorCode.None,
            error = "",
            uid = query_uid,
            rank_data = {
                {
                    rank_id = player_info.sub_rank_id or 0,
                    rank_type = player_info.rank_type or 0,
                    is_flow = player_info.is_flow or false,
                    rank_items = {player_info},
                    create_time = player_info.create_time or 0,
                    last_refresh_time = player_info.last_refresh_time or 0,
                }
            },
        }
    else
        -- 完整的排行榜数据
        rsp_msg = {
            code = ErrorCode.None,
            error = "",
            uid = query_uid,
            rank_data = rank_data,
        }
    end

    return context.S2C(context.net_id, CmdCode.PBRankGetInfoRspCmd, rsp_msg, req.msg_context.stub_id)
end

-- 获取所有排行榜类型
function Rank.PBRankGetAllTypesReqCmd(req)
    -- 调用排行榜服务获取所有类型
    local err, types_data = clusterd.call(3004, "rank", "RankMgr.GetAllRankTypes", {})
    if err ~= ErrorCode.None then
        moon.error("Failed to get all rank types:", err)
        return context.S2C(context.net_id, CmdCode.PBRankGetAllTypesRspCmd, {
            code = ErrorCode.ServerInternalError,
            error = "获取排行榜类型失败",
            uid = context.uid,
        }, req.msg_context.stub_id)
    end

    -- 构建响应
    local rsp_msg = {
        code = ErrorCode.None,
        error = "",
        uid = context.uid,
        types = types_data,
    }

    return context.S2C(context.net_id, CmdCode.PBRankGetAllTypesRspCmd, rsp_msg, req.msg_context.stub_id)
end

-- (旧单榜两段式领奖的确认/取消函数已删除, 新三榜见下方 confirmBoardRewardClaim/cancelBoardRewardClaim)

-- 领取排行榜奖励(新三榜: 按一级标签聚合领奖, 取该标签下全部子榜最优名次档位)
function Rank.PBRankGetRewardReqCmd(req)
    local category = req.msg.category or 0
    if category <= 0 then
        return context.S2C(context.net_id, CmdCode.PBRankGetRewardRspCmd, {
            code = ErrorCode.ParamInvalid,
            error = "无效的请求参数",
            uid = context.uid,
            category = category,
        }, req.msg_context.stub_id)
    end
    return Rank.BoardRewardClaim(req, category)
end

-- 处理玩家上榜
function Rank.UpdatePlayerRank(rank_type, player_data, force)
    player_data.id = player_data.id or context.uid
    player_data.uid = player_data.id
    local result, err = clusterd.call(3004, "rank", "RankMgr.handlePlayerRankUpdate", {rank_type = rank_type, uid = player_data.id, player_data = player_data, force = force})
    if result == nil then
        moon.error("Failed to update player rank:", err)
        return ErrorCode.ServerInternalError
    end
    return result
end

-- (旧榜上报函数已删除: 段位/主线/封塔/发电/玩家/角色/古董/宗门 旧14榜已下线,
--  上游调用点同步注释; 新三榜上报入口见文件末尾 OnGhostKingSettle/OnBootyExtracted/OnAntiqueAppraised)

-- (发电/玩家/角色/古董旧榜上报函数已删除)

-- (宗门榜上报函数与宗主信息获取已删除: 宗门四榜已下线且原本就无调用方)

--[[
旧榜客户端直报协议已停用(2026-11 新三榜改造):
新三榜(鬼王竞速/摸金/古董)为服务端结算权威上报(见下方 OnGhostKingSettle/OnBootyExtracted/OnAntiqueAppraised),
旧14榜在 RankLogic 入口已屏蔽; 原PBRankUpdateXxxReqCmd×7处理函数整体注释保留备查,
对应proto消息已从 rank.proto 删除。

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
    local difficulty = req.msg.difficulty
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
    local role_id = req.msg.roleid
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
]]

--===========================================================================
-- 新三榜(鬼王竞速/摸金/古董): 服务端结算权威上报
-- 榜实例与合并方式由 static/table/RankBoard.lua 配置, 此处只负责条件过滤与取数
--===========================================================================

local function build_board_player_data(value, ed)
    local user_attr = scripts.UserModel.GetUserAttr()
    local battle_info = getPlayerBattleInfo()
    return {
        name = user_attr.nick_name,
        avatar = user_attr.head_icon,
        af = user_attr.head_frame,
        gn = user_attr.guild_name or "",
        gid = user_attr.guild_id or 0,
        value = value,
        ed = ed,
        chr = battle_info.chr,
        chs = battle_info.chs,
        gho = battle_info.gho,
        ghs = battle_info.ghs,
    }
end

-- 按(标签, 子榜, 窗口)找榜实例上报; RankBoard未注册(清单外鬼王/古董)静默跳过
local function update_board(category, sub_id, window, value, ed)
    local boards = GameCfg.RankBoard
    if not boards then
        return
    end
    for rank_type, cfg in pairs(boards) do
        if cfg.category == category and cfg.sub_id == sub_id and cfg.window == window then
            Rank.UpdatePlayerRank(rank_type, build_board_player_data(value, ed))
            return
        end
    end
end

--- 鬼王竞速榜入口(Room.GameSettle 鬼王章节分支调用)
--- 口径: 地狱难度(5)+带词条通关, 周榜+总榜各取最好一次(merge=max)
--- 鬼王ID来自 DS 结算 ghost_king_kills(map: 鬼王id->击杀次数, 方案C), 同局击杀多只鬼王时每只各上各榜
--- 词条难度分 = Σ AllTag[tag].tagscore(词条品质分1~7, maxtag=5封顶35分)
--- 排序口径: 难度分降序 → 用时升序, 编码为单值:
---   value = 难度分 × 1e7 + (1e7 - 用时秒)   (难度分1~35, 用时<1e7秒, int64安全)
---   value 完全相等(=难度分和用时都相同, 秒级)即并列
function Rank.OnGhostKingSettle(chapter_id, clear_time, ghost_king_kills, mode_tags)
    if not clear_time or clear_time <= 0 then
        return
    end
    if not ghost_king_kills or table.size(ghost_king_kills) == 0 then
        return
    end
    if not mode_tags or table.size(mode_tags) == 0 then
        return -- 未开词条的对局不计入竞速榜
    end

    -- 词条难度分求和(查不到配置的词条按0分计)
    local tag_score = 0
    for _, tag_id in pairs(mode_tags) do
        local tag_cfg = GameCfg.AllTag[tag_id]
        if tag_cfg and tag_cfg.tagscore then
            tag_score = tag_score + tag_cfg.tagscore
        end
    end

    local value = tag_score * 10000000 + (10000000 - clear_time)
    for ghost_id, _kill_cnt in pairs(ghost_king_kills) do
        -- 次数不影响竞速口径(只比最快通关), 每只鬼王独立成榜
        local ed = {
            cid = chapter_id, gkid = ghost_id, df = 5,
            ct = clear_time, ts = tag_score,
            tags = table.concat(mode_tags, ","), -- 逗号串(extra_data逐字段tostring, 数组不可直接放)
        }
        update_board(RankDef.Category.SPEED, ghost_id, RankDef.WindowType.WEEKLY, value, ed)
        update_board(RankDef.Category.SPEED, ghost_id, RankDef.WindowType.SEASON, value, ed)
    end
end

--- 摸金榜入口(Room.GameSettle 成功带出分支调用)
--- 口径: 任意模式通关或撤离成功带出的战利品估值(booty_value), 周榜+总榜累加(merge=sum)
--- 死亡/撤退失败不带出(调用侧已过滤); "被截走"无服务端字段, 归入不带出
function Rank.OnBootyExtracted(booty_value)
    if not booty_value or booty_value <= 0 then
        return
    end
    update_board(RankDef.Category.GOLD, 0, RankDef.WindowType.WEEKLY, booty_value, { v = booty_value })
    update_board(RankDef.Category.GOLD, 0, RankDef.WindowType.SEASON, booty_value, { v = booty_value })
end

--- 古董榜入口(AntiqueShowcase.IdentifyAntique 鉴定完成处调用)
--- 口径: 红古董(quality=5)鉴定次数用尽且为真的价值, 周榜+总榜取最高(merge=max, 同款多件取最高一件天然成立)
function Rank.OnAntiqueAppraised(antique_id, price)
    if not antique_id or not price or price <= 0 then
        return
    end
    update_board(RankDef.Category.ANTIQUE, antique_id, RankDef.WindowType.WEEKLY, price, { aid = antique_id, v = price })
    update_board(RankDef.Category.ANTIQUE, antique_id, RankDef.WindowType.SEASON, price, { aid = antique_id, v = price })
end

--===========================================================================
-- 新三榜: 聚合领奖(两段式)与上期锁榜排名查询
--===========================================================================

local function confirmBoardRewardClaim(category, uid)
    local ok, err = pcall(clusterd.call, 3004, "rank", "RankMgr.ConfirmBoardReward", {
        category = category,
        uid = uid,
    })
    if not ok then
        -- 确认失败仅记录日志(快照残留可重新领取), 不影响已入包的奖励
        moon.error(string.format("[Rank] ConfirmBoardReward failed: uid=%d, category=%d, err=%s", uid, category, tostring(err)))
    end
end

local function cancelBoardRewardClaim(category, uid)
    local ok, err = pcall(clusterd.call, 3004, "rank", "RankMgr.CancelBoardRewardClaim", {
        category = category,
        uid = uid,
    })
    if not ok then
        moon.error(string.format("[Rank] CancelBoardRewardClaim failed: uid=%d, category=%d, err=%s", uid, category, tostring(err)))
    end
end

-- 新三榜聚合领奖: 直接进背包不走邮件; 同标签多子榜取最高名次档位只发一次
function Rank.BoardRewardClaim(req, category)
    local err, reward_pool_cfg, best_info = clusterd.call(3004, "rank", "RankMgr.GetBoardReward", {
        category = category,
        uid = context.uid,
    })
    if err ~= ErrorCode.None then
        local err_msg = (err == ErrorCode.RankRewardNotExist) and "未上榜或已领取" or "领取奖励失败"
        return context.S2C(context.net_id, CmdCode.PBRankGetRewardRspCmd, {
            code = err,
            error = err_msg,
            uid = context.uid,
            category = category,
        }, req.msg_context.stub_id)
    end

    -- 发放奖励(与旧领奖同一入包管线)
    local add_items = {}
    for item_id, item_cnt in pairs(reward_pool_cfg or {}) do
        if not add_items[item_id] then
            add_items[item_id] = { id = item_id, count = 0, pos = 0 }
        end
        add_items[item_id].count = add_items[item_id].count + item_cnt
    end

    local stack_items, unstack_items, deal_coins = {}, {}, {}
    if table.size(add_items) > 0 then
        local ok = ItemDefine.GetItemDataFromIdCount(add_items, {}, stack_items, unstack_items, deal_coins)
        if not ok then
            cancelBoardRewardClaim(category, context.uid)
            return context.S2C(context.net_id, CmdCode.PBRankGetRewardRspCmd, {
                code = ErrorCode.ConfigError,
                error = "排行榜奖励配置不存在",
                uid = context.uid,
                category = category,
            }, req.msg_context.stub_id)
        end
    end
    -- CheckEmptyEnough 期望 {id,count,pos} 简单结构(同 Bag.lua:3724 用法), 不能传 GetItemDataFromIdCount
    -- 的输出(ItemData结构, 数量在common_info.item_count, 顶层无count字段, 只读表读count必抛错);
    -- 货币(≤999)不占背包格, 从容量检查中排除
    local bag_check_items = {}
    for item_id, v in pairs(add_items) do
        if ItemDefine.GetItemPosType(item_id) ~= ItemDefine.EItemBigType.Coin then
            bag_check_items[item_id] = v
        end
    end
    local bag_err_code = scripts.Bag.CheckEmptyEnough(BagDef.BagType.Cangku, bag_check_items, table.size(unstack_items))
    if bag_err_code ~= ErrorCode.None then
        cancelBoardRewardClaim(category, context.uid)
        return context.S2C(context.net_id, CmdCode.PBRankGetRewardRspCmd, {
            code = bag_err_code,
            error = "背包空间不足",
            uid = context.uid,
            category = category,
        }, req.msg_context.stub_id)
    end
    local bag_change_log = {}
    if table.size(stack_items) + table.size(unstack_items) > 0 then
        bag_err_code = scripts.Bag.AddItems(BagDef.BagType.Cangku, stack_items, unstack_items, bag_change_log)
        if bag_err_code ~= ErrorCode.None then
            scripts.Bag.RollBackWithChange(bag_change_log)
            cancelBoardRewardClaim(category, context.uid)
            return context.S2C(context.net_id, CmdCode.PBRankGetRewardRspCmd, {
                code = bag_err_code,
                error = "背包空间不足",
                uid = context.uid,
                category = category,
            }, req.msg_context.stub_id)
        end
    end
    if table.size(deal_coins) > 0 then
        bag_err_code = scripts.Bag.DealCoins(deal_coins, bag_change_log)
        if bag_err_code ~= ErrorCode.None then
            scripts.Bag.RollBackWithChange(bag_change_log)
            cancelBoardRewardClaim(category, context.uid)
            return context.S2C(context.net_id, CmdCode.PBRankGetRewardRspCmd, {
                code = bag_err_code,
                error = "添加货币失败",
                uid = context.uid,
                category = category,
            }, req.msg_context.stub_id)
        end
    end

    confirmBoardRewardClaim(category, context.uid)

    local reward_data = {}
    for item_id, item_cnt in pairs(reward_pool_cfg or {}) do
        table.insert(reward_data, { item_id = item_id, count = item_cnt, type = "item" })
    end

    scripts.Bag.SaveAndLog(bag_change_log, ItemDef.ChangeReason.RankReward)
    return context.S2C(context.net_id, CmdCode.PBRankGetRewardRspCmd, {
        code = ErrorCode.None,
        error = "",
        uid = context.uid,
        success = true,
        reward = reward_data,
        category = category,
        best_rank = (best_info and best_info.rank) or 0,
    }, req.msg_context.stub_id)
end

-- 新三榜: 查询上期锁榜排名(领奖弹窗展示"上周排名"; 领取后返回空)
function Rank.PBRankGetBoardHistoryReqCmd(req)
    local category = req.msg.category or 0
    local err, items = clusterd.call(3004, "rank", "RankMgr.GetBoardHistory", {
        category = category,
        uid = context.uid,
    })
    if err ~= ErrorCode.None then
        return context.S2C(context.net_id, CmdCode.PBRankGetBoardHistoryRspCmd, {
            code = err,
            error = "查询失败",
            uid = context.uid,
            category = category,
        }, req.msg_context.stub_id)
    end
    return context.S2C(context.net_id, CmdCode.PBRankGetBoardHistoryRspCmd, {
        code = ErrorCode.None,
        error = "",
        uid = context.uid,
        category = category,
        items = items or {},
    }, req.msg_context.stub_id)
end

-- 测试命令(仅测试环境): 直接驱动新三榜上报入口(与Room.GameSettle/AntiqueShowcase挂点同一函数) / 触发榜期刷新
function Rank.PBTestRankBoardSettleReqCmd(req)
    local kind = req.msg.kind or 0
    local times = tonumber(req.msg.times) or 1
    if times < 1 then times = 1 end
    if times > 100 then times = 100 end
    local applied = 0

    if kind == 1 then
        -- kind=1: 竞速, sub_id=鬼王ID(与RankBoard竞速行sub_id同源), tags=本局词条(默认{3000007}, 空=未开词条不上榜)
        -- 注: proto3的int32缺省解码为0而非nil, 默认值需显式判0
        local tags = req.msg.tags
        if tags == nil then
            tags = { 3000007 } -- 默认单词条7分, 兼容旧调用
        end
        local chapter_id = req.msg.chapter_id
        if not chapter_id or chapter_id == 0 then
            chapter_id = 2001
        end
        for _ = 1, times do
            Rank.OnGhostKingSettle(chapter_id, req.msg.clear_time or 300,
                { [req.msg.sub_id or 2011] = 1 }, tags)
            applied = applied + 1
        end
    elseif kind == 2 then
        for _ = 1, times do
            Rank.OnBootyExtracted(req.msg.value or 0)
            applied = applied + 1
        end
    elseif kind == 3 then
        for _ = 1, times do
            Rank.OnAntiqueAppraised(req.msg.sub_id or 625018, req.msg.value or 0)
            applied = applied + 1
        end
    elseif kind == 9 or kind == 10 then
        local window = (kind == 9) and 1 or 2
        local err = clusterd.call(3004, "rank", "RankMgr.TestRefreshRanks", { window = window })
        if err ~= ErrorCode.None then
            return context.S2C(context.net_id, CmdCode.PBTestRankBoardSettleRspCmd, {
                code = err, error = "刷新失败", uid = context.uid, applied = 0,
            }, req.msg_context.stub_id)
        end
        applied = 1
    elseif kind == 11 then
        local err = clusterd.call(3004, "rank", "RankMgr.TestClearBoards", {})
        if err ~= ErrorCode.None then
            return context.S2C(context.net_id, CmdCode.PBTestRankBoardSettleRspCmd, {
                code = err, error = "清榜失败", uid = context.uid, applied = 0,
            }, req.msg_context.stub_id)
        end
        applied = 1
    else
        return context.S2C(context.net_id, CmdCode.PBTestRankBoardSettleRspCmd, {
            code = ErrorCode.ParamInvalid, error = "无效kind", uid = context.uid, applied = 0,
        }, req.msg_context.stub_id)
    end

    moon.info(string.format("[Rank] test_settle uid=%s kind=%s applied=%s", tostring(context.uid), tostring(kind), tostring(applied)))
    return context.S2C(context.net_id, CmdCode.PBTestRankBoardSettleRspCmd, {
        code = ErrorCode.None, error = "", uid = context.uid, applied = applied,
    }, req.msg_context.stub_id)
end

return Rank