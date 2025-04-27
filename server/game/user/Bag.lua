local moon = require "moon"
local common = require "common"
local uuid = require "uuid"
local GameCfg = common.GameCfg
local ErrorCode = common.ErrorCode
local CmdCode = common.CmdCode
local Database = common.Database

---@type user_context
local context = ...
local scripts = context.scripts

local BagType = {
    Cangku = "cangku",
    Consume = "consume",
    Booty = "booty",
}

local ItemType = {
    ALL = 1,
    Consume = 2,
}

local init_cangku_capacity = 75
local init_consume_capacity = 25
local init_booty_capacity = 20

---@class Bag
local Bag = {}

function Bag.Init()
    local bagTypes = {}
    table.insert(bagTypes, BagType.Cangku)
    table.insert(bagTypes, BagType.Consume)
    table.insert(bagTypes, BagType.Booty)
    local baginfos = Bag.LoadBags(bagTypes)
    if baginfos then
        scripts.UserModel.SetBagData(baginfos)
    end

    local bagdata = scripts.UserModel.GetBagData()
    if not bagdata then
        bagdata = {
            [BagType.Cangku] = {
                bag_item_type = ItemType.ALL,
                capacity = init_cangku_capacity,
                items = {}     -- map
            },
            [BagType.Consume] = {
                bag_item_type = ItemType.Consume,
                capacity = init_consume_capacity,
                items = {}     -- map
            },
            [BagType.Booty] = {
                bag_item_type = ItemType.ALL,
                capacity = init_booty_capacity,
                items = {}     -- map
            },
        }

        scripts.UserModel.SetBagData(bagdata)
        Bag.SaveBagsNow(bagTypes)
    end
end

function Bag.Start()
    -- body
end

-- 添加物品（支持自动堆叠）
function Bag.AddItem(bagType, itemId, count, itype)
    -- 参数校验
    if count == 0 then
        return ErrorCode.ParamInvalid
    end

    if bagType ~= BagType.Cangku and bagType ~= BagType.Consume and bagType ~= BagType.Booty then
        return ErrorCode.BagNotExist
    end

    local item_cfg = GameCfg.Item[itemId]
    if not item_cfg then
        return ErrorCode.ItemNotExist
    end

    local bagdata = scripts.UserModel.GetBagData()
    if not bagdata then
        return ErrorCode.BagNotExist
    end
    local baginfo = bagdata[bagType]
    -- 类型检查
    local item_type = scripts.ItemDefine.GetItemType(itemId)
    if baginfo.bag_item_type ~= ItemType.ALL and baginfo.bag_item_type ~= item_type then
        return ErrorCode.BagTypeMismatch
    end

    -- 处理物品增减
    local change = {
        bagType = bagType,
        items = {}
    }
    if count > 0 then
        -- 添加逻辑
        local remaining = count

        -- 先尝试堆叠
        for pos, itemdata in pairs(baginfo.items) do
            if itemdata.itype == itype
                and itemdata.common_info.config_id == itemId
                and itemdata.common_info.uniqid == 0
                and itemdata.common_info.item_count < item_cfg.stack_count then
                local canAdd = math.min(item_cfg.stack_count - itemdata.common_info.item_count, remaining)
                change.items[pos] = {
                    now_id = itemId,
                    old = itemdata.common_info.item_count,
                    new = itemdata.common_info.item_count + canAdd
                }
                remaining = remaining - canAdd
                if remaining == 0 then
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
                change.items[pos] = { now_id = item_cfg.id, old = 0, new = canAdd }
                remaining = remaining - canAdd
                if remaining <= 0 then
                    break
                end
            end
        end

        if remaining <= 0 then
            for pos, change_value in pairs(change.items) do
                if change_value.old == 0 then
                    baginfo.items[pos] = {
                        itype = itype,
                        common_info = {
                            config_id = item_cfg.id,
                            uniqid = 0,
                            item_count = change_value.new,
                            item_type = item_cfg.type1,
                            trade_cnt = -1,
                        },
                        special_info = {},
                    }
                else
                    baginfo.items[pos].common_info.item_count = change_value.new
                end
            end
        else
            return ErrorCode.BagFull
        end
    else
        local remaining = count

        -- 先尝试扣减
        for pos, itemdata in pairs(baginfo.items) do
            if itemdata.common_info.item_count == itemId
                and itemdata.common_info.uniqid == 0 then

                if itemdata.common_info.item_count + remaining > 0 then
                    change.items[pos] = {
                        old = itemdata.common_info.item_count,
                        new = itemdata.common_info.item_count + remaining,
                    }
                 
                    remaining = 0
                else
                    change.items[pos] = { old = itemdata.common_info.item_count, new = 0 }
                    remaining = remaining + itemdata.common_info.item_count
                end

                if remaining == 0 then
                    break
                end
            end
        end

        if remaining >= 0 then
            for pos, change_value in pairs(change.items) do
                baginfo.items[pos].common_info.item_count = change_value.new
                if baginfo.items[pos].common_info.item_count == 0 then
                    baginfo.items[pos] = nil
                end
            end
        else
            return ErrorCode.BagNotEnough
        end
    end

    return ErrorCode.None, change
