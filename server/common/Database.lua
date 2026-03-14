local moon = require("moon")
local json = require("json")
local redisd = require("redisd")
local uuid = require("uuid")
local protocol = require("common.protocol_pb")
local crypt = require("crypt")
local TradeDef = require("common.def.TradeDef")

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
        local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
        if err then
            error("RedisGetUserAttr failed:" .. tostring(err))
        end
        if res and #res > 0 then
            for i = 1, #res do
                user_attr[fields[i]] = json.decode(res[i] or "null")
            end
        end
    else
        local res, err = redis_call(addr_db, "HGETALL", "user_attr_" .. uid)
        if err then
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

function _M.RedisGetSimpleUserAttr(addr_db, uids)
    local res, err = redis_call(addr_db, "HMGET", "user_simple_attr", table.unpack(uids))
    if err then
        error("RedisGetSimpleUserAttr failed:" .. tostring(err))
    end
    local uids_attrs = {}
    if res and #res > 0 then
        moon.warn(string.format("RedisGetSimpleUserAttr res = %s", json.pretty_encode(res)))
        for i = 1, #res do
            uids_attrs[uids[i]] = json.decode(res[i] or "null")
        end
    end

    return uids_attrs
end

function _M.RedisSetSimpleUserAttr(addr_db, simple_user_attrs)
    local tmp = {}
    for uid, simple_user_attr in pairs(simple_user_attrs) do
        table.insert(tmp, uid)
        table.insert(tmp, json.encode(simple_user_attr))
    end
    moon.warn(string.format("RedisSetSimpleUserAttr res = %s", json.pretty_encode(tmp)))
    redis_send(addr_db, "HSET", "user_simple_attr", table.unpack(tmp))
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
function _M.createuser(addr, plateform_id, password_hash)
    if not password_hash then
        password_hash = ""
    end
    local cmd = string.format([[
        INSERT INTO mgame.account (authkey, username, password_hash) VALUES ('%s','%s','%s');
    ]], plateform_id, plateform_id, password_hash)
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
        local pbdata = crypt.base64decode(res[1].value)
        local success, result = pcall(function()
            local _, tmp_data = protocol.decodewithname("PBUserAttr", pbdata)
            return tmp_data
        end)
        
        if success then
            return result
        else
            -- 解码失败，可能是协议格式不兼容，尝试修复
            moon.error(string.format("Failed to decode PBUserAttr for uid %d: %s", uid, result))
            
            -- 尝试使用旧的解码方式或其他修复逻辑
            -- 这里可以根据具体情况实现数据迁移逻辑
            -- 目前返回默认值，让系统重新初始化
            local UserAttrDef = require("common.def.UserAttrDef")
            local default_attr = UserAttrDef.newUserAttr()
            default_attr.uid = uid
            return default_attr
        end
    end

    return nil
end

function _M.saveuser_attr(addr, uid, data)
    assert(data)

    local pbname, pb_data = protocol.encodewithname("PBUserAttr", data)
    local pbvalue = crypt.base64encode(pb_data)
    local data_str = jencode(data)

    local cmd = string.format([[
        INSERT INTO mgame.user_attr (uid, value, json)
        VALUES (%d, '%s', '%s')
        ON DUPLICATE KEY UPDATE value = '%s', json = '%s';
    ]], uid, pbvalue, data_str, pbvalue, data_str)
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
        redis_send(addr_db, "EXPIRE", temp_key, 10)
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

-- 清理redis的房间记录
function _M.clear_all_room_keys(addr_db)
    -- 首先获取所有带ROOM_PREFIX前缀的键
    local cursor = tonumber(0)
    local batch_size = 1000 -- 每次处理的键数量

    -- 删除房间数据
    repeat
        local res, err = redis_call(addr_db, "SCAN", cursor, "MATCH", ROOM_PREFIX .. "*", "COUNT", batch_size)
        if err then
            moon.error("Scan room keys failed: " .. tostring(err))
            break
        end

        cursor = tonumber(res[1])
        local keys = res[2]

        if #keys > 0 then
            local pipeline = {}
            table.insert(pipeline, "DEL")
            for _, key in pairs(keys) do
                table.insert(pipeline, key)
            end
            redis_send(addr_db, table.unpack(pipeline))
        end
    until cursor == 0

    moon.info("All room keys and indexes have been cleared")
end
 
-- 加载所有公会id
function _M.load_guildids(addr)
    local cmd = [[
        SELECT guildId FROM mgame.c_guild;
    ]]
    local res, err = moon.call("lua", addr, cmd)
    if res and #res > 0 then
        local guild_ids = {}
        for _, row in pairs(res) do
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
        local pbdata = crypt.base64decode(res[1].value)
        local _, tmp_data = protocol.decodewithname("PBGuildInfoDB", pbdata)
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
        local pbdata = crypt.base64decode(res[1].value)
        local _, tmp_data = protocol.decodewithname("PBGuildShopDB", pbdata)
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
        local pbdata = crypt.base64decode(res[1].value)
        local _, tmp_data = protocol.decodewithname("PBGuildBagDB", pbdata)
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
        local pbdata = crypt.base64decode(res[1].value)
        local _, tmp_data = protocol.decodewithname("PBGuildRecordDB", pbdata)
        return tmp_data
    end
    print("load_guildrecord failed", guild_id, err)
    return nil
end
function _M.save_guildinfo(addr, guild_id, data)
    assert(data)

    local data_str = jencode(data)
    local _, pbdata = protocol.encodewithname("PBGuildInfoDB", data)
    local pbvalue = crypt.base64encode(pbdata)
    local cmd = string.format([[
        INSERT INTO mgame.c_guild (guildId, value, json)
        VALUES (%d, '%s', '%s')
        ON DUPLICATE KEY UPDATE value = '%s', json = '%s';
    ]], guild_id, pbvalue, data_str, pbvalue, data_str)
    return moon.call("lua", addr, cmd)
end
function _M.save_guildshop(addr, guild_id, data)
    assert(data)

    local data_str = jencode(data)
    local _, pbdata = protocol.encodewithname("PBGuildShopDB", data)
    local pbvalue = crypt.base64encode(pbdata)
    local cmd = string.format([[
        INSERT INTO mgame.c_guild_shop (guildId, value, json)
        VALUES (%d, '%s', '%s')
        ON DUPLICATE KEY UPDATE value = '%s', json = '%s';
    ]], guild_id, pbvalue, data_str, pbvalue, data_str)
    return moon.call("lua", addr, cmd)
end

function _M.save_guildbag(addr, guild_id, data)
    assert(data)

    local data_str = jencode(data)
    local _, pbdata = protocol.encodewithname("PBGuildBagDB", data)
    local pbvalue = crypt.base64encode(pbdata)
    local cmd = string.format([[
        INSERT INTO mgame.c_guild_bag (guildId, value, json)
        VALUES (%d, '%s', '%s')
        ON DUPLICATE KEY UPDATE value = '%s', json = '%s';
    ]], guild_id, pbvalue, data_str, pbvalue, data_str)
    return moon.call("lua", addr, cmd)
end

function _M.save_guildrecord(addr, guild_id, data)
    assert(data)

    local data_str = jencode(data)
    local _, pbdata = protocol.encodewithname("PBGuildRecordDB", data)
    local pbvalue = crypt.base64encode(pbdata)
    local cmd = string.format([[
        INSERT INTO mgame.c_guild_record (guildId, value, json)
        VALUES (%d, '%s', '%s')
        ON DUPLICATE KEY UPDATE value = '%s', json = '%s';
    ]], guild_id, pbvalue, data_str, pbvalue, data_str)
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
            local pbvalue = crypt.base64encode(pbdata)
            had_param = true

            str_param1 = str_param1 .. ", " .. bagTypeName .. ", " .. bagTypeName.. "_json"
            str_param2 = str_param2 .. ", '" .. pbvalue .. "', '" .. data_str .. "'"
            if str_param3 ~= "" then
                str_param3 = str_param3.. ", "
            end
            str_param3 = str_param3 ..
            " " .. bagTypeName .. "='" .. pbvalue .. "', " .. bagTypeName .. "_json='" .. data_str .. "'"
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
                local pbdata = crypt.base64decode(sql_res[1][bagTypeName])
                local _, tmp_data = protocol.decodewithname("PBBag", pbdata)
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
        local pbdata = crypt.base64decode(res[1].value)
        local _, tmp_data = protocol.decodewithname("PBUserGhostDatas", pbdata)
        return tmp_data
    end
    print("loaduserghosts failed", uid, err)
    return nil
