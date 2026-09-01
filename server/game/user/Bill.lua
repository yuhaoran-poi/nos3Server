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

-- 模块级 in-memory cache, 用于避免 PBCheckBillOrderReqCmd 等场景下重复
-- Database.loadbillorder 的 RPC 调用. 因为 service_user 是 per-user 多协程
-- 模型, 跨协程访问需通过下列 helper 走 CAS 通道, 不可直接读/写.

---@param expected_orderid? integer 若提供, 则只在 on_order_info.orderid 匹配时返回
---@return table|nil 当前订单引用或 nil
function Bill.GetCurrentOrder(expected_orderid)
    local cur = Bill.on_order_info
    if not cur then return nil end
    if expected_orderid ~= nil and cur.orderid ~= expected_orderid then
        return nil
    end
    return cur
end

---@param order_info table|nil 要写入的订单引用, nil 表示清空
---@param expected_orderid? integer 若提供, 仅在当前 on_order_info.orderid 匹配时覆盖
---@return boolean 是否成功写入
function Bill.SetCurrentOrder(order_info, expected_orderid)
    if expected_orderid ~= nil then
        local cur = Bill.on_order_info
        if not cur or cur.orderid ~= expected_orderid then
            return false   -- 已被其他协程改动, 拒绝覆盖
        end
    end
    Bill.on_order_info = order_info
    return true
