require("common.LuaPanda").start("127.0.0.1", 8818)

local moon = require("moon")
local seri = require("seri")
local buffer = require("buffer")
local common = require("common")
local setup = require("common.setup")
local json = require "json"
local protocol = common.protocol
local CmdCode = common.CmdCode
local GameDef = common.GameDef

local bunpack = buffer.unpack
local wfront = buffer.write_front

local mdecode = protocol.decode

local fwd_addr = CmdCode.forward

local id_to_name = protocol.name

local redirect = moon.redirect

local PTYPE_C2S = GameDef.PTYPE_C2S

---@class user_context:base_context
---@field scripts user_scripts
local context = {
    uid = 0,
    play_ds_node = {},
---@diagnostic disable-next-line: missing-fields
    scripts = {},
    ---other service address
    net_id = 0,
 
    guild_node = 0,
    addr_guild = 0,
}

local command = setup(context, "user")

local function forward(subname, reqmsg)
    local address
    local v = fwd_addr[subname]
    if v ~= "addr_auth" then
        address = context[v]
    end

    if not address then
        moon.error("recv unknown message", subname)
        return
    end

    moon.send("lua", address, subname, reqmsg)
    --redirect(msg, address, PTYPE_C2S)
end

moon.raw_dispatch("C2S", function(msg)
    local name, req = protocol.decode(moon.decode(msg, "B"))
    for key, MessagePack in ipairs(req.messages) do
        local reqmsg = {}
        reqmsg.msg_context = {
            uid = context.uid,
            net_id = context.net_id,
            broadcast = MessagePack.broadcast,
            stub_id = MessagePack.stub_id,
            msg_type = MessagePack.msg_type
        }
        --local subname, submsg = protocol.DecodeMessagePack(MessagePack)
        local msg_name = id_to_name(MessagePack.msg_type)
        if not command[msg_name] then
            reqmsg.msg = MessagePack.msg_body
            forward(msg_name, reqmsg)
        else
            local subname, submsg = protocol.DecodeMessagePack(MessagePack)
            moon.debug(string.format("recv Message:\n%s", json.pretty_encode(submsg)))
            reqmsg.msg = submsg

            local fn = command[subname]
            moon.async(function()
                local ok, res = xpcall(fn, debug.traceback, reqmsg)
                --
                if not ok then
                    moon.error(string.format("err res:\n%s", json.pretty_encode(res)))
                    --context.S2C(CmdCode.S2CErrorCode, { code = 1 }) --server internal error
                elseif res then
                    moon.info(res)
                    --context.S2C(CmdCode.S2CErrorCode, { code = res })
                end
            end)
        end
    end
end)

context.addr_gate = moon.queryservice("gate")
context.addr_db_redis = moon.queryservice("db_user")
if moon.queryservice("db_game") > 0 then
    context.addr_db_user = moon.queryservice("db_game")
end
context.addr_db_server = moon.queryservice("db_server")
context.addr_center = moon.queryservice("center")
context.addr_auth = moon.queryservice("auth")

-- context.S2C = function(cmd_code, mtable, stubId)
--     moon.raw_send('S2C', context.addr_gate, protocol.encodeMessagePacket(context.net_id, cmd_code, mtable, stubId or 0))
-- end

-- context.S2C = function(net_id, cmd_code, mtable, stubId)
--     forwardD2C(context, net_id, protocol.encodeMessagePacket(net_id, cmd_code, mtable, stubId or 0))
--     --moon.raw_send('S2C', context.addr_gate, protocol.encodePacket(uid, cmd_code, mtable,mc))
-- end

moon.shutdown(function()
    print("user %d shutdown", context.uid)
end)

---垃圾收集器间歇率控制着收集器需要在开启新的循环前要等待多久。 
---增大这个值会减少收集器的积极性。
---当这个值比 100 小的时候，收集器在开启新的循环前不会有等待。 
---设置这个值为 200 就会让收集器等到总内存使用量达到 之前的两倍时才开始新的循环。
---params: 垃圾收集器间歇率, 垃圾收集器步进倍率, 垃圾收集器单次运行步长“大小”
collectgarbage("incremental",120)
