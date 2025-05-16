local moon = require "moon"
local common = require "common"
local uuid = require "uuid"
local GameCfg = common.GameCfg
local ErrorCode = common.ErrorCode
local CmdCode = common.CmdCode
local Database = common.Database
local BagDef = require("common.def.BagDef")
local ItemDef = require("common.def.ItemDef")

---@type user_context
local context = ...
local scripts = context.scripts

-- local ItemType = {
--     ALL = 1,
--     Consume = 2,
-- }

---@class Bag
local Bag = {}

function Bag.Init()
    
end

function Bag.Start()
    local bagTypes = {}
    bagTypes[BagDef.BagType.Cangku] = 1
    bagTypes[BagDef.BagType.Consume] = 1
    bagTypes[BagDef.BagType.Booty] = 1

    local baginfos = Bag.LoadBags(bagTypes)
    if baginfos then
        scripts.UserModel.SetBagData(baginfos)
    end

    local bagdata = scripts.UserModel.GetBagData()
    if not bagdata then
        bagdata = BagDef.newBags()

        scripts.UserModel.SetBagData(bagdata)
        Bag.SaveBagsNow(bagTypes)
    end

    local coininfos = Bag.LoadCoins()
    if coininfos then
        scripts.UserModel.SetCoinsData(coininfos)
    end

    local coinsdata = scripts.UserModel.GetCoinsData()
    if not coinsdata then
        coinsdata = BagDef.newPBUserCoins()

        scripts.UserModel.SetCoinsData(coinsdata)
        Bag.SaveCoinsNow()
    end
end

function Bag.SaveBagsNow(bagTypes)
    local bagdata = scripts.UserModel.GetBagData()
    if not bagdata then
        return false
    end

    local save_bags = {}
    local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
    for bagType, _ in pairs(bagTypes) do
        if bagType ~= BagDef.BagType.Coins and bagdata[bagType] then
            save_bags[bagType] = bagdata[bagType]
        end
    end

    local success = Database.saveuserbags(context.addr_db_user, context.uid, save_bags)
    return success
end

function Bag.LoadBags(bagTypes)
    local baginfos = Database.loaduserbags(context.addr_db_user, context.uid, bagTypes)
    return baginfos
end

function Bag.SaveCoinsNow()
    local coinsdata = scripts.UserModel.GetCoinsData()
    if not coinsdata then
        return false
    end

    local success = Database.saveusercoins(context.addr_db_user, context.uid, coinsdata)
    return success
end

function Bag.LoadCoins()
    local coininfos = Database.loadusercoins(context.addr_db_user, context.uid)
    return coininfos
end

function Bag.AddCapacity(bagType, add_capacity)
    if add_capacity <= 0 then
        return ErrorCode.ParamInvalid
    end

    if bagType ~= BagDef.BagType.Cangku
        and bagType ~= BagDef.BagType.Consume
        and bagType ~= BagDef.BagType.Booty then
        return ErrorCode.BagNotExist
    end

    local bagdata = scripts.UserModel.GetBagData()
    if not bagdata then
        return ErrorCode.BagNotExist
    end

    local baginfo = bagdata[bagType]
    if bagType == BagDef.BagType.Cangku
        and baginfo.capacity + add_capacity > BagDef.max_cangku_capacity then
        return ErrorCode.BagCapacityOverflow
    elseif bagType == BagDef.BagType.Consume
        and baginfo.capacity + add_capacity > BagDef.max_consume_capacity then
        return ErrorCode.BagCapacityOverflow
    elseif bagType == BagDef.BagType.Booty
        and baginfo.capacity + add_capacity > BagDef.max_booty_capacity then
        return ErrorCode.BagCapacityOverflow
    end

    baginfo.capacity = baginfo.capacity + add_capacity
    return ErrorCode.None
end

function Bag.GetEmptyPosNum(bagType)
    local bagdata = scripts.UserModel.GetBagData()
    if not bagdata then
        return 0
    end

    local baginfo = bagdata[bagType]
    local emptyCount = baginfo.capacity - table.size(baginfo.items)

    return emptyCount
end

function Bag.RollBackWithChange(num_change_logs, info_change_logs)
    if not num_change_logs and not info_change_logs then
        return
    end

    local bagdata = scripts.UserModel.GetBagData()
    if not bagdata then
        return
    end

    local coinsdata = scripts.UserModel.GetCoinsData()
    if not coinsdata then
        return
    end

    -- 先执行道具数量变更回滚
    for bagType, logs in pairs(num_change_logs) do
        if bagType == BagDef.BagType.Coins then
            for coinid, log in pairs(logs) do
                coinsdata[coinid].coin_count = log.after_count - log.change_count
            end
        else
            local baginfo = bagdata[bagType]
            if baginfo then
                for pos, log in pairs(logs) do
                    if baginfo.items[pos] then
                        local itemdata = baginfo.items[pos]
                        itemdata.common_info.item_count = itemdata.common_info.item_count - log.change_count
                        if itemdata.common_info.item_count == 0 then
                            baginfo.items[pos] = nil
                        end
                    end
                end
            end
        end
    end

    -- 再执行道具属性变更回滚
    for _, info in pairs(info_change_logs) do
        local baginfo = bagdata[info.bagType]
        if baginfo and baginfo.items[info.pos] then
            table.copy(baginfo.items[info.pos], info.itemdata)
        end
    end
end

-- function Bag.RunChange(num_change, info_change)
--     if not num_change and not info_change then
--         return nil, nil
--     end

--     local bagdata = scripts.UserModel.GetBagData()
--     if not bagdata then
--         return nil, nil
--     end

--     local save_bags = {}
--     local change_log = {}
--     for bagType, pos_list in pairs(num_change) do
--         local baginfo = bagdata[bagType]
--         if baginfo then
--             for pos, _ in pairs(pos_list) do
--                 if baginfo.items[pos]
--                     and baginfo.items[pos].common_info.lock_count ~= 0 then
--                     local itemdata = baginfo.items[pos]

