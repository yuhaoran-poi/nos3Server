local moon = require("moon")
local common = require("common")
local clusterd = require("cluster")
local json = require "json"
local CmdCode = common.CmdCode
local GameCfg = common.GameCfg
local Database = common.Database
local protocol = common.protocol

---@type user_context
local context = ...
local scripts = context.scripts

local state = { ---内存中的状态
    online = false,
    ismatching = false
}

---@class User
local User = {}
function User.Load(req)
    --local ret = LuaPanda and LuaPanda.BP and LuaPanda.BP()
    local function fn()
        -- 向Usermgr申请是否允许登录
        local res, err = clusterd.call(9999, "usermgr", "Usermgr.ApplyLogin", { uid = req.uid, nid = moon.env("NODE"), user_addr = req.addr_user })
        print("Usermgr.ApplyLogin", res, err)
        if res.error ~= "success" then
            return false
        end

        local data = scripts.UserModel.Get()
        if data then
            return data
        end

        data, err = Database.loaduser(context.addr_db_user, req.uid)
        --local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
        if data and #data > 0 then
            data = data[1] -- 取出结果集第一条记录
        end

        local isnew = false
        if not data then
            if req.pull then
                return
            end

            isnew = true

            data = {
                authkey = req.msg.login_data.authkey,
                uid = req.uid,
                name = req.msg.login_data.authkey,
                level = 10,
                score = 0
            }
        end

        scripts.UserModel.Create(data)

        context.uid = req.uid
        context.net_id = req.net_id
        ---初始化自己数据
        context.batch_invoke_throw("Init", isnew)
        ---初始化互相引用的数据
        context.batch_invoke_throw("Start")
        return data
    end

    local ok, res = xpcall(fn, debug.traceback, req)
    if not ok or not res then
        return false, res
    end

    if not res then
        local errmsg = string.format("user init failed, can not find user %d", req.uid)
        moon.error(errmsg)
        return false, errmsg
    end
    return true
end

function User.Login(req)
    if req.pull then--服务器主动拉起玩家
        return scripts.UserModel.Get().authkey
    end
    if state.online then
        context.batch_invoke("Offline")
    end
    context.batch_invoke("Online")
    return scripts.UserModel.Get().authkey
end

function User.Logout()
    context.batch_invoke("Offline")
    return true
end

function User.Init()
    GameCfg.Load()
end

function User.Start()

end

function User.Online()
    state.online = true
    scripts.UserModel.MutGet().logintime = moon.time()
end

function User.Offline()
    if not state.online then
        return
    end

    print(context.uid, "offline")
    state.online = false

	if state.ismatching then
        state.ismatching = false
        moon.send("lua", context.addr_center, "Center.UnMatch", context.uid)
    end
end

function User.OnHour()
    -- body
end

function User.OnDay()
    -- body
end

function User.Exit()
    local ok, err = xpcall(scripts.UserModel.Save, debug.traceback)
    if not ok then
        moon.error("user exit save db error", err)
    end

    -- 通知usermgr
    clusterd.call(9999, "usermgr", "Usermgr.NotifyLogout", { uid = context.uid, nid = moon.env("NODE") })
    
    moon.quit()
    return true
end

function User.C2SUserData()
    context.S2C(CmdCode.S2CUserData, scripts.UserModel.Get())
end

function User.PBClientGetUsrSimInfoReqCmd(req)
    local function func()
        if not req then
           return false
        end
        
        local user_data = scripts.UserModel.Get()
        if not user_data then
            local res = { code = 2003, error = "no user_data" }
            return res
        end
        
        if not user_data.simple then
            --内存中不存在则查询数据库
            local db_data, err = Database.loaduser_simple(context.addr_db_user, context.uid)
            if db_data and #db_data == 1 then
                local pbname, tmp_data = protocol.decodewithname("PBUserSimpleInfo", db_data[1].value)
                user_data.simple = tmp_data
            else
                --数据库中不存在则视为新用户初始化
                local user_simple = {
                    uid = user_data.user_id,
                    plateform_id = user_data.authkey,
                    nickname = user_data.name,
                    head_icon = 0,
                    sex = 0,
                    praise_num = 0,
                    head_frame = 0,
                    account_create_time = moon.time(),
                    account_level = 0,
                    account_exp = 0,
                    account_total_exp = 0,
                    guild_uid = 0,
                    guild_name = "",
                    cur_show_role = {
                        role_id = 0,
                        skin_list = {}
                    },
                    pinch_face_data = {
                        setting_data = "",
                    },
                    title = 0,
                    player_flag = 0,
                    online_time = moon.time(),
                    sum_online_time = 0,
                    pa_flag = 0,
                    mons_uniqid = 0,
                    mons_confid = 0,
                    mons_skin_list = {},
                }

                local pbname, pb_data = protocol.encodewithname("PBUserSimpleInfo", user_simple)
                local db_op, err = Database.saveuser_simple(context.addr_db_user, context.uid, user_simple, pb_data)
                if not db_op or err then
                    local res = { code = 2004, error = "no user_simple" }
                    return res
                end
                user_data.simple = user_simple
            end
            
            scripts.UserModel.SetSimple(user_data.simple)
        end
        --local rank_data = Database.query_rank(context.addr_db_user, context.uid)
        --local role_data = Database.query_role(context.addr_db_user, context.uid)

        local res = { code = 0, error = "success", user_simple = user_data.simple }
        return res
    end

    local ok, res = xpcall(func, debug.traceback)
    local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
    if ok then
        local ret = {
            code = res.code,
            error = res.error,
            uid = context.uid,
            info = res.user_simple
        }
        context.S2C(context.net_id, CmdCode["PBClientGetUsrSimInfoRspCmd"], ret, req.msg_context.stub_id) -- body
    else
        --moon.error(err)
        moon.error(string.format("err = %s", json.pretty_encode(res)))
    end
end

function User.C2SPing(req)
    req.stime = moon.time()
    context.S2C(CmdCode.S2CPong, req)
end

--PBPingCmd
function User.PBPingCmd(req)
    local ret =
    {
        time = req.msg.time
    }
    context.S2C(context.net_id, CmdCode.PBPongCmd, ret, req.msg_context.stub_id)
end

--请求匹配
function User.C2SMatch()
    if state.ismatching then
        return
    end

    state.ismatching = true
    --向匹配服务器请求
    local ok, err = moon.call("lua", context.addr_center, "Center.Match", context.uid, moon.id)
    if not ok then
        state.ismatching = false
        moon.error(err)
        return
    end
    context.S2C(CmdCode.S2CMatch,{res=true})
end

function User.MatchSuccess(addr_room, roomid)
    state.ismatching = false
    context.addr_room = addr_room
    state.roomid = roomid
    context.S2C(CmdCode.S2CMatchSuccess,{res=true})
end

--房间一局结束
function User.GameOver(score)
    print("GameOver, add score", score)
    local data = scripts.UserModel.MutGet()
    data.score = data.score + score
    context.addr_room = 0
    context.S2C(CmdCode.S2CGameOver,{score=score})
end

function User.AddScore(count)
    local data = scripts.UserModel.MutGet()
    data.score = data.score + count
    return true
end

return User
