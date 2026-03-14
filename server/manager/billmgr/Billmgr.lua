local moon = require("moon")
local socket = require("moon.socket")
local common = require("common")
local CmdCode = common.CmdCode
local GameCfg = common.GameCfg --游戏配置
local Database = common.Database
local ErrorCode = common.ErrorCode
local lock_bill_check = require("moon.queue")()
local httpc = require("moon.http.client")
local json = require("json")
local crypt = require("crypt")
local protocol = require("common.protocol_pb")
local ProtoEnum = require("tools.ProtoEnum")
local UserAttrLogic = require("common.logic.UserAttrLogic")
local BillDef = require("common.def.BillDef")
local jencode = json.encode
local jdecode = json.decode

---@type billmgr_context
local context = ...

local listenfd

local function escape(s)
    return (string.gsub(s, "([^A-Za-z0-9_])", function(c)
        return string.format("%%%02X", string.byte(c))
    end))
end

---@class Billmgr
local Billmgr = {
    now_order_id = 0,
    on_order_infos = {},
}

function Billmgr.Init()
    -- -- 新增定时器轮询
    moon.async(function()
        while true do
            moon.sleep(5000) -- 每5秒检查一次
            Billmgr.CheckOrder()
        end
    end)

    return true
end

function Billmgr.Start()
    Billmgr.now_order_id = Database.getmaxorderid(context.addr_db_game)
    if Billmgr.now_order_id < 0 then
        moon.error("Billmgr.Start getmaxorderid failed")
        return
    end
    if Billmgr.now_order_id == 0 then
        Billmgr.now_order_id = 1
    end
    return true
end

function Billmgr.CheckOrder()
    local scope <close> = lock_bill_check()

    local now_ts = moon.time()
    local del_orderids = {}
    for orderid, check_data in pairs(Billmgr.on_order_infos) do
        if check_data.check_ts == 0 or now_ts - check_data.check_ts >= 20 then
            -- 查询订单状态
            local order_form = {
                key = steamsdk_conf.order_key,
                appid = steamsdk_conf.appId,
                orderid = check_data.order_info.orderid,
                transid = check_data.order_info.transid,
            }
            local param_tbl = {}
            for k, v in pairs(order_form) do
                table.insert(param_tbl, string.format("%s=%s", escape(k), escape(v)))
            end
            local param_str = table.concat(param_tbl, "&")
            local get_url = steamsdk_conf.query_order_url .. "?" .. param_str
            local response = httpc.get(get_url)
            print_r(response)
            local json_success, rsp_data = pcall(json.decode, response.body or "")
            if json_success and rsp_data and rsp_data.response.result == 'OK' then
                if rsp_data.response.params.status == 'Approved' then
                    moon.info("Billmgr.CheckOrder orderid = %s, status = %s", orderid, rsp_data.response.params.status)
                elseif rsp_data.response.params.status == 'Succeeded' then
                    if check_data.order_info.state == BillDef.orderStatus.WAIT then
                        local ret = Database.updatebillorderstate(context.addr_db_user, check_data.order_info.orderid,
                            check_data.order_info.state, BillDef.orderStatus.PAID, true)
                        if ret > 0 then
                            check_data.order_info.state = BillDef.orderStatus.PAID
                            context.send_user(check_data.order_info.uid, "Bill.OnBillPaid", check_data.order_info)
                        end
                    end
                    table.insert(del_orderids, orderid)
                elseif rsp_data.response.params.status == 'Failed' then
                    Database.updatebillorderstate(context.addr_db_user, check_data.order_info.orderid,
                        check_data.order_info.state, BillDef.orderStatus.FAIL, false)
                    context.send_user(check_data.order_info.uid, "Bill.OnBillFailed", check_data.order_info)
                    table.insert(del_orderids, orderid)
                elseif rsp_data.response.params.status == 'Refunded'
                    or rsp_data.response.params.status == 'PartialRefund'
                    or rsp_data.response.params.status == 'Chargedback'
                    or rsp_data.response.params.status == 'RefundedSuspectedFraud'
                    or rsp_data.response.params.status == 'RefundedFriendlyFraud' then
                    Database.updatebillorderstate(context.addr_db_user, check_data.order_info.orderid,
                        check_data.order_info.state, BillDef.orderStatus.REFUND, true)
                    context.send_user(check_data.order_info.uid, "Bill.OnBillRefund", check_data.order_info)
                    table.insert(del_orderids, orderid)
                end
            end
        end
    end
end

function Billmgr.GetNowOrderId()
    local ret_id = Billmgr.now_order_id
    Billmgr.now_order_id = Billmgr.now_order_id + 1
    return ret_id
end

function Billmgr.AddBill(order_info)
    local scope <close> = lock_bill_check()

    Billmgr.on_order_infos[order_info.orderid] = { order_info = order_info, check_ts = moon.time() }
end

function Billmgr.DelBill(orderid)
    local scope <close> = lock_bill_check()

    Billmgr.on_order_infos[orderid] = nil
end

function Billmgr.Shutdown()
    -- for _, n in pairs(context.rooms) do
    --     socket.close(n.fd)
    -- end
    if listenfd then
        socket.close(listenfd)
    end
    moon.quit()
    return true
end

return Billmgr
