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
local MissionDef = require("common.def.MissionDef")

---@type user_context
local context = ...
local scripts = context.scripts
local AbilityTagIdMin = 1000000
local data_version = 2

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
    print("Bag.Init Random seed initialized:", seed)

    local bagTypes = {}
    bagTypes[BagDef.BagType.Cangku] = 1
    bagTypes[BagDef.BagType.Consume] = 1
    bagTypes[BagDef.BagType.Booty] = 1
    bagTypes[BagDef.BagType.Tool] = 1

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
        bagdata[BagDef.BagType.Tool].bag_item_type = ItemDefine.ItemBagType.TOOL

        local cangku_cfg = GameCfg.WarehouseExpansion[1]
        if cangku_cfg then
            bagdata[BagDef.BagType.Cangku].capacity = cangku_cfg.warehouse_grids
            bagdata[BagDef.BagType.Cangku].grid_id = 1
        end
        local consume_cfg = GameCfg.ConsumablesBackpackExpansion[1]
        if consume_cfg then
            bagdata[BagDef.BagType.Consume].capacity = consume_cfg.consumables_backpack_grids
            bagdata[BagDef.BagType.Consume].grid_id = 1
        end
        local booty_cfg = GameCfg.BootyBackpackExpansion[1]
        if booty_cfg then
            bagdata[BagDef.BagType.Booty].capacity = booty_cfg.booty_backpack_grids
            bagdata[BagDef.BagType.Booty].grid_id = 1
        end
        local tool_cfg = GameCfg.ToolBackpackExpansion[1]
        if tool_cfg then
            bagdata[BagDef.BagType.Tool].capacity = tool_cfg.grids
            bagdata[BagDef.BagType.Tool].grid_id = 1
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

        local init_cangku_items = {}
        local init_coins = {}
        local init_consume_items = {}
        local change_log = {}
        for k, v in pairs(init_cfg.warehouse_bag) do
            local init_item_info = {
                id = k,
                count = v,
            }
            table.insert(init_cangku_items, init_item_info)
        end
        for k, v in pairs(init_cfg.consumables_bag) do
            local init_item_info = {
                id = k,
                count = v,
            }
            table.insert(init_consume_items, init_item_info)
        end
        for k, v in pairs(init_cfg.warehouse_bag) do
            -- local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
            local item_big_type = ItemDefine.GetItemPosType(k)
            if item_big_type == ItemDefine.EItemBigType.Coin then
                local init_coin_info = {
                    coin_id = k,
                    coin_count = v,
                }
                table.insert(init_coins, init_coin_info)
            end
        end

        if table.size(init_cangku_items) > 0 then
            local stack_items, unstack_items, deal_coins = {}, {}, {}
            -- local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
            local ok = ItemDefine.GetItemDataFromIdCount(init_cangku_items, {}, stack_items, unstack_items, deal_coins)
            if ok then
                if table.size(stack_items) + table.size(unstack_items) > 0 then
                    Bag.AddItems(BagDef.BagType.Cangku, stack_items, unstack_items, change_log)
                end
            end
        end

        if table.size(init_consume_items) > 0 then
            local stack_items, unstack_items, deal_coins = {}, {}, {}
            local ok = ItemDefine.GetItemDataFromIdCount(init_consume_items, {}, stack_items, unstack_items, deal_coins)
            -- local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
            if ok then
                if table.size(stack_items) + table.size(unstack_items) > 0 then
                    Bag.AddItems(BagDef.BagType.Consume, stack_items, unstack_items, change_log)
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
        bagTypes[BagDef.BagType.Tool] = 1
        Bag.SaveBagsNow(bagTypes, true)
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

function Bag.SaveBagsNow(bagTypes, is_new)
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

    local write_version = 0
    if is_new then
        write_version = data_version
    end
    local success = Database.saveuserbags(context.addr_db_user, context.uid, save_bags, write_version)
    scripts.UserModel.RemoveDirtyModule("Bag", bagTypes)
    return success
end

function Bag.TimingSave(bagTypes)
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
    local baginfos = Database.loaduserbags(context.addr_db_user, context.uid, bagTypes, data_version)
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

