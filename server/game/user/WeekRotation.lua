--[[
周天轮转(门票流转) 活动模块
需求: 《驱灵天师》周天轮转(门票流转)系统策划案 V1.3 (2026-11-05)

要点:
- 3周轮换, 每周开启 1主线+1副模式 共2个活动, 周三06:00切换(案子P02, 原05:00已改06:00)
- 周期锚点 = 上线开启时间(策划表 WeekRotation.open_time, 约定填在7001行; 表未配置时功能整体不生效)
- 通关成功才计分(is_complete==1), 由 Room.GameSettle 调 OnSettleSuccess
- 5档宝箱/轮次7轮上限/幂等领奖(案子12章)
- 数据跨周自动重置, 重置前打日志留存供客服查询(案子2.9)

待接入(等策划/proto):
1. ✅ 已接入策划表 GameCfg.WeekRotation(static/table/WeekRotation.lua)
2. 协议消息已定义于 protocol/activity.proto(活动系统通用协议文件, 以后活动相关PB统一加在该文件),
   走联编流程重生成 CmdCode 后本模块处理器自动路由生效:
   PBGetWeekRotationInfoReqCmd/RspCmd  拉取活动信息 { uid }
   PBClaimWeekRotationTierReqCmd/RspCmd 领档 { uid, activity_id, tier, claim_all } claim_all=1为一键
   PBWeekRotationSyncCmd  服务端主动推送活动数据变化(积分/跨周重置)
   PBWeekRotationNotifyCmd 服务端推送提醒(结束前1小时)
   协议落地前推送静默跳过(rawget探测)
   注: 档位宝箱开启复用现有道具使用链路(PBUseItemReqCmd, 宝箱为use_type=6道具),
   掉落由策划在Item表配置, 本模块无开箱协议
3. 建表SQL见 WeekRotationDef.lua 头部注释
]]

local moon = require "moon"
local datetime = require "moon.datetime"
local common = require "common"
local ErrorCode = common.ErrorCode
local CmdCode = common.CmdCode
local Database = common.Database
local json = require "json"
local WeekRotationDef = require "common.def.WeekRotationDef"
local ItemDefine = require "common.logic.ItemDefine"
local BagDef = require "common.def.BagDef"
local ItemDef = require "common.def.ItemDef"

---@type user_context
local context = ...
local scripts = context.scripts

---@class WeekRotation
local WeekRotation = {}

local Config = WeekRotationDef.Config
local GameCfg = common.GameCfg

-- 策划表 GameCfg.WeekRotation 单行访问(字段: tier_scores/tier_rewards/rewards_id/chapterid/difficulty1~5/score1~5 等)
local function get_activity_cfg(act_id)
    local cfgs = GameCfg.WeekRotation
    return cfgs and cfgs[act_id] or nil
end

-- 轮换配对推导: cycle_week × activity_type → 每周 {main_id, sub_id}; 周期周数 = 最大cycle_week
local rotation_cache = nil
local function get_rotation()
    if rotation_cache then
        return rotation_cache
    end
    local cfgs = GameCfg.WeekRotation
    local weeks, cycle_weeks = {}, 0
    if cfgs then
        for act_id, cfg in pairs(cfgs) do
            local w = cfg.cycle_week or 0
            if w >= 1 then
                local slot = weeks[w]
                if not slot then
                    slot = { main_id = 0, sub_id = 0 }
                    weeks[w] = slot
                end
                if cfg.activity_type == WeekRotationDef.ActivityType.MAINLINE then
                    slot.main_id = act_id
                else
                    slot.sub_id = act_id
                end
                if w > cycle_weeks then
                    cycle_weeks = w
                end
            end
        end
    end
    rotation_cache = { weeks = weeks, cycle_weeks = cycle_weeks }
    return rotation_cache
end

-- 周期锚点(上线开启时间): 取策划表非零 open_time(约定只填在周期第1周主活动行, 如7001, 其余行留空),
-- 未配置(全0/缺列)时活动整体静默。⚠️ 上线后不可再改, 改动 = 全员周期错位触发一次数据重置
local function get_anchor_ts()
    local cfgs = GameCfg.WeekRotation
    if cfgs then
        for _, cfg in pairs(cfgs) do
            local t = cfg.open_time
            if t and t > 0 then
                return t
            end
        end
    end
    return 0
