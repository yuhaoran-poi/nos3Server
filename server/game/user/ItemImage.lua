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
local CommonCfgDef = require("common.def.CommonCfgDef")
local MissionDef = require("common.def.MissionDef")

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
    --加载全部图鉴数据
    local itemImageinfos = ItemImage.LoadItemImages()
    if itemImageinfos then
        scripts.UserModel.SetItemImages(itemImageinfos)
    end

    local itemImages = scripts.UserModel.GetItemImages()
    if not itemImages then
        itemImages = ItemDef.newUserImage()
        scripts.UserModel.SetItemImages(itemImages)
    end
end

function ItemImage.Start(isnew)
    local itemImages = scripts.UserModel.GetItemImages()
    if not itemImages then
        return false
    end
    
    if isnew then
        local init_cfg = GameCfg.Init[1]
        if init_cfg then
            for _, init_add_id in pairs(init_cfg.collection) do
                ItemImage.AddItemImage(init_add_id, {}, true)
            end
        end

        ItemImage.SaveItemImagesNow()
    end
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
            or item_type == ItemDefine.EItemSmallType.GhostSkin
            or item_type == ItemDefine.EItemSmallType.ItemSkin
            or item_type == ItemDefine.EItemSmallType.HeadSkin
            or item_type == ItemDefine.EItemSmallType.HeadFrameSkin
            or item_type == ItemDefine.EItemSmallType.TitleSkin then
            if not update_msg.update_images.skin_image then
                update_msg.update_images.skin_image = {}
            end
            update_msg.update_images.skin_image[config_id] = itemImages.skin_image[config_id]
        elseif item_type == ItemDefine.EItemSmallType.SpaceRing then
            if itemImages.space_ring_image[config_id] then
                if not update_msg.update_images.space_ring_image then
                    update_msg.update_images.space_ring_image = {}
                end
                update_msg.update_images.space_ring_image[config_id] = itemImages.space_ring_image[config_id]
            end
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

function ItemImage.GetSkinTypeCnt(itemImages)
    if not itemImages then
        itemImages = scripts.UserModel.GetItemImages()
        if not itemImages then
            return 0, 0
        end
    end

    if not itemImages.skin_image then
        return 0, 0
    end

    local role_cnt, item_cnt = 0, 0
    for config_id, skin in pairs(itemImages.skin_image) do
        if skin.valid_ts == 0 then
            local item_type = ItemDefine.GetItemType(config_id)
            if item_type == ItemDefine.EItemSmallType.RoleSkin then
                role_cnt = role_cnt + 1
            elseif item_type == ItemDefine.EItemSmallType.ItemSkin then
                item_cnt = item_cnt + 1
            end
        end
    end
    return role_cnt, item_cnt
end

