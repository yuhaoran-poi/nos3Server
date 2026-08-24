--require("common.LuaPanda").start("127.0.0.1", 8818)
local moon = require("moon")
local mysql = require("moon.db.mysql")
local buffer = require("buffer")
local json = require "json"

local conf = ...

-- 共享状态:全 driver 实例都用这套
local pool_stats = {
    total = 0,             -- 配置的 poolsize
    alive = 0,             -- 当前可用数
    reconnects = 0,        -- 累计重连次数
    last_err = nil,        -- 最近一次错误
    last_recover_ts = 0,
    last_empty_log_ts = 0, -- 上次池子空警告时间(避免刷屏)
    slow_query_count = 0,  -- 累计慢查询次数(超过阈值的)
}

-- 慢查询阈值(毫秒),可通过 conf.slow_threshold_ms 覆盖
-- 与 SHORT_WAIT_MS=500 对齐,只抓 SQL 本身的慢,不被池子争用干扰
local SLOW_THRESHOLD_MS = 500

-- 连接池空时的等待策略(毫秒)
local SHORT_WAIT_MS = 500 -- 池子空但无 pending 时,基础等待(允许正常 SQL 慢一点也能拿到连接)
local LONG_WAIT_MS = 1500 -- 有 pending 时上限(给重连 worker 充分时间回流)
-- 注意:SHORT_WAIT_MS + max_pending * 100 <= LONG_WAIT_MS
-- 当前公式:每个 pending 加 100ms,所以 LONG_WAIT_MS - SHORT_WAIT_MS 至少要能容纳所有 pending
-- poolsize 通常 5~10 → 10 * 100 = 1000,SHORT=500 时 LONG 至少 1500