function Bag.AddCapacity(bagType, add_capacity_id, add_capacity_num)
    if bagType ~= BagDef.BagType.Cangku
        and bagType ~= BagDef.BagType.Consume
        and bagType ~= BagDef.BagType.Booty
        and bagType ~= BagDef.BagType.Tool then
        return ErrorCode.BagNotExist
    end

    local bagdata = scripts.UserModel.GetBagData()
    if not bagdata then
        return ErrorCode.BagNotExist
    end

    local cost, after_capacity = {}, 0
    local baginfo = bagdata[bagType]

    -- 检查 add_capacity_id 和 add_capacity_num 只能有一个生效
    if (add_capacity_id and add_capacity_id > 0) and (add_capacity_num and add_capacity_num > 0) then
        return ErrorCode.ParamInvalid
    end

    if add_capacity_id and add_capacity_id > 0 then
        -- 使用配置ID方式扩容
        if bagType == BagDef.BagType.Cangku then
            local cur_grid_id = baginfo.grid_id or 1
            local cur_bag_cfg = GameCfg.WarehouseExpansion[cur_grid_id]
            local bag_cfg = GameCfg.WarehouseExpansion[add_capacity_id]
            if not cur_bag_cfg or not bag_cfg or add_capacity_id ~= cur_grid_id + 1 then
                return ErrorCode.ParamInvalid
            end
            if table.size(bag_cfg.warehouse_cost) <= 0 then
                return ErrorCode.BagCapacityOverflow
            end
            cost = bag_cfg.warehouse_cost
            after_capacity = baginfo.capacity + (bag_cfg.warehouse_grids - cur_bag_cfg.warehouse_grids)
        elseif bagType == BagDef.BagType.Consume then
            local cur_grid_id = baginfo.grid_id or 1
            local cur_bag_cfg = GameCfg.ConsumablesBackpackExpansion[cur_grid_id]
            local bag_cfg = GameCfg.ConsumablesBackpackExpansion[add_capacity_id]
            if not cur_bag_cfg or not bag_cfg or add_capacity_id ~= cur_grid_id + 1 then
                return ErrorCode.ParamInvalid
            end
            if table.size(bag_cfg.consumables_backpack_cost) <= 0 then
                return ErrorCode.BagCapacityOverflow
            end
            cost = bag_cfg.consumables_backpack_cost
            after_capacity = baginfo.capacity +
                (bag_cfg.consumables_backpack_grids - cur_bag_cfg.consumables_backpack_grids)
        elseif bagType == BagDef.BagType.Booty then
            local cur_grid_id = baginfo.grid_id or 1
            local cur_bag_cfg = GameCfg.BootyBackpackExpansion[cur_grid_id]
            local bag_cfg = GameCfg.BootyBackpackExpansion[add_capacity_id]
            if not cur_bag_cfg or not bag_cfg or add_capacity_id ~= cur_grid_id + 1 then
                return ErrorCode.ParamInvalid
            end
            if table.size(bag_cfg.booty_backpack_cost) <= 0 then
                return ErrorCode.BagCapacityOverflow
            end
            cost = bag_cfg.booty_backpack_cost
            after_capacity = baginfo.capacity + (bag_cfg.booty_backpack_grids - cur_bag_cfg.booty_backpack_grids)
        else
            return ErrorCode.ParamInvalid
        end
    elseif add_capacity_num and add_capacity_num > 0 then
        -- 使用直接增加格子数量方式扩容（无消耗）
        after_capacity = baginfo.capacity + add_capacity_num
    else
        return ErrorCode.ParamInvalid
    end

    -- 计算消耗资源（仅配置ID方式需要消耗）
    local change_log = {}
    change_log[bagType] = {}

    if add_capacity_id and add_capacity_id > 0 then
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

        -- 更新当前配置ID
        baginfo.grid_id = add_capacity_id
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

    change_logs = {}
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
        change_reason = change_reason,
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
                    grid_id = baginfo.grid_id,
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
                        local old_data = Bag.dataMap[old_config_id]
                        if not old_data then
                            moon.error(string.format(
                                "[Bag.SaveAndLog] dataMap[%d] is nil! pos=%d bagType=%s reason=%d old_itemdata=%s dataMap=%s",
                                old_config_id, pos, bagType, change_reason,
                                json.pretty_encode(logs),
                                json.pretty_encode(Bag.dataMap)
                            ))
                        else
                            local new_tmp = {
                                old_num = 0,
                                new_num = 0,
                                change_uniq = {},
                            }
                            for _, tmp_data in pairs(old_data) do
                                new_tmp.old_num = new_tmp.old_num + tmp_data.allCount
                            end
                            item_log_datas[old_config_id] = new_tmp
                        end
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
                    -- 设计契约:old_config_id 出现在这里时,Bag.dataMap 必须有对应索引
                    -- 如果不存在,说明上游某处改了背包数据但没同步 dataMap,这是数据错误
                    -- 不能 silently 创建/跳过,必须 assert 暴露以便排查根因
                    if old_config_id > 0 then
                        if not (Bag.dataMap[old_config_id] and Bag.dataMap[old_config_id][bagType]) then
                            -- 收集该 bagType 下所有已注册 config_id,便于定位漏注册的是哪个
                            local registered_cfgs = {}
                            for k, v in pairs(Bag.dataMap) do
                                if v[bagType] then
                                    table.insert(registered_cfgs, k)
                                end
                            end
                            moon.error(string.format(
                                "Bag.SaveAndLog dataMap inconsistent: "
                                .. "old_config_id=%d not in Bag.dataMap (bagType=%s, pos=%d), "
                                .. "old_item_count=%d, old_uniqid=%d, now_config_id=%d, "
                                .. "registered_cfgs_in_bagType=[%s], "
                                .. "old_itemdata=%s, now_itemdata=%s",
                                old_config_id, bagType, pos,
                                old_item_count, old_uniqid, now_config_id,
                                table.concat(registered_cfgs, ","),
                                json.pretty_encode(old_itemdata or {}),
                                json.pretty_encode(now_itemdata or {})))
                        end
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
    local save_now = false
    -- 统计所有记录变更
    if change_reason ~= ItemDef.ChangeReason.BagMove
        and change_reason ~= ItemDef.ChangeReason.SortOutItems then
            
        if change_reason ~= ItemDef.ChangeReason.GameStartCost then
            save_now = true
        end
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
        if save_now then
            success = Bag.SaveBagsNow(bagTypes)
        else
            scripts.UserModel.AddDirtyModule("Bag", bagTypes)
            success = true
        end
    end

    --发送PBBagUpdateSyncCmd
    if success then
        --local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
        context.S2C(context.net_id, CmdCode["PBBagUpdateSyncCmd"], update_msg, 0)
    end

    --存储日志
    if change_reason ~= ItemDef.ChangeReason.BagMove
        and change_reason ~= ItemDef.ChangeReason.SortOutItems then
        if table.size(write_log_datas) > 0 then
            scripts.Item.SendLog(write_log_datas)
        end

        -- 触发道具任务
        for _, write_log in pairs(write_log_datas) do
            if write_log.new_num > write_log.old_num then
                local param1 = 0
                local item_cfg = GameCfg.Item[write_log.config_id]
                if item_cfg then
                    param1 = item_cfg.type1
                end
                if param1 == 0 then
                    local uniq_cfg = GameCfg.UniqueItem[write_log.config_id]
                    if uniq_cfg then
                        param1 = uniq_cfg.type1
                    end
                end
                scripts.Mission.TriggerCondition(MissionDef.EConditionIds.GET_ITEM_CNT,
                    { param1, write_log.config_id, change_reason }, write_log.new_num - write_log.old_num)
            elseif write_log.new_num < write_log.old_num then
                local param1 = 0
                local item_cfg = GameCfg.Item[write_log.config_id]
                if item_cfg then
                    param1 = item_cfg.type1
                end
                if param1 == 0 then
                    local uniq_cfg = GameCfg.UniqueItem[write_log.config_id]
                    if uniq_cfg then
                        param1 = uniq_cfg.type1
                    end
                end
                scripts.Mission.TriggerCondition(MissionDef.EConditionIds.CONSUME_ITEM_CNT,
                    { param1, write_log.config_id, change_reason }, write_log.old_num - write_log.new_num)
            end
        end
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
    if pos < 0 then
        moon.error("Bag.AddLog pos = ", pos)
        moon.error(string.format("logs = %s", json.pretty_encode(logs)))
        if old_itemdata then
            moon.error(string.format("old_itemdata = %s", json.pretty_encode(old_itemdata)))
        end
        return
    end

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
        and bagType ~= BagDef.BagType.Booty
        and bagType ~= BagDef.BagType.Tool then
        return ErrorCode.BagNotExist
    end

    local bagdata = scripts.UserModel.GetBagData()
    if not bagdata or not bagdata[bagType] then
        return ErrorCode.BagNotExist
    end

    local now_config_ids = {}
    for config_id, _ in pairs(Bag.dataMap) do
        if Bag.dataMap[config_id][bagType] then
            table.insert(now_config_ids, config_id)
        end
    end
    if table.size(now_config_ids) <= 0 then
        return ErrorCode.BagEmpty
    end
    table.sort(now_config_ids)

    -- local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
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
                                if not dest_item or not src_item then
                                    moon.error(string.format(
                                        "[Bag.SortOut stack] item nil! bagType=%s config_id=%d dest_pos=%d src_pos=%d dest_count=%d src_count=%d count=%d dest_item=%s src_item=%s\n"
                                        .. "stack_baginfo.items=%s\n"
                                        .. "bdata[bagType].pos_count=%s",
                                        bagType, config_id, dest_pos, src_pos, dest_count, src_count, count,
                                        tostring(dest_item), tostring(src_item),
                                        json.pretty_encode(stack_baginfo.items),
                                        json.pretty_encode(bdata[bagType].pos_count)
                                    ))
                                end
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

    -- local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
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
    for _, config_id in ipairs(now_config_ids) do
        local bdata = Bag.dataMap[config_id][bagType]
        if bdata then
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

