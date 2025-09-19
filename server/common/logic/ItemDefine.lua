local moon = require "moon"
local common = require "common"
local ItemDef = require("common.def.ItemDef")
local GameCfg = common.GameCfg

---@class ItemDefine
---@field public EItemSmallType table
---@field public EItemBigType table
---@field public ItemBagType table
---@field public GetItemType fun(nConfigId: integer): integer
---@field public GetItemPosType fun(nConfigId: integer): integer
---@field public GetItemBagType fun(nConfigId: integer): integer

local ItemDefine = {
    Coin = { start = 1, End = 99 },
    Piece = { start = 10000, End = 29999 },
    EffectCard = { start = 30000, End = 30999 },
    Book = { start = 31000, End = 33999 },
    CostItem = { start = 34000, End = 34999 },
    MonsterSoul = { start = 35000, End = 36999 },
    TempCard = { start = 37000, End = 39999 },
    PlayItem = { start = 40000, End = 40999 },
    GrowthItem = { start = 41000, End = 50999 },
    StackMagicItem = { start = 51000, End = 75999 },
    GhostSkillBook = { start = 95000, End = 95999 },
    HumanStackDiagrams = { start = 96000, End = 105999 },
    GhostStackDiagrams = { start = 106000, End = 115999 },
    HumanTabooWord = { start = 116000, End = 119999 },
    GhostTabooWord = { start = 120000, End = 123999 },
    Gift = { start = 320000, End = 329999 },
    DurabItem = { start = 500000, End = 500999 },
    MagicItem = { start = 600000, End = 624999 },
    Antique = { start = 625000, End = 629999 },
    HumanDiagrams = { start = 630000, End = 639999 },
    GhostDiagrams = { start = 640000, End = 649999 },
    GhostSkin = { start = 1070000, End = 1119999 },
    RoleSkin = { start = 1132000, End = 1281999 },

    EItemSmallType = {
        Coin = 1,
        Piece = 2,
        EffectCard = 3,
        Book = 4,
        CostItem = 5,
        MonsterSoul = 6,
        TempCard = 7,
        PlayItem = 8,
        GrowthItem = 9,
        StackMagicItem = 10,
        GhostSkillBook = 11,
        HumanStackDiagrams = 12,
        GhostStackDiagrams = 13,
        HumanTabooWord = 14,
        GhostTabooWord = 15,
        Gift = 16,
        DurabItem = 17,
        MagicItem = 18,
        Antique = 19,
        HumanDiagrams = 20,
        GhostDiagrams = 21,
        RoleSkin = 22,
        GhostSkin = 23,
        Other = 255,
    },

    EItemBigType = {
        Coin = 1,
        StackItem = 2,
        UnStackItem = 3,
        UniqueItem = 4,
        Skin = 5,
        Other = 255,
    },

    ItemBagType = {
        ALL = 1,
        Consume = 2,
    },
}