end

-- 档位数由配置 tier_scores 数组长度决定(当前5档, 跟随策划表)
local function get_tier_count(act_id)
    local cfg = get_activity_cfg(act_id)
    return (cfg and cfg.tier_scores) and #cfg.tier_scores or 0
end

local DAY_SECONDS <const> = 24 * 60 * 60
local WEEK_SECONDS <const> = 7 * DAY_SECONDS

--=====================================================================================
-- 周次计算
--=====================================================================================

-- 距离ts最近且<=ts的 周三SWITCH_OFFSET点 时间戳
local function cur_switch_ts(ts)
    local day_ts = datetime.dailytime(ts)
    local week_day = tonumber(os.date("%w", day_ts)) -- 0=周日 3=周三
    local back_days = (week_day - 3) % 7
    local switch_ts = day_ts - back_days * DAY_SECONDS + Config.SWITCH_HOUR_OFFSET
    if switch_ts > ts then
        switch_ts = switch_ts - WEEK_SECONDS
    end
    return switch_ts
end

-- 严格大于ts的下一个 周三SWITCH_OFFSET点
local function next_switch_ts(ts)
    return cur_switch_ts(ts) + WEEK_SECONDS
end

-- 上线日锚点之后的第一个周三切换点(上线日所在的第1周 = 锚点 ~ 该切换点)
local function first_boundary_ts()
    return next_switch_ts(get_anchor_ts())
end

--- 当前周状态
--- @return nil|table { cycle=全局周序号(0起), week_idx=周期内周次(1-3), main_id, sub_id, cur_start_ts, next_switch_ts }
local function get_week_state(now_ts)
    local anchor_ts = get_anchor_ts()
    if not anchor_ts or anchor_ts <= 0 then
        return nil -- 锚点未配置, 活动不开启
    end
    if now_ts < anchor_ts then
        return nil -- 未到上线日
    end

    local boundary = first_boundary_ts()
    local cycle
    if now_ts < boundary then
        cycle = 0 -- 第1周(上线日的不完整周)
    else
        cycle = 1 + math.floor((now_ts - boundary) / WEEK_SECONDS)
    end

    local rot = get_rotation()
    if rot.cycle_weeks <= 0 then
        moon.error("[week_rotation] GameCfg.WeekRotation empty")
        return nil
    end

    local week_idx = cycle % rot.cycle_weeks + 1
    local rotation = rot.weeks[week_idx]
    if not rotation or rotation.main_id <= 0 or rotation.sub_id <= 0 then
        moon.error("[week_rotation] rotation config missing, week_idx = ", week_idx)
        return nil
    end

    return {
        cycle = cycle,
        week_idx = week_idx,
        main_id = rotation.main_id,
        sub_id = rotation.sub_id,
        cur_start_ts = (cycle == 0) and anchor_ts or (boundary + (cycle - 1) * WEEK_SECONDS),
        next_switch_ts = (cycle == 0) and boundary or (boundary + cycle * WEEK_SECONDS),
    }
end

--=====================================================================================
-- 数据
--=====================================================================================

-- json落库重读后数字键会变字符串键, 统一归一化回数字键
local function normalize_loaded_data(data)
    if not data or not data.activities then
        return
    end
    local normalized = {}
    for act_key, act in pairs(data.activities) do
        local act_id = tonumber(act_key) or act.activity_id
        if act.claimed_tiers then
            local tiers = {}
            for tier_key, v in pairs(act.claimed_tiers) do
                local tier = tonumber(tier_key)
                if tier then
                    tiers[tier] = v
                end
            end
            act.claimed_tiers = tiers
        end
        act.activity_id = act_id
        act.score = act.score or 0
        act.round = act.round or 1
        act.locked = act.locked or 0
        normalized[act_id] = act
    end
    data.activities = normalized
    data.data_key = tonumber(data.data_key) or -1
    data.remind_key = data.remind_key or ""
end

function WeekRotation.Init()
    local week_rotation = WeekRotation.LoadData()
    if week_rotation then
        normalize_loaded_data(week_rotation)
        scripts.UserModel.SetWeekRotation(week_rotation)
    end

    local data = scripts.UserModel.GetWeekRotation()
    if not data then
        data = WeekRotationDef.newPlayerData()
        data.uid = context.uid
        scripts.UserModel.SetWeekRotation(data)
    end
