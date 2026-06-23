local moon = require "moon"
local datetime = require("moon.datetime")
local common = require "common"
local clusterd = require("cluster")
local GameCfg = common.GameCfg
local ErrorCode = common.ErrorCode
local CmdCode = common.CmdCode
local Database = common.Database
local ShopDef = require("common.def.ShopDef")
local RoleDef = require("common.def.RoleDef")
local ItemDefine = require("common.logic.ItemDefine")
local BagDef = require("common.def.BagDef")
local ItemDef = require("common.def.ItemDef")
local TreasureDef = require("common.def.TreasureDef")
local CommonCfgDef = require("common.def.CommonCfgDef")
local MissionDef = require("common.def.MissionDef")
local json = require("json")

---@type user_context
local context = ...
local scripts = context.scripts

---@class Shop
local Shop = {}

function Shop.Init()
    --加载商城,宝箱数据
    local shop_data, treasure_data = Shop.LoadShopInfo()
    if shop_data then
        scripts.UserModel.SetShopData(shop_data)
    end
    if treasure_data then
        scripts.UserModel.SetTreasureData(treasure_data)
    end

    local shops = scripts.UserModel.GetShopData()
    if not shops then
        shops = ShopDef.newShopPlayerData()
        shops.uid = context.uid
        shops.last_check_ts = moon.time()
        scripts.UserModel.SetShopData(shops)
    end
    local treasures = scripts.UserModel.GetTreasureData()
    if not treasures then
        treasures = TreasureDef.newTreasurePlayerData()
        scripts.UserModel.SetTreasureData(treasures)
    end
end

function Shop.Start()
    local trade_data = scripts.UserModel.GetShopData()
    if not trade_data then
        return
    end

    Shop.SaveShopsNow()
end

function Shop.SaveShopsNow()
    local shops = scripts.UserModel.GetShopData()
    if not shops then
        return false
    end
    local treasures = scripts.UserModel.GetTreasureData()
    if not treasures then
        return false
    end

    local success = Database.saveshopinfo(context.addr_db_user, context.uid, shops, treasures)
    return success
end

function Shop.LoadShopInfo()
    local shop_info, treasure_info = Database.loadshopinfo(context.addr_db_user, context.uid)
    return shop_info, treasure_info
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
    Shop.CheckShopBuyData()

    local res, err = clusterd.call(3999, "shopmgr", "Shopmgr.GetShopServerBuy")
    if err then
        moon.error("Shop.PBGetShopDataReqCmd Shopmgr.GetShopServerBuy err:%s", err)
    end

    local rsp = {
        code = ErrorCode.None,
        error = "",
        uid = context.uid,
        now_sys_ts = moon.time(),
        shop_player_data = shops,
        shop_server_buy = res,
    }
    return context.S2C(context.net_id, CmdCode["PBGetShopDataRspCmd"], rsp, req.msg_context.stub_id)
end

function Shop.PBShopAddBuyCarReqCmd(req)
    -- 参数验证
    if not req.msg.product_id
        or not req.msg.product_num then
        return context.S2C(context.net_id, CmdCode.PBShopAddBuyCarRspCmd, {
            code = ErrorCode.ParamInvalid,
            error = "无效请求参数",
            uid = context.uid,
        }, req.msg_context.stub_id)
    end
    -- Shop.CheckShopBuyData()

    local shops = scripts.UserModel.GetShopData()
    if not shops then
        return context.S2C(context.net_id, CmdCode["PBShopAddBuyCarReqCmd"],
            { code = ErrorCode.ServerInternalError, error = "数据加载出错", uid = context.uid }, req.msg_context.stub_id)
    end

    local now_ts = moon.time()
    local rsp_msg = {
        code = ErrorCode.None,
        error = "",
        uid = context.uid,
        now_sys_ts = now_ts,
        buy_car_data = shops.buy_car_data,
    }

    local kind_max_cfg = GameCfg.StoreConfig[ShopDef.ShopConfigId.BuyCarKindMax]
    if not kind_max_cfg or table.size(shops.buy_car_data) + 1 > kind_max_cfg.value then
        rsp_msg.code = ErrorCode.ShopBuyCarKindOverflow
        rsp_msg.error = "购物车种类超出限制"
        return context.S2C(context.net_id, CmdCode.PBShopAddBuyCarRspCmd, rsp_msg, req.msg_context.stub_id)
    end

    local now_buy_car_cnt = shops.buy_car_data[req.msg.product_id] or 0
    local num_max_cfg = GameCfg.StoreConfig[ShopDef.ShopConfigId.BuyCarNumMax]
    if not num_max_cfg or now_buy_car_cnt + req.msg.product_num > num_max_cfg.value then
        rsp_msg.code = ErrorCode.ShopBuyCarNumOverflow
        rsp_msg.error = "购物车数量超出限制"
        return context.S2C(context.net_id, CmdCode.PBShopAddBuyCarRspCmd, rsp_msg, req.msg_context.stub_id)
    end

    local product_cfg = GameCfg.ExchangeStoreWaresConfig[req.msg.product_id]
    if not product_cfg then
        rsp_msg.code = ErrorCode.ConfigError
        rsp_msg.error = "配置错误"
        return context.S2C(context.net_id, CmdCode.PBShopAddBuyCarRspCmd, rsp_msg, req.msg_context.stub_id)
    end
    if not product_cfg.validity_time_stamp
        or not product_cfg.validity_time_stamp[1]
        or not product_cfg.validity_time_stamp[2]
        or now_ts < product_cfg.validity_time_stamp[1]
        or now_ts > product_cfg.validity_time_stamp[2] then
        rsp_msg.code = ErrorCode.ShopBuyInvalid
        rsp_msg.error = "不允许购买"
        return context.S2C(context.net_id, CmdCode.PBShopAddBuyCarRspCmd, rsp_msg, req.msg_context.stub_id)
    end

    shops.buy_car_data[req.msg.product_id] = now_buy_car_cnt + req.msg.product_num
    Shop.SaveShopsNow()

    rsp_msg.buy_car_data = shops.buy_car_data
    return context.S2C(context.net_id, CmdCode.PBShopAddBuyCarRspCmd, rsp_msg, req.msg_context.stub_id)
