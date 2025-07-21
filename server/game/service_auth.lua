--require("common.LuaPanda").start("127.0.0.1", 8818)
local moon = require("moon")
local setup = require("common.setup")

local conf = ...

---@class auth_context:base_context
---@field uid_map table<integer,AuthUser> @内存加载的玩家服务信息
---@field scripts auth_scripts
---@field ds_map table<integer,AuthDs> @内存加载的ds服务信息
local context = {
    conf = conf,
    uid_map = {},
    net_id_map = {},
    openid_map = {},--- map<authkey, uid>
    auth_queue = {},
    service_counter = 0,
    scripts = {},
    ds_map = {}
}

local command = setup(context)

---@diagnostic disable-next-line: duplicate-set-field
command.hotfix = function(names)
    for _,u in pairs(context.uid_map) do
        moon.send("lua", u.addr_user, "hotfix", names)
    end

    for uid, q in pairs(context.auth_queue) do
        if q("counter") >0 then
            moon.async(function()
                context.scripts.Auth.SendUser(uid, "hotfix", names)
            end)
        end
    end
end

