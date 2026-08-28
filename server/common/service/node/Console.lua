local moon = require("moon")
local json = require("json")
local fs = require("fs")
local datetime = require("moon.datetime")
local sharetable = require("sharetable")
local clusterd = require("cluster")
local ChatLogic = require("common.logic.ChatLogic") --聊天逻辑
local MailLogic = require("common.logic.MailLogic")
local TradeDef = require("common.def.TradeDef")
-- local GameCfg = require("common.cfg.GameCfg")

---@type node_context
local context = ...

local NODEID = math.tointeger(moon.env("NODE"))
local THREAD_NUM = math.tointeger(moon.env("THREAD_NUM"))

local static_tables_md5 = {}

local function Response(code, message, data)
	return json.encode({ code = code, message = message, data = data })
end

local function ResponseV2(res, err)
	if res == false then
		return json.encode({ code = -1, message = err, data = err })
	end
	return json.encode({ code = 0, data = res })
end

---@class Console
local Console = {}

function Console.Init()
    static_tables_md5 = Console.table_md5()
    return true
end

function Console.Notify_nodemgr(nodeinfo)
    local res, err = clusterd.call(3999, "nodemgr", "Nodemgr.BindNode", nodeinfo)
    print("Notify_nodemgr", res.error, err)
	if res.error == "success" then
		return true-- body
    else
		return false
	end
end

local help = [[
param '<>' means require
param '()' means optional

Gloabl command format:S<nodeid> command params. e. S1 help
Command List:
	tstate:                            Get worker thread state.
	list:                              List all services.
	quit <address>:                    Force close the specificed service.
	time:                              Print current server's time.
	adjtime <seconds>:                 Forward adjust server time in seconds.
	settime <Y-M-D H:M:S>:             Forward set server time.
	next_hour:                         Forward adjust server time to next hour.
	loglevel <LEVEL>:                  Set log level 'DEBUG','INFO','WARN','ERROR'.
	gc:                                Let all services run gc.
	state:                             List all services's state.
	mem:                               List all services's lua memory.
	ping <address> :                   Ping the specificed service.
	reload:                            Reload static table files.
	syschat:                           Send system chat to all online users.
	add_account_exp:                   Add account exp to users.
	add_items:                         Add items to users.
	send_system_mail:                  Send system mail to users.
	cancel_system_mail:                Cancel system mail to users.
	add_treasure_box:                  Add treasure box to users.
	add_trade_product:                 Add trade product to users.
	hotfix <servicename> <filename_no_path_no_ext_1> <filename_no_path_no_ext_2>....: Hotfix script file. e. S1 hotfix user Hello
	queryservice <name>:               Query service address by name. e. S1 queryservice roommgr

User command format:     U<uid> command params
Command List:
	syschat <msg_content> <msg_attach> #发送系统聊天. syschat 你好 这是聊天附件字符串
	addscore <uid> <count> #增加积分. 1234567 999 给玩家1234567增加999积分
	add_account_exp <uid> <count> #增加账号经验. 1234567 999 给玩家1234567增加999账号经验
	add_items <uid> <config_id> <item_count> #增加物品. 1234567 30001 2 给玩家1234567增加2个30001物品
	send_system_mail <uid> <send_info_str> #给玩家发系统邮件. 1234567 send_system_mail mail_info 给玩家1234567发系统邮件mail_info
	cancel_system_mail <uid> <mail_id> #撤销系统邮件. 1234567 cancel_system_mail 12345 给玩家1234567撤销系统邮件12345
	add_treasure_box <uid> <config_id> <item_count> #给玩家加宝箱. 1234567 30001 2 给玩家1234567加2个30001宝箱
	add_trade_product <sale_config_id> <sale_num> <sale_price> <sale_ts> #添加交易行商品. 10001 10 100 3600 添加交易行商品10001,10个,单价100元,3600秒有效
	close_start_game <close_reason> #关闭游戏开始. close_start_game 关闭游戏
	open_start_game <open_reason> #打开游戏开始. open_start_game 打开游戏
	add_grade_score <uid> <count> #增加段位积分. 1234567 999 给玩家1234567增加999段位积分
	]]