-- 整理背包（新实现，保持原 Bag.SortOut 不变以便对比）
---@param bagType string
function Bag.SortOutNew(bagType)
    -- 参数校验
    if bagType ~= BagDef.BagType.Cangku
        and bagType ~= BagDef.BagType.Consume
        and bagType ~= BagDef.BagType.Booty
        and bagType ~= BagDef.BagType.Tool then
        return ErrorCode.BagNotExist
    end

    local bagdata = scripts.UserModel.GetBagData()
    if not bagdata or not bagdata[bagType] then
        return ErrorCode.BagNotExist
    end

    local baginfo = bagdata[bagType]
    if not baginfo.items or table.size(baginfo.items) <= 0 then
        return ErrorCode.BagEmpty
    end

    -- 1) 收集所有物品，拆分为可堆叠和不可堆叠两组
    -- 同一 config_id 视为可堆叠；uniqid != 0 的物品单独存放
    local stackable_groups = {} -- config_id -> list of {pos, item, count}
    local unique_items = {}     -- list of {pos, item, uniqid, config_id}
    for pos, item in pairs(baginfo.items) do
        if not item or not item.common_info then
            baginfo.items[pos] = nil
        else
            local cfg_id = item.common_info.config_id
            local uniqid = item.common_info.uniqid
            if uniqid and uniqid ~= 0 then
                table.insert(unique_items, {
                    pos = pos,
                    item = item,
                    uniqid = uniqid,
                    config_id = cfg_id,
                })
            else
                if not stackable_groups[cfg_id] then
                    stackable_groups[cfg_id] = {}
                end
                table.insert(stackable_groups[cfg_id], {
                    pos = pos,
                    item = item,
                    count = item.common_info.item_count or 0,
                })
            end
        end
    end

    -- 2) 按 config_id 升序排序，确定可堆叠物品的最终顺序
    local sorted_cfg_ids = {}
    for cfg_id, _ in pairs(stackable_groups) do
        table.insert(sorted_cfg_ids, cfg_id)
    end
    table.sort(sorted_cfg_ids)

    -- 3) 堆叠阶段：同类物品按堆叠上限合并，记录变更日志
    local stack_change_logs = { [bagType] = {} }
    local need_rebuild = false
    for _, cfg_id in ipairs(sorted_cfg_ids) do
        local item_cfg = GameCfg.Item[cfg_id]
        if not item_cfg then
            -- 配置不存在时跳过
            stackable_groups[cfg_id] = nil
        else
            local group = stackable_groups[cfg_id]
            -- 同组内按数量降序排列：先把大堆作为目标，后续小堆往里塞
            table.sort(group, function(a, b)
                return a.count > b.count
            end)

            for i = 1, #group - 1 do
                local dest = group[i]
                if dest.count < item_cfg.stack_count then
                    for j = i + 1, #group do
                        local src = group[j]
                        if dest.count >= item_cfg.stack_count then
                            break
                        end
                        if src.count > 0 then
                            local space = item_cfg.stack_count - dest.count
                            local move = math.min(space, src.count)
                            if move > 0 then
                                Bag.AddLog(stack_change_logs[bagType], dest.pos, dest.item)
                                Bag.AddLog(stack_change_logs[bagType], src.pos, src.item)
                                dest.item.common_info.item_count = dest.item.common_info.item_count + move
                                src.item.common_info.item_count = src.item.common_info.item_count - move
                                dest.count = dest.item.common_info.item_count
                                src.count = src.item.common_info.item_count
                                need_rebuild = true
                            end
                        end
                    end
                end
            end
        end
    end

    if need_rebuild then
        local success = Bag.SaveAndLog(stack_change_logs, ItemDef.ChangeReason.SortOutItems)
        if not success then
            return ErrorCode.BagSortOutFailed
        end
    end

    -- 4) 重建 items：按 config_id 升序，每个 config_id 内「可堆叠物品」在前、「唯一物品」在后
    --    这样可以保证最终顺序完全按 config_id 从小到大排列
    -- 收集所有涉及的 config_id（可堆叠 + 唯一物品）
    local all_cfg_ids = {}
    local seen = {}
    for _, cfg_id in ipairs(sorted_cfg_ids) do
        all_cfg_ids[#all_cfg_ids + 1] = cfg_id
        seen[cfg_id] = true
    end
    for _, entry in ipairs(unique_items) do
        if not seen[entry.config_id] then
            all_cfg_ids[#all_cfg_ids + 1] = entry.config_id
            seen[entry.config_id] = true
        end
    end
    table.sort(all_cfg_ids)

    -- 唯一物品按 config_id 分桶（桶内保持原顺序）
    local unique_by_cfg = {}
    for _, entry in ipairs(unique_items) do
        if not unique_by_cfg[entry.config_id] then
            unique_by_cfg[entry.config_id] = {}
        end
        table.insert(unique_by_cfg[entry.config_id], entry)
    end

    local old_items = baginfo.items
    local new_items = {}
    local new_pos_count = {}  -- config_id -> { [pos] = count }
    local new_uniqid_pos = {} -- config_id -> { [uniqid] = pos }
    local new_all_count = {}  -- config_id -> number
    local cur_pos = 1

    for _, cfg_id in ipairs(all_cfg_ids) do
        -- 先填入可堆叠物品
        local group = stackable_groups[cfg_id]
        if group then
            for _, entry in ipairs(group) do
                if entry.count > 0 and entry.item.common_info.item_count > 0 then
                    new_items[cur_pos] = entry.item
                    if not new_pos_count[cfg_id] then
                        new_pos_count[cfg_id] = {}
                    end
                    new_pos_count[cfg_id][cur_pos] = entry.item.common_info.item_count
                    new_all_count[cfg_id] = (new_all_count[cfg_id] or 0) + entry.item.common_info.item_count
                    cur_pos = cur_pos + 1
                end
            end
        end

        -- 再填入唯一物品
        local u_items = unique_by_cfg[cfg_id]
        if u_items then
            for _, entry in ipairs(u_items) do
                new_items[cur_pos] = entry.item
                if not new_uniqid_pos[cfg_id] then
                    new_uniqid_pos[cfg_id] = {}
                end
                new_uniqid_pos[cfg_id][entry.uniqid] = cur_pos
                new_all_count[cfg_id] = (new_all_count[cfg_id] or 0) + 1
                cur_pos = cur_pos + 1
            end
        end
    end

    -- 5) 记录移动日志并替换 items
    local move_change_logs = { [bagType] = {} }
    local need_save_move = false
    for old_pos, old_item in pairs(old_items) do
        if old_item and old_item.common_info then
            Bag.AddLog(move_change_logs[bagType], old_pos, old_item)
            need_save_move = true
        end
    end
    for new_pos, new_item in pairs(new_items) do
        if not move_change_logs[bagType][new_pos] then
            Bag.AddLog(move_change_logs[bagType], new_pos, {})
            need_save_move = true
        end
    end

    baginfo.items = new_items

    if need_save_move then
        local success = Bag.SaveAndLog(move_change_logs, ItemDef.ChangeReason.SortOutItems)
        if not success then
            return ErrorCode.BagSortOutFailed
        end
    end

    -- 6) 同步 Bag.dataMap 中的 pos_count / uniqid_pos / allCount（仅针对本 bagType）
    for _, cfg_id in ipairs(all_cfg_ids) do
        local bd = Bag.dataMap[cfg_id] and Bag.dataMap[cfg_id][bagType]
        if bd then
            bd.pos_count = new_pos_count[cfg_id] or {}
            bd.uniqid_pos = new_uniqid_pos[cfg_id] or {}
            bd.allCount = new_all_count[cfg_id] or 0
            Bag.dataMap[cfg_id][bagType] = bd
        end
    end

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
                new_item.itype = ItemDefine.GetItemType(item_cfg.id)
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
        for cur_pos, itemdata in pairs(baginfo.items) do
            if itemdata.common_info.config_id == itemId
                and itemdata.common_info.uniqid == 0
                and itemdata.common_info.item_count > 0 then
                local canSub = math.min(itemdata.common_info.item_count, -remaining)

                -- Bag.AddLog(logs, cur_pos, ItemDef.LogType.ChangeNum, itemId, 0, itemdata.common_info.item_count)
                Bag.AddLog(logs, cur_pos, itemdata)
                itemdata.common_info.item_count = itemdata.common_info.item_count - canSub
                if itemdata.common_info.item_count == 0 then
                    baginfo.items[cur_pos] = nil
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
                -- new_item.common_info.uniqid = uuid.next()
                new_item.common_info.uniqid = common.UniqueId.next()
                -- 只在古董 config_id 范围内打印日志
                local config_id = item_data.common_info.config_id
                if config_id >= ItemDefine.Antique.start and config_id <= ItemDefine.Antique.End then
                    moon.info(string.format("[AddUniqItem] generated new uniqid=%d for antique config_id=%d, bagType=%s, pos=%d",
                        new_item.common_info.uniqid, config_id, bagType, pos))
                end
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
    local item_cfg = GameCfg.UniqueItem[item_data.common_info.config_id] -- 耐久度道具配置？
    if not item_cfg then
        return ErrorCode.ItemNotExist
    end
    -- 类型检查
    local item_type = ItemDefine.GetItemBagType(item_data.common_info.config_id)
    if baginfo.bag_item_type ~= ItemDefine.ItemBagType.ALL
        and baginfo.bag_item_type ~= item_type then
        return ErrorCode.BagTypeMismatch
    end

    -- local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
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
                new_item.special_info.durab_item.cur_durability = item_cfg.durability
            end
            if new_item.common_info.uniqid == 0 then
                -- new_item.common_info.uniqid = uuid.next()
                new_item.common_info.uniqid = common.UniqueId.next()
            end

            baginfo.items[pos] = new_item
            -- Bag.AddLog(change_log, pos, ItemDef.LogType.ChangeNum, 0, 0, 0)
            Bag.AddLog(change_log, pos, {})
            add_pos = pos

            break
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
        local item_cfg = GameCfg.UniqueItem[item_data.common_info.config_id]
        if item_cfg then
            new_itemdata.special_info.magic_item.cur_durability = item_cfg.durability
            new_itemdata.special_info.magic_item.strong_value = item_cfg.sturdy
        end
    end

    if table.size(new_itemdata.special_info.magic_item.tags) == 0 then
        -- 获取默认词条
        local uniq_item_cfg = GameCfg.UniqueItem[item_data.common_info.config_id]
        if uniq_item_cfg and uniq_item_cfg.default_entry and table.size(uniq_item_cfg.default_entry) > 0 then
            for tag_id, tag_value in pairs(uniq_item_cfg.default_entry) do
                local new_tag = {
                    tag_id = tag_id,
                    val = tag_value,
                }
                table.insert(new_itemdata.special_info.magic_item.tags, new_tag)
            end
        end
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
        local item_cfg = GameCfg.UniqueItem[item_data.common_info.config_id]
        if item_cfg then
            new_itemdata.special_info.diagrams_item.cur_durability = item_cfg.durability
            new_itemdata.special_info.diagrams_item.strong_value = item_cfg.sturdy
        end
    end
    if table.size(new_itemdata.special_info.diagrams_item.tags) == 0 then
        -- 获取默认词条
        local uniq_item_cfg = GameCfg.UniqueItem[item_data.common_info.config_id]
        if uniq_item_cfg and uniq_item_cfg.default_entry and table.size(uniq_item_cfg.default_entry) > 0 then
            for tag_id, tag_value in pairs(uniq_item_cfg.default_entry) do
                local new_tag = {
                    tag_id = tag_id,
                    val = tag_value,
                }
                table.insert(new_itemdata.special_info.diagrams_item.tags, new_tag)
            end
        end
    end

    return ErrorCode.None
