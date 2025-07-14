local moon = require("moon")
local socket = require("moon.socket")
local common = require("common")
local CmdCode = common.CmdCode
local GameCfg = common.GameCfg --游戏配置
local Database = common.Database
local ErrorCode = common.ErrorCode
local lock = require("moon.queue")()
local httpc = require("moon.http.client")
local json = require("json")
local crypt = require("crypt")
local protocol = require("common.protocol_pb")
local RoomDef = require("common.def.RoomDef")
local jencode = json.encode
local jdecode = json.decode

---@type friendmgr_context
local context = ...

local listenfd
local maxplayers = 10

---@class Friendmgr
local Friendmgr = {}

function Friendmgr.Init()

end

function Friendmgr.Start()
    return true
end

function Friendmgr.AddOfflineApply(msg)
    Database.RedisAddFriendApply(context.addr_db_redis, msg.target_uid, msg.uid, msg.apply_data)
end

function Friendmgr.Shutdown()
    -- for _, n in pairs(context.rooms) do
    --     socket.close(n.fd)
    -- end
    if listenfd then
        socket.close(listenfd)
    end
    moon.quit()
    return true
end

return Friendmgr
