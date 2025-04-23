local moon = require "moon"
local common = require "common"
local GameCfg = common.GameCfg
local ErrorCode = common.ErrorCode
local CmdCode = common.CmdCode

---@type user_context
local context = ...
local scripts = context.scripts

local BagType = {
    Cangku = 1,
    Consume = 2,
    Booty = 3,
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
    local data = scripts.UserModel.Get()
    if not data or not data.bagData then
        data.bagData = {
            bags = {
                [BagType.Cangku] = {
                    item_type = ItemType.ALL,
                    capacity = init_cangku_capacity,
                    items = {} -- map
                },
                [BagType.Consume] = {
                    item_type = ItemType.Consume,
                    capacity = init_consume_capacity,
                    items = {} -- map
                },
                [BagType.Booty] = {
                    item_type = ItemType.ALL,
                    capacity = init_booty_capacity,
                    items = {} -- map
                },
            },
        }
    end
end

function Bag.Start()
    -- body
end

-- 添加物品（支持自动堆叠）
function Bag.AddItem(bagType, itemId, count)
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

    local baginfo = scripts.UserModel.MutGet().bagData.bags[bagType]
    -- 类型检查
    local item_type = scripts.ItemDefine.GetItemType(itemId)
    if baginfo.item_type ~= ItemType.ALL and baginfo.item_type ~= item_type then
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
        for pos, item in pairs(baginfo.items) do
            if item.id == itemId and item.count < item_cfg.stack_count then
                local canAdd = math.min(item_cfg.stack_count - item.count, remaining)
                change.items[pos] = { now_id = itemId, old = item.count, new = item.count + canAdd }
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
                if not baginfo.items[pos] or baginfo.items[pos].count == 0 then
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
                baginfo.items[pos] = { id = change_value.now_id, count = change_value.new }
            end
        else
            return ErrorCode.BagFull
        end
    else
        local remaining = count

        -- 先尝试扣减
        for pos, item in pairs(baginfo.items) do
            if item.id == itemId then
                if item.count + remaining > 0 then
                    change.items[pos] = { old = item.count, new = item.count + remaining }
                    remaining = 0
                else
                    change.items[pos] = { old = item.count, new = 0 }
                    remaining = remaining + item.count
                end

                if remaining == 0 then
                    break
                end
            end
        end

        if remaining >= 0 then
            for pos, change_value in pairs(change.items) do
                baginfo.items[pos].count = change_value.new
                if baginfo.items[pos].count == 0 then
                    baginfo.items[pos] = nil
                end
            end
        else
            return ErrorCode.BagNotEnough
        end
    end

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

    local baginfos = scripts.UserModel.MutGet().bagData
    local srcBag = baginfos.bags[srcBagType]
    local destBag = baginfos.bags[destBagType]

    -- 源物品校验
    local srcItem = srcBag.items[srcPos]
    if not srcItem or srcItem.count <= 1 then
        return ErrorCode.SplitNotAllowed
    end

    if splitCount >= srcItem.count then
        return ErrorCode.SplitCountInvalid
    end

    -- 检查目标位置是否被占用
    if destBag.items[destPos] then
        return ErrorCode.MoveTargetOccupied
    end

    -- 跨背包类型校验
    local itemType = scripts.ItemDefine.GetItemType(srcItem.id)
    if destBag.item_type ~= ItemType.ALL and destBag.item_type ~= itemType then
        return ErrorCode.BagTypeMismatch
    end

    -- 执行拆分操作
    local changes = {}

    local srcChange = {
        bagType = srcBagType,
        items = {}
    }
    srcChange.items[srcPos] = {
        id = srcItem.id,
        old = srcItem.count,
        new = srcItem.count - splitCount
    }
    table.insert(changes, srcChange)
    srcItem.count = srcItem.count - splitCount

    local destChange = {
        bagType = destBagType,
        items = {}
    }
    destChange.items[destPos] = {
        id = srcItem.id,
        old = 0,
        new = splitCount
    }
    table.insert(changes, destChange)
    destBag.items[destPos] = {
        id = srcItem.id,
        count = splitCount
    }

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
    local baginfos = scripts.UserModel.MutGet().bagData
    local srcBag = baginfos.bags[srcBagType]
    local destBag = baginfos.bags[destBagType]

    -- 源物品校验
    local srcItem = srcBag.items[srcPos]
    if not srcItem then
        return ErrorCode.ItemNotExist
    end

    -- 目标背包类型校验
    local itemType = scripts.ItemDefine.GetItemType(srcItem.id)
    if destBag.item_type ~= ItemType.ALL and destBag.item_type ~= itemType then
        return ErrorCode.BagTypeMismatch
    end

    local destItem = destBag.items[destPos]
    if destItem then
        -- 目标位置有物品，检查是否可以交换
        local destItemType = scripts.ItemDefine.GetItemType(destItem.id)
        if srcBag.item_type ~= ItemType.ALL and srcBag.item_type ~= destItemType then
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
            id = destItem.id,
            new = destItem.count
        }
        table.insert(changes, srcChange)
        local destChange = {
            bagType = destBagType,
            items = {}
        }
        destChange.items[destPos] = {
            id = srcItem.id,
            new = srcItem.count
        }
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
            id = srcItem.id,
            new = srcItem.count
        }
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

return Bag