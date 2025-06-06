local moon = require("moon")
local json = require("json")
local redisd = require("redisd")
local uuid = require("uuid")
local protocol = require("common.protocol_pb")
local crypt = require("crypt")
 
 

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

function _M.RedisGetUserAttr(addr_db, uid, fields)
    local user_attr = {}
    if fields and type(fields) == "table" and table.size(fields) > 0 then
        local res, err = redis_call(addr_db, "HMGET", "user_attr_" .. uid, table.unpack(fields))
        if res == false then
            error("RedisGetUserAttr failed:" .. tostring(err))
        end
        if res and #res > 0 then
            for i = 1, #res, 2 do
                user_attr[res[i]] = json.decode(res[i + 1] or "null")
            end
        end
    else
        local res, err = redis_call(addr_db, "HGETALL", "user_attr_" .. uid)
        if res == false then
            error("RedisGetUserAttr failed:" .. tostring(err))
        end
        if res and #res > 0 then
            for i = 1, #res, 2 do
                user_attr[res[i]] = json.decode(res[i + 1] or "null")
            end
        end
    end

    return user_attr
end

function _M.RedisSetUserAttr(addr_db, uid, user_attr)
    local tmp = {}
    for k, v in pairs(user_attr) do
        table.insert(tmp, k)
        table.insert(tmp, json.encode(v))
    end
    redis_send(addr_db, "HMSET", "user_attr_" .. uid, table.unpack(tmp))
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

-- function _M.loaduserdata(addr, uid)
--     local cmd = string.format([[
--         SELECT data FROM mgame.userdata WHERE uid = %d;
--     ]], uid)
--     local res, err = moon.call("lua", addr, cmd)
--     if res and #res > 0 then
--         return jdecode(res[1].data)
--     end
--     print("loaduserdata failed", uid, err)
--     return nil
-- end

-- function _M.saveuserdata(addr, uid, data)
--     assert(data)

--     local data_str = jencode(data)

--     local cmd = string.format([[
--         INSERT INTO mgame.userdata (uid, data)
--         VALUES (%d, '%s')
--         ON DUPLICATE KEY UPDATE data = '%s';
--     ]], uid, data_str, data_str)
--     moon.send("lua", addr, cmd)
-- end

function _M.loaduser_attr(addr, uid)
    local cmd = string.format([[
        SELECT uid, value, json FROM mgame.user_attr WHERE uid = %d;
    ]], uid)

    local res, err = moon.call("lua", addr, cmd)
    if res and #res > 0 then
        local _, tmp_data = protocol.decodewithname("PBUserAttr", res[1].value)
        return tmp_data
    end

    return nil
end

function _M.saveuser_attr(addr, uid, data)
    assert(data)

    local pbname, pb_data = protocol.encodewithname("PBUserAttr", data)
    local data_str = jencode(data)

    local cmd = string.format([[
        INSERT INTO mgame.user_attr (uid, value, json)
        VALUES (%d, '%s', '%s')
        ON DUPLICATE KEY UPDATE value = '%s', json = '%s';
    ]], uid, pb_data, data_str, pb_data, data_str)
    return moon.call("lua", addr, cmd)
end

-- 房间索引前缀常量
local ROOM_PREFIX = "room:"
local INDEX_PREFIX = "room:index:"
local TEMP_PREFIX = "room:temp:"