end

function WeekRotation.Start()
    local data = scripts.UserModel.GetWeekRotation()
    if not data then
        return
    end

    -- 登录即校验跨周重置
    WeekRotation.EnsureRefresh()

    -- 在线周期巡检: 跨周重置/切换推送/结束前1小时提醒(案子12章)
    moon.async(function()
        while true do
            moon.sleep(60000) -- 60秒
            local ok, err = xpcall(WeekRotation.OnCycleCheck, debug.traceback)
            if not ok then
                moon.error("[week_rotation] OnCycleCheck err:\n", err)
            end
        end
    end)

    scripts.UserModel.AddDirtyModule("WeekRotation")
end

function WeekRotation.LoadData()
    local data, db_err = Database.loadweekrotation(context.addr_db_user, context.uid)
    if db_err then
        context.db_init_failed = db_err -- 查询失败: 置登录失败标记
    end
    return data
end

function WeekRotation.SaveNow()
    local data = scripts.UserModel.GetWeekRotation()
    if not data then
        return false
    end
    local success = Database.saveweekrotation(context.addr_db_user, context.uid, data)
    scripts.UserModel.RemoveDirtyModule("WeekRotation")
    return success
end

function WeekRotation.TimingSave()
    local data = scripts.UserModel.GetWeekRotation()
    if not data then
        return false
    end
    return Database.saveweekrotation(context.addr_db_user, context.uid, data)
end

--- 跨周重置校验(幂等): data_key != 当前cycle → 清空积分/轮次/领取状态
--- @return WeekRotationPlayerData
function WeekRotation.EnsureRefresh()
    local data = scripts.UserModel.GetWeekRotation()
    if not data then
        return nil, nil
    end
    local st = get_week_state(moon.time())
    if not st then
        return data, nil
    end
    if data.data_key ~= st.cycle then
        if data.data_key >= 0 and table.size(data.activities) > 0 then
            -- 历史数据留存(案子2.9): 重置前落日志供客服查询; 未领档位即奖励流失(埋点activity_leave)
            for act_id, act in pairs(data.activities) do
                local cfg = get_activity_cfg(act_id)
                local unclaimed = 0
                for tier = 1, get_tier_count(act_id) do
                    if not act.claimed_tiers[tier] and act.score >= (cfg and cfg.tier_scores[tier] or 0) then
                        unclaimed = unclaimed + 1
                    end
                end
                moon.info(string.format("[week_rotation] event=activity_leave uid=%s activity=%s round=%s score=%s unclaimed=%s",
                    tostring(context.uid), tostring(act_id), tostring(act.round), tostring(act.score), unclaimed))
            end
            moon.info(string.format("[week_rotation] reset uid=%s old_data_key=%s new_data_key=%s old=%s",
                tostring(context.uid), tostring(data.data_key), tostring(st.cycle), json.encode(data.activities)))
        end
        data.data_key = st.cycle
        data.activities = {}
        WeekRotation.SaveNow()
    end
    return data, st
end

-- 在线周期巡检(Start协程)
function WeekRotation.OnCycleCheck()
    local data = scripts.UserModel.GetWeekRotation()
    if not data then
        return
    end
    local now_ts = moon.time()
    local st = get_week_state(now_ts)
    if not st then
        return
    end

    -- 跨周: 重置 + 推送
    if data.data_key ~= st.cycle then
        WeekRotation.EnsureRefresh()
        WeekRotation.PushInfo()
        return
    end

    -- 结束前1小时提醒(当周只提醒一次, 案子8.11)
    local remind_key = tostring(st.cycle)
    if st.next_switch_ts - now_ts <= 3600 and st.next_switch_ts > now_ts and data.remind_key ~= remind_key then
        data.remind_key = remind_key
        WeekRotation.SaveNow()
        WeekRotation.PushNotify("ending_soon", st.next_switch_ts)
    end
end

--=====================================================================================
-- 积分
--=====================================================================================

-- 数组包含判断(不用table.indexof, 兼容sharetable代理)
local function array_contains(arr, v)
    for _, x in ipairs(arr) do
        if x == v then
            return true
        end
    end
    return false