function Console.help()
    return help
end

-- 发送系统聊天
function Console.syschat(msg_content, msg_attach)
    ChatLogic.SendMsgToSystemChannel(msg_content, msg_attach)
    return Response(0, "OK", { msg_content = msg_content, msg_attach = msg_attach })
end

---热更某个服务目录下的脚本
function Console.hotfix(sname, ...)
	local modlist = { ... }
	if #modlist == 0 then
		return string.format("server %d hotfix failed, empty file list", NODEID)
	end

	local fixlist = {}
	for _, modname in ipairs(modlist) do
		local filepath = string.format("game/%s/%s.lua", sname, modname)
		local content, err = io.readfile(filepath)
		if not content then
			return string.format("server %d hotfix %s failed, %s", NODEID, filepath, tostring(err))
		end
		fixlist[modname] = filepath
		moon.env(filepath, content)
	end

	if sname == "user" then
		moon.send("lua", moon.queryservice("auth"), "hotfix", fixlist)
	else
		moon.send("lua", moon.queryservice(sname), "hotfix", fixlist)
	end
	return Response(0, "OK", modlist)
end

function Console.table_md5()
	local res = {}
	local list = fs.listdir("static/table")
	for _, file in ipairs(list) do
		if not fs.isdir(file) then
			local name = fs.stem(file)
			local md5str = moon.md5(io.readfile(file))
			res[name] = md5str
		end
	end
	return res
end

