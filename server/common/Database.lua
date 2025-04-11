local moon = require("moon")
local json = require("json")
local redisd = require("redisd")
---@type sqlclient
local pgsql = require("sqldriver")

local schema = require("schema")

local jencode = json.encode

local jdecode = json.decode

local redis_call = redisd.call

local redis_send = redisd.send

local _M = {}

function _M.loadallopenid(addr_db)
    local res, err = redis_call(addr_db, "hgetall", "openidmap")
    if res == false then
        error("loadallopenid failed:" .. tostring(err))
    end
    return res
end

function _M.loadserverdata(addr_db)
    local res, err = redis_call(addr_db, "get", "serverdata")
    if res == false then
        error("loadserverdata failed:" .. tostring(err))
    end
    return res
end

function _M.saveserverdata(addr_db, data)
    local res, err = redis_call(addr_db, "set", "serverdata", data)
    if res == false then
        error("loadserverdata failed:" .. tostring(err))
    end
    return res
end

function _M.loadGloabalDsGnId(addr_db)
    local res, err = redis_call(addr_db, "get", "GloabalDsGnId")
    if res == false then
        error("loadGloabalDsGnId failed:" .. tostring(err))
    end
    return res
end

function _M.saveGloabalDsGnId(addr_db, data)
    local res, err = redis_call(addr_db, "set", "GloabalDsGnId", data)
    if res == false then
        error("saveGloabalDsGnId failed:" .. tostring(err))
    end
    return res
end



function _M.queryuserid(addr_db, authkey)
    local res, err = redis_call(addr_db, "hget", "openidmap", authkey)
    if res == false then
        error("queryuserid failed:" .. tostring(err))
    end

    if res then
        return math.tointeger(res)
    end

    return res
end

function _M.insertuserid(addr_db, authkey, userid)
    return redis_call(addr_db, "hset", "openidmap", authkey, userid)
end

-- function _M.loaduser(addr_db, userid)
--     local res, err = redis_call(addr_db, "hget", "usermap", userid)
--     if res == false then
--         error("loaduser failed:" .. tostring(err))
--     end

--     if res then
--         res = jdecode(res)
--     end

--     return res
-- end

-- function _M.saveuser(addr_db, userid, data)
--     if moon.DEBUG() then
--         schema.validate("UserData", data)
--     end

--     data = jencode(data)
--     redis_send(addr_db, "hset", "usermap", userid, data)
-- end

if moon.queryservice("db_game") > 0 then
        ---async
    ---@param db integer
    ---@param uid integer
    ---@return UserData?
    -- function _M.loaduser(db, uid)
    --     local res, err = pgsql.query(db, string.format("select * from userdata where uid=%s;", uid), uid)
    --     if not res then
    --         error("loaduser failed:" .. err)
    --     end

    --     if res.code then
    --         error("loaduser failed db error:" .. json.encode(res))
    --     end

    --     local row = res.data[1]
    --     if row then
    --         return jdecode(row.data)
    --     end
    --     ---空数据:新玩家
    --     return nil
    -- end

    -- function _M.saveuser(db, uid, data)
    --     assert(data)

    --     if moon.DEBUG() then
    --         schema.validate("UserData", data)
    --     end

    --     local tmp = {
    --         "insert into userdata(uid, data) values(",
    --         uid,
    --         ",'",
    --         data, -- auto encode as json
    --         "') on conflict (uid) do update set data = excluded.data;"
    --     }
    --     pgsql.execute(db, tmp, uid)
    -- end
end

