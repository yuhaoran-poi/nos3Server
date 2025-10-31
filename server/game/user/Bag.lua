local moon = require "moon"
local common = require "common"
local uuid = require "uuid"
local json = require "json"
local clusterd = require("cluster")
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
local AbilityTagIdMin = 1000000

-- local ItemType = {
--     ALL = 1,
--     Consume = 2,
-- }

---@class Bag
local Bag = {}

function Bag.Init()
    -- 随机数种子
    local seed = os.time() + math.floor(tonumber(tostring(os.clock()):reverse():sub(1, 6)))
    math.randomseed(seed)
    print("Random seed initialized:", seed)

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
        bagdata[BagDef.BagType.Cangku].bag_item_type = ItemDefine.ItemBagType.ALL
        bagdata[BagDef.BagType.Consume].bag_item_type = ItemDefine.ItemBagType.CONSUME
        bagdata[BagDef.BagType.Booty].bag_item_type = ItemDefine.ItemBagType.ALL
        local cangku_cfg = GameCfg.WarehouseExpansion[1]
        if cangku_cfg then
            bagdata[BagDef.BagType.Cangku].capacity = cangku_cfg.warehouse_grids
        end
        local consume_cfg = GameCfg.ConsumablesBackpackExpansion[1]
        if consume_cfg then
            bagdata[BagDef.BagType.Consume].capacity = consume_cfg.consumables_backpack_grids
        end
        local booty_cfg = GameCfg.BootyBackpackExpansion[1]
        if booty_cfg then
            bagdata[BagDef.BagType.Booty].capacity = booty_cfg.booty_backpack_grids
        end
        scripts.UserModel.SetBagData(bagdata)
    end

    local coininfos = Bag.LoadCoins()
    if coininfos then
        scripts.UserModel.SetCoinsData(coininfos)
    end

    local coinsdata = scripts.UserModel.GetCoinsData()
    if not coinsdata then
        coinsdata = BagDef.newPBUserCoins()
        scripts.UserModel.SetCoinsData(coinsdata)
    end
end

function Bag.Start(isnew)
    local bagdata = scripts.UserModel.GetBagData()
    if not bagdata then
        return
    end

    if isnew then
        local init_cfg = GameCfg.Init[1]
        if not init_cfg then
            return
        end

        local init_items = {}
        local init_coins = {}
        local change_log = {}
        for k, v in pairs(init_cfg.item) do
            local init_item_info = {
                id = k,
                count = v,
            }
            table.insert(init_items, init_item_info)
        end
        for k, v in pairs(init_cfg.item) do
            init_coins[k] = {
                coin_id = k,
                coin_count = v,
            }
        end

        if table.size(init_items) > 0 then
            local stack_items, unstack_items, deal_coins = {}, {}, {}
            local ok = ItemDefine.GetItemDataFromIdCount(init_items, {}, stack_items, unstack_items, deal_coins)
            if ok then
                if table.size(stack_items) + table.size(unstack_items) > 0 then
                    Bag.AddItems(BagDef.BagType.Cangku, stack_items, unstack_items, change_log)
                end
            end
        end

        if table.size(init_coins) > 0 then
            local stack_items, unstack_items, deal_coins = {}, {}, {}
            local ok = ItemDefine.GetItemDataFromIdCount({}, init_coins, stack_items, unstack_items, deal_coins)
            if ok then
                if table.size(deal_coins) > 0 then
                    Bag.DealCoins(deal_coins, change_log)
                end
            end
        end

        local bagTypes = {}
        bagTypes[BagDef.BagType.Cangku] = 1
        bagTypes[BagDef.BagType.Consume] = 1
        bagTypes[BagDef.BagType.Booty] = 1
        Bag.SaveBagsNow(bagTypes)
        Bag.SaveCoinsNow()
    end

    -- 将所有背包中的道具序列化
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

function Bag.AddCapacity(bagType, add_capacity_id)
    if add_capacity_id <= 1 then
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

    local cost, after_capacity = {}, 0
    local baginfo = bagdata[bagType]
    if bagType == BagDef.BagType.Cangku then
        local bag_cfg = GameCfg.WarehouseExpansion[add_capacity_id]
        if not bag_cfg then
            return ErrorCode.ParamInvalid
        end
        if bag_cfg.warehouse_grids <= baginfo.capacity
            or table.size(bag_cfg.warehouse_cost) <= 0 then
            return ErrorCode.BagCapacityOverflow
        end
        cost = bag_cfg.warehouse_cost
        after_capacity = bag_cfg.warehouse_grids
    elseif bagType == BagDef.BagType.Consume then
        local bag_cfg = GameCfg.ConsumablesBackpackExpansion[add_capacity_id]
        if not bag_cfg then
            return ErrorCode.ParamInvalid
        end
        if bag_cfg.consumables_backpack_grids <= baginfo.capacity
            or table.size(bag_cfg.consumables_backpack_cost) <= 0 then
            return ErrorCode.BagCapacityOverflow
        end
        cost = bag_cfg.consumables_backpack_cost
        after_capacity = bag_cfg.consumables_backpack_grids
    elseif bagType == BagDef.BagType.Booty then
        local bag_cfg = GameCfg.BootyBackpackExpansion[add_capacity_id]
        if not bag_cfg then
            return ErrorCode.ParamInvalid
        end
        if not bag_cfg then
            return ErrorCode.ParamInvalid
        end
        if bag_cfg.booty_backpack_grids <= baginfo.capacity
            or table.size(bag_cfg.booty_backpack_cost) <= 0 then
            return ErrorCode.BagCapacityOverflow
        end
        cost = bag_cfg.booty_backpack_cost
        after_capacity = bag_cfg.booty_backpack_grids
    end

    -- 计算消耗资源
    local cost_items = {}
    local cost_coins = {}
    ItemDefine.GetItemsFromCfg(cost, 1, true, cost_items, cost_coins)
    -- 检查资源是否足够
    local err_code_items = Bag.CheckItemsEnough(BagDef.BagType.Cangku, cost_items, {})
    if err_code_items ~= ErrorCode.None then
        return err_code_items
    end
    local err_code_coins = Bag.CheckCoinsEnough(cost_coins)
    if err_code_coins ~= ErrorCode.None then
        return err_code_coins
    end
    -- 扣除消耗
    local change_log = {}
    change_log[bagType] = {}
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

    baginfo.capacity = after_capacity
    return ErrorCode.None, change_log
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

-- function Bag.RollBackWithChange(change_logs)
--     if not change_logs or table.size(change_logs) == 0 then
--         return
--     end

--     local bagdata = scripts.UserModel.GetBagData()
--     if not bagdata then
--         return
--     end

--     local coinsdata = scripts.UserModel.GetCoinsData()
--     if not coinsdata then
--         return
--     end

--     -- 先执行道具数量变更回滚
--     for bagType, logs in pairs(change_logs) do
--         if bagType == BagDef.BagType.Coins then
--             for coinid, log in pairs(logs) do
--                 coinsdata.coins[coinid].coin_count = log.old_count
--             end
--         else
--             local baginfo = bagdata[bagType]
--             if baginfo then
--                 for pos, log in pairs(logs) do
--                     if log.change_type == ItemDef.LogType.ChangeNum
--                         and baginfo.items[pos] then
--                         baginfo.items[pos].common_info.item_count = log.old_count
--                         if baginfo.items[pos].common_info.item_count == 0 then
--                             baginfo.items[pos] = nil
--                         end
--                     elseif log.change_type == ItemDef.LogType.ChangeInfo then
--                         baginfo.items[pos] = table.copy(log.old_itemdata)
--                     end
--                 end
--             end
--         end
--     end
-- end

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

    -- 执行道具变更回滚
    for bagType, logs in pairs(change_logs) do
        if bagType == BagDef.BagType.Coins then
            for coinid, old_coininfo in pairs(logs) do
                coinsdata.coins[coinid] = old_coininfo
            end
        else
            local baginfo = bagdata[bagType]
            if baginfo then
                for pos, old_itemdata in pairs(logs) do
                    if table.size(old_itemdata) == 0 then
                        baginfo.items[pos] = nil
                    else
                        baginfo.items[pos] = old_itemdata
                    end
                end
            end
        end
    end
end

-- function Bag.SaveAndLog(bagTypes, change_logs, change_reason)
--     local success = true

--     local bagdata = scripts.UserModel.GetBagData()
--     if not bagdata then
--         return
--     end

--     local coinsdata = scripts.UserModel.GetCoinsData()
--     if not coinsdata then
--         return
--     end

--     -- 用于日志存储的数据
--     -- local write_log_datas = {
--     --     [ItemDef.LogType.ChangeNum] = {},
--     --     [ItemDef.LogType.ChangeInfo] = {},
--     -- }
--     -- local now_ts = moon.time()

