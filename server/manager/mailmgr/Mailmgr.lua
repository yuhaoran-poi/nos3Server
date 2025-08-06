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
local FriendDef = require("common.def.FriendDef")
local ProtoEnum = require("tools.ProtoEnum")
local UserAttrLogic = require("common.logic.UserAttrLogic")
local jencode = json.encode
local jdecode = json.decode

---@type mailmgr_context
local context = ...

local listenfd
local maxplayers = 10

---@class Mailmgr
local Mailmgr = {}

function Mailmgr.Init()
    return 123
end

function Mailmgr.Start()
    return true
end

function Mailmgr.GetSystemMailIds(req_data)
    local add_mailids = Database.select_mailids(context.addr_db_redis, req_data.uid, req_data.last_system_mail_id,
    req_data.now_ts)
    local del_mailids = Database.select_expire_mailids(context.addr_db_redis, req_data.uid, req_data.now_ts)
    local res = {
        add_mailids = add_mailids,
        del_mailids = del_mailids,
    }
    return res
end

function Mailmgr.SetSystemMailDetail(mail_info)
    Database.RedisSetSystemMailsInfo(context.addr_db_redis, mail_info)
end

function Mailmgr.DelSystemMailDetail(mail_id)
    Database.RedisDelSystemMailsInfo(context.addr_db_redis, mail_id)
end

function Mailmgr.AddSystemMail(mail_info, all_user, recv_uids)
    local ret_id = Database.add_system_mail(context.addr_db_redis, mail_info, all_user, recv_uids)
    if ret_id <= 0 then
        return "failed"
    end

    mail_info.simple_data.mail_id = ret_id
    Mailmgr.SetSystemMailDetail(mail_info)

    -- 通知所有Gate
    context.broadcast_gate("Gate.SendSystemMail", mail_info)

    return "success"
end

function Mailmgr.InvalidSystemMail(mail_id)
    local ret = Database.invalid_system_mail(context.addr_db_redis, mail_id)
    if ret <= 0 then
        return "failed"
    end

    Mailmgr.DelSystemMailDetail(mail_id)

    -- 通知所有Gate
    context.broadcast_gate("Gate.InvalidSystemMail", mail_id)
end

function Mailmgr.Shutdown()
    -- for _, n in pairs(context.rooms) do
    --     socket.close(n.fd)
    -- end
    if listenfd then
        socket.close(listenfd)
    end
    moon.quit()
    return true
end

return Mailmgr
