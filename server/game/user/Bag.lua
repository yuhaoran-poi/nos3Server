local moon = require "moon"
local common = require "common"
local uuid = require "uuid"
local json = require "json"
local GameCfg = common.GameCfg
local ErrorCode = common.ErrorCode
local CmdCode = common.CmdCode
local Database = common.Database
local BagDef = require("common.def.BagDef")
local ItemDef = require("common.def.ItemDef")

---@type user_context
local context = ...
local scripts = context.scripts
local AbilityTagIdMin = 1000000

-- local ItemType = {
--     ALL = 1,
--     Consume = 2,
-- }

---@class Bag
local Bag = {}

function Bag.Init()
    
end

-- function Bag.Start()
    
-- end

function Bag.Start()
    local bagTypes = {}
    bagTypes[BagDef.BagType.Cangku] = 1
    bagTypes[BagDef.BagType.Consume] = 1
    bagTypes[BagDef.BagType.Booty] = 1

    local baginfos = Bag.LoadBags(bagTypes)
    --local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
    if baginfos then
        scripts.UserModel.SetBagData(baginfos)
    end

    local bagdata = scripts.UserModel.GetBagData()
    if not bagdata then
        bagdata = BagDef.newBags()
        bagdata[BagDef.BagType.Cangku].bag_item_type = scripts.ItemDefine.ItemBagType.ALL
        bagdata[BagDef.BagType.Consume].bag_item_type = scripts.ItemDefine.ItemBagType.CONSUME
        bagdata[BagDef.BagType.Booty].bag_item_type = scripts.ItemDefine.ItemBagType.ALL

        local init_cfg = GameCfg.Init[1]
        if not init_cfg then
            return { code = ErrorCode.ConfigError, error = "no init_cfg" }
        end
        scripts.UserModel.SetBagData(bagdata)

        local init_items = {}
        local change_log = {}
        for k, v in pairs(init_cfg.item) do
            local bigType = scripts.ItemDefine.GetItemPosType(k)
            if bigType == scripts.ItemDefine.EItemBigType.StackItem
                or bigType == scripts.ItemDefine.EItemBigType.UnStackItem
                or bigType == scripts.ItemDefine.EItemBigType.UniqueItem then
                init_items[k] = { count = v }
            end
        end
        if table.size(init_items) > 0 then
            scripts.Bag.AddItems(BagDef.BagType.Cangku, init_items, {}, change_log)
        end

        Bag.SaveBagsNow(bagTypes)
    end

    local coininfos = Bag.LoadCoins()
    if coininfos then
        scripts.UserModel.SetCoinsData(coininfos)
    end

    local coinsdata = scripts.UserModel.GetCoinsData()
    if not coinsdata then
        coinsdata = BagDef.newPBUserCoins()

        local init_cfg = GameCfg.Init[1]
        if not init_cfg then
            return { code = ErrorCode.ConfigError, error = "no init_cfg" }
        end
        scripts.UserModel.SetCoinsData(coinsdata)

        local init_coins = {}
        local change_log = {}
        for k, v in pairs(init_cfg.item) do
            local bigType = scripts.ItemDefine.GetItemPosType(k)
            if bigType == scripts.ItemDefine.EItemBigType.Coin then
                init_coins[k] = {
                    coin_id = k,
                    count = v,
                }
            end
        end
        if table.size(init_coins) > 0 then
            scripts.Bag.DealCoins(init_coins, change_log)
        end

        Bag.SaveCoinsNow()
    end

    -- 将所有背包中的道具序列化
    --local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
    Bag.dataMap = {}
    for bagType, baginfo in pairs(bagdata) do
        for pos, itemdata in pairs(baginfo.items) do
            if not Bag.dataMap[itemdata.common_info.config_id] then
                Bag.dataMap[itemdata.common_info.config_id] = {}
            end
            if not Bag.dataMap[itemdata.common_info.config_id][bagType] then
                Bag.dataMap[itemdata.common_info.config_id][bagType] = {
                    allCount = 0,
                    pos_count = {},
                    uniqid_pos = {},
                }
            end

            local data = Bag.dataMap[itemdata.common_info.config_id][bagType]
            if itemdata.common_info.uniqid == 0 then
                data.pos_count[pos] = itemdata.common_info.item_count
                data.allCount = data.allCount + itemdata.common_info.item_count
            else
                data.uniqid_pos[itemdata.common_info.uniqid] = pos
                data.allCount = data.allCount + 1
            end
        end
    end
end

function Bag.SaveBagsNow(bagTypes)
    local bagdata = scripts.UserModel.GetBagData()
    if not bagdata then
        return false
    end

    local save_bags = {}
    --local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
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

function Bag.RollBackWithChange(change_logs)
    if not change_logs or table.size(change_logs) == 0 then
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
    for bagType, logs in pairs(change_logs) do
        if bagType == BagDef.BagType.Coins then
            for coinid, log in pairs(logs) do
                coinsdata.coins[coinid].coin_count = log.old_count
            end
        else
            local baginfo = bagdata[bagType]
            if baginfo then
                for pos, log in pairs(logs) do
                    if log.change_type == BagDef.LogType.ChangeNum
                        and baginfo.items[pos] then
                        baginfo.items[pos].common_info.item_count = log.old_count
                        if baginfo.items[pos].common_info.item_count == 0 then
                            baginfo.items[pos] = nil
                        end
                    elseif log.change_type == BagDef.LogType.ChangeInfo then
                        baginfo.items[pos] = table.copy(log.old_itemdata)
                    end
                end
            end
        end
    end
end