-- 创建/更新房间
function _M.upsert_room(addr_db, roomid, room_tags, room_data)
    -- 获取旧值
    local ola_values = {}
    local old_json, err = redis_call(addr_db, "MGET", ROOM_PREFIX .. roomid)
    --
    if old_json and next(old_json) ~= nil then
        ola_values = json.decode(old_json[1])
    end

    -- 存储新数据
    redis_send(addr_db, "MSET", ROOM_PREFIX .. roomid, json.encode(room_data))

    -- 更新索引
    for tag, new_value in pairs(room_tags) do
        local old_value = ola_values[tag]
        -- 删除旧索引
        if old_value and old_value ~= new_value then
            local del_pipeline = {}
            table.insert(del_pipeline, "SREM")
            table.insert(del_pipeline, INDEX_PREFIX .. tag .. ":" .. old_value)
            table.insert(del_pipeline, roomid)
            redis_send(addr_db, table.unpack(del_pipeline))
        end

        -- 添加新索引
        local add_pipeline = {}
        table.insert(add_pipeline, "SADD")
        table.insert(add_pipeline, INDEX_PREFIX .. tag .. ":" .. new_value)
        table.insert(add_pipeline, roomid)
        redis_send(addr_db, table.unpack(add_pipeline))

        -- 添加0索引
        local add_pipeline_0 = {}
        table.insert(add_pipeline_0, "SADD")
        table.insert(add_pipeline_0, INDEX_PREFIX .. tag .. ":" .. 0)
        table.insert(add_pipeline_0, roomid)
        redis_send(addr_db, table.unpack(add_pipeline_0))
    end
end

-- 复合条件分页查询
function _M.search_rooms(addr_db, conditions, page, page_size)
    -- 生成临时键
    local temp_key = TEMP_PREFIX .. moon.md5(json.encode(conditions))
    -- 查看临时键是否存在
    local exists, e_err = redis_call(addr_db, "EXISTS", temp_key)
    if exists == 0 then
        -- 新建临时键
        -- 构建查询条件集合
        local sets = {}
        for tag, value in pairs(conditions) do
            table.insert(sets, INDEX_PREFIX .. tag .. ":" .. value)
        end

        -- 执行集合运算
        if #sets == 0 then return { total = 0, data = {} } end

        redis_send(addr_db, "SINTERSTORE", temp_key, table.unpack(sets))
        redis_send(addr_db, "EXPIRE", temp_key, 600)
    end

    -- 分页查询
    local ids, i_err = redis_call(addr_db, "SMEMBERS", temp_key)
    if #ids > 0 then
        table.sort(ids)
        local total = #ids
        -- 计算分页范围
        local beg_idx = math.max(1, (page - 1) * page_size + 1)
        local end_idx = math.min(beg_idx + page_size - 1, total)
        -- 提取当前页数据
        local pipeline = {}
        table.insert(pipeline, "MGET")
        local can_get = false
        for i = beg_idx, end_idx do
            if ids[i] then
                table.insert(pipeline, ROOM_PREFIX .. ids[i])
                can_get = true
            else
                break -- 防止索引越界
            end
        end

        if can_get then
            local res, r_err = redis_call(addr_db, table.unpack(pipeline))
            if res and next(res) ~= nil then
                for i = 1, #res do
                    if res[i] then
                        res[i] = json.decode(res[i])
                    end
                end
            end
            return {
                total = #res,
                data = res
            }
        end
    end

    return {
        total = 0,
        data = {}
    }
end

-- 删除房间
function _M.delete_room(addr_db, roomid)
    -- 获取房间信息
    local ola_values = {}
    local old_json, err = redis_call(addr_db, "MGET", ROOM_PREFIX .. roomid)
    if old_json and next(old_json) ~= nil then
        ola_values = json.decode(old_json[1])
        if not ola_values then
            ola_values = {}
        end
    end

    -- 删除主数据
    redis_send(addr_db, "DEL", ROOM_PREFIX .. roomid)

    -- 清理索引
    for k, v in pairs(ola_values) do
        local del_pipeline = {}
        table.insert(del_pipeline, "SREM")
        table.insert(del_pipeline, INDEX_PREFIX .. k .. ":" .. v)
        table.insert(del_pipeline, roomid)

        redis_send(addr_db, table.unpack(del_pipeline))

        -- 删除0索引
        local del_pipeline_0 = {}
        table.insert(del_pipeline_0, "SREM")
        table.insert(del_pipeline_0, INDEX_PREFIX .. k .. ":" .. 0)
        table.insert(del_pipeline_0, roomid)
        redis_send(addr_db, table.unpack(del_pipeline_0))
    end
