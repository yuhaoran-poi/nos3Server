local moon = require "moon"
local common = require "common"
local uuid = require "uuid"
local GameCfg = common.GameCfg
local ErrorCode = common.ErrorCode
local CmdCode = common.CmdCode
local Database = common.Database
local BagDef = require("common.def.BagDef")
local ItemDef = require("common.def.ItemDef")
local ItemDefine = require("common.logic.ItemDefine")

---@type user_context
local context = ...
local scripts = context.scripts

-- local ItemImageDefine = {
--     ItemImageID = { Start = 1017000, End = 1017999 },
--     ItemImageSkin = { Start = 1070000, End = 1119999 },
-- }

---@class ItemImage
local ItemImage = {}

function ItemImage.Init()
    
end

function ItemImage.Start()
    --加载全部图鉴数据
    local itemImageinfos = ItemImage.LoadItemImages()
    if itemImageinfos then
        scripts.UserModel.SetItemImages(itemImageinfos)
    end

    local itemImages = scripts.UserModel.GetItemImages()
    if not itemImages then
        itemImages = ItemDef.newUserImage()

        scripts.UserModel.SetItemImages(itemImages)
        ItemImage.SaveItemImagesNow()
    end

    -- return { code = ErrorCode.None }
end

function ItemImage.SaveItemImagesNow()
    local itemImages = scripts.UserModel.GetItemImages()
    if not itemImages then
        return false
    end

    local success = Database.saveuseritemimage(context.addr_db_user, context.uid, itemImages)
    return success
end

function ItemImage.LoadItemImages()
    local itemImageinfos = Database.loaduseritemimage(context.addr_db_user, context.uid)
    return itemImageinfos
end

function ItemImage.SaveAndLog(config_ids)
    local itemImages = scripts.UserModel.GetItemImages()
    if not itemImages then
        return false
    end
    
    local update_msg = {
        update_images = {},
    }
    for _, config_id in pairs(config_ids) do
        local item_type = ItemDefine.GetItemType(config_id)
        if item_type == ItemDefine.EItemSmallType.MagicItem then
            if itemImages.magic_item_image[config_id] then
                if not update_msg.update_images.magic_item_image then
                    update_msg.update_images.magic_item_image = {}
                end
                update_msg.update_images.magic_item_image[config_id] = itemImages.magic_item_image[config_id]
            end
        elseif item_type == ItemDefine.EItemSmallType.HumanDiagrams then
            if itemImages.human_diagrams_image[config_id] then
                if not update_msg.update_images.human_diagrams_image then
                    update_msg.update_images.human_diagrams_image = {}
                end
                update_msg.update_images.human_diagrams_image[config_id] = itemImages.human_diagrams_image[config_id]
            end
        elseif item_type == ItemDefine.EItemSmallType.GhostDiagrams then
            if itemImages.ghost_diagrams_image[config_id] then
                if not update_msg.update_images.ghost_diagrams_image then
                    update_msg.update_images.ghost_diagrams_image = {}
                end
                update_msg.update_images.ghost_diagrams_image[config_id] = itemImages.ghost_diagrams_image[config_id]
            end
        elseif item_type == ItemDefine.EItemSmallType.RoleSkin
            or item_type == ItemDefine.EItemSmallType.GhostSkin then
            if not update_msg.update_images.skin_image then
                update_msg.update_images.skin_image = {}
            end
            update_msg.update_images.skin_image[config_id] = itemImages.skin_image[config_id]
        else
            if itemImages.item_image[config_id] then
                if not update_msg.update_images.item_image then
                    update_msg.update_images.item_image = {}
                end
                update_msg.update_images.item_image[config_id] = itemImages.item_image[config_id]
            end
        end
    end

    context.S2C(context.net_id, CmdCode["PBImageUpdateSyncCmd"], update_msg, 0)

    ItemImage.SaveItemImagesNow()
end

