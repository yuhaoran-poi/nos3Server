local moon = require("moon")
local socket = require("moon.socket")
local common = require("common")
local CmdCode = common.CmdCode
local GameCfg = common.GameCfg --游戏配置
local Database = common.Database
local ErrorCode = common.ErrorCode
local httpc = require("moon.http.client")
local json = require("json")
local crypt = require("crypt")
local lock_wait = require("moon.queue")()
local lock_run = require("moon.queue")()
local protocol = require("common.protocol_pb")
local ChatLogic = require("common.logic.ChatLogic")
local jencode = json.encode
local jdecode = json.decode

---@type citymgr_context
local context = ...

local listenfd
local max_num = 50
local min_num = 30

---@class Citymgr
local Citymgr = {}

function Citymgr.Init()
    context.citys = {}        -- 全量主城数据存储
    context.uid_cityid = {}   -- 用户ID与主城ID的映射关系
    context.waitds_citys = {} -- 等待中主城列表
    context.addr_db_server = moon.queryservice("db_server")

    Citymgr.CreateCity()
    -- 新增定时器轮询
    moon.async(function()
        while true do
            moon.sleep(10000) -- 每10秒检查一次
            local allocated_citys = Citymgr.CheckWaitDSCitys()
            Citymgr.SetNewDsCitys(allocated_citys)
            Citymgr.CheckCityRun()
        end
    end)
    return true
end

function Citymgr.CheckWaitDSCitys()
    local now = moon.time()
    local scope <close> = lock_wait()
    -- moon.debug(string.format("CheckWaitDSCitys time:%d", now))

    local function allocate_cb(rsp_data)
        if not rsp_data or not rsp_data.error or rsp_data.error ~= "success" then
            return false
        end

        if not rsp_data.allocationresponse then
            return false
        end

        local ret = {}
        if not rsp_data.allocationresponse.address
            or not rsp_data.allocationresponse.gameServerName
            or not rsp_data.allocationresponse.nodeName then
            return false
        end

        ret.ds_ip = rsp_data.allocationresponse.address
        ret.region = rsp_data.allocationresponse.gameServerName
        ret.serverssion = rsp_data.allocationresponse.nodeName

        return true, ret
    end
    
    local function query_cb(rsp_data)
        if not rsp_data or not rsp_data.gameservers or #rsp_data.gameservers ~= 1 then
            return false
        end

        local gameserver = rsp_data.gameservers[1]
        if not gameserver.labels
            or not gameserver.labels["agones.dev/sdk-clb_address"] then
            return false
        end

        return true, gameserver.labels["agones.dev/sdk-clb_address"]
    end
    
    for k, v in pairs(context.waitds_citys) do
        if now - v.lasttime >= 10 then
            v.lasttime = now
            
            if v.status == 0 then
                local response = httpc.post(context.conf.allocate_url, v.allocate_data)
                local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
                local rsp_data = json.decode(response.body)
                local success, ret = allocate_cb(rsp_data)
                if not success or not ret then
                    moon.error(string.format("allocate_cb rsp_data:\n%s", json.pretty_encode(rsp_data)))
                    v.failcnt = v.failcnt + 1
                else
                    moon.info(string.format("allocate_cb rsp_data:\n%s", json.pretty_encode(rsp_data)))
                    v.ds_ip = ret.ds_ip
                    v.region = ret.region
                    v.serverssion = ret.serverssion

                    v.status = 1
                    v.failcnt = 0
                end
            elseif v.status == 1 then
                local get_url = context.conf.query_url .. "?name=" .. v.region
                local response = httpc.get(get_url)
                local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
                local rsp_data = json.decode(response.body)
                local success, ret = query_cb(rsp_data)
                if not success or not ret then
                    moon.error(string.format("query_cb rsp_data:\n%s", json.pretty_encode(rsp_data)))
                    v.failcnt = v.failcnt + 1
                else
                    moon.info(string.format("query_cb rsp_data:\n%s", json.pretty_encode(rsp_data)))
                    v.ds_address = ret
                    
                    v.status = 2
                    v.failcnt = 0
                end
            else
                v.failcnt = v.failcnt + 1
            end
        end
    end

    local allocated_citys = {}
    local fail_citys = {}
    for k, v in pairs(context.waitds_citys) do
        if v.status == 2 then
            allocated_citys[k] = v
        elseif v.failcnt > 5 then
            table.insert(fail_citys, k)
        end
    end
    for cityid, _ in pairs(allocated_citys) do
        context.waitds_citys[cityid] = nil
    end
    for cityid, _ in pairs(fail_citys) do
        context.waitds_citys[cityid] = nil
    end
    moon.error(string.format("allocated_citys:\n%s", json.pretty_encode(allocated_citys)))
    return allocated_citys
