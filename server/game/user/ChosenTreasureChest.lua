--[[
天选宝箱(ChosenTreasureChest) 活动模块
需求: 《天选宝箱》系统策划案 v3.9 + 口径定稿(2026-11)

要点:
- 九格无放回: 权重合计10000(万分位, 公示口径=初始权重), 抽中移出池, 剩余池归一化抽取
- 九档九格(2026-11改版): step_prices九档; 每档按剩余池权重抽1格, 无收池, cur_step=10终态(走满必集齐)
- 令 = 活动货币(Coin表, 一箱一令ticket_id, 跨期保留不回收); 绑定灵石(coin3)优先购买, 不足补扣灵石(coin2), 1令=100灵石
- 时间窗: 下线后禁止开箱/买令/免费领令(协议层校验, 防直发); 返场 = 复用旧箱ID只改配置start_time/end_time
- 进度按期号锚点(period_key=cfg.start_time)惰性重置: 访问时发现不匹配 → 审计日志 → 全新九格;
  锚定新期StartTime而非end_time, 策划中途延期不会误清数据
- 免费领令: 账号等级达标(gift_lv), 每箱全期一次(gift_claimed不随期重置), 数量=第1档价(推导, 不配置)

协议(定义于 protocol/activity.proto, protogen重生成CmdCode后本模块处理器自动路由):
  PBGetChosenTreasureChestInfoReqCmd/RspCmd     拉取全部箱信息+进度
  PBOpenChosenTreasureChestReqCmd/RspCmd        开箱(单抽/收池)
  PBBuyChosenTreasureChestTicketReqCmd/RspCmd   购买令(灵石→令)
  PBGetChosenTreasureChestGiftReqCmd/RspCmd     免费领取首抽令
建表SQL见 ChosenTreasureChestDef.lua 头部注释(已追加到 database/mgame.sql)
]]

local moon = require "moon"
local common = require "common"
local ErrorCode = common.ErrorCode
local CmdCode = common.CmdCode
local Database = common.Database
local json = require "json"
local CTCDef = require "common.def.ChosenTreasureChestDef"
local ItemDefine = require "common.logic.ItemDefine"
local BagDef = require "common.def.BagDef"
local ItemDef = require "common.def.ItemDef"

---@type user_context
local context = ...
local scripts = context.scripts

---@class ChosenTreasureChest
local ChosenTreasureChest = {}

local Config = CTCDef.Config
local GameCfg = common.GameCfg

--=====================================================================================
-- 配置访问与校验
--=====================================================================================

local function get_box_cfg(box_id)
    local cfgs = GameCfg.ChosenTreasureChest
    return cfgs and cfgs[box_id] or nil
end

-- 箱状态: 0=待上线 1=在售 2=已下线
local BOX_STATE = { WAIT = 0, ON_SALE = 1, OFF_SALE = 2 }

local function get_box_state(cfg, now_ts)
    if now_ts < cfg.start_time then
        return BOX_STATE.WAIT
    end
    if now_ts < cfg.end_time then
        return BOX_STATE.ON_SALE
    end
    return BOX_STATE.OFF_SALE
end

local function sorted_box_ids()
    local ids = {}
    local cfgs = GameCfg.ChosenTreasureChest
    if cfgs then
        for box_id, _ in pairs(cfgs) do
            table.insert(ids, box_id)
        end
        table.sort(ids)
    end
    return ids
end

