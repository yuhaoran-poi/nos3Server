local moon = require("moon")
local datetime = require("moon.datetime")
local common = require("common")
local clusterd = require("cluster")
local json = require "json"
local CmdCode = common.CmdCode
local GameCfg = common.GameCfg
local Database = common.Database
local protocol = common.protocol
local ErrorCode = common.ErrorCode
local httpc = require("moon.http.client")
local BillDef = require("common.def.BillDef")
local ItemDef = require("common.def.ItemDef")
local ProtoEnum = require("tools.ProtoEnum")
local serverconf = require("serverconf")
local MissionDef = require("common.def.MissionDef")
local Rank = require("game.user.Rank")

---@type user_context
local context = ...
local scripts = context.scripts

local function escape(s)
    return (string.gsub(s, "([^A-Za-z0-9_])", function(c)
        return string.format("%%%02X", string.byte(c))
    end))
end

---@class Bill
local Bill = {}

function Bill.Init()
    --加载充值数据
    --local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
    local bills_data = Bill.LoadBills()
    if bills_data then
        scripts.UserModel.SetBills(bills_data)
    end

    local bills = scripts.UserModel.GetBills()
    if not bills then
        bills = BillDef.newBillData()
        bills.update_ts = moon.time()
        scripts.UserModel.SetBills(bills)
    end
end

function Bill.Start()
    local bills = scripts.UserModel.GetBills()
    if not bills then
        return false
    end

    Bill.DealOnOrder()

    return true
end

function Bill.SaveBillsNow()
    local bills = scripts.UserModel.GetBills()
    if not bills then
        return false
    end

    --发电榜更新
    scripts.Rank.UpdateRank_Fadian(bills.week_bill_amount, bills.month_bill_amount, bills.total_bill_amount)
    local success = Database.savebillinfo(context.addr_db_user, context.uid, bills)
    return success
end

function Bill.LoadBills()
    --local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
    local bills_data = Database.loadbillinfo(context.addr_db_user, context.uid)
    return bills_data
end

function Bill.GetTotalAmount()
    local bills = scripts.UserModel.GetBills()
    if not bills or not bills.total_bill_amount then
        return 0
    end

    return bills.total_bill_amount
end

function Bill.DealOnOrder()
    local bills = scripts.UserModel.GetBills()
    if not bills then
        return
    end
    if not bills.on_order_id or bills.on_order_id == 0 then
        return
    end

    local order_info = Database.loadbillorder(context.addr_db_user, bills.on_order_id)
    if not order_info then
        return
    end

    if order_info.state ~= BillDef.orderStatus.WAIT
        and order_info.state ~= BillDef.orderStatus.PAID then
        return
    end
    
    local json_success, rsp_data = Bill.QueryOrder(bills.on_order_id, order_info.transid)
    if not json_success then
        return
    else
        if rsp_data.response.result == 'OK' then
            if rsp_data.response.params.status == 'Approved' then
                order_info.state = BillDef.orderStatus.WAIT
                Bill.on_order_info = order_info
                return
            elseif rsp_data.response.params.status == 'Succeeded' then
                clusterd.send(3999, "billmgr", "Billmgr.DelBill", bills.on_order_id)
                local bill_cfg = GameCfg.RechargeStoreConfig[Bill.on_order_info.bill_id]
                if not bill_cfg then
                    bills.on_order_id = 0
                    Bill.on_order_info = nil
                    Bill.SaveBillsNow()
                    return
                end
                local ret_status = Bill.BillDeliver(order_info, bill_cfg) -- 充值成功,发货
                if ret_status == BillDef.orderStatus.DONE then
                    Bill.AddBillAmount(bills, order_info, bill_cfg)
                end
                bills.on_order_id = 0
                Bill.on_order_info = nil
                Bill.SaveBillsNow()
            elseif rsp_data.response.params.status == 'Failed' then
                clusterd.send(3999, "billmgr", "Billmgr.DelBill", bills.on_order_id)
                Bill.BillFailed(order_info) -- 充值失败,记录失败
                bills.on_order_id = 0
                Bill.on_order_info = nil
                Bill.SaveBillsNow()
            elseif rsp_data.response.params.status == 'Refunded'
                or rsp_data.response.params.status == 'PartialRefund'
                or rsp_data.response.params.status == 'Chargedback'
                or rsp_data.response.params.status == 'RefundedSuspectedFraud'
                or rsp_data.response.params.status == 'RefundedFriendlyFraud' then
                -- 订单已退款
                -- 购物车中的一个或多个物品已退款
                -- 订单存在欺诈或争议
                -- 因涉嫌欺诈,该订单已被 Valve 退款
                -- 因被认定为友好欺诈,该订单已被 Valve 退款
                clusterd.send(3999, "billmgr", "Billmgr.DelBill", bills.on_order_id)
                Bill.BillRefund(Bill.on_order_info) -- 充值退款,记录退款
                bills.on_order_id = 0
                Bill.on_order_info = nil
                Bill.SaveBillsNow()
            else
                moon.error("DealOnOrder 未知订单状态: " .. rsp_data.response.params.status)
            end
        end
    end