function Bag.SaveAndLog(bagTypes, change_logs)
    local success = true

    local bagdata = scripts.UserModel.GetBagData()
    if not bagdata then
        return
    end

    local coinsdata = scripts.UserModel.GetCoinsData()
    if not coinsdata then
        return
    end

    -- 修改dataMap
    -- 去掉已经为0的道具格子
    -- 将变更记录作为PBBagUpdateSyncCmd发送
    local update_msg = {
        update_items = {},
        update_coins = {},
    }
    if change_logs then
        for bagType, logs in pairs(change_logs) do
            if bagType ~= BagDef.BagType.Coins then
                local baginfo = bagdata[bagType]
                if not baginfo then
                    return
                end

                if not update_msg.update_items[bagType] then
                    update_msg.update_items[bagType] = {
                        bag_item_type = baginfo.bag_item_type,
                        capacity = baginfo.capacity,
                        items = {},
                    }
                end

                for pos, loginfo in pairs(logs) do
                    local now_itemdata = baginfo.items[pos]
                    update_msg.update_items[bagType].items[pos] = now_itemdata
                    loginfo.new_config_id = now_itemdata.common_info.config_id
                    loginfo.new_uniqid = now_itemdata.common_info.uniqid
                    loginfo.new_count = now_itemdata.common_info.item_count

                    -- 处理dataMap变更
                    if not Bag.dataMap[loginfo.new_config_id] then
                        Bag.dataMap[loginfo.new_config_id] = {}
                    end
                    if not Bag.dataMap[loginfo.new_config_id][bagType] then
                        Bag.dataMap[loginfo.new_config_id][bagType] = {
                            allCount = 0,
                            pos_count = {},
                            uniqid_pos = {},
                        }
                    end

                    if Bag.dataMap[loginfo.old_config_id]
                        and Bag.dataMap[loginfo.old_config_id][bagType] then
                        Bag.dataMap[loginfo.old_config_id][bagType].allCount = Bag.dataMap
                            [loginfo.old_config_id][bagType].allCount - loginfo.old_count
                    end
                    Bag.dataMap[loginfo.new_config_id][bagType].allCount = Bag.dataMap
                        [loginfo.new_config_id][bagType].allCount + loginfo.new_count

                    if Bag.dataMap[loginfo.old_config_id]
                        and Bag.dataMap[loginfo.old_config_id][bagType] then
                        if loginfo.old_uniqid ~= 0 then
                            Bag.dataMap[loginfo.old_config_id][bagType].uniqid_pos[loginfo.old_uniqid] = nil
                        else
                            Bag.dataMap[loginfo.old_config_id][bagType].pos_count[pos] = nil
                        end
                    end
                    if loginfo.new_uniqid ~= 0 then
                        Bag.dataMap[loginfo.new_config_id][bagType].uniqid_pos[loginfo.new_uniqid] = pos
                    else
                        Bag.dataMap[loginfo.new_config_id][bagType].pos_count[pos] = loginfo.new_count
                    end

                    -- 去掉已经为0的道具格子
                    if loginfo.log_type == BagDef.LogType.ChangeNum then
                        if baginfo.items[pos].common_info.item_count == 0 then
                            baginfo.items[pos] = nil
                            update_msg.update_items[bagType].items[pos] = {}
                        end
                    elseif loginfo.log_type == BagDef.LogType.ChangeInfo then
                        if baginfo.items[pos].common_info.item_count == 0 then
                            baginfo.items[pos] = nil
                            update_msg.update_items[bagType].items[pos] = {}
                        else
                            -- 记录ChangeInfo后的新itemdata
                            loginfo.new_itemdata = table.copy(now_itemdata, true)
                        end
                    end
                end
            else
                if not update_msg.update_coins then
                    update_msg.update_coins = {}
                end

                for coinid, _ in pairs(logs) do
                    update_msg.update_coins[coinid] = coinsdata.coins[coinid]
                end
            end
        end
    end

    if bagTypes and bagTypes[BagDef.BagType.Coins] then
        success = Bag.SaveCoinsNow()
    end
    
    local success = Bag.SaveBagsNow(bagTypes)

    --发送PBBagUpdateSyncCmd
    if success then
        --local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
        context.S2C(context.net_id, CmdCode["PBBagUpdateSyncCmd"], update_msg, 0)
    end

    --存储日志

    return success
end

-- function Bag.BagGetChangeItems(change_logs)
--     local change_items = {}

--     local bagdata = scripts.UserModel.GetBagData()
--     if not bagdata then
--         return change_items
--     end

--     for bagType, logs in pairs(change_logs) do
--         if not change_items[bagType] then
--             change_items[bagType] = {}
--         end

--         local baginfo = bagdata[bagType]
--         change_items[bagType].bag_item_type = baginfo.bag_item_type
--         change_items[bagType].capacity = baginfo.capacity
--         change_items[bagType].items = {}
--         for pos, _ in pairs(logs) do
--             if baginfo.items[pos] then
--                 change_items[bagType].items[pos] = baginfo.items[pos]
--             else
--                 change_items[bagType].items[pos] = {}
--             end
--         end
--     end

--     return change_items
-- end

function Bag.AddLog(logs, pos, log_type, old_itemid, old_uniqid, old_count, old_itemdata)
    logs[pos] = {
        log_type = log_type,
        old_config_id = old_itemid,
        old_uniqid = old_uniqid,
        old_count = old_count,
        old_itemdata = {},
    }

    if log_type == BagDef.LogType.ChangeInfo then
        logs[pos].old_itemdata = old_itemdata
    end
end

-- 添加物品（支持自动堆叠）
function Bag.AddItem(bagType, baginfo, itemId, count, logs)
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

            Bag.AddLog(logs, pos, BagDef.LogType.ChangeNum, itemId, 0, itemdata.common_info.item_count)
            itemdata.common_info.item_count = itemdata.common_info.item_count + canAdd
            
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

            Bag.AddLog(logs, pos, BagDef.LogType.ChangeNum, 0, 0, 0)
            baginfo.items[pos] = new_item

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