end

function Shop.PBShopDelBuyCarReqCmd(req)
    -- 参数验证
    if not req.msg.product_id_num then
        return context.S2C(context.net_id, CmdCode.PBShopAddBuyCarRspCmd, {
            code = ErrorCode.ParamInvalid,
            error = "无效请求参数",
            uid = context.uid,
        }, req.msg_context.stub_id)
    end

    local shops = scripts.UserModel.GetShopData()
    if not shops then
        return context.S2C(context.net_id, CmdCode["PBShopDelBuyCarReqCmd"],
            { code = ErrorCode.ServerInternalError, error = "数据加载出错", uid = context.uid }, req.msg_context.stub_id)
    end

    local now_ts = moon.time()
    local rsp_msg = {
        code = ErrorCode.None,
        error = "",
        uid = context.uid,
        now_sys_ts = now_ts,
        buy_car_data = shops.buy_car_data,
    }

    for product_id, del_num in pairs(req.msg.product_id_num) do
        if not shops.buy_car_data[product_id] then
            rsp_msg.code = ErrorCode.ShopBuyCarNotExist
            rsp_msg.error = "购物车不存在"
            return context.S2C(context.net_id, CmdCode.PBShopDelBuyCarRspCmd, rsp_msg, req.msg_context.stub_id)
        end
        if shops.buy_car_data[product_id] < del_num then
            rsp_msg.code = ErrorCode.ShopBuyCarNumNotEnough
            rsp_msg.error = "购物车数量不足"
            return context.S2C(context.net_id, CmdCode.PBShopDelBuyCarRspCmd, rsp_msg, req.msg_context.stub_id)
        end
    end

    for product_id, del_num in pairs(req.msg.product_id_num) do
        shops.buy_car_data[product_id] = shops.buy_car_data[product_id] - del_num
        if shops.buy_car_data[product_id] == 0 then
            shops.buy_car_data[product_id] = nil
        end
    end
    Shop.SaveShopsNow()

    rsp_msg.buy_car_data = shops.buy_car_data
    return context.S2C(context.net_id, CmdCode.PBShopDelBuyCarRspCmd, rsp_msg, req.msg_context.stub_id)
end