end
 
-- 加载所有公会id
function _M.load_guildids(addr)
    local cmd = [[
        SELECT guildId FROM mgame.c_guild;
    ]]
    local res, err = moon.call("lua", addr, cmd)
    if res and #res > 0 then
        local guild_ids = {}
        for _, row in ipairs(res) do
            table.insert(guild_ids, row.guildId)
        end
        return guild_ids
    end
    print("load_guildids failed", err)
    return {}
end
-- 加载公会信息
function _M.load_guildinfo(addr, guild_id)
    local cmd = string.format([[
        SELECT value, json FROM mgame.c_guild WHERE guildId = %d;
    ]], guild_id)
    local res, err = moon.call("lua", addr, cmd)
    if res and #res > 0 then
        local _, tmp_data = protocol.decodewithname("PBGuildInfoDB", res[1].value)
        return tmp_data
    end
    print("load_guildinfo failed", guild_id, err)
    return nil
end
function _M.load_guildshop(addr, guild_id)
    local cmd = string.format([[
        SELECT value, json FROM mgame.c_guild_shop WHERE guildId = %d;
    ]], guild_id)
    local res, err = moon.call("lua", addr, cmd)
    if res and #res > 0 then
        local _, tmp_data = protocol.decodewithname("PBGuildShopDB", res[1].value)
        return tmp_data
    end
    print("load_guildshop failed", guild_id, err)
    return nil
end
function _M.load_guildbag(addr, guild_id)
    local cmd = string.format([[
        SELECT value, json FROM mgame.c_guild_bag WHERE guildId = %d;
    ]],guild_id)
    local res, err = moon.call("lua", addr, cmd)
    if res and #res > 0 then
        local _, tmp_data = protocol.decodewithname("PBGuildBagDB", res[1].value)
        return tmp_data
    end
    print("load_guildbag failed", guild_id, err)
    return nil
end
function _M.load_guildrecord(addr, guild_id)
    local cmd = string.format([[
        SELECT value, json FROM mgame.c_guild_record WHERE guildId = %d;
    ]], guild_id)
    local res, err = moon.call("lua", addr, cmd)
    if res and #res > 0 then
        local _, tmp_data = protocol.decodewithname("PBGuildRecordDB", res[1].value)
        return tmp_data
    end
    print("load_guildrecord failed", guild_id, err)
    return nil
end
function _M.save_guildinfo(addr, guild_id, data)
    assert(data)

    local data_str = jencode(data)
    local _, pbdata = protocol.encodewithname("PBGuildInfoDB", data)
    local cmd = string.format([[
        INSERT INTO mgame.c_guild (guildId, value, json)
        VALUES (%d, '%s', '%s')
        ON DUPLICATE KEY UPDATE value = '%s', json = '%s';
    ]], guild_id, pbdata, data_str, pbdata, data_str)
    return moon.call("lua", addr, cmd)
end
function _M.save_guildshop(addr, guild_id, data)
    assert(data)

    local data_str = jencode(data)
    local _, pbdata = protocol.encodewithname("PBGuildShopDB", data)
    local cmd = string.format([[
        INSERT INTO mgame.c_guild_shop (guildId, value, json)
        VALUES (%d, '%s', '%s')
        ON DUPLICATE KEY UPDATE value = '%s', json = '%s';
    ]], guild_id, pbdata, data_str, pbdata, data_str)
    return moon.call("lua", addr, cmd)
end

function _M.save_guildbag(addr, guild_id, data)
    assert(data)

    local data_str = jencode(data)
    local _, pbdata = protocol.encodewithname("PBGuildBagDB", data)
    local cmd = string.format([[
        INSERT INTO mgame.c_guild_bag (guildId, value, json)
        VALUES (%d, '%s', '%s')
        ON DUPLICATE KEY UPDATE value = '%s', json = '%s';
    ]], guild_id, pbdata, data_str, pbdata, data_str)
    return moon.call("lua", addr, cmd)