--     -- 修改dataMap
--     -- 去掉已经为0的道具格子
--     -- 将变更记录作为PBBagUpdateSyncCmd发送
--     local update_msg = {
--         update_items = {},
--         update_coins = {},
--     }
--     if change_logs then
--         for bagType, logs in pairs(change_logs) do
--             if bagType ~= BagDef.BagType.Coins then
--                 local baginfo = bagdata[bagType]
--                 if not baginfo then
--                     return
--                 end

--                 if not update_msg.update_items[bagType] then
--                     update_msg.update_items[bagType] = {
--                         bag_item_type = baginfo.bag_item_type,
--                         capacity = baginfo.capacity,
--                         items = {},
--                     }
--                 end

--                 for pos, loginfo in pairs(logs) do
--                     local now_itemdata = baginfo.items[pos]
--                     update_msg.update_items[bagType].items[pos] = now_itemdata
--                     loginfo.new_config_id = now_itemdata.common_info.config_id
--                     loginfo.new_uniqid = now_itemdata.common_info.uniqid
--                     loginfo.new_count = now_itemdata.common_info.item_count

--                     -- -- 记录Bag.dataMap变更前的背包数据
--                     -- if loginfo.log_type == ItemDef.LogType.ChangeNum then
--                     --     if not write_log_datas[ItemDef.LogType.ChangeNum][loginfo.old_config_id]
--                     --         and loginfo.old_config_id > 0 then
--                     --         local new_write_log = BagDef.newPBBagLog()
--                     --         new_write_log.uid = context.uid
--                     --         new_write_log.config_id = loginfo.old_config_id
--                     --         for _, tmp_data in pairs(Bag.dataMap[loginfo.old_config_id]) do
--                     --             new_write_log.old_num = new_write_log.old_num + tmp_data.allCount
--                     --         end
--                     --         new_write_log.change_type = loginfo.log_type
--                     --         new_write_log.change_reason = change_reason
--                     --         new_write_log.log_ts = now_ts
--                     --         write_log_datas[ItemDef.LogType.ChangeNum][loginfo.old_config_id] = new_write_log
--                     --     end
--                     --     if not write_log_datas[ItemDef.LogType.ChangeNum][loginfo.new_config_id]
--                     --         and loginfo.new_config_id > 0 then
--                     --         local new_write_log = BagDef.newPBBagLog()
--                     --         new_write_log.uid = context.uid
--                     --         new_write_log.config_id = loginfo.new_config_id
--                     --         if Bag.dataMap[loginfo.new_config_id] then
--                     --             for _, tmp_data in pairs(Bag.dataMap[loginfo.new_config_id]) do
--                     --                 new_write_log.old_num = new_write_log.old_num + tmp_data.allCount
--                     --             end
--                     --         end
--                     --         new_write_log.change_type = loginfo.log_type
--                     --         new_write_log.change_reason = change_reason
--                     --         new_write_log.log_ts = now_ts
--                     --         write_log_datas[ItemDef.LogType.ChangeNum][loginfo.new_config_id] = new_write_log
--                     --     end
--                     -- elseif loginfo.log_type == ItemDef.LogType.ChangeInfo then
--                     --     if not write_log_datas[ItemDef.LogType.ChangeInfo][loginfo.old_config_id] then
--                     --         local new_write_log = BagDef.newPBBagLog()
--                     --         new_write_log.uid = context.uid
--                     --         new_write_log.config_id = loginfo.old_config_id
--                     --         new_write_log.old_num = 1
--                     --         new_write_log.new_num = 1
--                     --         new_write_log.mod_uniqid = loginfo.old_uniqid
--                     --         if loginfo.old_itemdata then
--                     --             new_write_log.old_item_data = loginfo.old_itemdata
--                     --         end
--                     --         if now_itemdata then
--                     --             new_write_log.new_item_data = now_itemdata
--                     --         end
--                     --         new_write_log.change_type = loginfo.log_type
--                     --         new_write_log.change_reason = change_reason
--                     --         new_write_log.log_ts = now_ts
--                     --         write_log_datas[ItemDef.LogType.ChangeInfo][loginfo.old_config_id] = new_write_log
--                     --     end
--                     -- end

--                     -- 处理dataMap变更
--                     if not Bag.dataMap[loginfo.new_config_id] then
--                         Bag.dataMap[loginfo.new_config_id] = {}
--                     end
--                     if not Bag.dataMap[loginfo.new_config_id][bagType] then
--                         Bag.dataMap[loginfo.new_config_id][bagType] = {
--                             allCount = 0,
--                             pos_count = {},
--                             uniqid_pos = {},
--                         }
--                     end

--                     if Bag.dataMap[loginfo.old_config_id]
--                         and Bag.dataMap[loginfo.old_config_id][bagType] then
--                         Bag.dataMap[loginfo.old_config_id][bagType].allCount = Bag.dataMap
--                             [loginfo.old_config_id][bagType].allCount - loginfo.old_count
--                     end
--                     Bag.dataMap[loginfo.new_config_id][bagType].allCount = Bag.dataMap
--                         [loginfo.new_config_id][bagType].allCount + loginfo.new_count

--                     if Bag.dataMap[loginfo.old_config_id]
--                         and Bag.dataMap[loginfo.old_config_id][bagType] then
--                         if loginfo.old_uniqid ~= 0 then
--                             Bag.dataMap[loginfo.old_config_id][bagType].uniqid_pos[loginfo.old_uniqid] = nil

--                             -- if loginfo.log_type == ItemDef.LogType.ChangeNum
--                             --     and write_log_datas[ItemDef.LogType.ChangeNum][loginfo.old_config_id] then
--                             --     table.insert(write_log_datas[ItemDef.LogType.ChangeNum][loginfo.old_config_id]
--                             --         .change_uniqids, loginfo.old_uniqid)
--                             -- end
--                         else
--                             Bag.dataMap[loginfo.old_config_id][bagType].pos_count[pos] = nil
--                         end
--                     end
--                     if loginfo.new_uniqid ~= 0 then
--                         Bag.dataMap[loginfo.new_config_id][bagType].uniqid_pos[loginfo.new_uniqid] = pos

--                         -- if loginfo.log_type == ItemDef.LogType.ChangeNum
--                         --     and write_log_datas[ItemDef.LogType.ChangeNum][loginfo.new_config_id] then
--                         --     table.insert(write_log_datas[ItemDef.LogType.ChangeNum][loginfo.new_config_id]
--                         --         .change_uniqids, loginfo.new_uniqid)
--                         -- end
--                     else
--                         Bag.dataMap[loginfo.new_config_id][bagType].pos_count[pos] = loginfo.new_count
--                     end

--                     -- 去掉已经为0的道具格子
--                     if loginfo.log_type == ItemDef.LogType.ChangeNum then
--                         if baginfo.items[pos].common_info.item_count == 0 then
--                             baginfo.items[pos] = nil
--                             update_msg.update_items[bagType].items[pos] = {}
--                         end
--                     elseif loginfo.log_type == ItemDef.LogType.ChangeInfo then
--                         if baginfo.items[pos].common_info.item_count == 0 then
--                             baginfo.items[pos] = nil
--                             update_msg.update_items[bagType].items[pos] = {}
--                         else
--                             -- 记录ChangeInfo后的新itemdata
--                             loginfo.new_itemdata = table.copy(now_itemdata, true)
--                         end
--                     end

--                     -- -- 记录Bag.dataMap变更后的背包数据
--                     -- if loginfo.log_type == ItemDef.LogType.ChangeNum then
--                     --     if write_log_datas[ItemDef.LogType.ChangeNum][loginfo.old_config_id] then
--                     --         for _, tmp_data in pairs(Bag.dataMap[loginfo.old_config_id]) do
--                     --             write_log_datas[ItemDef.LogType.ChangeNum][loginfo.old_config_id].new_num =
--                     --                 write_log_datas[ItemDef.LogType.ChangeNum][loginfo.old_config_id].new_num +
--                     --                 tmp_data.allCount
--                     --         end
--                     --     end
--                     --     if write_log_datas[ItemDef.LogType.ChangeNum][loginfo.new_config_id] then
--                     --         for _, tmp_data in pairs(Bag.dataMap[loginfo.new_config_id]) do
--                     --             write_log_datas[ItemDef.LogType.ChangeNum][loginfo.new_config_id].new_num =
--                     --                 write_log_datas[ItemDef.LogType.ChangeNum][loginfo.new_config_id].new_num +
--                     --                 tmp_data.allCount
--                     --         end
--                     --     end
--                     -- end
--                 end
--             else
--                 if not update_msg.update_coins then
--                     update_msg.update_coins = {}
--                 end

--                 for coinid, _ in pairs(logs) do
--                     update_msg.update_coins[coinid] = coinsdata.coins[coinid]
--                 end
--             end
--         end
--     end

--     local success_coin = false
--     if bagTypes and bagTypes[BagDef.BagType.Coins] then
--         success_coin = Bag.SaveCoinsNow()
--     end