-- map<int32, PBImage> item_image				= 1;	//道具图鉴	有key则执行覆盖
-- map<int32, PBImage> magic_item_image		= 2;	//法器图鉴	有key则执行覆盖
-- map<int32, PBImage> human_diagrams_image	= 3;	//角色八卦牌图鉴	有key则执行覆盖
-- map<int32, PBImage> ghost_diagrams_image	= 4;	//鬼宠八卦牌图鉴	有key则执行覆盖
-- map<int32, PBSkinImage> skin_image			= 5;	//皮肤动作表情图鉴	有key则执行覆盖
function ItemImage.AddItemImage(config_id, change_image_ids)
    local itemImages = scripts.UserModel.GetItemImages()
    if not itemImages then
        return false
    end

    local item_type = ItemDefine.GetItemType(config_id)
    if item_type == ItemDefine.EItemSmallType.MagicItem then
        if not itemImages.magic_item_image[config_id] then
            local itemImage_info = ItemDef.newImage()
            itemImage_info.config_id = config_id
            itemImages.magic_item_image[config_id] = itemImage_info

            table.insert(change_image_ids, config_id)
        end
    elseif item_type == ItemDefine.EItemSmallType.HumanDiagrams then
        if not itemImages.human_diagrams_image[config_id] then
            local itemImage_info = ItemDef.newImage()
            itemImage_info.config_id = config_id
            itemImages.human_diagrams_image[config_id] = itemImage_info

            table.insert(change_image_ids, config_id)
        end
    elseif item_type == ItemDefine.EItemSmallType.GhostDiagrams then
        if not itemImages.ghost_diagrams_image[config_id] then
            local itemImage_info = ItemDef.newImage()
            itemImage_info.config_id = config_id
            itemImages.ghost_diagrams_image[config_id] = itemImage_info

            table.insert(change_image_ids, config_id)
        end
    elseif item_type == ItemDefine.EItemSmallType.RoleSkin
        or item_type == ItemDefine.EItemSmallType.GhostSkin then
        if not itemImages.skin_image[config_id] then
            local itemImage_info = ItemDef.newSkinImage()
            itemImage_info.config_id = config_id
            itemImages.skin_image[config_id] = itemImage_info

            table.insert(change_image_ids, config_id)
        end
    elseif item_type == ItemDefine.EItemSmallType.PlayItem
        or item_type == ItemDefine.EItemSmallType.DurabItem then
        if not itemImages.item_image[config_id] then
            local itemImage_info = ItemDef.newImage()
            itemImage_info.config_id = config_id
            itemImages.item_image[config_id] = itemImage_info

            table.insert(change_image_ids, config_id)
        end
    end

    return true
end

function ItemImage.GetImage(config_id)
    local itemImages = scripts.UserModel.GetItemImages()
    if not itemImages then
        return false
    end

    local item_type = ItemDefine.GetItemType(config_id)
    if item_type == ItemDefine.EItemSmallType.MagicItem then
        return itemImages.magic_item_image[config_id], item_type
    elseif item_type == ItemDefine.EItemSmallType.HumanDiagrams then
        return itemImages.human_diagrams_image[config_id], item_type
    elseif item_type == ItemDefine.EItemSmallType.GhostDiagrams then
        return itemImages.ghost_diagrams_image[config_id], item_type
    elseif item_type == ItemDefine.EItemSmallType.RoleSkin
        or item_type == ItemDefine.EItemSmallType.GhostSkin then
        return itemImages.skin_image[config_id], item_type
    else
        return itemImages.item_image[config_id], item_type
    end
end