end

function _M.saveuserghosts(addr, uid, data)
    assert(data)

    local data_str = jencode(data)
    local _, pbdata = protocol.encodewithname("PBUserGhostDatas", data)
    local pbvalue = crypt.base64encode(pbdata)
    local cmd = string.format([[
        INSERT INTO mgame.ghosts (uid, value, json)
        VALUES (%d, '%s', '%s')
        ON DUPLICATE KEY UPDATE value = '%s', json = '%s';
    ]], uid, pbvalue, data_str, pbvalue, data_str)

    return moon.send("lua", addr, cmd)
end

function _M.loaduseritemimage(addr, uid)
    local cmd = string.format([[
        SELECT value, json FROM mgame.itemimages WHERE uid = %d;
    ]], uid)
    local res, err = moon.call("lua", addr, cmd)
    if res and #res > 0 then
        local pbdata = crypt.base64decode(res[1].value)
        local _, tmp_data = protocol.decodewithname("PBUserImage", pbdata)
        return tmp_data
    end
    print("loaduseritemimage failed", uid, err)
    return nil
end

function _M.saveuseritemimage(addr, uid, data)
    assert(data)

    local data_str = jencode(data)
    local _, pbdata = protocol.encodewithname("PBUserImage", data)
    local pbvalue = crypt.base64encode(pbdata)
    local cmd = string.format([[
        INSERT INTO mgame.itemimages (uid, value, json)
        VALUES (%d, '%s', '%s')
        ON DUPLICATE KEY UPDATE value = '%s', json = '%s';
    ]], uid, pbvalue, data_str, pbvalue, data_str)

    return moon.send("lua", addr, cmd)
end

function _M.loadusercoins(addr, uid)
    local cmd = string.format([[
        SELECT value, json FROM mgame.coins WHERE uid = %d;
    ]], uid)
    local res, err = moon.call("lua", addr, cmd)
    if res and #res > 0 then
        local pbdata = crypt.base64decode(res[1].value)
        local _, tmp_data = protocol.decodewithname("PBUserCoins", pbdata)
        return tmp_data
    end
    print("loadusercoins failed", uid, err)

    return nil
end

function _M.saveusercoins(addr, uid, data)
    assert(data)

    local data_str = jencode(data)
    local _, pbdata = protocol.encodewithname("PBUserCoins", data)
    local pbvalue = crypt.base64encode(pbdata)
    local cmd = string.format([[
        INSERT INTO mgame.coins (uid, value, json)
        VALUES (%d, '%s', '%s')
        ON DUPLICATE KEY UPDATE value = '%s', json = '%s';
    ]], uid, pbvalue, data_str, pbvalue, data_str)

    moon.send("lua", addr, cmd)

    return true
end

-- 记录背包道具变更日志
function _M.ItemChangeLog(addr, uid, config_id, old_num, new_num, mod_uniqid, del_uniqids, add_uniqids,
                          old_item_data, new_item_data, relation_roleid, relation_ghostid, relation_ghost_uniqid, relation_imageid, change_type, change_reason, log_ts)
    local del_uniqids_str = jencode(del_uniqids) or ""
    local add_uniqids_str = jencode(add_uniqids) or ""
    local old_item_data_str = jencode(old_item_data) or ""
    local new_item_data_str = jencode(new_item_data) or ""
    local cmd = string.format([[
        INSERT INTO mlog.bag_change_log (uid, config_id, old_num, new_num, mod_uniqid, del_uniqids,
     add_uniqids, old_item_data, new_item_data, relation_roleid, relation_ghostid, relation_ghost_uniqid, relation_imageid, change_type, change_reason, log_ts)
        VALUES (%d, %d, %d, %d, %d, '%s', '%s', '%s', '%s', %d, %d, %d, %d, %d, %d, %d);
    ]], uid, config_id, old_num, new_num, mod_uniqid, del_uniqids_str, add_uniqids_str, old_item_data_str,
        new_item_data_str, relation_roleid, relation_ghostid, relation_ghost_uniqid, relation_imageid, change_type, change_reason, log_ts)
    moon.send("lua", addr, cmd)
end

function _M.loadfriends(addr, uid)
    local cmd = string.format([[
        SELECT value, json FROM mgame.friends WHERE uid = %d;
    ]], uid)
    local res, err = moon.call("lua", addr, cmd)
    if res and #res > 0 then
        local pbdata = crypt.base64decode(res[1].value)
        local _, tmp_data = protocol.decodewithname("PBUserFriendDatas", pbdata)
        return tmp_data
    end
    print("loadfriends failed", uid, err)
    return nil
end

function _M.savefriends(addr, uid, data)
    assert(data)

    local data_str = jencode(data)
    local _, pbdata = protocol.encodewithname("PBUserFriendDatas", data)
    local pbvalue = crypt.base64encode(pbdata)
    local cmd = string.format([[
        INSERT INTO mgame.friends (uid, value, json)
        VALUES (%d, '%s', '%s')
        ON DUPLICATE KEY UPDATE value = '%s', json = '%s';
    ]], uid, pbvalue, data_str, pbvalue, data_str)

    return moon.send("lua", addr, cmd)
end

-- 好友离线数据前缀常量
local FRIEND_RELATION = "friend_relation"

function _M.RedisGetFriendRelation(addr_db_redis, uids)
    local res, err = redis_call(addr_db_redis, "HMGET", FRIEND_RELATION, table.unpack(uids))
    if err then
        error("RedisGetFriendRelation failed:" .. tostring(err))
        return {}
    end
    local user_relations = {}
    if res and #res > 0 then
        moon.warn(string.format("RedisGetFriendRelation res = %s", json.pretty_encode(res)))
        for i = 1, #res do
            user_relations[uids[i]] = json.decode(res[i] or "null")
        end
    end

    return user_relations
end

function _M.RedisSetFriendRelation(addr_db_redis, user_relations)
    local tmp = {}
    for uid, relations in pairs(user_relations) do
        table.insert(tmp, uid)
        table.insert(tmp, json.encode(relations))
    end
    redis_send(addr_db_redis, "HSET", FRIEND_RELATION, table.unpack(tmp))
end

function _M.loadmails(addr, uid)
    local cmd = string.format([[
        SELECT value, json FROM mgame.mails WHERE uid = %d;
    ]], uid)
    local res, err = moon.call("lua", addr, cmd)
    if res and #res > 0 then
        local pbdata = crypt.base64decode(res[1].value)
        local _, tmp_data = protocol.decodewithname("PBUserMailBox", pbdata)
        return tmp_data
    end
    print("loadmails failed", uid, err)
    return nil
end

function _M.savemails(addr, uid, data)
    assert(data)

    local data_str = jencode(data)
    local _, pbdata = protocol.encodewithname("PBUserMailBox", data)
    local pbvalue = crypt.base64encode(pbdata)
    local cmd = string.format([[
        INSERT INTO mgame.mails (uid, value, json)
        VALUES (%d, '%s', '%s')
        ON DUPLICATE KEY UPDATE value = '%s', json = '%s';
    ]], uid, pbvalue, data_str, pbvalue, data_str)

    return moon.send("lua", addr, cmd)
end