--                     local log_info = {
--                         log_type = BagDef.LogType.ChangeNum,
--                         bagType = bagType,
--                         pos = pos,
--                         config_id = itemdata.common_info.config_id,
--                         before_count = itemdata.common_info.item_count,
--                         after_count = itemdata.common_info.item_count + itemdata.common_info.lock_count,
--                         uniqid = itemdata.common_info.uniqid,
--                     }

--                     itemdata.common_info.item_count = itemdata.common_info.item_count + itemdata.common_info.lock_count
--                     itemdata.common_info.lock_count = 0
--                     if itemdata.common_info.item_count == 0 then
--                         baginfo.items[pos] = nil
--                     end

--                     table.insert(change_log, log_info)
--                 end
--             end

--             save_bags[bagType] = 1
--         end
--     end

--     local change_item_pos = {}
--     for _, info in pairs(info_change) do
--         local baginfo = bagdata[info.bagType]
--         if baginfo then
--             if not change_item_pos[info.bagType] then
--                 change_item_pos[info.bagType] = {}
--             end

--             if baginfo.items[info.pos] then
--                 change_item_pos[info.bagType][info.pos] = 1
--             end
--         end
--     end
--     for bagType, pos_list in pairs(change_item_pos) do
--         for pos, _ in pairs(pos_list) do
--             local log_info = {
--                 log_type = BagDef.LogType.ChangeInfo,
--                 bagType = bagType,
--                 pos = pos,
--                 itemdata = {},
--             }
--             table.copy(log_info.itemdata, bagdata[bagType].items[pos])

--             table.insert(change_log, log_info)
--         end

--         save_bags[bagType] = 1
--     end

--     return save_bags, change_log
-- end

function Bag.SaveAndLog(bagTypes, num_change_logs, info_change_logs)
    local success = true

    if bagTypes and bagTypes[BagDef.BagType.Coins] then
        success = Bag.SaveCoinsNow()
    end
    
    local success = Bag.SaveBagsNow(bagTypes)

    --存储日志

    return success
end

function Bag.BagGetChangeItems(change_logs)
    local change_items = {}

    local bagdata = scripts.UserModel.GetBagData()
    if not bagdata then
        return change_items
    end

    for bagType, logs in pairs(change_logs) do
        if not change_items[bagType] then
            change_items[bagType] = {}
        end

        local baginfo = bagdata[bagType]
        change_items[bagType].bag_item_type = baginfo.bag_item_type
        change_items[bagType].capacity = baginfo.capacity
        change_items[bagType].items = {}
        for pos, _ in pairs(logs) do
            if baginfo.items[pos] then
                change_items[bagType].items[pos] = baginfo.items[pos]
            else
                change_items[bagType].items[pos] = {}
            end
        end
    end

    return change_items
end

-- 添加物品（支持自动堆叠）
function Bag.AddItem(baginfo, itemId, count, logs)
    local item_cfg = GameCfg.Item[itemId]
    if not item_cfg then
        return ErrorCode.ItemNotExist
    end

    -- 类型检查
    local item_type = scripts.ItemDefine.GetItemBagType(itemId)
    if baginfo.bag_item_type ~= scripts.ItemDefine.ItemBagType.ALL
        and baginfo.bag_item_type ~= item_type then
        return ErrorCode.BagTypeMismatch
    end

    -- 处理物品增减
    local remaining = count

    -- 先尝试堆叠
    for pos, itemdata in pairs(baginfo.items) do
        if itemdata.common_info.config_id == itemId
            and itemdata.common_info.uniqid == 0
            and itemdata.common_info.item_count < item_cfg.stack_count then
            local canAdd = math.min(item_cfg.stack_count - itemdata.common_info.item_count, remaining)

            itemdata.common_info.item_count = itemdata.common_info.item_count + canAdd
            logs[pos] = { config_id = itemId, uniqid = 0, change_count = canAdd }
            remaining = remaining - canAdd
            if remaining <= 0 then
                break
            end
        end
    end

    -- 尝试添加新位置
    if remaining > 0 then
        local needPosize = math.ceil(remaining / item_cfg.stack_count)
        local emptyPos = {}
        for pos = 1, baginfo.capacity do
            if not baginfo.items[pos] then
                table.insert(emptyPos, pos)

                if #emptyPos >= needPosize then
                    break
                end
            end
        end

        for _, pos in pairs(emptyPos) do
            local canAdd = math.min(item_cfg.stack_count, remaining)

            local new_item = ItemDef.newItemData()
            new_item.itype = item_type
            new_item.common_info.config_id = item_cfg.id
            new_item.common_info.item_count = canAdd
            new_item.common_info.item_type = item_cfg.type1
            new_item.common_info.trade_cnt = -1

            baginfo.items[pos] = new_item
            logs[pos] = { config_id = itemId, uniqid = 0, change_count = canAdd }
            remaining = remaining - canAdd
            if remaining <= 0 then
                break
            end
        end
    end

    if remaining > 0 then
        return ErrorCode.BagFull
    end

    return ErrorCode.None
end

function Bag.DelItem(baginfo, itemId, count, pos, logs)
    local item_cfg = GameCfg.Item[itemId]
    if not item_cfg then
        return ErrorCode.ItemNotExist
    end

    local remaining = count

    if pos > 0 then
        local itemdata = baginfo.items[pos]
        if not itemdata
            and itemdata.common_info.config_id == itemId
            and itemdata.common_info.uniqid == 0
            and itemdata.common_info.item_count + remaining >= 0 then
            return ErrorCode.ItemNotEnough
        end

        itemdata.common_info.item_count = itemdata.common_info.item_count + remaining
        logs[pos] = { config_id = itemId, uniqid = 0, change_count = remaining }
    else
        -- 先尝试扣减
        for pos, itemdata in pairs(baginfo.items) do
            if itemdata.common_info.config_id == itemId
                and itemdata.common_info.uniqid == 0
                and itemdata.common_info.item_count > 0 then
                local canSub = math.min(itemdata.common_info.item_count, -remaining)

                itemdata.common_info.item_count = itemdata.common_info.item_count - canSub
                logs[pos] = { config_id = itemId, uniqid = 0, change_count = -canSub }
                remaining = remaining + canSub

                if remaining >= 0 then
                    break
                end
            end
        end
    end

    if remaining < 0 then
        return ErrorCode.BagNotEnough
    end

    return ErrorCode.None
