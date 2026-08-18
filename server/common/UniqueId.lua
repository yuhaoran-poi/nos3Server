--[[
UniqueId - 永不重复的 UUID 生成器(纯 Lua,63-bit int64 范围)

位分配(63-bit,最高位恒为 0,保证在有符号 int64 [0, 2^63-1] 范围内):
  | 37 bit 时间戳(每 32 ms) | 14 bit serverid | 12 bit counter |
  |=========================|=================|================|
  高位                                                          低位

时间戳范围:
  37 bit × 32 ms = 2^37 × 32 ms = 2^42 ms ≈ 139 年
  从 1970 起可表示到 2109 年

serverid 范围:
  14 bit = 0~16383(支持 1~16391,超出范围通过模运算回卷)

counter 范围:
  12 bit = 0~4095(每 32 ms 一个时间单位内最多生成 4096 个)

最大 UUID 值 = 2^63 - 1 = 9223372036854775807 = int64 max

特性:
  ✓ 进程内单调递增(永远)
  ✓ 跨进程隔离(serverid)
  ✓ 跨重启隔离(时间戳)
  ✓ 时间回拨保护
  ✓ counter 溢出保护
  ✓ int64 范围内,无溢出风险
]]

local moon = require("moon")

local M = {}

-- 位分配常量
local COUNTER_BITS = 12
local SERVERID_BITS = 14
local TIME_UNIT_MS = 32  -- 2^5,每 32 ms 为一个时间单位(粒度)

local COUNTER_MAX = 4095                  -- 2^12 - 1
local SERVERID_MAX = 16383                -- 2^14 - 1
local TIME_UNIT_MAX = 137438953471        -- 2^37 - 1,保证 (2^37-1) << 26 < 2^63

-- 位移量
local TIME_UNIT_SHIFT = COUNTER_BITS + SERVERID_BITS  -- 26
local SERVERID_SHIFT = COUNTER_BITS                  -- 12

-- 模块级状态(Lua 协程单线程,无需锁)
local _serverid = 0
local _last_time_unit = 0
local _counter = 0
local _initialized = false

---@param serverid integer|nil 进程级唯一 ID(1~16391),超出范围自动模运算到 [0, 16383]
function M.init(serverid)
    if serverid == nil then
        _serverid = 0
    else
        _serverid = math.floor(tonumber(serverid) or 0)
    end
    if _serverid < 0 then
        _serverid = 0
    end
    if _serverid > SERVERID_MAX then
        _serverid = _serverid - math.floor(_serverid / (SERVERID_MAX + 1)) * (SERVERID_MAX + 1)
    end
    _last_time_unit = moon.now() // TIME_UNIT_MS
    _counter = 0
    _initialized = true
end

---生成下一个永不重复的 UUID(63-bit int64)
---@return integer
function M.next()
    if not _initialized then
        M.init()
    end

    local now_ms = moon.now()
    local time_unit = now_ms // TIME_UNIT_MS

    -- 保护:time_unit 不能超过 TIME_UNIT_MAX(2^37 - 1)
    if time_unit > TIME_UNIT_MAX then
        moon.error(string.format("UniqueId time_unit overflow: %d > %d, clamping", time_unit, TIME_UNIT_MAX))
        time_unit = TIME_UNIT_MAX
    end

    -- 1. 时间回拨保护:系统时间回退时,主动 sleep 等待追上
    if time_unit < _last_time_unit then
        while time_unit < _last_time_unit do
            local sleep_ms = (_last_time_unit - time_unit) * TIME_UNIT_MS
            if sleep_ms > 0 then
                moon.sleep(sleep_ms)
            end
            now_ms = moon.now()
            time_unit = now_ms // TIME_UNIT_MS
            if time_unit > TIME_UNIT_MAX then
                time_unit = TIME_UNIT_MAX
            end
        end
    end

    if time_unit == _last_time_unit then
        -- 2. 同一时间单位内,counter +1
        _counter = _counter + 1
        if _counter > COUNTER_MAX then
            -- 2.1 counter 溢出(32 ms 内超过 4096 次),sleep 到下一时间单位
            local target_ms = (_last_time_unit + 1) * TIME_UNIT_MS
            local sleep_ms = target_ms - now_ms
            if sleep_ms > 0 then
                moon.sleep(sleep_ms)
            end
            now_ms = moon.now()
            time_unit = now_ms // TIME_UNIT_MS
            if time_unit > TIME_UNIT_MAX then
                time_unit = TIME_UNIT_MAX
            end
            _last_time_unit = time_unit
            _counter = 0
        end
    else
        -- 3. 进入新时间单位
        _last_time_unit = time_unit
        _counter = 0
    end

    -- 4. 组合:time_unit(37) << 26 | serverid(14) << 12 | counter(12)
    -- 最大值 = (2^37-1)<<26 | (2^14-1)<<12 | (2^12-1) = 2^63 - 1 (int64 max)
    return (_last_time_unit << TIME_UNIT_SHIFT) | (_serverid << SERVERID_SHIFT) | _counter
end

---调试用:返回内部状态
---@return table
function M.debug()
    return {
        serverid = _serverid,
        last_time_unit = _last_time_unit,
        last_ms = _last_time_unit * TIME_UNIT_MS,
        counter = _counter,
        initialized = _initialized,
    }
end

return M