function Bag.DelItem(bagType, baginfo, itemId, count, pos, logs)
    local item_cfg = GameCfg.Item[itemId]
    if not item_cfg then
        return ErrorCode.ItemNotExist
    end

    local remaining = count

    if pos > 0 then
        local itemdata = baginfo.items[pos]
        if not itemdata
            or itemdata.common_info.config_id ~= itemId
            or itemdata.common_info.uniqid ~= 0
            or itemdata.common_info.item_count + remaining < 0 then
            return ErrorCode.ItemNotEnough
        end

        Bag.AddLog(logs, pos, BagDef.LogType.ChangeNum, itemId, 0, itemdata.common_info.item_count)
        itemdata.common_info.item_count = itemdata.common_info.item_count + remaining
        
        remaining = 0
    else
        -- 先尝试扣减
        for pos, itemdata in pairs(baginfo.items) do
            if itemdata.common_info.config_id == itemId
                and itemdata.common_info.uniqid == 0
                and itemdata.common_info.item_count > 0 then
                local canSub = math.min(itemdata.common_info.item_count, -remaining)

                Bag.AddLog(logs, pos, BagDef.LogType.ChangeNum, itemId, 0, itemdata.common_info.item_count)
                itemdata.common_info.item_count = itemdata.common_info.item_count - canSub

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

function Bag.AddUniqItem(bagType, baginfo, itemId, uniqid, itype, logs)
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
            Bag.AddLog(logs, pos, BagDef.LogType.ChangeNum, 0, 0, 0)

            return ErrorCode.None, pos
        end
    end

    return ErrorCode.BagFull
end

function Bag.AddUniqItemData(bagType, baginfo, item_data, logs)
    --local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
    if not item_data or not item_data.common_info then
        return ErrorCode.ItemNotExist
    end

    -- 处理物品记录
    for pos = 1, baginfo.capacity do
        if not baginfo.items[pos] then
            baginfo.items[pos] = table.copy(item_data)
            Bag.AddLog(logs, pos, BagDef.LogType.ChangeNum, 0, 0, 0)

            return ErrorCode.None, pos
        end
    end

    return ErrorCode.BagFull
end

function Bag.DelUniqItem(bagType, baginfo, itemId, uniqid, pos, logs)
    -- 参数校验
    if not baginfo.items[pos] then
        return ErrorCode.ItemNotExist
    end
    if baginfo.items[pos].common_info.config_id ~= itemId
        or baginfo.items[pos].common_info.uniqid ~= uniqid
        or baginfo.items[pos].common_info.item_count ~= 1 then
        return ErrorCode.ItemNotExist
    end

    baginfo.items[pos].common_info.item_count = 0
    -- 处理物品记录
    Bag.AddLog(logs, pos, BagDef.LogType.ChangeNum, itemId, uniqid, 1)

    return ErrorCode.None
end

function Bag.AddMagicItem(bagType, baginfo, itemId, count, change_log)
    for i = 1, count do
        local uniqid = uuid.next()
        local errorCode, add_pos = Bag.AddUniqItem(bagType, baginfo, itemId, uniqid,
        scripts.ItemDefine.EItemSmallType.MagicItem,
            change_log)
        if errorCode ~= ErrorCode.None or not add_pos then
            return errorCode
        end

        local itemdata = baginfo.items[add_pos]
        itemdata.special_info = {
            magic_item = ItemDef.newMagicItem(),
        }
        itemdata.special_info.magic_item.cur_durability = 0
        itemdata.special_info.magic_item.strong_value = 0
        itemdata.special_info.magic_item.light_cnt = 0
        itemdata.special_info.magic_item.tags = {}
        itemdata.special_info.magic_item.ability_tag = {}
    end

    --添加法器图鉴
    --scripts.ItemImage.AddMagicItemImage(itemId)

    return ErrorCode.None
end

function Bag.AddDiagramsCard(bagType, baginfo, itemId, count, change_log)
    local itype = scripts.ItemDefine.GetItemType(itemId)
    for i = 1, count do
        local uniqid = uuid.next()
        local errorCode, add_pos = Bag.AddUniqItem(bagType, baginfo, itemId, uniqid, itype, change_log)
        if errorCode ~= ErrorCode.None or not add_pos then
            return errorCode
        end

        local itemdata = baginfo.items[add_pos]
        itemdata.special_info = {
            diagrams_item = ItemDef.newDiagramsCard(),
        }
        itemdata.special_info.diagrams_item.cur_durability = 0
        itemdata.special_info.diagrams_item.strong_value = 0
        itemdata.special_info.diagrams_item.light_cnt = 0
        itemdata.special_info.diagrams_item.tags = {}
        itemdata.special_info.diagrams_item.ability_tag = {}
    end

    --添加八卦牌图鉴
    --scripts.ItemImage.AddDiagramsCardImage(itemId)

    return ErrorCode.None
end

function Bag.GetItemCount(config_id, bagType)
    if not Bag.dataMap[config_id] then
        return 0
    end

    if not bagType then
        local count = 0
        for bag_type, mapinfo in pairs(Bag.dataMap[config_id]) do
            count = count + mapinfo.allCount
        end

        return count
    else
        if not Bag.dataMap[config_id][bagType] then
            return 0
        end

        return Bag.dataMap[config_id][bagType].allCount
    end
end