function _M.select_mailids(addr, uid, last_system_mail_id, now_ts)
    local cmd = string.format([[
        SELECT mail_id FROM mgame.system_mail WHERE mail_id > %d AND end_ts > %d AND valid = 1 AND (all_user = 1 OR JSON_CONTAINS(recv_uids, '%d'));
    ]], last_system_mail_id, now_ts, uid)
    local res, err = moon.call("lua", addr, cmd)
    if err then
        moon.error(string.format("select_mailids err = %s", json.pretty_encode(err)))
        return nil
    else
        if res then
            local mail_ids = {}
            for _, row in pairs(res) do
                mail_ids[row.mail_id] = 1
            end
            return mail_ids
        end
    end
    print("select_mailids failed", uid, err)
    return nil
end

function _M.select_expire_mailids(addr, uid, now_ts)
    local cmd = string.format([[
        SELECT mail_id FROM mgame.system_mail WHERE end_ts > %d AND valid = 0 AND (all_user = 1 OR JSON_CONTAINS(recv_uids, CAST(%d AS JSON), '$'));
    ]], now_ts, uid)
    local res, err = moon.call("lua", addr, cmd)
    if err then
        moon.error(string.format("select_expire_mailids err = %s", json.pretty_encode(err)))
        return nil
    else
        if res then
            local mail_ids = {}
            for _, row in pairs(res) do
                mail_ids[row.mail_id] = 1
            end
            return mail_ids
        end
    end
    print("select_expire_mailids failed", uid, err)
    return nil
end

function _M.add_system_mail(addr, mail_info, all_user, recv_uids)
    local items_str = jencode(mail_info.items_simple)
    local item_datas_str = jencode(mail_info.item_datas)
    local coins_str = jencode(mail_info.coins)
    local uids_str = json.encode(recv_uids)
    local _, pbdata = protocol.encodewithname("PBMailData", mail_info)
    local pbvalue = crypt.base64encode(pbdata)
    local cmd = string.format([[
        INSERT INTO mgame.system_mail (mail_type, beg_ts, end_ts, mail_title_id, mail_title, mail_icon_id, mail_content_id, mail_content, sign, items_simple, item_datas, coins, mail_data, all_user, recv_uids, valid)
        VALUES (%d, %d, %d, %d, '%s', %d, %d, '%s', '%s', '%s', '%s', '%s', '%s', %d, '%s', %d);
    ]], mail_info.simple_data.mail_type, mail_info.simple_data.beg_ts, mail_info.simple_data.end_ts,
    mail_info.simple_data.mail_title_id, mail_info.simple_data.mail_title, mail_info.mail_icon_id,
        mail_info.mail_content_id, mail_info.mail_content, mail_info.sign, items_str, item_datas_str,
        coins_str, pbvalue, all_user, uids_str, 1)

    local res, err = moon.call("lua", addr, cmd)
    if err then
        moon.error(string.format("add_system_mail err = %s", json.pretty_encode(err)))
        return 0
    else
        if res then
            moon.debug(string.format("add_system_mail res = %s", json.pretty_encode(res)))
            return res.insert_id
        end
    end

    return 0
end

function _M.invalid_system_mail(addr, mail_id)
    local cmd = string.format([[
        UPDATE mgame.system_mail SET valid = 0 WHERE mail_id = %d;
    ]], mail_id)

    local res, err = moon.call("lua", addr, cmd)
    if err then
        moon.error(string.format("invalid_system_mail err = %s", json.pretty_encode(err)))
        return 0
    else
        if res then
            moon.debug(string.format("invalid_system_mail res = %s", json.pretty_encode(res)))
            return res.affected_rows
        end
    end

    return 0
end

function _M.get_last_system_mail_id(addr)
    local cmd = string.format([[
        SELECT mail_id FROM mgame.system_mail ORDER BY mail_id DESC LIMIT 1;
    ]])
    local res, err = moon.call("lua", addr, cmd)
    if res and res[1] then
        return tonumber(res[1].mail_id) or 0
    end
    return 0
end

-- 好友离线数据前缀常量
local SYSTEM_MAIL_INFO = "system_mail_info"

function _M.RedisGetSystemMailsInfo(addr_db_redis, mail_ids)
    local res, err = redis_call(addr_db_redis, "HMGET", SYSTEM_MAIL_INFO, table.unpack(mail_ids))
    if err then
        error("RedisGetSystemMailsInfo failed:" .. tostring(err))
        return {}
    end
    local mails_info = {}
    if res and #res > 0 then
        moon.warn(string.format("RedisGetSystemMailsInfo res = %s", json.pretty_encode(res)))
        for i = 1, #res do
            mails_info[mail_ids[i]] = json.decode(res[i] or "null")
        end
    end

    return mails_info
end

function _M.RedisSetSystemMailsInfo(addr_db_redis, mail_info)
    local tmp = {}
    table.insert(tmp, mail_info.simple_data.mail_id)
    table.insert(tmp, json.encode(mail_info))
    redis_send(addr_db_redis, "HSET", SYSTEM_MAIL_INFO, table.unpack(tmp))
end

function _M.RedisDelSystemMailsInfo(addr_db_redis, mail_id)
    redis_send(addr_db_redis, "HDEL", SYSTEM_MAIL_INFO, mail_id)
end

function _M.loadtradeinfo(addr, uid)
    local cmd = string.format([[
        SELECT value, json FROM mgame.trades WHERE uid = %d;
    ]], uid)
    local res, err = moon.call("lua", addr, cmd)
    if res and #res > 0 then
        local pbdata = crypt.base64decode(res[1].value)
        local _, tmp_data = protocol.decodewithname("PBSelfTradeInfo", pbdata)
        return tmp_data
    end
    print("loadtradeinfo failed", uid, err)
    return nil
end

function _M.savetradeinfo(addr, uid, data)
    assert(data)

    local data_str = jencode(data)
    local _, pbdata = protocol.encodewithname("PBSelfTradeInfo", data)
    local pbvalue = crypt.base64encode(pbdata)
    local cmd = string.format([[
        INSERT INTO mgame.trades (uid, value, json)
        VALUES (%d, '%s', '%s')
        ON DUPLICATE KEY UPDATE value = '%s', json = '%s';
    ]], uid, pbvalue, data_str, pbvalue, data_str)

    return moon.send("lua", addr, cmd)
end

function _M.getmaxtradeid(addr)
    local res, err = moon.call("lua", addr, "SELECT MAX(trade_id) as max_trade_id FROM mgame.trade_product;")
    if err then
        error("getmaxtradeid failed:" .. tostring(err))
        return -1
    end
    if res and res[1] then
        return tonumber(res[1].max_trade_id) or 0
    end
    return 0
end

function _M.addtradeproduct(addr, product_data, condition1, condition2, condition3, condition4, condition5)
    -- local item_data_str = jencode(product_data.item_data)
    -- local _, pbdata = protocol.encodewithname("PBItemData", product_data.item_data)
    -- local pbvalue = crypt.base64encode(pbdata)
    local cmd = string.format([[
        INSERT INTO mgame.trade_product (trade_id, config_id, total_num, seller_uid, beg_ts, end_ts,
        single_price, sale_num, now_num, condition1, condition2,
        condition3, condition4, condition5, state)
        VALUES (%d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d);
    ]], product_data.trade_id, product_data.config_id, product_data.total_num,
        product_data.seller_uid, product_data.beg_ts, product_data.end_ts,
        product_data.trade_data.single_price, product_data.trade_data.sale_num,
        product_data.trade_data.now_num, condition1, condition2, condition3, condition4, condition5, product_data.state)

    local res, err = moon.call("lua", addr, cmd)
    if err then
        moon.error(string.format("addtradeproduct err = %s", json.pretty_encode(err)))
        return 0
    else
        if res then
            moon.debug(string.format("addtradeproduct res = %s", json.pretty_encode(res)))
            return res.insert_id
        end
    end
end

