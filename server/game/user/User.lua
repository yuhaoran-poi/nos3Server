local moon = require("moon")
local common = require("common")
local clusterd = require("cluster")
local json = require "json"
local CmdCode = common.CmdCode
local GameCfg = common.GameCfg
local Database = common.Database
local protocol = common.protocol
local ErrorCode = common.ErrorCode
local UserSimpleDef = require("common.def.UserSimpleDef")
local RoleDef = require("common.def.RoleDef")
local GhostDef = require("common.def.GhostDef")
local BagDef = require("common.def.BagDef")

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
    local function fn()
        -- 向Usermgr申请是否允许登录
        local res, err = clusterd.call(3999, "usermgr", "Usermgr.ApplyLogin",
            { uid = req.uid, nid = moon.env("NODE"), addr_user = req.addr_user })

        print("Usermgr.ApplyLogin", res, err)
        if res.error ~= "success" then
            return false
        end

        local data = scripts.UserModel.Get()
        if data then
            return data
        end

        local user_data, err = Database.loaduserdata(context.addr_db_user, req.uid)
        if user_data then
            data = {
                user_id = user_data.user_id,
                user_data = user_data, -- 取出结果集第一条记录
                authkey = req.msg.login_data.authkey
            }
        end

        local isnew = false
        if not data then
            if req.pull then
                return false
            end

            isnew = true

            data = {
                authkey = req.msg.login_data.authkey,
                user_id = req.uid,
                user_data = {
                    user_id = req.uid,
                    name = req.msg.login_data.authkey,
                    -- 聊天相关数据
                    chat_info = {
                        silence = 0, -- 禁言时间戳，0表示未禁言
                    }
                }
            }
        end

        scripts.UserModel.Create(data)
        context.uid = req.uid
        context.net_id = req.net_id

        ---初始化自己数据
        context.batch_invoke_throw("Init", isnew)
        ---初始化互相引用的数据
        context.batch_invoke_throw("Start")

        ---加载simple数据
        local simple_res = User.LoadSimple()
        if simple_res.code ~= ErrorCode.None then
            return false
        end
        ---加载道具图鉴数据
        local image_res = scripts.ItemImage.Start()
        if image_res.code ~= ErrorCode.None then
            return false
        end
        ---加载背包数据
        ---scripts.Bag.Start()
        ---加载角色数据
        local role_res = scripts.Role.Start()
        if role_res.code ~= ErrorCode.None then
            return false
        end
        ---加载鬼宠数据
        local ghost_res = scripts.Ghost.Start()
        if ghost_res.code ~= ErrorCode.None then
            return false
        end

        scripts.UserModel.SaveRun()

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

function User.LoadSimple()
    local DB = scripts.UserModel.Get()
    if not DB then
        local res = { code = 2003, error = "no user_data" }
        return res
    end

    if not DB.simple then
        --内存中不存在则查询数据库
        local redis_db_data = Database.GetUserSimple(context.addr_db_redis, context.uid)

        local db_data, err = Database.loaduser_simple(context.addr_db_user, context.uid)
        if db_data and #db_data == 1 then
            local pbname, tmp_data = protocol.decodewithname("PBUserSimpleInfo", db_data[1].value)
            DB.simple = tmp_data
        else
            local init_cfg = GameCfg.Init[1]
            if not init_cfg then
                return { code = ErrorCode.ConfigError, error = "no init" }
            end
            --数据库中不存在则视为新用户初始化
            local user_simple = UserSimpleDef.newUserSimpleInfo()
            user_simple.uid = DB.user_id
            user_simple.plateform_id = DB.authkey
            user_simple.nick_name = DB.name or DB.authkey
            user_simple.head_icon = init_cfg.head
            user_simple.head_frame = init_cfg.head_box
            user_simple.account_create_time = moon.time()
            user_simple.account_exp = init_cfg.exp
            user_simple.title = init_cfg.title
            user_simple.online_time = moon.time()

            local db_op, err = Database.saveuser_simple(context.addr_db_user, context.uid, user_simple)
            if not db_op or err then
                local res = { code = 2004, error = "no user_simple" }
                return res
            end
            Database.SetUserSimple(context.addr_db_redis, context.uid, user_simple)
            scripts.UserModel.SetSimple(DB.simple)
        end
    end
    return { code = 0, error = "success", user_simple = DB.simple }
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
    --local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
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
    clusterd.call(3999, "usermgr", "Usermgr.NotifyLogout", { uid = context.uid, nid = moon.env("NODE") })
    
    moon.quit()
    return true
