--require("common.LuaPanda").start("127.0.0.1", 8818)

local moon = require("moon")
local socket = require("moon.socket")
local common = require("common")
local setup = require("common.setup")

local protocol = common.protocol

local conf = ...

---@class nodemgr_context:base_context
---@field scripts node_scripts
local context = {
    conf = conf,
    node_map = {}, --直连到本mgr的所有node
}

setup(context)

-- socket.on("accept", function(fd, msg)
--     print("node: accept ", fd, moon.decode(msg, "Z"))
--     socket.set_enable_chunked(fd, "w")
--     --socket.settimeout(fd, 60)
-- end)

-- socket.on("message", function(fd, msg)
--     local n = context.fd_map[fd]
--     if not n then
--         ---first message must be auth message
--         --local ret = LuaPanda and LuaPanda.BP and LuaPanda.BP()
--         context.auth_watch[fd] = tostring(msg)
--     end

--     local name, req = protocol.decode(moon.decode(msg, "B"))
--     for key, MessagePack in ipairs(req.messages) do
--         local subname, submsg = protocol.DecodeMessagePack(MessagePack)
--         local reqmsg = {}
--         reqmsg.msg_context = {
--             net_id = MessagePack.net_id,
--             broadcast = MessagePack.broadcast,
--             stub_id = MessagePack.stub_id,
--             msg_type = MessagePack.msg_type
--         }
--         reqmsg.msg = submsg
--         reqmsg.sign = context.auth_watch[fd]
--         reqmsg.fd = fd
--         reqmsg.addr = socket.getaddress(fd)

--         local fn = command[subname]
--         if fn then
--             local ok, res = xpcall(fn, debug.traceback, reqmsg)
--             --local ret = LuaPanda and LuaPanda.BP and LuaPanda.BP()
--             if not ok then
--                 moon.error(res)
--                 --context.S2C(CmdCode.S2CErrorCode, { code = 1 }) --server internal error
--             elseif res then
--                 moon.error(res)
--                 --context.S2C(CmdCode.S2CErrorCode, { code = res })
--             end
--         else
--             print("nodemgr:recv unknown message", subname)
--         end
--     end
-- end)

-- socket.on("close", function(fd, msg)
--     local data = moon.decode(msg, "Z")
--     context.auth_watch[fd] = nil
--     local n = context.fd_map[fd]
--     if not n then
--         return
--     end
--     context.fd_map[fd] = nil
--     context.node_map[n.net_id] = nil
--     print("nodemgr: close", fd, data)
-- end)

moon.shutdown(function()
    moon.quit()
end)
