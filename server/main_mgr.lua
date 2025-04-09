---__init__
if _G["__init__"] then
    local arg = ...
    return {
        thread = 8,
        enable_stdout = true,
        logfile = string.format("log/game-%s-%s.log", arg[1], os.date("%Y-%m-%d-%H-%M-%S")),
        loglevel = "DEBUG",
        path = table.concat({
            "./?.lua",
            "./?/init.lua",
            "moon/lualib/?.lua",
            "moon/service/?.lua",
            -- Append your lua module search path
        }, ";")
    }
end

local moon = require("moon")
local socket = require("moon.socket")
local json = require("json")
local uuid = require("uuid")
local httpc = require("moon.http.client")
local serverconf = require("serverconf")
local common = require("common")
local schema = require("schema")
local db = common.Database
local CreateTable = common.CreateTable


local arg = moon.args()

local function load_protocol(file)
    local pb = require "pb"
    local fobj = assert(io.open(file, "rb"))
    local content = fobj:read("*a")
    fobj:close()
    assert(pb.load(content))
    --- load once, then shared by other services
    pb.share_state()
end

-- If use protobuf, load *.pb file here, only need load once.
load_protocol("protocol/proto.pb")
schema.load(json.decode(io.readfile([[./protocol/json_verify.json]])))

local function run(node_conf)

    local db_conf = serverconf.db[node_conf.node]

    local services = {
        {
            unique = true,
            name = "cluster",
            file = "moon/service/cluster.lua",
            url = serverconf.CLUSTER_ETC_URL,
            threadid = 1,
        },
        {
            unique = true,
            name = "db_server",
            file = "moon/service/redisd.lua",
            threadid = 1,
            opts = db_conf.redis
        },
        {
            unique = true,
            name = "node",
            file = "game/service_node.lua",
            threadid = 2,
        },
        {
            unique = true,
            name = "sharetable",
            file = "moon/service/sharetable.lua",
            dir = "static/table",
            threadid = 3
        },
        {
            unique = true,
            name = "nodemgr",
            file = "manager/service_nodemgr.lua",
            threadid = 4,
            websocket = false,
        },
        {
            unique = true,
            name = "usermgr",
            file = "manager/service_usermgr.lua",
            threadid = 5,
            websocket = false,
        },
        {
            unique = true,
            name = "teammgr",
            file = "manager/service_teammgr.lua",
            threadid = 6,
            websocket = false,
        },
        {
            unique = true,
            name = "roommgr",
            file = "manager/service_roommgr.lua",
            threadid = 7,
            websocket = false,
            room_startid = 10000,
        },
    }

    local function Start()
        ---控制服务初始化顺序,Init一般为加载DB
        assert(moon.call("lua", moon.queryservice("node"), "Init"))
        assert(moon.call("lua", moon.queryservice("nodemgr"), "Init"))
        assert(moon.call("lua", moon.queryservice("usermgr"), "Init"))
        assert(moon.call("lua", moon.queryservice("teammgr"), "Init"))
        assert(moon.call("lua", moon.queryservice("roommgr"), "Init"))
        assert(moon.call("lua", moon.queryservice("nodemgr"), "Start"))
        assert(moon.call("lua", moon.queryservice("usermgr"), "Start"))
        assert(moon.call("lua", moon.queryservice("teammgr"), "Start"))
        assert(moon.call("lua", moon.queryservice("roommgr"), "Start"))

        local data = db.loadserverdata(moon.queryservice("db_server"))
        if not data then
            data = { boot_times = 0 }
        else
            data = json.decode(data)
        end
        ---服务器启动次数+1
        data.boot_times = data.boot_times + 1
        moon.env("SERVER_START_TIMES", tostring(data.boot_times))
        ---初始化唯一ID生成器
        uuid.init(1, tonumber(arg[1]), data.boot_times)

        ---加载完数据后 开始接受网络连接
        assert(moon.call("lua", moon.queryservice("cluster"), "Listen"))
    end

    local server_ok = false
    local addrs = {}

    moon.async(function()
        for _, conf in ipairs(services) do
            local addr = moon.new_service(conf)
            ---如果关键服务创建失败，立刻退出进程
            if 0 == addr then
                moon.exit(-1)
                return
            end
            table.insert(addrs, addr)
        end

        local ok, err = xpcall(Start, debug.traceback)
        if not ok then
            moon.error("server will abort, init error\n", err)
            moon.exit(-1)
            return
        end
        server_ok = true
    end)

    ---注册进程退出信号处理
    moon.shutdown(function()
        print("receive shutdown")
        moon.async(function()
            if server_ok then
                -- wait other service shutdown
                local i = 5
                while i > 0 do
                    moon.sleep(1000)
                    print(i .. "......")
                    i = i - 1
                end

                moon.kill(moon.queryservice("nodemgr"))
            else
                moon.exit(-1)
            end

            ---wait all service quit
            while true do
                local size = moon.server_stats("service.count")
                if size == 2 then
                    break
                end
                moon.sleep(200)
                print("bootstrap wait all service quit, now count:", size)
            end

            moon.kill(moon.queryservice("sharetable"))
            moon.quit()
        end)
    end)
end

moon.async(function()
    local response = httpc.get(string.format(serverconf.NODE_ETC_URL, arg[1]))
    if response.status_code ~= 200 then
        moon.error(response.status_code, response.body)
        moon.exit(-1)
        return
    end

    local node_conf = json.decode(response.body)

    moon.env("NODE", arg[1])
    moon.env("SERVER_NAME", node_conf.type .. "-" .. tostring(node_conf.node))
    moon.env("SERVER_TYPE", node_conf.type)
    run(node_conf)
end)