function Bag.GetItemPosNum(config_id, bagType)
    if not Bag.dataMap[config_id] then
        return 0
    end

    if not bagType then
        local count = 0
        for bag_type, mapinfo in pairs(Bag.dataMap[config_id]) do
            count = table.size(mapinfo.pos_count) + table.size(mapinfo.uniq_count)
        end

        return count
    else
        if not Bag.dataMap[config_id][bagType] then
            return 0
        end

        return table.size(Bag.dataMap[config_id][bagType].pos_count) +
        table.size(Bag.dataMap[config_id][bagType].uniq_count)
    end
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
        if item.count >= 0 then
            return ErrorCode.ParamInvalid
        end

        local remaining = item.count
        if item.pos ~= 0 then
            if not baginfo.items[item.pos]
                or baginfo.items[item.pos].common_info.config_id ~= itemid
                or baginfo.items[item.pos].common_info.item_count + remaining < 0 then
                return ErrorCode.ItemNotExist
            else
                if baginfo.items[item.pos].common_info.item_count + remaining < 0 then
                    return ErrorCode.ItemNotEnough
                end
            end
        else
            local count = Bag.GetItemCount(itemid, bagType)

            if count + remaining < 0 then
                return ErrorCode.ItemNotEnough
            end
        end
    end

    return ErrorCode.None
end

function Bag.CheckItemsEnoughPos(bagType, del_items)
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

    for pos, item in pairs(del_items) do
        if item.item_count >= 0 then
            return ErrorCode.ParamInvalid
        end

        if del_items.uniqid == 0 then
            if not baginfo.items[pos]
                or baginfo.items[pos].common_info.config_id ~= item.config_id
                or baginfo.items[pos].common_info.item_count + item.item_count < 0 then
                return ErrorCode.ItemNotEnough
            end
        else
            if not baginfo.items[pos]
                or baginfo.items[pos].common_info.uniqid ~= item.uniqid
                or baginfo.items[pos].common_info.item_count + item.item_count < 0 then
                return ErrorCode.ItemNotEnough
            end
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
            if not coinsdata.coins[coinid] or coinsdata.coins[coinid].coin_count + coin.count < 0 then
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
    --local baginfo = bagdata[bagType]
    local empty_pos_num = Bag.GetEmptyPosNum(bagType)

    -- 计算背包空间是否足够
    for itemid, item in pairs(add_items) do
        if item.count < 0 then
            return ErrorCode.ParamInvalid
        end
        local item_cfg = GameCfg.Item[itemid]
        local uniqitem_cfg = GameCfg.UniqueItem[itemid]
        if not item_cfg and not uniqitem_cfg then
            return ErrorCode.ConfigError
        end

        local item_big_type = scripts.ItemDefine.GetItemPosType(itemid)
        if item_big_type == scripts.ItemDefine.EItemBigType.StackItem and item_cfg then
            local remaining = item.count
            local now_cnt = Bag.GetItemCount(itemid, bagType)
            local now_pos_num = Bag.GetItemPosNum(itemid, bagType)
            local need_pos = math.ceil((remaining + now_cnt) / item_cfg.stack_count)
            if now_pos_num < need_pos then
                empty_pos_num = empty_pos_num - (need_pos - now_pos_num)
                if empty_pos_num < 0 then
                    return ErrorCode.BagFull
                end
            end
        elseif (item_big_type == scripts.ItemDefine.EItemBigType.UnStackItem and uniqitem_cfg)
            or (item_big_type == scripts.ItemDefine.EItemBigType.UniqueItem and uniqitem_cfg) then
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
            err_code = Bag.DelUniqItem(bagType, baginfo, uniqitem.config_id, uniqitem.uniqid, uniqitem.pos, change_log[bagType])
            if err_code ~= ErrorCode.None then
                return err_code
            end
        end
    end

    for itemid, item in pairs(del_items) do
        if item.count >= 0 then
            return ErrorCode.ParamInvalid
        end

        err_code = Bag.DelItem(bagType, baginfo, itemid, item.count, item.pos, change_log[bagType])
        if err_code ~= ErrorCode.None then
            return err_code
        end
    end

    return ErrorCode.None
end

function Bag.DelItemsPos(bagType, del_items, change_log)
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
    for pos, item in pairs(del_items) do
        if item.item_count >= 0 then
            return ErrorCode.ParamInvalid
        end

        if item.uniqid == 0 then
            err_code = Bag.DelItem(bagType, baginfo, item.config_id, item.item_count, pos, change_log[bagType])
        else
            err_code = Bag.DelUniqItem(bagType, baginfo, item.config_id, item.uniqid, pos, change_log[bagType])
        end
        if err_code ~= ErrorCode.None then
            return err_code
        end
    end

    return ErrorCode.None
end

