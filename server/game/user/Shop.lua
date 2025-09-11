local moon = require "moon"
local datetime = require("moon.datetime")
local common = require "common"
local clusterd = require("cluster")
local GameCfg = common.GameCfg
local ErrorCode = common.ErrorCode
local CmdCode = common.CmdCode
local Database = common.Database
local ShopDef = require("common.def.ShopDef")

---@type user_context
local context = ...
local scripts = context.scripts

---@class Shop
local Shop = {}

function Shop.Init()
    --加载商城数据
    -- local shop_data = Shop.LoadShopInfo()
    -- if shop_data then
    --     scripts.UserModel.SetShopData(shop_data)
    -- end

    -- local shops = scripts.UserModel.GetShopData()
    -- if not shops then
    --     shops = ShopDef.newShopPlayerData()
    --     shops.uid = context.uid
    --     shops.last_check_ts = moon.time()
    --     scripts.UserModel.SetShopData(shops)
    -- end
end

function Shop.Start()
    -- local trade_data = scripts.UserModel.GetShopData()
    -- if not trade_data then
    --     return
    -- end

    -- Shop.SaveShopInfoNow()
end

function Shop.SaveShopsNow()
    local shops = scripts.UserModel.GetShopData()
    if not shops then
        return false
    end

    local success = Database.saveshopinfo(context.addr_db_user, context.uid, shops)
    return success
end

function Shop.LoadShopInfo()
    local trade_info = Database.loadshopinfo(context.addr_db_user, context.uid)
    return trade_info
end

function Shop.CheckShopBuyData()
    local shops = scripts.UserModel.GetShopData()
    if not shops then
        return
    end

    local now_ts = moon.time()
    if datetime.is_same_day(shops.last_check_ts, now_ts) then
        return
    end

    for product_id, buy_cnt in pairs(shops.buy_product_list) do
        if buy_cnt > 0 then
            local shop_cfg = GameCfg.ExchangeStoreWaresConfig[product_id]
            if shop_cfg and shop_cfg.quota_type == ShopDef.ShopQuotaType.Day then
                shops.buy_product_list[product_id] = 0
            end
        end
    end

    if not datetime.is_same_week(shops.last_check_ts, now_ts) then
        for product_id, buy_cnt in pairs(shops.buy_product_list) do
            if buy_cnt > 0 then
                local shop_cfg = GameCfg.ExchangeStoreWaresConfig[product_id]
                if shop_cfg and shop_cfg.quota_type == ShopDef.ShopQuotaType.Week then
                    shops.buy_product_list[product_id] = 0
                end
            end
        end
    end

    if not datetime.is_same_month(shops.last_check_ts, now_ts) then
        for product_id, buy_cnt in pairs(shops.buy_product_list) do
            if buy_cnt > 0 then
                local shop_cfg = GameCfg.ExchangeStoreWaresConfig[product_id]
                if shop_cfg and shop_cfg.quota_type == ShopDef.ShopQuotaType.Month then
                    shops.buy_product_list[product_id] = 0
                end
            end
        end
    end

    shops.last_check_ts = now_ts
    Shop.SaveShopsNow()
end

function Shop.PBGetShopDataReqCmd(req)
    local shops = scripts.UserModel.GetShopData()
    if not shops then
        return context.S2C(context.net_id, CmdCode["PBGetShopDataRspCmd"],
            { code = ErrorCode.ServerInternalError, error = "数据加载出错", uid = context.uid }, req.msg_context.stub_id)
    end


end

return Shop