function ItemImage.UpLvImage(config_id, add_exp)
    local image_data, item_type = ItemImage.GetImage(config_id)
    if not image_data then
        return ErrorCode.ItemNotExist
    end

    local function check_add_exp(up_exp_cfgs, exps, remain_exp)
        for _, cfg in pairs(up_exp_cfgs) do
            if cfg.allexp > image_data.exp then
                if image_data.exp + add_exp >= cfg.allexp then
                    local canAdd = math.min(cfg.allexp - image_data.exp, remain_exp)
                    if not exps[cfg.cost] then
                        exps[cfg.cost] = 0
                    end
                    exps[cfg.cost] = exps[cfg.cost] + canAdd
                    remain_exp = remain_exp - canAdd
                else
                    if not exps[cfg.cost] then
                        exps[cfg.cost] = 0
                    end
                    exps[cfg.cost] = exps[cfg.cost] + remain_exp
                    remain_exp = 0

                    break
                end
            end
        end

        return remain_exp
    end

    -- 检索加经验配置
    local exps = {}
    local remain_exp = add_exp
    if item_type == ItemDefine.EItemSmallType.MagicItem then
        local up_exp_cfgs = GameCfg.MagicItemUpLv
        if up_exp_cfgs then
            remain_exp = check_add_exp(up_exp_cfgs, exps, remain_exp)
        end
    elseif item_type == ItemDefine.EItemSmallType.PlayItem
        or item_type == ItemDefine.EItemSmallType.UnStackItem then
        local up_exp_cfgs = GameCfg.GamePropUpLv
        if up_exp_cfgs then
            remain_exp = check_add_exp(up_exp_cfgs, exps, remain_exp)
        end
    elseif item_type == ItemDefine.EItemSmallType.HumanDiagrams then
        local up_exp_cfgs = GameCfg.BaGuaBrandUpLv
        if up_exp_cfgs then
            remain_exp = check_add_exp(up_exp_cfgs, exps, remain_exp)
        end
    elseif item_type == ItemDefine.EItemSmallType.GhostDiagrams then
        local up_exp_cfgs = GameCfg.GhostEquipmentUpLv
        if up_exp_cfgs then
            remain_exp = check_add_exp(up_exp_cfgs, exps, remain_exp)
        end
    end

    if remain_exp > 0 or table.size(exps) <= 0 then
        return ErrorCode.ItemMaxExp
    end

    -- 计算消耗资源
    local cost_items = {}
    local cost_coins = {}
    for id, count in pairs(exps) do
        local cost_cfg = GameCfg.UpLvCostIDMapping[id]
        if not cost_cfg then
            return ErrorCode.ItemUpLvCostNotExist
        end

        ItemDefine.GetItemsFromCfg(cost_cfg, (count / cost_cfg.cnt), true, cost_items, cost_coins)
    end

    -- 检查资源是否足够
    local err_code_items = scripts.Bag.CheckItemsEnough(BagDef.BagType.Cangku, cost_items, {})
    if err_code_items ~= ErrorCode.None then
        return err_code_items
    end
    local err_code_coins = scripts.Bag.CheckCoinsEnough(cost_coins)
    if err_code_coins ~= ErrorCode.None then
        return err_code_coins
    end

    -- 增加经验
    local new_exp = image_data.exp + add_exp
    image_data.exp = new_exp

    -- 扣除消耗
    local change_log = {}
    local err_code_del = ErrorCode.None
    if table.size(cost_items) > 0 then
        err_code_del = scripts.Bag.DelItems(BagDef.BagType.Cangku, cost_items, {}, change_log)
        if err_code_del ~= ErrorCode.None then
            scripts.Bag.RollBackWithChange(change_log)
            return err_code_del
        end
    end
    if table.size(cost_coins) > 0 then
        err_code_del = scripts.Bag.DealCoins(cost_coins, change_log)
        if err_code_del ~= ErrorCode.None then
            scripts.Bag.RollBackWithChange(change_log)
            return err_code_del
        end
    end

    return ErrorCode.None, change_log
end

function ItemImage.CheckUseItemUpLv(config_id, exp_id, exp_cnt)
    local image_data, item_type = ItemImage.GetImage(config_id)
    if not image_data then
        return ErrorCode.ItemNotExist
    end

    local function check_add_exp(up_exp_cfgs, cur_exp, after_up_exp)
        for _, cfg in pairs(up_exp_cfgs) do
            if image_data.exp < cfg.allexp and after_up_exp >= cfg.allexp then
                if cfg.cost ~= exp_id then
                    return ErrorCode.ConfigError
                end
            end

            if after_up_exp < cfg.allexp then
                return ErrorCode.None
            end
        end

        return ErrorCode.ItemMaxExp
    end

    local after_up_exp = image_data.exp + exp_cnt
    if item_type == ItemDefine.EItemSmallType.MagicItem then
        local up_exp_cfgs = GameCfg.MagicItemUpLv
        local err_code = check_add_exp(up_exp_cfgs, image_data.exp, after_up_exp)
        if err_code ~= ErrorCode.None then
            return err_code
        end
    elseif item_type == ItemDefine.EItemSmallType.PlayItem
        or item_type == ItemDefine.EItemSmallType.UnStackItem then
        local up_exp_cfgs = GameCfg.GamePropUpLv
        local err_code = check_add_exp(up_exp_cfgs, image_data.exp, after_up_exp)
        if err_code ~= ErrorCode.None then
            return err_code
        end
    elseif item_type == ItemDefine.EItemSmallType.HumanDiagrams then
        local up_exp_cfgs = GameCfg.BaGuaBrandUpLv
        local err_code = check_add_exp(up_exp_cfgs, image_data.exp, after_up_exp)
        if err_code ~= ErrorCode.None then
            return err_code
        end
    elseif item_type == ItemDefine.EItemSmallType.GhostDiagrams then
        local up_exp_cfgs = GameCfg.GhostEquipmentUpLv
        local err_code = check_add_exp(up_exp_cfgs, image_data.exp, after_up_exp)
        if err_code ~= ErrorCode.None then
            return err_code
        end
    end
    
    -- image_data.exp = after_up_exp

    return ErrorCode.None