end

-- 章节归属活动匹配: 当周活动 × chapterid列表包含(案子4); chapterid缺省时按bind_mode章节段降级全计并告警(案子12章)
local function match_activity(st, chapter_id)
    for _, act_id in ipairs({ st.main_id, st.sub_id }) do
        local cfg = get_activity_cfg(act_id)
        if cfg then
            local ids = cfg.chapterid
            if ids and #ids > 0 then
                if array_contains(ids, chapter_id) then
                    return act_id, cfg
                end
            else
                local range = WeekRotationDef.MODE_CHAPTER_RANGE[cfg.bind_mode]
                if range and chapter_id >= range[1] and chapter_id <= range[2] then
                    moon.error(string.format("[week_rotation] chapterid missing, activity=%s degrade to bind_mode range", tostring(act_id)))
                    return act_id, cfg
                end
            end
        end
    end
    return nil
end

-- 单把积分: 难度组 difficulty1~5/score1~5, difficulty落在组内取对应score(封魔塔difficulty=层数)
local function get_run_score(activity_id, difficulty)
    local cfg = get_activity_cfg(activity_id)
    if not cfg then
        return 0
    end
    for i = 1, 5 do
        local diffs = cfg["difficulty" .. i]
        if diffs and #diffs > 0 and array_contains(diffs, difficulty) then
            return cfg["score" .. i] or 0
        end
    end
    return 0
end

--- 结算成功计分入口(Room.GameSettle 在 is_complete==1 时调用)
function WeekRotation.OnSettleSuccess(chapter_id, difficulty)
    if not chapter_id or not difficulty then
        return
    end
    local data, st = WeekRotation.EnsureRefresh()
    if not data or not st then
        return
    end

    local act_id, cfg = match_activity(st, chapter_id)
    if not act_id then
        return
    end
    local score = get_run_score(act_id, difficulty)
    if score <= 0 then
        return
    end

    local act = data.activities[act_id]
    if not act then
        act = WeekRotationDef.newActivityData(act_id)
        data.activities[act_id] = act
    end
    if act.locked == 1 then
        return -- 已达轮次上限, 积分无意义不再累计
    end

    act.score = act.score + score
    scripts.UserModel.AddDirtyModule("WeekRotation")

    moon.info(string.format("[week_rotation] event=score_gain uid=%s activity=%s chapter=%s difficulty=%s score=%s total=%s round=%s",
        tostring(context.uid), tostring(act_id), tostring(chapter_id), tostring(difficulty),
        score, act.score, act.round))

    -- 达档即时推送(客户端30秒轮询兜底, 案子12章)
    WeekRotation.PushInfo()
end

--=====================================================================================
-- 领奖/轮次
--=====================================================================================

-- 构建客户端可见的活动数据
local function build_activity_view(act_id, act, st)
    local cfg = get_activity_cfg(act_id)
    act = act or WeekRotationDef.newActivityData(act_id)
    local claimed_list = {}
    for tier = 1, get_tier_count(act_id) do
        if act.claimed_tiers[tier] then
            table.insert(claimed_list, tier)
        end
    end
    return {
        activity_id = act_id,
        name = "",        -- 策划表name列未导出(标记N), 活动名由客户端本地配置, 服务器置空
        sub_name = "",
        activity_type = cfg and cfg.activity_type or 0,
        score = act.score,
        round = act.round,
        max_round = cfg and cfg.max_round or 0,
        locked = act.locked,
        full_score = cfg and cfg.full_score or 0,
        tier_scores = cfg and cfg.tier_scores or {},
        tier_chests = cfg and cfg.tier_rewards or {},
        claimed_tiers = claimed_list, -- 已领档位数组(与proto repeated对齐)
        end_ts = st and st.next_switch_ts or 0,
    }
end

local function build_info()
    local data, st = WeekRotation.EnsureRefresh()
    local infos = {}
    if data and st then
        table.insert(infos, build_activity_view(st.main_id, data.activities[st.main_id], st))
        table.insert(infos, build_activity_view(st.sub_id, data.activities[st.sub_id], st))
    end
    return {
        uid = context.uid,
        opened = (st ~= nil) and 1 or 0, -- proto为int32, boolean会导致pb.encode抛错
        week_index = st and st.week_idx or 0,
        cycle_weeks = get_rotation().cycle_weeks,
        activities = infos,
    }