if conf.name then
    local list = require("list")
    local dbs = list.new()
    -- 需要重连的连接队列(被踢出主池,后台重连后回流)
    local pending_reconnect = list.new()
    -- 正在执行的 SQL 追踪(连接句柄 -> SQL),用于 POOL_EMPTY 时定位占着连接不放的语句
    local inflight = {}
    pool_stats.total = conf.poolsize or 1

    -- conf 覆盖(可选,运维想调阈值不用改代码)
    if conf.slow_threshold_ms and type(conf.slow_threshold_ms) == "number" then
        SLOW_THRESHOLD_MS = conf.slow_threshold_ms
    end
    if conf.short_wait_ms and type(conf.short_wait_ms) == "number" then
        SHORT_WAIT_MS = conf.short_wait_ms
    end
    if conf.long_wait_ms and type(conf.long_wait_ms) == "number" then
        LONG_WAIT_MS = conf.long_wait_ms
    end

    -- 后台重连 worker:从 pending 队列取坏连接,按指数退避重试
    moon.async(function()
        local backoff = 1 -- 秒,失败后翻倍,成功重置
        while true do
            while list.size(pending_reconnect) == 0 do
                moon.sleep(1000) -- 队列空,1 秒后再看
            end

            local db_or_err = list.pop(pending_reconnect)
            -- db_or_err 是上次失败的连接对象(可能是 mysql 句柄,也可能已经是错误 dict)
            if db_or_err and db_or_err.disconnect then
                pcall(function() db_or_err:disconnect() end) -- 尝试优雅关闭
            end

            -- 尝试重建连接
            local ok, new_db = pcall(mysql.connect, conf.opts)
            if ok and new_db and not new_db.code then
                list.push(dbs, new_db)
                pool_stats.alive = list.size(dbs)
                pool_stats.reconnects = pool_stats.reconnects + 1
                pool_stats.last_recover_ts = moon.time()
                moon.warn(string.format(
                    "[%s] mysql reconnected (alive=%d/%d, total reconnects=%d)",
                    conf.name, pool_stats.alive, pool_stats.total, pool_stats.reconnects))
                backoff = 1
            else
                pool_stats.last_err = new_db and new_db.message or tostring(new_db)
                moon.error(string.format(
                    "[%s] mysql reconnect failed, retry in %ds: %s",
                    conf.name, backoff, pool_stats.last_err))
                moon.sleep(backoff * 1000)
                backoff = math.min(backoff * 2, 60) -- 1→2→4→8→...→60 封顶
                -- 重连失败,放回 pending 继续等
                if db_or_err then
                    list.push(pending_reconnect, db_or_err)
                end
            end
        end
    end)

    -- 初始化连接池(后台异步,启动不阻塞)
    moon.async(function()
        for _ = 1, pool_stats.total do
            local ok, db = pcall(mysql.connect, conf.opts)
            if ok and db and not db.code then
                list.push(dbs, db)
                pool_stats.alive = list.size(dbs)
            else
                pool_stats.last_err = db and db.message or tostring(db)
                moon.error(string.format("[%s] initial mysql connect failed: %s",
                    conf.name, pool_stats.last_err))
                -- 占个位,等后台 worker 帮忙重连
                list.push(pending_reconnect, { placeholder = true })
            end
        end
    end)

    -- 周期 ping 健康检查(L25-39 升级版)
    moon.async(function()
        while true do
            moon.sleep(30000) -- 30 秒一轮

            -- 原子 pop:不先做 size 检查,直接 pop,根据结果分支
            -- 避免与 SQL handler / force_reconnect 并发时 size>0 但 pop 出 nil 的 race
            local db = list.pop(dbs)
            if db then
                local ok, ret = pcall(function() return db:ping() end)
                if not ok or not ret or ret.server_status ~= 2 then
                    -- ping 失败:踢出主池,丢进待重连队列
                    moon.warn(string.format("[%s] mysql ping failed, mark for reconnect: %s",
                        conf.name, json.pretty_encode(ret or { err = "ping_exception" })))
                    list.push(pending_reconnect, db)
                else
                    -- 正常,放回
                    list.push(dbs, db)
                end
                pool_stats.alive = list.size(dbs)
            elseif list.size(pending_reconnect) > 0 then
                -- 池子是空的但有 pending,说明正在重连,打点日志
                -- (避免每 30 秒被空日志刷屏,只在第一次空时打)
                if pool_stats.last_empty_log_ts == 0
                    or moon.time() - pool_stats.last_empty_log_ts > 300 then
                    pool_stats.last_empty_log_ts = moon.time()
                    moon.warn(string.format(
                        "[%s] pool empty, waiting reconnect (alive=%d/%d, pending=%d)",
                        conf.name, list.size(dbs), pool_stats.total, list.size(pending_reconnect)))
                end
            end
        end
    end)

    -- 合并 dispatch:moon.dispatch 同一个 PTYPE 只会保留最后一个 handler
    -- 必须把诊断命令和 SQL 查询统一入口,按 op 路由
    moon.dispatch("lua", function(sender, sessionid, op, payload)
        local sender_hex = string.format("0x%X", sender)

        -- 控制命令:诊断
        if op == "_diag" then
            local result = {
                name = conf.name,
                pool_total = pool_stats.total,
                pool_alive = list.size(dbs),
                pool_pending = list.size(pending_reconnect),
                reconnects = pool_stats.reconnects,
                slow_query_count = pool_stats.slow_query_count,
                slow_threshold_ms = SLOW_THRESHOLD_MS,
                last_err = pool_stats.last_err,
                last_recover_ts = pool_stats.last_recover_ts,
            }
            moon.info(string.format(
                "[%s] _diag from sender=%s session=%d -> alive=%d/%d, pending=%d, reconnects=%d, slow=%d, threshold=%dms, last_err=%s",
                conf.name, sender_hex, sessionid,
                result.pool_alive, result.pool_total, result.pool_pending,
                result.reconnects, result.slow_query_count, result.slow_threshold_ms,
                tostring(result.last_err)))
            return result
        end

        -- 控制命令:强制重连(把池子里的所有连接全部踢到 pending 触发重连)
        if op == "_force_reconnect" then
            -- 原子 pop 循环:不再先 size 检查,直接 pop,pop 出 nil 说明池子空了
            local count = 0
            while true do
                local db = list.pop(dbs)
                if not db then break end
                list.push(pending_reconnect, db)
                count = count + 1
            end
            pool_stats.alive = 0
            moon.warn(string.format(
                "[%s] _force_reconnect from sender=%s session=%d -> kicked %d connections (alive=0/%d, pending=%d)",
                conf.name, sender_hex, sessionid, count,
                pool_stats.total, list.size(pending_reconnect)))
            return { ok = true, kicked = count }
        end

        -- SQL 查询路径(向下兼容原签名,op 即为 sql 字符串)
        local sql = op
        if type(sql) ~= "string" then
            moon.error(string.format(
                "[%s] INVALID_SQL from sender=%s session=%d: op type=%s, payload type=%s",
                conf.name, sender_hex, sessionid, type(op), type(payload)))
            if sessionid ~= 0 then
                moon.response("lua", sender, sessionid, {
                    badresult = true,
                    code = "INVALID_SQL",
                    message = string.format("op must be a SQL string, got %s/%s", type(op), type(payload)),
                })
            end
            return
        end

        -- 优化3:动态等待策略
        -- - 池子空但无 pending:适度等待(SHORT_WAIT_MS,500ms),容忍瞬时尖刺
        -- - 池子空且有 pending:延长等待(LONG_WAIT_MS,1500ms),给重连 worker 时间回流
        local pending_cnt = list.size(pending_reconnect)
        local wait_target = SHORT_WAIT_MS
        if pending_cnt > 0 then
            -- 每个 pending 额外加 100ms,但不超过 LONG_WAIT_MS
            wait_target = math.min(SHORT_WAIT_MS + pending_cnt * 100, LONG_WAIT_MS)
        end

        -- 原子 pop-in-wait:在等待循环内直接尝试 pop,避免 size>0 但 pop 失败的 race
        local db
        local wait_cnt = 0
        while wait_cnt < wait_target do
            db = list.pop(dbs)
            if db then break end
            moon.sleep(1)
            wait_cnt = wait_cnt + 1
        end

        if not db then
            -- 池子空且等待超时,先 dump 当前所有 in-flight 的 SQL,直接定位占着连接的语句
            local inflight_dump = {}
            local idx = 0
            for _, in_sql in pairs(inflight) do
                idx = idx + 1
                inflight_dump[idx] = string.sub(in_sql or "", 1, 200)
            end
            -- 池子空且等待超时,立即返回错误给 caller(由 caller 决定 retry)
            local err_res = {
                badresult = true,
                code = "POOL_EMPTY",
                message = string.format(
                    "no available mysql connection (alive=0/%d, pending=%d, wait=%dms, last_err=%s)",
                    pool_stats.total, pending_cnt, wait_target, tostring(pool_stats.last_err)),
            }
            moon.error(string.format(
                "[%s] POOL_EMPTY from sender=%s session=%d: waited=%dms, target=%dms, pending=%d, last_err=%s, sql_prefix=%.80s",
                conf.name, sender_hex, sessionid,
                wait_cnt, wait_target, pending_cnt,
                tostring(pool_stats.last_err),
                sql:sub(1, 80)))
            -- 把当前正在执行的 N 条 SQL 全部 dump,前面标序号便于逐一核对
            if idx > 0 then
                moon.error(string.format(
                    "[%s] POOL_EMPTY inflight_count=%d (these SQLs are currently holding connections):",
                    conf.name, idx))
                for i, dumped_sql in ipairs(inflight_dump) do
                    moon.error(string.format("  [%d] %s", i, dumped_sql))
                end
            end
            if sessionid ~= 0 then
                moon.response("lua", sender, sessionid, err_res)
            end
            return
        end

        -- 拿到连接,登记到 in-flight,等所有归还路径(push/pending)统一清理
        inflight[db] = sql

        -- 拿到连接,但等待过久:打点日志(>50ms 视为异常,避免刷屏)
        if wait_cnt > 50 then
            moon.warn(string.format(
                "[%s] pool contention from sender=%s session=%d: waited=%dms, target=%dms, pending=%d",
                conf.name, sender_hex, sessionid, wait_cnt, wait_target, pending_cnt))
        end

        -- 优化4:慢查询直接 moon.warn 输出 SQL
        local query_start = moon.now()
        local ok, res = pcall(function() return db:query(sql) end)
        local query_cost = moon.now() - query_start

        if query_cost > SLOW_THRESHOLD_MS then
            pool_stats.slow_query_count = pool_stats.slow_query_count + 1
            -- 截断超长 SQL 避免日志爆炸(>2KB 的 SQL 通常是批量写入,截断到 2KB)
            local log_sql = sql
            if #log_sql > 2048 then
                log_sql = log_sql:sub(1, 2048) .. "...[truncated " .. (#sql - 2048) .. " bytes]"
            end
            moon.warn(string.format("[%s] slow query %dms (threshold=%dms, total_slow=%d): %s",
                conf.name, query_cost, SLOW_THRESHOLD_MS,
                pool_stats.slow_query_count, log_sql))
        end

        if not ok then
            -- query 本身抛异常(连接被踢 / 协议错误),踢出重连
            moon.error(string.format("[%s] mysql query exception from sender=%s session=%d: %s",
                conf.name, sender_hex, sessionid, tostring(res)))
            inflight[db] = nil
            list.push(pending_reconnect, db)
            pool_stats.alive = list.size(dbs)
            res = {
                badresult = true,
                code = "QUERY_EXCEPTION",
                message = tostring(res),
            }
        elseif res and res.errno then
            -- MySQL 返回错误,连接本身可能还活着(语法错/约束冲突),放回池子
            moon.error(string.format("[%s] mysql query failed from sender=%s session=%d: errno=%d, msg=%s",
                conf.name, sender_hex, sessionid, res.errno, tostring(res.message)))
            moon.error(string.format("[%s] mysql query sql: %s", conf.name, tostring(sql)))
            inflight[db] = nil
            list.push(dbs, db)
            res = {
                badresult = true,
                code = "MYSQL_ERROR",
                message = tostring(res.message),
                errno = res.errno,
            }
        else
            -- 正常,放回池子
            inflight[db] = nil
            list.push(dbs, db)
        end

        if sessionid ~= 0 then
            moon.response("lua", sender, sessionid, res)
        end
    end)
end