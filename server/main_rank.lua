---__init__
if _G["__init__"] then
    local arg = ...
    return {
        thread = 16,
        enable_stdout = true,
        logfile = string.format("log/rank-%s-%s.log", arg[1], os.date("%Y-%m-%d-%H-%M-%S")),
        loglevel = "DEBUG",
        path = table.concat({
            "./?.lua",
            "./?/init.lua",
            "moon/lualib/?.lua",
            "moon/service/?.lua",
        }, ";")
    }
end

local moon = require("moon")
-- Bridge OS env (HTTPS_PROXY/HTTP_PROXY/...) into moon.env so that
-- moon's internal http client can read them. Must run before any
-- outbound HTTPS request issued by services in this process.
require("common.env_bridge").run()
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
    pb.share_state()
end

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
            name = "db_user",
            file = "moon/service/redisd.lua",
            threadid = 1,
            poolsize = 5,
            opts = db_conf.redis
        },
        {
            unique = true,
            name = "node",
            file = "common/service/service_node.lua",
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
            name = "db_redis",
            file = "moon/service/redisd.lua",
            threadid = 2,
            poolsize = 5,
            opts = db_conf.redis
        },
        {
            unique = true,
            name = "db_log",
            file = "common/service/mysqldriver.lua",
            threadid = 4,
            poolsize = 5,
            opts = db_conf.mysql
        },
        {
            unique = true,
            name = "rank",
            file = "rank/service_rank.lua",
            threadid = 5,
        },
    }

    local function Start()
        assert(moon.call("lua", moon.queryservice("node"), "Init"))
        assert(moon.call("lua", moon.queryservice("rank"), "Init"))

        local data = db.loadserverdata(moon.queryservice("db_server"))
        if not data then
            data = { boot_times = 0 }
        else
            data = json.decode(data)
        end
        data.boot_times = data.boot_times + 1
        if data.boot_times > 1023 then
            data.boot_times = 1
        end
        moon.env("SERVER_START_TIMES", tostring(data.boot_times))
        uuid.init(1, tonumber(arg[1]), data.boot_times)
        -- 初始化永不重复的 UniqueId(用同一个 serverid 避免与现有 uuid 段位宽冲突)
        common.UniqueId.init(tonumber(arg[1]))

        assert(moon.call("lua", moon.queryservice("cluster"), "Listen"))
        assert(moon.call("lua", moon.queryservice("rank"), "Start"))
    end

    local server_ok = false
    local addrs = {}

    moon.async(function()
        for _, conf in ipairs(services) do
            local addr = moon.new_service(conf)
            if 0 == addr then
                moon.error("Failed to create service:", conf.name)
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

    moon.shutdown(function()
        print("receive shutdown")
        moon.async(function()
            if server_ok then
                local i = 5
                while i > 0 do
                    moon.sleep(1000)
                    print(i .. "......")
                    i = i - 1
                end

                moon.kill(moon.queryservice("rank"))
            else
                moon.exit(-1)
            end

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
    moon.env("SERVER_NAME", node_conf.type.."-"..tostring(node_conf.node))
    moon.env("SERVER_TYPE", node_conf.type)
    run(node_conf)
end)