end

function Bill.CheckBillAmount(bills)
    local is_change = false
    local now_ts = moon.time()
    if not datetime.is_same_day(bills.update_ts, now_ts) then
        bills.day_bill_amount = 0
        is_change = true
    end
    if not datetime.is_same_week(bills.update_ts, now_ts) then
        bills.week_bill_amount = 0
        is_change = true
    end
    if not datetime.is_same_month(bills.update_ts, now_ts) then
        bills.month_bill_amount = 0
        is_change = true
    end
    if not datetime.is_same_year(bills.update_ts, now_ts) then
        bills.year_bill_amount = 0
        is_change = true
    end
    if is_change then
        bills.update_ts = now_ts
        Bill.SaveBillsNow()
    end
end

function Bill.AddBillAmount(bills, order_info, bill_cfg)
    Bill.CheckBillAmount(bills)
    -- 增加累充
    local amount_record = bill_cfg.price_record * order_info.bill_num
    local now_ts = moon.time()
    if datetime.is_same_day(Bill.on_order_info.create_ts, now_ts) then
        bills.day_bill_amount = bills.day_bill_amount + amount_record
    end
    if datetime.is_same_week(Bill.on_order_info.create_ts, now_ts) then
        bills.week_bill_amount = bills.week_bill_amount + amount_record
    end
    if datetime.is_same_month(Bill.on_order_info.create_ts, now_ts) then
        bills.month_bill_amount = bills.month_bill_amount + amount_record
    end
    if datetime.is_same_year(Bill.on_order_info.create_ts, now_ts) then
        bills.year_bill_amount = bills.year_bill_amount + amount_record
    end
    bills.total_bill_amount = bills.total_bill_amount + amount_record
    -- 触发充值金额
    scripts.Mission.TriggerCondition(MissionDef.EConditionIds.RECHARGE_CNT, {}, amount_record)
    -- 触发累计充值金额
    scripts.Mission.TriggerCondition(MissionDef.EConditionIds.TOTAL_RECHARGE_CNT, {}, bills.total_bill_amount)

    context.S2C(context.net_id, CmdCode.PBBillDoneSyncCmd, {
        bill_id = Bill.on_order_info.bill_id,
        bill_num = Bill.on_order_info.bill_num,
        bill_amount = amount_record,
    }, 0)
end

function Bill.OnBillPaid(order_info)
    local bills = scripts.UserModel.GetBills()
    if not bills then
        return false
    end

    local bill_cfg = GameCfg.RechargeStoreConfig[order_info.bill_id]
    if not bill_cfg then
        return false
    end
    
    if order_info.orderid == bills.on_order_id
        and Bill.on_order_info
        and Bill.on_order_info.orderid == order_info.orderid
        and Bill.on_order_info.state == BillDef.orderStatus.WAIT then
        Bill.on_order_info.state = BillDef.orderStatus.PAID
        local ret = Bill.BillDeliver(Bill.on_order_info, bill_cfg)
        if Bill.on_order_info.state == BillDef.orderStatus.DONE then
            Bill.AddBillAmount(bills, Bill.on_order_info, bill_cfg)

            bills.on_order_id = 0
            Bill.on_order_info = nil
            Bill.SaveBillsNow()
        end
    end
end

function Bill.BillDeliver(order_info, bill_cfg)
    if order_info.state ~= BillDef.orderStatus.WAIT
        and order_info.state ~= BillDef.orderStatus.PAID then
        return order_info.state
    end

    local ret = Database.updatebillorderstate(context.addr_db_user, order_info.orderid, order_info.state,
        BillDef.orderStatus.DONE, true)
    if ret <= 0 then
        return order_info.state
    end
    order_info.state = BillDef.orderStatus.DONE

    -- 发送充值道具到客户端
    local bag_change_log = {}
    local bill_coins = {}
    for coin_id, coin_count in pairs(bill_cfg.prop) do
        bill_coins[coin_id] = {
            coin_id = coin_id,
            coin_count = coin_count * order_info.bill_num,
        }
    end
    local err_code_add = scripts.Bag.DealCoins(bill_coins, bag_change_log)
    if err_code_add ~= ErrorCode.None then
        scripts.Bag.RollBackWithChange(bag_change_log)
        moon.error("Bill.BillDeliver err_code_add = " .. err_code_add)
    end
    scripts.Bag.SaveAndLog(bag_change_log, ItemDef.ChangeReason.Bill)

    return order_info.state
