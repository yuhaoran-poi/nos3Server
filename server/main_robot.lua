---__init__
if _G["__init__"] then
    local arg = ...
    return {
        thread = 2,
        enable_stdout = true,
        logfile = string.format("log/robot-%s-%s.log", arg[1], os.date("%Y-%m-%d-%H-%M-%S")),
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
--local db = common.Database
--local CreateTable = common.CreateTable


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
        -- {
        --     unique = true,
        --     name = "db_openid",
        --     file = "moon/service/redisd.lua",
        --     threadid = 1,
        --     poolsize = 5,
        --     opts = db_conf.redis
        -- },
        {
            name = "robot",
            file = "robot/robot.lua",
            unique = true,
            threadid = 1,
            -- host = "118.24.31.127",
            host = "127.0.0.1",
            port = 12108,
            -- dhost = "118.24.31.127",
            dhost = "127.0.0.1",
            dport = 11288,
        },
        {
            name = "robotmgr",
            file = "robot/robotmgr.lua",
            unique = true,
            threadid = 2,
            -- host = "118.24.31.127",
            host = "127.0.0.1",
            port = 12108
        }
    }

    local function Start()
        print("main_robot start")
        ---控制服务初始化顺序,Init一般为加载DB
        assert(moon.call("lua", moon.queryservice("robot"), "Init"))
        assert(moon.call("lua", moon.queryservice("robot"), "DoPing"))
        assert(moon.call("lua", moon.queryservice("robotmgr"), "Init"))
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
                --assert(moon.call("lua", moon.queryservice("gate"), "Gate.Shutdown"))

                moon.kill(moon.queryservice("robot"))
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