end

function Bag.AddUniqItem(baginfo, itemId, uniqid, itype, logs)
    -- 参数校验
    local item_cfg = GameCfg.UniqueItem[itemId]
    if not item_cfg then
        return ErrorCode.ItemNotExist
    end

    -- 类型检查
    local item_type = scripts.ItemDefine.GetItemBagType(itemId)
    if baginfo.bag_item_type ~= scripts.ItemDefine.ItemBagType.ALL
        and baginfo.bag_item_type ~= item_type then
        return ErrorCode.BagTypeMismatch
    end

    -- 处理物品记录
    for pos = 1, baginfo.capacity do
        if not baginfo.items[pos] then
            local new_item = ItemDef.newItemData()
            new_item.itype = itype
            new_item.common_info.config_id = item_cfg.id
            new_item.common_info.uniqid = uniqid
            new_item.common_info.item_count = 1
            new_item.common_info.item_type = item_cfg.type1
            new_item.common_info.trade_cnt = -1

            baginfo.items[pos] = new_item
            logs[pos] = { config_id = itemId, uniqid = uniqid, change_count = 1 }

            return ErrorCode.None, pos
        end
    end

    return ErrorCode.BagFull
end

function Bag.DelUniqItem(baginfo, itemId, uniqid, pos, logs)
    -- 参数校验
    if not baginfo.items[pos] then
        return ErrorCode.ItemNotExist
    end
    if baginfo.items[pos].common_info.config_id ~= itemId
        or baginfo.items[pos].common_info.uniqid ~= uniqid
        or baginfo.items[pos].common_info.item_count == 1 then
        return ErrorCode.ItemNotExist
    end

    baginfo.items[pos].common_info.item_count = 0
    -- 处理物品记录
    logs[pos] = { config_id = itemId, uniqid = uniqid, change_count = -1 }

    return ErrorCode.None
end

function Bag.AddMagicItem(baginfo, itemId, count, change_log)
    for i = 1, count do
        local uniqid = uuid.next()
        local errorCode, add_pos = Bag.AddUniqItem(baginfo, itemId, uniqid, scripts.ItemDefine.EItemSmallType.MagicItem,
            change_log)
        if errorCode ~= ErrorCode.None or not add_pos then
            return errorCode
        end

        local itemdata = baginfo.items[add_pos]
        itemdata.special_info = {
            magic_item = ItemDef.newMagicItem(),
        }
        itemdata.special_info.magic_item.cur_durability = 0
        itemdata.special_info.magic_item.max_durability = 0
        itemdata.special_info.magic_item.light_cnt = 0
        itemdata.special_info.magic_item.tags = {}
    end

    --添加法器图鉴
    --scripts.ItemImage.AddMagicItemImage(itemId)

    return ErrorCode.None
end

function Bag.AddDiagramsCard(baginfo, itemId, count, change_log)
    local itype = scripts.ItemDefine.GetItemType(itemId)
    for i = 1, count do
        local uniqid = uuid.next()
        local errorCode, add_pos = Bag.AddUniqItem(baginfo, itemId, uniqid, itype, change_log)
        if errorCode ~= ErrorCode.None or not add_pos then
            return errorCode
        end

        local itemdata = baginfo.items[add_pos]
        itemdata.special_info = {
            diagrams_item = ItemDef.newDiagramsCard(),
        }
        itemdata.special_info.diagrams_item.cur_durability = 0
        itemdata.special_info.diagrams_item.max_durability = 0
        itemdata.special_info.diagrams_item.light_cnt = 0
        itemdata.special_info.diagrams_item.tags = {}
    end

    --添加八卦牌图鉴
    --scripts.ItemImage.AddDiagramsCardImage(itemId)

    return ErrorCode.None
end

function Bag.CheckItemsEnough(bagType, del_items, del_unique_items)
    -- 参数校验
    if bagType ~= BagDef.BagType.Cangku
        and bagType ~= BagDef.BagType.Consume
        and bagType ~= BagDef.BagType.Booty then
        return ErrorCode.BagNotExist
    end

    local bagdata = scripts.UserModel.GetBagData()
    if not bagdata or not bagdata[bagType] then
        return ErrorCode.BagNotExist
    end
    local baginfo = bagdata[bagType]

    --检测扣除的唯一道具是否存在
    for uniqid, uniqitem in pairs(del_unique_items) do
        local find_uniq = false
        if uniqitem.pos ~= 0 then
            if baginfo.items[uniqitem.pos]
                and baginfo.items[uniqitem.pos].common_info.uniqid == uniqid then
                find_uniq = true
            end

            if find_uniq then
                break
            end
        else
            for pos, itemdata in pairs(baginfo.items) do
                if itemdata.common_info.uniqid == uniqid then
                    find_uniq = true
                    uniqitem.pos = pos
                    break
                end
            end
        end

        if not find_uniq then
            return ErrorCode.ItemNotExist
        end
    end

    --检测扣除的道具是否足够
    for itemid, item in pairs(del_items) do
        if item.count > 0 then
            return ErrorCode.ParamInvalid
        end

        local remaining = item.count
        if item.pos ~= 0 then
            if baginfo.items[item.pos]
                and baginfo.items[item.pos].common_info.config_id == itemid
                and baginfo.items[item.pos].common_info.item_count >= remaining then
                remaining = 0
            else
                return ErrorCode.ItemNotExist
            end
        else
            for pos, itemdata in pairs(baginfo.items) do
                if itemdata.common_info.config_id == itemid
                    and itemdata.common_info.item_count > 0 then
                    remaining = remaining + itemdata.common_info.item_count
                    if remaining >= 0 then
                        break
                    end
                end
            end
        end

        if remaining < 0 then
            return ErrorCode.ItemNotEnough
        end
    end

    return ErrorCode.None
