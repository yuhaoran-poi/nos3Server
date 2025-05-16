local moon = require "moon"
local common = require "common"
local uuid = require "uuid"
local GameCfg = common.GameCfg
local ErrorCode = common.ErrorCode
local CmdCode = common.CmdCode
local Database = common.Database
--local ItemImageDef = require("common.def.ItemImageDef")

---@type user_context
local context = ...
local scripts = context.scripts

local ItemImageDefine = {
    ItemImageID = { Start = 1017000, End = 1017999 },
    ItemImageSkin = { Start = 1070000, End = 1119999 },
}

---@class ItemImage
local ItemImage = {}

function ItemImage.Init()
    
end

function ItemImage.Start()
    --加载全部角色数据
    local itemImageinfos = ItemImage.LoadItemImages()
    if itemImageinfos then
        scripts.UserModel.SetItemImages(itemImageinfos)
    end

    -- local itemImages = scripts.UserModel.GetItemImages()
    -- if not itemImages then
    --     itemImages = ItemImageDef.newUserItemImageDatas()

    --     scripts.UserModel.SetItemImages(itemImages)
    --     ItemImage.SaveItemImagesNow()
    -- end

    return { code = ErrorCode.None }
end

function ItemImage.SaveItemImagesNow()
    -- local itemImages = scripts.UserModel.GetItemImages()
    -- if not itemImages then
    --     return false
    -- end

    -- local success = Database.saveuseritemImages(context.addr_db_user, context.uid, itemImages)
    -- return success
end

function ItemImage.LoadItemImages()
    -- local itemImageinfos = Database.loaduseritemimage(context.addr_db_user, context.uid)
    -- return itemImageinfos
end

function ItemImage.AddMagicItemImage(config_id)
    -- local itemImages = scripts.UserModel.GetItemImages()
    -- if not itemImages then
    --     return false
    -- end

    -- if not itemImages.magic_item_image[config_id] then
    --     local itemImage_info = ItemImageDef.newImage()
    --     itemImage_info.config_id = config_id
    --     itemImages.magic_item_image[config_id] = itemImage_info
    -- end

    return true
end

function ItemImage.AddDiagramsCardImage(config_id)
    -- local itemImages = scripts.UserModel.GetItemImages()
    -- if not itemImages then
    --     return false
    -- end

    -- local item_type = scripts.ItemDefine.GetItemType(config_id)

    -- if item_type == scripts.ItemDefine.EItemSmallType.HumanDiagrams then
    --     if not itemImages.human_diagrams_image[config_id] then
    --         local itemImage_info = ItemImageDef.newImage()
    --         itemImage_info.config_id = config_id
    --         itemImages.human_diagrams_image[config_id] = itemImage_info
    --     end
    -- elseif item_type == scripts.ItemDefine.EItemSmallType.GhostDiagrams then
    --     if not itemImages.ghost_diagrams_image[config_id] then
    --         local itemImage_info = ItemImageDef.newImage()
    --         itemImage_info.config_id = config_id
    --         itemImages.ghost_diagrams_image[config_id] = itemImage_info
    --     end
    -- else
    --     return false
    -- end

    return true
end

return ItemImage