end

function Bag.AddUniqItem(bagType, itemId, uniqid)
    -- 参数校验
    if bagType ~= BagType.Cangku
        and bagType ~= BagType.Consume
        and bagType ~= BagType.Booty then
        return ErrorCode.BagNotExist
    end

    local item_cfg = GameCfg.UniqueItem[itemId]
    if not item_cfg then
        return ErrorCode.ItemNotExist
    end

    local bagdata = scripts.UserModel.GetBagData()
    if not bagdata then
        return ErrorCode.BagNotExist
    end
    local baginfo = bagdata[bagType]
    -- 类型检查
    local item_type = scripts.ItemDefine.GetItemType(itemId)
    if baginfo.bag_item_type ~= ItemType.ALL and baginfo.bag_item_type ~= item_type then
        return ErrorCode.BagTypeMismatch
    end

    -- 处理物品记录
    local change = {
        bagType = bagType,
        items = {}
    }

    for pos = 1, baginfo.capacity do
        if not baginfo.items[pos] then
            change.items[pos] = { now_id = item_cfg.id, uniqid = uniqid, old = 0, new = 1 }

            baginfo.items[pos] = {
                itype = item_cfg.type1,
                common_info = {
                    config_id = item_cfg.id,
                    uniqid = uniqid,
                    item_count = 1,
                    item_type = item_cfg.type1,
                    trade_cnt = -1,
                },
                special_info = {},
            }

            return ErrorCode.None, change, pos
        end
    end

    return ErrorCode.BagFull
end

function Bag.DelUniqItem(bagType, itemId, uniqid, pos)
    -- 参数校验
    if bagType ~= BagType.Cangku
        and bagType ~= BagType.Consume
        and bagType ~= BagType.Booty then
        return ErrorCode.BagNotExist
    end

    local bagdata = scripts.UserModel.GetBagData()
    if not bagdata then
        return ErrorCode.BagNotExist
    end
    local baginfo = bagdata[bagType]
    if not baginfo.items[pos] then
        return ErrorCode.ItemNotExist
    end
    if baginfo.items[pos].common_info.config_id ~= itemId
        or baginfo.items[pos].common_info.uniqid ~= uniqid then
        return ErrorCode.ItemNotExist
    end

    -- 处理物品记录
    local change = {
        bagType = bagType,
        items = {}
    }
    change.items[pos] = {
        now_id = baginfo.items[pos].common_info.config_id,
        uniqid = baginfo.items[pos].common_info.uniqid,
        old = 1,
        new = 0
    }
    baginfo.items[pos] = nil
    return ErrorCode.None, change
end

function Bag.SplitItem(srcBagType, srcPos, destBagType, destPos, splitCount)
    -- 参数校验
    if splitCount <= 0 then
        return ErrorCode.ParamInvalid
    end

    if srcBagType ~= BagType.Cangku
        and srcBagType ~= BagType.Consume
        and srcBagType ~= BagType.Booty then
        return ErrorCode.BagNotExist
    end

    if destBagType ~= BagType.Cangku
        and destBagType ~= BagType.Consume
        and destBagType ~= BagType.Booty then
        return ErrorCode.BagNotExist
    end

    local bagdata = scripts.UserModel.GetBagData()
    if not bagdata then
        return ErrorCode.BagNotExist
    end
    local srcBag = bagdata[srcBagType]
    local destBag = bagdata[destBagType]

    -- 源物品校验
    local srcItem = srcBag.items[srcPos]
    if not srcItem
        or srcItem.common_info.uniqid ~= 0
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
    local itemType = scripts.ItemDefine.GetItemType(srcItem.common_info.config_id)
    if destBag.bag_item_type ~= ItemType.ALL and destBag.bag_item_type ~= itemType then
        return ErrorCode.BagTypeMismatch
    end

    -- 执行拆分操作
    local changes = {}

    local srcChange = {
        bagType = srcBagType,
        items = {}
    }
    srcChange.items[srcPos] = {
        now_id = srcItem.common_info.config_id,
        old = srcItem.common_info.item_count,
        new = srcItem.common_info.item_count - splitCount
    }
    table.insert(changes, srcChange)
    srcItem.common_info.item_count = srcItem.common_info.item_count - splitCount

    local destChange = {
        bagType = destBagType,
        items = {}
    }
    destChange.items[destPos] = {
        now_id = srcItem.common_info.config_id,
        old = 0,
        new = splitCount
    }
    table.insert(changes, destChange)
    table.copy(destBag.items[destPos], srcItem)
    destBag.items[destPos].common_info.item_count = splitCount

    return ErrorCode.None, changes