end

-- 发放可堆叠道具(宝箱/开箱产出), 复用GameSettle的背包写入链
local function grant_items(item_counts)
    local box_list = {}
    for item_id, cnt in pairs(item_counts) do
        box_list[item_id] = { id = item_id, count = cnt, pos = 0 }
    end
    local stack_items, unstack_items, deal_coins = {}, {}, {}
    local ok = ItemDefine.GetItemDataFromIdCount(box_list, {}, stack_items, unstack_items, deal_coins)
    if not ok then
        moon.error(string.format("[week_rotation] GetItemDataFromIdCount err uid=%s items=%s",
            tostring(context.uid), json.encode(item_counts)))
        return ErrorCode.ServerInternalError
    end

    local code = scripts.Bag.CheckEmptyEnough(BagDef.BagType.Cangku, box_list, 0)
    if code ~= ErrorCode.None then
        return code -- 背包满等
    end

    local bag_change_log = {}
    code = scripts.Bag.AddItems(BagDef.BagType.Cangku, stack_items, unstack_items, bag_change_log)
    if code ~= ErrorCode.None then
        scripts.Bag.RollBackWithChange(bag_change_log)
        return code
    end
    scripts.Bag.SaveAndLog(bag_change_log, ItemDef.ChangeReason.WeekRotationReward)
    return ErrorCode.None
end

-- 轮次推进: 5档全领 → 开新一轮(案子2.6); 达上限锁定
local function try_advance_round(data, act_id, act)
    local cfg = get_activity_cfg(act_id)
    for tier = 1, get_tier_count(act_id) do
        if not act.claimed_tiers[tier] then
            return -- 还有档位未领, 不推进
        end
    end
    if act.round >= (cfg and cfg.max_round or 0) then
        act.locked = 1
        moon.info(string.format("[week_rotation] event=round_limit uid=%s activity=%s round=%s",
            tostring(context.uid), tostring(act_id), act.round))
        return
    end
    act.round = act.round + 1
    act.score = 0
    act.claimed_tiers = {}
    moon.info(string.format("[week_rotation] event=round_complete uid=%s activity=%s round=%s",
        tostring(context.uid), tostring(act_id), act.round))
end