-- 启动期配置校验(错误打日志不阻断, 防策划表填错静默上线)
local validated = false
local function validate_configs()
    if validated then
        return
    end
    validated = true
    local cfgs = GameCfg.ChosenTreasureChest
    if not cfgs or table.size(cfgs) == 0 then
        return
    end
    local ticket_owner = {}
    for box_id, cfg in pairs(cfgs) do
        local prefix = string.format("[chosen_chest] config err box=%s: ", tostring(box_id))
        if not cfg.start_time or not cfg.end_time or cfg.start_time >= cfg.end_time then
            moon.error(prefix .. "start_time/end_time invalid")
        end
        if type(cfg.step_prices) ~= "table" then
            moon.error(prefix .. "step_prices missing")
        else
            for step = 1, Config.STEP_COUNT do
                local price = cfg.step_prices[step]
                if not price or price <= 0 then
                    moon.error(prefix .. "step_prices[" .. step .. "] invalid")
                end
            end
        end
        if type(cfg.slot_items) ~= "table" or type(cfg.slot_weights) ~= "table" then
            moon.error(prefix .. "slot_items/slot_weights missing")
        else
            local weight_sum = 0
            for slot = 1, Config.SLOT_COUNT do
                local item = cfg.slot_items[slot]
                local weight = cfg.slot_weights[slot]
                if not item or item <= 0 then
                    moon.error(prefix .. "slot_items[" .. slot .. "] invalid")
                elseif item <= 999 then
                    -- 货币ID段: 走不到背包发放链(会被分流到deal_coins被丢弃), 禁止配在格位里
                    moon.error(prefix .. "slot_items[" .. slot .. "] coin id not allowed")
                end
                if not weight or weight <= 0 then
                    moon.error(prefix .. "slot_weights[" .. slot .. "] invalid")
                else
                    weight_sum = weight_sum + weight
                end
            end
            if weight_sum ~= Config.WEIGHT_TOTAL then
                moon.error(prefix .. "slot_weights sum=" .. weight_sum .. " expect=" .. Config.WEIGHT_TOTAL)
            end
        end
        local ticket = cfg.ticket_id
        if not ticket or not GameCfg.Coin or not GameCfg.Coin[ticket] then
            moon.error(prefix .. "ticket_id " .. tostring(ticket) .. " not in Coin table")
        elseif ticket_owner[ticket] then
            moon.error(prefix .. "ticket_id " .. ticket .. " duplicated with box " .. tostring(ticket_owner[ticket]))
        else
            ticket_owner[ticket] = box_id
        end
        if not cfg.gift_lv or cfg.gift_lv < 0 then
            moon.error(prefix .. "gift_lv invalid")
        end
    end
end

--=====================================================================================
-- 数据生命周期
--=====================================================================================

-- json落库重读后数字键会变字符串键, 统一归一化回数字键
local function normalize_loaded_data(data)
    if not data then
        return
    end
    if data.boxes then
        local boxes = {}
        for box_key, box in pairs(data.boxes) do
            local box_id = tonumber(box_key)
            if box_id and type(box) == "table" then
                local drawn = {}
                if box.drawn_slots then
                    for slot_key, v in pairs(box.drawn_slots) do
                        local slot = tonumber(slot_key)
                        if slot then
                            drawn[slot] = v
                        end
                    end
                end
                box.drawn_slots = drawn
                box.period_key = tonumber(box.period_key) or 0
                box.cur_step = tonumber(box.cur_step) or 1
                boxes[box_id] = box
            end
        end
        data.boxes = boxes
    else
        data.boxes = {}
    end
    if data.gift_claimed then
        local claimed = {}
        for box_key, v in pairs(data.gift_claimed) do
            local box_id = tonumber(box_key)
            if box_id then
                claimed[box_id] = v
            end
        end
        data.gift_claimed = claimed
    else
        data.gift_claimed = {}
    end
    data.uid = tonumber(data.uid) or context.uid
end

function ChosenTreasureChest.Init()
    local data = ChosenTreasureChest.LoadData()
    if data then
        normalize_loaded_data(data)
        scripts.UserModel.SetChosenTreasureChest(data)
    end
    if not scripts.UserModel.GetChosenTreasureChest() then
        data = CTCDef.newPlayerData()
        data.uid = context.uid
        scripts.UserModel.SetChosenTreasureChest(data)
    end
end

function ChosenTreasureChest.Start()
    if not scripts.UserModel.GetChosenTreasureChest() then
        return
    end
    validate_configs()
    scripts.UserModel.AddDirtyModule("ChosenTreasureChest")
end

function ChosenTreasureChest.LoadData()
    local data, db_err = Database.loadchosentreasurechest(context.addr_db_user, context.uid)
    if db_err then
        context.db_init_failed = db_err -- 查询失败: 置登录失败标记
    end
    return data
end

function ChosenTreasureChest.SaveNow()
    local data = scripts.UserModel.GetChosenTreasureChest()
    if not data then
        return false
    end
    local success = Database.savechosentreasurechest(context.addr_db_user, context.uid, data)
    scripts.UserModel.RemoveDirtyModule("ChosenTreasureChest")
    return success
end