function Bag.AddItems(bagType, add_items, add_item_datas, change_log)
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
    --local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
    for itemid, item in pairs(add_items) do
        if item.count < 0 then
            return ErrorCode.ParamInvalid
        end

        local item_big_type = scripts.ItemDefine.GetItemPosType(itemid)
        local item_small_type = scripts.ItemDefine.GetItemType(itemid)
        if item_big_type == scripts.ItemDefine.EItemBigType.StackItem then
            err_code = Bag.AddItem(bagType, baginfo, itemid, item.count, change_log[bagType])
            if err_code ~= ErrorCode.None then
                return err_code
            end
        elseif item_big_type == scripts.ItemDefine.EItemBigType.UnStackItem
            or item_big_type == scripts.ItemDefine.EItemBigType.UniqueItem then
            if item_small_type == scripts.ItemDefine.EItemSmallType.DurabItem then
                -- 执行不可堆叠道具添加
            elseif item_small_type == scripts.ItemDefine.EItemSmallType.HumanDiagrams
                or item_small_type == scripts.ItemDefine.EItemSmallType.GhostDiagrams then
                err_code = Bag.AddDiagramsCard(bagType, baginfo, itemid, item.count, change_log[bagType])
                if err_code ~= ErrorCode.None then
                    return err_code
                end
            elseif item_small_type == scripts.ItemDefine.EItemSmallType.MagicItem then
                err_code = Bag.AddMagicItem(bagType, baginfo, itemid, item.count, change_log[bagType])
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

    for uniqid, item_data in pairs(add_item_datas) do
        err_code = Bag.AddUniqItemData(bagType, baginfo, item_data, change_log[bagType])
        if err_code ~= ErrorCode.None then
            return err_code
        end
    end

    -- 判断图鉴是否需要更新
    --local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
    local change_image_ids = {}
    for pos, log in pairs(change_log[bagType]) do
        if log.log_type == BagDef.LogType.ChangeNum
            and log.old_config_id == 0
            and log.old_count == 0
            and baginfo.items[pos] then
            local item_small_type = scripts.ItemDefine.GetItemType(baginfo.items[pos].common_info.config_id)
            if item_small_type == scripts.ItemDefine.EItemSmallType.HumanDiagrams
                or item_small_type == scripts.ItemDefine.EItemSmallType.GhostDiagrams then
                scripts.ItemImage.AddDiagramsCardImage(baginfo.items[pos].common_info.config_id, change_image_ids)
            elseif item_small_type == scripts.ItemDefine.EItemSmallType.MagicItem then
                scripts.ItemImage.AddMagicItemImage(baginfo.items[pos].common_info.config_id, change_image_ids)
            end
        end
    end
    -- 发送图鉴更新消息
    if table.size(change_image_ids) > 0 then
        scripts.ItemImage.SaveAndLog(change_image_ids)
    end

    return ErrorCode.None
end

function Bag.DealCoins(coins, change_log)
    local coinsdata = scripts.UserModel.GetCoinsData()
    if not coinsdata then
        return ErrorCode.CoinNotExist
    end
    
    for coinid, coin in pairs(coins) do
        if coin.count < 0 and not coinsdata.coins[coinid] then
            Bag.RollBackWithChange(change_log)
            return ErrorCode.CoinNotExist
        end

        if not coinsdata.coins[coinid] then
            coinsdata.coins[coinid] = {
                coin_id = coinid,
                coin_count = 0,
            }
        end

        if not change_log[BagDef.BagType.Coins] then
            change_log[BagDef.BagType.Coins] = {}
        end
        Bag.AddLog(change_log[BagDef.BagType.Coins], coinid, BagDef.LogType.ChangeNum, coinid, 0, coinsdata.coins[coinid].coin_count)

        coinsdata.coins[coinid].coin_count = coinsdata.coins[coinid].coin_count + coin.count
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
    if not change_log then
        change_log = {}
    end
    if not change_log[destBagType] then
        change_log[destBagType] = {}
    end
    Bag.AddLog(change_log[destBagType], destPos, BagDef.LogType.ChangeNum, destItem.common_info.config_id,
        0, destItem.common_info.item_count)
    destItem.common_info.item_count = destItem.common_info.item_count + move_count

    if not change_log[srcBagType] then
        change_log[srcBagType] = {}
    end
    Bag.AddLog(change_log[srcBagType], srcPos, BagDef.LogType.ChangeNum, srcItem.common_info.config_id,
        0, srcItem.common_info.item_count)
    srcItem.common_info.item_count = srcItem.common_info.item_count - move_count

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
    if not change_log then
        change_log = {}
    end
    if not change_log[srcBagType] then
        change_log[srcBagType] = {}
    end
    Bag.AddLog(change_log[srcBagType], srcPos, BagDef.LogType.ChangeNum, srcItem.common_info.config_id,
        0, srcItem.common_info.item_count)
    srcItem.common_info.item_count = srcItem.common_info.item_count - splitCount

    if not change_log[destBagType] then
        change_log[destBagType] = {}
    end
    Bag.AddLog(change_log[destBagType], destPos, BagDef.LogType.ChangeNum, srcItem.common_info.config_id, 0, 0)
    destBag.items[destPos] = table.copy(srcItem)
    destBag.items[destPos].common_info.item_count = splitCount

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
    if not change_log then
        change_log = {}
    end
    if not change_log[srcBagType] then
        change_log[srcBagType] = {}
    end
    Bag.AddLog(change_log[srcBagType], srcPos, BagDef.LogType.ChangeInfo, srcItem.common_info.config_id,
        srcItem.common_info.uniqid, srcItem.common_info.item_count, table.copy(srcItem))

    if destItem then
        -- 交换物品
        srcBag.items[srcPos] = destItem
        if not change_log[srcBagType] then
            change_log[srcBagType] = {}
        end
        Bag.AddLog(change_log[destBagType], destPos, BagDef.LogType.ChangeInfo, destItem.common_info.config_id,
        destItem.common_info.uniqid, destItem.common_info.item_count, table.copy(destItem))
        destBag.items[destPos] = srcItem

    else
        -- 移动到空位
        if not change_log[srcBagType] then
            change_log[srcBagType] = {}
        end
        Bag.AddLog(change_log[destBagType], destPos, BagDef.LogType.ChangeInfo, 0, 0, 0, nil)
        destBag.items[destPos] = srcItem
        srcBag.items[srcPos] = nil
    end

    return ErrorCode.None
end

---@return integer, PBItemData ? nil
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

    return ErrorCode.None, table.copy(baginfo.items[pos])
end

---@return integer, PBItemData ? nil
function Bag.MutOneItemData(bagType, pos)
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

-- function Bag.SetOneItemData(bagType, pos, itemdata)
--     -- 获取数据副本
--     local bagdata = scripts.UserModel.GetBagData()
--     if not bagdata then
--         return ErrorCode.BagNotExist
--     end