function ItemDefine.GetItemType(nConfigId)
    if nConfigId >= ItemDefine.Coin.start and nConfigId <= ItemDefine.Coin.End then
        return ItemDefine.EItemSmallType.Coin
    elseif nConfigId >= ItemDefine.Piece.start and nConfigId <= ItemDefine.Piece.End then
        return ItemDefine.EItemSmallType.Piece
    elseif nConfigId >= ItemDefine.EffectCard.start and nConfigId <= ItemDefine.EffectCard.End then
        return ItemDefine.EItemSmallType.EffectCard
    elseif nConfigId >= ItemDefine.Book.start and nConfigId <= ItemDefine.Book.End then
        return ItemDefine.EItemSmallType.Book
    elseif nConfigId >= ItemDefine.CostItem.start and nConfigId <= ItemDefine.CostItem.End then
        return ItemDefine.EItemSmallType.CostItem
    elseif nConfigId >= ItemDefine.MonsterSoul.start and nConfigId <= ItemDefine.MonsterSoul.End then
        return ItemDefine.EItemSmallType.MonsterSoul
    elseif nConfigId >= ItemDefine.TempCard.start and nConfigId <= ItemDefine.TempCard.End then
        return ItemDefine.EItemSmallType.TempCard
    elseif nConfigId >= ItemDefine.PlayItem.start and nConfigId <= ItemDefine.PlayItem.End then
        return ItemDefine.EItemSmallType.PlayItem
    elseif nConfigId >= ItemDefine.GrowthItem.start and nConfigId <= ItemDefine.GrowthItem.End then
        return ItemDefine.EItemSmallType.GrowthItem
    elseif nConfigId >= ItemDefine.StackMagicItem.start and nConfigId <= ItemDefine.StackMagicItem.End then
        return ItemDefine.EItemSmallType.StackMagicItem
    elseif nConfigId >= ItemDefine.GhostSkillBook.start and nConfigId <= ItemDefine.GhostSkillBook.End then
        return ItemDefine.EItemSmallType.GhostSkillBook
    elseif nConfigId >= ItemDefine.HumanStackDiagrams.start and nConfigId <= ItemDefine.HumanStackDiagrams.End then
        return ItemDefine.EItemSmallType.HumanStackDiagrams
    elseif nConfigId >= ItemDefine.GhostStackDiagrams.start and nConfigId <= ItemDefine.GhostStackDiagrams.End then
        return ItemDefine.EItemSmallType.GhostStackDiagrams
    elseif nConfigId >= ItemDefine.HumanTabooWord.start and nConfigId <= ItemDefine.HumanTabooWord.End then
        return ItemDefine.EItemSmallType.HumanTabooWord
    elseif nConfigId >= ItemDefine.GhostTabooWord.start and nConfigId <= ItemDefine.GhostTabooWord.End then
        return ItemDefine.EItemSmallType.GhostTabooWord
    elseif nConfigId >= ItemDefine.Gift.start and nConfigId <= ItemDefine.Gift.End then
        return ItemDefine.EItemSmallType.Gift
    elseif nConfigId >= ItemDefine.DurabItem.start and nConfigId <= ItemDefine.DurabItem.End then
        return ItemDefine.EItemSmallType.DurabItem
    elseif nConfigId >= ItemDefine.MagicItem.start and nConfigId <= ItemDefine.MagicItem.End then
        return ItemDefine.EItemSmallType.MagicItem
    elseif nConfigId >= ItemDefine.Antique.start and nConfigId <= ItemDefine.Antique.End then
        return ItemDefine.EItemSmallType.Antique
    elseif nConfigId >= ItemDefine.HumanDiagrams.start and nConfigId <= ItemDefine.HumanDiagrams.End then
        return ItemDefine.EItemSmallType.HumanDiagrams
    elseif nConfigId >= ItemDefine.GhostDiagrams.start and nConfigId <= ItemDefine.GhostDiagrams.End then
        return ItemDefine.EItemSmallType.GhostDiagrams
    elseif nConfigId >= ItemDefine.RoleSkin.start and nConfigId <= ItemDefine.RoleSkin.End then
        return ItemDefine.EItemSmallType.RoleSkin
    elseif nConfigId >= ItemDefine.GhostSkin.start and nConfigId <= ItemDefine.GhostSkin.End then
        return ItemDefine.EItemSmallType.GhostSkin
    else
        moon.error("GetItemType - unknown config_id:", nConfigId)
        return ItemDefine.EItemSmallType.Other
    end
end

function ItemDefine.GetItemPosType(nConfigId)
    local nItemType = ItemDefine.GetItemType(nConfigId)
    if nItemType == ItemDefine.EItemSmallType.Coin then
        return ItemDefine.EItemBigType.Coin
    elseif nItemType >= ItemDefine.EItemSmallType.Piece
        and nItemType <= ItemDefine.EItemSmallType.Gift then
        return ItemDefine.EItemBigType.StackItem
    elseif nItemType == ItemDefine.EItemSmallType.DurabItem then
        return ItemDefine.EItemBigType.UnStackItem
    elseif nItemType >= ItemDefine.EItemSmallType.MagicItem
        and nItemType <= ItemDefine.EItemSmallType.GhostDiagrams then
        return ItemDefine.EItemBigType.UniqueItem
    elseif nItemType >= ItemDefine.EItemSmallType.RoleSkin
        and nItemType <= ItemDefine.EItemSmallType.GhostSkin then
        return ItemDefine.EItemBigType.Skin
    else
        moon.error("GetItemPosType - unknown config_id:", nConfigId)
        return ItemDefine.EItemBigType.Other
    end