end

function Bill.OnBillFailed(order_info)
    local bills = scripts.UserModel.GetBills()
    if not bills then
        return false
    end

    if order_info.orderid == bills.on_order_id
        and Bill.on_order_info
        and Bill.on_order_info.orderid == order_info.orderid then
        Bill.on_order_info.state = BillDef.orderStatus.FAIL
        bills.on_order_id = 0
        Bill.on_order_info = nil
        Bill.SaveBillsNow()
    end
end

function Bill.BillFailed(order_info)
    if order_info.state ~= BillDef.orderStatus.WAIT
        and order_info.state ~= BillDef.orderStatus.PAID then
        return order_info.state
    end

    local ret = Database.updatebillorderstate(context.addr_db_user, order_info.orderid, order_info.state,
        BillDef.orderStatus.FAIL, true)
    if ret <= 0 then
        return order_info.state
    end
    order_info.state = BillDef.orderStatus.FAIL

    return order_info.state
end

function Bill.OnBillRefund(order_info)
    local bills = scripts.UserModel.GetBills()
    if not bills then
        return false
    end

    if order_info.orderid == bills.on_order_id
        and Bill.on_order_info
        and Bill.on_order_info.orderid == order_info.orderid then
        Bill.on_order_info.state = BillDef.orderStatus.REFUND
        bills.on_order_id = 0
        Bill.on_order_info = nil
        Bill.SaveBillsNow()
    end
end

function Bill.BillRefund(order_info)
    local ret = Database.updatebillorderstate(context.addr_db_user, order_info.orderid, order_info.state,
        BillDef.orderStatus.REFUND, true)
    if ret <= 0 then
        return order_info.state
    end
    order_info.state = BillDef.orderStatus.REFUND

    return order_info.state
end

function Bill.QueryOrder(orderid, transid)
    local order_form = {
        key = serverconf.STEAM_CONF.order_key,
        appid = serverconf.STEAM_CONF.appId,
        orderid = orderid,
        transid = transid,
    }
    local param_tbl = {}
    for k, v in pairs(order_form) do
        table.insert(param_tbl, string.format("%s=%s", escape(k), escape(v)))
    end
    local param_str = table.concat(param_tbl, "&")
    local get_url = serverconf.STEAM_CONF.query_order_url .. "?" .. param_str
    local response = httpc.get(get_url)
    print_r(response)
    local json_success, rsp_data = pcall(json.decode, response.body or "")
    return json_success, rsp_data
end

function Bill.PBGetBillsReqCmd(req)
    local bills = scripts.UserModel.GetBills()
    if not bills then
        return context.S2C(context.net_id, CmdCode.PBGetBillsRspCmd,
            { code = ErrorCode.ServerInternalError, error = "数据加载出错", uid = context.uid }, req.msg_context.stub_id)
    end

    Bill.CheckBillAmount(bills)

    local rsp_msg = {
        code = ErrorCode.None,
        error = "",
        uid = req.msg.uid,
        bills_data = bills,
    }
    return context.S2C(context.net_id, CmdCode.PBGetBillsRspCmd, rsp_msg, req.msg_context.stub_id)
end