end

function _M.save_guildrecord(addr, guild_id, data)
    assert(data)

    local data_str = jencode(data)
    local _, pbdata = protocol.encodewithname("PBGuildRecordDB", data)
    local cmd = string.format([[
        INSERT INTO mgame.c_guild_record (guildId, value, json)
        VALUES (%d, '%s', '%s')
        ON DUPLICATE KEY UPDATE value = '%s', json = '%s';
    ]], guild_id, pbdata, data_str, pbdata, data_str)
    return moon.call("lua", addr, cmd)
end

-- 背包相关数据
-- function _M.saveuserbag(addr, uid, data)
--     assert(data)

--     local data_str = jencode(data)
--     --local _, pbdata = protocol.encodewithname("PBGuildRecordDB", data)

--     local cmd = string.format([[
--         INSERT INTO mgame.userbag (uid, data_json)
--         VALUES (%d, '%s')
--         ON DUPLICATE KEY UPDATE data_json = '%s';
--     ]], uid, data_str, data_str)
--     moon.send("lua", addr, cmd)
-- end

function _M.saveuserbags(addr, uid, bags_data)
    assert(bags_data)

    local str_sql = "INSERT INTO mgame.userbag(uid"
    local str_param1 = ""
    local str_param2 = ""
    local str_param3 = ""
    local had_param = false

    for bagTypeName, bagData in pairs(bags_data) do
        local data_str = jencode(bagData)
        local _, pbdata = protocol.encodewithname("PBBag", bagData)
        if data_str and pbdata then
            had_param = true

            str_param1 = str_param1 .. ", " .. bagTypeName .. ", " .. bagTypeName.. "_json"
            str_param2 = str_param2 .. ", '" .. pbdata .. "', '" .. data_str .. "'"
            if str_param3 ~= "" then
                str_param3 = str_param3.. ", "
            end
            str_param3 = str_param3 .. " " .. bagTypeName .. "='" .. pbdata .. "', " .. bagTypeName .. "_json='" .. data_str .. "'"
        end
    end
    if not had_param then
        return false
    end

    str_sql = str_sql .. str_param1 .. ") VALUES (" .. uid .. str_param2 .. ")" .. "ON DUPLICATE KEY UPDATE" .. str_param3 .. ";"
    moon.send("lua", addr, str_sql)

    return true
end

function _M.loaduserbags(addr, uid, bags_id)
    assert(bags_id)

    local str_sql = "SELECT uid"
    local str_param1 = ""
    local had_param = false
    for bagTypeName, _ in pairs(bags_id) do
        if bagTypeName then
            had_param = true
            str_param1 = str_param1 .. ", " .. bagTypeName
        end
    end
    if not had_param then
        return nil
    end

    str_sql = str_sql .. str_param1 .. " FROM mgame.userbag WHERE uid=" .. uid
    local sql_res, err = moon.call("lua", addr, str_sql)
    if not err and sql_res and #sql_res > 0 then
        local bag_res = {}
        for bagTypeName, _ in pairs(bags_id) do
            if sql_res[1][bagTypeName] then
                local _, tmp_data = protocol.decodewithname("PBBag", sql_res[1][bagTypeName])
                if tmp_data then
                    bag_res[bagTypeName] = tmp_data
                end
            end
        end

        return bag_res
    end

    return nil
end

function _M.loaduserroles(addr, uid)
    local cmd = string.format([[
        SELECT value, json FROM mgame.roles WHERE uid = %d;
    ]], uid)
    local res, err = moon.call("lua", addr, cmd)
    if res and #res > 0 then
        local pbdata = crypt.base64decode(res[1].value)
        local _, tmp_data = protocol.decodewithname("PBUserRoleDatas", pbdata)
        return tmp_data
    end
    print("loaduserroles failed", uid, err)
    return nil
end