-- map<int32, PBImage> item_image				= 1;	//道具图鉴	有key则执行覆盖
-- map<int32, PBImage> magic_item_image		= 2;	//法器图鉴	有key则执行覆盖
-- map<int32, PBImage> human_diagrams_image	= 3;	//角色八卦牌图鉴	有key则执行覆盖
-- map<int32, PBImage> ghost_diagrams_image	= 4;	//鬼宠八卦牌图鉴	有key则执行覆盖
-- map<int32, PBSkinImage> skin_image            = 5;    //皮肤动作表情图鉴    有key则执行覆盖
-- map<int32, PBImage> space_ring_image       = 6;    //空间戒指图鉴    有key则执行覆盖
function ItemImage.AddItemImage(config_id, change_image_ids, use_item)
    local itemImages = scripts.UserModel.GetItemImages()
    if not itemImages then
        return ErrorCode.ServerInternalError
    end

    local item_type = ItemDefine.GetItemType(config_id)
    if item_type == ItemDefine.EItemSmallType.MagicItem then
        if not itemImages.magic_item_image[config_id] then
            local itemImage_info = ItemDef.newImage()
            itemImage_info.config_id = config_id
            itemImages.magic_item_image[config_id] = itemImage_info

            table.insert(change_image_ids, config_id)
        else
            return ErrorCode.ItemImageExist
        end
    elseif item_type == ItemDefine.EItemSmallType.HumanDiagrams then
        if not itemImages.human_diagrams_image[config_id] then
            local itemImage_info = ItemDef.newImage()
            itemImage_info.config_id = config_id
            itemImages.human_diagrams_image[config_id] = itemImage_info

            table.insert(change_image_ids, config_id)
        else
            return ErrorCode.ItemImageExist
        end
    elseif item_type == ItemDefine.EItemSmallType.GhostDiagrams then
        if not itemImages.ghost_diagrams_image[config_id] then
            local itemImage_info = ItemDef.newImage()
            itemImage_info.config_id = config_id
            itemImages.ghost_diagrams_image[config_id] = itemImage_info

            table.insert(change_image_ids, config_id)
        else
            return ErrorCode.ItemImageExist
        end
    elseif (item_type == ItemDefine.EItemSmallType.RoleSkin
            or item_type == ItemDefine.EItemSmallType.GhostSkin
            or item_type == ItemDefine.EItemSmallType.ItemSkin
            or item_type == ItemDefine.EItemSmallType.HeadSkin
            or item_type == ItemDefine.EItemSmallType.HeadFrameSkin
            or item_type == ItemDefine.EItemSmallType.TitleSkin) and use_item then
        if not itemImages.skin_image[config_id] or itemImages.skin_image[config_id].valid_ts ~= 0 then
            local itemImage_info = ItemDef.newSkinImage()
            itemImage_info.config_id = config_id
            itemImages.skin_image[config_id] = itemImage_info

            table.insert(change_image_ids, config_id)
        else
            return ErrorCode.ItemImageExist
        end
    elseif item_type == ItemDefine.EItemSmallType.SpaceRing then
        if not itemImages.space_ring_image[config_id] then
            local itemImage_info = ItemDef.newImage()
            itemImage_info.config_id = config_id
            itemImages.space_ring_image[config_id] = itemImage_info

            table.insert(change_image_ids, config_id)
        else
            return ErrorCode.ItemImageExist
        end
    elseif item_type == ItemDefine.EItemSmallType.PlayItem
        or item_type == ItemDefine.EItemSmallType.DurabItem
        or item_type == ItemDefine.EItemSmallType.Tool then
        if not itemImages.item_image[config_id] then
            local itemImage_info = ItemDef.newImage()
            itemImage_info.config_id = config_id
            itemImages.item_image[config_id] = itemImage_info

            table.insert(change_image_ids, config_id)
        else
            return ErrorCode.ItemImageExist
        end
    else
        return ErrorCode.ItemNotExist
    end

    if item_type == ItemDefine.EItemSmallType.RoleSkin then
        -- 触发角色皮肤数量
        local now_cnt, _ = ItemImage.GetSkinTypeCnt(itemImages)
        scripts.Mission.TriggerCondition(MissionDef.EConditionIds.UNLOCK_ROLE_SKIN_CNT, {}, now_cnt)
        -- 触发指定皮肤解锁
        scripts.Mission.TriggerCondition(MissionDef.EConditionIds.UNLOCK_ROLE_SKIN, { config_id }, 1)
    elseif item_type == ItemDefine.EItemSmallType.ItemSkin then
        -- 触发道具皮肤数量
        local _, now_cnt = ItemImage.GetSkinTypeCnt(itemImages)
        scripts.Mission.TriggerCondition(MissionDef.EConditionIds.UNLOCK_ITEM_SKIN_CNT, {}, now_cnt)
    end
    return ErrorCode.None
end

function ItemImage.AddItemImageValidtime(config_id, change_image_ids, use_item, valid_ts)
    local itemImages = scripts.UserModel.GetItemImages()
    if not itemImages then
        return ErrorCode.ServerInternalError
    end

    local item_type = ItemDefine.GetItemType(config_id)
    if (item_type == ItemDefine.EItemSmallType.RoleSkin
            or item_type == ItemDefine.EItemSmallType.GhostSkin
            or item_type == ItemDefine.EItemSmallType.ItemSkin
            or item_type == ItemDefine.EItemSmallType.HeadSkin
            or item_type == ItemDefine.EItemSmallType.HeadFrameSkin
            or item_type == ItemDefine.EItemSmallType.TitleSkin) and use_item then
        if itemImages.skin_image[config_id] and itemImages.skin_image[config_id].valid_ts == 0 then
            return ErrorCode.ItemImageExist
        else
            local now_ts = moon.time()
            if not itemImages.skin_image[config_id] then
                local itemImage_info = ItemDef.newSkinImage()
                itemImage_info.config_id = config_id
                itemImage_info.valid_ts = now_ts + valid_ts
                itemImages.skin_image[config_id] = itemImage_info
            else
                if now_ts >= itemImages.skin_image[config_id].valid_ts then
                    itemImages.skin_image[config_id].valid_ts = now_ts + valid_ts
                else
                    itemImages.skin_image[config_id].valid_ts = itemImages.skin_image[config_id].valid_ts + valid_ts
                end
            end

            table.insert(change_image_ids, config_id)
        end
    else
        return ErrorCode.ItemNotExist
    end

    return ErrorCode.None
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
        or item_type == ItemDefine.EItemSmallType.GhostSkin
        or item_type == ItemDefine.EItemSmallType.ItemSkin
        or item_type == ItemDefine.EItemSmallType.HeadSkin
        or item_type == ItemDefine.EItemSmallType.HeadFrameSkin
        or item_type == ItemDefine.EItemSmallType.TitleSkin then
        return itemImages.skin_image[config_id], item_type
    elseif item_type == ItemDefine.EItemSmallType.SpaceRing then
        return itemImages.space_ring_image[config_id], item_type
    else
        return itemImages.item_image[config_id], item_type
    end
