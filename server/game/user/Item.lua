local moon = require "moon"
local common = require "common"
local GameCfg = common.GameCfg
local ErrorCode = common.ErrorCode
local CmdCode = common.CmdCode
local ItemDefine = require("common.logic.ItemDefine")

---@type user_context
local context = ...
local scripts = context.scripts

---@class Item
local Item = {}

function Item.Init()
    
end

function Item.Start()
    local data = scripts.UserModel.Get()
    if not data.itemlist then
        data.itemlist = {}
    end
end

-- 随机词条id
function Item.RangeTags(tag_pool)
    local total_weight = 0
    for id, weight in pairs(tag_pool) do
        total_weight = total_weight + weight
    end

    local rand = math.random(total_weight)
    for id, weight in pairs(tag_pool) do
        rand = rand - weight
        if rand <= 0 then
            return id
        end
    end

    return 0
end

-- 从配置中获取道具或者货币map
function Item.GetItemsFromCfg(item_cfg, num, negative, items, coins)
    if not item_cfg then
        return
    end

    for id, cnt in pairs(item_cfg) do
        if ItemDefine.GetItemType(id) == ItemDefine.EItemSmallType.Coin then
            if not coins[id] then
                coins[id] = {
                    coin_id = id,
                    coin_count = 0,
                }
            end
            if negative then
                coins[id].coin_count = coins[id].coin_count - cnt * num
            else
                coins[id].coin_count = coins[id].coin_count + cnt * num
            end
        else
            if not items[id] then
                items[id] = {
                    id = id,
                    count = 0,
                    pos = 0,
                }
            end
            if negative then
                items[id].count = items[id].count - cnt * num
            else
                items[id].count = items[id].count + cnt * num
            end
        end
    end
end

-- 把道具和货币map转换为添加列表
function Item.GetItemListFromItemsCoins(items, coins, add_list)
    if not items and not coins then
        return
    end

    for id, item in pairs(items) do
        table.insert(add_list, item)
    end
    for id, coin in pairs(coins) do
        table.insert(add_list, { id = coin.coin_id, count = coin.coin_count })
    end
end

return Item