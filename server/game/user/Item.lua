local moon = require "moon"
local common = require "common"
local GameCfg = common.GameCfg
local ErrorCode = common.ErrorCode
local CmdCode = common.CmdCode

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

-- 从配置中获取物品
function Item.GetItemsFromCfg(item_cfg, num, negative, items, coins)
    if not item_cfg then
        return
    end

    for id, cnt in pairs(item_cfg) do
        if scripts.ItemDefine.GetItemType(id) == scripts.ItemDefine.EItemSmallType.Coin then
            if not coins[id] then
                coins[id] = {
                    coin_id = id,
                    count = 0,
                }
            end
            if negative then
                coins[id].count = coins[id].count - cnt * num
            else
                coins[id].count = coins[id].count + cnt * num
            end
        else
            if not items[id] then
                items[id] = {
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

return Item