--- 领取档位奖励(单档/一键), 幂等: 重复请求返回成功与已领状态, 不重复发奖(案子12章)
function WeekRotation.PBClaimWeekRotationTierReqCmd(req)
    local rsp_msg = {
        code = ErrorCode.None,
        error = "",
        uid = context.uid,
        activity_id = req.msg.activity_id or 0,
        chests_granted = 0,
        info = nil,
    }

    local data, st = WeekRotation.EnsureRefresh()
    if not data or not st then
        rsp_msg.code = ErrorCode.ConfigError
        rsp_msg.error = "活动未开启"
        return context.S2C(context.net_id, CmdCode.PBClaimWeekRotationTierRspCmd, rsp_msg, req.msg_context.stub_id)
    end

    -- 过期校验: 只允许领取当周开启的活动(案子12章"活动已结束")
    local act_id = req.msg.activity_id
    if act_id ~= st.main_id and act_id ~= st.sub_id then
        rsp_msg.code = ErrorCode.ConfigError
        rsp_msg.error = "活动已结束"
        return context.S2C(context.net_id, CmdCode.PBClaimWeekRotationTierRspCmd, rsp_msg, req.msg_context.stub_id)
    end

    local cfg = get_activity_cfg(act_id)
    if not cfg then
        rsp_msg.code = ErrorCode.ConfigError
        rsp_msg.error = "配置错误"
        return context.S2C(context.net_id, CmdCode.PBClaimWeekRotationTierRspCmd, rsp_msg, req.msg_context.stub_id)
    end

    local act = data.activities[act_id]
    if not act then
        rsp_msg.code = ErrorCode.ParamInvalid
        rsp_msg.error = "暂无可领取档位"
        return context.S2C(context.net_id, CmdCode.PBClaimWeekRotationTierRspCmd, rsp_msg, req.msg_context.stub_id)
    end
    if act.locked == 1 then
        rsp_msg.error = "本周轮次已达上限"
        return context.S2C(context.net_id, CmdCode.PBClaimWeekRotationTierRspCmd, rsp_msg, req.msg_context.stub_id)
    end

    -- 收集本次要领取的档位
    local to_claim = {}
    if req.msg.claim_all == 1 then
        for tier = 1, get_tier_count(act_id) do
            if not act.claimed_tiers[tier] and act.score >= cfg.tier_scores[tier] then
                table.insert(to_claim, tier)
            end
        end
    else
        local tier = req.msg.tier
        if not tier or tier < 1 or tier > get_tier_count(act_id) then
            rsp_msg.code = ErrorCode.ParamInvalid
            rsp_msg.error = "参数错误"
            return context.S2C(context.net_id, CmdCode.PBClaimWeekRotationTierRspCmd, rsp_msg, req.msg_context.stub_id)
        end
        if act.claimed_tiers[tier] then
            -- 幂等: 已领取直接返回成功状态, 不重复发奖
            rsp_msg.error = "已领取"
            rsp_msg.info = build_info()
            return context.S2C(context.net_id, CmdCode.PBClaimWeekRotationTierRspCmd, rsp_msg, req.msg_context.stub_id)
        end
        if act.score < cfg.tier_scores[tier] then
            rsp_msg.code = ErrorCode.ParamInvalid
            rsp_msg.error = "积分未达档位"
            return context.S2C(context.net_id, CmdCode.PBClaimWeekRotationTierRspCmd, rsp_msg, req.msg_context.stub_id)
        end
        table.insert(to_claim, tier)
    end

    if table.size(to_claim) <= 0 then
        rsp_msg.code = ErrorCode.ParamInvalid
        rsp_msg.error = "暂无可领取档位"
        return context.S2C(context.net_id, CmdCode.PBClaimWeekRotationTierRspCmd, rsp_msg, req.msg_context.stub_id)
    end

    -- 宝箱道具校验(策划item未配置时防呆拦截, 不扣进度)
    if not cfg.rewards_id or cfg.rewards_id <= 0 then
        moon.error("[week_rotation] rewards_id not configured, activity = ", act_id)
        rsp_msg.code = ErrorCode.ConfigError
        rsp_msg.error = "配置错误"
        return context.S2C(context.net_id, CmdCode.PBClaimWeekRotationTierRspCmd, rsp_msg, req.msg_context.stub_id)
    end

    local chest_cnt = 0
    for _, tier in ipairs(to_claim) do
        chest_cnt = chest_cnt + (cfg.tier_rewards[tier] or 0)
    end

    local code = grant_items({ [cfg.rewards_id] = chest_cnt })
    if code ~= ErrorCode.None then
        rsp_msg.code = code
        rsp_msg.error = "发放失败"
        return context.S2C(context.net_id, CmdCode.PBClaimWeekRotationTierRspCmd, rsp_msg, req.msg_context.stub_id)
    end

    for _, tier in ipairs(to_claim) do
        act.claimed_tiers[tier] = 1
        moon.info(string.format("[week_rotation] event=tier_claim uid=%s activity=%s tier=%s round=%s chests=%s",
            tostring(context.uid), tostring(act_id), tier, act.round, cfg.tier_rewards[tier] or 0))
    end
    try_advance_round(data, act_id, act)

    WeekRotation.SaveNow()
    rsp_msg.chests_granted = chest_cnt
    rsp_msg.info = build_info()
    return context.S2C(context.net_id, CmdCode.PBClaimWeekRotationTierRspCmd, rsp_msg, req.msg_context.stub_id)
end

-- 注: 档位宝箱为普通道具, 开启复用现有道具使用链路(PBUseItemReqCmd, use_type=6随机礼包),
-- 掉落配置由策划在Item表为宝箱道具配置use_award/award_weight, 本模块不再单独实现开箱

--=====================================================================================
-- GM
--=====================================================================================

