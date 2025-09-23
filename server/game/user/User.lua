local moon = require("moon")
local common = require("common")
local clusterd = require("cluster")
local json = require "json"
local CmdCode = common.CmdCode
local GameCfg = common.GameCfg
local Database = common.Database
local protocol = common.protocol
local ErrorCode = common.ErrorCode
local UserAttrDef = require("common.def.UserAttrDef")
local RoleDef = require("common.def.RoleDef")
local GhostDef = require("common.def.GhostDef")
local BagDef = require("common.def.BagDef")
local ProtoEnum = require("tools.ProtoEnum")
local UserAttrLogic = require("common.logic.UserAttrLogic")
local CommonCfgDef = require("common.def.CommonCfgDef")
local ItemDefine = require("common.logic.ItemDefine")

---@type user_context
local context = ...
local scripts = context.scripts

local state = { ---内存中的状态
    online = false,
    ismatching = false
}

local simple_fields = {
    ProtoEnum.UserAttrType.uid,
    ProtoEnum.UserAttrType.nick_name,
    ProtoEnum.UserAttrType.head_icon,
    ProtoEnum.UserAttrType.sex,
    ProtoEnum.UserAttrType.head_frame,
    ProtoEnum.UserAttrType.account_exp,
    ProtoEnum.UserAttrType.guild_id,
    ProtoEnum.UserAttrType.guild_name,
    ProtoEnum.UserAttrType.cur_show_role,
    ProtoEnum.UserAttrType.title,
    ProtoEnum.UserAttrType.player_flag,
    ProtoEnum.UserAttrType.is_online,
}

local function hasSimpleAttr(user_attr)  
    for _, simple_field in pairs(simple_fields) do
        if user_attr[simple_field] then
            return true
        end
    end

    return false
end

---@class User
local User = {}
function User.Load(req)
    local function fn()
        -- 向Usermgr申请是否允许登录
        local res, err = clusterd.call(3999, "usermgr", "Usermgr.ApplyLogin",
            { uid = req.uid, nid = moon.env("NODE"), addr_user = req.addr_user })

        if res.error ~= "success" then
            moon.error(string.format("User.Load res = %s", json.pretty_encode(res)))
            return false
        end

        local data = scripts.UserModel.Get()
        if data then
            --moon.error(string.format("User.Load return data = %s", json.pretty_encode(data)))
            return data
        end

        ---加载UserAttr数据
        local db_user_attr, err = Database.loaduser_attr(context.addr_db_user, req.uid)
        if db_user_attr then
            data = {
                user_id = db_user_attr.uid,
                authkey = req.plateform_id,
                user_attr = db_user_attr, -- 取出结果集第一条记录
            }
        end

        local isnew = false
        if not data then
            if req.pull then
                return false
            end

            isnew = true
            --数据库中不存在则视为新用户初始化
            data = {
                authkey = req.plateform_id,
                user_id = req.uid,
                user_attr = UserAttrDef.newUserAttr(),
            }
            data.user_attr.uid = data.user_id
            data.user_attr.plateform_id = data.authkey
            data.user_attr.nick_name = data.name or data.authkey
            data.user_attr.account_create_time = moon.time()
        end
        data.user_attr.online_time = moon.time()
        data.user_attr.is_online = UserAttrDef.ONLINE_STATE.ONLINE

        scripts.UserModel.Create(data)
        context.uid = req.uid
        context.net_id = req.net_id
        -- moon.warn(string.format("User.Load context.net_id = %d", context.net_id))

        ---初始化自己数据
        context.batch_invoke_throw("Init", isnew)
        ---初始化互相引用的数据
        context.batch_invoke_throw("Start", isnew)

        if isnew then
            ---根据初始化表进行user_attr初始化
            local init_cfg = GameCfg.Init[1]
            if not init_cfg then
                return false
            end

            ---存储UserAttr数据
            local user_attr = scripts.UserModel.MutGetUserAttr()
            user_attr.head_icon = init_cfg.head
            user_attr.head_frame = init_cfg.head_box
            user_attr.account_exp = init_cfg.exp
            user_attr.title = init_cfg.title
        end

        -- ---加载道具图鉴数据
        -- local image_res = scripts.ItemImage.Start()
        -- if image_res.code ~= ErrorCode.None then
        --     return false
        -- end
        -- ---加载背包数据
        -- scripts.Bag.Start()
        -- ---加载角色数据
        -- local role_res = scripts.Role.Start()
        -- if role_res.code ~= ErrorCode.None then
        --     return false
        -- end
        -- ---加载鬼宠数据
        -- local ghost_res = scripts.Ghost.Start()
        -- if ghost_res.code ~= ErrorCode.None then
        --     return false
        -- end

        -- 同步到redis
        local to_redis_data = scripts.UserModel.GetUserAttr()
        Database.RedisSetUserAttr(context.addr_db_redis, context.uid, to_redis_data)

        local simple_attr = User.GetUserSimpleData()
        --local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
        local simple_to_redis = {}
        simple_to_redis[context.uid] = simple_attr
        Database.RedisSetSimpleUserAttr(context.addr_db_redis, simple_to_redis)
        --local user_attr_res = User.LoadUserAttr()
        --if user_attr_res.code ~= ErrorCode.None then
        --    return false
        --end

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

function User.QueryUserAttr(fields)
    local DB = scripts.UserModel.Get()

    if not DB or not DB.user_attr or table.size(DB.user_attr) <= 0 then
        --内存中不存在则查询数据库
        local user_attr = Database.RedisGetUserAttr(context.addr_db_redis, context.uid, fields)
        if not user_attr or table.size(user_attr) <= 0 then
            local db_data = Database.loaduser_attr(context.addr_db_user, context.uid)
            if not db_data then
                return { code = ErrorCode.ServerInternalError, error = "no user_attr" }
            else
                local res_attr = {}
                if type(fields) == "table" then
                    for _, field in pairs(fields) do
                        if db_data[field] then
                            res_attr[field] = db_data[field]
                        end
                    end
                else
                    res_attr = db_data
                end
                
                return { code = ErrorCode.None, error = "success", user_attr = res_attr }
            end
        else
            return { code = ErrorCode.None, error = "success", user_attr = user_attr }
        end
    else
        local res_attr = {}
        if type(fields) == "table" then
            for _, field in pairs(fields) do
                if DB.user_attr[field] then
                    res_attr[field] = DB.user_attr[field]
                end
            end
        else
            res_attr = DB.user_attr
        end
        return { code = ErrorCode.None, error = "success", user_attr = res_attr }
    end
end

function User.SetUserAttr(user_attr, sync_client)
    if not user_attr or type(user_attr) ~= "table" or table.size(user_attr) <= 0 then
        return false
    end

    local t = {}
    local db_user_attr = scripts.UserModel.MutGetUserAttr()
    -- 同步到内存
    for field, value in pairs(user_attr) do
        if user_attr[field] ~= nil then
            db_user_attr[field] = value
            t[field] = value
        end
    end
    -- 同步到redis
    Database.RedisSetUserAttr(context.addr_db_redis, context.uid, t)
    if hasSimpleAttr(t) then
        local simple_attr = {}
        for _, field in pairs(simple_fields) do
            if db_user_attr[field] then
                simple_attr[field] = db_user_attr[field]
            end
        end

        local simple_to_redis = {}
        simple_to_redis[context.uid] = simple_attr
        Database.RedisSetSimpleUserAttr(context.addr_db_redis, simple_to_redis)
    end

    ----local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
    -- 同步到客户端
    if sync_client then
        local msg_data = {
            attr = t
        }
        context.S2C(context.net_id, CmdCode["PBUserAttrSyncCmd"], msg_data, 0)
    end
end

function User.GetOnlineUserAttr(fields)
    local db_user_attr = scripts.UserModel.GetUserAttr()
    local user_attr = {}
    --local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
    if type(fields) == "table" then
        for _, field in pairs(fields) do
            if db_user_attr[field] then
                user_attr[field] = db_user_attr[field]
            end
        end
    else
        -- 取全数据
        return db_user_attr
    end
    return user_attr