--     success = Bag.SaveBagsNow(bagTypes)
--     --发送PBBagUpdateSyncCmd
--     if success or success_coin then
--         --local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
--         context.S2C(context.net_id, CmdCode["PBBagUpdateSyncCmd"], update_msg, 0)
--     end

--     --存储日志

--     return success
-- end

function Bag.SaveAndLog(change_logs, change_reason,
                        relation_roleid, relation_ghostid, relation_ghost_uniqid, relation_imageid)
    if not change_logs then
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

    -- 用于日志存储的数据
    local coin_log_datas = {}
    local item_log_datas = {}

    -- 修改dataMap
    -- 将变更记录作为PBBagUpdateSyncCmd发送
    local update_msg = {
        update_items = {},
        update_coins = {},
    }
    for bagType, logs in pairs(change_logs) do
        if bagType == BagDef.BagType.Coins then
            if not update_msg.update_coins then
                update_msg.update_coins = {}
            end

            for coinid, old_coininfo in pairs(logs) do
                update_msg.update_coins[coinid] = coinsdata.coins[coinid]
                local new_tmp = {
                    old_num = old_coininfo.coin_count,
                    new_num = coinsdata.coins[coinid].coin_count,
                }
                coin_log_datas[coinid] = new_tmp
            end
        else
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

                for pos, old_itemdata in pairs(logs) do
                    local old_config_id = 0
                    local old_item_count = 0
                    local old_uniqid = 0
                    if old_itemdata and old_itemdata.common_info then
                        if old_itemdata.common_info.config_id then
                            old_config_id = old_itemdata.common_info.config_id
                        end
                        if old_itemdata.common_info.item_count then
                            old_item_count = old_itemdata.common_info.item_count
                        end
                        if old_itemdata.common_info.uniqid then
                            old_uniqid = old_itemdata.common_info.uniqid
                        end
                    end

                    local now_itemdata = baginfo.items[pos]
                    local now_config_id = 0
                    local now_item_count = 0
                    local now_uniqid = 0
                    if now_itemdata and now_itemdata.common_info then
                        if now_itemdata.common_info.config_id then
                            now_config_id = now_itemdata.common_info.config_id
                        end
                        if now_itemdata.common_info.item_count then
                            now_item_count = now_itemdata.common_info.item_count
                        end
                        if now_itemdata.common_info.uniqid then
                            now_uniqid = now_itemdata.common_info.uniqid
                        end
                    end

                    -- 处理发送到客户端的更新信息
                    if now_config_id == 0 then
                        if old_config_id > 0 then
                            update_msg.update_items[bagType].items[pos] = table.copy(old_itemdata, true)
                            update_msg.update_items[bagType].items[pos].common_info.item_count = 0
                        end
                    else
                        update_msg.update_items[bagType].items[pos] = now_itemdata

                        -- 处理dataMap新增
                        if not Bag.dataMap[now_config_id] then
                            Bag.dataMap[now_config_id] = {}
                        end
                        if not Bag.dataMap[now_config_id][bagType] then
                            Bag.dataMap[now_config_id][bagType] = {
                                allCount = 0,
                                pos_count = {},
                                uniqid_pos = {},
                            }
                        end
                    end

                    -- 记录Bag.dataMap变更前的背包数据
                    if old_config_id > 0 and not item_log_datas[old_config_id] then
                        local new_tmp = {
                            old_num = 0,
                            new_num = 0,
                            change_uniq = {},
                        }
                        for _, tmp_data in pairs(Bag.dataMap[old_config_id]) do
                            new_tmp.old_num = new_tmp.old_num + tmp_data.allCount
                        end
                        item_log_datas[old_config_id] = new_tmp
                    end
                    if now_config_id > 0 and not item_log_datas[now_config_id] then
                        local new_tmp = {
                            old_num = 0,
                            new_num = 0,
                            change_uniq = {},
                        }
                        for _, tmp_data in pairs(Bag.dataMap[now_config_id]) do
                            new_tmp.old_num = new_tmp.old_num + tmp_data.allCount
                        end
                        item_log_datas[now_config_id] = new_tmp
                    end

                    -- 处理dataMap变更
                    if old_config_id > 0 then
                        local change_dataMap = Bag.dataMap[old_config_id][bagType]
                        change_dataMap.allCount = change_dataMap.allCount - old_item_count
                        if old_uniqid > 0 and change_dataMap.uniqid_pos[old_uniqid] == pos then
                            -- 唯一道具pos可能已经变更，需要比较是否为当前pos
                            change_dataMap.uniqid_pos[old_uniqid] = nil
                        else
                            change_dataMap.pos_count[pos] = nil
                        end
                        Bag.dataMap[old_config_id][bagType] = change_dataMap
                    end
                    if now_config_id > 0 then
                        local change_dataMap = Bag.dataMap[now_config_id][bagType]
                        change_dataMap.allCount = change_dataMap.allCount + now_item_count
                        if now_uniqid > 0 then
                            change_dataMap.uniqid_pos[now_uniqid] = pos
                        else
                            change_dataMap.pos_count[pos] = now_item_count
                        end
                        Bag.dataMap[now_config_id][bagType] = change_dataMap
                    end

                    -- 记录唯一道具变更
                    if old_config_id > 0 and old_uniqid > 0 then
                        if not item_log_datas[old_config_id].change_uniq[old_uniqid] then
                            item_log_datas[old_config_id].change_uniq[old_uniqid] = {}
                        end
                        if not item_log_datas[old_config_id].change_uniq[old_uniqid].old_itemdata then
                            item_log_datas[old_config_id].change_uniq[old_uniqid].old_itemdata = old_itemdata
                        end
                    end
                    if now_config_id > 0 and now_uniqid > 0 then
                        if not item_log_datas[now_config_id].change_uniq[now_uniqid] then
                            item_log_datas[now_config_id].change_uniq[now_uniqid] = {}
                        end
                        if not item_log_datas[now_config_id].change_uniq[now_uniqid].new_itemdata then
                            item_log_datas[now_config_id].change_uniq[now_uniqid].new_itemdata = now_itemdata
                        end
                    end
                end
            end
        end
    end

    -- local write_log_datas = {
    --     [ItemDef.LogType.ChangeNum] = {},
    --     [ItemDef.LogType.ChangeInfo] = {},
    -- }
    local write_log_datas = {}
    local now_ts = moon.time()
    -- 统计所有记录变更
    if change_reason ~= ItemDef.ChangeReason.BagMove
        and change_reason ~= ItemDef.ChangeReason.SortOutItems then
        for tmp_config_id, tmp_data in pairs(coin_log_datas) do
            if tmp_data.new_num ~= tmp_data.old_num then
                local new_write_log = ItemDef.newPBItemLog()
                new_write_log.uid = context.uid
                new_write_log.config_id = tmp_config_id
                new_write_log.old_num = tmp_data.old_num
                new_write_log.new_num = tmp_data.new_num
                new_write_log.relation_roleid = relation_roleid or 0
                new_write_log.relation_ghostid = relation_ghostid or 0
                new_write_log.relation_ghost_uniqid = relation_ghost_uniqid or 0
                new_write_log.relation_imageid = relation_imageid or 0
                new_write_log.change_type = ItemDef.LogType.ChangeNum
                new_write_log.change_reason = change_reason
                new_write_log.log_ts = now_ts
                table.insert(write_log_datas, new_write_log)
                -- write_log_datas[ItemDef.LogType.ChangeNum][tmp_config_id] = new_write_log
            end
        end
        for tmp_config_id, tmp_data in pairs(item_log_datas) do
            for _, bag_data_map in pairs(Bag.dataMap[tmp_config_id]) do
                tmp_data.new_num = tmp_data.new_num + bag_data_map.allCount
            end

            if table.size(tmp_data.change_uniq) == 0 then
                if tmp_data.new_num ~= tmp_data.old_num then
                    local new_write_log = ItemDef.newPBItemLog()
                    new_write_log.uid = context.uid
                    new_write_log.config_id = tmp_config_id
                    new_write_log.old_num = tmp_data.old_num
                    new_write_log.new_num = tmp_data.new_num
                    new_write_log.relation_roleid = relation_roleid or 0
                    new_write_log.relation_ghostid = relation_ghostid or 0
                    new_write_log.relation_ghost_uniqid = relation_ghost_uniqid or 0
                    new_write_log.relation_imageid = relation_imageid or 0
                    new_write_log.change_type = ItemDef.LogType.ChangeNum
                    new_write_log.change_reason = change_reason
                    new_write_log.log_ts = now_ts
                    table.insert(write_log_datas, new_write_log)
                    -- write_log_datas[ItemDef.LogType.ChangeNum][tmp_config_id] = new_write_log
                end
            else
                local change_num_log = ItemDef.newPBItemLog()
                change_num_log.uid = context.uid
                change_num_log.config_id = tmp_config_id
                change_num_log.old_num = tmp_data.old_num
                change_num_log.new_num = tmp_data.new_num
                change_num_log.relation_roleid = relation_roleid or 0
                change_num_log.relation_ghostid = relation_ghostid or 0
                change_num_log.relation_ghost_uniqid = relation_ghost_uniqid or 0
                change_num_log.relation_imageid = relation_imageid or 0
                change_num_log.change_type = ItemDef.LogType.ChangeNum
                change_num_log.change_reason = change_reason
                change_num_log.log_ts = now_ts

                for change_uniqid, change_data in pairs(tmp_data.change_uniq) do
                    if not change_data.old_itemdata or not change_data.new_itemdata then
                        if change_data.old_itemdata then
                            table.insert(change_num_log.del_uniqids, change_uniqid)
                            table.insert(change_num_log.old_item_data, change_data.old_itemdata)
                        end
                        if change_data.new_itemdata then
                            table.insert(change_num_log.add_uniqids, change_uniqid)
                            table.insert(change_num_log.new_item_data, change_data.new_itemdata)
                        end
                    else
                        if not scripts.Item.UniqItemEqual(change_data.old_itemdata, change_data.new_itemdata) then
                            local change_info_log = ItemDef.newPBItemLog()
                            change_info_log.uid = context.uid
                            change_info_log.config_id = tmp_config_id
                            change_info_log.old_num = 1
                            change_info_log.new_num = 1
                            change_info_log.mod_uniqid = change_uniqid
                            table.insert(change_info_log.old_item_data, change_data.old_itemdata)
                            table.insert(change_info_log.new_item_data, change_data.new_itemdata)
                            change_info_log.change_type = ItemDef.LogType.ChangeInfo
                            change_info_log.change_reason = change_reason
                            change_info_log.log_ts = now_ts
                            table.insert(write_log_datas, change_info_log)
                        end
                    end
                end
                if table.size(change_num_log.del_uniqids) > 0 or table.size(change_num_log.add_uniqids) > 0 then
                    table.insert(write_log_datas, change_num_log)
                end
            end
        end
    end
    

    local success = false
    if table.size(update_msg.update_coins) > 0 then
        success = Bag.SaveCoinsNow()
    end
    local bagTypes = {}
    for bagType, _ in pairs(change_logs) do
        bagTypes[bagType] = 1
    end
    if table.size(update_msg.update_items) > 0 then
        success = Bag.SaveBagsNow(bagTypes)
    end

    --发送PBBagUpdateSyncCmd
    if success then
        --local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
        context.S2C(context.net_id, CmdCode["PBBagUpdateSyncCmd"], update_msg, 0)
    end

    --存储日志
    if change_reason ~= ItemDef.ChangeReason.BagMove
        and change_reason ~= ItemDef.ChangeReason.SortOutItems then
        scripts.Item.SendLog(write_log_datas)
    end

    return success