end

function Citymgr.SetNewDsCitys(allocated_citys)
    for cityid, allocate_info in pairs(allocated_citys) do
        local city = {
            cityid = cityid,
            region = allocate_info.region,
            ds_address = allocate_info.ds_address,
            ds_ip = allocate_info.ds_ip,
            now_num = 0,
            pre_enter_num = 0,
            players = {},
            nid = 0,
            addr_dsnode = 0,
        }

        -- 创建附近聊天频道
        local res = ChatLogic.NewNearbyChannel(cityid)
        if res.code ~= ErrorCode.None then
            moon.error(string.format("NewNearbyChannel cityid:%d, code:%d, error:%s", cityid, res.code, res.error))
        end

        local scope <close> = lock_run()
        context.citys[cityid] = city
    end
end

function Citymgr.AddWaitDSCitys(cityid, allocate_data)
    local scope <close> = lock_wait()

    context.waitds_citys[cityid] = {
        status = 0,
        lasttime = 0,
        failcnt = 0,
        ds_ip = "",
        region = "",
        serverssion = "",
        ds_address = "",
        allocate_data = allocate_data,
    }
end

function Citymgr.CheckCityRun()
    local function query_cb(rsp_data)
        if not rsp_data or not rsp_data.gameservers or #rsp_data.gameservers ~= 1 then
            return false
        end

        local gameserver = rsp_data.gameservers[1]
        if not gameserver.labels then
            return false
        end

        return true
    end

    -- 检查是否有主城已死亡或者需要新创主城
    local dead_cityids = {}
    local canEnterRoom = {}
    for cityid, cityinfo in pairs(context.citys) do
        local get_url = context.conf.query_url .. "?name=" .. cityinfo.region
        local response = httpc.get(get_url)
        local rsp_data = json.decode(response.body)
        local success, ret = query_cb(rsp_data)
        if not success then
            moon.error(string.format("CheckCityRun rsp_data:\n%s", json.pretty_encode(rsp_data)))
            table.insert(dead_cityids, cityid)
        else
            if cityinfo.now_num < min_num then
                table.insert(canEnterRoom, cityid)
            end
        end
    end

    for _, cityid in pairs(dead_cityids) do
        -- 销毁附近聊天频道
        local res = ChatLogic.RemoveNearbyChannel(cityid)
        if res.code ~= ErrorCode.None then
            moon.error(string.format("RemoveNearbyChannel cityid:%d, code:%d, error:%s", cityid, res.code, res.error))
        end
        Citymgr.DestroyCity(cityid)
    end

    if #canEnterRoom + table.size(context.waitds_citys) < 1 then
        moon.info("CheckCityRun #canEnterRoom = %d, table.size(context.waitds_citys) = %d", #canEnterRoom,
            table.size(context.waitds_citys))
        Citymgr.CreateCity()
    end
end

-- 生成唯一房间ID（保留原逻辑）
local function generate_cityid()
    context.city_nowid = context.city_nowid + 1
    return context.city_nowid
end

function Citymgr.CreateCity()
    local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
    local cityid = generate_cityid()

    local city_info = {
        ds_id = cityid,
        chapter = 0,
        difficulty = 0,
        map_id = 0,
        boss_id = 0,
        server_ip = context.conf.mgr_host_ip,
        server_port = context.conf.mgr_host_port,
    }
    local _, pbdata = protocol.encodewithname("PBDsCreateData", city_info)
    local city_str = crypt.base64encode(pbdata)
    local allocate_data = {
        fleet = context.conf.fleet,
        room = city_str,
    }
    moon.info(string.format("CreateCity allocate_data =\n%s", json.pretty_encode(allocate_data)))
    Citymgr.AddWaitDSCitys(cityid, json.encode(allocate_data))
end

function Citymgr.DestroyCity(cityid)
    local scope <close> = lock_run()

    local city = context.citys[cityid]
    if not city then
        return
    end
    for uid, _ in pairs(city.players) do
        context.uid_cityid[uid] = nil
    end
    context.citys[cityid] = nil
end