function ChosenTreasureChest.TimingSave()
    local data = scripts.UserModel.GetChosenTreasureChest()
    if not data then
        return false
    end
    return Database.savechosentreasurechest(context.addr_db_user, context.uid, data)
end

--=====================================================================================
-- 期号惰性重置与视图
--=====================================================================================

--- 取单箱进度(带期号惰性重置): period_key ~= cfg.start_time → 审计日志后重置为全新九格
--- @return ChosenTreasureChestBoxData 该箱进度(一定非nil)
local function ensure_box_data(data, cfg)
    local box = data.boxes[cfg.id]
    if not box or box.period_key ~= cfg.start_time then
        if box then
            moon.info(string.format(
                "[chosen_chest] event=period_reset uid=%s box=%s old_period=%s new_period=%s old_drawn=%s old_step=%s",
                tostring(context.uid), tostring(cfg.id), tostring(box.period_key), tostring(cfg.start_time),
                json.encode(box.drawn_slots), tostring(box.cur_step)))
        end
        box = CTCDef.newBoxData(cfg.start_time)
        data.boxes[cfg.id] = box
    end
    return box
end

local function build_box_view(box_id, cfg, data, now_ts)
    local box = ensure_box_data(data, cfg)
    local drawn_list = {}
    for slot = 1, Config.SLOT_COUNT do
        if box.drawn_slots[slot] then
            table.insert(drawn_list, slot)
        end
    end
    local step_prices, slot_items, slot_weights = {}, {}, {}
    for step = 1, Config.STEP_COUNT do
        table.insert(step_prices, cfg.step_prices[step] or 0)
    end
    for slot = 1, Config.SLOT_COUNT do
        table.insert(slot_items, cfg.slot_items[slot] or 0)
        table.insert(slot_weights, cfg.slot_weights[slot] or 0)
    end
    return {
        box_id = box_id,
        state = get_box_state(cfg, now_ts),
        start_time = cfg.start_time,
        end_time = cfg.end_time,
        ticket_id = cfg.ticket_id,
        gift_lv = cfg.gift_lv or 0,
        gift_claimed = data.gift_claimed[box_id] and 1 or 0,
        step_prices = step_prices,
        slot_items = slot_items,
        slot_weights = slot_weights,
        drawn_slots = drawn_list,
        cur_step = box.cur_step,
    }
end

--=====================================================================================
-- 开箱事务(扣令+发物件, 同change_log, 失败整体回滚)
--=====================================================================================

-- 发放物件并落审计: 与扣令共用一份change_log, 任一步失败RollBack整体回滚
-- 注意: Bag写函数内禁止yield, 本函数全同步
local function grant_open_rewards(cost_coins, item_counts, change_reason)
    local bag_change_log = {}
    local code = scripts.Bag.DealCoins(cost_coins, bag_change_log)
    if code ~= ErrorCode.None then
        scripts.Bag.RollBackWithChange(bag_change_log)
        return code
    end

    local box_list = {}
    for item_id, cnt in pairs(item_counts) do
        box_list[item_id] = { id = item_id, count = cnt, pos = 0 }
    end
    local stack_items, unstack_items, deal_coins = {}, {}, {}
    local ok = ItemDefine.GetItemDataFromIdCount(box_list, {}, stack_items, unstack_items, deal_coins)
    if not ok then
        scripts.Bag.RollBackWithChange(bag_change_log)
        moon.error(string.format("[chosen_chest] GetItemDataFromIdCount err uid=%s items=%s",
            tostring(context.uid), json.encode(item_counts)))
        return ErrorCode.ServerInternalError
    end

    code = scripts.Bag.CheckEmptyEnough(BagDef.BagType.Cangku, box_list, 0)
    if code ~= ErrorCode.None then
        scripts.Bag.RollBackWithChange(bag_change_log)
        return code
    end
    code = scripts.Bag.AddItems(BagDef.BagType.Cangku, stack_items, unstack_items, bag_change_log)
    if code ~= ErrorCode.None then
        scripts.Bag.RollBackWithChange(bag_change_log)
        return code
    end

    scripts.Bag.SaveAndLog(bag_change_log, change_reason)
    return ErrorCode.None
end

--=====================================================================================
-- 协议: 拉取信息
--=====================================================================================