--     local baginfo = bagdata[bagType]
--     if not baginfo then
--         return ErrorCode.BagNotExist
--     end

--     baginfo.items[pos] = table.copy(itemdata)

--     return ErrorCode.None, baginfo.items[pos]
-- end

function Bag.GetBagdata(bags_name)
    local bagdata = scripts.UserModel.GetBagData()
    if not bagdata then
        return { errcode = ErrorCode.BagNotExist }
    end

    local res = {
        errcode = ErrorCode.None,
        bag_datas = {}
    }
    for _, bag_name in pairs(bags_name) do
        if bag_name ~= BagDef.BagType.Cangku
            and bag_name ~= BagDef.BagType.Consume
            and bag_name ~= BagDef.BagType.Booty then
            return { errcode = ErrorCode.BagNotExist }
        end

        if bagdata[bag_name] then
            res.bag_datas[bag_name] = bagdata[bag_name]
        end
    end

    return res
end

function Bag.InlayTabooWord(taboo_word_id, inlay_type, uniqid)
    local err_code, item_data = Bag.MutOneItemData(BagDef.BagType.Cangku, uniqid)
    if err_code ~= ErrorCode.None or not item_data then
        return err_code
    end

    if inlay_type == 1 then
        if not item_data.special_info
            or not item_data.special_info.magic_item then
            return ErrorCode.ItemNotExist
        end
    else
        if not item_data.special_info
            or not item_data.special_info.diagrams_item then
            return ErrorCode.ItemNotExist
        end
    end

    local uniqitem_cfg = GameCfg.UniqueItem[item_data.common_info.config_id]
    local item_cfg = GameCfg.Item[taboo_word_id]
    if not uniqitem_cfg or not item_cfg then
        return ErrorCode.ConfigError
    end
    if uniqitem_cfg.type4 ~= item_cfg.type4 then
        return ErrorCode.InlayTypeNotMatch
    end
    if inlay_type ~= 1 and uniqitem_cfg.type5 ~= item_cfg.type5 then
        return ErrorCode.InlayTypeNotMatch
    end

    -- 扣除道具消耗
    local cost_items = {}
    cost_items[taboo_word_id] = {
        count = -1,
        pos = 0,
    }
    local err_code = Bag.CheckItemsEnough(BagDef.BagType.Cangku, cost_items, {})
    if err_code ~= ErrorCode.None then
        return ErrorCode.ItemNotEnough
    end

    local bag_change_log = {}
    local err_code_del = Bag.DelItems(BagDef.BagType.Cangku, cost_items, {}, bag_change_log)
    if err_code_del ~= ErrorCode.None then
        Bag.RollBackWithChange(bag_change_log)
        return ErrorCode.ItemNotEnough
    end

    -- 镶嵌讳字
    if inlay_type == 1 then
        item_data.special_info.magic_item.tabooword_id = taboo_word_id
    else
        item_data.special_info.diagrams_item.tabooword_id = taboo_word_id
    end

    return ErrorCode.None, bag_change_log
end

function Bag.PBBagGetDataReqCmd(req)
    if table.size(req.msg.bags_name) <= 0 then
        return context.S2C(context.net_id, CmdCode["PBBagGetDataRspCmd"],
            { code = ErrorCode.ParamInvalid, error = "参数错误", uid = context.uid }, req.msg_context.stub_id)
    end

    local res = {
        code = ErrorCode.None,
        error = "",
        uid = context.uid,
        bag_datas = {},
    }
    local ret = Bag.GetBagdata(req.msg.bags_name)
    if ret.errcode ~= ErrorCode.None or table.size(ret.bag_datas) <= 0 then
        res.code = ret.errcode
        return context.S2C(context.net_id, CmdCode["PBBagGetDataRspCmd"], res, req.msg_context.stub_id)
    else
        res.bag_datas = ret.bag_datas
        return context.S2C(context.net_id, CmdCode["PBBagGetDataRspCmd"], res, req.msg_context.stub_id)
    end
end

function Bag.PBBagGetCoinsReqCmd(req)
    local coinsdata = scripts.UserModel.GetCoinsData()
    if not coinsdata then
        return context.S2C(context.net_id, CmdCode["PBBagGetCoinsRspCmd"],
            { code = ErrorCode.BagNotExist, error = "货币未加载", uid = context.uid }, req.msg_context.stub_id)
    end

    --local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
    local res = {
        code = ErrorCode.None,
        error = "",
        uid = context.uid,
        coin_datas = coinsdata,
    }

    return context.S2C(context.net_id, CmdCode["PBBagGetCoinsRspCmd"], res, req.msg_context.stub_id)
end