end

function User.GetUserSimpleData()
    local simple_data = User.GetOnlineUserAttr(simple_fields)

    return simple_data
end

function User.GetUsrRoomBriefData()
    local room_member_fields = {
        ProtoEnum.UserAttrType.uid,
        ProtoEnum.UserAttrType.nick_name,
        ProtoEnum.UserAttrType.head_icon,
        ProtoEnum.UserAttrType.sex,
        ProtoEnum.UserAttrType.head_frame,
        ProtoEnum.UserAttrType.rank_level,
        ProtoEnum.UserAttrType.cur_show_role,
        ProtoEnum.UserAttrType.title,
        ProtoEnum.UserAttrType.player_flag,
        ProtoEnum.UserAttrType.cur_show_ghost,
    }
    local room_member_data = User.GetOnlineUserAttr(room_member_fields)

    return room_member_data
end

function User.GetUserDetails()
    local details_fields = {
        ProtoEnum.UserAttrType.uid,
        ProtoEnum.UserAttrType.nick_name,
        ProtoEnum.UserAttrType.head_icon,
        ProtoEnum.UserAttrType.sex,
        ProtoEnum.UserAttrType.head_frame,
        ProtoEnum.UserAttrType.rank_level,
        ProtoEnum.UserAttrType.guild_id,
        ProtoEnum.UserAttrType.guild_name,
        ProtoEnum.UserAttrType.cur_show_role,
        ProtoEnum.UserAttrType.title,
        ProtoEnum.UserAttrType.player_flag,
        ProtoEnum.UserAttrType.cur_show_ghost,
    }
    local details_data = User.GetOnlineUserAttr(details_fields)
    local role_data = scripts.Role.GetRoleInfo(details_data.cur_show_role.config_id)
    local ghost_data = scripts.Ghost.GetGhostInfo(details_data.cur_show_ghost.config_id)

    return {user_attr = details_data, role_data = role_data, ghost_data = ghost_data}
end

function User.Login(req)
    if req.pull then --服务器主动拉起玩家
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

function User.InPlay(roomid)
    if not context.roomid or context.roomid ~= roomid then
        return
    end
    -- 同步游戏中状态到redis
    local update_user_attr = {}
    update_user_attr[ProtoEnum.UserAttrType.is_online] = UserAttrDef.ONLINE_STATE.IN_GAME
    User.SetUserAttr(update_user_attr, true)
end

function User.OutPlay(roomid)
    moon.warn("User.OutPlay roomid = ", roomid)
    if not context.roomid or context.roomid ~= roomid then
        moon.error("User.OutPlay roomid not match, roomid = ", roomid)
        return
    end

    local query_user_attr = {}
    table.insert(query_user_attr, ProtoEnum.UserAttrType.is_online)
    local query_res = User.QueryUserAttr(query_user_attr)
    if query_res[ProtoEnum.UserAttrType.is_online] == UserAttrDef.ONLINE_STATE.IN_GAME then
        -- 同步离开游戏中状态到redis
        local update_user_attr = {}
        if context.roomid then
            update_user_attr[ProtoEnum.UserAttrType.is_online] = UserAttrDef.ONLINE_STATE.IN_ROOM
        else
            update_user_attr[ProtoEnum.UserAttrType.is_online] = UserAttrDef.ONLINE_STATE.ONLINE
        end
        User.SetUserAttr(update_user_attr, true)
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

    -- 退出房间
    scripts.Room.ForceExitRoom()

    -- 同步离线状态到redis
    local update_user_attr = {}
    update_user_attr[ProtoEnum.UserAttrType.is_online] = UserAttrDef.ONLINE_STATE.OFFLINE
    User.SetUserAttr(update_user_attr, false)

    User.Logout()

    -- 通知usermgr
    local res, err = clusterd.call(3999, "usermgr", "Usermgr.NotifyLogout", { uid = context.uid, nid = moon.env("NODE") })
    if err then
        moon.error(string.format("User.Exit err = %s", json.pretty_encode(err)))
    end
    if res.error ~= "success" then
        moon.error(string.format("User.Exit res = %s", json.pretty_encode(res)))
    end
    
    moon.quit()
    return true
end

function User.C2SUserData()
    context.S2C(CmdCode.S2CUserData, scripts.UserModel.Get())
end

function User.PBClientGetUsrSimInfoReqCmd(req)
    local simple_data = User.GetUserSimpleData()

    -- local tmp_uids = {}
    -- table.insert(tmp_uids, context.uid)
    -- table.insert(tmp_uids, context.uid + 1)
    -- local user_attr = Database.RedisGetSimpleUserAttr(context.addr_db_redis, tmp_uids)
    
    local ret = {
        code = ErrorCode.None,
        error = "success",
        uid = context.uid,
        info = simple_data,
    }
    -- moon.warn(string.format("PBClientGetUsrSimInfoReqCmd ret = %s", json.pretty_encode(ret)))
    -- moon.warn(string.format("PBClientGetUsrSimInfoReqCmd req.msg_context.stub_id = %d", req.msg_context.stub_id))
    context.S2C(context.net_id, CmdCode["PBClientGetUsrSimInfoRspCmd"], ret, req.msg_context.stub_id)
end

function User.PBClientGetAllUserAttrReqCmd(req)
    local total_attr = User.GetOnlineUserAttr()

    local ret = {
        code = ErrorCode.None,
        error = "success",
        uid = context.uid,
        info = total_attr,
    }
    context.S2C(context.net_id, CmdCode["PBClientGetAllUserAttrRspCmd"], ret, req.msg_context.stub_id)
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

    local update_user_attr = {}
    update_user_attr[ProtoEnum.UserAttrType.online_time] = moon.time()
    User.SetUserAttr(update_user_attr, false)
end

-- function User.SimpleSetShowRole(role_info)
--     local user_attr = scripts.UserModel.GetUserAttr()
--     if not user_attr then
--         return false
--     end

--     if not user_attr.cur_show_role then
--         user_attr.cur_show_role = RoleDef.newSimpleRoleData()
--     end
--     user_attr.cur_show_role.config_id = role_info.config_id
--     user_attr.cur_show_role.skins = role_info.skins

--     return true
-- end

-- function User.SimpleSetShowGhost(ghost_info, ghost_image)
--     local user_attr = scripts.UserModel.GetUserAttr()
--     if not user_attr then
--         return false
--     end

--     if not user_attr.cur_show_ghost then
--         user_attr.cur_show_ghost = GhostDef.newSimpleGhostData()
--     end
--     user_attr.cur_show_ghost.config_id = ghost_info.config_id
--     user_attr.cur_show_ghost.skin_id = ghost_image.cur_skin_id

--     return true
-- end

local function LightRoleEquipment(msg)
    local role_info = scripts.Role.GetRoleInfo(msg.roleid)
    if not role_info then
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
        if table.size(save_bags) > 0 then
            -- 只存储了背包变更数据
            scripts.Bag.SaveAndLog(save_bags, change_log)
        end
        -- 存储角色数据
        if scripts.Role.ModMagicItem(msg.roleid, item_data) == ErrorCode.None then
            local change_roles = {}
            change_roles[msg.roleid] = "LightMagicItem"
            scripts.Role.SaveAndLog(change_roles)
        else
            moon.error("LightRoleEquipment LightMagicItem Fail:", msg.roleid)
        end

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
        if table.size(save_bags) > 0 then
            -- 只存储了背包变更数据
            scripts.Bag.SaveAndLog(save_bags, change_log)
        end
        -- 存储角色数据
        if scripts.Role.ModDiagramsCard(msg.roleid, item_data, slot) then
            local change_roles = {}
            change_roles[msg.roleid] = "LightDiagramsCard"
            scripts.Role.SaveAndLog(change_roles)
        else
            moon.error("LightRoleEquipment LightDiagramsCard Fail:", msg.roleid)
        end

        return ErrorCode.None, item_data
    end
end

