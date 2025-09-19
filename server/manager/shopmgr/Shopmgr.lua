local moon = require("moon")
local datetime = require("moon.datetime")
local socket = require("moon.socket")
local common = require("common")
local CmdCode = common.CmdCode
local GameCfg = common.GameCfg --游戏配置
local Database = common.Database
local ErrorCode = common.ErrorCode
local lock = require("moon.queue")()
local httpc = require("moon.http.client")
local json = require("json")
local crypt = require("crypt")
local protocol = require("common.protocol_pb")
local ShopDef = require("common.def.ShopDef")
local ProtoEnum = require("tools.ProtoEnum")
local UserAttrLogic = require("common.logic.UserAttrLogic")
local jencode = json.encode
local jdecode = json.decode

---@type trademgr_context
local context = ...

local listenfd
local maxplayers = 10

---@class Shopmgr
local Shopmgr = {
    shop_server_sale = {},
    change_product_ids = {},
    add_buy_logs = {},
}

function Shopmgr.Init()
    local ret = Database.loadshopserversale(context.addr_db_game)
    if ret then
        Shopmgr.shop_server_sale = ret
    end
end

function Shopmgr.Start()
    -- 新增定时器轮询
    moon.async(function()
        while true do
            moon.sleep(10000) -- 每10秒存储一次
            Shopmgr.SaveShopServerSale()
            Shopmgr.SaveShopBuyLog()
        end
    end)

    return true
end

function Shopmgr.SaveShopServerSale()
    if table.size(Shopmgr.change_product_ids) == 0 then
        return
    end

    local save_datas = {}
    for product_id, _ in pairs(Shopmgr.change_product_ids) do
        save_datas[product_id] = Shopmgr.shop_server_sale[product_id] or 0
    end
    Database.saveshopserversale(context.addr_db_game, save_datas)

    Shopmgr.change_product_ids = {}
end

function Shopmgr.SaveShopBuyLog()
    if table.size(Shopmgr.add_buy_logs) == 0 then
        return
    end

    for _, log_data in pairs(Shopmgr.add_buy_logs) do
        Database.saveshopbuylog(context.addr_db_game, log_data)
    end

    Shopmgr.add_buy_logs = {}
end

function Shopmgr.GetProductSale(product_id)
    return Shopmgr.shop_server_sale[product_id] or 0
end

function Shopmgr.ChangeProductSale(product_id, change_num)
    local now_sale = Shopmgr.shop_server_sale[product_id] or 0
    Shopmgr.shop_server_sale[product_id] = now_sale + change_num
    Shopmgr.change_product_ids[product_id] = true
end

function Shopmgr.GetShopServerBuy()
    return Shopmgr.shop_server_sale
end

function Shopmgr.DealShopServerBuy(server_product_list)
    for product_id, num in pairs(server_product_list) do
        local product_cfg = GameCfg.ExchangeStoreWaresConfig[product_id]
        if not product_cfg then
            return { code = ErrorCode.ConfigError, error = "product not found" }
        end
        if product_cfg.limited_type ~= ShopDef.ShopLimitType.ServerLimit then
            return { code = ErrorCode.ShopBuyLimitExceed, error = "product limited type error" }
        end
        if Shopmgr.GetProductSale(product_id) + num > product_cfg.limited_num then
            return { code = ErrorCode.ShopBuyLimitExceed, error = "product buy limit exceed" }
        end
        Shopmgr.ChangeProductSale(product_id, num)
    end

    return { code = ErrorCode.None, error = "success" }
end

function Shopmgr.DelShopServerBuy(server_product_list)
    for product_id, num in pairs(server_product_list) do
        if Shopmgr.GetProductSale(product_id) >= num then
            Shopmgr.ChangeProductSale(product_id, -num)
        end
    end
end

function Shopmgr.AddShopPersonBuy(person_product_list)
    for product_id, num in pairs(person_product_list) do
        Shopmgr.ChangeProductSale(product_id, num)
    end
end

function Shopmgr.AddShopLog(log_data)
    table.insert(Shopmgr.add_buy_logs, log_data)
end

function Shopmgr.Shutdown()
    -- for _, n in pairs(context.rooms) do
    --     socket.close(n.fd)
    -- end
    if listenfd then
        socket.close(listenfd)
    end

    -- 关闭前先进行数据存储
    Shopmgr.SaveShopServerSale()
    Shopmgr.SaveShopBuyLog()
    
    moon.quit()
    return true
end

return Shopmgr