end

function Bag.AddSpaceRing(bagType, baginfo, item_data, change_log)
    local itype = ItemDefine.GetItemType(item_data.common_info.config_id)
    local errorCode, add_pos = Bag.AddUniqItem(bagType, baginfo, item_data, itype, change_log)
    if errorCode ~= ErrorCode.None or not add_pos then
        return errorCode
    end

    local new_itemdata = baginfo.items[add_pos]
    if item_data.special_info and item_data.special_info.space_ring then
        new_itemdata.special_info = table.copy(item_data.special_info, true)
    else
        new_itemdata.special_info = {
            space_ring = ItemDef.newSpaceRing(),
        }
        local item_cfg = GameCfg.UniqueItem[item_data.common_info.config_id]
        if item_cfg then
            new_itemdata.special_info.space_ring.cur_durability = item_cfg.durability
            new_itemdata.special_info.space_ring.strong_value = item_cfg.sturdy
        end
    end
    if table.size(new_itemdata.special_info.space_ring.tags) == 0 then
        -- 获取默认词条
        local uniq_item_cfg = GameCfg.UniqueItem[item_data.common_info.config_id]
        if uniq_item_cfg and uniq_item_cfg.default_entry and table.size(uniq_item_cfg.default_entry) > 0 then
            for tag_id, tag_value in pairs(uniq_item_cfg.default_entry) do
                local new_tag = {
                    tag_id = tag_id,
                    val = tag_value,
                }
                table.insert(new_itemdata.special_info.space_ring.tags, new_tag)
            end
        end
    end

    return ErrorCode.None
end

function Bag.AddSkinCard(bagType, baginfo, item_data, change_log)
    local item_cfg = GameCfg.UniqueItem[item_data.common_info.config_id] -- 耐久度道具配置？
    if not item_cfg then
        return ErrorCode.ItemNotExist
    end
    -- 类型检查
    local item_type = ItemDefine.GetItemBagType(item_data.common_info.config_id)
    if baginfo.bag_item_type ~= ItemDefine.ItemBagType.ALL
        and baginfo.bag_item_type ~= item_type then
        return ErrorCode.BagTypeMismatch
    end

    -- local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
    -- 处理物品记录
    local add_pos = 0
    local itype = ItemDefine.GetItemType(item_data.common_info.config_id)
    for pos = 1, baginfo.capacity do
        if not baginfo.items[pos] then
            --local new_item = ItemDef.newItemData()
            local new_item = table.copy(item_data)
            if not new_item
                or not new_item.common_info then
                new_item = ItemDef.newItemData()
                new_item.itype = itype
                new_item.common_info.config_id = item_cfg.id
                new_item.common_info.item_count = 1
                new_item.common_info.item_type = item_cfg.type1
                new_item.common_info.trade_cnt = -1
            end
            if new_item.common_info.uniqid == 0 then
                -- new_item.common_info.uniqid = uuid.next()
                new_item.common_info.uniqid = common.UniqueId.next()
            end

            baginfo.items[pos] = new_item
            -- Bag.AddLog(change_log, pos, ItemDef.LogType.ChangeNum, 0, 0, 0)
            Bag.AddLog(change_log, pos, {})
            add_pos = pos

            break
        end
    end
    if add_pos == 0 then
        return ErrorCode.BagFull
    end

    return ErrorCode.None
end

function Bag.SyncBagInfo(bagType, sync_baginfo, change_log)
    -- 参数校验
    if bagType ~= BagDef.BagType.Cangku
        and bagType ~= BagDef.BagType.Consume
        and bagType ~= BagDef.BagType.Booty
        and bagType ~= BagDef.BagType.Tool then
        moon.error("Bag.SyncBagInfo bagType error: ", bagType)
        return ErrorCode.BagNotExist
    end

    local bagdata = scripts.UserModel.GetBagData()
    if not bagdata or not bagdata[bagType] then
        moon.error("Bag.SyncBagInfo not bagdata bagType: ", bagType)
        return ErrorCode.BagNotExist
    end
    local now_baginfo = bagdata[bagType]

    if sync_baginfo.capacity then
        if sync_baginfo.capacity < now_baginfo.capacity then
            moon.error("Bag.SyncBagInfo sync_baginfo.capacity error: ", sync_baginfo.capacity, now_baginfo.capacity)
            return ErrorCode.BagNotExist
        end
        now_baginfo.capacity = sync_baginfo.capacity
    end
        
    if not change_log[bagType] then
        change_log[bagType] = {}
    end
    for i = 1, now_baginfo.capacity do
        local now_itemdata = now_baginfo.items[i]
        local sync_itemdata = sync_baginfo.items[i]

        if now_itemdata and sync_itemdata then
            if sync_itemdata.common_info.uniqid ~= now_itemdata.common_info.uniqid then
                Bag.AddLog(change_log[bagType], i, now_itemdata)
                now_baginfo.items[i] = sync_itemdata
            else
                if now_itemdata.common_info.uniqid == 0 then
                    if now_itemdata.common_info.config_id ~= sync_itemdata.common_info.config_id
                        or now_itemdata.common_info.item_count ~= sync_itemdata.common_info.item_count
                        or now_itemdata.common_info.item_type ~= sync_itemdata.common_info.item_type
                        or now_itemdata.common_info.trade_cnt ~= sync_itemdata.common_info.trade_cnt then
                        Bag.AddLog(change_log[bagType], i, now_itemdata)
                        now_baginfo.items[i] = sync_itemdata
                    end
                else
                    Bag.AddLog(change_log[bagType], i, now_itemdata)
                    now_baginfo.items[i] = sync_itemdata
                end
            end
        elseif sync_itemdata then
            Bag.AddLog(change_log[bagType], i, {})
            now_baginfo.items[i] = sync_itemdata
        elseif now_itemdata then
            Bag.AddLog(change_log[bagType], i, now_itemdata)
            now_baginfo.items[i] = nil
        end
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

function Bag.GetCoinCount(coin_id)
    local coinsdata = scripts.UserModel.GetCoinsData()
    if not coinsdata then
        return 0
    end

    if coinsdata.coins[coin_id] and coinsdata.coins[coin_id].coin_count ~= 0 then
        return coinsdata.coins[coin_id].coin_count
    end
    return 0
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
        -- moon.warn(string.format("Bag.GetItemPosNum Bag.dataMap=%s", json.pretty_encode(Bag.dataMap)))
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
        and bagType ~= BagDef.BagType.Booty
        and bagType ~= BagDef.BagType.Tool then
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
    local need_bound_items = {} -- 暂存转换的非绑道具
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

            local item_cfg = GameCfg.Item[itemid]
            if item_cfg and item_cfg.bound_id ~= 0 then
                if count + remaining < 0 then
                    -- 尝试用非绑道具补足
                    local bound_count = Bag.GetItemCount(item_cfg.bound_id, bagType)
                    if count + bound_count + remaining < 0 then
                        return ErrorCode.ItemNotEnough
                    else
                        -- 修改绑定道具消耗数量
                        item.count = -count
                        if not need_bound_items[item_cfg.bound_id] then
                            need_bound_items[item_cfg.bound_id] = {
                                id = item_cfg.bound_id,
                                count = count + remaining,
                                pos = 0
                            }
                        else
                            need_bound_items[item_cfg.bound_id].count = need_bound_items[item_cfg.bound_id].count + count +
                                remaining
                        end
                    end
                end
            else
                if count + remaining < 0 then
                    return ErrorCode.ItemNotEnough
                end
            end
        end
    end
    for bound_id, bound_item in pairs(need_bound_items) do
        local need_count = bound_item.count
        if del_items[bound_id] then
            need_count = need_count + del_items[bound_id].count
        end

        local count = Bag.GetItemCount(bound_id, bagType)
        if count + need_count < 0 then
            return ErrorCode.ItemNotEnough
        else
            if del_items[bound_id] then
                del_items[bound_id].count = need_count
            else
                del_items[bound_id] = bound_item
            end
        end
    end

    return ErrorCode.None
