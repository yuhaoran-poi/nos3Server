---Bridge OS environment variables into moon.env KV store.
---Required because moon's internal http client (internal.lua) reads
---HTTPS_PROXY / HTTP_PROXY from moon.env (per moon official example:
---moon/example/example_http.lua:67), NOT from OS env.
---
---Usage (in main_*.lua, immediately after `require("moon")`):
---    require("common.env_bridge").run()
---
---This should run as early as possible in each moon worker process,
---before any service that may issue outbound HTTPS via httpc.

local moon = require("moon")

local M = {}

---Copy a single OS env var into moon.env if set.
---@param os_key string OS env var name
---@param moon_key? string moon.env key (defaults to os_key)
local function bridge_one(os_key, moon_key)
    moon_key = moon_key or os_key
    local v = os.getenv(os_key)
    if v and v ~= "" then
        moon.env(moon_key, v)
    end
end

function M.run()
    bridge_one("HTTPS_PROXY")
    bridge_one("HTTP_PROXY")
    bridge_one("ALL_PROXY")
    bridge_one("NO_PROXY")
end

return M