function _M.gettradeproductwithnum(addr, start_trade_id, state, num)
    local cmd = string.format([[
        SELECT trade_id, config_id, total_num, seller_uid, beg_ts, end_ts, single_price, sale_num, now_num, state FROM mgame.trade_product WHERE trade_id >= %d AND state = %d ORDER BY trade_id LIMIT %d;
    ]], start_trade_id, state, num)
    local res, err = moon.call("lua", addr, cmd)
    if err then
        moon.error(string.format("gettradeproductwithnum err = %s", json.pretty_encode(err)))
        return nil
    end

    if res and #res > 0 then
        local ret = {}
        for i = 1, #res do
            local trade_product = TradeDef.newTradeProductBaseData()
            trade_product.trade_id = res[i].trade_id
            trade_product.config_id = res[i].config_id
            trade_product.total_num = res[i].total_num
            trade_product.seller_uid = res[i].seller_uid
            trade_product.beg_ts = res[i].beg_ts
            trade_product.end_ts = res[i].end_ts
            trade_product.state = res[i].state
            trade_product.trade_data.single_price = res[i].single_price
            trade_product.trade_data.sale_num = res[i].sale_num
            trade_product.trade_data.now_num = res[i].now_num

            table.insert(ret, trade_product)
        end
        return ret
    end
    moon.error("gettradeproductwithnum failed", start_trade_id, num, err)
    return nil
end

function _M.gettradeproductwithids(addr, trade_ids)
    local where_str = ""
    if #trade_ids == 1 then
        where_str = "trade_id = " .. trade_ids[1] .. " AND state=" .. TradeDef.StateType.ON_SALE
    else
        where_str = "trade_id IN ("
        for i = 1, #trade_ids do
            where_str = where_str .. trade_ids[i]
            if i < #trade_ids then
                where_str = where_str .. ","
            end
        end
        where_str = where_str .. ") AND state=" .. TradeDef.StateType.ON_SALE
    end

    local cmd = string.format([[
        SELECT trade_id, config_id, total_num, seller_uid, beg_ts, end_ts, single_price, sale_num, now_num, state FROM mgame.trade_product WHERE %s;
    ]], where_str)
    local res, err = moon.call("lua", addr, cmd)
    if err then
        moon.error(string.format("gettradeproductwithids err = %s", json.pretty_encode(err)))
        return nil
    end
    if res and #res > 0 then
        local ret = {}
        for i = 1, #res do
            local trade_product = TradeDef.newTradeProductBaseData()
            trade_product.trade_id = res[i].trade_id
            trade_product.config_id = res[i].config_id
            trade_product.total_num = res[i].total_num
            trade_product.seller_uid = res[i].seller_uid
            trade_product.beg_ts = res[i].beg_ts
            trade_product.end_ts = res[i].end_ts
            trade_product.state = res[i].state
            trade_product.trade_data.single_price = res[i].single_price
            trade_product.trade_data.sale_num = res[i].sale_num
            trade_product.trade_data.now_num = res[i].now_num

            table.insert(ret, trade_product)
        end
        return ret
    end
    moon.error("gettradeproductwithids failed", where_str, err)
    return nil
end

function _M.gettradeproduct(addr, where_data, num)
    local where_str = ""
    local where_fields = {}
    if where_data then
        for field, value in pairs(where_data) do
            if field == "trade_id" or field == "config_id" or field == "seller_uid"
                or field == "beg_ts" or field == "end_ts" or field == "single_price"
                or field == "sale_num" or field == "now_num" or field == "state" then
                -- 数值型字段
                table.insert(where_fields, string.format("%s = %d", field, value))
            else
                -- 对于未知字段，可以选择忽略或报错
                moon.error("gettradeproduct: unknown field '%s', skipping", field)
                return false
            end
        end
    end
    if #where_fields > 0 then
        where_str = where_str .. table.concat(where_fields, " AND ")
    end

    local cmd = string.format([[
        SELECT trade_id, config_id, total_num, seller_uid, beg_ts, end_ts, single_price, sale_num, now_num, state FROM mgame.trade_product WHERE %s LIMIT %d;
    ]], where_str, num)
    local res, err = moon.call("lua", addr, cmd)
    if err then
        moon.error(string.format("gettradeproduct err = %s", json.pretty_encode(err)))
        return nil
    end
    if res and #res > 0 then
        local ret = {}
        for i = 1, #res do
            local trade_product = TradeDef.newTradeProductBaseData()
            trade_product.trade_id = res[i].trade_id
            trade_product.config_id = res[i].config_id
            trade_product.total_num = res[i].total_num
            trade_product.seller_uid = res[i].seller_uid
            trade_product.beg_ts = res[i].beg_ts
            trade_product.end_ts = res[i].end_ts
            trade_product.state = res[i].state
            trade_product.trade_data.single_price = res[i].single_price
            trade_product.trade_data.sale_num = res[i].sale_num
            trade_product.trade_data.now_num = res[i].now_num

            table.insert(ret, trade_product)
        end
        return ret
    end
    moon.error("gettradeproduct failed", where_str, err)
    return nil
end

function _M.updatetradeproductwithids(addr, trade_ids, where_data, update_data)
    if not update_data or type(update_data) ~= "table" then
        moon.error("updatetradeproductwithids: update_data should be a table")
        return false
    end

    local where_str = "trade_id IN ("
    for i = 1, #trade_ids do
        where_str = where_str .. trade_ids[i]
        if i < #trade_ids then
            where_str = where_str .. ","
        end
    end
    where_str = where_str .. ") "

    local where_fields = {}
    if where_data then
        for field, value in pairs(where_data) do
            if field == "state" then
                -- 数值型字段
                table.insert(where_fields, string.format("%s = %d", field, value))
            else
                -- 对于未知字段，可以选择忽略或报错
                moon.error("updatetradeproductwithids: unknown field '%s', skipping", field)
                return false
            end
        end
    end
    if #where_fields > 0 then
        where_str = where_str .. " AND " .. table.concat(where_fields, " AND ")
    end

    local update_fields = {}
    for field, value in pairs(update_data) do
        if field == "beg_ts" or field == "end_ts" or field == "single_price" or field == "sale_num"
            or field == "now_num" or field == "state" or field == "condition1" or field == "condition2"
            or field == "condition3" or field == "condition4" or field == "condition5" then
            -- 数值型字段
            table.insert(update_fields, string.format("%s = %d", field, value))
        else
            -- 对于未知字段，可以选择忽略或报错
            moon.error("updatetradeproductwithids: unknown field '%s', skipping", field)
        end
    end
    if #update_fields == 0 then
        moon.error("updatetradeproductwithids: no valid fields to update")
        return false
    end

    local cmd = string.format([[
        UPDATE mgame.trade_product SET %s WHERE %s;
    ]], table.concat(update_fields, ", "), where_str)

    return moon.send("lua", addr, cmd)
end

function _M.updatetradeproduct(addr, trade_id, where_data, update_data, need_ret)
    if not update_data or type(update_data) ~= "table" then
        moon.error("updatetradeproduct: update_data should be a table")
        return 0
    end

    local where_str = string.format("WHERE trade_id = %d", trade_id)

    local where_fields = {}
    if where_data then
        for field, value in pairs(where_data) do
            if field == "state" then
                -- 数值型字段
                table.insert(where_fields, string.format("%s = %d", field, value))
            else
                -- 对于未知字段，可以选择忽略或报错
                moon.error("updatetradeproduct: unknown field '%s', skipping", field)
                return 0
            end
        end
    end
    if #where_fields > 0 then
        where_str = where_str .. " AND " .. table.concat(where_fields, " AND ")
    end

    local update_fields = {}
    for field, value in pairs(update_data) do
        if field == "beg_ts" or field == "end_ts" or field == "single_price" or field == "sale_num"
            or field == "now_num" or field == "state" or field == "condition1" or field == "condition2"
            or field == "condition3" or field == "condition4" or field == "condition5" then
            -- 数值型字段
            table.insert(update_fields, string.format("%s = %d", field, value))
        else
            -- 对于未知字段，可以选择忽略或报错
            moon.error("updatetradeproduct: unknown field '%s', skipping", field)
        end
    end
    if #update_fields == 0 then
        moon.error("updatetradeproduct: no valid fields to update")
        return 0
    end

    local cmd = string.format([[
        UPDATE mgame.trade_product SET %s WHERE %s;
    ]], table.concat(update_fields, ", "), where_str)
    if need_ret then
        local res, err = moon.call("lua", addr, cmd)
        if err then
            moon.error(string.format("updatetradeproduct err = %s", json.pretty_encode(err)))
            return 0
        else
            if res then
                moon.debug(string.format("updatetradeproduct res = %s", json.pretty_encode(res)))
                return res.affected_rows
            end
        end
        return 0
    else
        moon.send("lua", addr, cmd)
        return 0
    end