function ChosenTreasureChest.PBGetChosenTreasureChestInfoReqCmd(req)
    validate_configs()
    local data = scripts.UserModel.GetChosenTreasureChest()
    if not data then
        return context.S2C(context.net_id, CmdCode.PBGetChosenTreasureChestInfoRspCmd, {
            code = ErrorCode.ServerInternalError,
            error = "数据未初始化",
            uid = context.uid,
            info = nil,
        }, req.msg_context.stub_id)
    end

    local now_ts = moon.time()
    local chests = {}
    local dirty = false
    for _, box_id in ipairs(sorted_box_ids()) do
        local cfg = get_box_cfg(box_id)
        local box = data.boxes[box_id]
        if not box or box.period_key ~= cfg.start_time then
            dirty = true -- 视图构建内发生了期重置, 标脏等定时存
        end
        table.insert(chests, build_box_view(box_id, cfg, data, now_ts))
    end
    if dirty then
        scripts.UserModel.AddDirtyModule("ChosenTreasureChest")
    end

    return context.S2C(context.net_id, CmdCode.PBGetChosenTreasureChestInfoRspCmd, {
        code = ErrorCode.None,
        error = "",
        uid = context.uid,
        info = { uid = context.uid, chests = chests },
    }, req.msg_context.stub_id)
end

--=====================================================================================
-- 协议: 开箱
--=====================================================================================

function ChosenTreasureChest.PBOpenChosenTreasureChestReqCmd(req)
    local box_id = req.msg.box_id or 0
    local rsp_msg = {
        code = ErrorCode.None,
        error = "",
        uid = context.uid,
        box_id = box_id,
        step = 0,
        hit_slots = {},
        hit_items = {},
        cur_step = 0,
    }
    local function reply(code, err)
        rsp_msg.code = code
        rsp_msg.error = err or ""
        return context.S2C(context.net_id, CmdCode.PBOpenChosenTreasureChestRspCmd, rsp_msg, req.msg_context.stub_id)
    end

    local cfg = get_box_cfg(box_id)
    if not cfg then
        return reply(ErrorCode.ChosenChestNotFound, "宝匣不存在")
    end
    if get_box_state(cfg, moon.time()) ~= BOX_STATE.ON_SALE then
        return reply(ErrorCode.ChosenChestNotOnSale, "宝匣未在售")
    end

    local data = scripts.UserModel.GetChosenTreasureChest()
    if not data then
        return reply(ErrorCode.ServerInternalError, "数据未初始化")
    end
    local box = ensure_box_data(data, cfg)

    if box.cur_step >= Config.CUR_STEP_FINISHED then
        return reply(ErrorCode.ChosenChestAlreadyFinished, "本期已开满")
    end

    local step = box.cur_step
    local price = cfg.step_prices[step] or 0
    if price <= 0 then
        return reply(ErrorCode.ConfigError, "配置错误")
    end

    -- 本次抽出格位: 每档按剩余池权重抽1格(九档九格, 无收池)
    local hit_slots = {}
    local pool = {}
    for slot = 1, Config.SLOT_COUNT do
        if not box.drawn_slots[slot] then
            pool[slot] = cfg.slot_weights[slot]
        end
    end
    if table.size(pool) == 0 then
        return reply(ErrorCode.ChosenChestAlreadyFinished, "本期已开满")
    end
    local slot = scripts.Item.RangeTags(pool)
    if not slot or slot <= 0 then
        return reply(ErrorCode.ServerInternalError, "奖池异常")
    end
    table.insert(hit_slots, slot)

    -- 物件聚合(同ID多格时合并数量)
    local item_counts = {}
    local hit_items = {}
    for _, slot in ipairs(hit_slots) do
        local item_id = cfg.slot_items[slot]
        item_counts[item_id] = (item_counts[item_id] or 0) + 1
        table.insert(hit_items, item_id)
    end

    -- 事务: 扣令 + 发物件
    local cost_coins = { [cfg.ticket_id] = { coin_id = cfg.ticket_id, coin_count = -price } }
    local check_code = scripts.Bag.CheckCoinsEnough(cost_coins)
    if check_code ~= ErrorCode.None then
        return reply(ErrorCode.ChosenChestTicketNotEnough, "令不足")
    end
    local code = grant_open_rewards(cost_coins, item_counts, ItemDef.ChangeReason.ChosenChestOpen)
    if code ~= ErrorCode.None then
        moon.error(string.format("[chosen_chest] open grant failed uid=%s box=%s step=%s code=%s",
            tostring(context.uid), tostring(box_id), tostring(step), tostring(code)))
        return reply(code, "发放失败")
    end

    -- 进度推进(无放回: 抽中移出池)
    for _, slot in ipairs(hit_slots) do
        box.drawn_slots[slot] = 1
    end
    box.cur_step = step + 1
    ChosenTreasureChest.SaveNow()

    moon.info(string.format("[chosen_chest] event=open uid=%s box=%s step=%s price=%s slots=%s items=%s cur_step=%s",
        tostring(context.uid), tostring(box_id), tostring(step), tostring(price),
        json.encode(hit_slots), json.encode(hit_items), tostring(box.cur_step)))

    rsp_msg.step = step
    rsp_msg.hit_slots = hit_slots
    rsp_msg.hit_items = hit_items
    rsp_msg.cur_step = box.cur_step
    return context.S2C(context.net_id, CmdCode.PBOpenChosenTreasureChestRspCmd, rsp_msg, req.msg_context.stub_id)