local function LightGhostEquipment(msg)
    local ghost_info = scripts.Ghost.GetGhostInfo(msg.ghostid)
    if not ghost_info then
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
        if table.size(save_bags) > 0 then
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
    local light_bagid = msg.bag_name
    local light_pos = msg.pos

    if not msg.uniqid or msg.uniqid == 0 then
        local err_code, change_log = scripts.Bag.GetSpecialItemFromCommonItem(msg.bag_name, msg.pos, msg.config_id)
        if err_code ~= ErrorCode.None or not change_log then
            return err_code
        end

        local save_bags = {}
        for bagType, logs in pairs(change_log) do
            save_bags[bagType] = 1
            for pos, log in pairs(logs) do
                if log.log_type == BagDef.LogType.ChangeNum
                    and log.old_config_id == 0
                    and log.old_count == 0 then
                    light_bagid = bagType
                    light_pos = pos
                end
            end
        end

        -- 生成新唯一道具，进行保存
        scripts.Bag.SaveAndLog(save_bags, change_log)
    end

    --local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
    local get_err_code, item_data = scripts.Bag.MutOneItemData(light_bagid, light_pos)
    if get_err_code ~= ErrorCode.None
        or not item_data
        or (msg.uniqid ~= 0 and item_data.common_info.uniqid ~= msg.uniqid) then
        return get_err_code
    end

    -- 记录旧道具数据
    local old_itemdata = table.copy(item_data)
    if not old_itemdata then
        return ErrorCode.BagNotExist
    end

    local light_err_code, change_log = scripts.Bag.Light(item_data)
    if light_err_code ~= ErrorCode.None or not change_log then
        return light_err_code
    end

    -- 存储数据
    if not change_log[light_bagid] then
        change_log[light_bagid] = {}
    end
    scripts.Bag.AddLog(change_log[light_bagid], light_pos, BagDef.LogType.ChangeInfo, old_itemdata.common_info.config_id,
        old_itemdata.common_info.uniqid, old_itemdata.common_info.item_count, old_itemdata)

    local save_bags = {}
    for bagType, _ in pairs(change_log) do
        save_bags[bagType] = 1
    end

    if table.size(save_bags) > 0 then
        scripts.Bag.SaveAndLog(save_bags, change_log)
    end

    return ErrorCode.None, item_data
end

-- 客户端请求--装备开光
function User.PBClientLightReqCmd(req)
    local err_code, item_data = ErrorCode.None, nil
    --local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
    -- 参数有效性验证
    if req.msg.roleid and req.msg.roleid ~= 0
        and req.msg.uniqid and req.msg.uniqid ~= 0 then
        err_code, item_data = LightRoleEquipment(req.msg)
    elseif req.msg.ghostid and req.msg.ghostid ~= 0
        and req.msg.uniqid and req.msg.uniqid ~= 0 then
        err_code, item_data = LightGhostEquipment(req.msg)
    elseif req.msg.bag_name and req.msg.bag_name ~= ""
        and req.msg.pos and req.msg.pos ~= 0 then
        err_code, item_data = LightBagItem(req.msg)
    else
        return context.S2C(context.net_id, CmdCode.PBClientLightRspCmd, {
            code = ErrorCode.ParamInvalid,
            error = "无效请求参数",
            uid = context.uid,
            roleid = req.msg.roleid or 0,
            ghostid = req.msg.ghostid or 0,
            bag_name = req.msg.bag_name or "",
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
            bag_name = req.msg.bag_name or "",
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
            bag_name = req.msg.bag_name or "",
            pos = req.msg.pos or 0,
            config_id = req.msg.config_id or 0,
            uniqid = req.msg.uniqid or 0,
        })
    end
end

-- 客户端请求--所有背包和货币信息
function User.PBClientGetUsrBagsInfoReqCmd(req)
    local bagdata = scripts.UserModel.GetBagData()
    if not bagdata then
        return context.S2C(context.net_id, CmdCode["PBClientGetUsrBagsInfoRspCmd"],
            { code = ErrorCode.BagNotExist, error = "背包未加载", uid = context.uid }, req.msg_context.stub_id)
    end

    local coinsdata = scripts.UserModel.GetCoinsData()
    if not coinsdata then
        return context.S2C(context.net_id, CmdCode["PBClientGetUsrBagsInfoRspCmd"],
            { code = ErrorCode.BagNotExist, error = "货币未加载", uid = context.uid }, req.msg_context.stub_id)
    end

    local res = {
        code = ErrorCode.None,
        error = "",
        uid = context.uid,
        bags_info = {
            bags = {}
        },
        coins_info = coinsdata,
    }
    for _, bag_name in pairs(req.msg.bags_name) do
        if bagdata[bag_name] then
            res.bags_info.bags[bag_name] = bagdata[bag_name]
        end
    end

    return context.S2C(context.net_id, CmdCode["PBClientGetUsrBagsInfoRspCmd"], res, req.msg_context.stub_id)
end

-- DS给玩家加道具
function User.DsAddItems(simple_items)
    local bagdata = scripts.UserModel.GetBagData()
    if not bagdata then
        return ErrorCode.BagNotExist
    end

    local coinsdata = scripts.UserModel.GetCoinsData()
    if not coinsdata then
        return ErrorCode.BagNotExist
    end

    local add_items = {}
    local add_coins = {}
    local change_log = {}
    local err_code = ErrorCode.None
    for _, item in pairs(simple_items) do
        local smallType = ItemDefine.GetItemType(item.config_id)
        if smallType == ItemDefine.EItemSmallType.Coin then
            add_coins[item.config_id] = {
                coin_id = item.config_id,
                coin_count = item.item_count,
            }
        else
            add_items[item.config_id] = {id = item.config_id, count = item.item_count, pos = 0 }
        end
    end

    --local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
    if table.size(add_items) + table.size(add_coins) <= 0 then
        err_code = ErrorCode.ItemNotExist
    end

    -- 根据道具表生成item_data
    -- local add_list = {}
    -- ItemDefine.GetItemListFromItemsCoins(add_items, add_coins, add_list)
    local stack_items, unstack_items, deal_coins = {}, {}, {}
    local ok = ItemDefine.GetItemDataFromIdCount(add_items, add_coins, stack_items, unstack_items, deal_coins)
    if not ok then
        return ErrorCode.ConfigError
    end

    if table.size(stack_items) + table.size(unstack_items) > 0 then
        err_code = scripts.Bag.AddItems(BagDef.BagType.Cangku, stack_items, unstack_items, change_log)
    end
    if table.size(deal_coins) > 0 then
        err_code = scripts.Bag.DealCoins(deal_coins, change_log)
    end

    if err_code == ErrorCode.None then
        local save_bags = {}
        for bagType, _ in pairs(change_log) do
            save_bags[bagType] = 1
        end
        --local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
        scripts.Bag.SaveAndLog(save_bags, change_log)
    end
    return err_code
end