end

-- function Bag.AddLog(logs, pos, log_type, old_itemid, old_uniqid, old_count, old_itemdata)
--     logs[pos] = {
--         log_type = log_type,
--         old_config_id = old_itemid,
--         old_uniqid = old_uniqid,
--         old_count = old_count,
--         old_itemdata = {},
--     }

--     if log_type == ItemDef.LogType.ChangeInfo then
--         logs[pos].old_itemdata = old_itemdata
--     end
-- end

function Bag.AddLog(logs, pos, old_itemdata)
    if logs[pos] then
        return
    end

    if not old_itemdata or table.size(old_itemdata) <= 0 then
        logs[pos] = {}
    else
        logs[pos] = table.copy(old_itemdata)
    end
end

-- Bag.dataMap[itemdata.common_info.config_id][bagType] = {
--                     allCount = 0,
--                     pos_count = {},
--                     uniqid_pos = {},
--                 }
-- 整理背包
function Bag.SortOut(bagType)
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

    local now_config_ids = {}
    for config_id, _ in pairs(Bag.dataMap) do
        table.insert(now_config_ids, config_id)
    end
    if table.size(now_config_ids) <= 0 then
        return ErrorCode.BagEmpty
    end
    table.sort(now_config_ids)

    local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
    -- 先堆叠
    local stack_baginfo = bagdata[bagType]
    local stack_change_logs = {
        [bagType] = {}
    }
    for config_id, bdata in pairs(Bag.dataMap) do
        if bdata[bagType]
            and bdata[bagType].allCount > 0
            and table.size(bdata[bagType].pos_count) > 0 then
            local item_cfg = GameCfg.Item[config_id]
            if item_cfg then
                local dest_pos, dest_count = 0, 0
                for pos, count in pairs(bdata[bagType].pos_count) do
                    if count ~= 0 then
                        if dest_pos == 0 then
                            if count < item_cfg.stack_count then
                                dest_pos = pos
                                dest_count = count
                            end
                        else
                            local src_pos, src_count = 0, 0
                            if count < item_cfg.stack_count then
                                src_pos = pos
                                src_count = math.min(count, item_cfg.stack_count - dest_count)
                            end
                            if src_pos > 0 then
                                local dest_item = stack_baginfo.items[dest_pos]
                                local src_item = stack_baginfo.items[src_pos]
                                Bag.AddLog(stack_change_logs[bagType], dest_pos, dest_item)
                                Bag.AddLog(stack_change_logs[bagType], src_pos, src_item)
                                dest_item.common_info.item_count = dest_item.common_info.item_count + src_count
                                src_item.common_info.item_count = src_item.common_info.item_count - src_count

                                dest_count = dest_item.common_info.item_count
                                src_count = src_item.common_info.item_count
                                if src_count ~= 0 then
                                    dest_pos = src_pos
                                    dest_count = src_count
                                else
                                    if dest_count >= item_cfg.stack_count then
                                        dest_pos = 0
                                        dest_count = 0
                                    end
                                    stack_baginfo.items[src_pos] = nil
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    if table.size(stack_change_logs[bagType]) > 0 then
        local success = Bag.SaveAndLog(stack_change_logs, ItemDef.ChangeReason.SortOutItems)
        if not success then
            return ErrorCode.BagSortOutFailed
        end
    end
    -- moon.warn(string.format("stack_baginfo.items = %s", json.pretty_encode(stack_baginfo.items)))
    -- moon.warn(string.format("Bag.dataMap = %s", json.pretty_encode(Bag.dataMap)))
    -- moon.warn(string.format("stack_change_logs[bagType] = %s", json.pretty_encode(stack_change_logs[bagType])))

    local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
    -- 再移动
    local cur_use_pos = 1
    local move_baginfo = bagdata[bagType]
    local move_change_logs = {
        [bagType] = {}
    }
    local old_items = table.copy(move_baginfo.items, true)
    if not old_items or table.size(old_items) <= 0 then
        return ErrorCode.BagEmpty
    end
    for _, config_id in pairs(now_config_ids) do
        local bdata = Bag.dataMap[config_id][bagType]
        for pos, count in pairs(bdata.pos_count) do
            if count ~= 0 then
                if pos ~= cur_use_pos then
                    local src_item = old_items[pos]
                    Bag.AddLog(move_change_logs[bagType], cur_use_pos, old_items[cur_use_pos])
                    Bag.AddLog(move_change_logs[bagType], pos, move_baginfo.items[pos])
                    move_baginfo.items[cur_use_pos] = src_item
                    if pos > cur_use_pos then
                        move_baginfo.items[pos] = nil
                    end
                end

                cur_use_pos = cur_use_pos + 1
            end
        end
        for uniqid, pos in pairs(bdata.uniqid_pos) do
            if pos > 0 then
                if pos ~= cur_use_pos then
                    local src_item = old_items[pos]
                    Bag.AddLog(move_change_logs[bagType], cur_use_pos, old_items[cur_use_pos])
                    Bag.AddLog(move_change_logs[bagType], pos, src_item)
                    move_baginfo.items[cur_use_pos] = src_item
                    if pos > cur_use_pos then
                        move_baginfo.items[pos] = nil
                    end
                end
                cur_use_pos = cur_use_pos + 1
            end
        end
    end
    if table.size(move_change_logs[bagType]) > 0 then
        local success = Bag.SaveAndLog(move_change_logs, ItemDef.ChangeReason.SortOutItems)
        if not success then
            return ErrorCode.BagSortOutFailed
        end
    end
    -- moon.warn(string.format("move_baginfo.items = %s", json.pretty_encode(move_baginfo.items)))
    -- moon.warn(string.format("Bag.dataMap = %s", json.pretty_encode(Bag.dataMap)))
    -- moon.warn(string.format("move_change_logs[bagType] = %s", json.pretty_encode(move_change_logs[bagType])))

    return ErrorCode.None
end