end

function _M.addauctionproduct(addr, product_data, condition1, condition2, condition3, condition4, condition5, custome_condition)
    local item_data_str = jencode(product_data.item_data)
    local _, pbdata = protocol.encodewithname("PBItemData", product_data.item_data)
    local pbvalue = crypt.base64encode(pbdata)
    local custome_condition_str = jencode(custome_condition)
    local cmd = string.format([[
        INSERT INTO mgame.auction_product (trade_id, config_id, uniqid, seller_uid, beg_ts, end_ts, item_data, item_data_json, start_price, buyout_price, cur_price, buyer_uid, condition1, condition2, condition3, condition4, condition5, custome_condition, state) VALUES (%d, %d, %d, %d, %d, %d, '%s', '%s', %d, %d, %d, %d, %d, %d, %d, %d, %d, '%s', %d);]],
        product_data.trade_id, product_data.item_data.common_info.config_id, product_data.item_data.common_info.uniqid,
        product_data.seller_uid, product_data.beg_ts, product_data.end_ts, pbvalue, item_data_str,
        product_data.auction_data.start_price, product_data.auction_data.buyout_price,
        product_data.auction_data.cur_price, product_data.auction_data.buyer_uid, condition1, condition2, condition3,
        condition4, condition5, custome_condition_str, product_data.state)
        
    local res, err = moon.call("lua", addr, cmd)
    if err then
        moon.error(string.format("addauctionproduct err = %s", json.pretty_encode(err)))
        return 0
    else
        if res then
            moon.debug(string.format("addauctionproduct res = %s", json.pretty_encode(res)))
            return res.insert_id
        end
    end
end

function _M.updatetraderecord(addr, record_data, condition1, condition2, condition3, condition4, condition5)
    assert(record_data)

    local cmd = string.format([[
        INSERT INTO mgame.trade_record (trade_config_id, sale_num, sale_total_price, last_deal_price, update_ts, yes_sale_num, yes_sale_total_price, yes_average_price, min_price, min_price_num, condition1, condition2, condition3, condition4, condition5)
        VALUES (%d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d, %d)
        ON DUPLICATE KEY UPDATE sale_num = %d, sale_total_price = %d, last_deal_price = %d, update_ts = %d, yes_sale_num = %d, yes_sale_total_price = %d, yes_average_price = %d, min_price = %d, min_price_num = %d, condition1 = %d, condition2 = %d, condition3 = %d, condition4 = %d, condition5 = %d;
    ]], record_data.trade_config_id, record_data.sale_num, record_data.sale_total_price, record_data.last_deal_price,
        record_data.update_ts, record_data.yes_sale_num, record_data.yes_sale_total_price, record_data.yes_average_price,
        record_data.min_price, record_data.min_price_num, condition1, condition2, condition3, condition4, condition5,
        record_data.sale_num, record_data.sale_total_price, record_data.last_deal_price, record_data.update_ts, record_data.yes_sale_num,
        record_data.yes_sale_total_price, record_data.yes_average_price, record_data.min_price,
        record_data.min_price_num, condition1, condition2, condition3, condition4, condition5)

    return moon.send("lua", addr, cmd)
end

function _M.gettraderecordwithids(addr, ids, sort_describe)
    local where_str = "trade_config_id IN ("
    for i = 1, #ids do
        where_str = where_str .. ids[i]
        if i < #ids then
            where_str = where_str .. ","
        end
    end
    where_str = where_str .. ")"

    local cmd = string.format([[
        SELECT trade_config_id, last_deal_price, yes_average_price, min_price, min_price_num FROM mgame.trade_record WHERE %s ORDER BY %s;
    ]], where_str, sort_describe)
    local res, err = moon.call("lua", addr, cmd)
    if err then
        moon.error(string.format("gettraderecordwithids err = %s", json.pretty_encode(err)))
        return nil
    end
    if res and #res > 0 then
        local trade_records = {}
        for i = 1, #res do
            local record = TradeDef.newTradeSearchSimpleData()
            record.config_id = res[i].trade_config_id
            record.min_price = res[i].min_price
            record.last_deal_price = res[i].last_deal_price
            record.yes_average_price = res[i].yes_average_price
            record.min_price_num = res[i].min_price_num
            table.insert(trade_records, record)
        end
        return trade_records
    end
    moon.error("gettraderecordwithids failed", where_str, err)
    return nil
end

function _M.gettraderecordswithconditions(addr, condition1, condition2, condition3, condition4, condition5
    , sort_describe, start_idx, num)
    local where_str = "WHERE "
    if condition1 > 0 then
        where_str = where_str .. string.format("condition1=%d", condition1)
    end
    if condition2 > 0 then
        if where_str ~= "WHERE " then
            where_str = where_str .. " AND "
        end
        where_str = where_str .. string.format("condition2=%d", condition2)
    end
    if condition3 > 0 then
        if where_str ~= "WHERE " then
            where_str = where_str .. " AND "
        end
        where_str = where_str .. string.format("condition3 = %d", condition3)
    end
    if condition4 > 0 then
        if where_str ~= "WHERE " then
            where_str = where_str .. " AND "
        end
        where_str = where_str .. string.format("condition4 = %d", condition4)
    end
    if condition5 > 0 then
        if where_str ~= "WHERE " then
            where_str = where_str .. " AND "
        end
        where_str = where_str .. string.format("condition5 = %d", condition5)
    end

    if where_str == "WHERE " then
        where_str = ""
    end

    local cmd = string.format([[
        SELECT trade_config_id, last_deal_price, yes_average_price, min_price, min_price_num FROM mgame.trade_record WHERE %s ORDER BY %s LIMIT %d OFFSET %d;
    ]], where_str, sort_describe, num, start_idx)
    local res, err = moon.call("lua", addr, cmd)
    if err then
        moon.error(string.format("gettraderecordswithconditions err = %s", json.pretty_encode(err)))
        return nil
    end
    if res and #res > 0 then
        local trade_records = {}
        for i = 1, #res do
            local record = TradeDef.newTradeSearchSimpleData()
            record.config_id = res[i].trade_config_id
            record.min_price = res[i].min_price
            record.last_deal_price = res[i].last_deal_price
            record.yes_average_price = res[i].yes_average_price
            record.min_price_num = res[i].min_price_num
            table.insert(trade_records, record)
        end
        return trade_records
    end
    moon.error("gettraderecordswithconditions failed", where_str, err)
    return nil
end

function _M.gettraderecordseq(addr, start_config_id, num)
    local cmd = string.format([[
        SELECT trade_config_id, sale_num, sale_total_price, last_deal_price, update_ts, yes_sale_num, yes_sale_total_price, yes_average_price, min_price, min_price_num, condition1, condition2, condition3, condition4, condition5 FROM mgame.trade_record WHERE trade_config_id > %d ORDER BY trade_config_id ASC LIMIT %d;
    ]], start_config_id, num)
    local res, err = moon.call("lua", addr, cmd)
    if err then
        moon.error(string.format("gettraderecordseq err = %s", json.pretty_encode(err)))
        return nil
    end
    if res and #res > 0 then
        local ret = {}
        for i = 1, #res do
            local record = {}
            record.trade_config_id = res[i].trade_config_id
            record.sale_num = res[i].sale_num
            record.sale_total_price = res[i].sale_total_price
            record.last_deal_price = res[i].last_deal_price
            record.update_ts = res[i].update_ts
            record.yes_sale_num = res[i].yes_sale_num
            record.yes_sale_total_price = res[i].yes_sale_total_price
            record.yes_average_price = res[i].yes_average_price
            record.min_price = res[i].min_price
            record.min_price_num = res[i].min_price_num
            record.condition1 = res[i].condition1
            record.condition2 = res[i].condition2
            record.condition3 = res[i].condition3
            record.condition4 = res[i].condition4
            record.condition5 = res[i].condition5
            table.insert(ret, record)
        end
        return ret
    end
    moon.error("gettraderecordseq failed", start_config_id, num, err)
    return nil