-- 客户端请求--图鉴升级
function User.PBClientItemUpLvReqCmd(req)
    -- 参数验证
    if not req.msg.config_id or req.msg.add_exp <= 0 then
        return context.S2C(context.net_id, CmdCode.PBClientItemUpLvRspCmd, {
            code = ErrorCode.ParamInvalid,
            error = "无效请求参数",
            uid = context.uid,
            config_id = req.msg.config_id or 0,
            add_exp = req.msg.add_exp or 0,
        }, req.msg_context.stub_id)
    end

    local err_code, change_log = ErrorCode.None, nil
    if RoleDef.RoleDefine.RoleID.Start <= req.msg.config_id
        and req.msg.config_id <= RoleDef.RoleDefine.RoleID.End then
        err_code, change_log = scripts.Role.UpLv(req.msg.config_id, req.msg.add_exp)
    elseif GhostDef.GhostDefine.GhostID.Start <= req.msg.config_id
        and req.msg.config_id <= GhostDef.GhostDefine.GhostID.End then
        err_code, change_log = scripts.Ghost.UpLv(req.msg.config_id, req.msg.add_exp)
    else
        -- 图鉴升级
        err_code, change_log = scripts.ItemImage.UpLvImage(req.msg.config_id, req.msg.add_exp)
    end
    
    if err_code ~= ErrorCode.None then
        return context.S2C(context.net_id, CmdCode.PBClientItemUpLvRspCmd, {
            code = ErrorCode.ItemNotExist,
            error = "图鉴不存在",
            uid = context.uid,
            config_id = req.msg.config_id,
            add_exp = req.msg.add_exp,
        }, req.msg_context.stub_id)
    end

    context.S2C(context.net_id, CmdCode.PBClientItemUpLvRspCmd, {
        code = ErrorCode.None,
        error = "",
        uid = context.uid,
        config_id = req.msg.config_id,
        add_exp = req.msg.add_exp,
    }, req.msg_context.stub_id)

    -- 存储背包变更
    if change_log then
        local save_bags = {}
        for bagType, _ in pairs(change_log) do
            save_bags[bagType] = 1
        end

        if table.size(save_bags) > 0 then
            scripts.Bag.SaveAndLog(save_bags, change_log)
        end
    end
    if RoleDef.RoleDefine.RoleID.Start <= req.msg.config_id
        and req.msg.config_id <= RoleDef.RoleDefine.RoleID.End then
        local change_roles = {}
        change_roles[req.msg.config_id] = "UpLv"
        scripts.Role.SaveAndLog(change_roles)
    elseif GhostDef.GhostDefine.GhostID.Start <= req.msg.config_id
        and req.msg.config_id <= GhostDef.GhostDefine.GhostID.End then
        local change_ghosts = {
            ghost = {},
            image = {},
        }
        change_ghosts.image[req.msg.config_id] = "UpLv"
        scripts.Ghost.SaveAndLog(change_ghosts)
    else
        -- 图鉴信息变更
        local change_image_ids = {}
        table.insert(change_image_ids, req.msg.config_id)
        scripts.ItemImage.SaveAndLog(change_image_ids)
    end
end

-- 客户端请求--使用道具升级
function User.PBUseItemUpLvReqCmd(req)
    -- 参数验证
    if not req.msg.target_id or not req.msg.cost_id or req.msg.cost_num <= 0 then
        return context.S2C(context.net_id, CmdCode.PBUseItemUpLvRspCmd, {
            code = ErrorCode.ParamInvalid,
            error = "无效请求参数",
            uid = context.uid,
            target_id = req.msg.target_id or 0,
            cost_id = req.msg.cost_id or 0,
            cost_num = req.msg.cost_num or 0,
        }, req.msg_context.stub_id)
    end

    local cost_items = {}
    cost_items[req.msg.cost_id] = {
        id = req.msg.cost_id,
        count = 0,
        pos = 0,
    }
    cost_items[req.msg.cost_id].count = cost_items[req.msg.cost_id].count - req.msg.cost_num

    -- 检测道具是否足够
    local bag_cost_code = scripts.Bag.CheckItemsEnough(BagDef.BagType.Cangku, cost_items, {})
    if bag_cost_code ~= ErrorCode.None then
        return context.S2C(context.net_id, CmdCode.PBUseItemUpLvRspCmd, {
            code = bag_cost_code,
            error = "道具不足",
            uid = context.uid,
            target_id = req.msg.target_id,
            cost_id = req.msg.cost_id,
            cost_num = req.msg.cost_num,
        }, req.msg_context.stub_id)
    end

    local item_cfg = GameCfg.Item[req.msg.cost_id]
    if not item_cfg or not item_cfg.use_award or table.size(item_cfg.use_award) ~= 1 then
        return context.S2C(context.net_id, CmdCode.PBUseItemUpLvRspCmd, {
            code = ErrorCode.ConfigError,
            error = "道具配置错误",
            uid = context.uid,
            target_id = req.msg.target_id,
            cost_id = req.msg.cost_id,
            cost_num = req.msg.cost_num,
        }, req.msg_context.stub_id)
    end

    local up_exp_id, up_exp_cnt = 0, 0
    for id, cnt in pairs(item_cfg.use_award) do
        up_exp_id = id
        up_exp_cnt = cnt * req.msg.cost_num
    end

    -- 检查经验增加
    local err_code = ErrorCode.None
    if RoleDef.RoleDefine.RoleID.Start <= req.msg.target_id
        and req.msg.target_id <= RoleDef.RoleDefine.RoleID.End then
        err_code = scripts.Role.CheckUseItemUpLv(req.msg.target_id, up_exp_id, up_exp_cnt)
    elseif GhostDef.GhostDefine.GhostID.Start <= req.msg.target_id
        and req.msg.target_id <= GhostDef.GhostDefine.GhostID.End then
        err_code = scripts.Ghost.CheckUseItemUpLv(req.msg.target_id, up_exp_id, up_exp_cnt)
    else
        -- 图鉴升级
        err_code = scripts.ItemImage.CheckUseItemUpLv(req.msg.target_id, up_exp_id, up_exp_cnt)
    end
    if err_code ~= ErrorCode.None then
        return context.S2C(context.net_id, CmdCode.PBUseItemUpLvRspCmd, {
            code = err_code,
            error = "升级失败",
            uid = context.uid,
            target_id = req.msg.target_id,
            cost_id = req.msg.cost_id,
            cost_num = req.msg.cost_num,
        }, req.msg_context.stub_id)
    end

    -- 扣除消耗
    local bag_change_log = {}
    local err_code_del = ErrorCode.None
    if table.size(cost_items) > 0 then
        err_code_del = scripts.Bag.DelItems(BagDef.BagType.Cangku, cost_items, {}, bag_change_log)
        if err_code_del ~= ErrorCode.None then
            scripts.Bag.RollBackWithChange(bag_change_log)
            return context.S2C(context.net_id, CmdCode.PBUseItemUpLvRspCmd, {
                code = err_code_del,
                error = "道具不足",
                uid = context.uid,
                target_id = req.msg.target_id,
                cost_id = req.msg.cost_id,
                cost_num = req.msg.cost_num,
            }, req.msg_context.stub_id)
        end
    end

    -- 增加经验
    if RoleDef.RoleDefine.RoleID.Start <= req.msg.target_id
        and req.msg.target_id <= RoleDef.RoleDefine.RoleID.End then
        err_code = scripts.Role.UpExp(req.msg.target_id, up_exp_cnt)
    elseif GhostDef.GhostDefine.GhostID.Start <= req.msg.target_id
        and req.msg.target_id <= GhostDef.GhostDefine.GhostID.End then
        err_code = scripts.Ghost.UpExp(req.msg.target_id, up_exp_cnt)
    else
        -- 图鉴升级
        err_code = scripts.ItemImage.UpExp(req.msg.target_id, up_exp_cnt)
    end
    if err_code ~= ErrorCode.None then
        scripts.Bag.RollBackWithChange(bag_change_log)
        return context.S2C(context.net_id, CmdCode.PBUseItemUpLvRspCmd, {
            code = err_code,
            error = "增加经验失败",
            uid = context.uid,
            target_id = req.msg.target_id,
            cost_id = req.msg.cost_id,
            cost_num = req.msg.cost_num,
        }, req.msg_context.stub_id)
    end

    context.S2C(context.net_id, CmdCode.PBUseItemUpLvRspCmd, {
        code = err_code,
        error = "success",
        uid = context.uid,
        target_id = req.msg.target_id,
        cost_id = req.msg.cost_id,
        cost_num = req.msg.cost_num,
    }, req.msg_context.stub_id)

    -- 存储背包变更
    if bag_change_log then
        local save_bags = {}
        for bagType, _ in pairs(bag_change_log) do
            save_bags[bagType] = 1
        end

        if table.size(save_bags) > 0 then
            scripts.Bag.SaveAndLog(save_bags, bag_change_log)
        end
    end
    if RoleDef.RoleDefine.RoleID.Start <= req.msg.target_id
        and req.msg.target_id <= RoleDef.RoleDefine.RoleID.End then
        local change_roles = {}
        change_roles[req.msg.target_id] = "UpLv"
        scripts.Role.SaveAndLog(change_roles)
    elseif GhostDef.GhostDefine.GhostID.Start <= req.msg.target_id
        and req.msg.target_id <= GhostDef.GhostDefine.GhostID.End then
        local change_ghosts = {
            ghost = {},
            image = {},
        }
        change_ghosts.image[req.msg.target_id] = "UpLv"
        scripts.Ghost.SaveAndLog(change_ghosts)
    else
        -- 图鉴信息变更
        local change_image_ids = {}
        table.insert(change_image_ids, req.msg.target_id)
        scripts.ItemImage.SaveAndLog(change_image_ids)
    end
