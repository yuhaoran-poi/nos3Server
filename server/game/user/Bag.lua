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
    local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
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
        [bagType] = {}
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
                change[bagType][pos] = {
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
                change[bagType][pos] = { now_id = item_cfg.id, old = 0, new = canAdd }
                remaining = remaining - canAdd
                if remaining <= 0 then
                    break
                end
            end
        end

        if remaining <= 0 then
            for pos, change_value in pairs(change[bagType]) do
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
                    change[bagType][pos] = {
                        old = itemdata.common_info.item_count,
                        new = itemdata.common_info.item_count + remaining,
                    }
                 
                    remaining = 0
                else
                    change[bagType][pos] = { old = itemdata.common_info.item_count, new = 0 }
                    remaining = remaining + itemdata.common_info.item_count
                end

                if remaining == 0 then
                    break
                end
            end
        end

        if remaining >= 0 then
            for pos, change_value in pairs(change[bagType]) do
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
        [bagType] = {}
    }

    for pos = 1, baginfo.capacity do
        if not baginfo.items[pos] then
            change[bagType][pos] = { now_id = item_cfg.id, uniqid = uniqid, old = 0, new = 1 }

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

function Bag.StackItems(srcBagType, srcPos, destBagType, destPos)
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

    if srcBagType == destBagType and srcPos == destPos then
        return ErrorCode.StackNotAllowed
    end

    local bagdata = scripts.UserModel.GetBagData()
    if not bagdata then
        return ErrorCode.BagNotExist
    end
    local srcBag = bagdata[srcBagType]
    local destBag = bagdata[destBagType]

    -- 源道具校验
    local srcItem = srcBag.items[srcPos]
    if not srcItem or srcItem.common_info.uniqid ~= 0 or srcItem.special_info ~= nil then
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
    local available_count = item_cfg.stack_count - destItem.common_info.item_count
    if available_count <= 0 then
        return ErrorCode.StackFull
    end

    local move_count = math.min(available_count, srcItem.common_info.item_count)

    -- 处理变更记录
    local change = {}
    change[srcBagType] = {
        [srcPos] = {
            now_id = srcItem.common_info.config_id,
            old = srcItem.common_info.item_count,
            new = srcItem.common_info.item_count - move_count
        }
    }
    if change[destBagType] then
        change[destBagType][destPos] = {
            now_id = destItem.common_info.config_id,
            old = destItem.common_info.item_count,
            new = destItem.common_info.item_count + move_count
        }
    else
        change[destBagType] = {
            [destPos] = {
                now_id = destItem.common_info.config_id,
                old = destItem.common_info.item_count,
                new = destItem.common_info.item_count + move_count
            }
        }
    end

    -- 执行堆叠操作
    destItem.common_info.item_count = destItem.common_info.item_count + move_count
    srcItem.common_info.item_count = srcItem.common_info.item_count - move_count
    -- 清理空堆叠
    if srcItem.common_info.item_count <= 0 then
        srcBag.items[srcPos] = nil
    end

    return ErrorCode.None, change
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
        [bagType] = {}
    }
    change[bagType][pos] = {
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

    if srcBagType == destBagType and srcPos == destPos then
        return ErrorCode.StackNotAllowed
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
    local change = {
        [srcBagType] = {}
    }
    change[srcBagType][srcPos] = {
        now_id = srcItem.common_info.config_id,
        old = srcItem.common_info.item_count,
        new = srcItem.common_info.item_count - splitCount
    }
    if change[destBagType] then
        change[destBagType][destPos] = {
            now_id = srcItem.common_info.config_id,
            old = 0,
            new = splitCount
        }
    else
        change[destBagType] = {
            [destPos] = {
                now_id = srcItem.common_info.config_id,
                old = 0,
                new = splitCount
            }
        }
    end

    srcItem.common_info.item_count = srcItem.common_info.item_count - splitCount
    table.copy(destBag.items[destPos], srcItem)
    destBag.items[destPos].common_info.item_count = splitCount

    return ErrorCode.None, change
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
    local change = {}
    if destItem then
        -- 交换物品
        srcBag.items[srcPos] = destItem
        destBag.items[destPos] = srcItem

        change[srcBagType] = {
            [srcPos] = {
                now_id = destItem.common_info.config_id,
                new = destItem.common_info.item_count
            }
        }
        if destItem.common_info.uniqid ~= 0 then
            change[srcBagType][srcPos].uniqid = destItem.common_info.uniqid
        end

        if change[destBagType] then
            change[destBagType][destPos] = {
                now_id = srcItem.common_info.config_id,
                new = srcItem.common_info.item_count
            }
        else
            change[destBagType] = {
                [destPos] = {
                    now_id = srcItem.common_info.config_id,
                    new = srcItem.common_info.item_count
                }
            }
        end
        if srcItem.common_info.uniqid ~= 0 then
            change[destBagType][destPos].uniqid = srcItem.common_info.uniqid
        end
    else
        -- 移动到空位
        destBag.items[destPos] = srcItem
        srcBag.items[srcPos] = nil

        change[destBagType] = {
            [destPos] = {
                now_id = srcItem.common_info.config_id,
                new = srcItem.common_info.item_count
            }
        }
        if srcItem.common_info.uniqid ~= 0 then
            change[destBagType][destPos].uniqid = srcItem.common_info.uniqid
        end

        if change[srcBagType] then
            change[srcBagType][srcPos] = {
                now_id = 0,
                new = 0
            }
        else
            change[srcBagType] = {
                [srcPos] = {
                    now_id = 0,
                    new = 0
                }
            }
        end
    end

    return ErrorCode.None, change
end

function Bag.AddMagicItem(bagType, itemId, uniqid, maxDurability, light_cnt, tags)
    local errorCode, change, add_pos = Bag.AddUniqItem(bagType, itemId, uniqid)
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

    return ErrorCode.None, change, add_pos
end

function Bag.SaveBagsNow(bagTypes)
    local bagdata = scripts.UserModel.GetBagData()
    if not bagdata then
        return false
    end
    local save_bags = {}
    for _, bagType in pairs(bagTypes) do
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

function Bag.PBBagOperateItemReqCmd(req)
    local err_code, change = ErrorCode.ParamInvalid, nil
    if req.msg.operate_type == 1 then
        err_code, change = Bag.StackItems(req.msg.src_bag, req.msg.src_pos, req.msg.dest_bag, req.msg.dest_pos)
    elseif req.msg.operate_type == 2 then
        err_code, change = Bag.SplitItem(req.msg.src_bag, req.msg.src_pos, req.msg.dest_bag, req.msg.dest_pos)
    elseif req.msg.operate_type == 2 then
        err_code, change = Bag.MoveItem(req.msg.src_bag, req.msg.src_pos, req.msg.dest_bag, req.msg.dest_pos)
    end

    if err_code ~= ErrorCode.None or not change then
        return context.S2C(context.net_id, CmdCode["PBBagOperateItemRspCmd"],
            { code = err_code, error = "执行出错", uid = context.uid }, req.msg_context.stub_id)
    end

    local change_bags = {}
    local res_change_items = {}
    local bagdata = scripts.UserModel.GetBagData()
    for bagtype, change_info in pairs(change) do
        table.insert(change_bags, bagtype)

        local change_bag = bagdata[bagtype]
        res_change_items[bagtype].bag_item_type = change_bag.bag_item_type
        res_change_items[bagtype].capacity = change_bag.capacity
        res_change_items[bagtype].items = {}
        for pos, _ in pairs(change_info) do
            if change_bag.items[pos] then
                res_change_items[bagtype].items[pos] = change_bag.items[pos]
            else
                res_change_items[bagtype].items[pos] = {}
            end
        end
    end

    local success = Bag.SaveBagsNow(change_bags)
    if not success then
        return context.S2C(context.net_id, CmdCode["PBBagOperateItemRspCmd"],
            { code = ErrorCode.BagSaveFailed, error = "保存背包失败", uid = context.uid }, req.msg_context.stub_id)
    end

    return context.S2C(context.net_id, CmdCode["PBBagOperateItemRspCmd"],
        { code = ErrorCode.None, error = "", uid = context.uid, change_items = res_change_items },
        req.msg_context.stub_id)
end

return Bag