end

-- function _M.RedisAddCompletelogid(addr_db_redis, uid, log_id)
--     local redis_key = string.format("trade:completed:log_ids:%d", uid)
--     redis_send(addr_db_redis, "SADD", redis_key, log_id)
-- end

-- function _M.RedisDelProductData(addr_db_redis, product_ids)
--     redis_send(addr_db_redis, "HDEL", PRODUCT_DATA, table.unpack(product_ids))
-- end

function _M.getmaxtradelogid(addr)
    local res, err = moon.call("lua", addr, "SELECT MAX(log_id) as max_log_id FROM mgame.trade_log;")
    if err then
        error("getmaxtradelogid failed:" .. tostring(err))
        return -1
    end
    if res and res[1] then
        return tonumber(res[1].max_log_id) or 0
    end
    return 0
end

function _M.loadplayertradelog(addr, uid)
    local cmd = string.format([[
        SELECT log_id, trade_id, config_id, deal_num, deal_price, seller_uid, buyer_uid, trade_ts,
        trade_tax, send_mail FROM mgame.trade_log WHERE (seller_uid = %d OR buyer_uid = %d)
        ORDER BY trade_ts DESC LIMIT 100;
    ]], uid, uid)
    local res, err = moon.call("lua", addr, cmd)
    if res and #res > 0 then
        local trade_logs = {}
        for i = 1, #res do
            local trade_log = TradeDef.newTradeLogData()
            trade_log.log_id = res[i].log_id
            trade_log.trade_id = res[i].trade_id
            trade_log.config_id = res[i].config_id
            trade_log.deal_num = res[i].deal_num
            trade_log.deal_price = res[i].deal_price
            trade_log.seller_uid = res[i].seller_uid
            trade_log.buyer_uid = res[i].buyer_uid
            trade_log.trade_ts = res[i].trade_ts
            trade_log.trade_tax = res[i].trade_tax
            trade_log.send_mail = res[i].send_mail
            table.insert(trade_logs, trade_log)
        end
        return trade_logs
    end
    moon.error("loadplayertradelog failed", uid, err)
    return nil
end

function _M.addtradelog(addr, trade_log)
    local cmd = string.format([[
        INSERT INTO mgame.trade_log (log_id, trade_id, config_id, deal_num, deal_price, seller_uid, buyer_uid,
        trade_ts, trade_tax, send_mail)
        VALUES (%d, %d, %d, %d, %d, %d, %d, %d, %d, %d);
    ]], trade_log.log_id, trade_log.trade_id, trade_log.config_id, trade_log.deal_num, trade_log.deal_price,
        trade_log.seller_uid, trade_log.buyer_uid, trade_log.trade_ts, trade_log.trade_tax, trade_log.send_mail)

    return moon.send("lua", addr, cmd)
end

function _M.updatetradelog(addr, log_id, send_mail)
    local cmd = string.format([[
        UPDATE mgame.trade_log SET send_mail = %d WHERE log_id = %d;
    ]], send_mail, log_id)
    return moon.send("lua", addr, cmd)
end

function _M.gettradelog(addr, log_id)
    local cmd = string.format([[
        SELECT log_id, trade_id, config_id, deal_num, deal_price, seller_uid, buyer_uid, trade_ts,
        trade_tax, send_mail FROM mgame.trade_log WHERE log_id = %d;
    ]], log_id)
    local res, err = moon.call("lua", addr, cmd)
    if res and #res > 0 then
        local pbdata = crypt.base64decode(res[1].item_data)
        local _, item_data = protocol.decodewithname("PBItemData", pbdata)
        local trade_log = TradeDef.newTradeLogData()
        trade_log.log_id = res[1].log_id
        trade_log.trade_id = res[1].trade_id
        trade_log.config_id = res[1].config_id
        trade_log.deal_num = res[1].deal_num
        trade_log.deal_price = res[1].deal_price
        trade_log.seller_uid = res[1].seller_uid
        trade_log.buyer_uid = res[1].buyer_uid
        trade_log.trade_ts = res[1].trade_ts
        trade_log.trade_tax = res[1].trade_tax
        trade_log.send_mail = res[1].send_mail
        return trade_log
    end
    moon.error("gettradelog failed", log_id, err)
    return nil
end

function _M.gettradelognomail(addr, uid)
    local cmd = string.format([[
        SELECT log_id, trade_id, config_id, deal_num, deal_price, seller_uid, buyer_uid, trade_ts,
        trade_tax, send_mail FROM mgame.trade_log WHERE seller_uid = %d;
    ]], uid)
    local res, err = moon.call("lua", addr, cmd)
    if res and #res > 0 then
        local trade_logs = {}
        for i = 1, #res do
            local trade_log = TradeDef.newTradeLogData()
            trade_log.log_id = res[i].log_id
            trade_log.trade_id = res[i].trade_id
            trade_log.config_id = res[i].config_id
            trade_log.deal_num = res[i].deal_num
            trade_log.deal_price = res[i].deal_price
            trade_log.seller_uid = res[i].seller_uid
            trade_log.buyer_uid = res[i].buyer_uid
            trade_log.trade_ts = res[i].trade_ts
            trade_log.trade_tax = res[i].trade_tax
            trade_log.send_mail = res[i].send_mail
            trade_logs[trade_log.trade_id] = trade_log
        end
        return trade_logs
    end
    moon.error("loadplayertradelog failed", uid, err)
    return nil
end

function _M.loadplayerauctionlog(addr, uid)
    local cmd = string.format([[
        SELECT log_id, auction_id, deal_price, seller_uid, buyer_uid, trade_ts, trade_tax,
        item_data FROM mgame.auction_log WHERE (seller_uid = %d OR buyer_uid = %d)
        ORDER BY trade_ts DESC LIMIT 100;
    ]], uid, uid)
    local res, err = moon.call("lua", addr, cmd)
    if res and #res > 0 then
        local auction_logs = {}
        for i = 1, #res do
            local pbdata = crypt.base64decode(res[i].item_data)
            local _, item_data = protocol.decodewithname("PBItemData", pbdata)

            local auction_log = TradeDef.newAuctionLogData()
            auction_log.log_id = res[i].log_id
            auction_log.auction_id = res[i].auction_id
            auction_log.deal_price = res[i].deal_price
            auction_log.seller_uid = res[i].seller_uid
            auction_log.buyer_uid = res[i].buyer_uid
            auction_log.trade_ts = res[i].trade_ts
            auction_log.trade_tax = res[i].trade_tax
            auction_log.item_data = item_data
            auction_logs[auction_log.auction_id] = auction_log
        end
        return auction_logs
    end
    moon.error("loadplayerauctionlog failed", uid, err)
    return nil
end

function _M.addauctionlog(addr, auction_log)
    local item_data_str = jencode(auction_log.item_data)
    local _, pbdata = protocol.encodewithname("PBItemData", auction_log.item_data)
    local pbvalue = crypt.base64encode(pbdata)

    local cmd = string.format([[
        INSERT INTO mgame.auction_log (auction_id, deal_price, seller_uid, buyer_uid, trade_ts,
        trade_tax, item_data, item_data_json)
        VALUES (%d, %d, %d, %d, %d, %d, '%s', '%s');
    ]], auction_log.auction_id, auction_log.deal_price, auction_log.seller_uid, auction_log.buyer_uid, auction_log.trade_ts, auction_log.trade_tax, pbvalue, item_data_str)

    return moon.send("lua", addr, cmd)
end

