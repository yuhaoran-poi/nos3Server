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

-- 添加物品（支持自动堆叠）
function Bag.AddItem(bagType, itemId, count)
    -- 参数校验
    if count == 0 then
        return ErrorCode.ParamInvalid
    end

    if bagType ~= BagType.Cangku and bagType ~= BagType.Consume and BagType.Booty then
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
    local changes = {}
    if count > 0 then
        -- 添加逻辑
        local remaining = count

        -- 先尝试堆叠
        for pos, item in pairs(baginfo.items) do
            if item.id == itemId and item.count < item_cfg.stack_count then
                local canAdd = math.min(item_cfg.stack_count - item.count, remaining)
                changes[pos] = { old = item.count, new = item.count + canAdd }
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
                changes[pos] = { now_id = item_cfg.id, old = 0, new = canAdd }
                remaining = remaining - canAdd
                if remaining <= 0 then
                    break
                end
            end
        end

        if remaining <= 0 then
            for pos, change_value in pairs(changes) do
                if change_value.now_id then
                    baginfo.items[pos] = { id = change_value.now_id, count = change_value.new }
                else
                    baginfo.items[pos].count = change_value.new
                end
            end
        end
    else
        local remaining = count

        -- 先尝试扣减
        for pos, item in pairs(baginfo.items) do
            if item.id == itemId then
                if item.count + remaining > 0 then
                    changes[pos] = { old = item.count, new = item.count + remaining }
                    remaining = 0
                else
                    changes[pos] = { old = item.count, new = 0 }
                    remaining = remaining + item.count
                end

                if remaining == 0 then
                    break
                end
            end
        end

        if remaining >= 0 then
            for pos, change_value in pairs(changes) do
                baginfo.items[pos].count = change_value.new
            end
        end

        -- ... 减少逻辑需要先计算总数量 ...
        if total < required then
            return ErrorCode.BagNotEnough
        end
    end

    return ErrorCode.None
end

function Bag.Start()
    -- body
end

--检查物品数量是否足够
function Bag.Check(id, count)
    if count <=0 then
        return ErrorCode.ParamInvalid
    end
    local DB = scripts.UserModel.Get()
    local item = DB.itemlist[id]
    if not item or item.count < count  then
        return ErrorCode.BagNotEnough
    end
    return 0
end


function Bag.Cost(id, count, trace, send_list)
    if count <=0 then
        return ErrorCode.ParamInvalid
    end

    local DB = scripts.UserModel.MutGet()

    local item = DB.itemlist[id]

    if not item or item.count < count  then
        return ErrorCode.BagNotEnough
    end
    item.count = item.count - count

    if not send_list then
        --context.S2C(CmdCode.S2CUpdateBag,{list={item}})
    else
        table.insert(send_list, item)
    end
end

function Bag.Costlist(list, trace)
    local DB = scripts.UserModel.MutGet()
    for _, v in ipairs(list) do
        local item = DB.itemlist[v[1]]
        if not item or item.count < v[2]  then
            return ErrorCode.BagNotEnough
        end
    end

    local send_list = {}
    for _, v in ipairs(list) do
        Bag.Cost(v[1], v[2], trace, send_list)
    end
    context.S2C(CmdCode.S2CUpdateBag,{list= send_list})
end

function Bag.AddBagList(list, trace)
    local send_list = {}
    for _,v in ipairs(list) do
        Bag.AddBag(v.id, v.count, trace, send_list)
    end
    if #send_list > 0 then
        context.S2C(CmdCode.S2CUpdateBag,{list=send_list})
    end
end

function Bag.AddBag(id, count, trace, send_list)
    print("AddBag", id, count, trace)

    local cfg = GameCfg.item[id]
    if not cfg then
        moon.error("item not exist", id)
        return ErrorCode.BagNotExist
    end

    local DB = scripts.UserModel.MutGet()

    local item = DB.itemlist[id]
    if not item then
        item = {count = 0}
        DB.itemlist[id] = item
    end
    item.id = id
    item.count = item.count + count

    if not send_list then
        --context.S2C(CmdCode.S2CUpdateBag,{list={item}})
    else
        table.insert(send_list, item)
    end
    return ErrorCode.None
end

function Bag.C2SBagList()
    context.S2C(CmdCode.S2CBagList, {list = scripts.UserModel.Get().itemlist})
end

---@param req C2SUseBag
function Bag.C2SUseBag(req)
    local cfg = GameCfg.item[req.id]
    if not cfg then
        return ErrorCode.BagNotExist
    end
end

return Bag