--- GM直接加积分(hub console: add_week_score <uid> <activity_id> <count>)
--- 仅当周开启的活动有效; 支持负数扣减(下限0); 达轮次上限(locked)时拒绝
function WeekRotation.GMAddScore(activity_id, score)
    activity_id = math.tointeger(activity_id)
    score = math.tointeger(score)
    if not activity_id or not score or score == 0 then
        return false
    end
    local data, st = WeekRotation.EnsureRefresh()
    if not data or not st then
        moon.error(string.format("[week_rotation] GMAddScore activity not open, uid=%s activity=%s", tostring(context.uid), tostring(activity_id)))
        return false
    end
    if activity_id ~= st.main_id and activity_id ~= st.sub_id then
        moon.error(string.format("[week_rotation] GMAddScore activity %s not in current week(main=%s sub=%s), uid=%s",
            tostring(activity_id), tostring(st.main_id), tostring(st.sub_id), tostring(context.uid)))
        return false
    end
    local act = data.activities[activity_id]
    if not act then
        act = WeekRotationDef.newActivityData(activity_id)
        data.activities[activity_id] = act
    end
    if act.locked == 1 then
        moon.error(string.format("[week_rotation] GMAddScore locked, uid=%s activity=%s", tostring(context.uid), tostring(activity_id)))
        return false
    end
    act.score = math.max(0, act.score + score)
    scripts.UserModel.AddDirtyModule("WeekRotation")
    moon.info(string.format("[week_rotation] event=gm_score uid=%s activity=%s add=%s total=%s round=%s",
        tostring(context.uid), tostring(activity_id), tostring(score), tostring(act.score), tostring(act.round)))
    WeekRotation.PushInfo()
    return true
end

--=====================================================================================
-- 信息拉取与推送
--=====================================================================================

function WeekRotation.PBGetWeekRotationInfoReqCmd(req)
    local info = build_info()
    return context.S2C(context.net_id, CmdCode.PBGetWeekRotationInfoRspCmd, {
        code = ErrorCode.None,
        error = "",
        uid = context.uid,
        info = info,
    }, req.msg_context.stub_id)
end

-- CmdCode为锁表, 未知key直接index会抛错, 用rawget探测(协议落地前静默跳过推送)
local function safe_cmd_code(name)
    return rawget(CmdCode, name)
end

function WeekRotation.PushInfo()
    local cmd = safe_cmd_code("PBWeekRotationSyncCmd")
    if not cmd then
        return
    end
    -- 消息体须为{uid, info}结构, 直接传build_info()会因字段不匹配被pb静默丢弃只编出uid
    context.S2C(context.net_id, cmd, {
        uid = context.uid,
        info = build_info(),
    }, 0)
end

function WeekRotation.PushNotify(notify_type, end_ts)
    local cmd = safe_cmd_code("PBWeekRotationNotifyCmd")
    if not cmd then
        return
    end
    context.S2C(context.net_id, cmd, {
        uid = context.uid,
        notify_type = notify_type,
        end_ts = end_ts or 0,
    }, 0)
end

--=====================================================================================
-- 测试辅助(仅测试环境, 机器人E2E驱动, 上线前可整体删除)
--=====================================================================================

--- 模拟通关结算累计积分: 等价于结算成功时 Room.GameSettle 的挂点调用
function WeekRotation.PBTestWeekRotationSettleReqCmd(req)
    local rsp_msg = {
        code = ErrorCode.None,
        error = "",
        uid = context.uid,
        applied = 0,
    }
    local chapter = tonumber(req.msg.chapter) or 0
    local difficulty = tonumber(req.msg.difficulty) or 0
    local times = tonumber(req.msg.times) or 1
    if times < 1 then
        times = 1
    end
    if times > 100 then
        times = 100
    end
    for _ = 1, times do
        WeekRotation.OnSettleSuccess(chapter, difficulty)
        rsp_msg.applied = rsp_msg.applied + 1
    end
    moon.info(string.format("[week_rotation] test_settle uid=%s chapter=%s difficulty=%s times=%s",
        tostring(context.uid), tostring(chapter), tostring(difficulty), tostring(rsp_msg.applied)))
    local cmd = safe_cmd_code("PBTestWeekRotationSettleRspCmd")
    if cmd then
        return context.S2C(context.net_id, cmd, rsp_msg, req.msg_context.stub_id)
    end
    moon.error("[week_rotation] PBTestWeekRotationSettleRspCmd not in CmdCode, rerun pb tool")
end

return WeekRotation