function Shop.PBShopBuyReqCmd(req)
    -- 参数验证
    if not req.msg.with_car
        or not req.msg.buy_id_num then
        return context.S2C(context.net_id, CmdCode.PBShopBuyRspCmd, {
            code = ErrorCode.ParamInvalid,
            error = "无效请求参数",
            uid = context.uid,
        }, req.msg_context.stub_id)
    end
    Shop.CheckShopBuyData()

    local shops = scripts.UserModel.GetShopData()
    if not shops then
        return context.S2C(context.net_id, CmdCode["PBShopBuyRspCmd"],
            { code = ErrorCode.ServerInternalError, error = "数据加载出错", uid = context.uid }, req.msg_context.stub_id)
    end

    local now_ts = moon.time()
    local rsp_msg = {
        code = ErrorCode.None,
        error = "",
        uid = context.uid,
        now_sys_ts = now_ts,
        buy_id_num = req.msg.buy_id_num,
    }

    local log_max_cfg = GameCfg.StoreConfig[ShopDef.ShopConfigId.BuyLogMax]
    if not log_max_cfg or log_max_cfg.value <= 0 then
        rsp_msg.code = ErrorCode.ShopBuyLogOverflow
        rsp_msg.error = "购买记录超出限制"
        return context.S2C(context.net_id, CmdCode.PBShopBuyRspCmd, rsp_msg, req.msg_context.stub_id)
    end

    local mail_id_cfg = GameCfg.StoreConfig[ShopDef.ShopConfigId.ShopMailId]
    if not mail_id_cfg then
        rsp_msg.code = ErrorCode.ShopMailNotFound
        rsp_msg.error = "商店邮件配置不存在"
        return context.S2C(context.net_id, CmdCode.PBShopBuyRspCmd, rsp_msg, req.msg_context.stub_id)
    end

    local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
    local product_id_num = {}
    if req.msg.with_car == 0 then
        for _, selecbuy in pairs(req.msg.buy_id_num) do
            table.insert(product_id_num, selecbuy)
        end
    else
        for _, selecbuy in pairs(req.msg.buy_id_num) do
            if not shops.buy_car_data[selecbuy.product_id]
                or selecbuy.product_num > shops.buy_car_data[selecbuy.product_id] then
                rsp_msg.code = ErrorCode.ShopBuyCarNotExist
                rsp_msg.error = "购物车不存在"
                return context.S2C(context.net_id, CmdCode.PBShopBuyRspCmd, rsp_msg, req.msg_context.stub_id)
            end
            table.insert(product_id_num, selecbuy)
        end
    end

    -- 检测个人限购、合并消耗与获得
    local add_list = {}
    local cost_list = {}
    local add_roles = {}
    local server_product_list = {}
    local person_product_list = {}
    local buy_data = {}
    local add_treasure_list = {}
    for _, selecbuy in pairs(product_id_num) do
        local product_cfg = GameCfg.ExchangeStoreWaresConfig[selecbuy.product_id]
        if not product_cfg then
            rsp_msg.code = ErrorCode.ConfigError
            rsp_msg.error = "配置错误"
            moon.error("Shop.PBShopBuyReqCmd config error product_id=%d", selecbuy.product_id)
            return context.S2C(context.net_id, CmdCode.PBShopBuyRspCmd, rsp_msg, req.msg_context.stub_id)
        end
        if not product_cfg.validity_time_stamp
            or not product_cfg.validity_time_stamp[1]
            or not product_cfg.validity_time_stamp[2]
            or now_ts < product_cfg.validity_time_stamp[1]
            or now_ts > product_cfg.validity_time_stamp[2] then
            rsp_msg.code = ErrorCode.ShopBuyInvalid
            rsp_msg.error = "不允许购买"
            return context.S2C(context.net_id, CmdCode.PBShopAddBuyCarRspCmd, rsp_msg, req.msg_context.stub_id)
        end
        local now_buy_cnt = shops.buy_product_list[selecbuy.product_id] or 0
        if product_cfg.quota_type ~= ShopDef.ShopQuotaType.NoQuota
            and now_buy_cnt + selecbuy.product_num > product_cfg.quota_num then
            rsp_msg.code = ErrorCode.ShopBuyQuotaExceed
            rsp_msg.error = "购买次数超过限购"
            return context.S2C(context.net_id, CmdCode.PBShopBuyRspCmd, rsp_msg, req.msg_context.stub_id)
        end
        if product_cfg.limited_type == ShopDef.ShopLimitType.ServerLimit then
            server_product_list[selecbuy.product_id] = selecbuy.product_num
        else
            person_product_list[selecbuy.product_id] = selecbuy.product_num
        end

        for config_id, prop_num in pairs(product_cfg.prop) do
            if RoleDef.RoleDefine.RoleID.Start <= config_id
                and config_id <= RoleDef.RoleDefine.RoleID.End then
                if prop_num * selecbuy.product_num > 1 or add_roles[config_id] then
                    rsp_msg.code = ErrorCode.ShopBuyNumError
                    rsp_msg.error = "购买数量错误"
                    return context.S2C(context.net_id, CmdCode.PBShopBuyRspCmd, rsp_msg, req.msg_context.stub_id)
                end
                add_roles[config_id] = 1
            else
                if not add_list[config_id] then
                    add_list[config_id] = 0
                end
                add_list[config_id] = add_list[config_id] + prop_num * selecbuy.product_num
            end
        end

        local buy_single = ShopDef.newShopBuySingle()
        buy_single.product_id = selecbuy.product_id
        buy_single.product_num = selecbuy.product_num
        local price_key = "price" .. selecbuy.price_type
        if not product_cfg[price_key] or table.size(product_cfg[price_key]) == 0 then
            rsp_msg.code = ErrorCode.ConfigError
            rsp_msg.error = "货币类型错误"
            return context.S2C(context.net_id, CmdCode.PBShopBuyRspCmd, rsp_msg, req.msg_context.stub_id)
        end
        buy_single.single_price = product_cfg[price_key]

        for config_id, price_num in pairs(product_cfg[price_key]) do
            if not cost_list[config_id] then
                cost_list[config_id] = 0
            end
            cost_list[config_id] = cost_list[config_id] + price_num * selecbuy.product_num

            buy_single.total_price[config_id] = price_num * selecbuy.product_num
        end

        table.insert(buy_data, buy_single)

        if table.size(product_cfg.treasurechest) > 0 then
            for t_id, t_cnt in pairs(product_cfg.treasurechest) do
                if not add_treasure_list[t_id] then
                    add_treasure_list[t_id] = 0
                end
                add_treasure_list[t_id] = add_treasure_list[t_id] + t_cnt * selecbuy.product_num
            end
        end
    end

    -- 检测角色是否可以获得
    local err_code = scripts.Role.CheckAddRoles(add_roles)
    if err_code ~= ErrorCode.None then
        rsp_msg.code = err_code
        rsp_msg.error = "角色不能获得"
        return context.S2C(context.net_id, CmdCode.PBShopBuyRspCmd, rsp_msg, req.msg_context.stub_id)
    end

    -- 检查消耗品数量
    local cost_items, cost_coins = {}, {}
    ItemDefine.GetItemsFromCfg(cost_list, 1, true, cost_items, cost_coins)
    local err_code_items = scripts.Bag.CheckItemsEnough(BagDef.BagType.Cangku, cost_items, {})
    if err_code_items ~= ErrorCode.None then
        rsp_msg.code = err_code_items
        rsp_msg.error = "消耗物品不足"
        return context.S2C(context.net_id, CmdCode.PBShopBuyRspCmd, rsp_msg, req.msg_context.stub_id)
    end
    local err_code_coins = scripts.Bag.CheckCoinsEnough(cost_coins)
    if err_code_coins ~= ErrorCode.None then
        rsp_msg.code = err_code_coins
        rsp_msg.error = "消耗金币不足"
        return context.S2C(context.net_id, CmdCode.PBShopBuyRspCmd, rsp_msg, req.msg_context.stub_id)
    end

    -- 计算获得资源
    local add_items, add_coins = {}, {}
    local use_mail = false
    if table.size(add_list) > 0 then
        ItemDefine.GetItemsFromCfg(add_list, 1, false, add_items, add_coins)
        if table.size(add_items) + table.size(add_coins) <= 0 then
            rsp_msg.code = ErrorCode.ConfigError
            rsp_msg.error = "配置错误"
            moon.error(string.format("Shop.PBShopBuyReqCmd config error add_list=%s", json.pretty_encode(add_list)))
            moon.error(string.format("Shop.PBShopBuyReqCmd config error add_items=%s", json.pretty_encode(add_items)))
            moon.error(string.format("Shop.PBShopBuyReqCmd config error add_coins=%s", json.pretty_encode(add_coins)))
            return context.S2C(context.net_id, CmdCode.PBShopBuyRspCmd, rsp_msg, req.msg_context.stub_id)
        end
    end
    if table.size(add_items) > 0 then
        local ret_code = scripts.Bag.TryEmptyEnough(BagDef.BagType.Cangku, add_items, 0)
        if ret_code ~= ErrorCode.None then
            moon.error(string.format("Shop.PBShopBuyReqCmd TryEmptyEnough error ret_code=%d", ret_code))
            if ret_code == ErrorCode.BagFull then
                use_mail = true
            else
                rsp_msg.code = ret_code
                rsp_msg.error = "尝试添加道具失败"
                return context.S2C(context.net_id, CmdCode.PBShopBuyRspCmd, rsp_msg, req.msg_context.stub_id)
            end
        end
    end
    -- 根据道具表生成item_data
    local stack_items, unstack_items, deal_coins = {}, {}, {}
    if table.size(add_items) + table.size(add_coins) > 0 then
        local ok = ItemDefine.GetItemDataFromIdCount(add_items, add_coins, stack_items, unstack_items, deal_coins)
        if not ok then
            rsp_msg.code = ErrorCode.ConfigError
            rsp_msg.error = "配置错误"
            moon.error(string.format("Shop.PBShopBuyReqCmd config error add_items=%s", json.pretty_encode(add_items)))
            moon.error(string.format("Shop.PBShopBuyReqCmd config error add_coins=%s", json.pretty_encode(add_coins)))
            moon.error(string.format("Shop.PBShopBuyReqCmd config error stack_items=%s", json.pretty_encode(stack_items)))
            return context.S2C(context.net_id, CmdCode.PBShopBuyRspCmd, rsp_msg, req.msg_context.stub_id)
        end
    end

    -- 向全服管理器申请减扣商品
    if table.size(server_product_list) > 0 then
        local res, err = clusterd.call(3999, "shopmgr", "Shopmgr.DealShopServerBuy", server_product_list)
        if err then
            moon.error("Shop.PBGetShopDataReqCmd Shopmgr.DealShopServerBuy err:%s", err)
            rsp_msg.code = ErrorCode.ServerInternalError
            rsp_msg.error = "服务器内部错误"
            return context.S2C(context.net_id, CmdCode.PBShopBuyRspCmd, rsp_msg, req.msg_context.stub_id)
        end
        if res.code ~= ErrorCode.None then
            rsp_msg.code = res.code
            rsp_msg.error = res.error
            return context.S2C(context.net_id, CmdCode.PBShopBuyRspCmd, rsp_msg, req.msg_context.stub_id)
        end
    end

    local bag_change_log = {}
    -- 扣除道具消耗
    if table.size(cost_items) > 0 then
        rsp_msg.code = scripts.Bag.DelItems(BagDef.BagType.Cangku, cost_items, {}, bag_change_log)
        if rsp_msg.code ~= ErrorCode.None then
            rsp_msg.error = "消耗物品不足"

            scripts.Bag.RollBackWithChange(bag_change_log)
            clusterd.send(3999, "shopmgr", "Shopmgr.DelShopServerBuy", server_product_list)
            return context.S2C(context.net_id, CmdCode.PBShopBuyRspCmd, rsp_msg, req.msg_context.stub_id)
        end
    end
    if table.size(cost_coins) > 0 then
        rsp_msg.code = scripts.Bag.DealCoins(cost_coins, bag_change_log)
        if rsp_msg.code ~= ErrorCode.None then
            rsp_msg.error = "消耗金币不足"

            scripts.Bag.RollBackWithChange(bag_change_log)
            clusterd.send(3999, "shopmgr", "Shopmgr.DelShopServerBuy", server_product_list)
            return context.S2C(context.net_id, CmdCode.PBShopBuyRspCmd, rsp_msg, req.msg_context.stub_id)
        end
    end

    if not use_mail then
        -- 添加道具
        if table.size(stack_items) + table.size(unstack_items) > 0 then
            rsp_msg.code = scripts.Bag.AddItems(BagDef.BagType.Cangku, stack_items, unstack_items, bag_change_log)
            if rsp_msg.code ~= ErrorCode.None then
                rsp_msg.error = "添加道具失败"

                scripts.Bag.RollBackWithChange(bag_change_log)
                clusterd.send(3999, "shopmgr", "Shopmgr.DelShopServerBuy", server_product_list)
                return context.S2C(context.net_id, CmdCode.PBShopBuyRspCmd, rsp_msg, req.msg_context.stub_id)
            end
        end
    else
        -- 发送邮件
        local item_datas = {}
        for _, item_data in pairs(stack_items) do
            table.insert(item_datas, item_data)
        end
        for _, item_data in pairs(unstack_items) do
            table.insert(item_datas, item_data)
        end
        local mail_ret = scripts.Mail.RecvImmediateMail(mail_id_cfg.value, {}, item_datas, {})
        if not mail_ret then
            rsp_msg.code = ErrorCode.ShopMailSendFailed
            rsp_msg.error = "发送邮件失败"

            scripts.Bag.RollBackWithChange(bag_change_log)
            clusterd.send(3999, "shopmgr", "Shopmgr.DelShopServerBuy", server_product_list)
            return context.S2C(context.net_id, CmdCode.PBShopBuyRspCmd, rsp_msg, req.msg_context.stub_id)
        end
    end
    -- 添加货币
    if table.size(deal_coins) > 0 then
        rsp_msg.code = scripts.Bag.DealCoins(deal_coins, bag_change_log)
        if rsp_msg.code ~= ErrorCode.None then
            rsp_msg.error = "添加货币失败"

            scripts.Bag.RollBackWithChange(bag_change_log)
            clusterd.send(3999, "shopmgr", "Shopmgr.DelShopServerBuy", server_product_list)
            return context.S2C(context.net_id, CmdCode.PBShopBuyRspCmd, rsp_msg, req.msg_context.stub_id)
        end
    end

    -- 添加角色
    local change_roles = {}
    for roleid, _ in pairs(add_roles) do
        rsp_msg.code = scripts.Role.AddRole(roleid)
        if rsp_msg.code ~= ErrorCode.None then
            rsp_msg.code = ErrorCode.RoleAddFail
            rsp_msg.error = "角色添加失败"

            scripts.Bag.RollBackWithChange(bag_change_log)
            clusterd.send(3999, "shopmgr", "Shopmgr.DelShopServerBuy", server_product_list)
            return context.S2C(context.net_id, CmdCode.PBSureCompositeRspCmd, rsp_msg, req.msg_context.stub_id)
        end

        change_roles[roleid] = "AddRole"
    end

    -- 发送非全服限购商品到全服管理器记录
    if table.size(person_product_list) > 0 then
        clusterd.send(3999, "shopmgr", "Shopmgr.AddShopPersonBuy", person_product_list)
    end

    -- 数据存储更新
    -- local save_bags = {}
    -- for bagType, _ in pairs(bag_change_log) do
    --     save_bags[bagType] = 1
    -- end
    -- scripts.Bag.SaveAndLog(save_bags, bag_change_log)
    scripts.Bag.SaveAndLog(bag_change_log, ItemDef.ChangeReason.ShopBuy)

    if table.size(change_roles) > 0 then
        scripts.Role.SaveAndLog(change_roles)
    end

    -- 添加宝箱
    for t_id, t_cnt in pairs(add_treasure_list) do
        Shop.AddTreasure(t_id, t_cnt)
    end
    -- 触发获得宝箱数量
    local total_get_count = Shop.GetTreasureTotalCnt()
    scripts.Mission.TriggerCondition(MissionDef.EConditionIds.GET_TREASURE_CNT, { 0 }, total_get_count)

    -- 保存购物数据并添加购物日志
    for _, selecbuy in pairs(product_id_num) do
        if not shops.buy_product_list[selecbuy.product_id] then
            shops.buy_product_list[selecbuy.product_id] = 0
        end
        shops.buy_product_list[selecbuy.product_id] = shops.buy_product_list[selecbuy.product_id] + selecbuy.product_num

        if req.msg.with_car ~= 0 then
            shops.buy_car_data[selecbuy.product_id] = shops.buy_car_data[selecbuy.product_id] - selecbuy.product_num
            if shops.buy_car_data[selecbuy.product_id] == 0 then
                shops.buy_car_data[selecbuy.product_id] = nil
            end
        end
    end
    shops.self_order_id = shops.self_order_id + 1

    local new_order_id = tonumber(tostring(context.uid) .. tostring(shops.self_order_id))
    local new_log = ShopDef.newShopBuyLog()
    new_log.order_id = math.floor(new_order_id) or context.uid
    new_log.buyer_uid = context.uid
    new_log.buy_ts = moon.time()
    new_log.log_total_price = cost_list
    new_log.buy_data = buy_data
    if table.size(shops.shop_logs) >= log_max_cfg.value then
        table.remove(shops.shop_logs, 1)
    end
    table.insert(shops.shop_logs, new_log)

    Shop.SaveShopsNow()

    clusterd.send(3999, "shopmgr", "Shopmgr.AddShopLog", new_log)

    return context.S2C(context.net_id, CmdCode.PBShopBuyRspCmd, rsp_msg, req.msg_context.stub_id)