end

function ItemImage.UpExp(config_id, exp_cnt)
    local image_data, item_type = ItemImage.GetImage(config_id)
    if not image_data then
        return ErrorCode.ItemNotExist
    end

    image_data.exp = image_data.exp + exp_cnt

    return ErrorCode.None
end

function ItemImage.UpStarImage(config_id)
    local image_data, item_type = ItemImage.GetImage(config_id)
    if not image_data then
        return ErrorCode.ItemNotExist
    end
    
    local star_cfg = GameCfg.UpStar[image_data.config_id]
    if not star_cfg then
        return ErrorCode.ConfigError
    end
    if image_data.star_level >= star_cfg.maxlv then
        return ErrorCode.ItemMaxStar
    end

    local cost_key = "cost" .. (image_data.star_level + 1)
    if not star_cfg[cost_key] then
        return ErrorCode.ConfigError
    end
    local cost_cfg = star_cfg[cost_key]

    -- 计算消耗资源
    local cost_items = {}
    local cost_coins = {}
    ItemDefine.GetItemsFromCfg(cost_cfg, 1, true, cost_items, cost_coins)

    -- 检查资源是否足够
    local err_code_items = scripts.Bag.CheckItemsEnough(BagDef.BagType.Cangku, cost_items, {})
    if err_code_items ~= ErrorCode.None then
        return err_code_items
    end
    local err_code_coins = scripts.Bag.CheckCoinsEnough(cost_coins)
    if err_code_coins ~= ErrorCode.None then
        return err_code_coins
    end

    -- 增加星星
    image_data.star_level = image_data.star_level + 1

    -- 扣除消耗
    local change_log = {}
    local err_code_del = ErrorCode.None
    if table.size(cost_items) > 0 then
        err_code_del = scripts.Bag.DelItems(BagDef.BagType.Cangku, cost_items, {}, change_log)
        if err_code_del ~= ErrorCode.None then
            scripts.Bag.RollBackWithChange(change_log)
            return err_code_del
        end
    end
    if table.size(cost_coins) > 0 then
        err_code_del = scripts.Bag.DealCoins(cost_coins, change_log)
        if err_code_del ~= ErrorCode.None then
            scripts.Bag.RollBackWithChange(change_log)
            return err_code_del
        end
    end

    return ErrorCode.None, change_log
end

function ItemImage.GetImagesInfo()
    local itemImages = scripts.UserModel.GetItemImages()
    if not itemImages then
        return { errcode = ErrorCode.ServerInternalError }
    end

    return { errcode = ErrorCode.None, image_data = itemImages }
end

function ItemImage.PBImageGetDataReqCmd(req)
    local itemImages = scripts.UserModel.GetItemImages()
    if not itemImages then
        return context.S2C(context.net_id, CmdCode["PBImageGetDataRspCmd"], {code = ErrorCode.ServerInternalError, error = "服务器内部错误"}, req.msg_context.stub_id)
    end

    local res = {
        code = ErrorCode.None,
        error = "",
        uid = context.uid,
        image_data = itemImages,
    }
    return context.S2C(context.net_id, CmdCode["PBImageGetDataRspCmd"], res, req.msg_context.stub_id)
end

return ItemImage