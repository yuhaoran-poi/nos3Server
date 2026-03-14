local moon = require "moon"
local common = require "common"
local protocol = require("common.protocol_pb")
local clusterd = require("cluster")
local GameCfg = common.GameCfg
local ErrorCode = common.ErrorCode
local CmdCode = common.CmdCode
local Database = common.Database
-- local ProtoEnum = require("tools.ProtoEnum")
-- local NewBagDef = require("common.def.NewBagDef")
-- local BagDef = require("common.def.BagDef")
-- local ItemDef = require("common.def.ItemDef")
-- local ItemDefine = require("common.logic.ItemDefine")

---@type user_context
local context = ...
local scripts = context.scripts

---@class NewBag
local NewBag = {}

function NewBag.Init()
    --加载全部角色数据
end

function NewBag.Start(isnew)
    local width = 10
    local height = 10
    if isnew then
        NewBag.max_width = width
        NewBag.max_height = height
        NewBag.cells = {}
        for y = 1, NewBag.max_height do
            NewBag.cells[y] = {}
            for x = 1, NewBag.max_width do
                NewBag.cells[y][x] = 0
            end
        end
        NewBag.empty_cells_num = NewBag.max_width * NewBag.max_height
        NewBag.items = {} -- map: item_id -> item
    end
end

function NewBag.can_place(locate, x, y)
    if not locate or not locate.width or not locate.height then
        return false
    end
    if locate.width > NewBag.max_width or locate.height > NewBag.max_height then
        return false
    end
    if locate.width * locate.height > NewBag.empty_cells_num then
        return false
    end

    local find_empty = function(target_x, target_y)
        for height = target_y, target_y + locate.height - 1, 1 do
            for width = target_x, target_x + locate.width - 1, 1 do
                if NewBag.cells[height][width] ~= 0 then
                    return false, width
                end
            end
        end

        return true, target_x
    end

    if x and y and x > 0 and y > 0 then
        if NewBag.cells[y][x] ~= 0 then
            return false
        end
        local success, used_width = find_empty(x, y)
        if not success then
            return false
        end

        return true, x, y
    else
        for cur_y = 1, NewBag.max_height, 1 do
            local success, used_x = false, 0
            for cur_x = 1, NewBag.max_width, 1 do
                if used_x >= NewBag.max_width then
                    break
                end

                if cur_x > used_x and NewBag.cells[cur_y][cur_x] == 0 then
                    success, used_x = find_empty(cur_x, cur_y)
                    if success then
                        return true, cur_x, cur_y
                    end
                end
            end
        end
        return false
    end
end

function NewBag.add_item(item_id, item_width, item_height)
    if not item_id or item_id <= 0 then
        return false
    end

    local locate = {
        width = item_width,
        height = item_height,
    }
    local success, use_x, use_y = NewBag.can_place(locate)
    if not success then
        return false
    end

    local item_locate = {
        x = use_x,
        y = use_y,
        width = locate.width,
        height = locate.height,
    }
    NewBag.items[item_id] = item_locate
    NewBag.empty_cells_num = NewBag.empty_cells_num - locate.width * locate.height
    for height = item_locate.y, item_locate.y + item_locate.height - 1, 1 do
        for width = item_locate.x, item_locate.x + item_locate.width - 1, 1 do
            NewBag.cells[height][width] = item_id
        end
    end
    
    return true
end

function NewBag.remove(item_id)
    if not item_id or item_id <= 0 then
        return false
    end

    local locate = NewBag.items[item_id]
    if not locate or not locate.x or not locate.y
        or locate.x <= 0 or locate.y <= 0
        or locate.width <= 0 or locate.height <= 0 then
        return false
    end

    for height = locate.y, locate.y + locate.height - 1, 1 do
        for width = locate.x, locate.x + locate.width - 1, 1 do
            NewBag.cells[height][width] = 0
        end
    end
    NewBag.empty_cells_num = NewBag.empty_cells_num + locate.width * locate.height
    NewBag.items[item_id] = nil

    return true
end

function NewBag.move(src_item_id, dest_locate, replace_item_id, replace_locate)
    if not src_item_id or not dest_locate or not dest_locate.x or not dest_locate.y
        or dest_locate.x <= 0 or dest_locate.y <= 0 then
        return false
    end
    if not NewBag.items[src_item_id] then
        return false
    end

    if replace_item_id then
        if not replace_locate or not replace_locate.x or not replace_locate.y
            or replace_locate.x <= 0 or replace_locate.y <= 0 then
            return false
        end
        if not NewBag.items[replace_item_id] then
            return false
        end
    end

    -- 先记录当前的背包数据
    local old_cells = table.copy(NewBag.cells)
    local old_empty_cells_num = NewBag.empty_cells_num
    local old_items = table.copy(NewBag.items)
    if not old_cells or not old_empty_cells_num or not old_items then
        return false
    end

    -- 先删除原位置的物品
    if not NewBag.remove(src_item_id) then
        return false
    end
    if replace_item_id then
        if not NewBag.remove(replace_item_id) then
            NewBag.cells = old_cells
            NewBag.empty_cells_num = old_empty_cells_num
            NewBag.items = old_items
            return false
        end
    end

    -- 添加新位置物品
    local src_item = old_items[src_item_id]
    local move_locate = {
        width = src_item.width,
        height = src_item.height,
    }
    local success, use_x, use_y = NewBag.can_place(move_locate, dest_locate.x, dest_locate.y)
    if not success then
        NewBag.cells = old_cells
        NewBag.empty_cells_num = old_empty_cells_num
        NewBag.items = old_items
        return false
    end
    local src_item_locate = {
        x = use_x,
        y = use_y,
        width = move_locate.width,
        height = move_locate.height,
    }
    NewBag.items[src_item_id] = src_item_locate
    NewBag.empty_cells_num = NewBag.empty_cells_num - move_locate.width * move_locate.height
    for height = src_item_locate.y, src_item_locate.y + src_item_locate.height - 1, 1 do
        for width = src_item_locate.x, src_item_locate.x + src_item_locate.width - 1, 1 do
            NewBag.cells[height][width] = src_item_id
        end
    end

    if replace_item_id then
        local replace_item = old_items[replace_item_id]
        move_locate = {
            width = replace_item.width,
            height = replace_item.height,
        }
        success, use_x, use_y = NewBag.can_place(move_locate, replace_locate.x, replace_locate.y)
        if not success then
            NewBag.cells = old_cells
            NewBag.empty_cells_num = old_empty_cells_num
            NewBag.items = old_items
            return false
        end
        local replace_item_locate = {
            x = use_x,
            y = use_y,
            width = move_locate.width,
            height = move_locate.height,
        }
        NewBag.items[replace_item_id] = replace_item_locate
        NewBag.empty_cells_num = NewBag.empty_cells_num - move_locate.width * move_locate.height
        for height = replace_item_locate.y, replace_item_locate.y + replace_item_locate.height - 1, 1 do
            for width = replace_item_locate.x, replace_item_locate.x + replace_item_locate.width - 1, 1 do
                NewBag.cells[height][width] = replace_item_id
            end
        end
    end

    return true
end

return NewBag