end

function Bag.CheckCoinsEnough(coins)
    local coinsdata = scripts.UserModel.GetCoinsData()
    if not coinsdata then
        return ErrorCode.CoinNotExist
    end
    
    --检测扣除的道具是否足够
    for coinid, coin in pairs(coins) do
        if coin.count < 0 then
            if not coinsdata[coinid] or coinsdata[coinid].coin_count + coin.count < 0 then
                return ErrorCode.CoinNotEnough
            end
        end
    end

    return ErrorCode.None
end

function Bag.CheckEmptyEnough(bagType, add_items)
    -- 参数校验
    if bagType ~= BagDef.BagType.Cangku
        and bagType ~= BagDef.BagType.Consume
        and bagType ~= BagDef.BagType.Booty then
        return ErrorCode.BagNotExist
    end

    local bagdata = scripts.UserModel.GetBagData()
    if not bagdata or not bagdata[bagType] then
        return ErrorCode.BagNotExist
    end
    local baginfo = bagdata[bagType]
    local empty_pos_num = Bag.GetEmptyPosNum(bagType)

    -- 计算背包空间是否足够
    for itemid, item in pairs(add_items) do
        if item.count < 0 then
            return ErrorCode.ParamInvalid
        end
        local item_cfg = GameCfg.Item[itemid]
        if not item_cfg then
            return ErrorCode.ConfigError
        end

        local item_big_type = scripts.ItemDefine.GetItemPosType(itemid)
        if item_big_type == scripts.ItemDefine.EItemBigType.StackItem then
            local remaining = item.count
            for pos, itemdata in pairs(baginfo.items) do
                if itemdata.common_info.config_id == itemid
                    and itemdata.common_info.item_count < item_cfg.stack_count then
                    remaining = remaining - (item_cfg.stack_count - itemdata.common_info.item_count)
                    if remaining <= 0 then
                        break
                    end
                end
            end

            if remaining > 0 then
                local need_pos = math.ceil(remaining / item_cfg.stack_count)
                empty_pos_num = empty_pos_num - need_pos
                if empty_pos_num < 0 then
                    return ErrorCode.BagFull
                end
            end
        elseif item_big_type == scripts.ItemDefine.EItemBigType.UnStackItem
            or item_big_type == scripts.ItemDefine.EItemBigType.UniqueItem then
            empty_pos_num = empty_pos_num - item.count
            if empty_pos_num < 0 then
                return ErrorCode.BagFull
            end
        else
            return ErrorCode.ItemNotExist
        end
    end

    return ErrorCode.None
end

function Bag.DelItems(bagType, del_items, del_unique_items, change_log)
    -- 参数校验
    if bagType ~= BagDef.BagType.Cangku
        and bagType ~= BagDef.BagType.Consume
        and bagType ~= BagDef.BagType.Booty then
        return ErrorCode.BagNotExist
    end

    local bagdata = scripts.UserModel.GetBagData()
    if not bagdata or not bagdata[bagType] then
        return ErrorCode.BagNotExist
    end
    local baginfo = bagdata[bagType]

    local err_code = ErrorCode.None
    if not change_log[bagType] then
        change_log[bagType] = {}
    end
    -- 执行物品删除
    if table.size(del_unique_items) > 0 then
        for uniqid, uniqitem in pairs(del_unique_items) do
            err_code = Bag.DelUniqItem(bagType, uniqitem.config_id, uniqitem.uniqid, uniqitem.pos, change_log[bagType])
            if err_code ~= ErrorCode.None then
                return err_code
            end
        end
    end

    for itemid, item in pairs(del_items) do
        if item.count >= 0 then
            return ErrorCode.ParamInvalid
        end

        err_code = Bag.DelItem(baginfo, itemid, item.count, item.pos, change_log[bagType])
        if err_code ~= ErrorCode.None then
            return err_code
        end
    end

    return ErrorCode.None
end

function Bag.AddItems(bagType, add_items, change_log)
    -- 参数校验
    if bagType ~= BagDef.BagType.Cangku
        and bagType ~= BagDef.BagType.Consume
        and bagType ~= BagDef.BagType.Booty then
        return ErrorCode.BagNotExist
    end

    local bagdata = scripts.UserModel.GetBagData()
    if not bagdata or not bagdata[bagType] then
        return ErrorCode.BagNotExist
    end
    local baginfo = bagdata[bagType]

    local err_code = ErrorCode.None
    if not change_log[bagType] then
        change_log[bagType] = {}
    end
    -- 执行物品添加
    for itemid, item in pairs(add_items) do
        if item.count < 0 then
            return ErrorCode.ParamInvalid
        end

        local item_big_type = scripts.ItemDefine.GetItemPosType(itemid)
        local item_small_type = scripts.ItemDefine.GetItemType(itemid)
        if item_big_type == scripts.ItemDefine.EItemBigType.StackItem then
            err_code = Bag.AddItem(baginfo, itemid, item.count, change_log[bagType])
            if err_code ~= ErrorCode.None then
                return err_code
            end
        elseif item_big_type == scripts.ItemDefine.EItemBigType.UnStackItem
            or item_big_type == scripts.ItemDefine.EItemBigType.UniqueItem then
            if item_small_type == scripts.ItemDefine.EItemSmallType.DurabItem then
                -- 执行不可堆叠道具添加
            elseif item_small_type == scripts.ItemDefine.EItemSmallType.HumanDiagrams
                or item_small_type == scripts.ItemDefine.EItemSmallType.GhostDiagrams then
                err_code = Bag.AddDiagramsCard(baginfo, itemid, item.count, change_log[bagType])
                if err_code ~= ErrorCode.None then
                    return err_code
                end
            elseif item_small_type == scripts.ItemDefine.EItemSmallType.MagicItem then
                err_code = Bag.AddMagicItem(baginfo, itemid, item.count, change_log[bagType])
                if err_code ~= ErrorCode.None then
                    return err_code
                end
            else
                return ErrorCode.ItemNotExist
            end
        else
            return ErrorCode.ItemNotExist
        end
    end

    -- 判断图鉴是否需要更新
    for _, log in pairs(change_log[bagType]) do
        local item_small_type = scripts.ItemDefine.GetItemType(log.config_id)
        if item_small_type == scripts.ItemDefine.EItemSmallType.HumanDiagrams
            or item_small_type == scripts.ItemDefine.EItemSmallType.GhostDiagrams then
            scripts.ItemImage.AddDiagramsCardImage(log.config_id)
        elseif item_small_type == scripts.ItemDefine.EItemSmallType.MagicItem then
            scripts.ItemImage.AddMagicItemImage(log.config_id)
        end
    end

    return ErrorCode.None