end

function ItemDefine.GetItemBagType(nConfigId)
    if (nConfigId >= ItemDefine.CostItem.start and nConfigId <= ItemDefine.CostItem.End)
        or (nConfigId >= ItemDefine.DurabItem.start and nConfigId <= ItemDefine.DurabItem.End) then
        return ItemDefine.ItemBagType.Consume
    end

    return ItemDefine.ItemBagType.ALL
end

-- 从配置map中获取道具map,货币map
-- param item_cfg = {[1] = 1}
-- return items = {[1] = {id = 1, count = 1, pos = 0}}
-- return coins = {[1] = {coin_id = 1, coin_count = 1}}
function ItemDefine.GetItemsFromCfg(item_cfg, num, negative, items, coins)
    if not item_cfg then
        return false
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
    return true
end

-- 合并道具和货币map转换为添加的简化数组
-- param items = {[1] = {id = 1, count = 1, pos = 0}}
-- param coins = {[1] = {coin_id = 1, coin_count = 1}}
-- return add_list = {{id = 1, count = 1}, {id = 2, count = 1}}
function ItemDefine.GetItemListFromItemsCoins(items, coins, add_list)
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

-- 根据道具货币简化数组生成可堆叠道具map，不可堆叠道具数组，货币map
-- param item_list = {{id = 1, count = 1}, {id = 2, count = 1}}
-- return stack_items = {[PBItemData.common_info.config_id] = PBItemData}
-- return unstack_items = {PBItemData, PBItemData}
-- return stack_coins = {[PBCoin.coin_id] = PBCoin}
function ItemDefine.GetItemDataFromIdCount(item_list, coin_list, stack_items, unstack_items, stack_coins)
    if item_list and table.size(item_list) > 0 then
        for _, item in pairs(item_list) do
            if not item.id or not item.count or item.count == 0 then
                return false
            end
            local item_big_type = ItemDefine.GetItemPosType(item.id)
            if item_big_type == ItemDefine.EItemBigType.Coin then
                if not stack_coins[item.id] then
                    local new_coin = ItemDef.newCoin()
                    new_coin.coin_id = item.id
                    stack_coins[item.id] = new_coin
                end
                stack_coins[item.id].coin_count = stack_coins[item.id].coin_count + item.count
            elseif item_big_type == ItemDefine.EItemBigType.StackItem then
                if not stack_items[item.id] then
                    local item_cfg = GameCfg.Item[item.id]
                    if not item_cfg then
                        return false
                    end
                    local item_type = ItemDefine.GetItemBagType(item.id)

                    local new_item = ItemDef.newItemData()
                    new_item.itype = item_type
                    new_item.common_info.config_id = item_cfg.id
                    new_item.common_info.item_type = item_cfg.type1
                    new_item.common_info.trade_cnt = -1
                    stack_items[item.id] = new_item
                end
                stack_items[item.id].common_info.item_count = stack_items[item.id].common_info.item_count + item.count
            elseif item_big_type == ItemDefine.EItemBigType.UnStackItem then
                local item_cfg = GameCfg.Item[item.id]
                if not item_cfg then
                    return false
                end
                local item_type = ItemDefine.GetItemBagType(item.id)

                local new_item = ItemDef.newItemData()
                new_item.itype = item_type
                new_item.common_info.config_id = item_cfg.id
                if item.uniqid then
                    new_item.common_info.uniqid = item.uniqid
                end
                new_item.common_info.item_count = item.count
                new_item.common_info.item_type = item_cfg.type1
                new_item.common_info.trade_cnt = -1
                if item.trade_cnt then
                    new_item.common_info.trade_cnt = item.trade_cnt
                end
                new_item.special_info.durab_item = ItemDef.newDurabItem()
                if item.special_info and item.special_info.durab_item then
                    if item.special_info.durab_item.cur_durability then
                        new_item.special_info.durab_item.cur_durability = item.special_info.durab_item.cur_durability
                    end
                    if item.special_info.durab_item.strong_value then
                        new_item.special_info.durab_item.strong_value = item.special_info.durab_item.strong_value
                    end
                end
                table.insert(unstack_items, new_item)
            elseif item_big_type == ItemDefine.EItemBigType.UniqueItem then
                local uniqitem_cfg = GameCfg.UniqueItem[item.id]
                if not uniqitem_cfg then
                    return false
                end
                local item_type = ItemDefine.GetItemBagType(item.id)

                local new_item = ItemDef.newItemData()
                new_item.itype = item_type
                new_item.common_info.config_id = uniqitem_cfg.id
                if item.uniqid then
                    new_item.common_info.uniqid = item.uniqid
                end
                new_item.common_info.item_count = item.count
                new_item.common_info.item_type = uniqitem_cfg.type1
                new_item.common_info.trade_cnt = -1
                if item.trade_cnt then
                    new_item.common_info.trade_cnt = item.trade_cnt
                end

                local item_small_type = ItemDefine.GetItemType(item.id)
                if item_small_type == ItemDefine.EItemSmallType.HumanDiagrams
                    or item_small_type == ItemDefine.EItemSmallType.GhostDiagrams then
                    new_item.special_info.diagrams_item = ItemDef.newDiagramsCard()
                    if item.special_info and item.special_info.diagrams_item then
                        if item.special_info.diagrams_item.cur_durability then
                            new_item.special_info.diagrams_item.cur_durability = item.special_info.diagrams_item
                                .cur_durability
                        end
                        if item.special_info.diagrams_item.strong_value then
                            new_item.special_info.diagrams_item.strong_value = item.special_info.diagrams_item
                                .strong_value
                        end
                        if item.special_info.diagrams_item.tabooword_id then
                            new_item.special_info.diagrams_item.tabooword_id = item.special_info.diagrams_item
                                .tabooword_id
                        end
                        if item.special_info.diagrams_item.light_cnt then
                            new_item.special_info.diagrams_item.light_cnt = item.special_info.diagrams_item.light_cnt
                        end
                        if item.special_info.diagrams_item.tags then
                            new_item.special_info.diagrams_item.tags = item.special_info.diagrams_item.tags
                        end
                        if item.special_info.diagrams_item.ability_tag then
                            new_item.special_info.diagrams_item.ability_tag = item.special_info.diagrams_item
                                .ability_tag
                        end
                    end
                    table.insert(unstack_items, new_item)
                elseif item_small_type == ItemDefine.EItemSmallType.MagicItem then
                    new_item.special_info.magic_item = ItemDef.newMagicItem()
                    if item.special_info and item.special_info.magic_item then
                        if item.special_info.magic_item.cur_durability then
                            new_item.special_info.magic_item.cur_durability = item.special_info.magic_item
                                .cur_durability
                        end
                        if item.special_info.magic_item.strong_value then
                            new_item.special_info.magic_item.strong_value = item.special_info.magic_item.strong_value
                        end
                        if item.special_info.magic_item.tabooword_id then
                            new_item.special_info.magic_item.tabooword_id = item.special_info.magic_item.tabooword_id
                        end
                        if item.special_info.magic_item.light_cnt then
                            new_item.special_info.magic_item.light_cnt = item.special_info.magic_item.light_cnt
                        end
                        if item.special_info.magic_item.tags then
                            new_item.special_info.magic_item.tags = item.special_info.magic_item.tags
                        end
                        if item.special_info.magic_item.ability_tag then
                            new_item.special_info.magic_item.ability_tag = item.special_info.magic_item.ability_tag
                        end
                    end
                    table.insert(unstack_items, new_item)
                end
            end
        end
    end

    if coin_list and table.size(coin_list) > 0 then
        for _, coin in pairs(coin_list) do
            if not coin.coin_id or not coin.coin_count or coin.coin_count == 0 then
                return false
            end
            local item_big_type = ItemDefine.GetItemPosType(coin.coin_id)
            if item_big_type == ItemDefine.EItemBigType.Coin then
                if not stack_coins[coin.coin_id] then
                    local new_coin = ItemDef.newCoin()
                    new_coin.coin_id = coin.coin_id
                    stack_coins[coin.coin_id] = new_coin
                end
                stack_coins[coin.coin_id].coin_count = stack_coins[coin.coin_id].coin_count + coin.coin_count
            else
                return false
            end
        end
    end

    return true
end

return ItemDefine
