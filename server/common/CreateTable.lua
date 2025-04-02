local moon = require("moon")

return function(addr_db)
    -- 修改执行命令为 DB.Query
    local ok, err = moon.call("lua", addr_db, [[
        CREATE TABLE IF NOT EXISTS userdata (
            uid BIGINT PRIMARY KEY NOT NULL,
            data TEXT NOT NULL
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;
    ]])
    assert(ok, err)
end