end

function User.C2SUserData()
    context.S2C(CmdCode.S2CUserData, scripts.UserModel.Get())
end

function User.PBClientGetUsrSimInfoReqCmd(req)
  
    local res, err = User.LoadSimple()
    --
    if not err and res then
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

function User.SimpleSetShowRole(role_info)
    local simple_data = scripts.UserModel.GetSimple()
    if not simple_data then
        return false
    end

    simple_data.cur_show_role = RoleDef.newSimpleRoleData()
    simple_data.cur_show_role.config_id = role_info.config_id
    simple_data.cur_show_role.skins = role_info.skins

    return true
end

function User.SimpleSetShowGhost(ghost_info, ghost_image)
    local simple_data = scripts.UserModel.GetSimple()
    if not simple_data then
        return false
    end

    simple_data.cur_show_ghost = GhostDef.newSimpleGhostData()
    simple_data.cur_show_ghost.config_id = ghost_info.config_id
    simple_data.cur_show_ghost.skin_id = ghost_image.cur_skin_id

    return true
end

local function LightRoleEquipment(msg)
    local err_role_code, role_info = scripts.Role.GetRoleInfo(msg.roleid)
    if err_role_code ~= ErrorCode.None or role_info then
        return ErrorCode.RoleNotExist
    end

    if role_info.magic_item
        and role_info.magic_item.common_info
        and role_info.magic_item.common_info.uniqid == msg.uniqid then
        local item_data = role_info.magic_item
        local err_code, change_log = scripts.Bag.Light(item_data)
        if err_code ~= ErrorCode.None or not change_log then
            return ErrorCode.LightMagicItemFail
        end

        -- 存储背包数据
        local save_bags = {}
        for bagType, _ in pairs(change_log) do
            save_bags[bagType] = 1
        end
        if table.size(save_bags) then
            -- 只存储了背包变更数据
            scripts.Bag.SaveAndLog(save_bags, change_log)
        end
        -- 存储角色数据
        scripts.Role.ModMagicItem(msg.roleid, item_data)
        scripts.Role.SaveRolesNow()
        scripts.Role.AddLog(msg.roleid, "LightMagicItem")

        return ErrorCode.None, item_data
    else
        local slot = 0
        for k, v in pairs(role_info.digrams_cards) do
            if v.common_info.uniqid == msg.uniqid then
                slot = k
                break
            end
        end
        if slot == 0 then
            return ErrorCode.DigramsCardNotExist
        end

        local item_data = role_info.digrams_cards[slot]
        local err_code, change_log = scripts.Bag.Light(item_data)
        if err_code ~= ErrorCode.None or not change_log then
            return ErrorCode.LightDigramsCardFail
        end

        -- 存储背包数据
        local save_bags = {}
        for bagType, _ in pairs(change_log) do
            save_bags[bagType] = 1
        end
        if table.size(save_bags) then
            -- 只存储了背包变更数据
            scripts.Bag.SaveAndLog(save_bags, change_log)
        end
        -- 存储角色数据
        scripts.Role.ModDiagramsCard(msg.roleid, item_data, slot)
        scripts.Role.SaveRolesNow()
        scripts.Role.AddLog(msg.roleid, "LightDiagramsCard")

        return ErrorCode.None, item_data
    end
end

local function LightGhostEquipment(msg)
    local err_ghost_code, ghost_info = scripts.Ghost.GetGhostInfo(msg.ghostid)
    if err_ghost_code ~= ErrorCode.None or ghost_info then
        return ErrorCode.GhostNotExist
    end

    if ghost_info.digrams_cards then
        local slot = 0
        for k, v in pairs(ghost_info.digrams_cards) do
            if v.common_info.uniqid == msg.uniqid then
                slot = k
                break
            end
        end
        if slot == 0 then
            return ErrorCode.DigramsCardNotExist
        end

        local item_data = ghost_info.digrams_cards[slot]
        local err_code, change_log = scripts.Bag.Light(item_data)
        if err_code ~= ErrorCode.None or not change_log then
            return ErrorCode.LightDigramsCardFail
        end

        -- 存储背包数据
        local save_bags = {}
        for bagType, _ in pairs(change_log) do
            save_bags[bagType] = 1
        end
        if table.size(save_bags) then
            -- 只存储了背包变更数据
            scripts.Bag.SaveAndLog(save_bags, change_log)
        end
        -- 存储角色数据
        scripts.Ghost.ModDiagramsCard(msg.ghostid, item_data, slot)
        scripts.Ghost.SaveGhostsNow()
        scripts.Ghost.AddLog(msg.ghostid, "LightDiagramsCard")

        return ErrorCode.None, item_data
    else
        return ErrorCode.DigramsCardNotExist
    end