-- 添加物品（支持自动堆叠）
---@param bagType string
---@param baginfo PBBag
---@param item_data PBItemData
---@param logs table<number, {}>
function Bag.AddItem(bagType, baginfo, item_data, logs)
    local item_cfg = GameCfg.Item[item_data.common_info.config_id]
    if not item_cfg then
        return ErrorCode.ItemNotExist
    end

    -- 类型检查
    local item_type = ItemDefine.GetItemBagType(item_data.common_info.config_id)
    if baginfo.bag_item_type ~= ItemDefine.ItemBagType.ALL
        and baginfo.bag_item_type ~= item_type then
        return ErrorCode.BagTypeMismatch
    end

    -- 处理物品增减
    local remaining = item_data.common_info.item_count

    -- 先尝试堆叠
    for pos, itemdata in pairs(baginfo.items) do
        if itemdata.common_info.config_id == item_data.common_info.config_id
            and itemdata.common_info.uniqid == 0
            and itemdata.common_info.item_count < item_cfg.stack_count then
            local canAdd = math.min(item_cfg.stack_count - itemdata.common_info.item_count, remaining)

            -- Bag.AddLog(logs, pos, ItemDef.LogType.ChangeNum, item_data.common_info.config_id, 0,
            -- itemdata.common_info.item_count)
            Bag.AddLog(logs, pos, itemdata)
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

            local new_item = table.copy(item_data)
            if not new_item or not new_item.common_info then
                new_item = ItemDef.newItemData()
                new_item.itype = item_type
                new_item.common_info.config_id = item_cfg.id
                new_item.common_info.item_type = item_cfg.type1
                new_item.common_info.trade_cnt = -1
            end
            new_item.common_info.item_count = canAdd

            -- Bag.AddLog(logs, pos, ItemDef.LogType.ChangeNum, 0, 0, 0)
            Bag.AddLog(logs, pos, {})
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

        -- Bag.AddLog(logs, pos, ItemDef.LogType.ChangeNum, itemId, 0, itemdata.common_info.item_count)
        Bag.AddLog(logs, pos, itemdata)
        itemdata.common_info.item_count = itemdata.common_info.item_count + remaining
        if itemdata.common_info.item_count == 0 then
            baginfo.items[pos] = nil
        end
        
        remaining = 0
    else
        -- 先尝试扣减
        for pos, itemdata in pairs(baginfo.items) do
            if itemdata.common_info.config_id == itemId
                and itemdata.common_info.uniqid == 0
                and itemdata.common_info.item_count > 0 then
                local canSub = math.min(itemdata.common_info.item_count, -remaining)

                -- Bag.AddLog(logs, pos, ItemDef.LogType.ChangeNum, itemId, 0, itemdata.common_info.item_count)
                Bag.AddLog(logs, pos, itemdata)
                itemdata.common_info.item_count = itemdata.common_info.item_count - canSub
                if itemdata.common_info.item_count == 0 then
                    baginfo.items[pos] = nil
                end

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

function Bag.AddUniqItem(bagType, baginfo, item_data, itype, logs)
    if not item_data or not item_data.common_info then
        return ErrorCode.ItemNotExist
    end

    -- 参数校验
    local item_cfg = GameCfg.UniqueItem[item_data.common_info.config_id]
    if not item_cfg then
        return ErrorCode.ItemNotExist
    end

    -- 类型检查
    local item_type = ItemDefine.GetItemBagType(item_data.common_info.config_id)
    if baginfo.bag_item_type ~= ItemDefine.ItemBagType.ALL
        and baginfo.bag_item_type ~= item_type then
        return ErrorCode.BagTypeMismatch
    end

    -- 处理物品记录
    for pos = 1, baginfo.capacity do
        if not baginfo.items[pos] then
            local new_item = ItemDef.newItemData()
            new_item.itype = itype
            new_item.common_info.config_id = item_cfg.id
            new_item.common_info.uniqid = item_data.common_info.uniqid
            new_item.common_info.item_count = item_data.common_info.item_count
            new_item.common_info.item_type = item_cfg.type1
            new_item.common_info.trade_cnt = item_data.common_info.trade_cnt
            if new_item.common_info.uniqid == 0 then
                new_item.common_info.uniqid = uuid.next()
            end

            baginfo.items[pos] = new_item
            -- Bag.AddLog(logs, pos, ItemDef.LogType.ChangeNum, 0, 0, 0)
            Bag.AddLog(logs, pos, {})

            return ErrorCode.None, pos
        end
    end

    return ErrorCode.BagFull
end

-- function Bag.AddUniqItemData(bagType, baginfo, item_data, logs)
--     --local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
--     if not item_data or not item_data.common_info then
--         return ErrorCode.ItemNotExist
--     end

--     -- 处理物品记录
--     for pos = 1, baginfo.capacity do
--         if not baginfo.items[pos] then
--             baginfo.items[pos] = table.copy(item_data)
--             Bag.AddLog(logs, pos, ItemDef.LogType.ChangeNum, 0, 0, 0)

--             return ErrorCode.None, pos
--         end
--     end

--     return ErrorCode.BagFull
-- end

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

    -- 处理物品记录
    -- Bag.AddLog(logs, pos, ItemDef.LogType.ChangeNum, itemId, uniqid, 1)
    Bag.AddLog(logs, pos, baginfo.items[pos])
    baginfo.items[pos].common_info.item_count = 0
    baginfo.items[pos] = nil

    return ErrorCode.None
end

-- 添加古董
function Bag.AddAntique(bagType, baginfo, item_data, change_log)
    local item_cfg = GameCfg.AntiqueItem[item_data.common_info.config_id]
    if not item_cfg then
        return ErrorCode.ItemNotExist
    end

    local itype = ItemDefine.GetItemType(item_data.common_info.config_id)
    local errorCode, add_pos = Bag.AddUniqItem(bagType, baginfo, item_data, itype, change_log)
    if errorCode ~= ErrorCode.None or not add_pos then
        return errorCode
    end

    local new_itemdata = baginfo.items[add_pos]
    if item_data.special_info and item_data.special_info.antique_item then
        new_itemdata.special_info = table.copy(item_data.special_info, true)
    else
        new_itemdata.special_info = {
            antique_item = ItemDef.newAntique(),
        }

        for coin_id, cnt in pairs(item_cfg.initprice) do
            new_itemdata.special_info.antique_item.price.coin_id = coin_id
            new_itemdata.special_info.antique_item.price.coin_count = cnt
        end
        new_itemdata.special_info.antique_item.quality = item_cfg.quality
        new_itemdata.special_info.antique_item.remain_identify_num = item_cfg.identifynum
    end

    return ErrorCode.None
end

function Bag.AddDurabItem(bagType, baginfo, item_data, change_log)
    local item_cfg = GameCfg.Item[item_data.common_info.config_id]
    if not item_cfg then
        return ErrorCode.ItemNotExist
    end
    -- 类型检查
    local item_type = ItemDefine.GetItemBagType(item_data.common_info.config_id)
    if baginfo.bag_item_type ~= ItemDefine.ItemBagType.ALL
        and baginfo.bag_item_type ~= item_type then
        return ErrorCode.BagTypeMismatch
    end

    -- 处理物品记录
    local add_pos = 0
    local itype = ItemDefine.GetItemType(item_data.common_info.config_id)
    for pos = 1, baginfo.capacity do
        if not baginfo.items[pos] then
            --local new_item = ItemDef.newItemData()
            local new_item = table.copy(item_data)
            if not new_item
                or not new_item.common_info
                or not new_item.special_info
                or not new_item.special_info.durab_item then
                new_item = ItemDef.newItemData()
                new_item.itype = itype
                new_item.common_info.config_id = item_cfg.id
                new_item.common_info.item_count = 1
                new_item.common_info.item_type = item_cfg.type1
                new_item.common_info.trade_cnt = -1
                new_item.special_info.durab_item = ItemDef.newDurabItem()
            end
            if new_item.common_info.uniqid == 0 then
                new_item.common_info.uniqid = uuid.next()
            end

            baginfo.items[pos] = new_item
            -- Bag.AddLog(change_log, pos, ItemDef.LogType.ChangeNum, 0, 0, 0)
            Bag.AddLog(change_log, pos, {})
            add_pos = pos
        end
    end
    if add_pos == 0 then
        return ErrorCode.BagFull
    end

    return ErrorCode.None
end

function Bag.AddMagicItem(bagType, baginfo, item_data, change_log)
    --local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
    local errorCode, add_pos = Bag.AddUniqItem(bagType, baginfo, item_data, ItemDefine.EItemSmallType.MagicItem,
    change_log)
    if errorCode ~= ErrorCode.None or not add_pos then
        return errorCode
    end

    local new_itemdata = baginfo.items[add_pos]
    if item_data.special_info and item_data.special_info.magic_item then
        new_itemdata.special_info = table.copy(item_data.special_info, true)
    else
        new_itemdata.special_info = {
            magic_item = ItemDef.newMagicItem(),
        }
    end

    return ErrorCode.None
end