end

function Bag.DealCoins(coins, change_log)
    local coinsdata = scripts.UserModel.GetCoinsData()
    if not coinsdata then
        return ErrorCode.CoinNotExist
    end
    
    for coinid, coin in pairs(coins) do
        if coin.count < 0 and not coinsdata[coinid] then
            Bag.RollBackWithChange(change_log, {})
            return ErrorCode.CoinNotExist
        end

        if not coinsdata[coinid] then
            coinsdata[coinid] = {
                coin_id = coinid,
                coin_count = 0,
            }
        end

        coinsdata[coinid].coin_count = coinsdata[coinid].coin_count + coin.count

        if not change_log[BagDef.BagType.Coins] then
            change_log[BagDef.BagType.Coins] = {}
        end
        change_log[BagDef.BagType.Coins][coinid] = {
            after_count = coinsdata[coinid].coin_count,
            change_count = coin.count
        }
    end

    return ErrorCode.None
end

-- function Bag.AddOrDelItems(bagType, items, del_unique_items)
--     -- 存储背包变更及日志
--     Bag.SaveAndLog(change_log, {})

--     return ErrorCode.None, change_log
-- end

function Bag.StackItems(srcBagType, srcPos, destBagType, destPos, change_log)
    -- 参数校验
    if srcBagType ~= BagDef.BagType.Cangku
        and srcBagType ~= BagDef.BagType.Consume
        and srcBagType ~= BagDef.BagType.Booty then
        return ErrorCode.BagNotExist
    end

    if destBagType ~= BagDef.BagType.Cangku
        and destBagType ~= BagDef.BagType.Consume
        and destBagType ~= BagDef.BagType.Booty then
        return ErrorCode.BagNotExist
    end

    if srcBagType == destBagType and srcPos == destPos then
        return ErrorCode.StackNotAllowed
    end

    local bagdata = scripts.UserModel.GetBagData()
    if not bagdata then
        return ErrorCode.BagNotExist
    end

    local srcBag = bagdata[srcBagType]
    local destBag = bagdata[destBagType]
    if srcBag.capacity < srcPos or destBag.capacity < destPos then
        return ErrorCode.BagCapacityOverflow
    end

    -- 源道具校验,不能有被锁定数量的道具
    local srcItem = srcBag.items[srcPos]
    if not srcItem or srcItem.common_info.uniqid ~= 0
        or srcItem.special_info ~= nil
        or srcItem.common_info.lock_count ~= 0 then
        return ErrorCode.StackNotAllowed
    end
    if srcItem.common_info.item_count <= 0 then
        return ErrorCode.StackNotAllowed
    end

    -- 目标道具校验
    local destItem = destBag.items[destPos]
    if not destItem or destItem.common_info.uniqid ~= 0 or destItem.special_info ~= nil then
        return ErrorCode.StackNotAllowed
    end

    -- 类型一致性校验
    if srcItem.common_info.config_id ~= destItem.common_info.config_id then
        return ErrorCode.StackTypeMismatch
    end

    local item_cfg = GameCfg.Item[srcItem.common_info.config_id]
    if not item_cfg then
        return ErrorCode.ItemNotExist
    end

    -- 计算可堆叠数量
    local available_count = item_cfg.stack_count - (destItem.common_info.item_count + destItem.common_info.lock_count)
    if available_count <= 0 then
        return ErrorCode.StackFull
    end

    local move_count = math.min(available_count, srcItem.common_info.item_count)

    -- 执行堆叠操作
    destItem.common_info.item_count = destItem.common_info.item_count + move_count
    srcItem.common_info.item_count = srcItem.common_info.item_count - move_count
    if srcItem.common_info.item_count == 0 then
        srcBag.items[srcPos] = nil
    end

    -- 记录日志
    if not change_log[destBagType] then
        change_log[destBagType] = {}
    end
    if not change_log[srcBagType] then
        change_log[srcBagType] = {}
    end
    change_log[destBagType][destPos] = {
        config_id = destItem.common_info.config_id,
        uniqid = destItem.common_info.uniqid,
        change_count = move_count,
    }
    change_log[srcBagType][srcPos] = {
        config_id = srcItem.common_info.config_id,
        uniqid = srcItem.common_info.uniqid,
        change_count = -move_count,
    }

    return ErrorCode.None
end