end

function ItemImage.CheckImageValid(config_id)
    local itemImages = scripts.UserModel.GetItemImages()
    if not itemImages then
        return false
    end

    local item_type = ItemDefine.GetItemType(config_id)
    if item_type == ItemDefine.EItemSmallType.MagicItem then
        if not itemImages.magic_item_image[config_id] then
            return false
        end
        return true
    elseif item_type == ItemDefine.EItemSmallType.HumanDiagrams then
        if not itemImages.human_diagrams_image[config_id] then
            return false
        end
        return true
    elseif item_type == ItemDefine.EItemSmallType.GhostDiagrams then
        if not itemImages.ghost_diagrams_image[config_id] then
            return false
        end
        return true
    elseif item_type == ItemDefine.EItemSmallType.RoleSkin
        or item_type == ItemDefine.EItemSmallType.GhostSkin
        or item_type == ItemDefine.EItemSmallType.ItemSkin
        or item_type == ItemDefine.EItemSmallType.HeadSkin
        or item_type == ItemDefine.EItemSmallType.HeadFrameSkin
        or item_type == ItemDefine.EItemSmallType.TitleSkin then
        if not itemImages.skin_image[config_id] then
            return false
        end
        if itemImages.skin_image[config_id].valid_ts == 0 then
            return true
        end
        if itemImages.skin_image[config_id].valid_ts > moon.time() then
            return true
        end
        return false
    elseif item_type == ItemDefine.EItemSmallType.SpaceRing then
        if not itemImages.space_ring_image[config_id] then
            return false
        end
        return true
    else
        return false
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
    elseif item_type == ItemDefine.EItemSmallType.SpaceRing then
        local up_exp_cfgs = GameCfg.SpaceRingUpLv
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
        local cur_cfg = GameCfg.UpLvCostIDMapping[id]
        if not cur_cfg or not cur_cfg.cost or not cur_cfg.cnt then
            return ErrorCode.ItemUpLvCostNotExist
        end

        ItemDefine.GetItemsFromCfg(cur_cfg.cost, (count / cur_cfg.cnt), true, cost_items, cost_coins)
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

