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
local json = require("json")

---@type user_context
local context = ...
local scripts = context.scripts

---@class Shop
local Shop = {}

function Shop.Init()
    --加载商城数据
    local shop_data = Shop.LoadShopInfo()
    if shop_data then
        scripts.UserModel.SetShopData(shop_data)
    end

    local shops = scripts.UserModel.GetShopData()
    if not shops then
        shops = ShopDef.newShopPlayerData()
        shops.uid = context.uid
        shops.last_check_ts = moon.time()
        scripts.UserModel.SetShopData(shops)
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
        for id, num in pairs(req.msg.buy_id_num) do
            product_id_num[id] = num
        end
    else
        for id, num in pairs(req.msg.buy_id_num) do
            if not shops.buy_car_data[id]
                or num > shops.buy_car_data[id] then
                rsp_msg.code = ErrorCode.ShopBuyCarNotExist
                rsp_msg.error = "购物车不存在"
                return context.S2C(context.net_id, CmdCode.PBShopBuyRspCmd, rsp_msg, req.msg_context.stub_id)
            end
            product_id_num[id] = num
        end
    end

    -- 检测个人限购、合并消耗与获得
    local add_list = {}
    local cost_list = {}
    local add_roles = {}
    local server_product_list = {}
    local person_product_list = {}
    local buy_data = {}
    for id, num in pairs(product_id_num) do
        local product_cfg = GameCfg.ExchangeStoreWaresConfig[id]
        if not product_cfg then
            rsp_msg.code = ErrorCode.ConfigError
            rsp_msg.error = "配置错误"
            moon.error("Shop.PBShopBuyReqCmd config error product_id=%d", id)
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
        local now_buy_cnt = shops.buy_product_list[id] or 0
        if product_cfg.quota_type ~= ShopDef.ShopQuotaType.NoQuota
            and now_buy_cnt + num > product_cfg.quota_num then
            rsp_msg.code = ErrorCode.ShopBuyQuotaExceed
            rsp_msg.error = "购买次数超过限购"
            return context.S2C(context.net_id, CmdCode.PBShopBuyRspCmd, rsp_msg, req.msg_context.stub_id)
        end
        if product_cfg.limited_type == ShopDef.ShopLimitType.ServerLimit then
            server_product_list[id] = num
        else
            person_product_list[id] = num
        end

        for config_id, prop_num in pairs(product_cfg.prop) do
            if RoleDef.RoleDefine.RoleID.Start <= config_id
                and config_id <= RoleDef.RoleDefine.RoleID.End then
                if prop_num * num > 1 or add_roles[config_id] then
                    rsp_msg.code = ErrorCode.ShopBuyNumError
                    rsp_msg.error = "购买数量错误"
                    return context.S2C(context.net_id, CmdCode.PBShopBuyRspCmd, rsp_msg, req.msg_context.stub_id)
                end
                add_roles[config_id] = 1
            else
                if not add_list[config_id] then
                    add_list[config_id] = 0
                end
                add_list[config_id] = add_list[config_id] + prop_num * num
            end
        end

        local buy_single = ShopDef.newShopBuySingle()
        buy_single.product_id = id
        buy_single.product_num = num
        buy_single.single_price = product_cfg.price

        for config_id, price_num in pairs(product_cfg.price) do
            if not cost_list[config_id] then
                cost_list[config_id] = 0
            end
            cost_list[config_id] = cost_list[config_id] + price_num * num

            buy_single.total_price[config_id] = price_num * num
        end

        table.insert(buy_data, buy_single)
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
    ItemDefine.GetItemsFromCfg(add_list, 1, false, add_items, add_coins)
    if table.size(add_items) + table.size(add_coins) <= 0 then
        rsp_msg.code = ErrorCode.ConfigError
        rsp_msg.error = "配置错误"
        moon.error(string.format("Shop.PBShopBuyReqCmd config error add_list=%s", json.pretty_encode(add_list)))
        moon.error(string.format("Shop.PBShopBuyReqCmd config error add_items=%s", json.pretty_encode(add_items)))
        moon.error(string.format("Shop.PBShopBuyReqCmd config error add_coins=%s", json.pretty_encode(add_coins)))
        return context.S2C(context.net_id, CmdCode.PBShopBuyRspCmd, rsp_msg, req.msg_context.stub_id)
    end
    if table.size(add_items) > 0 then
        local ret_code = scripts.Bag.TryEmptyEnough(BagDef.BagType.Cangku, add_items, 0)
        if ret_code ~= ErrorCode.None then
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
    local ok = ItemDefine.GetItemDataFromIdCount(add_items, add_coins, stack_items, unstack_items, deal_coins)
    if not ok then
        rsp_msg.code = ErrorCode.ConfigError
        rsp_msg.error = "配置错误"
        moon.error(string.format("Shop.PBShopBuyReqCmd config error add_items=%s", json.pretty_encode(add_items)))
        moon.error(string.format("Shop.PBShopBuyReqCmd config error add_coins=%s", json.pretty_encode(add_coins)))
        moon.error(string.format("Shop.PBShopBuyReqCmd config error stack_items=%s", json.pretty_encode(stack_items)))
        return context.S2C(context.net_id, CmdCode.PBShopBuyRspCmd, rsp_msg, req.msg_context.stub_id)
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
        if mail_ret ~= ErrorCode.None then
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

        change_roles[req.msg.roleid] = "AddRole"
    end

    -- 发送非全服限购商品到全服管理器记录
    if table.size(person_product_list) > 0 then
        clusterd.send(3999, "shopmgr", "Shopmgr.AddShopPersonBuy", person_product_list)
    end

    -- 数据存储更新
    local save_bags = {}
    for bagType, _ in pairs(bag_change_log) do
        save_bags[bagType] = 1
    end
    scripts.Bag.SaveAndLog(save_bags, bag_change_log)

    if table.size(change_roles) > 0 then
        scripts.Role.SaveAndLog(change_roles)
    end

    -- 保存购物数据并添加购物日志
    for id, num in pairs(product_id_num) do
        if not shops.buy_product_list[id] then
            shops.buy_product_list[id] = 0  
        end
        shops.buy_product_list[id] = shops.buy_product_list[id] + num

        if req.msg.with_car ~= 0 then
            shops.buy_car_data[id] = shops.buy_car_data[id] - num
            if shops.buy_car_data[id] == 0 then
                shops.buy_car_data[id] = nil
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

return Shop