function Bag.SplitItem(srcBagType, srcPos, destBagType, destPos, splitCount, change_log)
    -- 参数校验
    if splitCount <= 0 then
        return ErrorCode.ParamInvalid
    end

    if srcBagType ~= BagDef.BagType.Cangku
        and srcBagType ~= BagDef.BagType.Consume
        and srcBagType ~= BagDef.BagType.Booty then
        return ErrorCode.BagNotExist
    end

    if destBagType ~= BagDef.BagType.Cangku
        and destBagType ~= BagDef.BagType.Consume
        and destBagType ~= BagDef.BagType.Booty then
        return ErrorCode.BagNotExist
    end

    if srcBagType == destBagType and srcPos == destPos then
        return ErrorCode.StackNotAllowed
    end

    local bagdata = scripts.UserModel.GetBagData()
    if not bagdata then
        return ErrorCode.BagNotExist
    end

    local srcBag = bagdata[srcBagType]
    local destBag = bagdata[destBagType]
    if srcBag.capacity < srcPos or destBag.capacity < destPos then
        return ErrorCode.BagCapacityOverflow
    end

    -- 源物品校验,不能有被锁定数量的道具
    local srcItem = srcBag.items[srcPos]
    if not srcItem
        or srcItem.common_info.uniqid ~= 0
        or srcItem.common_info.lock_count ~= 0
        or srcItem.common_info.item_count <= 1 then
        return ErrorCode.SplitNotAllowed
    end

    if splitCount >= srcItem.common_info.item_count then
        return ErrorCode.SplitCountInvalid
    end

    -- 检查目标位置是否被占用
    if destBag.items[destPos] then
        return ErrorCode.MoveTargetOccupied
    end

    -- 跨背包类型校验
    local itemType = scripts.ItemDefine.GetItemBagType(srcItem.common_info.config_id)
    if destBag.bag_item_type ~= scripts.ItemDefine.ItemBagType.ALL
        and destBag.bag_item_type ~= itemType then
        return ErrorCode.BagTypeMismatch
    end

    -- 执行拆分操作
    srcItem.common_info.item_count = srcItem.common_info.item_count - splitCount
    table.copy(destBag.items[destPos], srcItem)
    destBag.items[destPos].common_info.item_count = splitCount
    -- 记录日志
    if not change_log[destBagType] then
        change_log[destBagType] = {}
    end
    if not change_log[srcBagType] then
        change_log[srcBagType] = {}
    end
    change_log[destBagType][destPos] = {
        config_id = srcItem.common_info.config_id,
        uniqid = srcItem.common_info.uniqid,
        change_count = splitCount,
    }
    change_log[srcBagType][srcPos] = {
        config_id = srcItem.common_info.config_id,
        uniqid = srcItem.common_info.uniqid,
        change_count = -splitCount,
    }

    return ErrorCode.None
end

function Bag.MoveItem(srcBagType, srcPos, destBagType, destPos, change_log)
    -- 参数校验
    if srcBagType ~= BagDef.BagType.Cangku
        and srcBagType ~= BagDef.BagType.Consume
        and srcBagType ~= BagDef.BagType.Booty then
        return ErrorCode.BagNotExist
    end

    if destBagType ~= BagDef.BagType.Cangku
        and destBagType ~= BagDef.BagType.Consume
        and destBagType ~= BagDef.BagType.Booty then
        return ErrorCode.BagNotExist
    end

    if srcBagType == destBagType and srcPos == destPos then
        return ErrorCode.StackNotAllowed
    end

    -- 获取数据副本
    local bagdata = scripts.UserModel.GetBagData()
    if not bagdata then
        return ErrorCode.BagNotExist
    end

    local srcBag = bagdata[srcBagType]
    local destBag = bagdata[destBagType]
    if srcBag.capacity < srcPos or destBag.capacity < destPos then
        return ErrorCode.BagCapacityOverflow
    end

    -- 源物品校验,不能有被锁定数量的道具
    local srcItem = srcBag.items[srcPos]
    if not srcItem or srcItem.common_info.lock_count ~= 0 then
        return ErrorCode.ItemNotExist
    end

    -- 目标背包类型校验
    local itemType = scripts.ItemDefine.GetItemBagType(srcItem.common_info.config_id)
    if destBag.bag_item_type ~= scripts.ItemDefine.ItemBagType.ALL
        and destBag.bag_item_type ~= itemType then
        return ErrorCode.BagTypeMismatch
    end

    local destItem = destBag.items[destPos]
    if destItem then
        -- 目标位置有物品
        -- 不能有被锁定数量的道具
        if destItem.common_info.lock_count ~= 0 then
            return ErrorCode.ItemNotExist
        end
        -- 检查是否可以交换
        local destItemType = scripts.ItemDefine.GetItemBagType(destItem.common_info.config_id)
        if srcBag.bag_item_type ~= scripts.ItemDefine.ItemBagType.ALL
            and srcBag.bag_item_type ~= destItemType then
            return ErrorCode.BagTypeMismatch
        end
    end

    -- 执行移动
    if destItem then
        -- 交换物品
        srcBag.items[srcPos] = destItem
        destBag.items[destPos] = srcItem
    else
        -- 移动到空位
        destBag.items[destPos] = srcItem
        srcBag.items[srcPos] = nil
    end
    -- 记录日志
    if not change_log[destBagType] then
        change_log[destBagType] = {}
    end
    if not change_log[srcBagType] then
        change_log[srcBagType] = {}
    end
    change_log[destBagType][destPos] = {
        config_id = srcItem.common_info.config_id,
        uniqid = srcItem.common_info.uniqid,
        change_count = srcItem.common_info.item_count,
    }
    change_log[srcBagType][srcPos] = {
        config_id = srcItem.common_info.config_id,
        uniqid = srcItem.common_info.uniqid,
        change_count = srcItem.common_info.item_count,
    }

    return ErrorCode.None
end

function Bag.GetOneItemData(bagType, pos)
    -- 获取数据副本
    local bagdata = scripts.UserModel.GetBagData()
    if not bagdata then
        return ErrorCode.BagNotExist
    end

    local baginfo = bagdata[bagType]
    if not baginfo or not baginfo.items[pos] then
        return ErrorCode.ItemNotExist
    end

    return ErrorCode.None, baginfo.items[pos]
end