end

function Bag.MoveItem(srcBagType, srcPos, destBagType, destPos)
    -- 参数校验
    if srcBagType ~= BagType.Cangku
        and srcBagType ~= BagType.Consume
        and srcBagType ~= BagType.Booty then
        return ErrorCode.BagNotExist
    end

    if destBagType ~= BagType.Cangku
        and destBagType ~= BagType.Consume
        and destBagType ~= BagType.Booty then
        return ErrorCode.BagNotExist
    end

    -- 获取数据副本
    local bagdata = scripts.UserModel.GetBagData()
    if not bagdata then
        return ErrorCode.BagNotExist
    end
    local srcBag = bagdata[srcBagType]
    local destBag = bagdata[destBagType]

    -- 源物品校验
    local srcItem = srcBag.items[srcPos]
    if not srcItem then
        return ErrorCode.ItemNotExist
    end

    -- 目标背包类型校验
    local itemType = scripts.ItemDefine.GetItemType(srcItem.common_info.config_id)
    if destBag.bag_item_type ~= ItemType.ALL and destBag.bag_item_type ~= itemType then
        return ErrorCode.BagTypeMismatch
    end

    local destItem = destBag.items[destPos]
    if destItem then
        -- 目标位置有物品，检查是否可以交换
        local destItemType = scripts.ItemDefine.GetItemType(destItem.common_info.config_id)
        if srcBag.bag_item_type ~= ItemType.ALL and srcBag.bag_item_type ~= destItemType then
            return ErrorCode.BagTypeMismatch
        end
    end

    -- 执行移动
    local changes = {}
    if destItem then
        -- 交换物品
        srcBag.items[srcPos] = destItem
        destBag.items[destPos] = srcItem

        local srcChange = {
            bagType = srcBagType,
            items = {}
        }
        srcChange.items[srcPos] = {
            now_id = destItem.common_info.config_id,
            new = destItem.common_info.item_count
        }
        if destItem.common_info.uniqid ~= 0 then
            srcChange.items[srcPos].uniqid = destItem.common_info.uniqid
        end
        table.insert(changes, srcChange)
        local destChange = {
            bagType = destBagType,
            items = {}
        }
        destChange.items[destPos] = {
            now_id = srcItem.common_info.config_id,
            new = srcItem.common_info.item_count
        }
        if srcItem.common_info.uniqid ~= 0 then
            destChange.items[destPos].uniqid = srcItem.common_info.uniqid
        end
        table.insert(changes, destChange)
    else
        -- 移动到空位
        destBag.items[destPos] = srcItem
        srcBag.items[srcPos] = nil

        local destChange = {
            bagType = destBagType,
            items = {}
        }
        destChange.items[destPos] = {
            id = srcItem.common_info.config_id,
            new = srcItem.common_info.item_count
        }
        if srcItem.common_info.uniqid ~= 0 then
            destChange.items[destPos].uniqid = srcItem.common_info.uniqid
        end
        table.insert(changes, destChange)

        local srcChange = {
            bagType = srcBagType,
            items = {}
        }
        srcChange.items[srcPos] = {
            id = 0,
            new = 0
        }
        table.insert(changes, srcChange)
    end

    return ErrorCode.None, changes
end

function Bag.AddMagicItem(bagType, itemId, uniqid, maxDurability, light_cnt, tags)
    local errorCode, changes, add_pos = Bag.AddUniqItem(bagType, itemId, uniqid)
    if errorCode ~= ErrorCode.None then
        return errorCode
    end

    local bagdata = scripts.UserModel.GetBagData()
    if not bagdata then
        return ErrorCode.BagNotExist
    end
    local baginfo = bagdata[bagType]
    baginfo.items[add_pos].special_info = {
        magic_item = {
            max_durability = maxDurability,
            cur_durability = maxDurability,
            light_cnt = light_cnt,
            tags = tags,
        }
    }

    return ErrorCode.None, changes, add_pos
end

function Bag.SaveBagsNow(bagTypes)
    local bagdata = scripts.UserModel.GetBagData()
    if not bagdata then
        return false
    end
    local save_bags = {}
    for bagType, _ in pairs(bagTypes) do
        if bagdata[bagType] then
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

return Bag