end

-- 客户端请求--图鉴升星
function User.PBClientItemUpStarReqCmd(req)
    -- 参数验证
    if not req.msg.config_id then
        return context.S2C(context.net_id, CmdCode.PBClientItemUpStarRspCmd, {
            code = ErrorCode.ParamInvalid,
            error = "无效请求参数",
            uid = context.uid,
            config_id = req.msg.config_id or 0,
        }, req.msg_context.stub_id)
    end

    local err_code, change_log = ErrorCode.None, nil
    if RoleDef.RoleDefine.RoleID.Start <= req.msg.config_id
        and req.msg.config_id <= RoleDef.RoleDefine.RoleID.End then
        err_code, change_log = scripts.Role.UpStar(req.msg.config_id)
    elseif GhostDef.GhostDefine.GhostID.Start <= req.msg.config_id
        and req.msg.config_id <= GhostDef.GhostDefine.GhostID.End then
        err_code, change_log = scripts.Ghost.UpStar(req.msg.config_id)
    else
        -- 图鉴升星
        err_code, change_log = scripts.ItemImage.UpStarImage(req.msg.config_id)
    end
    if err_code ~= ErrorCode.None then
        return context.S2C(context.net_id, CmdCode.PBClientItemUpStarRspCmd, {
            code = err_code,
            error = "升星失败",
            uid = context.uid,
            config_id = req.msg.config_id,
        }, req.msg_context.stub_id)
    end

    context.S2C(context.net_id, CmdCode.PBClientItemUpStarRspCmd, {
        code = ErrorCode.None,
        error = "",
        uid = context.uid,
        config_id = req.msg.config_id,
    }, req.msg_context.stub_id)

    -- 存储背包变更
    if change_log then
        local save_bags = {}
        for bagType, _ in pairs(change_log) do
            save_bags[bagType] = 1
        end

        if table.size(save_bags) > 0 then
            scripts.Bag.SaveAndLog(save_bags, change_log)
        end
    end

    if RoleDef.RoleDefine.RoleID.Start <= req.msg.config_id
        and req.msg.config_id <= RoleDef.RoleDefine.RoleID.End then
        local change_roles = {}
        change_roles[req.msg.config_id] = "UpStar"
        scripts.Role.SaveAndLog(change_roles)
    elseif GhostDef.GhostDefine.GhostID.Start <= req.msg.config_id
        and req.msg.config_id <= GhostDef.GhostDefine.GhostID.End then
        local change_ghosts = {
            ghost = {},
            image = {},
        }
        change_ghosts.image[req.msg.config_id] = "UpStar"
        scripts.Ghost.SaveAndLog(change_ghosts)
    else
        -- 图鉴信息变更
        local change_image_ids = {}
        table.insert(change_image_ids, req.msg.config_id)
        scripts.ItemImage.SaveAndLog(change_image_ids)
    end
end

-- function User.PBGetOtherDetailReqCmd(req)
--     if context.uid ~= req.msg.uid
--         or req.msg.quest_uid == 0
--         or req.msg.uid == req.msg.quest_uid then
--         return context.S2C(context.net_id, CmdCode.PBGetOtherDetailReqCmd, {
--             code = ErrorCode.ParamInvalid,
--             error = "无效请求参数",
--             uid = context.uid,
--             quest_uid = req.msg.quest_uid or 0,
--         }, req.msg_context.stub_id)
--     end

--     local detail_fields = {
--         ProtoEnum.UserAttrType.uid,
--         ProtoEnum.UserAttrType.nick_name,
--         ProtoEnum.UserAttrType.head_icon,
--         ProtoEnum.UserAttrType.sex,
--         ProtoEnum.UserAttrType.head_frame,
--         ProtoEnum.UserAttrType.account_exp,
--         ProtoEnum.UserAttrType.guild_id,
--         ProtoEnum.UserAttrType.guild_name,
--         ProtoEnum.UserAttrType.rank_level,
--         ProtoEnum.UserAttrType.cur_show_role,
--         ProtoEnum.UserAttrType.title,
--         ProtoEnum.UserAttrType.player_flag,
--     }
--     local user_attr_res = UserAttrLogic.GetOtherUserAttr(context, req.msg.uid, detail_fields)
--     if user_attr_res then
--         return context.S2C(context.net_id, CmdCode.PBGetOtherDetailReqCmd, {
--             code = ErrorCode.None,
--             error = "",
--             uid = context.uid,
--             quest_uid = req.msg.quest_uid,
--             user_attr = user_attr_res,
--         })
--     else
--         return context.S2C(context.net_id, CmdCode.PBGetOtherDetailReqCmd, {
--             code = ErrorCode.UserOffline,
--             error = "用户离线",
--             uid = context.uid,
--             quest_uid = req.msg.quest_uid or 0,
--         }, req.msg_context.stub_id)
--     end
-- end

function User.PBGetOtherSimpleReqCmd(req)
    if context.uid ~= req.msg.uid
        or req.msg.quest_uid == 0
        or req.msg.uid == req.msg.quest_uid then
        return context.S2C(context.net_id, CmdCode.PBGetOtherSimpleRspCmd, {
            code = ErrorCode.ParamInvalid,
            error = "无效请求参数",
            uid = context.uid,
            quest_uid = req.msg.quest_uid or 0,
        }, req.msg_context.stub_id)
    end

    local quest_uids = {}
    table.insert(quest_uids, req.msg.quest_uid)
    local users_attr = UserAttrLogic.QueryOtherUsersSimpleAttr(context, quest_uids)
    if not users_attr or table.size(users_attr) ~= 1 then
        return context.S2C(context.net_id, CmdCode.PBGetOtherSimpleRspCmd, {
            code = ErrorCode.UserNotExist,
            error = "用户不存在",
            uid = context.uid,
            quest_uid = req.msg.quest_uid or 0,
        }, req.msg_context.stub_id)
    else
        return context.S2C(context.net_id, CmdCode.PBGetOtherSimpleRspCmd, {
            code = ErrorCode.None,
            error = "",
            uid = context.uid,
            quest_uid = req.msg.quest_uid,
            info = users_attr[req.msg.quest_uid],
        }, req.msg_context.stub_id)
    end
end

function User.PBGetOtherDetailReqCmd(req)
    if context.uid ~= req.msg.uid
        or req.msg.quest_uid == 0
        or req.msg.uid == req.msg.quest_uid then
        return context.S2C(context.net_id, CmdCode.PBGetOtherDetailRspCmd, {
            code = ErrorCode.ParamInvalid,
            error = "无效请求参数",
            uid = context.uid,
            quest_uid = req.msg.quest_uid or 0,
        }, req.msg_context.stub_id)
    end

    local res = UserAttrLogic.GetOtherOnlineUserDetails(context, req.msg.quest_uid)
    if res then
        return context.S2C(context.net_id, CmdCode.PBGetOtherDetailRspCmd, {
            code = ErrorCode.None,
            error = "",
            uid = context.uid,
            quest_uid = req.msg.quest_uid,
            info = res.user_attr,
            role_data = res.role_data,
            ghost_data = res.ghost_data,
        }, req.msg_context.stub_id)
    else
        return context.S2C(context.net_id, CmdCode.PBGetOtherDetailReqCmd, {
            code = ErrorCode.UserOffline,
            error = "用户离线",
            uid = context.uid,
            quest_uid = req.msg.quest_uid or 0,
        }, req.msg_context.stub_id)
    end
end