function Bill.PBApplyBillOrderReqCmd(req)
    -- 参数验证
    if not req.msg.bill_id
        or not req.msg.bill_num
        or req.msg.bill_num <= 0 then
        return context.S2C(context.net_id, CmdCode.PBApplyBillOrderRspCmd, {
            code = ErrorCode.ParamInvalid,
            error = "无效请求参数",
            uid = context.uid,
        }, req.msg_context.stub_id)
    end

    local bills = scripts.UserModel.GetBills()
    if not bills then
        return context.S2C(context.net_id, CmdCode.PBGetBillsRspCmd,
            { code = ErrorCode.ServerInternalError, error = "数据加载出错", uid = context.uid }, req.msg_context.stub_id)
    end

    local bill_cfg = GameCfg.RechargeStoreConfig[req.msg.bill_id]
    if not bill_cfg then
        return context.S2C(context.net_id, CmdCode.PBApplyBillOrderRspCmd, {
            code = ErrorCode.BillIdInvalid,
            error = "充值ID错误",
            uid = context.uid,
        }, req.msg_context.stub_id)
    end

    if bills.on_order_id > 0 then
        return context.S2C(context.net_id, CmdCode.PBApplyBillOrderRspCmd, {
            code = ErrorCode.OnOrder,
            error = "当前有订单中",
            uid = context.uid,
            on_order_id = bills.on_order_id,
        }, req.msg_context.stub_id)
    end

    local res, err = clusterd.call(3999, "billmgr", "Billmgr.GetNowOrderId")
    if err or res <= 0 then
        return context.S2C(context.net_id, CmdCode.PBApplyBillOrderRspCmd, {
            code = ErrorCode.GetOrderIdFailed,
            error = "获取订单ID失败",
            uid = context.uid,
        }, req.msg_context.stub_id)
    end

    local query_user_attr = {}
    table.insert(query_user_attr, ProtoEnum.UserAttrType.plateform_id)
    local query_res = scripts.User.QueryUserAttr(query_user_attr)
    if not query_res.user_attr or not query_res.user_attr[ProtoEnum.UserAttrType.plateform_id] then
        return context.S2C(context.net_id, CmdCode.PBApplyBillOrderRspCmd, {
            code = ErrorCode.GetSteamIdFailed,
            error = "获取用户steamid失败",
            uid = context.uid,
        }, req.msg_context.stub_id)
    end
    local steamid = tonumber(query_res.user_attr[ProtoEnum.UserAttrType.plateform_id])
    local amount = req.msg.bill_num * bill_cfg.price

    local order_form = {
        key = serverconf.STEAM_CONF.order_key,
        orderid = res,
        steamid = steamid,
        appid = serverconf.STEAM_CONF.appId,
        itemcount = req.msg.bill_num,
        language = serverconf.STEAM_CONF.language,
        currency = serverconf.STEAM_CONF.currency,
        ['itemid[0]'] = req.msg.bill_id,
        ['qty[0]'] = req.msg.bill_num,
        ['amount[0]'] = amount,
        ['description[0]'] = steamsdk_conf.description,
    }
    local response = httpc.post(serverconf.STEAM_CONF.create_order_url, order_form)
    print_r(response)
    local json_success, rsp_data = pcall(json.decode, response.body or "")
    if not json_success then
        return context.S2C(context.net_id, CmdCode.PBApplyBillOrderRspCmd, {
            code = ErrorCode.OrderParsingFailed,
            error = "解析订单响应失败",
            uid = context.uid,
        }, req.msg_context.stub_id)
    end
    if rsp_data.response.result == 'OK' then
        local order_info = {
            orderid = tonumber(rsp_data.response.params.orderid),
            transid = tonumber(rsp_data.response.params.transid),
            steamid = steamid,
            uid = context.uid,
            bill_id = req.msg.bill_id,
            bill_num = req.msg.bill_num,
            bill_amount = amount,
            create_ts = moon.time(),
            is_sandbox = 0,
            state = BillDef.orderStatus.WAIT,
        }
        local ret_rows = Database.addbillorder(context.addr_db_user, order_info)
        if ret_rows <= 0 then
            return context.S2C(context.net_id, CmdCode.PBApplyBillOrderRspCmd, {
                code = ErrorCode.AddOrderFailed,
                error = "添加订单失败",
                uid = context.uid,
            }, req.msg_context.stub_id)
        end

        bills.on_order_id = order_info.orderid
        Bill.on_order_info = order_info
        clusterd.send(3999, "billmgr", "Billmgr.AddBill", order_info)
        Bill.SaveBillsNow()

        return context.S2C(context.net_id, CmdCode.PBApplyBillOrderRspCmd, {
            code = ErrorCode.None,
            error = "",
            uid = context.uid,
            on_order_id = order_info.orderid,
        }, req.msg_context.stub_id)
    else
        return context.S2C(context.net_id, CmdCode.PBApplyBillOrderRspCmd, {
            code = ErrorCode.CreateOrderFailed,
            error = "创建订单失败",
            uid = context.uid,
        }, req.msg_context.stub_id)
    end
end