end

local function LightBagItem(msg)
    local light_bagid = msg.bagid
    local light_pos = msg.pos

    if not msg.uniqid then
        local err_code, change_log = scripts.Bag.GetSpecialItemFromCommonItem(msg.bagid, msg.pos, msg.config_id)
        if err_code ~= ErrorCode.None or not change_log then
            return err_code
        end

        local save_bags = {}
        for bagType, bag_info in pairs(change_log) do
            save_bags[bagType] = 1
            for pos, value in pairs(bag_info) do
                if value.uniqid ~= 0 and value.count == 1 then
                    light_bagid = bagType
                    light_pos = pos
                    break
                end
            end
        end

        -- 生成新唯一道具，进行保存
        scripts.Bag.SaveAndLog(save_bags, change_log)
    end

    local get_err_code, item_data = scripts.Bag.GetOneItemData(light_bagid, light_pos)
    if get_err_code ~= ErrorCode.None
        or not item_data
        or (msg.uniqid ~= 0 and item_data.common_info.uniqid ~= msg.uniqid) then
        return get_err_code
    end

    -- 记录旧道具数据
    local old_itemdata = table.copy(item_data)
    local light_err_code, change_log = scripts.Bag.Light(item_data)
    if light_err_code ~= ErrorCode.None or not change_log then
        return light_err_code
    end

    -- 存储数据
    if not change_log[light_bagid] then
        change_log[light_bagid] = {}
    end
    scripts.Bag.AddLog(change_log[light_bagid], light_pos, BagDef.LogType.ChangeInfo, old_itemdata.common_info.config_id,
        old_itemdata.common_info.uniqid, item_data.common_info.item_count, old_itemdata)

    local save_bags = {}
    for bagType, _ in pairs(change_log) do
        save_bags[bagType] = 1
    end

    if table.size(save_bags) then
        scripts.Bag.SaveAndLog(save_bags, change_log)
    end

    return ErrorCode.None, item_data
end

-- 客户端请求--装备开光
function User.PBClientLightReqCmd(req)
    local err_code, item_data = ErrorCode.None, nil

    -- 参数有效性验证
    if req.msg.roleid and req.msg.uniqid then
        err_code, item_data = LightRoleEquipment(req.msg)
    elseif req.msg.ghostid and req.msg.uniqid then
        err_code, item_data = LightGhostEquipment(req.msg)
    elseif req.msg.bagid and req.msg.pos then
        err_code, item_data = LightBagItem(req.msg)
    else
        return context.S2C(context.net_id, CmdCode.PBClientLightRspCmd, {
            code = ErrorCode.ParamInvalid,
            error = "无效请求参数",
            uid = context.uid,
            roleid = req.msg.roleid or 0,
            ghostid = req.msg.ghostid or 0,
            bagid = req.msg.bagid or 0,
            pos = req.msg.pos or 0,
            config_id = req.msg.config_id or 0,
            uniqid = req.msg.uniqid or 0,
        }, req.msg_context.stub_id)
    end

    if err_code == ErrorCode.None and item_data then
        return context.S2C(context.net_id, CmdCode.PBClientLightRspCmd, {
            code = ErrorCode.None,
            error = "",
            uid = context.uid,
            roleid = req.msg.roleid or 0,
            ghostid = req.msg.ghostid or 0,
            bagid = req.msg.bagid or 0,
            pos = req.msg.pos or 0,
            config_id = req.msg.config_id or 0,
            uniqid = req.msg.uniqid or 0,
        })
    else
        return context.S2C(context.net_id, CmdCode.PBClientLightRspCmd, {
            code = err_code,
            error = "开光失败",
            uid = context.uid,
            roleid = req.msg.roleid or 0,
            ghostid = req.msg.ghostid or 0,
            bagid = req.msg.bagid or 0,
            pos = req.msg.pos or 0,
            config_id = req.msg.config_id or 0,
            uniqid = req.msg.uniqid or 0,
        })
    end
end

return User
