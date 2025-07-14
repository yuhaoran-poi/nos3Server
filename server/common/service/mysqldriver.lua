--require("common.LuaPanda").start("127.0.0.1", 8818)
local moon = require("moon")
local mysql = require("moon.db.mysql")
local buffer = require("buffer")
local json = require "json"

local conf = ...

if conf.name then
    local list = require("list")
    local dbs = list.new()
    moon.async(function()
        -- 初始化连接池
        for _ = 1, conf.poolsize do
            local db = mysql.connect(conf.opts)
            if db.code then
                moon.error("mysql connect failed:", db.message)
                return
            end
            list.push(dbs, db)
        end
    end)
   
    -- 新增定时器轮询
    moon.async(function()
        while true do
            moon.sleep(30000) -- 每30秒检查一次

            if list.size(dbs) > 0 then
                local db = list.pop(dbs)
                local ret = db:ping()
                if not ret or ret.server_status ~= 2 then
                    moon.err(string.format("mysql ping err ret:\n%s", json.pretty_encode(ret)))
                else
                    list.push(dbs, db)
                end
            end
        end
    end)

    moon.dispatch("lua", function(sender, sessionid, sql)
        -- 如果dbs为空，说明连接池已经满了，等待连接池有空闲连接
        while list.size(dbs) == 0 do
            moon.sleep(1)
        end
        local db = list.pop(dbs)
        if not db then
            moon.error("no available mysql connection")
            return
        end
        
        local res = db:query(sql)
        if res and res.errno then
            moon.error("mysql query failed:", res.message)
            moon.error("mysql query sql:", sql)
        end
        list.push(dbs, db)

        if sessionid ~= 0 then
            moon.response("lua", sender, sessionid, res)
        end
    end)
end