end

-- 根据pos检测道具是否足够
function Bag.CheckItemsEnoughPos(bagType, del_items)
    moon.debug("Bag.CheckItemsEnoughPos bagType=", bagType)
    moon.debug(string.format("Bag.CheckItemsEnoughPos del_items=%s", json.pretty_encode(del_items)))
    -- 参数校验
    if bagType ~= BagDef.BagType.Cangku
        and bagType ~= BagDef.BagType.Consume
        and bagType ~= BagDef.BagType.Booty
        and bagType ~= BagDef.BagType.Tool then
        moon.error("return 1")
        return ErrorCode.BagNotExist
    end

    local bagdata = scripts.UserModel.GetBagData()
    if not bagdata or not bagdata[bagType] then
        moon.error("return 2")
        return ErrorCode.BagNotExist
    end
    local baginfo = bagdata[bagType]

    for pos, item in pairs(del_items) do
        if item.item_count >= 0 then
            moon.error("return 3")
            return ErrorCode.ParamInvalid
        end

        if not baginfo.items[pos] then
            moon.error(string.format("Bag.CheckItemsEnoughPos item not exist pos=%d", pos))
            return ErrorCode.ItemNotExist
        end

        if not del_items.uniqid or del_items.uniqid == 0 then
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

    --绑定货币不足时进行对应转换
    local mod_coins = {}
    for coinid, coin in pairs(coins) do
        if coin.coin_count < 0 then
            local coin_cfg = GameCfg.Coin[coinid]
            if coin_cfg and coin_cfg.coin_bound ~= 0 then
                local need_coin_cnt = coin.coin_count
                local have_coin_cnt = 0
                if coinsdata.coins[coinid] and coinsdata.coins[coinid].coin_count ~= 0 then
                    have_coin_cnt = coinsdata.coins[coinid].coin_count
                end
                if have_coin_cnt + need_coin_cnt < 0 then
                    local need_coin_bound_cnt = have_coin_cnt + need_coin_cnt
                    if not mod_coins[coin_cfg.coin_bound] then
                        mod_coins[coin_cfg.coin_bound] = 0
                    end
                    mod_coins[coin_cfg.coin_bound] = mod_coins[coin_cfg.coin_bound] + need_coin_bound_cnt
                end
            end
        end
    end
    for id, cnt in pairs(mod_coins) do
        if not coins[id] then
            coins[id] = {
                coin_id = id,
                coin_count = 0,
            }
        end
        coins[id].coin_count = coins[id].coin_count + cnt
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
        and bagType ~= BagDef.BagType.Booty
        and bagType ~= BagDef.BagType.Tool then
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
        if itemid >=ItemDefine.AweItem.start and itemid <= ItemDefine.AweItem.End then
            break
        end

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
        elseif (item_big_type == ItemDefine.EItemBigType.UnStackItem and uniqitem_cfg)
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
        and bagType ~= BagDef.BagType.Booty
        and bagType ~= BagDef.BagType.Tool then
        moon.error("Bag.TryEmptyEnough error bagType", bagType)
        return ErrorCode.BagNotExist
    end

    local bagdata = scripts.UserModel.GetBagData()
    if not bagdata or not bagdata[bagType] then
        moon.error("Bag.TryEmptyEnough not bagdata", bagType)
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
            moon.error(string.format("Bag.TryEmptyEnough add_items=%s", json.pretty_encode(add_items)))
            return ErrorCode.ParamInvalid
        end
        local item_cfg = GameCfg.Item[itemid]
        local uniqitem_cfg = GameCfg.UniqueItem[itemid]
        if not item_cfg and not uniqitem_cfg then
            moon.error(string.format("Bag.TryEmptyEnough not item_cfg and not uniqitem_cfg itemid=%d", itemid))
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
        elseif (item_big_type == ItemDefine.EItemBigType.UnStackItem and uniqitem_cfg)
            or (item_big_type == ItemDefine.EItemBigType.UniqueItem and uniqitem_cfg) then
            empty_pos_num = empty_pos_num - item.count
            if empty_pos_num < 0 then
                ret_code = ErrorCode.BagFull
            end
        else
            moon.error(string.format("Bag.TryEmptyEnough not item_big_type itemid=%d", itemid))
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
        and bagType ~= BagDef.BagType.Booty
        and bagType ~= BagDef.BagType.Tool then
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
        and bagType ~= BagDef.BagType.Booty
        and bagType ~= BagDef.BagType.Tool then
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
        and bagType ~= BagDef.BagType.Booty
        and bagType ~= BagDef.BagType.Tool then
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
        elseif item_small_type == ItemDefine.EItemSmallType.DurabItem
            or item_small_type == ItemDefine.EItemSmallType.Tool then
            err_code = Bag.AddDurabItem(bagType, baginfo, item_data, change_log[bagType])
        elseif item_small_type == ItemDefine.EItemSmallType.Antique then
            err_code = Bag.AddAntique(bagType, baginfo, item_data, change_log[bagType])
        elseif item_small_type == ItemDefine.EItemSmallType.SpaceRing then
            err_code = Bag.AddSpaceRing(bagType, baginfo, item_data, change_log[bagType])
        elseif item_small_type == ItemDefine.EItemSmallType.SkinCard then
            err_code = Bag.AddSkinCard(bagType, baginfo, item_data, change_log[bagType])
        else
            moon.error(string.format("AddItems failed, item_data=%s", json.pretty_encode(item_data)))
            err_code = ErrorCode.ItemNotExist
        end

        if err_code ~= ErrorCode.None then
            return err_code
        end
    end

    -- -- 判断图鉴是否需要更新
    -- local change_image_ids = {}
    -- for pos, old_itemdata in pairs(change_log[bagType]) do
    --     if table.size(old_itemdata) <= 0 then
    --         scripts.ItemImage.AddItemImage(baginfo.items[pos].common_info.config_id, change_image_ids, true)
    --     end
    -- end
    -- -- 发送图鉴更新消息
    -- if table.size(change_image_ids) > 0 then
    --     scripts.ItemImage.SaveAndLog(change_image_ids)
    -- end

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
        local coin_cfg = GameCfg.Coin[coinid]
        if not coin_cfg then
            return ErrorCode.CoinNotExist
        end

        if coin.coin_count < 0 and not coinsdata.coins[coinid] then
            -- Bag.RollBackWithChange(change_log)
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

        if coinsdata.coins[coinid].coin_count + coin.coin_count > coin_cfg.max_num then
            coinsdata.coins[coinid].coin_count = coin_cfg.max_num
        else
            coinsdata.coins[coinid].coin_count = coinsdata.coins[coinid].coin_count + coin.coin_count
        end
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
        and srcBagType ~= BagDef.BagType.Booty
        and srcBagType ~= BagDef.BagType.Tool then
        return ErrorCode.BagNotExist
    end

    if destBagType ~= BagDef.BagType.Cangku
        and destBagType ~= BagDef.BagType.Consume
        and destBagType ~= BagDef.BagType.Booty
        and destBagType ~= BagDef.BagType.Tool then
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
    if srcBag.capacity < srcPos or destBag.capacity < destPos
        or srcPos <= 0 or destPos <= 0 then
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
        and srcBagType ~= BagDef.BagType.Booty
        and srcBagType ~= BagDef.BagType.Tool then
        return ErrorCode.BagNotExist
    end

    if destBagType ~= BagDef.BagType.Cangku
        and destBagType ~= BagDef.BagType.Consume
        and destBagType ~= BagDef.BagType.Booty
        and destBagType ~= BagDef.BagType.Tool then
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
    if srcBag.capacity < srcPos or destBag.capacity < destPos
        or srcPos <= 0 or destPos <= 0 then
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
        and srcBagType ~= BagDef.BagType.Booty
        and srcBagType ~= BagDef.BagType.Tool then
        return ErrorCode.BagNotExist
    end

    if destBagType ~= BagDef.BagType.Cangku
        and destBagType ~= BagDef.BagType.Consume
        and destBagType ~= BagDef.BagType.Booty
        and destBagType ~= BagDef.BagType.Tool then
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
    if srcBag.capacity < srcPos or destBag.capacity < destPos
        or srcPos <= 0 or destPos <= 0 then
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
        if not change_log[destBagType] then
            change_log[destBagType] = {}
        end
        -- Bag.AddLog(change_log[destBagType], destPos, ItemDef.LogType.ChangeInfo, destItem.common_info.config_id,
        --     destItem.common_info.uniqid, destItem.common_info.item_count, table.copy(destItem))
        Bag.AddLog(change_log[destBagType], destPos, destItem)
        destBag.items[destPos] = srcItem

    else
        -- 移动到空位
        if not change_log[destBagType] then
            change_log[destBagType] = {}
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