function Bag.AddDiagramsCard(bagType, baginfo, item_data, change_log)
    local itype = ItemDefine.GetItemType(item_data.common_info.config_id)
    local errorCode, add_pos = Bag.AddUniqItem(bagType, baginfo, item_data, itype, change_log)
    if errorCode ~= ErrorCode.None or not add_pos then
        return errorCode
    end

    local new_itemdata = baginfo.items[add_pos]
    if item_data.special_info and item_data.special_info.diagrams_item then
        new_itemdata.special_info = table.copy(item_data.special_info, true)
    else
        new_itemdata.special_info = {
            diagrams_item = ItemDef.newDiagramsCard(),
        }
    end

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
            count = table.size(mapinfo.pos_count) + table.size(mapinfo.uniqid_pos)
        end

        return count
    else
        if not Bag.dataMap[config_id][bagType] then
            return 0
        end
        moon.warn("Bag.GetItemPosNum config_id=", config_id)
        moon.warn("Bag.GetItemPosNum bagType=", bagType)
        moon.warn(string.format("Bag.GetItemPosNum Bag.dataMap=%s", json.pretty_encode(Bag.dataMap)))
        return table.size(Bag.dataMap[config_id][bagType].pos_count) +
            table.size(Bag.dataMap[config_id][bagType].uniqid_pos)
    end
end

-- 检查道具消耗是否足够
-- 输入参数可由ItemDefine.GetItemsFromCfg生成
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

-- 根据pos检测道具是否足够
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

-- 检查货币是否足够
-- 输入参数可由ItemDefine.GetItemsFromCfg生成
function Bag.CheckCoinsEnough(coins)
    local coinsdata = scripts.UserModel.GetCoinsData()
    if not coinsdata then
        return ErrorCode.CoinNotExist
    end
    
    --检测扣除的道具是否足够
    for coinid, coin in pairs(coins) do
        if coin.coin_count < 0 then
            if not coinsdata.coins[coinid] or coinsdata.coins[coinid].coin_count + coin.coin_count < 0 then
                return ErrorCode.CoinNotEnough
            end
        end
    end

    return ErrorCode.None
end

-- 检测是否有足够空位添加道具
-- param add_items可由ItemDefine.GetItemsFromCfg生成
function Bag.CheckEmptyEnough(bagType, add_items, use_pos_num)
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

    local empty_pos_num = Bag.GetEmptyPosNum(bagType)
    if empty_pos_num - use_pos_num < 0 then
        return ErrorCode.BagFull
    end
    empty_pos_num = empty_pos_num - use_pos_num

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

        local item_big_type = ItemDefine.GetItemPosType(itemid)
        if item_big_type == ItemDefine.EItemBigType.StackItem and item_cfg then
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
        elseif (item_big_type == ItemDefine.EItemBigType.UnStackItem and item_cfg)
            or (item_big_type == ItemDefine.EItemBigType.UniqueItem and uniqitem_cfg) then
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

-- 尝试是否有足够空位添加道具
function Bag.TryEmptyEnough(bagType, add_items, use_pos_num)
    local ret_code = ErrorCode.None
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

    local empty_pos_num = Bag.GetEmptyPosNum(bagType)
    if empty_pos_num - use_pos_num < 0 then
        ret_code = ErrorCode.BagFull
    end
    empty_pos_num = empty_pos_num - use_pos_num

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

        local item_big_type = ItemDefine.GetItemPosType(itemid)
        if item_big_type == ItemDefine.EItemBigType.StackItem and item_cfg then
            local remaining = item.count
            local now_cnt = Bag.GetItemCount(itemid, bagType)
            local now_pos_num = Bag.GetItemPosNum(itemid, bagType)
            local need_pos = math.ceil((remaining + now_cnt) / item_cfg.stack_count)
            if now_pos_num < need_pos then
                empty_pos_num = empty_pos_num - (need_pos - now_pos_num)
                if empty_pos_num < 0 then
                    ret_code = ErrorCode.BagFull
                end
            end
        elseif (item_big_type == ItemDefine.EItemBigType.UnStackItem and item_cfg)
            or (item_big_type == ItemDefine.EItemBigType.UniqueItem and uniqitem_cfg) then
            empty_pos_num = empty_pos_num - item.count
            if empty_pos_num < 0 then
                ret_code = ErrorCode.BagFull
            end
        else
            return ErrorCode.ItemNotExist
        end
    end

    return ret_code
end

-- 扣除道具
-- param del_items可由ItemDefine.GetItemsFromCfg生成
-- param del_unique_items={[uniqid] = {config_id = 1, uniqid = 1, pos = 1}}
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

-- 按格子号扣除道具
-- param del_items = {[pos] = {config_id = 1, uniqid = 0, item_count = -1}}
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

-- 批量添加道具
-- param stack_item_datas,unstack_item_datas可由ItemDefine.GetItemDataFromIdCount生成
function Bag.AddItems(bagType, stack_item_datas, unstack_item_datas, change_log)
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
    for item_id, item_data in pairs(stack_item_datas) do
        if item_data.common_info.item_count < 0 then
            return ErrorCode.ParamInvalid
        end
        err_code = Bag.AddItem(bagType, baginfo, item_data, change_log[bagType])
        if err_code ~= ErrorCode.None then
            return err_code
        end
    end
    
    for _, item_data in pairs(unstack_item_datas) do
        local item_small_type = ItemDefine.GetItemType(item_data.common_info.config_id)

        if item_small_type == ItemDefine.EItemSmallType.HumanDiagrams
            or item_small_type == ItemDefine.EItemSmallType.GhostDiagrams then
            err_code = Bag.AddDiagramsCard(bagType, baginfo, item_data, change_log[bagType])
        elseif item_small_type == ItemDefine.EItemSmallType.MagicItem then
            err_code = Bag.AddMagicItem(bagType, baginfo, item_data, change_log[bagType])
        elseif item_small_type == ItemDefine.EItemSmallType.DurabItem then
            err_code = Bag.AddDurabItem(bagType, baginfo, item_data, change_log[bagType])
        elseif item_small_type == ItemDefine.EItemSmallType.Antique then
            err_code = Bag.AddAntique(bagType, baginfo, item_data, change_log[bagType])
        else
            err_code = ErrorCode.ItemNotExist
        end

        if err_code ~= ErrorCode.None then
            return err_code
        end
    end

    -- 判断图鉴是否需要更新
    -- local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
    local change_image_ids = {}
    for pos, old_itemdata in pairs(change_log[bagType]) do
        if table.size(old_itemdata) <= 0 then
            scripts.ItemImage.AddItemImage(baginfo.items[pos].common_info.config_id, change_image_ids)
        end
    end
    -- 发送图鉴更新消息
    if table.size(change_image_ids) > 0 then
        scripts.ItemImage.SaveAndLog(change_image_ids)
    end

    return ErrorCode.None
end

-- 增加或扣除货币
-- param coins = {[PBCoin.coin_id] = PBCoin}
function Bag.DealCoins(coins, change_log)
    local coinsdata = scripts.UserModel.GetCoinsData()
    if not coinsdata then
        return ErrorCode.CoinNotExist
    end
    
    for coinid, coin in pairs(coins) do
        if coin.coin_count < 0 and not coinsdata.coins[coinid] then
            Bag.RollBackWithChange(change_log)
            return ErrorCode.CoinNotExist
        end

        if not coinsdata.coins[coinid] then
            coinsdata.coins[coinid] = ItemDef.newCoin()
            coinsdata.coins[coinid].coin_id = coinid
        end

        if not change_log[BagDef.BagType.Coins] then
            change_log[BagDef.BagType.Coins] = {}
        end
        -- Bag.AddLog(change_log[BagDef.BagType.Coins], coinid, ItemDef.LogType.ChangeNum, coinid, 0, coinsdata.coins[coinid].coin_count)
        Bag.AddLog(change_log[BagDef.BagType.Coins], coinid, coinsdata.coins[coinid])

        coinsdata.coins[coinid].coin_count = coinsdata.coins[coinid].coin_count + coin.coin_count
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
    if not srcItem or srcItem.common_info.uniqid ~= 0 then
        return ErrorCode.StackNotAllowed
    end
    if srcItem.common_info.item_count <= 0 then
        return ErrorCode.StackNotAllowed
    end

    -- 目标道具校验
    local destItem = destBag.items[destPos]
    if not destItem or destItem.common_info.uniqid ~= 0 then
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
    local available_count = item_cfg.stack_count - destItem.common_info.item_count
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
    -- Bag.AddLog(change_log[destBagType], destPos, ItemDef.LogType.ChangeNum, destItem.common_info.config_id,
    --     0, destItem.common_info.item_count)
    Bag.AddLog(change_log[destBagType], destPos, destItem)
    destItem.common_info.item_count = destItem.common_info.item_count + move_count

    if not change_log[srcBagType] then
        change_log[srcBagType] = {}
    end
    -- Bag.AddLog(change_log[srcBagType], srcPos, ItemDef.LogType.ChangeNum, srcItem.common_info.config_id,
    --     0, srcItem.common_info.item_count)
    Bag.AddLog(change_log[srcBagType], srcPos, srcItem)
    srcItem.common_info.item_count = srcItem.common_info.item_count - move_count
    if srcItem.common_info.item_count == 0 then
        srcBag.items[srcPos] = nil
    end

    return ErrorCode.None