function _M.getauctionlog(addr, log_id)
    local cmd = string.format([[
        SELECT log_id, auction_id, deal_price, seller_uid, buyer_uid, trade_ts, trade_tax,
        item_data FROM mgame.auction_log WHERE log_id = %d;
    ]], log_id)
    local res, err = moon.call("lua", addr, cmd)
    if res and #res > 0 then
        local pbdata = crypt.base64decode(res[1].item_data)
        local _, item_data = protocol.decodewithname("PBItemData", pbdata)
        local auction_log = TradeDef.newAuctionLogData()
        auction_log.log_id = res[1].log_id
        auction_log.auction_id = res[1].auction_id
        auction_log.deal_price = res[1].deal_price
        auction_log.seller_uid = res[1].seller_uid
        auction_log.buyer_uid = res[1].buyer_uid
        auction_log.trade_ts = res[1].trade_ts
        auction_log.trade_tax = res[1].trade_tax
        auction_log.item_data = item_data
        return auction_log
    end
    moon.error("getauctionlog failed", log_id, err)
    return nil
end

-- 交易行数据前缀常量
local PRODUCT_DATA = "product_data"

function _M.RedisGetProductData(addr_db_redis, product_ids)
    local res, err = redis_call(addr_db_redis, "HMGET", PRODUCT_DATA, table.unpack(product_ids))
    if err then
        moon.error("RedisGetProductData failed:" .. tostring(err))
        return {}
    end
    local product_datas = {}
    if res and #res > 0 then
        moon.warn(string.format("RedisGetProductData res = %s", json.pretty_encode(res)))
        for i = 1, #res do
            product_datas[product_ids[i]] = json.decode(res[i] or "null")
        end
    end

    return product_datas
end

function _M.RedisSetProductData(addr_db_redis, product_data)
    local tmp = {}
    table.insert(tmp, product_data.trade_id)
    table.insert(tmp, json.encode(product_data))
    redis_send(addr_db_redis, "HSET", PRODUCT_DATA, table.unpack(tmp))
end

function _M.RedisDelProductData(addr_db_redis, product_ids)
    redis_send(addr_db_redis, "HDEL", PRODUCT_DATA, table.unpack(product_ids))
end

-- 商店数据
function _M.loadshopinfo(addr, uid)
    local cmd = string.format([[
        SELECT value, json FROM mgame.shops WHERE uid = %d;
    ]], uid)
    local res, err = moon.call("lua", addr, cmd)
    if res and #res > 0 then
        local pbdata = crypt.base64decode(res[1].value)
        local _, tmp_data = protocol.decodewithname("PBShopPlayerData", pbdata)
        return tmp_data
    end
    moon.error("loadshopinfo failed", uid, err)
    return nil
end

function _M.saveshopinfo(addr, uid, data)
    assert(data)

    local data_str = jencode(data)
    local _, pbdata = protocol.encodewithname("PBShopPlayerData", data)
    local pbvalue = crypt.base64encode(pbdata)
    local cmd = string.format([[
        INSERT INTO mgame.shops (uid, value, json)
        VALUES (%d, '%s', '%s')
        ON DUPLICATE KEY UPDATE value = '%s', json = '%s';
    ]], uid, pbvalue, data_str, pbvalue, data_str)

    return moon.send("lua", addr, cmd)
end

function _M.loadshopserversale(addr, product_ids)
    if not product_ids or table.size(product_ids) == 0 then
        local cmd = string.format([[
            SELECT product_id, sale_num FROM mgame.shop_server_sale;
        ]])
        local res, err = moon.call("lua", addr, cmd)
        if res and #res > 0 then
            local shop_server_sale = {}
            for i = 1, #res do
                shop_server_sale[res[i].product_id] = res[i].sale_num
            end
            return shop_server_sale
        end
        moon.error("loadshopserversale failed", err)
        return nil
    else
        local product_id_str = table.concat(product_ids, ",")
        local cmd = string.format([[
            SELECT product_id, sale_num FROM mgame.shop_server_sale WHERE product_id IN (%s);
        ]], product_id_str)
        local res, err = moon.call("lua", addr, cmd)
        if res and #res > 0 then
            local shop_server_sale = {}
            for i = 1, #res do
                shop_server_sale[res[i].product_id] = res[i].sale_num
            end
            return shop_server_sale
        end
        moon.error("loadshopserversale failed", err)
        return nil
    end
end

function _M.saveshopserversale(addr, shop_server_sale)
    assert(shop_server_sale)

    for product_id, sale_num in pairs(shop_server_sale) do
        local cmd = string.format([[
            INSERT INTO mgame.shop_server_sale (product_id, sale_num)
            VALUES (%d, %d)
            ON DUPLICATE KEY UPDATE sale_num = %d;
        ]], product_id, sale_num, sale_num)
        moon.send("lua", addr, cmd)
    end
end

function _M.saveshopbuylog(addr, shop_buy_log)
    assert(shop_buy_log)
    if not shop_buy_log.buy_data or table.size(shop_buy_log.buy_data) == 0 then
        return
    end

    for _, buy_single in pairs(shop_buy_log.buy_data) do
        local single_price_str = jencode(buy_single.single_price)
        local total_price_str = jencode(buy_single.total_price)

        local cmd = string.format([[
        INSERT INTO mgame.shop_buy_log (order_id, buyer_uid, buy_ts, product_id, product_num, single_price, total_price)
        VALUES (%d, %d, %d, %d, %d, '%s', '%s');
        ]], shop_buy_log.order_id, shop_buy_log.buyer_uid, shop_buy_log.buy_ts, buy_single.product_id,
            buy_single.product_num, single_price_str, total_price_str)

        moon.send("lua", addr, cmd)
    end
end

function _M.loadusergods(addr, uid)
    local cmd = string.format([[
        SELECT value, json FROM mgame.gods WHERE uid = %d;
    ]], uid)
    local res, err = moon.call("lua", addr, cmd)
    if res and #res > 0 then
        local pbdata = crypt.base64decode(res[1].value)
        local _, tmp_data = protocol.decodewithname("PBUserGods", pbdata)
        return tmp_data
    end
    print("loadusergods failed", uid, err)
    return nil
end

function _M.saveusergods(addr, uid, data)
    assert(data)

    local data_str = jencode(data)
    local _, pbdata = protocol.encodewithname("PBUserGods", data)
    local pbvalue = crypt.base64encode(pbdata)
    local cmd = string.format([[
        INSERT INTO mgame.gods (uid, value, json)
        VALUES (%d, '%s', '%s')
        ON DUPLICATE KEY UPDATE value = '%s', json = '%s';
    ]], uid, pbvalue, data_str, pbvalue, data_str)

    return moon.send("lua", addr, cmd)
end

-- 加载用户古董展柜数据
function _M.loaduserantiqueshowcase(addr, uid)
    local cmd = string.format([[
        SELECT value, json FROM mgame.antiqueshowcase WHERE uid = %d;
    ]], uid)
    local res, err = moon.call("lua", addr, cmd)
    if res and #res > 0 then
        local pbdata = crypt.base64decode(res[1].value)
        local _, tmp_data = protocol.decodewithname("PBAntiqueShowcaseDataS", pbdata)
        return tmp_data
    end
    print("loaduserantiqueshowcase failed", uid, err)
    return nil
end

-- 保存用户古董展柜数据
function _M.saveuserantiqueshowcase(addr, uid, data)
    assert(data)

    local data_str = jencode(data)
    local _, pbdata = protocol.encodewithname("PBAntiqueShowcaseDataS", data)
    local pbvalue = crypt.base64encode(pbdata)
    local cmd = string.format([[
        INSERT INTO mgame.antiqueshowcase (uid, value, json)
        VALUES (%d, '%s', '%s')
        ON DUPLICATE KEY UPDATE value = '%s', json = '%s';
    ]], uid, pbvalue, data_str, pbvalue, data_str)

    return moon.send("lua", addr, cmd)
end

-- 好友离线数据前缀常量
local NICKNAME_UID = "nickname:uid"