function Bag.SetOneItemData(bagType, pos, itemdata)
    -- 获取数据副本
    local bagdata = scripts.UserModel.GetBagData()
    if not bagdata then
        return ErrorCode.BagNotExist
    end

    local baginfo = bagdata[bagType]
    if not baginfo then
        return ErrorCode.BagNotExist
    end

    table.copy(baginfo.items[pos], itemdata)

    return ErrorCode.None, baginfo.items[pos]
end

function Bag.PBBagGetDataReqCmd(req)
    if table.size(req.msg.bags_name) <= 0 then
        return context.S2C(context.net_id, CmdCode["PBBagGetDataRspCmd"],
            { code = ErrorCode.ParamInvalid, error = "参数错误", uid = context.uid }, req.msg_context.stub_id)
    end

    local bagdata = scripts.UserModel.GetBagData()
    if not bagdata then
        return context.S2C(context.net_id, CmdCode["PBBagGetDataRspCmd"],
            { code = ErrorCode.BagNotExist, error = "背包未加载", uid = context.uid }, req.msg_context.stub_id)
    end

    local res = {
        code = ErrorCode.None,
        error = "",
        uid = context.uid,
        bags = {}
    }
    for _, bag_name in pairs(req.msg.bags_name) do
        if bagdata[bag_name] then
            res.bags[bag_name] = bagdata[bag_name]
        end
    end
    
    return context.S2C(context.net_id, CmdCode["PBBagGetDataRspCmd"], res, req.msg_context.stub_id)
end

function Bag.PBBagOperateItemReqCmd(req)
    local err_code, change_logs = ErrorCode.ParamInvalid, nil
    if req.msg.operate_type == 1 then
        err_code, change_logs = Bag.StackItems(req.msg.src_bag, req.msg.src_pos, req.msg.dest_bag, req.msg.dest_pos)
    elseif req.msg.operate_type == 2 then
        err_code, change_logs = Bag.SplitItem(req.msg.src_bag, req.msg.src_pos, req.msg.dest_bag, req.msg.dest_pos,
        req.msg.splitCount)
    elseif req.msg.operate_type == 3 then
        err_code, change_logs = Bag.MoveItem(req.msg.src_bag, req.msg.src_pos, req.msg.dest_bag, req.msg.dest_pos)
    end

    if err_code ~= ErrorCode.None or not change_logs then
        return context.S2C(context.net_id, CmdCode["PBBagOperateItemRspCmd"],
            { code = err_code, error = "执行出错", uid = context.uid }, req.msg_context.stub_id)
    end

    local bags = {}
    bags[req.msg.src_bag] = 1
    bags[req.msg.dest_bag] = 1
    local success = Bag.SaveAndLog(bags, change_logs)
    if not success then
        return context.S2C(context.net_id, CmdCode["PBBagOperateItemRspCmd"],
            { code = ErrorCode.BagSaveFailed, error = "保存背包失败", uid = context.uid }, req.msg_context.stub_id)
    end

    local change_items = Bag.BagGetChangeItems(change_logs)
    return context.S2C(context.net_id, CmdCode["PBBagOperateItemRspCmd"],
        { code = ErrorCode.None, error = "", uid = context.uid, change_items = change_items },
        req.msg_context.stub_id)
end

function Bag.GetSpecialItemFromCommonItem(srcBagType, srcPos, item_id)
    if srcBagType == BagDef.BagType.Cangku
        and Bag.GetEmptyPosNum(BagDef.BagType.Cangku) < 1 then
        return ErrorCode.BagCapacityOverflow
    end

    local convert_config_id = GameCfg.LightConvert[item_id].getid
    if not convert_config_id then
        return ErrorCode.ConfigError
    end
    local item_type = scripts.ItemDefine.GetItemType(convert_config_id)
    local small_types = scripts.ItemDefine.EItemSmallType
    if item_type ~= small_types.MagicItem
        and item_type ~= small_types.HumanDiagrams
        and item_type ~= small_types.GhostDiagrams then
        return ErrorCode.ItemTypeMismatch
    end

    local del_items = {}
    del_items[item_id] = { pos = srcPos, count = -1 }
    local add_items = {}
    add_items[convert_config_id] = { pos = 0, count = 1 }
    -- 检查道具消耗
    local err_code = Bag.CheckItemsEnough(BagDef.BagType.Cangku, del_items, {})
    if err_code ~= ErrorCode.None then
        return err_code
    end
    -- 检查背包容量
    err_code = Bag.CheckEmptyEnough(BagDef.BagType.Cangku, add_items)
    if err_code ~= ErrorCode.None then
        return err_code
    end

    local change_log = {}
    -- 扣除道具消耗
    err_code = Bag.DelItems(BagDef.BagType.Cangku, del_items, {}, change_log)
    if err_code ~= ErrorCode.None then
        Bag.RollBackWithChange(change_log, {})
        return err_code
    end
    -- 添加道具
    err_code = Bag.AddItems(BagDef.BagType.Cangku, add_items, change_log)
    if err_code ~= ErrorCode.None then
        Bag.RollBackWithChange(change_log, {})
        return err_code
    end

    return ErrorCode.None, change_log
end