function ItemImage.CheckUseItemUpLv(config_id, exp_id, up_exp_total, item_exps)
    local image_data, item_type = ItemImage.GetImage(config_id)
    if not image_data then
        return ErrorCode.ItemNotExist, 0, {}
    end

    -- local function check_add_exp(up_exp_cfgs, cur_exp, after_up_exp)
    --     for _, cfg in pairs(up_exp_cfgs) do
    --         if image_data.exp < cfg.allexp and after_up_exp >= cfg.allexp then
    --             if cfg.cost ~= exp_id then
    --                 return ErrorCode.ConfigError
    --             end
    --         end

    --         if after_up_exp < cfg.allexp then
    --             return ErrorCode.None
    --         end
    --     end

    --     return ErrorCode.ItemMaxExp
    -- end
    local function check_add_exp(up_exp_cfgs, cur_exp, after_up_exp)
        local success = false
        local max_exp = 0
        for _, cfg in pairs(up_exp_cfgs) do
            if cur_exp < cfg.allexp then
                if cfg.cost ~= exp_id then
                    return ErrorCode.ConfigError, 0, {}
                end
            end
            if after_up_exp <= cfg.allexp then
                success = true
                break
            end
            max_exp = cfg.allexp
        end
        if success then
            local cost_items = {}
            for cost_id, exp_num in pairs(item_exps) do
                cost_items[cost_id] = {
                    id = cost_id,
                    count = -exp_num.num,
                    pos = 0,
                }
            end
            return ErrorCode.None, up_exp_total, cost_items
        end

        local cost_items = {}
        local need_exp = max_exp - cur_exp
        if need_exp > 0 then
            for cost_id, exp_num in pairs(item_exps) do
                local need_num = math.ceil(need_exp / exp_num.exp_cnt)
                need_num = math.min(need_num, exp_num.num)
                cost_items[cost_id] = {
                    id = cost_id,
                    count = -need_num,
                    pos = 0,
                }
                need_exp = need_exp - need_num * exp_num.exp_cnt
                if need_exp <= 0 then
                    break
                end
            end
        end

        return ErrorCode.None, max_exp - cur_exp, cost_items
    end

    local after_up_exp = image_data.exp + up_exp_total
    if item_type == ItemDefine.EItemSmallType.MagicItem then
        local up_exp_cfgs = GameCfg.MagicItemUpLv
        return check_add_exp(up_exp_cfgs, image_data.exp, after_up_exp)
    elseif item_type == ItemDefine.EItemSmallType.PlayItem
        or item_type == ItemDefine.EItemSmallType.UnStackItem then
        local up_exp_cfgs = GameCfg.GamePropUpLv
        return check_add_exp(up_exp_cfgs, image_data.exp, after_up_exp)
    elseif item_type == ItemDefine.EItemSmallType.HumanDiagrams then
        local up_exp_cfgs = GameCfg.BaGuaBrandUpLv
        return check_add_exp(up_exp_cfgs, image_data.exp, after_up_exp)
    elseif item_type == ItemDefine.EItemSmallType.GhostDiagrams then
        local up_exp_cfgs = GameCfg.GhostEquipmentUpLv
        return check_add_exp(up_exp_cfgs, image_data.exp, after_up_exp)
    elseif item_type == ItemDefine.EItemSmallType.SpaceRing then
        local up_exp_cfgs = GameCfg.SpaceRingUpLv
        return check_add_exp(up_exp_cfgs, image_data.exp, after_up_exp)
    end
    
    -- image_data.exp = after_up_exp

    return ErrorCode.ConfigError, 0, {}
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

    local rate_key = "rate" .. (image_data.star_level + 1)
    if not star_cfg[rate_key] then
        return ErrorCode.ConfigError
    end
    local rate_cfg = star_cfg[rate_key]

    local add_rate_cfg = CommonCfgDef.getConf("UpStarAdditionRate")
    if not add_rate_cfg then
        return ErrorCode.ConfigError
    end

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

    -- 计算升星概率
    local now_rate = rate_cfg + add_rate_cfg.value * image_data.star_fail_cnt
    local random_rate = math.random(1, 10000)
    if random_rate > now_rate then
        -- 增加升星失败次数
        image_data.star_fail_cnt = image_data.star_fail_cnt + 1
        return ErrorCode.UpStarProbFail, change_log
    else
        -- 增加星星
        image_data.star_level = image_data.star_level + 1
        image_data.star_fail_cnt = 0
        return ErrorCode.None, change_log
    end
end

function ItemImage.GetImagesInfo()
    local itemImages = scripts.UserModel.GetItemImages()
    if not itemImages then
        return { errcode = ErrorCode.ServerInternalError }
    end

    return { errcode = ErrorCode.None, image_data = itemImages }
end

function ItemImage.UseItemAddImage(item_cfg, msg_data, change_image_ids)
    local err_code = ErrorCode.ItemTypeMismatch
    if item_cfg.use_type == 1
        and msg_data.use_item_cnt == 1
        and item_cfg.use_skin
        and item_cfg.use_skin > 0 then
        err_code = ItemImage.AddItemImage(item_cfg.use_skin, change_image_ids, true)
        return err_code
    elseif item_cfg.use_type == 2
        and item_cfg.use_skin
        and item_cfg.use_skin > 0
        and item_cfg.skin_time
        and item_cfg.skin_time > 0 then
        err_code = ItemImage.AddItemImageValidtime(item_cfg.use_skin, change_image_ids, true,
            item_cfg.skin_time * msg_data.use_item_cnt)
        return err_code
    elseif item_cfg.use_type == 3 then

    end

    return err_code
end

function ItemImage.ItemChangeSkin(item_config_id, skin_id)
    local item_images = scripts.UserModel.GetItemImages()
    if not item_images then
        return ErrorCode.ServerInternalError
    end
    if not item_images[item_config_id] then
        return ErrorCode.ItemNotExist
    end
    if skin_id > 0 then
        if not ItemImage.CheckImageValid(skin_id) then
            return ErrorCode.ItemNotExist
        end
        local item_skin_cfg = GameCfg.ItemSkin[skin_id]
        if not item_skin_cfg or item_skin_cfg.belong ~= item_config_id then
            return ErrorCode.SkinNotMatch
        end
    end
    item_images.item_wear_skin[item_config_id] = skin_id

    ItemImage.SaveItemImagesNow()
    return ErrorCode.None
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