function Bill.PBCheckBillOrderReqCmd(req)
    -- 参数验证
    if not req.msg.on_order_id then
        return context.S2C(context.net_id, CmdCode.PBCheckBillOrderRspCmd, {
            code = ErrorCode.ParamInvalid,
            error = "无效请求参数",
            uid = context.uid,
        }, req.msg_context.stub_id)
    end

    local bills = scripts.UserModel.GetBills()
    if not bills then
        return context.S2C(context.net_id, CmdCode.PBCheckBillOrderRspCmd,
            { code = ErrorCode.ServerInternalError, error = "数据加载出错", uid = context.uid }, req.msg_context.stub_id)
    end

    if bills.on_order_id ~= req.msg.on_order_id
        or not Bill.on_order_info
        or Bill.on_order_info.orderid ~= req.msg.on_order_id then
        if Bill.on_order_info.orderid ~= bills.on_order_id then
            bills.on_order_id = Bill.on_order_info.orderid
            Bill.SaveBillsNow()
        end
        return context.S2C(context.net_id, CmdCode.PBCheckBillOrderRspCmd, {
            code = ErrorCode.OrderNotFound,
            error = "订单不存在",
            uid = context.uid,
            on_order_id = req.msg.on_order_id,
        }, req.msg_context.stub_id)
    end

    local ret_status = Bill.on_order_info.state
    local json_success, rsp_data = Bill.QueryOrder(bills.on_order_id, Bill.on_order_info.transid)
    if not json_success then
        return context.S2C(context.net_id, CmdCode.PBCheckBillOrderRspCmd, {
            code = ErrorCode.OrderParsingFailed,
            error = "解析订单响应失败",
            uid = context.uid,
            on_order_id = req.msg.on_order_id,
        }, req.msg_context.stub_id)
    else
        if rsp_data.response.result == 'OK' then
            if rsp_data.response.params.status == 'Approved' then
                Bill.on_order_info.state = BillDef.orderStatus.WAIT
                ret_status = Bill.on_order_info.state
            elseif rsp_data.response.params.status == 'Succeeded' then
                clusterd.send(3999, "billmgr", "Billmgr.DelBill", bills.on_order_id)
                local bill_cfg = GameCfg.RechargeStoreConfig[Bill.on_order_info.bill_id]
                if not bill_cfg then
                    return context.S2C(context.net_id, CmdCode.PBCheckBillOrderRspCmd, {
                        code = ErrorCode.BillIdInvalid,
                        error = "充值ID错误",
                        uid = context.uid,
                        on_order_id = req.msg.on_order_id,
                        order_state = ret_status,
                    }, req.msg_context.stub_id)
                end
                ret_status = Bill.BillDeliver(Bill.on_order_info, bill_cfg) -- 充值成功,发货
                if Bill.on_order_info.state == BillDef.orderStatus.DONE then
                    Bill.AddBillAmount(bills, Bill.on_order_info, bill_cfg)
                end
            elseif rsp_data.response.params.status == 'Failed' then
                clusterd.send(3999, "billmgr", "Billmgr.DelBill", bills.on_order_id)
                ret_status = Bill.BillFailed(Bill.on_order_info) -- 充值失败,记录失败
            elseif rsp_data.response.params.status == 'Refunded'
                or rsp_data.response.params.status == 'PartialRefund'
                or rsp_data.response.params.status == 'Chargedback'
                or rsp_data.response.params.status == 'RefundedSuspectedFraud'
                or rsp_data.response.params.status == 'RefundedFriendlyFraud' then
                -- 订单已退款
                -- 购物车中的一个或多个物品已退款
                -- 订单存在欺诈或争议
                -- 因涉嫌欺诈,该订单已被 Valve 退款
                -- 因被认定为友好欺诈,该订单已被 Valve 退款
                clusterd.send(3999, "billmgr", "Billmgr.DelBill", bills.on_order_id)
                ret_status = Bill.BillRefund(Bill.on_order_info) -- 充值退款,记录退款
            else
                moon.error("PBCheckBillOrderReqCmd 未知订单状态: " .. rsp_data.response.params.status)
            end
        end
    end
    
    if Bill.on_order_info.state == BillDef.orderStatus.DONE
        or Bill.on_order_info.state == BillDef.orderStatus.FAIL
        or Bill.on_order_info.state == BillDef.orderStatus.CLOSE
        or Bill.on_order_info.state == BillDef.orderStatus.REFUND then
        bills.on_order_id = 0
        Bill.on_order_info = nil
        Bill.SaveBillsNow()
    end
    
    return context.S2C(context.net_id, CmdCode.PBCheckBillOrderRspCmd, {
        code = ErrorCode.None,
        error = "",
        uid = context.uid,
        on_order_id = req.msg.on_order_id,
        order_state = ret_status,
    }, req.msg_context.stub_id)
end

return Bill