function Bag.PBBagOperateItemReqCmd(req)
    local err_code, change_logs = ErrorCode.ParamInvalid, {}
    if req.msg.operate_type == 1 then
        err_code = Bag.StackItems(req.msg.src_bag, req.msg.src_pos, req.msg.dest_bag, req.msg.dest_pos, change_logs)
    elseif req.msg.operate_type == 2 then
        err_code = Bag.SplitItem(req.msg.src_bag, req.msg.src_pos, req.msg.dest_bag, req.msg.dest_pos,
        req.msg.splitCount, change_logs)
    elseif req.msg.operate_type == 3 then
        err_code = Bag.MoveItem(req.msg.src_bag, req.msg.src_pos, req.msg.dest_bag, req.msg.dest_pos, change_logs)
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

    --local change_items = Bag.BagGetChangeItems(change_logs)
    return context.S2C(context.net_id, CmdCode["PBBagOperateItemRspCmd"],
        { code = ErrorCode.None, error = "", uid = context.uid },
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
    del_items[item_id] = { count = -1, pos = srcPos}
    local add_items = {}
    add_items[convert_config_id] = { count = 1, pos = 0 }
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
    --local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
    err_code = Bag.DelItems(BagDef.BagType.Cangku, del_items, {}, change_log)
    if err_code ~= ErrorCode.None then
        Bag.RollBackWithChange(change_log)
        return err_code
    end
    -- 添加道具
    err_code = Bag.AddItems(BagDef.BagType.Cangku, add_items, {}, change_log)
    if err_code ~= ErrorCode.None then
        Bag.RollBackWithChange(change_log)
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
    local cur_ability_tag = {}
    if op_itemdata.itype == scripts.ItemDefine.EItemSmallType.MagicItem then
        if op_itemdata.special_info and op_itemdata.special_info.magic_item then
            cur_light_cnt = op_itemdata.special_info.magic_item.light_cnt
            cur_tags = op_itemdata.special_info.magic_item.tags
            cur_ability_tag = op_itemdata.special_info.magic_item.ability_tag
        else
            return ErrorCode.ItemNotExist
        end
    elseif op_itemdata.itype == scripts.ItemDefine.EItemSmallType.HumanDiagrams
        or op_itemdata.itype == scripts.ItemDefine.EItemSmallType.GhostDiagrams then
        if op_itemdata.special_info and op_itemdata.special_info.diagrams_item then
            cur_light_cnt = op_itemdata.special_info.diagrams_item.light_cnt
            cur_tags = op_itemdata.special_info.diagrams_item.tags
            cur_ability_tag = op_itemdata.special_info.diagrams_item.ability_tag
        else
            return ErrorCode.ItemNotExist
        end
    else
        return ErrorCode.ItemNotExist
    end

    -- 检查是否达到开光次数及对应消耗配置
    -- local quality = uniqitem_cfg.type2
    local light_cfg = GameCfg.LightInfo[op_itemdata.common_info.config_id]
    if cur_light_cnt >= light_cfg.tagnum then
        return ErrorCode.LightMax
    end

    local cost_cfg = nil
    if cur_light_cnt == 0 then
        cost_cfg = light_cfg.tagcost1
    elseif cur_light_cnt == 1 then
        cost_cfg = light_cfg.tagcost2
    elseif cur_light_cnt == 2 then
        cost_cfg = light_cfg.tagcost3
    elseif cur_light_cnt == 3 then
        cost_cfg = light_cfg.tagcost4
    elseif cur_light_cnt == 4 then
        cost_cfg = light_cfg.tagcost5
    elseif cur_light_cnt == 5 then
        cost_cfg = light_cfg.tagcost6
    elseif cur_light_cnt == 6 then
        cost_cfg = light_cfg.tagcost7
    elseif cur_light_cnt == 7 then
        cost_cfg = light_cfg.tagcost8
    elseif cur_light_cnt == 8 then
        cost_cfg = light_cfg.tagcost9
    elseif cur_light_cnt == 9 then
        cost_cfg = light_cfg.tagcost10
    else
        return ErrorCode.LightMax
    end
    if not cost_cfg then
        return ErrorCode.ConfigError
    end

    -- 检查消耗品数量
    local cost_items, cost_coins = {}, {}
    scripts.Item.GetItemsFromCfg(cost_cfg, 1, true, cost_items, cost_coins)
    local err_code_items = Bag.CheckItemsEnough(BagDef.BagType.Cangku, cost_items, {})
    if err_code_items ~= ErrorCode.None then
        return err_code_items
    end
    local err_code_coins = Bag.CheckCoinsEnough(cost_coins)
    if err_code_coins ~= ErrorCode.None then
        return err_code_coins
    end

    --local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
    -- 随机出词条池子
    local light_cfg
    local id_weight = {}
    for pool_id, pool_weight in pairs(light_cfg.lightpooltype) do
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
    if table.size(cur_ability_tag) == 0 then
        for pool_id, pool_weight in pairs(light_cfg.lightpooltype2) do
            local pool_cfg = GameCfg.AllTagPool[pool_id]
            if not pool_cfg then
                return ErrorCode.TagPoolNotExist
            end

            for tag_id, tag_weight in pairs(pool_cfg.all_tag) do
                local tag_cfg = GameCfg.AllTag[tag_id]
                if not tag_cfg then
                    return ErrorCode.TagNotExist
                end

                if not id_weight[tag_id] then
                    id_weight[tag_id] = tag_weight * pool_weight
                else
                    id_weight[tag_id] = id_weight[tag_id] + (tag_weight * pool_weight)
                end
            end
        end
    end
    --local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
    if table.size(id_weight) <= 0 then
        return ErrorCode.TagNotExist
    end

    moon.debug(string.format("cur_tags:\n%s", json.pretty_encode(cur_tags)))
    moon.debug(string.format("cur_ability_tag:\n%s", json.pretty_encode(cur_ability_tag)))
    moon.debug(string.format("id_weight:\n%s", json.pretty_encode(id_weight)))
    -- 随机词条
    local new_tag_id = scripts.Item.RangeTags(id_weight)
    if new_tag_id == 0 then
        return ErrorCode.TagDuplicate
    end
    moon.debug(string.format("new_tag_id:%d", new_tag_id))
    -- 随机词条数值
    local tag_cfg = GameCfg.AllTag[new_tag_id]
    if not tag_cfg then
        return ErrorCode.TagNotExist
    end
    local new_tag_value = math.random(tag_cfg.min, tag_cfg.max)
    moon.debug(string.format("new_tag_value:%d min:%d max:%d", new_tag_id, tag_cfg.min, tag_cfg.max))

    -- 扣除消耗品
    local change_log = {}
    local err_code_del = ErrorCode.None
    if table.size(cost_items) > 0 then
        err_code_del = Bag.DelItems(BagDef.BagType.Cangku, cost_items, {}, change_log)
        if err_code_del ~= ErrorCode.None then
            Bag.RollBackWithChange(change_log)
            return err_code_del
        end
    end
    if table.size(cost_coins) > 0 then
        err_code_del = Bag.DealCoins(cost_coins, change_log)
        if err_code_del ~= ErrorCode.None then
            Bag.RollBackWithChange(change_log)
            return err_code_del
        end
    end

    -- 修改属性
    local new_tag = {
        id = new_tag_id,
        val = new_tag_value,
    }
    moon.debug(string.format("new_tag:\n%s", json.pretty_encode(new_tag)))
    if op_itemdata.itype == scripts.ItemDefine.EItemSmallType.MagicItem then
        op_itemdata.special_info.magic_item.light_cnt = cur_light_cnt + 1
        if new_tag_id >= AbilityTagIdMin then
            table.insert(op_itemdata.special_info.magic_item.ability_tag, new_tag)
        else
            table.insert(op_itemdata.special_info.magic_item.tags, new_tag)
        end
    elseif op_itemdata.itype == scripts.ItemDefine.EItemSmallType.HumanDiagrams
        or op_itemdata.itype == scripts.ItemDefine.EItemSmallType.GhostDiagrams then
        op_itemdata.special_info.diagrams_item.light_cnt = cur_light_cnt + 1
        if new_tag_id >= AbilityTagIdMin then
            table.insert(op_itemdata.special_info.diagrams_item.ability_tag, new_tag)
        else
            table.insert(op_itemdata.special_info.diagrams_item.tags, new_tag)
        end
    else
        Bag.RollBackWithChange(change_log)
        return ErrorCode.ItemNotExist
    end

    return ErrorCode.None, change_log
end

function Bag.PBDecomposeReqCmd(req)
    -- 参数验证
    if not req.msg.uid
        or not req.msg.decompose_items
        or table.size(req.msg.decompose_items) <= 0 then
        return context.S2C(context.net_id, CmdCode.PBDecomposeRspCmd, {
            code = ErrorCode.ParamInvalid,
            error = "无效请求参数",
            uid = req.msg.uid,
            decompose_items = req.msg.decompose_items or {},
        }, req.msg_context.stub_id)
    end

    local function decompose_func()
        local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
        local cost_items = {}
        local add_items, add_coins = {}, {}
        for _, value in pairs(req.msg.decompose_items) do
            -- 获取分解配置
            local decompose_cfg = {}
            if value.uniqid == 0 then
                local cfg = GameCfg.Item[value.config_id]
                if not cfg or table.size(cfg.decompose) <= 0 then
                    return ErrorCode.ForbidDecompose
                end
                decompose_cfg = cfg.decompose
            else
                local cfg = GameCfg.UniqueItem[value.config_id]
                if not cfg or table.size(cfg.decompose) <= 0 then
                    return ErrorCode.ForbidDecompose
                end
                decompose_cfg = cfg.decompose
            end

            -- 分解后获得的道具
            local decompose_items, decompose_coins = {}, {}
            scripts.Item.GetItemsFromCfg(decompose_cfg, value.item_count, false, decompose_items, decompose_coins)
            for id, item in pairs(decompose_items) do
                if not add_items[id] then
                    add_items[id] = item
                else
                    add_items[id].count = add_items[id].count + item.count
                end
            end
            for id, coin in pairs(decompose_coins) do
                if not add_coins[id] then
                    add_coins[id] = coin
                else
                    add_coins[id].count = add_coins[id].count + coin.count
                end
            end

            -- 消耗的道具
            cost_items[value.pos] = {
                config_id = value.config_id,
                uniqid = value.uniqid,
                item_count = -value.item_count,
            }
        end

        if table.size(cost_items) <= 0 then
            return ErrorCode.DecomposeFailed
        end

        local err_code = Bag.CheckItemsEnoughPos(BagDef.BagType.Cangku, cost_items)
        if err_code ~= ErrorCode.None then
            return err_code
        end

        local change_log = {}
        err_code = Bag.DelItemsPos(BagDef.BagType.Cangku, cost_items, change_log)
        if err_code ~= ErrorCode.None then
            Bag.RollBackWithChange(change_log)
            return err_code
        end

        if table.size(add_items) > 0 then
            err_code = Bag.AddItems(BagDef.BagType.Cangku, add_items, {}, change_log)
            if err_code ~= ErrorCode.None then
                Bag.RollBackWithChange(change_log)
                return err_code
            end
        end

        if table.size(add_coins) > 0 then
            err_code = Bag.DealCoins(add_coins, change_log)
            if err_code ~= ErrorCode.None then
                Bag.RollBackWithChange(change_log)
                return err_code
            end
        end

        return ErrorCode.None, change_log
    end

    local err_code, change_log = decompose_func()
    if err_code ~= ErrorCode.None or not change_log then
        return context.S2C(context.net_id, CmdCode.PBDecomposeRspCmd, {
            code = err_code,
            error = "分解失败",
            uid = req.msg.uid,
            decompose_items = req.msg.decompose_items or {},
        }, req.msg_context.stub_id)
    end

    -- 数据存储更新
    local save_bags = {}
    for bagType, _ in pairs(change_log) do
        save_bags[bagType] = 1
    end
    scripts.Bag.SaveAndLog(save_bags, change_log)

    return context.S2C(context.net_id, CmdCode.PBDecomposeRspCmd, {
        code = ErrorCode.None,
        uid = req.msg.uid,
        decompose_items = req.msg.decompose_items or {},
    }, req.msg_context.stub_id)
end

return Bag