end

--=====================================================================================
-- 协议: 购买令(灵石coin2 -> 本箱令, 1令=100灵石)
--=====================================================================================

function ChosenTreasureChest.PBBuyChosenTreasureChestTicketReqCmd(req)
    local box_id = req.msg.box_id or 0
    local num = tonumber(req.msg.num) or 0
    local rsp_msg = {
        code = ErrorCode.None,
        error = "",
        uid = context.uid,
        box_id = box_id,
        num = 0,
        coin_id = 0,
    }
    local function reply(code, err)
        rsp_msg.code = code
        rsp_msg.error = err or ""
        return context.S2C(context.net_id, CmdCode.PBBuyChosenTreasureChestTicketRspCmd, rsp_msg, req.msg_context.stub_id)
    end

    local cfg = get_box_cfg(box_id)
    if not cfg then
        return reply(ErrorCode.ChosenChestNotFound, "宝匣不存在")
    end
    if get_box_state(cfg, moon.time()) ~= BOX_STATE.ON_SALE then
        return reply(ErrorCode.ChosenChestNotOnSale, "宝匣未在售") -- 下线期间令不能买
    end
    if num < 1 or num > Config.BUY_NUM_MAX then
        return reply(ErrorCode.ChosenChestBuyNumInvalid, "购买数量错误")
    end

    local cost = num * Config.TICKET_EXCHANGE_RATE
    -- 2026-11改版: 优先扣绑定灵石(coin 3), 不足自动补扣非绑定灵石(coin 2)
    -- CheckCoinsEnough对绑定货币做单向转换(原表改写), DealCoins按改写后的金额执行
    local coins = {
        [Config.BOUND_LINGSHI_COIN_ID] = { coin_id = Config.BOUND_LINGSHI_COIN_ID, coin_count = -cost },
        [cfg.ticket_id] = { coin_id = cfg.ticket_id, coin_count = num },
    }
    local check_code = scripts.Bag.CheckCoinsEnough(coins)
    if check_code ~= ErrorCode.None then
        return reply(ErrorCode.CoinNotEnough, "灵石不足")
    end

    local bag_change_log = {}
    local code = scripts.Bag.DealCoins(coins, bag_change_log)
    if code ~= ErrorCode.None then
        scripts.Bag.RollBackWithChange(bag_change_log)
        return reply(code, "购买失败")
    end
    scripts.Bag.SaveAndLog(bag_change_log, ItemDef.ChangeReason.ChosenChestBuyTicket)

    moon.info(string.format("[chosen_chest] event=buy_ticket uid=%s box=%s num=%s cost=%s ticket_coin=%s coins_deduct=%s",
        tostring(context.uid), tostring(box_id), tostring(num),
        tostring(cost), tostring(cfg.ticket_id), json.encode(coins)))

    rsp_msg.num = num
    rsp_msg.coin_id = cfg.ticket_id
    return context.S2C(context.net_id, CmdCode.PBBuyChosenTreasureChestTicketRspCmd, rsp_msg, req.msg_context.stub_id)
end

--=====================================================================================
-- 协议: 免费领取首抽令(等级达标, 每箱全期一次, 数量=第1档价)
--=====================================================================================