function _M.saveuserroles(addr, uid, data)
    assert(data)

    local data_str = jencode(data)
    local _, pbdata = protocol.encodewithname("PBUserRoleDatas", data)
    local pbvalue = crypt.base64encode(pbdata)
    local cmd = string.format([[
        INSERT INTO mgame.roles (uid, value, json)
        VALUES (%d, '%s', '%s')
        ON DUPLICATE KEY UPDATE value = '%s', json = '%s';
    ]], uid, pbvalue, data_str, pbvalue, data_str)

    return moon.send("lua", addr, cmd)
end

function _M.loaduserghosts(addr, uid)
    local cmd = string.format([[
        SELECT value, json FROM mgame.ghosts WHERE uid = %d;
    ]], uid)
    local res, err = moon.call("lua", addr, cmd)
    if res and #res > 0 then
        local _, tmp_data = protocol.decodewithname("PBUserGhostDatas", res[1].value)
        return tmp_data
    end
    print("loaduserghosts failed", uid, err)
    return nil
end

function _M.saveuserghosts(addr, uid, data)
    assert(data)

    local data_str = jencode(data)
    local _, pbdata = protocol.encodewithname("PBUserGhostDatas", data)
    local cmd = string.format([[
        INSERT INTO mgame.ghosts (uid, value, json)
        VALUES (%d, '%s', '%s')
        ON DUPLICATE KEY UPDATE value = '%s', json = '%s';
    ]], uid, pbdata, data_str, pbdata, data_str)

    return moon.send("lua", addr, cmd)
end

function _M.loaduseritemimage(addr, uid)
    local cmd = string.format([[
        SELECT value, json FROM mgame.itemimages WHERE uid = %d;
    ]], uid)
    local res, err = moon.call("lua", addr, cmd)
    if res and #res > 0 then
        local _, tmp_data = protocol.decodewithname("PBUserImage", res[1].value)
        return tmp_data
    end
    print("loaduseritemimage failed", uid, err)
    return nil
end

function _M.saveuseritemimage(addr, uid, data)
    assert(data)

    local data_str = jencode(data)
    local _, pbdata = protocol.encodewithname("PBUserImage", data)
    local cmd = string.format([[
        INSERT INTO mgame.itemimages (uid, value, json)
        VALUES (%d, '%s', '%s')
        ON DUPLICATE KEY UPDATE value = '%s', json = '%s';
    ]], uid, pbdata, data_str, pbdata, data_str)

    return moon.send("lua", addr, cmd)
end

function _M.loadusercoins(addr, uid)
    local cmd = string.format([[
        SELECT value, json FROM mgame.coins WHERE uid = %d;
    ]], uid)
    local res, err = moon.call("lua", addr, cmd)
    if res and #res > 0 then
        local _, tmp_data = protocol.decodewithname("PBUserCoins", res[1].value)
        return tmp_data
    end
    print("loadusercoins failed", uid, err)

    return nil
end

function _M.saveusercoins(addr, uid, data)
    assert(data)

    local data_str = jencode(data)
    local _, pbdata = protocol.encodewithname("PBUserCoins", data)
    local cmd = string.format([[
        INSERT INTO mgame.coins (uid, value, json)
        VALUES (%d, '%s', '%s')
        ON DUPLICATE KEY UPDATE value = '%s', json = '%s';
    ]], uid, pbdata, data_str, pbdata, data_str)

    return moon.send("lua", addr, cmd)
end

-- 记录道具变更日志
function _M.ItemChangeLog(addr, uid, item_id, change_num, before_num, after_num, reason, reason_detail)
    local cmd = string.format([[
        INSERT INTO mlog.t_item_change (uid, item_id, change_num, before_num, after_num, reason, reason_detail)
        VALUES (%d, %d, %d, %d, %d, %d, '%s');
    ]], uid, item_id, change_num, before_num, after_num, reason, reason_detail)
    moon.send("lua", addr, cmd)
end

return _M