function Bag.GetUniqItemDurability(bagType, uniqid)
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
            local item_small_type = ItemDefine.GetItemType(itemdata.common_info.config_id)
            if item_small_type == ItemDefine.EItemSmallType.DurabItem then
                return ErrorCode.None, itemdata.special_info.durab_item.cur_durability
            elseif item_small_type == ItemDefine.EItemSmallType.MagicItem then
                return ErrorCode.None, itemdata.special_info.magic_item.cur_durability
            elseif item_small_type == ItemDefine.EItemSmallType.HumanDiagrams
                or item_small_type == ItemDefine.EItemSmallType.GhostDiagrams then
                return ErrorCode.None, itemdata.special_info.diagrams_item.cur_durability
            elseif item_small_type == ItemDefine.EItemSmallType.Antique then
                return ErrorCode.None, itemdata.special_info.antique_item.cur_durability
            elseif item_small_type == ItemDefine.EItemSmallType.SpaceRing then
                return ErrorCode.None, itemdata.special_info.space_ring.cur_durability
            else
                return ErrorCode.None, 0
            end
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
            and bag_name ~= BagDef.BagType.Booty
            and bag_name ~= BagDef.BagType.Tool then
            return { errcode = ErrorCode.BagNotExist }
        end

        if bagdata[bag_name] then
            res.bag_datas[bag_name] = bagdata[bag_name]
        end
    end

    return res
end

function Bag.GetBagCapacity(bags_name)
    local bagdata = scripts.UserModel.GetBagData()
    if not bagdata then
        return nil
    end

    local capacitys = {}
    for _, bag_name in pairs(bags_name) do
        if bag_name == BagDef.BagType.Cangku
            or bag_name == BagDef.BagType.Consume
            or bag_name == BagDef.BagType.Booty
            or bag_name == BagDef.BagType.Tool then
            if bagdata[bag_name] then
                capacitys[bag_name] = bagdata[bag_name].capacity
            else
                return nil
            end
        end
    end

    return capacitys
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
    else--[[if inlay_type == 2 then]]
        if not item_data.special_info
            or not item_data.special_info.diagrams_item then
            return ErrorCode.ItemNotExist
        end
    -- elseif inlay_type == 3 then
    --     if not item_data.special_info
    --         or not item_data.special_info.space_ring then
    --         return ErrorCode.ItemNotExist
    --     end
    end

    local uniqitem_cfg = GameCfg.UniqueItem[item_data.common_info.config_id]
    local item_cfg = GameCfg.Item[taboo_word_id]
    if not uniqitem_cfg or not item_cfg then
        return ErrorCode.ConfigError
    end
    -- if inlay_type == 1 then
    --     if item_cfg.type4 ~= ItemDef.TabooWordInlay.RoleType then
    --         return ErrorCode.InlayTypeNotMatch
    --     end
    -- else--[[if inlay_type == 2 then]]
    --     if uniqitem_cfg.type4 ~= item_cfg.type4 then
    --         return ErrorCode.InlayTypeNotMatch
    --     end
    --     if uniqitem_cfg.type5 ~= item_cfg.type5 then
    --         return ErrorCode.InlayTypeNotMatch
    --     end
    -- end
    local is_match = false
    for _, inlay in pairs(uniqitem_cfg.text_type) do
        if inlay == item_cfg.type4 then
            is_match = true
            break
        end
    end
    if not is_match then
        return ErrorCode.InlayTypeNotMatch
    end

    -- 扣除道具消耗
    local cost_items = {}
    cost_items[taboo_word_id] = {
        id = taboo_word_id,
        count = -1,
        pos = 0,
    }
    err_code = Bag.CheckItemsEnough(BagDef.BagType.Cangku, cost_items, {})
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
    else--[[if inlay_type == 2 then]]
        item_data.special_info.diagrams_item.tabooword_id = taboo_word_id
    -- elseif inlay_type == 3 then
    --     item_data.special_info.space_ring.tabooword_id = taboo_word_id
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
    -- moon.warn(string.format("req.msg.bags_name = %s", json.pretty_encode(req.msg.bags_name)))
    local ret = Bag.GetBagdata(req.msg.bags_name)
    -- moon.warn(string.format("ret = %s", json.pretty_encode(ret)))
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
    if not req.msg.operate_type
        or not req.msg.src_bag
        or not req.msg.src_pos
        or req.msg.src_pos <= 0
        or not req.msg.dest_bag
        or not req.msg.dest_pos
        or req.msg.dest_pos <= 0 then
        return context.S2C(context.net_id, CmdCode.PBBagOperateItemRspCmd,
            { code = ErrorCode.ParamInvalid, error = "参数错误", uid = context.uid }, req.msg_context.stub_id)
    end

    if context.lock_item_role == 1 then
        return context.S2C(context.net_id, CmdCode.PBBagOperateItemRspCmd,
            { code = ErrorCode.LockItemRole, error = "变更操作被锁定", uid = context.uid }, req.msg_context.stub_id)
    end

    local err_code, change_logs = ErrorCode.ParamInvalid, {}
    if req.msg.operate_type == 1 then
        err_code = Bag.StackItems(req.msg.src_bag, req.msg.src_pos, req.msg.dest_bag, req.msg.dest_pos, change_logs)
    elseif req.msg.operate_type == 2 then
        if not req.msg.split_count
            or req.msg.split_count <= 0 then
            return context.S2C(context.net_id, CmdCode.PBBagOperateItemRspCmd,
                { code = ErrorCode.ParamInvalid, error = "参数错误", uid = context.uid }, req.msg_context.stub_id)
        end
        
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

    local light_convert_cfg = GameCfg.LightConvert[item_id]
    if not light_convert_cfg then
        moon.error(string.format("GetSpecialItemFromCommonItem: no LightConvert config uid %d item_id=%d", context.uid, item_id))
        return ErrorCode.ConfigError
    end

    local convert_config_id = light_convert_cfg.getid
    if not convert_config_id then
        return ErrorCode.ConfigError
    end
    local item_type = ItemDefine.GetItemType(convert_config_id)
    local small_types = ItemDefine.EItemSmallType
    if item_type ~= small_types.MagicItem
        and item_type ~= small_types.HumanDiagrams
        and item_type ~= small_types.GhostDiagrams
        and item_type ~= small_types.SpaceRing
        and item_type ~= small_types.Antique then
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
    elseif op_itemdata.itype == ItemDefine.EItemSmallType.SpaceRing then
        if op_itemdata.special_info and op_itemdata.special_info.space_ring then
            cur_light_cnt = op_itemdata.special_info.space_ring.light_cnt
            cur_tags = op_itemdata.special_info.space_ring.tags
            cur_ability_tag = op_itemdata.special_info.space_ring.ability_tag
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
                moon.error("tag_id not found", tag_id, pool_id)
                return ErrorCode.TagNotExist
            end

            --现有词条去重
            local had_tag = false
            for _, tag in pairs(cur_tags) do
                if tag.tag_id == tag_id then
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
    -- moon.info(string.format("cur_ability_tag:\n%s", json.pretty_encode(cur_ability_tag)))
    if table.size(cur_ability_tag) == 0 then
        for pool_id, pool_weight in pairs(light_cfg.lightpooltype2) do
            local pool_cfg = GameCfg.AllTagPool[pool_id]
            if not pool_cfg then
                moon.error("pool_cfg not found", pool_id)
                return ErrorCode.TagPoolNotExist
            end

            for tag_id, tag_weight in pairs(pool_cfg.all_tag) do
                local tag_cfg = GameCfg.AllTag[tag_id]
                if not tag_cfg then
                    moon.error("tag_id not found", tag_id, pool_id)
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
    -- moon.info(string.format("id_weight:\n%s", json.pretty_encode(id_weight)))
    --local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
    if table.size(id_weight) <= 0 then
        moon.error("id_weight is empty")
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
        moon.error("tag_id not found", new_tag_id)
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
        tag_id = new_tag_id,
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
    elseif op_itemdata.itype == ItemDefine.EItemSmallType.SpaceRing then
        op_itemdata.special_info.space_ring.light_cnt = cur_light_cnt + 1
        if new_tag_id >= AbilityTagIdMin then
            table.insert(op_itemdata.special_info.space_ring.ability_tag, new_tag)
        else
            table.insert(op_itemdata.special_info.space_ring.tags, new_tag)
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

    for _, decompose_item in pairs(req.msg.decompose_items) do
        if decompose_item.item_count <= 0 then
            return context.S2C(context.net_id, CmdCode.PBDecomposeRspCmd, {
                code = ErrorCode.ParamInvalid,
                error = "参数错误",
                uid = req.msg.uid,
                decompose_items = req.msg.decompose_items
                }, req.msg_context.stub_id)
        end
    end

    if context.lock_item_role == 1 then
        return context.S2C(context.net_id, CmdCode.PBDecomposeRspCmd,
            { code = ErrorCode.LockItemRole, error = "变更操作被锁定", uid = context.uid }, req.msg_context.stub_id)
    end

    local function decompose_func()
        local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
        local cost_items = {}
        local add_items, add_coins = {}, {}
        for _, value in pairs(req.msg.decompose_items) do
            -- 获取分解配置
            local decompose_cfg = {}

            if value.config_id >= ItemDefine.Antique.start and value.config_id <= ItemDefine.Antique.End then
                local antique_info = scripts.AntiqueShowcase.GetAntiqueInfo(value.config_id, value.uniqid, value.pos)
                if not antique_info or not antique_info.price then
                    return ErrorCode.ItemNotExist
                end

                -- 古董道具：根据真伪确定出售价格
                if antique_info.is_fake == 1 then
                    -- 赝品古董道具：出售价格为100
                    decompose_cfg[antique_info.price.coin_id] = 100 * value.item_count
                    moon.info(string.format("Bag.PBDecomposeReqCmd antique_info is_fake: uid %d, config_id %d, uniqid %d, pos %d, coin_id %d, coin_count %d", context.uid, value.config_id, value.uniqid, value.pos, antique_info.price.coin_id, 100))
                else
                    -- 真品古董道具：使用鉴定后的价格作为出售价格
                    decompose_cfg[antique_info.price.coin_id] = antique_info.price.coin_count * value.item_count
                    moon.info(string.format("Bag.PBDecomposeReqCmd antique_info: uid %d, config_id %d, uniqid %d, pos %d, coin_id %d, coin_count %d, item_count %d", context.uid, value.config_id, value.uniqid, value.pos, antique_info.price.coin_id, antique_info.price.coin_count, value.item_count))
                end
            elseif value.uniqid == 0 then
                local cfg = GameCfg.Item[value.config_id]
                if not cfg or table.size(cfg.decompose) <= 0 then
                    return ErrorCode.ForbidDecompose
                end
                decompose_cfg = cfg.decompose
            else
                local err_code, cur_durability = Bag.GetUniqItemDurability(BagDef.BagType.Cangku, value.uniqid)
                if err_code ~= ErrorCode.None then
                    return err_code
                end
                local cfg = GameCfg.UniqueItem[value.config_id]
                if not cfg or table.size(cfg.decompose) <= 0 then
                    return ErrorCode.ForbidDecompose
                end
                -- local coef = cur_durability / cfg.durability
                for c_id, c_num in pairs(cfg.decompose) do
                    -- local correct_num = math.floor(c_num * coef)
                    -- if correct_num == 0 then
                    --     decompose_cfg[c_id] = correct_num
                    -- end
                    decompose_cfg[c_id] = c_num
                end
            end

            if table.size(decompose_cfg) <= 0 then
                return ErrorCode.DecomposeNotGet
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

    if context.lock_item_role == 1 then
        return context.S2C(context.net_id, CmdCode.PBBagAddCapacityRspCmd,
            { code = ErrorCode.LockItemRole, error = "变更操作被锁定", uid = context.uid }, req.msg_context.stub_id)
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

    if context.lock_item_role == 1 then
        return context.S2C(context.net_id, CmdCode.PBBagSortOutRspCmd,
            { code = ErrorCode.LockItemRole, error = "变更操作被锁定", uid = context.uid }, req.msg_context.stub_id)
    end

    local err_code = Bag.SortOutNew(req.msg.bag_name)
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
        moon.error("Bag.RandomSucc - rate is invalid", rate)
        return ErrorCode.ParamInvalid, 0
    end

    local succ = math.random(1, 10000) <= rate and 1 or 0
    return ErrorCode.None, succ