-- 客户端请求--道具修复
function User.PBClientItemRepairReqCmd(req)
    -- 参数验证
    if not req.msg.repair_uniqid or not req.msg.pos then
        return context.S2C(context.net_id, CmdCode.PBClientItemUpLvRspCmd, {
            code = ErrorCode.ParamInvalid,
            error = "无效请求参数",
            uid = context.uid,
            repair_uniqid = req.msg.repair_uniqid or 0,
            pos = req.msg.pos or 0,
        }, req.msg_context.stub_id)
    end

    local function repair_func()
        local errcode, item_data = scripts.Bag.MutOneItemData(BagDef.BagType.Cangku, req.msg.pos)
        if errcode ~= ErrorCode.None or not item_data then
            return errcode
        end
        local old_item_data = table.copy(item_data)
        local smallType = ItemDefine.GetItemType(item_data.common_info.config_id)
        if smallType == ItemDefine.EItemSmallType.MagicItem then
            if item_data.special_info.magic_item.strong_value <= 0 then
                return ErrorCode.StrongNotEnough
            end
            local magic_cfg = GameCfg.MagicItem[item_data.common_info.config_id]
            if not magic_cfg then
                return ErrorCode.ConfigError
            end
            if item_data.special_info.magic_item.cur_durability >= magic_cfg.durability then
                return ErrorCode.DurabilityMax
            end

            local change_logs = {}
            local add_durability = math.min(magic_cfg.durability - item_data.special_info.magic_item.cur_durability,
                item_data.special_info.magic_item.strong_value)
            
            -- 消耗配置
            local common_cfg = CommonCfgDef.getConf("MaintenanceCost")
            if not common_cfg then
                return ErrorCode.ConfigError
            end
            local cost_items = {}
            local cost_coins = {}
            ItemDefine.GetItemsFromCfg(common_cfg.items, add_durability, true, cost_items, cost_coins)

            -- 检测道具是否足够
            errcode = scripts.Bag.CheckItemsEnough(BagDef.BagType.Cangku, cost_items, {})
            if errcode ~= ErrorCode.None then
                return errcode
            end
            errcode = scripts.Bag.CheckCoinsEnough(cost_coins)
            if errcode ~= ErrorCode.None then
                return errcode
            end

            -- 扣除道具
            if table.size(cost_items) > 0 then
                errcode = scripts.Bag.DelItems(BagDef.BagType.Cangku, cost_items, {}, change_logs)
                if errcode ~= ErrorCode.None then
                    scripts.Bag.RollBackWithChange(change_logs)
                    return errcode
                end
            end
            if table.size(cost_coins) > 0 then
                errcode = scripts.Bag.DealCoins(cost_coins, change_logs)
                if errcode ~= ErrorCode.None then
                    scripts.Bag.RollBackWithChange(change_logs)
                    return errcode
                end
            end
            
            -- 增加法器耐久度
            item_data.special_info.magic_item.cur_durability = item_data.special_info.magic_item.cur_durability
                + add_durability
            item_data.special_info.magic_item.strong_value = item_data.special_info.magic_item.strong_value
                - add_durability

            -- 存储数据
            if not change_logs[BagDef.BagType.Cangku] then
                change_logs[BagDef.BagType.Cangku] = {}
            end
            scripts.Bag.AddLog(change_logs[BagDef.BagType.Cangku], req.msg.pos, BagDef.LogType.ChangeInfo,
                item_data.common_info.config_id,
                item_data.common_info.uniqid, item_data.common_info.item_count, old_item_data)

            local save_bags = {}
            for bagType, _ in pairs(change_logs) do
                save_bags[bagType] = 1
            end

            if table.size(save_bags) > 0 then
                scripts.Bag.SaveAndLog(save_bags, change_logs)
            end

            return ErrorCode.None, item_data
        else
            return ErrorCode.ItemTypeMismatch
        end
    end

    local errcode = repair_func()
    return context.S2C(context.net_id, CmdCode.PBClientItemUpLvRspCmd, {
        code = errcode,
        error = "",
        uid = context.uid,
        repair_uniqid = req.msg.repair_uniqid or 0,
        pos = req.msg.pos or 0,
    }, req.msg_context.stub_id)
end

function User.PBUseSkinGiftReqCmd(req)
    -- 参数验证
    if not req.msg.uid or not req.msg.gift_id then
        return context.S2C(context.net_id, CmdCode.PBUseSkinGiftRspCmd, {
            code = ErrorCode.ParamInvalid,
            error = "无效请求参数",
            uid = context.uid,
            gift_id = req.msg.gift_id or 0,
        }, req.msg_context.stub_id)
    end

    -- 读取皮肤礼包表
end

function User.Composite(composite_cfg, add_roles, add_items)
    local random_rate = math.random(1, 10000)
    if random_rate > composite_cfg.rate then
        return { code = ErrorCode.CompositeFail, error = "合成失败" }
    end

    local total_weight = 0
    if composite_cfg.weight then
        for id, weight in pairs(composite_cfg.weight) do
            total_weight = total_weight + weight
        end
    end

    if total_weight > 0 then
        local random_weight = math.random(1, total_weight)
        for id, weight in pairs(composite_cfg.weight) do
            random_weight = random_weight - weight
            if random_weight <= 0 then
                if composite_cfg.item_id[id] then
                    if RoleDef.RoleDefine.RoleID.Start <= id
                        and id <= RoleDef.RoleDefine.RoleID.End then
                        if add_roles[id] then
                            return { code = ErrorCode.RoleExist, error = "角色已拥有" }
                        else
                            add_roles[id] = 1
                        end
                    else
                        if not add_items[id] then
                            add_items[id] = {
                                id = id,
                                count = 0,
                                pos = 0,
                            }
                        end
                        add_items[id].count = add_items[id].count + composite_cfg.item_id[id]
                    end
                end

                break
            end
        end
    else
        if RoleDef.RoleDefine.RoleID.Start <= composite_cfg.item_id
            and composite_cfg.item_id <= RoleDef.RoleDefine.RoleID.End then
            if add_roles[composite_cfg.item_id] then
                return { code = ErrorCode.RoleExist, error = "角色已拥有" }
            else
                add_roles[composite_cfg.item_id] = 1
            end
        else
            if not add_items[composite_cfg.item_id] then
                add_items[composite_cfg.item_id] = {
                    id = composite_cfg.item_id,
                    count = 0,
                    pos = 0,
                }
            end
            add_items[composite_cfg.item_id].count = add_items[composite_cfg.item_id].count + composite_cfg.num
        end
    end

    -- 检测是否可以添加
    -- for _, roleid in pairs(add_roles) do
    --     local role_info = scripts.Role.GetRoleInfo(roleid)
    --     if role_info then
    --         return { code = ErrorCode.RoleExist, error = "角色已拥有" }
    --     end
    -- end
    -- if table.size(add_items) > 0 then
    --     local err_code = scripts.Bag.CheckEmptyEnough(BagDef.BagType.Cangku, add_items, 0)
    --     if err_code ~= ErrorCode.None then
    --         return { code = err_code, error = "背包空间不足" }
    --     end
    -- end

    return { code = ErrorCode.None, error = "合成成功" }
end