function Citymgr.ConnectCity(req)
    -- return { code = ErrorCode.None, error = "连接主城成功" }

    local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
    if not context.citys[req.cityid] then
        return { code = ErrorCode.CityNotFound, error = "主城不存在" }
    end

    local city = context.citys[req.cityid]
    city.nid = req.nid
    city.addr_dsnode = req.addr_dsnode
    return { code = ErrorCode.None, error = "连接主城成功" }
end

function Citymgr.ApplyLoginToCity(uid)
    local function findFreeCity()
        local scope <close> = lock_run()
        -- 查找空闲主城加入
        for cityid, city in pairs(context.citys) do
            if city.addr_dsnode and city.now_num + city.pre_enter_num < min_num then
                city.pre_enter_num = city.pre_enter_num + 1
                return {
                    code = ErrorCode.None,
                    error = "允许加入",
                    cityid = cityid,
                    region = city.region,
                    ds_address = city.ds_address,
                    ds_ip = city.ds_ip,
                }
            end
        end

        for cityid, city in pairs(context.citys) do
            if city.now_num + city.pre_enter_num < max_num then
                city.pre_enter_num = city.pre_enter_num + 1
                return {
                    code = ErrorCode.None,
                    error = "允许加入",
                    cityid = cityid,
                    region = city.region,
                    ds_address = city.ds_address,
                    ds_ip = city.ds_ip,
                }
            end
        end

        return nil
    end

    -- 检查是否已在主城
    if context.uid_cityid[uid] then
        return { code = ErrorCode.CityAlreadyInCity, error = "已在其他主城", cityid = context.uid_cityid[uid] }
    end

    local res = findFreeCity()
    -- local res = {
    --     code = ErrorCode.None,
    --     error = "允许加入",
    --     cityid = 1,
    --     region = "default",
    --     ds_address = "192.168.2.31-8888",
    --     ds_ip = "192.168.2.31",
    -- }
    if not res then
        return { code = ErrorCode.CityNotFound, error = "没有空闲主城" }
    end

    return res
end

function Citymgr.PlayerEnterCity(req)
    local function enterCity()
        local scope <close> = lock_run()

        if not context.citys[req.cityid] then
            return { code = ErrorCode.CityNotFound, error = "主城不存在" }
        end
        local city = context.citys[req.cityid]
        city.now_num = city.now_num + 1
        city.players[req.uid] = 1
        context.uid_cityid[req.uid] = req.cityid

        return { code = ErrorCode.None, error = "进入主城成功" }
    end

    local res = enterCity()
    if res.code == ErrorCode.None then
        -- 加入附近频道
        local chat_ret = ChatLogic.JoinNearbyChannel(req.cityid, req.uid)
        if chat_ret.code ~= ErrorCode.None then
            moon.error(string.format("JoinNearbyChannel uid:%d, cityid:%d, code:%d, error:%s", req.uid, req.cityid,
                chat_ret.code, chat_ret.error))
        end
    end
    return res
end

function Citymgr.PlayerExitCity(req)
    local function exitCity()
        local scope <close> = lock_run()

        if not context.citys[req.cityid]
            or not context.uid_cityid[req.uid]
            or context.uid_cityid[req.uid] ~= req.cityid then
            return { code = ErrorCode.UserNotEnterCity, error = "玩家没进入" }
        end

        context.uid_cityid[req.uid] = nil
        local city = context.citys[req.cityid]
        city.now_num = city.now_num - 1
        city.players[req.uid] = nil

        return { code = ErrorCode.None, error = "退出主城成功" }
    end

    local res = exitCity()
    if res.code == ErrorCode.None then
        -- 退出附近频道
        local chat_ret = ChatLogic.LeaveNearbyChannel(req.cityid, req.uid)
        if chat_ret.code ~= ErrorCode.None then
            moon.error(string.format("LeaveNearbyChannel uid:%d, cityid:%d, code:%d, error:%s", req.uid, req.cityid,
                chat_ret.code, chat_ret.error))
        end
    end
    return res
end

function Citymgr.UpdateCityPlayer(req)
    local function updateCity()
        local scope <close> = lock_run()

        if not context.citys[req.cityid] then
            return
        end
        local city = context.citys[req.cityid]
        city.now_num = req.player_num
        city.pre_enter_num = 0
    end

    updateCity()
end

function Citymgr.Start()
    return true
end

function Citymgr.Shutdown()
    -- for _, n in pairs(context.citys) do
    --     socket.close(n.fd)
    -- end
    if listenfd then
        socket.close(listenfd)
    end
    moon.quit()
    return true
end

return Citymgr