end

-- 获取随机元素
function Bag.GetRandomElement(container)
    if not container or #container == 0 then
        moon.error("Bag.GetRandomElement - container is empty")
        return ErrorCode.ParamInvalid
    end

    local randomIndex = math.random(1, #container)
    return ErrorCode.None, container[randomIndex]
end

-- 范围内随机值
function Bag.RandomValue(min, max)
    if max < min then
        moon.error("Bag.RandomValue_ - max is less than min", min, max)
        return ErrorCode.ParamInvalid
    elseif min == max then
        return ErrorCode.None, min
    end

    return ErrorCode.None, math.random(min, max)
end

function Bag.RandomWeightedIndex(weightMap)
    local totalWeight = 0
    for _, weight in pairs(weightMap) do
        if weight < 0 then
            moon.error("Bag.RandomWeightedIndex_ weight is less than 0")
            return ErrorCode.ParamInvalid
        end
        totalWeight = totalWeight + weight
    end

    if totalWeight == 0 then
        moon.error("Bag.RandomWeightedIndex_ totalWeight is 0")
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
    moon.info(string.format("PBAntiqueIdentifyReqCmd - uid = %s, config_id = %d, uniqid = %s, pos = %d",
    tostring(req.msg.uid), req.msg.config_id, tostring(req.msg.uniqid), req.msg.pos))
    local err_code, error, price_probability, rsp_config_id, rsp_uniqid, rsp_pos = scripts.AntiqueShowcase.IdentifyAntique(req.msg.config_id, req.msg.uniqid, req.msg.pos)
    return context.S2C(context.net_id, CmdCode.PBAntiqueIdentifyRspCmd, {
        code = err_code,
        error = error,
        config_id = rsp_config_id or req.msg.config_id,
        uniqid = rsp_uniqid or req.msg.uniqid,
        pos = rsp_pos or req.msg.pos,
        price_change_result = price_probability,
    }, req.msg_context.stub_id)
end

function Bag.PBAntiqueShowReqCmd(req)
    local preset_idx = req.msg.preset_idx or 0
    local err_code, error = scripts.AntiqueShowcase.AntiqueShow(req.msg.config_id, req.msg.uniqid, req.msg.showcase_id, req.msg.showcase_idx, req.msg.operate_type, req.msg.pos, preset_idx)
    return context.S2C(context.net_id, CmdCode.PBAntiqueShowRspCmd, {
        code = err_code,
        error = error,
        config_id = req.msg.config_id,
        uniqid = req.msg.uniqid,
        showcase_id = req.msg.showcase_id,
        showcase_idx = req.msg.showcase_idx,
        operate_type = req.msg.operate_type,
        pos = req.msg.pos,
        preset_idx = preset_idx,
    }, req.msg_context.stub_id)
end

-- 解锁预设页
function Bag.PBAntiquePresetUnlockReqCmd(req)
    moon.info(string.format("PBAntiquePresetUnlockReqCmd - uid=%d, preset_idx=%d", context.uid, req.msg.preset_idx))
    local err_code, error = scripts.AntiqueShowcase.UnlockPreset(req.msg.preset_idx)

    -- 获取解锁后的展示柜数据（含预设列表）
    local showcase_info = scripts.AntiqueShowcase.GetAntiqueShowcaseInfo()
    local showcase_data = showcase_info.antique_showcase_data or {}

    return context.S2C(context.net_id, CmdCode.PBAntiquePresetUnlockRspCmd, {
        code = err_code,
        error = error,
        preset_idx = req.msg.preset_idx,
        antique_showcase_data = showcase_data,
    }, req.msg_context.stub_id)
end

-- 使用预设
function Bag.PBAntiquePresetUseReqCmd(req)
    moon.info(string.format("PBAntiquePresetUseReqCmd - uid=%d, preset_idx=%d", context.uid, req.msg.preset_idx))
    local err_code, error = scripts.AntiqueShowcase.UsePreset(req.msg.preset_idx)

    -- 获取使用后的展示柜数据（含预设列表）
    local showcase_info = scripts.AntiqueShowcase.GetAntiqueShowcaseInfo()
    local showcase_data = showcase_info.antique_showcase_data or {}

    return context.S2C(context.net_id, CmdCode.PBAntiquePresetUseRspCmd, {
        code = err_code,
        error = error,
        preset_idx = req.msg.preset_idx,
        antique_showcase_data = showcase_data,
    }, req.msg_context.stub_id)
end

-- 获取预设信息
function Bag.PBAntiquePresetInfoReqCmd(req)
    -- 获取展示柜数据（含预设列表）
    local showcase_info = scripts.AntiqueShowcase.GetAntiqueShowcaseInfo()
    local showcase_data = showcase_info.antique_showcase_data or {}
    return context.S2C(context.net_id, CmdCode.PBAntiquePresetInfoRspCmd, {
        code = showcase_info.errcode or ErrorCode.None,
        error = showcase_info.error or "",
        antique_showcase_data = showcase_data,
    }, req.msg_context.stub_id)
end

-- 一键卸载预设页所有古董
function Bag.PBAntiquePresetRemoveReqCmd(req)
    moon.info(string.format("PBAntiquePresetRemoveReqCmd - uid=%d, preset_idx=%d", context.uid, req.msg.preset_idx))
    local err_code, error, total_count = scripts.AntiqueShowcase.RemoveAllAntiquesFromPreset(req.msg.preset_idx)

    return context.S2C(context.net_id, CmdCode.PBAntiquePresetRemoveRspCmd, {
        code = err_code,
        error = error,
        preset_idx = req.msg.preset_idx,
        total_count = total_count or 0,
    }, req.msg_context.stub_id)
end

function Bag.PBItemSellNpcReqCmd(req)
    -- 参数验证
    if not req.msg.sell_items
        or table.size(req.msg.sell_items) <= 0 then
        return context.S2C(context.net_id, CmdCode.PBItemSellNpcRspCmd, {
            code = ErrorCode.ParamInvalid,
            error = "无效请求参数",
            uid = req.msg.uid,
        }, req.msg_context.stub_id)
    end
    for pos, item_simple in pairs(req.msg.sell_items) do
        if item_simple.item_count <= 0 then
            return context.S2C(context.net_id, CmdCode.PBItemSellNpcRspCmd, {
                code = ErrorCode.ParamInvalid,
                error = "参数错误",
                uid = req.msg.uid,
                sell_items = req.msg.sell_items
            }, req.msg_context.stub_id)
        end
    end

    if context.lock_item_role == 1 then
        return context.S2C(context.net_id, CmdCode.PBItemSellNpcRspCmd,
            { code = ErrorCode.LockItemRole, error = "变更操作被锁定", uid = context.uid }, req.msg_context.stub_id)
    end

    local cost_items = {}
    local get_items_cfg = {}
    for pos, item_simple in pairs(req.msg.sell_items) do
        if item_simple.uniqid == 0 then
            local item_cfg = GameCfg.Item[item_simple.config_id]
            if item_cfg and table.size(item_cfg.sell_value) > 0 then
                for id, cnt in pairs(item_cfg.sell_value) do
                    if not get_items_cfg[id] then
                        get_items_cfg[id] = cnt * item_simple.item_count
                    else
                        get_items_cfg[id] = get_items_cfg[id] + (cnt * item_simple.item_count)
                    end
                end
            else
                return context.S2C(context.net_id, CmdCode.PBItemSellNpcRspCmd, {
                    code = ErrorCode.ItemNotSell,
                    error = "道具不能出售",
                    uid = req.msg.uid,
                }, req.msg_context.stub_id)
            end
        else
            local err_code, cur_durability = Bag.GetUniqItemDurability(BagDef.BagType.Cangku, item_simple.uniqid)
            if err_code ~= ErrorCode.None then
                return context.S2C(context.net_id, CmdCode.PBItemSellNpcRspCmd, {
                    code = err_code,
                    error = "道具不存在",
                    uid = req.msg.uid,
                }, req.msg_context.stub_id)
            end
            local uniqitem_cfg = GameCfg.UniqueItem[item_simple.config_id]
            if uniqitem_cfg and table.size(uniqitem_cfg.sell_value) > 0 then
                local coef = cur_durability / uniqitem_cfg.durability
                for id, cnt in pairs(uniqitem_cfg.sell_value) do
                    if not get_items_cfg[id] then
                        get_items_cfg[id] = math.floor(cnt * item_simple.item_count * coef)
                    else
                        get_items_cfg[id] = get_items_cfg[id] + math.floor(cnt * item_simple.item_count * coef)
                    end
                end
            else
                return context.S2C(context.net_id, CmdCode.PBItemSellNpcRspCmd, {
                    code = ErrorCode.ItemNotSell,
                    error = "道具不能出售",
                    uid = req.msg.uid,
                }, req.msg_context.stub_id)
            end
        end
        cost_items[pos] = {
            config_id = item_simple.config_id,
            uniqid = item_simple.uniqid,
            item_count = -item_simple.item_count,
        }
    end

    if table.size(cost_items) <= 0 then
        return context.S2C(context.net_id, CmdCode.PBItemSellNpcRspCmd, {
            code = ErrorCode.ConfigError,
            error = "出售配置错误",
            uid = req.msg.uid,
        }, req.msg_context.stub_id)
    end

    if Bag.CheckItemsEnoughPos(BagDef.BagType.Cangku, cost_items) ~= ErrorCode.None then
        return context.S2C(context.net_id, CmdCode.PBItemSellNpcRspCmd, {
            code = ErrorCode.ItemNotEnough,
            error = "道具不足",
            uid = req.msg.uid,
        }, req.msg_context.stub_id)
    end

    local add_items = {}
    local add_coins = {}
    ItemDefine.GetItemsFromCfg(get_items_cfg, 1, false, add_items, add_coins)
    if table.size(add_items) + table.size(add_coins) <= 0 then
        return context.S2C(context.net_id, CmdCode.PBItemSellNpcRspCmd, {
            code = ErrorCode.ConfigError,
            error = "出售配置错误",
            uid = req.msg.uid,
        }, req.msg_context.stub_id)
    end

    if table.size(add_items) > 0 then
        if Bag.CheckEmptyEnough(BagDef.BagType.Cangku, add_items, 0) ~= ErrorCode.None then
            return context.S2C(context.net_id, CmdCode.PBItemSellNpcRspCmd, {
                code = ErrorCode.BagFull,
                error = "背包已满",
                uid = req.msg.uid,
            }, req.msg_context.stub_id)
        end
    end

    local stack_items, unstack_items, deal_coins = {}, {}, {}
    local ok = ItemDefine.GetItemDataFromIdCount(add_items, add_coins, stack_items, unstack_items, deal_coins)
    if not ok then
        return context.S2C(context.net_id, CmdCode.PBItemSellNpcRspCmd, {
            code = ErrorCode.ConfigError,
            error = "出售配置错误",
            uid = req.msg.uid,
        }, req.msg_context.stub_id)
    end

    local change_log = {}
    local err_code = ErrorCode.None
    err_code = Bag.DelItemsPos(BagDef.BagType.Cangku, cost_items, change_log)
    if err_code ~= ErrorCode.None then
        Bag.RollBackWithChange(change_log)
        return context.S2C(context.net_id, CmdCode.PBItemSellNpcRspCmd, {
            code = err_code,
            error = "出售失败",
            uid = req.msg.uid,
        }, req.msg_context.stub_id)
    end

    if table.size(stack_items) + table.size(unstack_items) > 0 then
        err_code = Bag.AddItems(BagDef.BagType.Cangku, stack_items, unstack_items, change_log)
        if err_code ~= ErrorCode.None then
            Bag.RollBackWithChange(change_log)
            return context.S2C(context.net_id, CmdCode.PBItemSellNpcRspCmd, {
                code = err_code,
                error = "出售失败",
                uid = req.msg.uid,
            }, req.msg_context.stub_id)
        end
    end

    if table.size(deal_coins) > 0 then
        err_code = Bag.DealCoins(deal_coins, change_log)
        if err_code ~= ErrorCode.None then
            Bag.RollBackWithChange(change_log)
            return context.S2C(context.net_id, CmdCode.PBItemSellNpcRspCmd, {
                code = err_code,
                error = "出售失败",
                uid = req.msg.uid,
            }, req.msg_context.stub_id)
        end
    end

    -- 数据存储更新
    Bag.SaveAndLog(change_log, ItemDef.ChangeReason.ItemSellNpc)

    return context.S2C(context.net_id, CmdCode.PBItemSellNpcRspCmd, {
        code = ErrorCode.None,
        error = "出售成功",
        uid = req.msg.uid,
    }, req.msg_context.stub_id)
end

return Bag
