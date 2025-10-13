local moon = require "moon"
local common = require "common"
local protocol = require("common.protocol_pb")
local clusterd = require("cluster")
local GameCfg = common.GameCfg
local ErrorCode = common.ErrorCode
local CmdCode = common.CmdCode
local ItemDefine = require("common.logic.ItemDefine")

---@type user_context
local context = ...
local scripts = context.scripts

---@class Item
local Item = {}

function Item.Init()

end

function Item.Start()
    
end

-- 随机词条id
function Item.RangeTags(tag_pool)
    local total_weight = 0
    for id, weight in pairs(tag_pool) do
        total_weight = total_weight + weight
    end

    local rand = math.random(total_weight)
    for id, weight in pairs(tag_pool) do
        rand = rand - weight
        if rand <= 0 then
            return id
        end
    end

    return 0
end

-- 比较两个itemdata是否相等
function Item.UniqItemEqual(itemdata1, itemdata2)
    if not itemdata1 or not itemdata2 then
        return false
    end
    if not itemdata1.common_info or not itemdata2.common_info then
        return false
    end
    if itemdata1.common_info.item_type ~= itemdata2.common_info.item_type then
        return false
    end
    if itemdata1.common_info.config_id ~= itemdata2.common_info.config_id
        or itemdata1.common_info.uniqid == 0
        or itemdata1.common_info.uniqid ~= itemdata2.common_info.uniqid then
        return false
    end
    if itemdata1.common_info.item_count ~= itemdata2.common_info.item_count then
        return false
    end
    if itemdata1.common_info.trade_cnt ~= itemdata2.common_info.trade_cnt then
        return false
    end

    local _, pbdata1 = protocol.encodewithname("PBItemData", itemdata1)
    local _, pbdata2 = protocol.encodewithname("PBItemData", itemdata2)

    return pbdata1 == pbdata2
end
-- function Item.UniqItemEqual(itemdata1, itemdata2)
--     if not itemdata1 or not itemdata2 then
--         return false
--     end
--     if not itemdata1.common_info or not itemdata2.common_info then
--         return false
--     end
--     if not itemdata1.special_info or not itemdata2.special_info then
--         return false
--     end
--     if itemdata1.common_info.config_id ~= itemdata2.common_info.config_id
--         or itemdata1.common_info.uniqid == 0
--         or itemdata1.common_info.uniqid ~= itemdata2.common_info.uniqid then
--         return false
--     end
--     if itemdata1.common_info.trade_cnt ~= itemdata2.common_info.trade_cnt then
--         return false
--     end
--     if itemdata1.special_info.durab_item and table.size(itemdata1.special_info.durab_item) > 0 then
--         if not itemdata2.special_info.durab_item or table.size(itemdata2.special_info.durab_item) <= 0 then
--             return false
--         end
--         if itemdata1.special_info.durab_item.cur_durability ~= itemdata2.special_info.durab_item.cur_durability then
--             return false
--         end
--         if itemdata1.special_info.durab_item.strong_value ~= itemdata2.special_info.durab_item.strong_value then
--             return false
--         end
--     end
--     if itemdata1.special_info.magic_item and table.size(itemdata1.special_info.magic_item) > 0 then
--         if not itemdata2.special_info.magic_item or table.size(itemdata2.special_info.magic_item) <= 0 then
--             return false
--         end
--         if itemdata1.special_info.magic_item.cur_durability ~= itemdata2.special_info.magic_item.cur_durability then
--             return false
--         end
--         if itemdata1.special_info.magic_item.strong_value ~= itemdata2.special_info.magic_item.strong_value then
--             return false
--         end
--         if itemdata1.special_info.magic_item.tabooword_id ~= itemdata2.special_info.magic_item.tabooword_id then
--             return false
--         end
--         if itemdata1.special_info.magic_item.light_cnt ~= itemdata2.special_info.magic_item.light_cnt then
--             return false
--         end

--     end

--     return true
-- end

function Item.SendLog(write_log_datas)
    --存储日志
    clusterd.send(3003, "logmgr", "LogMgr.ItemChangeLog", write_log_datas)
end

return Item