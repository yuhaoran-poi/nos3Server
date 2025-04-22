local moon = require("moon")
local common = require("common")
local Database = common.Database

---@type user_context
local context = ...

---@class ItemDefine
local ItemDefine = {
    Map = { start = 5000, End = 5999 },
    Debris = { start = 20000, End = 29999 },
    EffectCard = { start = 30000, End = 30999 },
    Book = { start = 31000, End = 33999 },
    CostItem = { start = 34000, End = 34999 },
    MonsterSoul = { start = 35000, End = 36999 },
    TempCard = { start = 37000, End = 39999 },
    PlayItem = { start = 40000, End = 40999 },
    SecretPaper = { start = 41000, End = 50999 },
    MagicItem_Stack = { start = 51000, End = 90999 },
    GrowthItem = { start = 91000, End = 91999 },
    MinorStar = { start = 92000, End = 92099 },
    GhostSkillBook = { start = 95000, End = 95999 },
    Diagrams_Stack = { start = 96000, End = 115999 },
    TabooWord = { start = 116000, End = 123999 },
    Gift = { start = 320000, End = 329999 },
    MagicItem = { start = 500000, End = 519999 },
    Trigram = { start = 520500, End = 520599 },
    SealMonster = { start = 521000, End = 521999 },
    MonsterEquip = { start = 522000, End = 522999 },
    Antique = { start = 523000, End = 523999 },
    Diagrams = { start = 524000, End = 543999 },
    HumanRole = { start = 1000000, End = 1000999 },
    MainStar = { start = 1001000, End = 1003999 },
    MainStar_Effect = { start = 1004000, End = 1012999 },
    StarSymbol = { start = 1013000, End = 1014999 },
    Title = { start = 1015000, End = 1015999 },
    AweItem = { start = 1016000, End = 1016499 },
    Gods = { start = 1016500, End = 1016599 },
    SealMonster_Skin = { start = 1017000, End = 1036999 },
    TreasureBox = { start = 300000, End = 309999 },
    Skin = { start = 1020000, End = 1419999 }
}

function ItemDefine.GetItemType(nConfigId)
    if nConfigId >= ItemDefine.Map.start and nConfigId <= ItemDefine.Map.End then
        return "Map"
    elseif nConfigId >= ItemDefine.Debris.start and nConfigId <= ItemDefine.Debris.End then
        return "Debris"
    elseif nConfigId >= ItemDefine.EffectCard.start and nConfigId <= ItemDefine.EffectCard.End then
        return "EffectCard"
    elseif nConfigId >= ItemDefine.Book.start and nConfigId <= ItemDefine.Book.End then
        return "Book"
    elseif nConfigId >= ItemDefine.CostItem.start and nConfigId <= ItemDefine.CostItem.End then
        return "CostItem"
    elseif nConfigId >= ItemDefine.MonsterSoul.start and nConfigId <= ItemDefine.MonsterSoul.End then
        return "MonsterSoul"
    elseif nConfigId >= ItemDefine.TempCard.start and nConfigId <= ItemDefine.TempCard.End then
        return "TempCard"
    elseif nConfigId >= ItemDefine.PlayItem.start and nConfigId <= ItemDefine.PlayItem.End then
        return "PlayItem"
    elseif nConfigId >= ItemDefine.SecretPaper.start and nConfigId <= ItemDefine.SecretPaper.End then
        return "SecretPaper"
    elseif nConfigId >= ItemDefine.MagicItem_Stack.start and nConfigId <= ItemDefine.MagicItem_Stack.End then
        return "MagicItem_Stack"
    elseif nConfigId >= ItemDefine.GrowthItem.start and nConfigId <= ItemDefine.GrowthItem.End then
        return "GrowthItem"
    elseif nConfigId >= ItemDefine.MinorStar.start and nConfigId <= ItemDefine.MinorStar.End then
        return "MinorStar"
    elseif nConfigId >= ItemDefine.GhostSkillBook.start and nConfigId <= ItemDefine.GhostSkillBook.End then
        return "GhostSkillBook"
    elseif nConfigId >= ItemDefine.Diagrams_Stack.start and nConfigId <= ItemDefine.Diagrams_Stack.End then
        return "Diagrams_Stack"
    elseif nConfigId >= ItemDefine.TabooWord.start and nConfigId <= ItemDefine.TabooWord.End then
        return "TabooWord"
    elseif nConfigId >= ItemDefine.Gift.start and nConfigId <= ItemDefine.Gift.End then
        return "Gift"
    elseif nConfigId >= ItemDefine.MagicItem.start and nConfigId <= ItemDefine.MagicItem.End then
        return "MagicItem"
    elseif nConfigId >= ItemDefine.Trigram.start and nConfigId <= ItemDefine.Trigram.End then
        return "Trigram"
    elseif nConfigId >= ItemDefine.SealMonster.start and nConfigId <= ItemDefine.SealMonster.End then
        return "SealMonster"
    elseif nConfigId >= ItemDefine.MonsterEquip.start and nConfigId <= ItemDefine.MonsterEquip.End then
        return "MonsterEquip"
    elseif nConfigId >= ItemDefine.Antique.start and nConfigId <= ItemDefine.Antique.End then
        return "Antique"
    elseif nConfigId >= ItemDefine.Diagrams.start and nConfigId <= ItemDefine.Diagrams.End then
        return "Diagrams"
    elseif nConfigId >= ItemDefine.HumanRole.start and nConfigId <= ItemDefine.HumanRole.End then
        return "HumanRole"
    elseif nConfigId >= ItemDefine.MainStar.start and nConfigId <= ItemDefine.MainStar.End then
        return "MainStar"
    elseif nConfigId >= ItemDefine.MainStar_Effect.start and nConfigId <= ItemDefine.MainStar_Effect.End then
        return "MainStar_Effect"
    elseif nConfigId >= ItemDefine.StarSymbol.start and nConfigId <= ItemDefine.StarSymbol.End then
        return "StarSymbol"
    elseif nConfigId >= ItemDefine.Title.start and nConfigId <= ItemDefine.Title.End then
        return "Title"
    elseif nConfigId >= ItemDefine.AweItem.start and nConfigId <= ItemDefine.AweItem.End then
        return "AweItem"
    elseif nConfigId >= ItemDefine.Gods.start and nConfigId <= ItemDefine.Gods.End then
        return "Gods"
    elseif nConfigId >= ItemDefine.SealMonster_Skin.start and nConfigId <= ItemDefine.SealMonster_Skin.End then
        return "SealMonster_Skin"
    elseif nConfigId >= ItemDefine.TreasureBox.start and nConfigId <= ItemDefine.TreasureBox.End then
        return "TreasureBox"
    elseif nConfigId >= ItemDefine.Skin.start and nConfigId <= ItemDefine.Skin.End then
        return "Skin"
    else
        moon.error("GetItemType - unknown config_id:", nConfigId)
        return "Unknown"
    end
end

return ItemDefine