function Bag.Light(op_itemdata)
    if not op_itemdata then
        return ErrorCode.ItemNotExist
    end

    local uniqitem_cfg = GameCfg.UniqueItem[op_itemdata.common_info.config_id]
    if not uniqitem_cfg then
        return ErrorCode.ItemNotExist
    end

    -- 获取当前开光次数和词条
    local cur_light_cnt = 0
    local cur_tags = {}
    if op_itemdata.itype == scripts.ItemDefine.EItemSmallType.MagicItem then
        if op_itemdata.special_info and op_itemdata.special_info.magic_item then
            cur_light_cnt = op_itemdata.special_info.magic_item.light_cnt
            cur_tags = op_itemdata.special_info.magic_item.tags
        else
            return ErrorCode.ItemNotExist
        end
    elseif op_itemdata.itype == scripts.ItemDefine.EItemSmallType.HumanDiagrams
        or op_itemdata.itype == scripts.ItemDefine.EItemSmallType.GhostDiagrams then
        if op_itemdata.special_info and op_itemdata.special_info.diagrams_item then
            cur_light_cnt = op_itemdata.special_info.diagrams_item.light_cnt
            cur_tags = op_itemdata.special_info.diagrams_item.tags
        else
            return ErrorCode.ItemNotExist
        end
    else
        return ErrorCode.ItemNotExist
    end

    -- 检查是否达到开光次数及对应消耗配置
    local quality = uniqitem_cfg.type2
    local light_cfg = GameCfg.LightCost[quality]
    if cur_light_cnt >= light_cfg.num then
        return ErrorCode.LightMax
    end

    local cost_cfg = nil
    if cur_light_cnt == 0 then
        cost_cfg = light_cfg.cost1
    elseif cur_light_cnt == 1 then
        cost_cfg = light_cfg.cost2
    elseif cur_light_cnt == 2 then
        cost_cfg = light_cfg.cost3
    elseif cur_light_cnt == 3 then
        cost_cfg = light_cfg.cost4
    elseif cur_light_cnt == 4 then
        cost_cfg = light_cfg.cost5
    elseif cur_light_cnt == 5 then
        cost_cfg = light_cfg.cost6
    elseif cur_light_cnt == 6 then
        cost_cfg = light_cfg.cost7
    elseif cur_light_cnt == 7 then
        cost_cfg = light_cfg.cost8
    elseif cur_light_cnt == 8 then
        cost_cfg = light_cfg.cost9
    elseif cur_light_cnt == 9 then
        cost_cfg = light_cfg.cost10
    else
        return ErrorCode.LightMax
    end
    if not cost_cfg then
        return ErrorCode.ConfigError
    end

    -- 检查消耗品数量
    local cost_items = {}
    local cost_coins = {}
    for config_id, item_count in pairs(cost_cfg) do
        local small_type = scripts.ItemDefine.GetItemType(config_id)
        if small_type == scripts.ItemDefine.EItemSmallType.Coin then
            if not cost_coins[config_id] then
                cost_coins[config_id] = {
                    coin_id = 0,
                    count = 0,
                }
            end

            cost_coins[config_id].count = cost_coins[config_id].count - item_count
        else
            if not cost_items[config_id] then
                cost_items[config_id] = {
                    count = 0,
                    pos = 0,
                }
            end

            cost_items[config_id].count = cost_items[config_id].count - item_count
        end
    end
    local err_code_items = Bag.CheckItemsEnough(BagDef.BagType.Cangku, cost_items, {})
    if err_code_items ~= ErrorCode.None then
        return err_code_items
    end
    local err_code_coins = Bag.CheckCoinsEnough(cost_coins)
    if err_code_coins ~= ErrorCode.None then
        return err_code_coins
    end

    -- 随机出词条池子
    local id_weight = {}
    for pool_id, pool_weight in pairs(uniqitem_cfg.lightpooltype) do
        local pool_cfg = GameCfg.AllTagPool[pool_id]
        if not pool_cfg then
            return ErrorCode.TagPoolNotExist
        end

        for tag_id, tag_weight in pairs(pool_cfg.all_tag) do
            local tag_cfg = GameCfg.AllTag[tag_id]
            if not tag_cfg then
                return ErrorCode.TagNotExist
            end

            --现有词条去重
            local had_tag = false
            for _, tag in pairs(cur_tags) do
                if tag.id == tag_id then
                    had_tag = true
                end
            end

            if not had_tag then
                if not id_weight[tag_id] then
                    id_weight[tag_id] = tag_weight * pool_weight
                else
                    id_weight[tag_id] = id_weight[tag_id] + (tag_weight * pool_weight)
                end
            end
        end
    end
    if table.size(id_weight) <= 0 then
        return ErrorCode.TagNotExist
    end

    -- 随机词条
    local new_tag_id = scripts.Item.RangeTags(id_weight)
    if new_tag_id == 0 then
        return ErrorCode.TagDuplicate
    end
    -- 随机词条数值
    local tag_cfg = GameCfg.AllTag[new_tag_id]
    if not tag_cfg then
        return ErrorCode.TagNotExist
    end
    local new_tag_value = math.random(tag_cfg.min, tag_cfg.max)

    -- 扣除消耗品
    local change_log = {}
    local err_code_del = ErrorCode.None
    if table.size(cost_items) > 0 then
        err_code_del = Bag.DelItems(BagDef.BagType.Cangku, cost_items, {}, change_log)
        if err_code_del ~= ErrorCode.None then
            Bag.RollBackWithChange(change_log, {})
            return err_code_del
        end
    end
    if table.size(cost_coins) > 0 then
        err_code_del = Bag.DealCoins(cost_coins, change_log)
        if err_code_del ~= ErrorCode.None then
            Bag.RollBackWithChange(change_log, {})
            return err_code_del
        end
    end

    -- 修改属性
    local new_tag = {
        id = new_tag_id,
        value = new_tag_value,
    }
    if op_itemdata.itype == scripts.ItemDefine.EItemSmallType.MagicItem then
        op_itemdata.special_info.magic_item.light_cnt = cur_light_cnt + 1
        table.insert(op_itemdata.special_info.magic_item.tags, new_tag)
    elseif op_itemdata.itype == scripts.ItemDefine.EItemSmallType.HumanDiagrams
        or op_itemdata.itype == scripts.ItemDefine.EItemSmallType.GhostDiagrams then
        op_itemdata.special_info.diagrams_item.light_cnt = cur_light_cnt + 1
        table.insert(op_itemdata.special_info.diagrams_item.tags, new_tag)
    else
        Bag.RollBackWithChange(change_log, {})
        return ErrorCode.ItemNotExist
    end

    return ErrorCode.None, change_log
end

return Bag