end

function Bag.SplitItem(srcBagType, srcPos, destBagType, destPos, split_count, change_log)
    -- 参数校验
    if split_count <= 0 then
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
        or srcItem.common_info.item_count <= 1 then
        return ErrorCode.SplitNotAllowed
    end

    if split_count >= srcItem.common_info.item_count then
        return ErrorCode.SplitCountInvalid
    end

    -- 检查目标位置是否被占用
    if destBag.items[destPos] then
        return ErrorCode.MoveTargetOccupied
    end

    -- 跨背包类型校验
    local itemType = ItemDefine.GetItemBagType(srcItem.common_info.config_id)
    if destBag.bag_item_type ~= ItemDefine.ItemBagType.ALL
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
    -- Bag.AddLog(change_log[srcBagType], srcPos, ItemDef.LogType.ChangeNum, srcItem.common_info.config_id,
    --     0, srcItem.common_info.item_count)
    Bag.AddLog(change_log[srcBagType], srcPos, srcItem)
    srcItem.common_info.item_count = srcItem.common_info.item_count - split_count

    if not change_log[destBagType] then
        change_log[destBagType] = {}
    end
    -- Bag.AddLog(change_log[destBagType], destPos, ItemDef.LogType.ChangeNum, srcItem.common_info.config_id, 0, 0)
    Bag.AddLog(change_log[destBagType], destPos, {})
    destBag.items[destPos] = table.copy(srcItem)
    destBag.items[destPos].common_info.item_count = split_count

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
    if not srcItem then
        return ErrorCode.ItemNotExist
    end

    -- 目标背包类型校验
    local itemType = ItemDefine.GetItemBagType(srcItem.common_info.config_id)
    if destBag.bag_item_type ~= ItemDefine.ItemBagType.ALL
        and destBag.bag_item_type ~= itemType then
        return ErrorCode.BagTypeMismatch
    end

    local destItem = destBag.items[destPos]
    if destItem then
        -- 目标位置有物品
        -- 检查是否可以交换
        local destItemType = ItemDefine.GetItemBagType(destItem.common_info.config_id)
        if srcBag.bag_item_type ~= ItemDefine.ItemBagType.ALL
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
    -- Bag.AddLog(change_log[srcBagType], srcPos, ItemDef.LogType.ChangeInfo, srcItem.common_info.config_id,
    --     srcItem.common_info.uniqid, srcItem.common_info.item_count, table.copy(srcItem))
    Bag.AddLog(change_log[srcBagType], srcPos, srcItem)

    if destItem then
        -- 交换物品
        srcBag.items[srcPos] = destItem
        if not change_log[srcBagType] then
            change_log[srcBagType] = {}
        end
        -- Bag.AddLog(change_log[destBagType], destPos, ItemDef.LogType.ChangeInfo, destItem.common_info.config_id,
        --     destItem.common_info.uniqid, destItem.common_info.item_count, table.copy(destItem))
        Bag.AddLog(change_log[destBagType], destPos, destItem)
        destBag.items[destPos] = srcItem

    else
        -- 移动到空位
        if not change_log[srcBagType] then
            change_log[srcBagType] = {}
        end
        -- Bag.AddLog(change_log[destBagType], destPos, ItemDef.LogType.ChangeInfo, 0, 0, 0, nil)
        Bag.AddLog(change_log[destBagType], destPos, {})
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

---@return integer, integer, PBItemData ? nil
function Bag.GetUniqItemData(bagType, uniqid)
    -- 获取数据副本
    if uniqid <= 0 then
        return ErrorCode.ItemNotExist, 0
    end

    local bagdata = scripts.UserModel.GetBagData()
    if not bagdata then
        return ErrorCode.BagNotExist, 0
    end

    local baginfo = bagdata[bagType]
    for pos, itemdata in pairs(baginfo.items) do
        if itemdata.common_info.uniqid == uniqid then
            return ErrorCode.None, pos, table.copy(itemdata)
        end
    end

    return ErrorCode.ItemNotExist, 0
end

---@return integer, PBItemData ? nil
function Bag.MutOneItemData(bagType, pos)
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

---@return integer, integer, PBItemData ? nil
function Bag.MutUniqItemData(bagType, uniqid)
    if uniqid <= 0 then
        return ErrorCode.ItemNotExist, 0
    end
    
    local bagdata = scripts.UserModel.GetBagData()
    if not bagdata then
        return ErrorCode.BagNotExist, 0
    end

    local baginfo = bagdata[bagType]
    for pos, itemdata in pairs(baginfo.items) do
        if itemdata.common_info.uniqid == uniqid then
            return ErrorCode.None, pos, baginfo.items[pos]
        end
    end

    return ErrorCode.ItemNotExist, 0
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
    local err_code, pos, item_data = Bag.MutUniqItemData(BagDef.BagType.Cangku, uniqid)
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
    if inlay_type == 1 then
        if item_cfg.type4 ~= ItemDef.TabooWordInlay.RoleType then
            return ErrorCode.InlayTypeNotMatch
        end
    else
        if uniqitem_cfg.type4 ~= item_cfg.type4 then
            return ErrorCode.InlayTypeNotMatch
        end
        if uniqitem_cfg.type5 ~= item_cfg.type5 then
            return ErrorCode.InlayTypeNotMatch
        end
    end

    -- 扣除道具消耗
    local cost_items = {}
    cost_items[taboo_word_id] = {
        id = taboo_word_id,
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

    -- 处理物品记录
    if not bag_change_log[BagDef.BagType.Cangku] then
        bag_change_log[BagDef.BagType.Cangku] = {}
    end
    Bag.AddLog(bag_change_log[BagDef.BagType.Cangku], pos, item_data)

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
            req.msg.split_count, change_logs)
    elseif req.msg.operate_type == 3 then
        err_code = Bag.MoveItem(req.msg.src_bag, req.msg.src_pos, req.msg.dest_bag, req.msg.dest_pos, change_logs)
    end

    if err_code ~= ErrorCode.None or not change_logs then
        return context.S2C(context.net_id, CmdCode["PBBagOperateItemRspCmd"],
            { code = err_code, error = "执行出错", uid = context.uid }, req.msg_context.stub_id)
    end

    -- local bags = {}
    -- bags[req.msg.src_bag] = 1
    -- bags[req.msg.dest_bag] = 1
    -- local success = Bag.SaveAndLog(bags, change_logs)
    local success = Bag.SaveAndLog(change_logs, ItemDef.ChangeReason.BagMove)
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
    local item_type = ItemDefine.GetItemType(convert_config_id)
    local small_types = ItemDefine.EItemSmallType
    if item_type ~= small_types.MagicItem
        and item_type ~= small_types.HumanDiagrams
        and item_type ~= small_types.GhostDiagrams then
        return ErrorCode.ItemTypeMismatch
    end

    -- 检查道具消耗
    local del_items = {}
    del_items[item_id] = { id = item_id, count = -1, pos = srcPos }
    local err_code = Bag.CheckItemsEnough(BagDef.BagType.Cangku, del_items, {})
    if err_code ~= ErrorCode.None then
        return err_code
    end

    -- 检查背包容量
    local add_items = {}
    add_items[convert_config_id] = { id = convert_config_id, count = 1, pos = 0 }
    err_code = Bag.CheckEmptyEnough(BagDef.BagType.Cangku, add_items, 0)
    if err_code ~= ErrorCode.None then
        return err_code
    end

    -- 根据道具表生成item_data
    local stack_items, unstack_items, deal_coins = {}, {}, {}
    local ok = ItemDefine.GetItemDataFromIdCount(add_items, {}, stack_items, unstack_items, deal_coins)
    if not ok or table.size(stack_items) + table.size(unstack_items) <= 0 then
        return ErrorCode.ItemNotExist
    end

    local change_log = {}
    -- 扣除道具消耗
    err_code = Bag.DelItems(BagDef.BagType.Cangku, del_items, {}, change_log)
    if err_code ~= ErrorCode.None then
        Bag.RollBackWithChange(change_log)
        return err_code
    end
    -- 添加道具
    err_code = Bag.AddItems(BagDef.BagType.Cangku, stack_items, unstack_items, change_log)
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
    if op_itemdata.itype == ItemDefine.EItemSmallType.MagicItem then
        if op_itemdata.special_info and op_itemdata.special_info.magic_item then
            cur_light_cnt = op_itemdata.special_info.magic_item.light_cnt
            cur_tags = op_itemdata.special_info.magic_item.tags
            cur_ability_tag = op_itemdata.special_info.magic_item.ability_tag
        else
            return ErrorCode.ItemNotExist
        end
    elseif op_itemdata.itype == ItemDefine.EItemSmallType.HumanDiagrams
        or op_itemdata.itype == ItemDefine.EItemSmallType.GhostDiagrams then
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
    ItemDefine.GetItemsFromCfg(cost_cfg, 1, true, cost_items, cost_coins)
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
    if op_itemdata.itype == ItemDefine.EItemSmallType.MagicItem then
        op_itemdata.special_info.magic_item.light_cnt = cur_light_cnt + 1
        if new_tag_id >= AbilityTagIdMin then
            table.insert(op_itemdata.special_info.magic_item.ability_tag, new_tag)
        else
            table.insert(op_itemdata.special_info.magic_item.tags, new_tag)
        end
    elseif op_itemdata.itype == ItemDefine.EItemSmallType.HumanDiagrams
        or op_itemdata.itype == ItemDefine.EItemSmallType.GhostDiagrams then
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

            -- 分解后获得的道具列表
            ItemDefine.GetItemsFromCfg(decompose_cfg, value.item_count, false, add_items, add_coins)

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

        err_code = Bag.CheckEmptyEnough(BagDef.BagType.Cangku, add_items, 0)
        if err_code ~= ErrorCode.None then
            return err_code
        end

        -- 根据道具表生成item_data
        -- local add_list = {}
        -- ItemDefine.GetItemListFromItemsCoins(add_items, add_coins, add_list)
        if table.size(add_items) + table.size(add_coins) <= 0 then
            return ErrorCode.ConfigError
        end
        local stack_items, unstack_items, deal_coins = {}, {}, {}
        local ok = ItemDefine.GetItemDataFromIdCount(add_items, add_coins, stack_items, unstack_items, deal_coins)
        if not ok then
            return ErrorCode.ConfigError
        end

        local change_log = {}
        err_code = Bag.DelItemsPos(BagDef.BagType.Cangku, cost_items, change_log)
        if err_code ~= ErrorCode.None then
            Bag.RollBackWithChange(change_log)
            return err_code
        end

        if table.size(stack_items) + table.size(unstack_items) > 0 then
            err_code = Bag.AddItems(BagDef.BagType.Cangku, stack_items, unstack_items, change_log)
            if err_code ~= ErrorCode.None then
                Bag.RollBackWithChange(change_log)
                return err_code
            end
        end

        if table.size(deal_coins) > 0 then
            err_code = Bag.DealCoins(deal_coins, change_log)
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
    -- local save_bags = {}
    -- for bagType, _ in pairs(change_log) do
    --     save_bags[bagType] = 1
    -- end
    -- Bag.SaveAndLog(save_bags, change_log)
    Bag.SaveAndLog(change_log, ItemDef.ChangeReason.ItemDecompose)

    return context.S2C(context.net_id, CmdCode.PBDecomposeRspCmd, {
        code = ErrorCode.None,
        uid = req.msg.uid,
        decompose_items = req.msg.decompose_items or {},
    }, req.msg_context.stub_id)
