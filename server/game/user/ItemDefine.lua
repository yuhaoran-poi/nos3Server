local moon = require("moon")
local common = require("common")
local Database = common.Database

---@type user_context
local context = ...

---@class ItemDefine
---@field public EItemSmallType table
---@field public EItemBigType table
---@field public ItemBagType table
---@field public GetItemType fun(nConfigId: number): number
---@field public GetItemPosType fun(nConfigId: number): number
---@field public GetItemBagType fun(nConfigId: number): number

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
    GhostSkillBook = { start = 95000, End = 95999 },
    HumanTabooWord = { start = 116000, End = 119999 },
    GhostTabooWord = { start = 120000, End = 123999 },
    Gift = { start = 320000, End = 329999 },
    DurabItem = { start = 500000, End = 500999 },
    HumanDiagrams = { start = 524000, End = 533999 },
    GhostDiagrams = { start = 534000, End = 543999 },
    MagicItem = { start = 600000, End = 619999 },
    Antique = { start = 620000, End = 624999 },

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
        GhostSkillBook = 10,
        HumanTabooWord = 11,
        GhostTabooWord = 12,
        Gift = 13,
        DurabItem = 14,
        HumanDiagrams = 15,
        GhostDiagrams = 16,
        MagicItem = 17,
        Antique = 18,
        Other = 255,
    },

    EItemBigType = {
        Coin = 1,
        StackItem = 2,
        UnStackItem = 3,
        UniqueItem = 4,
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
    elseif nConfigId >= ItemDefine.GhostSkillBook.start and nConfigId <= ItemDefine.GhostSkillBook.End then
        return ItemDefine.EItemSmallType.GhostSkillBook
    elseif nConfigId >= ItemDefine.HumanTabooWord.start and nConfigId <= ItemDefine.HumanTabooWord.End then
        return ItemDefine.EItemSmallType.HumanTabooWord
    elseif nConfigId >= ItemDefine.GhostTabooWord.start and nConfigId <= ItemDefine.GhostTabooWord.End then
        return ItemDefine.EItemSmallType.GhostTabooWord
    elseif nConfigId >= ItemDefine.Gift.start and nConfigId <= ItemDefine.Gift.End then
        return ItemDefine.EItemSmallType.Gift
    elseif nConfigId >= ItemDefine.DurabItem.start and nConfigId <= ItemDefine.DurabItem.End then
        return ItemDefine.EItemSmallType.DurabItem
    elseif nConfigId >= ItemDefine.HumanDiagrams.start and nConfigId <= ItemDefine.HumanDiagrams.End then
        return ItemDefine.EItemSmallType.HumanDiagrams
    elseif nConfigId >= ItemDefine.GhostDiagrams.start and nConfigId <= ItemDefine.GhostDiagrams.End then
        return ItemDefine.EItemSmallType.GhostDiagrams
    elseif nConfigId >= ItemDefine.MagicItem.start and nConfigId <= ItemDefine.MagicItem.End then
        return ItemDefine.EItemSmallType.MagicItem
    elseif nConfigId >= ItemDefine.Antique.start and nConfigId <= ItemDefine.Antique.End then
        return ItemDefine.EItemSmallType.Antique
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
    elseif nItemType >= ItemDefine.EItemSmallType.HumanDiagrams
        and nItemType <= ItemDefine.EItemSmallType.Antique then
        return ItemDefine.EItemBigType.UniqueItem
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

return ItemDefine