end

function Shop.GetTreasureDatas()
    local treasures = scripts.UserModel.GetTreasureData()
    if not treasures then
        return {}
    end

    return treasures
end

function Shop.GetTreasureData(config_id)
    local treasures = scripts.UserModel.GetTreasureData()
    if not treasures or not treasures.treasure_list[config_id] then
        return {}
    end

    return treasures.treasure_list[config_id]
end

function Shop.GetTreasureTotalCnt()
    local treasures = scripts.UserModel.GetTreasureData()
    if not treasures then
        return 0
    end

    return treasures.total_get_count
end

function Shop.GetTreasureTotalOpenCnt()
    local treasures = scripts.UserModel.GetTreasureData()
    if not treasures then
        return 0
    end

    return treasures.total_open_count
end

function Shop.AddTreasure(config_id, num)
    -- moon.error("Shop AddTreasure config_id=%d num=%d", config_id, num)
    local treasures = scripts.UserModel.GetTreasureData()
    if not treasures then
        moon.error("Shop AddTreasure treasures err")
        return false
    end
    local item_type = ItemDefine.GetItemPosType(config_id)
    if item_type ~= ItemDefine.EItemBigType.TreasureChest then
        moon.error(string.format("Shop AddTreasure config_id=%d item_type=%d", config_id, item_type))
        return false
    end

    if not treasures.treasure_list[config_id] then
        local new_treasure = TreasureDef.newTreasureSingle()
        new_treasure.config_id = config_id
        new_treasure.now_count = num
        treasures.treasure_list[config_id] = new_treasure
        treasures.treasure_list[config_id].get_count = num
    else
        treasures.treasure_list[config_id].now_count = treasures.treasure_list[config_id].now_count + num
        treasures.treasure_list[config_id].get_count = treasures.treasure_list[config_id].get_count + num
    end
    treasures.total_get_count = treasures.total_get_count + num
    -- 触发获得宝箱数量
    scripts.Mission.TriggerCondition(MissionDef.EConditionIds.GET_TREASURE_CNT, { config_id },
        treasures.treasure_list[config_id].get_count)
    scripts.UserModel.SetTreasureData(treasures)

    Shop.SaveShopsNow()