end

function Bag.PBBagAddCapacityReqCmd(req)
    -- 参数验证
    if not req.msg.uid
        or not req.msg.bag_name
        or not req.msg.add_capacity_id then
        return context.S2C(context.net_id, CmdCode.PBBagAddCapacityRspCmd, {
            code = ErrorCode.ParamInvalid,
            error = "无效请求参数",
            uid = req.msg.uid,
            bag_name = req.msg.bag_name,
        }, req.msg_context.stub_id)
    end

    local err_code, change_log = Bag.AddCapacity(req.msg.bag_name, req.msg.add_capacity_id)
    if err_code ~= ErrorCode.None then
        return context.S2C(context.net_id, CmdCode.PBBagAddCapacityRspCmd, {
            code = err_code,
            error = "添加容量失败",
            uid = req.msg.uid,
            bag_name = req.msg.bag_name,
        }, req.msg_context.stub_id)
    end

    local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
    -- 数据存储更新
    if change_log then
        -- local save_bags = {}
        -- for bagType, _ in pairs(change_log) do
        --     save_bags[bagType] = 1
        -- end
        -- Bag.SaveAndLog(save_bags, change_log)
        Bag.SaveAndLog(change_log, ItemDef.ChangeReason.BagAddCapacity)
    end

    local bag_data = {}
    local res_bag_data = Bag.GetBagdata({req.msg.bag_name})
    if res_bag_data.errcode == ErrorCode.None
        and res_bag_data.bag_datas
        and res_bag_data.bag_datas[req.msg.bag_name] then
        bag_data = res_bag_data.bag_datas[req.msg.bag_name]
    end
    return context.S2C(context.net_id, CmdCode.PBBagAddCapacityRspCmd, {
        code = ErrorCode.None,
        error = "添加容量成功",
        uid = req.msg.uid,
        bag_name = req.msg.bag_name,
        bag_data = bag_data,
    }, req.msg_context.stub_id)
end

function Bag.PBBagSortOutReqCmd(req)
    -- 参数验证
    if not req.msg.uid
        or not req.msg.bag_name then
        return context.S2C(context.net_id, CmdCode.PBBagSortOutRspCmd, {
            code = ErrorCode.ParamInvalid,
            error = "无效请求参数",
            uid = req.msg.uid,
            bag_name = req.msg.bag_name,
        }, req.msg_context.stub_id)
    end

    local err_code = Bag.SortOut(req.msg.bag_name)
    if err_code ~= ErrorCode.None then
        return context.S2C(context.net_id, CmdCode.PBBagSortOutRspCmd, {
            code = err_code,
            error = "整理失败",
            uid = req.msg.uid,
            bag_name = req.msg.bag_name,
        }, req.msg_context.stub_id)
    end

    return context.S2C(context.net_id, CmdCode.PBBagSortOutRspCmd, {
        code = ErrorCode.None,
        error = "整理成功",
        uid = req.msg.uid,
        bag_name = req.msg.bag_name,
    }, req.msg_context.stub_id)
end

-- 根据概率随机是否成功
function Bag.RandomSucc(rate)
    if rate < 0 or rate > 10000 then
        print("Bag.RandomSucc - rate is invalid")
        return ErrorCode.ParamInvalid, 0
    end

    local succ = math.random(1, 10000) <= rate and 1 or 0
    return ErrorCode.None, succ
end

-- 获取随机元素
function Bag.GetRandomElement(container)
    if not container or #container == 0 then
        print("Bag.GetRandomElement - container is empty")
        return ErrorCode.ParamInvalid
    end

    local randomIndex = math.random(1, #container)
    return ErrorCode.None, container[randomIndex]
end

-- 范围内随机值
function Bag.RandomValue(min, max)
    if max <= min then
        print("Bag.RandomValue_ - max is less than min")
        return ErrorCode.ParamInvalid
    end

    return ErrorCode.None, math.random(min, max)
end

function Bag.RandomWeightedIndex(weightMap)
    local totalWeight = 0
    for _, weight in pairs(weightMap) do
        if weight < 0 then
            print("Bag.RandomWeightedIndex_ weight is less than 0")
            return ErrorCode.ParamInvalid
        end
        totalWeight = totalWeight + weight
    end

    if totalWeight == 0 then
        print("Bag.RandomWeightedIndex_ totalWeight is 0")
        return ErrorCode.ParamInvalid
    end

    local rand = math.random(1, totalWeight)
    local sum = 0
    for key, weight in pairs(weightMap) do
        sum = sum + weight
        if rand <= sum then
            return ErrorCode.None, key
        end
    end

    return ErrorCode.ParamInvalid
end

function Bag.PBAntiqueIdentifyReqCmd(req)
    local err_code, error = scripts.AntiqueShowcase.IdentifyAntique(req.msg.config_id, req.msg.uniqid, req.msg.pos)
    return context.S2C(context.net_id, CmdCode.PBAntiqueIdentifyRspCmd, {
        code = err_code,
        error = error,
        config_id = req.msg.config_id,
        uniqid = req.msg.uniqid,
        pos = req.msg.pos,
    }, req.msg_context.stub_id)
end

function Bag.PBAntiqueShowReqCmd(req)
    local err_code, error = scripts.AntiqueShowcase.AntiqueShow(req.msg.config_id, req.msg.uniq_id, req.msg.showcase_id, req.msg.showcase_idx, req.msg.operate_type, req.msg.pos)
    return context.S2C(context.net_id, CmdCode.PBAntiqueShowRspCmd, {
        code = err_code,
        error = error,
        config_id = req.msg.config_id,
        uniq_id = req.msg.uniq_id,
        showcase_id = req.msg.showcase_id,
        showcase_idx = req.msg.showcase_idx,
        operate_type = req.msg.operate_type,
        pos = req.msg.pos,
    }, req.msg_context.stub_id)
end

return Bag