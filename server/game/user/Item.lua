local moon = require "moon"
local common = require "common"
local GameCfg = common.GameCfg
local ErrorCode = common.ErrorCode
local CmdCode = common.CmdCode

---@type user_context
local context = ...
local scripts = context.scripts

---@class Item
local Item = {}

function Item.Init()
    
end

function Item.Start()
    local data = scripts.UserModel.Get()
    if not data.itemlist then
        data.itemlist = {}
    end
end

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

return Item