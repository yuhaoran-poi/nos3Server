--[[
天选宝箱(ChosenTreasureChest) 活动定义
需求: 《天选宝箱》系统策划案 v3.9 + 口径定稿(2026-11)

玩法要点:
- 九格无放回: 权重合计10000(万分位, 公示口径=初始权重), 抽中移出池
- 八档递增价: 第1-7档每档抽1格, 第8档一次收走剩余格位(cur_step=9终态)
- 令 = 活动货币(Coin表, 一箱一令ticket_id, 跨期保留不回收); 灵石(coin 2)购买, 1令=100灵石
- 下线期间(end_time后): 禁止开箱/买令/免费领令; 令保留, 返场继续可用
- 返场 = 复用旧箱ID只改配置start_time/end_time; 玩家进度按期号锚点(period_key=cfg.start_time)
  惰性重置(访问时发现不匹配 → 审计日志 → 重置为全新九格), 不在下线时主动清理
- 免费领令: 账号等级达标(gift_lv), 每箱全期一次(gift_claimed不随期重置), 数量=第1档价(推导, 不配置)

配置表 GameCfg.ChosenTreasureChest(static/table/ChosenTreasureChest.lua):
    id / ticket_id(令货币ID, Coin表) / start_time / end_time
    step_prices(八档价格) / slot_items(九格物件) / slot_weights(九格权重合计10000) / gift_lv(免费领令等级)

建表SQL(mgame.chosentreasureasurechests 三列式, 同weekrotations, 已追加到 database/mgame.sql):
    CREATE TABLE IF NOT EXISTS mgame.chosentreasurechests (
        uid BIGINT NOT NULL,
        value MEDIUMBLOB,
        json JSON,
        PRIMARY KEY (uid)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
]]

local LuaExt = require "common.LuaExt"

local ChosenTreasureChestDef = {}

-- 运行参数(非策划数值表, 属服务器运营参数)
local Config = {
    LINGSHI_COIN_ID = 2,        -- 灵石货币ID(非绑定)
    BOUND_LINGSHI_COIN_ID = 3,  -- 绑定灵石货币ID(买令优先扣, 不足自动补扣灵石2)
    TICKET_EXCHANGE_RATE = 100, -- 兑换比例: 1令 = 100灵石(案子1.4)
    WEIGHT_TOTAL = 10000,       -- 九格权重合计基准(万分位, 2026-11口径)
    STEP_COUNT = 9,             -- 档位数(2026-11改版: 九档九格, 每档抽1格, 无收池)
    SLOT_COUNT = 9,             -- 格位数
    CUR_STEP_FINISHED = 10,     -- 终态档位: 本期已开满(九档集齐)
    BUY_NUM_MAX = 10000,        -- 单次购买令数量上限(防呆, 非限购)
}

-- 玩家单箱进度(按期重置)
---@class ChosenTreasureChestBoxData
---@field period_key integer 期号锚点(=开局时cfg.start_time), 与当前配置不匹配即重置
---@field drawn_slots table<integer, integer> 已抽出格位 {[slot]=1}(九格无放回的"池")
---@field cur_step integer 下一次开启的档位(1-8), 9=本期已开满
local defaultChosenTreasureChestBoxData = {
    period_key = 0,
    drawn_slots = {},   -- { [slot] = 1 }
    cur_step = 1,
}

-- 玩家总数据(存储于 mgame.chosentreasurechests 表 json 列, 服务器私有结构不走网络)
---@class ChosenTreasureChestPlayerData
---@field uid integer
---@field boxes table<integer, ChosenTreasureChestBoxData> {[box_id]=BoxData} 进度, 按期惰性重置
---@field gift_claimed table<integer, integer> 免费领令标记 {[box_id]=1} 每箱全期唯一, 不随返场重置
local defaultChosenTreasureChestPlayerData = {
    uid = 0,
    boxes = {},         -- { [box_id] = defaultChosenTreasureChestBoxData }
    gift_claimed = {},  -- { [box_id] = 1 }
}

---@return ChosenTreasureChestBoxData
function ChosenTreasureChestDef.newBoxData(period_key)
    local t = LuaExt.const(table.copy(defaultChosenTreasureChestBoxData))
    t.period_key = period_key
    return t
end

---@return ChosenTreasureChestPlayerData
function ChosenTreasureChestDef.newPlayerData()
    return LuaExt.const(table.copy(defaultChosenTreasureChestPlayerData))
end

-- 导出
ChosenTreasureChestDef.Config = Config

return ChosenTreasureChestDef