function ChosenTreasureChest.PBGetChosenTreasureChestGiftReqCmd(req)
    local box_id = req.msg.box_id or 0
    local rsp_msg = {
        code = ErrorCode.None,
        error = "",
        uid = context.uid,
        box_id = box_id,
        ticket_num = 0,
    }
    local function reply(code, err)
        rsp_msg.code = code
        rsp_msg.error = err or ""
        return context.S2C(context.net_id, CmdCode.PBGetChosenTreasureChestGiftRspCmd, rsp_msg, req.msg_context.stub_id)
    end

    local cfg = get_box_cfg(box_id)
    if not cfg then
        return reply(ErrorCode.ChosenChestNotFound, "宝匣不存在")
    end
    if get_box_state(cfg, moon.time()) ~= BOX_STATE.ON_SALE then
        return reply(ErrorCode.ChosenChestNotOnSale, "宝匣未在售")
    end

    local user_attr = scripts.UserModel.GetUserAttr()
    local level = (user_attr and user_attr.account_level) or 0
    if level < (cfg.gift_lv or 0) then
        return reply(ErrorCode.ChosenChestGiftLevelNotEnough, "账号等级不足")
    end

    local data = scripts.UserModel.GetChosenTreasureChest()
    if not data then
        return reply(ErrorCode.ServerInternalError, "数据未初始化")
    end
    if data.gift_claimed[cfg.id] then
        return reply(ErrorCode.ChosenChestGiftAlreadyClaimed, "已领取")
    end

    local num = cfg.step_prices[1] or 0
    if num <= 0 then
        return reply(ErrorCode.ConfigError, "配置错误")
    end

    local bag_change_log = {}
    local coins = { [cfg.ticket_id] = { coin_id = cfg.ticket_id, coin_count = num } }
    local code = scripts.Bag.DealCoins(coins, bag_change_log)
    if code ~= ErrorCode.None then
        scripts.Bag.RollBackWithChange(bag_change_log)
        return reply(code, "发放失败")
    end
    scripts.Bag.SaveAndLog(bag_change_log, ItemDef.ChangeReason.ChosenChestGift)

    data.gift_claimed[cfg.id] = 1 -- 全期唯一标记, 不随期重置
    ChosenTreasureChest.SaveNow()

    moon.info(string.format("[chosen_chest] event=gift_claim uid=%s box=%s level=%s gift_lv=%s ticket_num=%s",
        tostring(context.uid), tostring(box_id), tostring(level), tostring(cfg.gift_lv), tostring(num)))

    rsp_msg.ticket_num = num
    return context.S2C(context.net_id, CmdCode.PBGetChosenTreasureChestGiftRspCmd, rsp_msg, req.msg_context.stub_id)
end

--=====================================================================================
-- GM(测试辅助)
--=====================================================================================

--- GM重置单箱进度(测返场重置): 直接按当前配置期号重建
function ChosenTreasureChest.GMResetBox(box_id)
    box_id = math.tointeger(box_id)
    local data = scripts.UserModel.GetChosenTreasureChest()
    local cfg = get_box_cfg(box_id)
    if not data or not cfg then
        return false
    end
    data.boxes[box_id] = CTCDef.newBoxData(cfg.start_time)
    ChosenTreasureChest.SaveNow()
    moon.info(string.format("[chosen_chest] event=gm_reset uid=%s box=%s", tostring(context.uid), tostring(box_id)))
    return true
end

--- GM直接加令(测开箱流程, 不走灵石兑换)
function ChosenTreasureChest.GMAddTicket(box_id, num)
    box_id = math.tointeger(box_id)
    num = math.tointeger(num)
    local cfg = get_box_cfg(box_id)
    if not cfg or not num or num <= 0 then
        return false
    end
    local bag_change_log = {}
    local coins = { [cfg.ticket_id] = { coin_id = cfg.ticket_id, coin_count = num } }
    local code = scripts.Bag.DealCoins(coins, bag_change_log)
    if code ~= ErrorCode.None then
        scripts.Bag.RollBackWithChange(bag_change_log)
        return false
    end
    scripts.Bag.SaveAndLog(bag_change_log, ItemDef.ChangeReason.ChosenChestGift)
    moon.info(string.format("[chosen_chest] event=gm_ticket uid=%s box=%s num=%s", tostring(context.uid), tostring(box_id), tostring(num)))
    return true
end

return ChosenTreasureChest