---更新配表,新表覆盖旧表后,执行这个命令
function Console.reload(...)
	local names = { ... }
	if #names == 0 then
		local tmp = Console.table_md5()
		for name, md5 in pairs(static_tables_md5) do
			local newmd5 = tmp[name]
			if md5 ~= newmd5 then
				table.insert(names, name)
			end
		end
		static_tables_md5 = tmp
	end

	local res = {}
	if #names > 0 then
		local all_ok = true
		for k, name in ipairs(names) do
			local filename = name .. ".lua"
			names[k] = filename
			local ok, err = sharetable.loadfile(filename)
			if ok then
				table.insert(res, string.format("%s(success)", name))
			else
				table.insert(res, string.format("%s(failed,%s)", name, tostring(err)))
				all_ok = false
				break
			end
		end

		if all_ok then
			local clients = sharetable.clients()
			for _, v in ipairs(clients) do
				moon.send("lua", v, "reload", names)
			end
		end
	end
	return string.format("server %d reload (count %d): %s", NODEID, #res, table.concat(res, " "))
end

local last_tstate_time = moon.clock()
function Console.tstate()
	local info = moon.server_stats()
	local t = json.decode(info)
	local res = {}
	for i, one in ipairs(t) do
		if one.id > 0 then
			local cpu = 100 * (one.cpu / (moon.clock() - last_tstate_time))
			one.cpu = string.format("%.02f", cpu)
		end
		res[#res + 1] = json.encode(one) .. "\n"
	end
	last_tstate_time = moon.clock()
	return table.concat(res)
end

function Console.queryservice(name)
	return string.format("%08X", moon.queryservice(name))
end

function Console.list()
	local num = THREAD_NUM
	local response = {}
	for i = 1, num do
		local s = json.decode(moon.scan_services(i))
		if s then
			for _, v in pairs(s) do
				table.insert(response, json.encode(v))
			end
		end
	end
	return table.concat(response, "\n")
end

function Console.quit(address)
	address = tonumber(address, 16)
	moon.kill(address)
	return true
end

function Console.time()
	return os.date("%Y-%m-%d %H:%M:%S", moon.time())
end

function Console.adjtime(offset)
	offset = math.tointeger(offset)
	if not offset or offset <= 0 then
		return "failed"
	end

	if moon.adjtime(offset * 1000) then
		return "ok"
	else
		return false, "failed: time can not rollback " .. offset
	end
end

function Console.settime(YMD, HMS)
	local strtime = YMD .. " " .. HMS
	local tm = datetime.parse(strtime)
	local t = os.time(tm)
	local now = moon.time()
	local delta = t - now
	if moon.adjtime(delta * 1000) then
		return "ok"
	else
		return false, "failed: time can not rollback " .. strtime
	end
end

function Console.next_hour()
	local diff = 3600000 - moon.now() % 3600000
	moon.adjtime(diff)
	return tostring(diff)
end

function Console.loglevel(lv)
	moon.loglevel(lv)
	return lv
end

function Console.gc(addr)
	if addr then
		local res, err = moon.call("debug", tonumber(addr, 16), "gc")
		if not res then
			return string.format("error(%s)", tostring(err))
		else
			return string.format("%s Kb", tostring(res))
		end
	else
		local num = THREAD_NUM
		local total = 0
		for i = 1, num do
			local services = json.decode(moon.scan_services(i))
			if services then
				for _, s in pairs(services) do
					local res, err = moon.call("debug", tonumber(s.serviceid, 16), "gc")
					if not res then
						print("error: ", err)
					else
						total = total + res
					end
				end
			end
		end
		return string.format("%.2f Kb", total)
	end
end

function Console.state(addr)
	if addr then
		local state, err = moon.call("debug", tonumber(addr, 16), "state")
		if not state then
			return string.format("error(%s)", err)
		else
			return state
		end
	else
		local num = THREAD_NUM
		local res = {}
		for i = 1, num do
			local services = json.decode(moon.scan_services(i))
			if services then
				for _, s in ipairs(services) do
					local state, err = moon.call("debug", tonumber(s.serviceid, 16), "state")
					if not state then
						s.state = string.format("error(%s)", err)
					else
						s.state = state
					end
					table.insert(res, json.encode(s))
				end
			end
		end
		return table.concat(res, "\n")
	end
end

function Console.mem(addr)
	if addr then
		local kb, err = moon.call("debug", tonumber(addr, 16), "mem")
		if not kb then
			return string.format("err (%s)", err)
		else
			return string.format("%.2f Kb", kb)
		end
	else
		local num = THREAD_NUM
		local res = {}
		for i = 1, num do
			local services = json.decode(moon.scan_services(i))
			if services then
				for _, s in pairs(services) do
					local kb, err = moon.call("debug", tonumber(s.serviceid, 16), "mem")
					if not kb then
						s.mem = string.format("err (%s)", err)
					else
						s.mem = string.format("%.2f Kb", kb)
					end
					table.insert(res, json.encode(s))
				end
			end
		end
		return table.concat(res, "\n")
	end
end

function Console.addscore(uid, count)
	local ok, err = context.call_user(uid, "User.AddScore", count)
	if not ok then
		return Response(-1, "Failed", err)
	end
	return Response(0, "OK")
end

function Console.addmail(uid, mail_key)
    local ok, err = moon.call("lua", context.addr_mail, "Mail.AddMail", uid, {
        mail_key = mail_key,
        flag = 0,
        rewards = {
            { id = 10001, count = 1 },
            { id = 10002, count = 2 },
        },
    })
    return ResponseV2(ok, err)
end

function Console.send_system_mail(send_info_str)
    local ok, info = MailLogic.DealSystemMail(send_info_str)
    moon.info("Console.send_system_mail ok: %s, info: %s", ok, info)
    if ok then
        local res, err = clusterd.call(3999, "mailmgr", "Mailmgr.AddSystemMail", info)
        if err then
            return Response(444, err, send_info_str)
        end

        if res.success then
            return Response(0, "OK", res.id)
        else
            return Response(444, "Failed", res.id)
        end
    else
        return Response(444, info, send_info_str)
    end
end

function Console.cancel_system_mail(cancel_id_str)
	local cancel_id = tonumber(cancel_id_str)
    if not cancel_id then
        return Response(444, "Failed", cancel_id_str)
    end
	
	local res, err = clusterd.call(3999, "mailmgr", "Mailmgr.InvalidSystemMail", cancel_id)
    if err then
        return Response(444, err, cancel_id_str)
    end

	if res then
		return Response(0, "OK")
	else
		return Response(444, "Failed", cancel_id_str)
	end
end

function Console.add_account_exp(uid, add_exp)
	add_exp = math.tointeger(add_exp)
    local res, err = context.call_user(uid, "User.GMAddAccountExp", add_exp)
    if err then
        return Response(444, err, string.format("%d %d", uid, add_exp))
    end

    if res then
		return Response(0, "OK")
    else
		return Response(444, "Failed", string.format("%d %d", uid, add_exp))
	end
end

function Console.add_items(uid, config_id, item_count)
    local item_simple = {
        config_id = config_id,
        item_count = item_count,
        uniqid = 0
    }
    local items = {}
    table.insert(items, item_simple)
    local res, err = context.call_user(uid, "User.DsAddItems", items)
    if err then
        return Response(444, err, string.format("%d %d, %d", uid, config_id, item_count))
    end

    if res then
        return Response(0, "OK")
    else
        return Response(444, "Failed", string.format("%d %d, %d", uid, config_id, item_count))
    end
end

function Console.add_treasure_box(uid, config_id, item_count)
	local res, err = context.call_user(uid, "Shop.AddTreasure", config_id, item_count)
	if err then
		return Response(444, err, string.format("%d %d, %d", uid, config_id, item_count))
	end

	if res then
		return Response(0, "OK")
	else
		return Response(444, "Failed", string.format("%d %d, %d", uid, config_id, item_count))
	end
end

function Console.add_trade_product(sale_config_id, sale_num, sale_price, sale_ts)
    local product_data = TradeDef.newTradeProductBaseData()
    product_data.trade_id = 1
    product_data.seller_uid = 0
    product_data.config_id = sale_config_id
    product_data.total_num = sale_num
    product_data.beg_ts = moon.time()
    product_data.end_ts = moon.time() + sale_ts
    product_data.state = TradeDef.StateType.ON_SALE
    product_data.trade_data.single_price = sale_price
    product_data.trade_data.sale_num = 0
    product_data.trade_data.now_num = sale_num

    local sale_data = {
        uid = 0,
        product_data = product_data,
        condition1 = 0,
        condition2 = 0,
        condition3 = 0,
        condition4 = 0,
        condition5 = 0,
    }

    local res, err = clusterd.call(3999, "trademgr", "Trademgr.GmAddTradeProduct", sale_data)
    if err then
        moon.error("Console.add_trade_product err: ", sale_config_id, sale_num, sale_price, sale_ts)
        return Response(444, err, string.format("%d %d, %d %d", sale_config_id, sale_num, sale_price, sale_ts))
    else
        if res <= 0 then
            return Response(444, "Failed", string.format("%d %d, %d %d", sale_config_id, sale_num, sale_price, sale_ts))
        end

        return Response(0, "OK trade_id: " .. res)
    end
end

function Console.close_start_game(close_reason)
	local res, err = clusterd.call(3999, "roommgr", "Roommgr.StartGameIsClose", true)
	if err then
		moon.error("Console.close_start_game err: ", close_reason)
		return Response(444, err, string.format("%s", close_reason))
	else
		return Response(0, "OK")
	end
end

function Console.open_start_game(open_reason)
	local res, err = clusterd.call(3999, "roommgr", "Roommgr.StartGameIsClose", false)
	if err then
		moon.error("Console.open_start_game err: ", open_reason)
		return Response(444, err, string.format("%s", open_reason))
	else
		return Response(0, "OK")
	end
end

function Console.add_grade_score(uid, add_score)
	add_score = math.tointeger(add_score)
	local res, err = context.call_user(uid, "Grade.GMChangeScore", add_score)
	if err then
		return Response(444, err, string.format("%d %d", uid, add_score))
	end

	if res then
		return Response(0, "OK")
	else
		return Response(444, "Failed", string.format("%d %d", uid, add_score))
	end
end

return Console