function _M.RedisGetNick(addr_db_redis, nickname)
    local res, err = redis_call(addr_db_redis, "GET", SYSTEM_MAIL_INFO .. nickname)
    if err then
        error("RedisCheckNick failed:" .. tostring(err))
        return {}
    end

    local nick_info = {}
    if res and #res > 0 then
        moon.warn(string.format("RedisCheckNick res = %s", json.pretty_encode(res)))
        for i = 1, #res do
            nick_info[nickname] = json.decode(res[i] or "null")
        end
    end

    return nick_info
end

function _M.RedisSetNick(addr_db_redis, nickname, uid)
    redis_send(addr_db_redis, "SET", NICKNAME_UID .. nickname, uid)
end

function _M.RedisDelNick(addr_db_redis, nickname)
    redis_send(addr_db_redis, "DEL", NICKNAME_UID .. nickname)
end

-- 战绩和返还列表操作
local BATTLE_SETTLE_INFO = "battle_settle_"
local BATTLE_RETURN_INFO = "battle_return_"
function _M.GetBattleSettleKey()
    return BATTLE_SETTLE_INFO
end
function _M.GetBattleReturnKey()
    return BATTLE_RETURN_INFO
end

---@param addr_db integer
---@param key string
---@param value any
---@return integer 列表长度
function _M.BattleListPushRight(addr_db, key, uid, value)
    local value_str = jencode(value)
    local base64_str = crypt.base64encode(value_str)
    local res, err = redis_call(addr_db, "RPUSH", key .. uid, base64_str)
    if err then
        moon.error("ListPushRight failed:" .. tostring(err) .. uid .. " value" .. value_str)
    end
    return res
end

---@param addr_db integer
---@param key string
---@return any 弹出的元素
function _M.BattleListPopLeft(addr_db, key, uid)
    local res, err = redis_call(addr_db, "LPOP", key .. uid)
    if err then
        moon.error("ListPopLeft failed:" .. tostring(err) .. uid)
    end
    if res then
        local value_str = crypt.base64decode(res)
        local value = jdecode(value_str)
        return value
    end
    return nil
end

---@param addr_db integer
---@param key string
---@param start integer 开始索引（0为第一个元素）
---@param stop integer 结束索引（-1为最后一个元素）
---@return table 元素列表
function _M.BattleListRange(addr_db, key, uid, start, stop)
    local res, err = redis_call(addr_db, "LRANGE", key .. uid, start, stop)
    if err then
        moon.error("ListRange failed:" .. tostring(err) .. uid)
    end
    if res then
        for i = 1, #res do
            local value_str = crypt.base64decode(res[i])
            local value = jdecode(value_str)
            res[i] = value
        end
    end
    return res
end

---@param addr_db integer
---@param key string
---@return integer 列表长度
function _M.BattleListLen(addr_db, key, uid)
    local res, err = redis_call(addr_db, "LLEN", key .. uid)
    if err then
        moon.error("ListLen failed:" .. tostring(err) .. uid)
    end
    return res
end

---@param addr_db integer
---@param key string
function _M.BattleDeleteEmptyList(addr_db, key, uid)
    -- Lua脚本：检查列表是否为空，为空则删除
    local script = [[
        local len = redis.call('LLEN', KEYS[1])
        if len == 0 then
            return redis.call('DEL', KEYS[1])
        end
        return 0
    ]]
    
    local res, err = redis_send(addr_db, "EVAL", script, 1, key .. uid)
    if err then
        moon.error("DeleteEmptyList failed:" .. tostring(err) .. uid)
    end
end

-- 段位数据
function _M.loadgradeinfo(addr, uid)
    local cmd = string.format([[
        SELECT value, json FROM mgame.grades WHERE uid = %d;
    ]], uid)
    local res, err = moon.call("lua", addr, cmd)
    if res and #res > 0 then
        local pbdata = crypt.base64decode(res[1].value)
        local _, tmp_data = protocol.decodewithname("PBGradePlayerData", pbdata)
        return tmp_data
    end
    moon.error("loadgradeinfo failed", uid, err)
    return nil
end

function _M.savegradeinfo(addr, uid, data)
    assert(data)

    local data_str = jencode(data)
    local _, pbdata = protocol.encodewithname("PBGradePlayerData", data)
    local pbvalue = crypt.base64encode(pbdata)
    local cmd = string.format([[
        INSERT INTO mgame.grades (uid, value, json)
        VALUES (%d, '%s', '%s')
        ON DUPLICATE KEY UPDATE value = '%s', json = '%s';
    ]], uid, pbvalue, data_str, pbvalue, data_str)

    return moon.send("lua", addr, cmd)
end

-- 充值数据
function _M.loadbillinfo(addr, uid)
    local cmd = string.format([[
        SELECT value, json FROM mgame.bills WHERE uid = %d;
    ]], uid)
    local res, err = moon.call("lua", addr, cmd)
    if res and #res > 0 then
        local pbdata = crypt.base64decode(res[1].value)
        local _, tmp_data = protocol.decodewithname("PBBillData", pbdata)
        return tmp_data
    end
    moon.error("loadgradeinfo failed", uid, err)
    return nil
end

function _M.savebillinfo(addr, uid, data)
    assert(data)

    local data_str = jencode(data)
    local _, pbdata = protocol.encodewithname("PBBillData", data)
    local pbvalue = crypt.base64encode(pbdata)
    local cmd = string.format([[
        INSERT INTO mgame.bills (uid, value, json)
        VALUES (%d, '%s', '%s')
        ON DUPLICATE KEY UPDATE value = '%s', json = '%s';
    ]], uid, pbvalue, data_str, pbvalue, data_str)

    return moon.send("lua", addr, cmd)
end

function _M.getmaxorderid(addr)
    local res, err = moon.call("lua", addr, "SELECT MAX(order_id) as max_order_id FROM mgame.bill_order;")
    if err then
        error("getmaxbillorderid failed:" .. tostring(err))
        return -1
    end
    if res and res[1] then
        return tonumber(res[1].max_order_id) or 0
    end
    return 0
end

function _M.addbillorder(addr, order_info)
    assert(order_info)

    local cmd = string.format([[
        INSERT INTO mgame.bill_order (orderid, transid, steamid, uid, bill_id, bill_num,
        bill_amount, create_ts, is_sanbox, state)
        VALUES (%d, %d, %d, %d, %d, %d, %d, %d, %d, %d);
    ]], order_info.orderid, order_info.transid, order_info.steamid, order_info.uid, order_info.bill_id,
        order_info.bill_num, order_info.bill_amount, order_info.create_ts, order_info.is_sanbox, order_info.state)

    local res, err = moon.call("lua", addr, cmd)
    if err then
        moon.error(string.format("addbillorder err = %s", json.pretty_encode(err)))
        return 0
    else
        if res then
            moon.debug(string.format("addbillorder res = %s", json.pretty_encode(res)))
            return res.insert_id
        end
    end
end

function _M.updatebillorderstate(addr, orderid, before_state, update_state, need_ret)
    local cmd = string.format([[
        UPDATE mgame.bill_order SET update_ts = %d, state = %d WHERE orderid = %d and state = %d;
    ]], moon.time(), update_state, orderid, before_state)
    
    if need_ret then
        local res, err = moon.call("lua", addr, cmd)
        if err then
            moon.error(string.format("updatebillorderstate err = %s", json.pretty_encode(err)))
            return 0
        else
            if res then
                moon.debug(string.format("updatebillorderstate res = %s", json.pretty_encode(res)))
                return res.affected_rows
            end
        end
        return 0
    else
        moon.send("lua", addr, cmd)
    end

    return 0
end

function _M.loadbillorder(addr, orderid)
    local cmd = string.format([[
        SELECT orderid, transid, steamid, uid, bill_id, bill_num,
        bill_amount, create_ts, is_sanbox, state FROM mgame.bill_order WHERE orderid = %d;
    ]], orderid)
    local res, err = moon.call("lua", addr, cmd)
    if res and #res == 1 then
        return res[1]
    end
    moon.error("loadbillorder failed", orderid, err)
    return nil
end

return _M