function User.PBSureCompositeReqCmd(req)
    -- 参数验证
    if not req.msg.uid or not req.msg.composite_id then
        return context.S2C(context.net_id, CmdCode.PBSureCompositeRspCmd, {
            code = ErrorCode.ParamInvalid,
            error = "无效请求参数",
            uid = context.uid,
            composite_id = req.msg.composite_id or 0,
        }, req.msg_context.stub_id)
    end

    local rsp_msg = {
        code = ErrorCode.None,
        error = "",
        uid = context.uid,
        composite_id = req.msg.composite_id or 0,
    }
    local composite_cfg = GameCfg.Composite[req.msg.composite_id]
    if not composite_cfg
        or req.msg.composite_cnt < 0
        or req.msg.composite_cnt > composite_cfg.max_num then
        rsp_msg.code = ErrorCode.ConfigError
        rsp_msg.error = "配置不存在"
        return context.S2C(context.net_id, CmdCode.PBSureCompositeRspCmd, rsp_msg, req.msg_context.stub_id)
    end

    local cost_items = {}
    local cost_coins = {}
    ItemDefine.GetItemsFromCfg(composite_cfg.cost, req.msg.composite_cnt, true, cost_items, cost_coins)

    -- 检测道具是否足够
    rsp_msg.code = scripts.Bag.CheckItemsEnough(BagDef.BagType.Cangku, cost_items, {})
    if rsp_msg.code ~= ErrorCode.None then
        rsp_msg.error = "道具不足"
        return context.S2C(context.net_id, CmdCode.PBSureCompositeRspCmd, rsp_msg, req.msg_context.stub_id)
    end
    rsp_msg.code = scripts.Bag.CheckCoinsEnough(cost_coins)
    if rsp_msg.code ~= ErrorCode.None then
        rsp_msg.error = "货币不足"
        return context.S2C(context.net_id, CmdCode.PBSureCompositeRspCmd, rsp_msg, req.msg_context.stub_id)
    end

    local add_roles = {}
    local add_items = {}
    for i = 1, req.msg.composite_cnt do
        local composite_ret = User.Composite(composite_cfg, add_roles, add_items)
        if composite_ret.code ~= ErrorCode.None
            and composite_ret.code ~= composite_ret.Errcode.CompositeFail then
            rsp_msg.code = composite_ret.code
            rsp_msg.error = composite_ret.error
            return context.S2C(context.net_id, CmdCode.PBSureCompositeRspCmd, rsp_msg, req.msg_context.stub_id)
        end
    end

    -- 检测是否可以添加
    for roleid, _ in pairs(add_roles) do
        local role_info = scripts.Role.GetRoleInfo(roleid)
        if role_info then
            rsp_msg.code = ErrorCode.RoleExist
            rsp_msg.error = "角色已拥有"
            return context.S2C(context.net_id, CmdCode.PBSureCompositeRspCmd, rsp_msg, req.msg_context.stub_id)
        end
        local role_cfg = GameCfg.HumanRole[roleid]
        if not role_cfg then
            rsp_msg.code = ErrorCode.ConfigError
            rsp_msg.error = "配置不存在"
            return context.S2C(context.net_id, CmdCode.PBSureCompositeRspCmd, rsp_msg, req.msg_context.stub_id)
        end
    end
    if table.size(add_items) > 0 then
        local err_code = scripts.Bag.CheckEmptyEnough(BagDef.BagType.Cangku, add_items, 0)
        if err_code ~= ErrorCode.None then
            rsp_msg.code = err_code
            rsp_msg.error = "背包空间不足"
            return context.S2C(context.net_id, CmdCode.PBSureCompositeRspCmd, rsp_msg, req.msg_context.stub_id)
        end
    end

    local ok, stack_items, unstack_items, deal_coins = false, {}, {}, {}
    if table.size(add_items) > 0 then
        ok = ItemDefine.GetItemDataFromIdCount(add_items, {}, stack_items, unstack_items, deal_coins)
        if not ok then
            rsp_msg.code = ErrorCode.ConfigError
            rsp_msg.error = "配置错误"
            return context.S2C(context.net_id, CmdCode.PBSureCompositeRspCmd, rsp_msg, req.msg_context.stub_id)
        end
    end

    local bag_change_log = {}
    local change_roles = {}
    -- 扣除道具消耗
    if table.size(cost_items) > 0 then
        rsp_msg.code = scripts.Bag.DelItems(req.msg.bag_name, cost_items, {}, bag_change_log)
        if rsp_msg.code ~= ErrorCode.None then
            scripts.Bag.RollBackWithChange(bag_change_log)
            return context.S2C(context.net_id, CmdCode.PBSureCompositeRspCmd, rsp_msg, req.msg_context.stub_id)
        end
    end
    if table.size(cost_coins) > 0 then
        rsp_msg.code = scripts.Bag.DealCoins(cost_coins, bag_change_log)
        if rsp_msg.code ~= ErrorCode.None then
            scripts.Bag.RollBackWithChange(bag_change_log)
            return context.S2C(context.net_id, CmdCode.PBSureCompositeRspCmd, rsp_msg, req.msg_context.stub_id)
        end
    end

    if table.size(stack_items) + table.size(unstack_items) > 0 then
        rsp_msg.code = scripts.Bag.AddItems(BagDef.BagType.Cangku, stack_items, unstack_items, bag_change_log)
        if rsp_msg.code ~= ErrorCode.None then
            scripts.Bag.RollBackWithChange(bag_change_log)
            return context.S2C(context.net_id, CmdCode.PBSureCompositeRspCmd, rsp_msg, req.msg_context.stub_id)
        end
    end

    for roleid, _ in pairs(add_roles) do
        rsp_msg.code = scripts.Role.AddRole(roleid)
        if rsp_msg.code ~= ErrorCode.None then
            rsp_msg.code = ErrorCode.RoleAddFail
            rsp_msg.error = "角色添加失败"

            scripts.Bag.RollBackWithChange(bag_change_log)
            return context.S2C(context.net_id, CmdCode.PBSureCompositeRspCmd, rsp_msg, req.msg_context.stub_id)
        end

        change_roles[req.msg.roleid] = "AddRole"
    end
    
    -- 执行完成回复
    context.S2C(context.net_id, CmdCode.PBSureCompositeRspCmd, rsp_msg, req.msg_context.stub_id)

    -- 数据存储更新
    local save_bags = {}
    for bagType, _ in pairs(bag_change_log) do
        save_bags[bagType] = 1
    end
    scripts.Bag.SaveAndLog(save_bags, bag_change_log)
    
    if table.size(change_roles) > 0 then
        scripts.Role.SaveAndLog(change_roles)
    end
end