end

function Shop.OpenTreasure(config_id, num)
    local treasures = scripts.UserModel.GetTreasureData()
    if not treasures then
        return ErrorCode.ServerInternalError
    end
    -- 执行开宝箱逻辑
    local item_type = ItemDefine.GetItemPosType(config_id)
    if item_type ~= ItemDefine.EItemBigType.TreasureChest then
        return ErrorCode.ParamInvalid
    end

    local treasure_cfg = GameCfg.TreasureChest[config_id]
    if not treasure_cfg then
        moon.error(string.format("GameCfg.TreasureChest config error config_id=%d", config_id))
        return ErrorCode.ConfigError
    end
    local mail_id_cfg = CommonCfgDef.getConf("TreasureBoxEmail")
    if not mail_id_cfg then
        moon.error("CommonCfgDef.getConf TreasureBoxEmail err")
        return ErrorCode.ConfigError
    end

    local now_ts = moon.time()
    if (treasure_cfg.start_time > 0 and now_ts < treasure_cfg.start_time)
        or (treasure_cfg.end_time > 0 and now_ts > treasure_cfg.end_time) then
        return ErrorCode.TreasureOutTime
    end

    local treasure_data = treasures.treasure_list[config_id]
    if not treasure_data then
        treasure_data = TreasureDef.newTreasureSingle()
        treasure_data.config_id = config_id
        treasures.treasure_list[config_id] = treasure_data
    end

    if treasure_cfg.type == TreasureDef.ChestType.CONSUME then
        if treasure_data.now_count < num then
            return ErrorCode.TreasureNotEnough
        end
    end

    local cost_items = {}
    local cost_coins = {}
    -- 计算消耗资源
    ItemDefine.GetItemsFromCfg(treasure_cfg.open_consume, num, true, cost_items, cost_coins)
    -- 检查资源是否足够
    local err_code_items = scripts.Bag.CheckItemsEnough(BagDef.BagType.Cangku, cost_items, {})
    if err_code_items ~= ErrorCode.None then
        return err_code_items
    end
    local err_code_coins = scripts.Bag.CheckCoinsEnough(cost_coins)
    if err_code_coins ~= ErrorCode.None then
        return err_code_coins
    end

    local trigger_cnt = 0
    local add_list, re_list = {}, {}
    for i = 1, num do
        local is_guarantee = false
        local cur_yu = (treasure_data.no_guarantee_cnt + i) % treasure_cfg.guarantee_trigger
        local cur_zheng = math.floor((treasure_data.no_guarantee_cnt + i) / treasure_cfg.guarantee_trigger)
        if treasure_cfg.guarantee_times < 0 then
            if cur_yu == 0 then
                is_guarantee = true
            end
        elseif treasure_cfg.guarantee_times > 0 then
            if treasure_data.already_guarantee_cnt + cur_zheng <= treasure_cfg.guarantee_times
                and cur_yu == 0 then
                is_guarantee = true
            end
        end

        local pool_id = 0
        if is_guarantee then
            pool_id = treasure_cfg.guarantee_item
        else
            -- 随机品质
            local rand_quality = scripts.Item.RangeTags(treasure_cfg.quality_weight)
            -- 随机类型
            local rand_class = scripts.Item.RangeTags(treasure_cfg.class_weight)
            pool_id = rand_class * 10 + rand_quality
        end

        local reward_cfg = GameCfg.TreasureChestRewards[pool_id]
        if not reward_cfg then
            moon.error(string.format("GameCfg.TreasureChestRewards config error pool_id=%d", pool_id))
            return ErrorCode.ConfigError
        end
        -- 随机奖品id
        local rand_id = scripts.Item.RangeTags(reward_cfg.item_weight)
        -- 随机奖品数量
        local rand_num = 0
        if reward_cfg.item_num[rand_id] then
            rand_num = reward_cfg.item_num[rand_id]
        end
        if rand_num == 0 then
            moon.error(string.format("GameCfg.TreasureChestRewards reward_cfg.item_num error rand_id=%d", rand_id))
            return ErrorCode.ConfigError
        end
        if not add_list[rand_id] then
            add_list[rand_id] = rand_num
        else
            add_list[rand_id] = add_list[rand_id] + rand_num
        end
        table.insert(re_list, {id = rand_id, count = rand_num})

        if is_guarantee then
            trigger_cnt = trigger_cnt + 1
        end
    end

    local add_items, add_coins = {}, {}
    ItemDefine.GetItemsFromCfg(add_list, 1, false, add_items, add_coins)
    if table.size(add_items) + table.size(add_coins) <= 0 then
        moon.error(string.format("ItemDefine.GetItemsFromCfg config error add_list=%s", json.pretty_encode(add_list)))
        return ErrorCode.ConfigError
    end
    local use_mail = false
    if table.size(add_items) > 0 then
        local ret_code = scripts.Bag.TryEmptyEnough(BagDef.BagType.Cangku, add_items, 0)
        if ret_code ~= ErrorCode.None then
            if ret_code == ErrorCode.BagFull then
                use_mail = true
            else
                return ret_code
            end
        end
    end

    local stack_items, unstack_items, deal_coins = {}, {}, {}
    local ok = ItemDefine.GetItemDataFromIdCount(add_items, add_coins, stack_items, unstack_items, deal_coins)
    if not ok then
        moon.error(string.format("ItemDefine.GetItemDataFromIdCount config error add_items=%s", json.pretty_encode(add_items)))
        moon.error(string.format("ItemDefine.GetItemDataFromIdCount config error add_coins=%s", json.pretty_encode(add_coins)))
        return ErrorCode.ConfigError
    end

    local bag_change_log = {}
    -- 扣除道具消耗
    if table.size(cost_items) > 0 then
        local err_code_items = scripts.Bag.DelItems(BagDef.BagType.Cangku, cost_items, {}, bag_change_log)
        if err_code_items ~= ErrorCode.None then
            scripts.Bag.RollBackWithChange(bag_change_log)
            return err_code_items
        end
    end
    if table.size(cost_coins) > 0 then
        local err_code_coins = scripts.Bag.DealCoins(cost_coins, bag_change_log)
        if err_code_coins ~= ErrorCode.None then
            scripts.Bag.RollBackWithChange(bag_change_log)
            return err_code_coins
        end
    end
    
    if not use_mail then
        if table.size(stack_items) + table.size(unstack_items) > 0 then
            local err_code_items = scripts.Bag.AddItems(BagDef.BagType.Cangku, stack_items, unstack_items, bag_change_log)
            if err_code_items ~= ErrorCode.None then
                scripts.Bag.RollBackWithChange(bag_change_log)
                return err_code_items
            end
        end
    else
        -- 发送邮件
        local item_datas = {}
        for _, item_data in pairs(stack_items) do
            table.insert(item_datas, item_data)
        end
        for _, item_data in pairs(unstack_items) do
            table.insert(item_datas, item_data)
        end
        local mail_ret = scripts.Mail.RecvImmediateMail(mail_id_cfg.value, {}, item_datas, {})
        if not mail_ret then
            scripts.Bag.RollBackWithChange(bag_change_log)
            return ErrorCode.TreasureMailSendFailed
        end
    end
    -- 添加货币
    if table.size(deal_coins) > 0 then
        local err_code_coins = scripts.Bag.DealCoins(deal_coins, bag_change_log)
        if err_code_coins ~= ErrorCode.None then
            scripts.Bag.RollBackWithChange(bag_change_log)
            return err_code_coins
        end
    end

    if treasure_cfg.type == TreasureDef.ChestType.CONSUME then
        treasure_data.now_count = treasure_data.now_count - num
    end
    treasure_data.open_count = treasure_data.open_count + num
    treasure_data.no_guarantee_cnt = treasure_data.no_guarantee_cnt + num -
        (treasure_cfg.guarantee_trigger * trigger_cnt)
    treasure_data.already_guarantee_cnt = treasure_data.already_guarantee_cnt + trigger_cnt
    treasures.treasure_list[config_id] = treasure_data
    treasures.total_open_count = treasures.total_open_count + num

    -- 触发获得宝箱数量
    scripts.Mission.TriggerCondition(MissionDef.EConditionIds.OPEN_TREASURE_CNT, { config_id }, treasure_data.open_count)
    scripts.Mission.TriggerCondition(MissionDef.EConditionIds.OPEN_TREASURE_CNT, { 0 }, treasures.total_open_count)

    Shop.SaveShopsNow()
    scripts.Bag.SaveAndLog(bag_change_log, ItemDef.ChangeReason.TreasureOpen)

    return ErrorCode.None, re_list
end

return Shop