function _M.LoadUserMail(addr_db, uid)
    local res, err = redis_call(addr_db, "HGETALL", "mail_"..uid)
    if err then
        moon.error("LoadUserMail failed ", uid, err)
        return false
    end
    local maillist = {}
    assert(#res%2==0, tostring(uid))
    for i=1,#res,2 do
        local mail = json.decode(res[i+1])
        maillist[tonumber(res[i])] = mail
    end
    return maillist
end

---@param addr_db integer
---@param uid integer
---@param mailId integer
---@param mail MailData
function _M.SaveUserMail(addr_db, uid, mailId, mail)
    redis_send(addr_db, "HSET", "mail_"..uid, mailId, json.encode(mail))
end

---@param addr_db integer
---@param uid integer
---@param mailIdList integer[]
function _M.DelUserMail(addr_db, uid, mailIdList)
    redis_send(addr_db, "HDEL", "mail_"..uid, table.unpack(mailIdList))
end

function _M.query_rank(addr_db, uid)
    local res, err = redis_call(addr_db, "HGETALL", "rank_"..uid)
    if res == false then
        error("query_rank failed:"..tostring(err))
    end
    
    local rank_data = {ghost = 0, human = 0}
    if res and #res > 0 then
        rank_data.ghost = tonumber(res[2]) or 0
        rank_data.human = tonumber(res[4]) or 0
    end
    return rank_data
end

function _M.query_role(addr_db, uid)
    local res, err = redis_call(addr_db, "HGETALL", "role_"..uid)
    if res == false then
        error("query_role failed:"..tostring(err))
    end
    
    local role_data = {equipped_id = 0, unlocked_skins = {}}
    if res and #res > 0 then
        role_data.equipped_id = tonumber(res[2]) or 0
        role_data.unlocked_skins = json.decode(res[4] or "[]")
    end
    return role_data
end

function _M.GetUserSimple(addr_db, uid)
    local res, err = redis_call(addr_db, "HGETALL", "user_simple_"..uid)
    if res == false then
        error("GetUserSimple failed:"..tostring(err))
    end
    
    local simple_data = {}
    if res and #res > 0 then
        for i=1,#res,2 do
            simple_data[res[i]] = json.decode(res[i+1] or "null")
        end
    end
    return simple_data
end

function _M.GetUserSimpleF(addr_db, uid, field)
    local res, err = redis_call(addr_db, "HGET", "user_simple_"..uid, field)
    if res == false then
        error("GetUserSimpleF failed:"..tostring(err))
    end
    
    if res then
        return json.decode(res)
    end
    return nil
end

function _M.SetUserSimple(addr_db, uid, simple)
    assert(simple)
    
    local tmp = {}
    for k,v in pairs(simple) do
        table.insert(tmp, k)
        table.insert(tmp, json.encode(v))
    end
    
    redis_send(addr_db, "HMSET", "user_simple_"..uid, table.unpack(tmp))
end

function _M.SetUserSimpleF(addr_db, uid, field, value)
    redis_send(addr_db, "HSET", "user_simple_"..uid, field, json.encode(value))
end

-- 新增分布式会话管理（核心改造点）
function _M.create_session(addr_db, uid)
    local session_id = moon.md5(tostring(uid)..moon.time()) -- 使用框架API生成全局唯一会话ID
    redis_send(addr_db, "HSET", "sessions", uid, session_id) -- 使用现有redis_send基础能力
    return session_id
end

function _M.validate_session(addr_db, uid, session_id)
    local res = redis_call(addr_db, "HGET", "sessions", uid) -- 复用现有redis_call接口
    return res == session_id
end

-- 检查账号是否存在
function _M.checkuser(addr, authkey)
    local cmd = string.format([[
        SELECT user_id FROM mgame.account WHERE authkey = '%s';
    ]], authkey)
    return moon.call("lua", addr, cmd)
end

-- 创建用户方法
function _M.createuser(addr, authkey, password_hash)
    local cmd = string.format([[
        INSERT INTO mgame.account (authkey, username, password_hash) VALUES ('%s','%s','%s');
    ]], authkey, authkey, password_hash)
    return moon.call("lua", addr, cmd)
end

-- 获取用户ID方法
function _M.getuserbyauthkey(addr, authkey)
    local cmd = string.format([[
        SELECT user_id, username, password_hash, last_login FROM mgame.account WHERE authkey = '%s';
    ]], authkey)
    return moon.call("lua", addr, cmd)
end

-- 获取用户方法
function _M.loaduser(addr, uid)
    local cmd = string.format([[
        SELECT user_id, authkey, username, password_hash, last_login FROM mgame.account WHERE user_id = %d;
    ]], uid)
    return moon.call("lua", addr, cmd)
end

function _M.getuser(addr, username)
    local cmd = string.format([[
        SELECT user_id, authkey, username, password_hash, last_login FROM mgame.account WHERE username = '%s';
    ]], username)
    return moon.call("lua", addr, cmd)
end

-- 更新用户登录时间方法
function _M.updatelogin(addr, user_id)
    local cmd = string.format([[
        UPDATE mgame.account SET last_login = NOW() WHERE user_id = %d;
    ]], user_id)
    moon.send("lua", addr, cmd)
end

function _M.saveuser(addr, uid, data)
    assert(data)

    local data_str = jencode(data)

    local cmd = string.format([[
        INSERT INTO mgame.userdata (uid, data)
        VALUES (%d, '%s')
        ON DUPLICATE KEY UPDATE data = '%s';
    ]], uid, data_str, data_str)
    moon.send("lua", addr, cmd)
end

function _M.loaduser_simple(addr, uid)
    local cmd = string.format([[
        SELECT uid, value, json FROM mgame.user_simple WHERE uid = %d;
    ]], uid)
    return moon.call("lua", addr, cmd)
end

function _M.saveuser_simple(addr, uid, data, pbdata)
    assert(data)

    local data_str = jencode(data)

    local cmd = string.format([[
        INSERT INTO mgame.user_simple (uid, value, json)
        VALUES (%d, '%s', '%s')
        ON DUPLICATE KEY UPDATE value = '%s', json = '%s';
    ]], uid, pbdata, data_str, pbdata, data_str)
    return moon.call("lua", addr, cmd)
end

function _M.save_guildinfo(addr, guild_id, data, pbdata)
    assert(data)

    local data_str = jencode(data)

    local cmd = string.format([[
        INSERT INTO mgame.c_guild (guild_id, value, json)
        VALUES (%d, '%s', '%s')
        ON DUPLICATE KEY UPDATE value = '%s', json = '%s';
    ]], guild_id, pbdata, data_str, pbdata, data_str)
    return moon.call("lua", addr, cmd)
end
function _M.save_guildshop(addr, guild_id, data, pbdata)
    assert(data)

    local data_str = jencode(data)

    local cmd = string.format([[
        INSERT INTO mgame.c_guild_shop (guild_id, value, json)
        VALUES (%d, '%s', '%s')
        ON DUPLICATE KEY UPDATE value = '%s', json = '%s';
    ]], guild_id, pbdata, data_str, pbdata, data_str)
    return moon.call("lua", addr, cmd)
end

function _M.save_guildbag(addr, guild_id, data, pbdata)
    assert(data)

    local data_str = jencode(data)

    local cmd = string.format([[
        INSERT INTO mgame.c_guild_bag (guild_id, value, json)
        VALUES (%d, '%s', '%s')
        ON DUPLICATE KEY UPDATE value = '%s', json = '%s';
    ]], guild_id, pbdata, data_str, pbdata, data_str)
    return moon.call("lua", addr, cmd)
end
function _M.save_guildrecord(addr, guild_id, data, pbdata)
    assert(data)

    local data_str = jencode(data)

    local cmd = string.format([[
        INSERT INTO mgame.c_guild_record (guild_id, value, json)
        VALUES (%d, '%s', '%s')
        ON DUPLICATE KEY UPDATE value = '%s', json = '%s';
    ]], uid, pbdata, data_str, pbdata, data_str)
    return moon.call("lua", addr, cmd)
end

return _M