function User.PBRandomCompositeReqCmd(req)
    -- 参数验证
    if not req.msg.uid or not req.msg.composite_id then
        return context.S2C(context.net_id, CmdCode.PBRandomCompositeRspCmd, {
            code = ErrorCode.ParamInvalid,
            error = "无效请求参数",
            uid = req.msg.uid,
            composite_id = req.msg.composite_id or 0,
        }, req.msg_context.stub_id)
    end

    local rsp_msg = {
        code = ErrorCode.None,
        error = "",
        uid = context.uid,
        gift_id = req.msg.gift_id or 0,
    }
    local composite_cfg = GameCfg.RandomComposite[req.msg.composite_id]
    if not composite_cfg
        or req.msg.composite_cnt < 0
        or req.msg.composite_cnt > composite_cfg.max_num then
        rsp_msg.code = ErrorCode.ConfigError
        rsp_msg.error = "配置不存在"
        return context.S2C(context.net_id, CmdCode.PBRandomCompositeRspCmd, rsp_msg, req.msg_context.stub_id)
    end

    local cost_items = {}
    local cost_coins = {}
    ItemDefine.GetItemsFromCfg(composite_cfg.cost, req.msg.composite_cnt, true, cost_items, cost_coins)

    -- 检测道具是否足够
    rsp_msg.code = scripts.Bag.CheckItemsEnough(BagDef.BagType.Cangku, cost_items, {})
    if rsp_msg.code ~= ErrorCode.None then
        rsp_msg.error = "道具不足"
        return context.S2C(context.net_id, CmdCode.PBRandomCompositeRspCmd, rsp_msg, req.msg_context.stub_id)
    end
    rsp_msg.code = scripts.Bag.CheckCoinsEnough(cost_coins)
    if rsp_msg.code ~= ErrorCode.None then
        rsp_msg.error = "货币不足"
        return context.S2C(context.net_id, CmdCode.PBRandomCompositeRspCmd, rsp_msg, req.msg_context.stub_id)
    end

    local add_roles = {}
    local add_items = {}
    for i = 1, req.msg.composite_cnt do
        local composite_ret = User.Composite(composite_cfg, add_roles, add_items)
        if composite_ret.code ~= ErrorCode.None
            and composite_ret.code ~= composite_ret.Errcode.CompositeFail then
            rsp_msg.code = composite_ret.code
            rsp_msg.error = composite_ret.error
            return context.S2C(context.net_id, CmdCode.PBRandomCompositeRspCmd, rsp_msg, req.msg_context.stub_id)
        end
    end

    -- 检测是否可以添加
    for roleid, _ in pairs(add_roles) do
        local role_info = scripts.Role.GetRoleInfo(roleid)
        if role_info then
            rsp_msg.code = ErrorCode.RoleExist
            rsp_msg.error = "角色已拥有"
            return context.S2C(context.net_id, CmdCode.PBRandomCompositeRspCmd, rsp_msg, req.msg_context.stub_id)
        end
        local role_cfg = GameCfg.HumanRole[roleid]
        if not role_cfg then
            rsp_msg.code = ErrorCode.ConfigError
            rsp_msg.error = "配置不存在"
            return context.S2C(context.net_id, CmdCode.PBRandomCompositeRspCmd, rsp_msg, req.msg_context.stub_id)
        end
    end
    if table.size(add_items) > 0 then
        local err_code = scripts.Bag.CheckEmptyEnough(BagDef.BagType.Cangku, add_items, 0)
        if err_code ~= ErrorCode.None then
            rsp_msg.code = err_code
            rsp_msg.error = "背包空间不足"
            return context.S2C(context.net_id, CmdCode.PBRandomCompositeRspCmd, rsp_msg, req.msg_context.stub_id)
        end
    end

    local ok, stack_items, unstack_items, deal_coins = false, {}, {}, {}
    if table.size(add_items) > 0 then
        ok = ItemDefine.GetItemDataFromIdCount(add_items, {}, stack_items, unstack_items, deal_coins)
        if not ok then
            rsp_msg.code = ErrorCode.ConfigError
            rsp_msg.error = "配置错误"
            return context.S2C(context.net_id, CmdCode.PBSureCompositeRspCmd, rsp_msg, req.msg_context.stub_id)
        end
    end

    local bag_change_log = {}
    local change_roles = {}
    -- 扣除道具消耗
    if table.size(cost_items) > 0 then
        rsp_msg.code = scripts.Bag.DelItems(req.msg.bag_name, cost_items, {}, bag_change_log)
        if rsp_msg.code ~= ErrorCode.None then
            scripts.Bag.RollBackWithChange(bag_change_log)
            return context.S2C(context.net_id, CmdCode.PBRandomCompositeRspCmd, rsp_msg, req.msg_context.stub_id)
        end
    end
    if table.size(cost_coins) > 0 then
        rsp_msg.code = scripts.Bag.DealCoins(cost_coins, bag_change_log)
        if rsp_msg.code ~= ErrorCode.None then
            scripts.Bag.RollBackWithChange(bag_change_log)
            return context.S2C(context.net_id, CmdCode.PBRandomCompositeRspCmd, rsp_msg, req.msg_context.stub_id)
        end
    end

    if table.size(stack_items) + table.size(unstack_items) > 0 then
        rsp_msg.code = scripts.Bag.AddItems(BagDef.BagType.Cangku, stack_items, unstack_items, bag_change_log)
        if rsp_msg.code ~= ErrorCode.None then
            scripts.Bag.RollBackWithChange(bag_change_log)
            return context.S2C(context.net_id, CmdCode.PBRandomCompositeRspCmd, rsp_msg, req.msg_context.stub_id)
        end
    end

    for roleid, _ in pairs(add_roles) do
        rsp_msg.code = scripts.Role.AddRole(roleid)
        if rsp_msg.code ~= ErrorCode.None then
            rsp_msg.code = ErrorCode.RoleAddFail
            rsp_msg.error = "角色添加失败"

            scripts.Bag.RollBackWithChange(bag_change_log)
            return context.S2C(context.net_id, CmdCode.PBRandomCompositeRspCmd, rsp_msg, req.msg_context.stub_id)
        end

        change_roles[req.msg.roleid] = "AddRole"
    end

    -- 执行完成回复
    context.S2C(context.net_id, CmdCode.PBRandomCompositeRspCmd, rsp_msg, req.msg_context.stub_id)

    -- 数据存储更新
    local save_bags = {}
    for bagType, _ in pairs(bag_change_log) do
        save_bags[bagType] = 1
    end
    scripts.Bag.SaveAndLog(save_bags, bag_change_log)

    if table.size(change_roles) > 0 then
        scripts.Role.SaveAndLog(change_roles)
    end
end

function User.PBInlayTabooWordReqCmd(req)
    -- 参数验证
    if not req.msg.uid
        or not req.msg.inlay_type
        or not req.msg.uniqid
        or not req.msg.tabooword_id then
        return context.S2C(context.net_id, CmdCode.PBInlayTabooWordRspCmd, {
            code = ErrorCode.ParamInvalid,
            error = "无效请求参数",
            uid = req.msg.uid,
            roleid = req.msg.roleid or 0,
            ghost_uniqid = req.msg.ghost_uniqid or 0,
            inlay_type = req.msg.inlay_type or 0,
            uniqid = req.msg.uniqid or 0,
            tabooword_id = req.msg.tabooword_id or 0,
        }, req.msg_context.stub_id)
    end

    local rsp_msg = {
        code = ErrorCode.None,
        error = "",
        uid = context.uid,
        roleid = req.msg.roleid or 0,
        ghost_uniqid = req.msg.ghost_uniqid or 0,
        inlay_type = req.msg.inlay_type or 0,
        uniqid = req.msg.uniqid or 0,
        tabooword_id = req.msg.tabooword_id or 0,
    }
    local bag_change_log = nil
    local change_roles = {}
    local change_ghosts = {}
    if req.msg.inlay_type == 1 then
        -- 法器
        if req.msg.roleid and req.msg.roleid > 0 then
            rsp_msg.code, bag_change_log = scripts.Role.InlayTabooWord(req.msg.roleid, req.msg.tabooword_id,
                req.msg.inlay_type, req.msg.uniqid)
            change_roles[req.msg.roleid] = "InlayTabooWord"
        else
            rsp_msg.code, bag_change_log = scripts.Bag.InlayTabooWord(req.msg.tabooword_id, req.msg.inlay_type,
                req.msg.uniqid)
        end
    elseif req.msg.inlay_type == 2 then
        -- 八卦牌
        if req.msg.roleid and req.msg.roleid > 0 then
            rsp_msg.code, bag_change_log = scripts.Role.InlayTabooWord(req.msg.roleid, req.msg.tabooword_id,
                req.msg.inlay_type, req.msg.uniqid)
            change_roles[req.msg.roleid] = "InlayTabooWord"
        elseif req.msg.ghost_uniqid and req.msg.ghost_uniqid > 0 then
            rsp_msg.code, bag_change_log = scripts.Ghost.InlayTabooWord(req.msg.ghost_uniqid, req.msg.tabooword_id,
                req.msg.inlay_type, req.msg.uniqid)
            change_ghosts[req.msg.ghost_uniqid] = "InlayTabooWord"
        else
            rsp_msg.code, bag_change_log = scripts.Bag.InlayTabooWord(req.msg.tabooword_id, req.msg.inlay_type,
                req.msg.uniqid)
        end
    else
        rsp_msg.code = ErrorCode.InlayTypeInvalid
        rsp_msg.error = "镶嵌类型错误"
    end

    if rsp_msg.code ~= ErrorCode.None or not bag_change_log then
        return context.S2C(context.net_id, CmdCode.PBInlayTabooWordRspCmd, rsp_msg, req.msg_context.stub_id)
    end

    context.S2C(context.net_id, CmdCode.PBInlayTabooWordRspCmd, rsp_msg, req.msg_context.stub_id)

    -- 数据存储更新
    local save_bags = {}
    for bagType, _ in pairs(bag_change_log) do
        save_bags[bagType] = 1
    end
    scripts.Bag.SaveAndLog(save_bags, bag_change_log)

    if table.size(change_roles) > 0 then
        scripts.Role.SaveAndLog(change_roles)
    end
    if table.size(change_ghosts) > 0 then
        scripts.Ghost.SaveAndLog(change_ghosts)
    end
end

return User