end

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
        moon.error("uid DealOnOrder 未知订单: ", context.uid, bills.on_order_id)
        bills.on_order_id = 0
        return
    end

    if order_info.state ~= BillDef.orderStatus.WAIT
        and order_info.state ~= BillDef.orderStatus.PAID then
        moon.error("uid DealOnOrder orderid 订单状态错误: ", context.uid, bills.on_order_id, order_info.state)
        bills.on_order_id = 0
        return
    end
    
    local json_success, rsp_data = Bill.QueryOrder(bills.on_order_id, order_info.transid)
    if not json_success then
        moon.error("uid DealOnOrder 查询订单失败: ", context.uid, rsp_data)
        return
    else
        if rsp_data.response.result == 'OK' then
            if rsp_data.response.params.status == 'Init' then
                order_info.state = BillDef.orderStatus.WAIT
                Bill.SetCurrentOrder(order_info, order_info.orderid)
                clusterd.send(3999, "billmgr", "Billmgr.AddBill", order_info)
                return

            elseif rsp_data.response.params.status == 'Approved' then
                Bill.FinalizeOrder(order_info.orderid)

                order_info.state = BillDef.orderStatus.WAIT
                Bill.SetCurrentOrder(order_info, order_info.orderid)
                clusterd.send(3999, "billmgr", "Billmgr.UpdateBill", order_info)
                return

            elseif rsp_data.response.params.status == 'Succeeded' then
                clusterd.send(3999, "billmgr", "Billmgr.DelBill", bills.on_order_id)
                local bill_cfg = GameCfg.RechargeStoreConfig[order_info.bill_id]
                if not bill_cfg then
                    moon.error("uid DealOnOrder 未知充值配置: ", context.uid, order_info.bill_id)
                    bills.on_order_id = 0
                    Bill.SetCurrentOrder(nil, order_info.orderid)
                    Bill.SaveBillsNow()
                    return
                end
                local ret_status = Bill.BillDeliver(order_info, bill_cfg) -- 充值成功,发货
                if ret_status == BillDef.orderStatus.DONE then
                    Bill.AddBillAmount(bills, order_info, bill_cfg)
                end
                bills.on_order_id = 0
                Bill.SetCurrentOrder(nil, order_info.orderid)
                Bill.SaveBillsNow()

            elseif rsp_data.response.params.status == 'Failed' then
                clusterd.send(3999, "billmgr", "Billmgr.DelBill", bills.on_order_id)
                Bill.BillFailed(order_info) -- 充值失败,记录失败
                bills.on_order_id = 0
                Bill.SetCurrentOrder(nil, order_info.orderid)
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
                Bill.BillRefund(order_info) -- 充值退款,记录退款
                bills.on_order_id = 0
                Bill.SetCurrentOrder(nil, order_info.orderid)
                Bill.SaveBillsNow()

            else
                moon.error("uid DealOnOrder 未知订单状态: ", context.uid, rsp_data.response.params.status)
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
    -- if not datetime.is_same_year(bills.update_ts, now_ts) then
    --     bills.year_bill_amount = 0
    --     is_change = true
    -- end
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
    if datetime.is_same_day(order_info.create_ts, now_ts) then
        bills.day_bill_amount = bills.day_bill_amount + amount_record
    end
    if datetime.is_same_week(order_info.create_ts, now_ts) then
        bills.week_bill_amount = bills.week_bill_amount + amount_record
    end
    if datetime.is_same_month(order_info.create_ts, now_ts) then
        bills.month_bill_amount = bills.month_bill_amount + amount_record
    end
    -- if datetime.is_same_year(order_info.create_ts, now_ts) then
    --     bills.year_bill_amount = bills.year_bill_amount + amount_record
    -- end
    bills.total_bill_amount = bills.total_bill_amount + amount_record
    -- 触发充值金额
    scripts.Mission.TriggerCondition(MissionDef.EConditionIds.RECHARGE_CNT, {}, amount_record)
    -- 触发累计充值金额
    scripts.Mission.TriggerCondition(MissionDef.EConditionIds.TOTAL_RECHARGE_CNT, {}, bills.total_bill_amount)

    context.S2C(context.net_id, CmdCode.PBBillDoneSyncCmd, {
        bill_id = order_info.bill_id,
        bill_num = order_info.bill_num,
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

    -- 单次调用 GetCurrentOrder, 走 CAS 通道, 拿到稳定引用
    local cur_order_info = Bill.GetCurrentOrder(order_info.orderid)
    if not cur_order_info
        or cur_order_info.state ~= BillDef.orderStatus.WAIT then
        return false
    end

    -- cur_order_info 与 Bill.on_order_info 是同一张表 (lua 引用语义).
    -- 此处修改 state 也等价于修改 Bill.on_order_info.state, 因此 SetCurrentOrder
    -- 不需要重新设引用. 后续 Bill.BillDeliver 内部 yield 期间, 其他协程
    -- 也只能通过 helper 改 Bill.on_order_info (CAS 校验 orderid), 不会
    -- 污染我们的状态语义.
    cur_order_info.state = BillDef.orderStatus.PAID
    local ret = Bill.BillDeliver(cur_order_info, bill_cfg)
    if ret == BillDef.orderStatus.DONE then
        Bill.AddBillAmount(bills, cur_order_info, bill_cfg)
        bills.on_order_id = 0
        -- CAS 清: 只在还是我的时候才清
        Bill.SetCurrentOrder(nil, order_info.orderid)
    end
    -- 失败分支: 不需要 else 恢复, 因为 cur_order_info.state 已经被
    -- Bill.BillDeliver 写成 WAIT/原 state, 下次 OnBillFailed/Paid 还会
    -- 通过 helper 看到 (CAS 校验 orderid 仍匹配).
end

function Bill.BillDeliver(order_info, bill_cfg)
    local old_state = order_info.state
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

        Database.updatebillorderstate(context.addr_db_user, order_info.orderid, order_info.state, old_state, true)
        order_info.state = old_state
        return order_info.state
    end
    scripts.Bag.SaveAndLog(bag_change_log, ItemDef.ChangeReason.Bill)

    return order_info.state
end

function Bill.OnBillFailed(order_info)
    local bills = scripts.UserModel.GetBills()
    if not bills then
        return false
    end

    local cur_order_info = Bill.GetCurrentOrder(order_info.orderid)
    if not cur_order_info then
        return false
    end

    cur_order_info.state = BillDef.orderStatus.FAIL
    bills.on_order_id = 0
    Bill.SetCurrentOrder(nil, order_info.orderid)
    Bill.SaveBillsNow()
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

    local cur_order_info = Bill.GetCurrentOrder(order_info.orderid)
    if not cur_order_info then
        return false
    end

    cur_order_info.state = BillDef.orderStatus.REFUND
    bills.on_order_id = 0
    Bill.SetCurrentOrder(nil, order_info.orderid)
    Bill.SaveBillsNow()
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
    local use_url = serverconf.STEAM_CONF.query_order_url
    if serverconf.STEAM_CONF.is_sandbox and serverconf.STEAM_CONF.is_sandbox == 1 then
        use_url = serverconf.STEAM_CONF.sandbox_query_order_url
    end
    local get_url = use_url .. "?" .. param_str
    local ok, response = pcall(httpc.get, get_url)
    if not ok or not response then
        moon.error(string.format("Bill query_order http failed: %s", tostring(response)))
        return false, nil
    end
    print_r(response)
    local json_success, rsp_data = pcall(json.decode, response.body or "")
    return json_success, rsp_data
end

function Bill.FinalizeOrder(orderid)
    local order_form = {
        key = serverconf.STEAM_CONF.order_key,
        orderid = orderid,
        appid = serverconf.STEAM_CONF.appId,
    }
    local use_url = serverconf.STEAM_CONF.finish_order_url
    if serverconf.STEAM_CONF.is_sandbox and serverconf.STEAM_CONF.is_sandbox == 1 then
        use_url = serverconf.STEAM_CONF.sandbox_finish_order_url
    end
    local response_ok, response = pcall(httpc.post_form, use_url, order_form)
    if not response_ok or not response then
        moon.error(string.format("Bill FinalizeOrder http failed: %s", tostring(response)))
        return false
    end
    print_r(response)
    local json_success, rsp_data = pcall(json.decode, response.body or "")
    if not json_success then
        moon.error(string.format("Bill FinalizeOrder json decode failed: %s", tostring(rsp_data)))
        return false
    end

    if rsp_data.response.result == 'OK' then
        return true
    end
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
        ['description[0]'] = bill_cfg.description or "test bill",
    }
    local use_url = serverconf.STEAM_CONF.create_order_url
    if serverconf.STEAM_CONF.is_sandbox and serverconf.STEAM_CONF.is_sandbox == 1 then
        use_url = serverconf.STEAM_CONF.sandbox_create_order_url
    end
    local response_ok, response = pcall(httpc.post_form, use_url, order_form)
    if not response_ok or not response then
        moon.error(string.format("Bill create_order http failed: %s", tostring(response)))
        return context.S2C(context.net_id, CmdCode.PBApplyBillOrderRspCmd, {
            code = ErrorCode.OrderCreateFailed,
            error = "支付服务暂时不可用,请稍后重试",
            uid = context.uid,
        }, req.msg_context.stub_id)
    end
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
            is_sanbox = serverconf.STEAM_CONF.is_sandbox or 0,
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
        Bill.SetCurrentOrder(order_info, nil)   -- 首次写入, 无需 CAS
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

    local cur_order_info = Bill.GetCurrentOrder(req.msg.on_order_id)
    if not cur_order_info
        or bills.on_order_id ~= req.msg.on_order_id then
        -- on_order_info 与 bills.on_order_id 不一致时, 尝试同步回 bills
        if cur_order_info and cur_order_info.orderid ~= bills.on_order_id then
            bills.on_order_id = cur_order_info.orderid
            Bill.SaveBillsNow()
        end
        return context.S2C(context.net_id, CmdCode.PBCheckBillOrderRspCmd, {
            code = ErrorCode.OrderNotFound,
            error = "订单不存在",
            uid = context.uid,
            on_order_id = req.msg.on_order_id,
        }, req.msg_context.stub_id)
    end

    local ret_status = cur_order_info.state
    local json_success, rsp_data = Bill.QueryOrder(bills.on_order_id, cur_order_info.transid)
    if not json_success then
        return context.S2C(context.net_id, CmdCode.PBCheckBillOrderRspCmd, {
            code = ErrorCode.OrderParsingFailed,
            error = "解析订单响应失败",
            uid = context.uid,
            on_order_id = req.msg.on_order_id,
        }, req.msg_context.stub_id)
    else
        if rsp_data.response.result == 'OK' then
            if rsp_data.response.params.status == 'Init' then
                cur_order_info.state = BillDef.orderStatus.WAIT
                ret_status = cur_order_info.state

            elseif rsp_data.response.params.status == 'Approved' then
                Bill.FinalizeOrder(cur_order_info.orderid)

                cur_order_info.state = BillDef.orderStatus.WAIT
                ret_status = cur_order_info.state

            elseif rsp_data.response.params.status == 'Succeeded' then
                clusterd.send(3999, "billmgr", "Billmgr.DelBill", bills.on_order_id)
                local bill_cfg = GameCfg.RechargeStoreConfig[cur_order_info.bill_id]
                if not bill_cfg then
                    return context.S2C(context.net_id, CmdCode.PBCheckBillOrderRspCmd, {
                        code = ErrorCode.BillIdInvalid,
                        error = "充值ID错误",
                        uid = context.uid,
                        on_order_id = req.msg.on_order_id,
                        order_state = ret_status,
                    }, req.msg_context.stub_id)
                end
                ret_status = Bill.BillDeliver(cur_order_info, bill_cfg) -- 充值成功,发货
                if cur_order_info.state == BillDef.orderStatus.DONE then
                    Bill.AddBillAmount(bills, cur_order_info, bill_cfg)
                end

            elseif rsp_data.response.params.status == 'Failed' then
                clusterd.send(3999, "billmgr", "Billmgr.DelBill", bills.on_order_id)
                ret_status = Bill.BillFailed(cur_order_info) -- 充值失败,记录失败

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
                ret_status = Bill.BillRefund(cur_order_info) -- 充值退款,记录退款

            else
                moon.error("PBCheckBillOrderReqCmd 未知订单状态: " .. rsp_data.response.params.status)
            end
        end
    end
    
    if cur_order_info.state == BillDef.orderStatus.DONE
        or cur_order_info.state == BillDef.orderStatus.FAIL
        or cur_order_info.state == BillDef.orderStatus.CLOSE
        or cur_order_info.state == BillDef.orderStatus.REFUND then
        bills.on_order_id = 0
        -- CAS 清: 只在 on_order_info 还指向本订单时才清
        Bill.SetCurrentOrder(nil, cur_order_info.orderid)
        Bill.SaveBillsNow()
    else
        -- CAS 恢复: 只在还没被其他协程改写时才写回
        Bill.SetCurrentOrder(cur_order_info, cur_order_info.orderid)
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
