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

function Friendmgr.ApplyFriend(apply_uid, apply_data, target_uid)
    local apply = {
        uid = apply_uid,
        data = apply_data,
    }
    local res, err = context.call_user(target_uid, "Friend.ApplyFriend", apply)
    if err or not res then
        moon.error("Friend.ApplyFriend err:%s", err)
        local friend_info = Database.RedisGetFriendInfo(context.addr_db_redis, target_uid)
    end
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
