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
local ItemDef = require("common.def.ItemDef")
local ChatLogic = require("common.logic.ChatLogic")

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
        
        -- 加载GameCfg
        GameCfg.Load()

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
            -- data.user_attr.nick_name = data.name or data.authkey
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
    moon.warn(string.format("user_attr res = %s", json.pretty_encode(user_attr)))
    moon.warn("sync_client = ", sync_client)
    if not user_attr or type(user_attr) ~= "table" or table.size(user_attr) <= 0 then
        moon.error("user_attr is nil or not table or size <= 0")
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
        moon.warn(string.format("msg_data res = %s", json.pretty_encode(msg_data)))
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
        ProtoEnum.UserAttrType.grade_show_info,
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
        ProtoEnum.UserAttrType.grade_show_info,
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
    local grade_show_infos = scripts.Grade.GetGradeShowInfos()

    return { user_attr = details_data, role_data = role_data, ghost_data = ghost_data, grade_show_infos =
    grade_show_infos }
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

function User.InitCheckData()
    User.CheckAccountLevel()
    User.NotifyGameSettle()
    User.NotifyGameReturnItems()
end

function User.Init()
    --local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
    --GameCfg.Load()
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

function User.ExitPlayDs()
    if not context.play_ds_node
        or not context.play_ds_node.ds_node or context.play_ds_node.ds_node == 0
        or not context.play_ds_node.ds_addr or context.play_ds_node.ds_addr == 0 then
        return
    end

    local mine_node = math.tointeger(moon.env("NODE"))
    if mine_node == context.play_ds_node.ds_node then
        moon.send("lua", context.play_ds_node.ds_addr, "DsNode.ExitPlayDs", context.uid)
    else
        clusterd.send(context.play_ds_node.ds_node, context.play_ds_node.ds_addr, "DsNode.ExitPlayDs", context.uid)
    end

    context.play_ds_node = nil
end

function User.InPlay(msg)
    moon.warn("User.InPlay roomid = ", msg.roomid)
    if not context.roomid or context.roomid ~= msg.roomid then
        moon.error("User.InPlay roomid not match, roomid = ", msg.roomid)
        return
    end
    if msg.ds_node and msg.ds_node ~= 0
        and msg.ds_addr and msg.ds_addr ~= 0 then
        context.play_ds_node = {
            ds_node = msg.ds_node,
            ds_addr = msg.ds_addr,
        }
    end
    -- 同步游戏中状态到redis
    local update_user_attr = {}
    update_user_attr[ProtoEnum.UserAttrType.is_online] = UserAttrDef.ONLINE_STATE.IN_GAME
    User.SetUserAttr(update_user_attr, true)
end

function User.OutPlay(out_data)
    moon.warn("User.OutPlay roomid = ", out_data.roomid)
    if not context.roomid or context.roomid ~= out_data.roomid then
        moon.error("User.OutPlay roomid not match, roomid = ", out_data.roomid)
        return
    end
    -- 退出游戏中的副本ds(如果有的话)
    User.ExitPlayDs()

    local query_user_attr = {}
    table.insert(query_user_attr, ProtoEnum.UserAttrType.is_online)
    local query_res = User.QueryUserAttr(query_user_attr)

    if out_data.need_exit_room then
        clusterd.send(3999, "roommgr", "Roommgr.ExitRoom",
            { uid = context.uid, roomid = context.roomid, is_force = true })
        context.roomid = nil

        -- 同步退出房间状态
        local update_user_attr = {}
        update_user_attr[ProtoEnum.UserAttrType.is_online] = UserAttrDef.ONLINE_STATE.ONLINE
        User.SetUserAttr(update_user_attr, true)

        -- 退出队伍频道
        local chat_ret = ChatLogic.LeaveRoomChannel(out_data.roomid, context.uid)
        if chat_ret.code ~= ErrorCode.None then
            moon.error(string.format("LeaveRoomChannel uid:%d, roomid:%d, code:%d, error:%s", context.uid,
                out_data.roomid,
                chat_ret.code, chat_ret.error))
        end
    else
        if query_res.user_attr[ProtoEnum.UserAttrType.is_online] == UserAttrDef.ONLINE_STATE.IN_GAME then
            -- 同步离开游戏中状态到redis
            local update_user_attr = {}
            update_user_attr[ProtoEnum.UserAttrType.is_online] = UserAttrDef.ONLINE_STATE.IN_ROOM
            User.SetUserAttr(update_user_attr, true)
        end
    end
    
    -- if out_data.need_settle and out_data.need_settle == 1 and out_data.player_settle then
    --     -- scripts.Room.GameSettle(out_data.player_settle)
    -- end
end

function User.NotifyGameSettle()
    while true do
        local settle_info = Database.BattleListPopLeft(context.addr_db_redis, Database.GetBattleSettleKey(), context.uid)
        if settle_info then
            scripts.Room.GameSettle(settle_info)
        else
            break
        end
    end
end

function User.NotifyGameReturnItems()
    -- while true do
    --     local return_info = Database.BattleListPopLeft(context.addr_db_redis, Database.GetBattleReturnKey(), context.uid)
    --     if return_info then
    --         -- scripts.Room.GameReturnItems(return_info)
    --     else
    --         break
    --     end
    -- end
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
    -- 退出游戏中的副本ds(如果有的话)
    User.ExitPlayDs()

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

-- function User.C2SUserData()
--     context.S2C(CmdCode.S2CUserData, scripts.UserModel.Get())
-- end

function User.CheckAccountLevel()
    local min_level = 1
    local max_level = table.size(GameCfg.ExperienceLevel)

    local query_user_attr = {}
    table.insert(query_user_attr, ProtoEnum.UserAttrType.account_exp)
    local query_res = User.QueryUserAttr(query_user_attr)
    local now_exp = 0
    if query_res.user_attr[ProtoEnum.UserAttrType.account_exp] then
        now_exp = query_res.user_attr[ProtoEnum.UserAttrType.account_exp]
    end

    local now_level = min_level
    for i = min_level, max_level, 1 do
        local conf_lv = GameCfg.ExperienceLevel[i]
        if not conf_lv then
            break
        end
        if now_exp < conf_lv.level_exp then
            break
        else
            now_level = i
        end
    end

    local update_user_attr = {}
    update_user_attr[ProtoEnum.UserAttrType.account_level] = now_level
    User.SetUserAttr(update_user_attr, false)
end

function User.AddAccountExp(add_exp)
    if add_exp == 0 then
        return
    end
    local min_level = 1
    local max_level = table.size(GameCfg.ExperienceLevel)

    local query_user_attr = {}
    table.insert(query_user_attr, ProtoEnum.UserAttrType.account_level)
    table.insert(query_user_attr, ProtoEnum.UserAttrType.account_exp)
    local query_res = User.QueryUserAttr(query_user_attr)
    local now_level = min_level
    if query_res.user_attr[ProtoEnum.UserAttrType.account_level] then
        now_level = query_res.user_attr[ProtoEnum.UserAttrType.account_level]
    end
    local now_exp = 0
    if query_res.user_attr[ProtoEnum.UserAttrType.account_exp] then
        now_exp = query_res.user_attr[ProtoEnum.UserAttrType.account_exp]
    end
    now_exp = now_exp + add_exp

    -- 经验转换等级
    if add_exp < 0 then
        for i = now_level, min_level, -1 do
            local conf_lv = GameCfg.ExperienceLevel[i]
            if not conf_lv then
                break
            end
            if now_exp >= conf_lv.level_exp then
                now_level = i
                break
            end
        end
    else
        for i = now_level, max_level, 1 do
            local conf_lv = GameCfg.ExperienceLevel[i]
            if not conf_lv then
                break
            end
            if now_exp < conf_lv.level_exp then
                break
            else
                now_level = i
            end
        end
    end

    local update_user_attr = {}
    update_user_attr[ProtoEnum.UserAttrType.account_level] = now_level
    update_user_attr[ProtoEnum.UserAttrType.account_exp] = now_exp
    User.SetUserAttr(update_user_attr, true)
end

function User.GMAddAccountExp(add_exp)
    -- GM增加账户经验
    User.AddAccountExp(add_exp)

    return true
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
    moon.warn(string.format("PBClientGetAllUserAttrReqCmd total_attr = %s", json.pretty_encode(total_attr)))
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
        local old_item_data = table.copy(item_data, true)
        local err_code, change_log = scripts.Bag.Light(item_data)
        if err_code ~= ErrorCode.None or not change_log then
            return ErrorCode.LightMagicItemFail
        end

        -- 存储背包数据
        -- local save_bags = {}
        -- for bagType, _ in pairs(change_log) do
        --     save_bags[bagType] = 1
        -- end
        -- if table.size(save_bags) > 0 then
        --     -- 只存储了背包变更数据
        --     scripts.Bag.SaveAndLog(save_bags, change_log)
        -- end
        if table.size(change_log) > 0 then
            -- 只存储了背包变更数据
            scripts.Bag.SaveAndLog(change_log, ItemDef.ChangeReason.RoleEquipLight, msg.roleid)
        end
        -- 存储角色数据
        if scripts.Role.ModMagicItem(msg.roleid, item_data) == ErrorCode.None then
            if old_item_data and old_item_data.common_info then
                -- 单独插入一条变更日志
                local write_log_datas = {}
                local new_write_log = ItemDef.newPBItemLog()
                new_write_log.uid = context.uid
                new_write_log.config_id = old_item_data.common_info.config_id
                new_write_log.old_num = 1
                new_write_log.new_num = 1
                new_write_log.mod_uniqid = msg.uniqid
                table.insert(new_write_log.old_item_data, old_item_data)
                table.insert(new_write_log.new_item_data, item_data)
                new_write_log.relation_roleid = msg.roleid
                new_write_log.change_type = ItemDef.LogType.ChangeInfo
                new_write_log.change_reason = ItemDef.ChangeReason.RoleEquipLight
                new_write_log.log_ts = moon.time()
                table.insert(write_log_datas, new_write_log)
                scripts.Item.SendLog(write_log_datas)
            end

            local change_roles = {}
            change_roles[msg.roleid] = "LightMagicItem"
            scripts.Role.SaveAndLog(change_roles)
        else
            moon.error("LightRoleEquipment LightMagicItem Fail:", msg.roleid)
        end

        return ErrorCode.None, item_data
    elseif role_info.space_ring
        and role_info.space_ring.common_info
        and role_info.space_ring.common_info.uniqid == msg.uniqid then
        local item_data = role_info.space_ring
        local old_item_data = table.copy(item_data, true)
        local err_code, change_log = scripts.Bag.Light(item_data)
        if err_code ~= ErrorCode.None or not change_log then
            return ErrorCode.LightSpaceRingFail
        end
        if table.size(change_log) > 0 then
            -- 只存储了背包变更数据
            scripts.Bag.SaveAndLog(change_log, ItemDef.ChangeReason.RoleEquipLight, msg.roleid)
        end
        -- 存储角色数据
        if scripts.Role.ModSpaceRing(msg.roleid, item_data) == ErrorCode.None then
            if old_item_data and old_item_data.common_info then
                -- 单独插入一条变更日志
                local write_log_datas = {}
                local new_write_log = ItemDef.newPBItemLog()
                new_write_log.uid = context.uid
                new_write_log.config_id = old_item_data.common_info.config_id
                new_write_log.old_num = 1
                new_write_log.new_num = 1
                new_write_log.mod_uniqid = msg.uniqid
                table.insert(new_write_log.old_item_data, old_item_data)
                table.insert(new_write_log.new_item_data, item_data)
                new_write_log.relation_roleid = msg.roleid
                new_write_log.change_type = ItemDef.LogType.ChangeInfo
                new_write_log.change_reason = ItemDef.ChangeReason.RoleEquipLight
                new_write_log.log_ts = moon.time()
                table.insert(write_log_datas, new_write_log)
                scripts.Item.SendLog(write_log_datas)
            end

            local change_roles = {}
            change_roles[msg.roleid] = "LightSpaceRing"
            scripts.Role.SaveAndLog(change_roles)
        else
            moon.error("LightRoleEquipment LightSpaceRing Fail:", msg.roleid)
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
        local old_item_data = table.copy(item_data, true)
        local err_code, change_log = scripts.Bag.Light(item_data)
        if err_code ~= ErrorCode.None or not change_log then
            return ErrorCode.LightDigramsCardFail
        end

        -- 存储背包数据
        -- local save_bags = {}
        -- for bagType, _ in pairs(change_log) do
        --     save_bags[bagType] = 1
        -- end
        -- if table.size(save_bags) > 0 then
        --     -- 只存储了背包变更数据
        --     scripts.Bag.SaveAndLog(save_bags, change_log)
        -- end
        if table.size(change_log) > 0 then
            -- 只存储了背包变更数据
            scripts.Bag.SaveAndLog(change_log, ItemDef.ChangeReason.RoleEquipLight)
        end
        -- 存储角色数据
        if scripts.Role.ModDiagramsCard(msg.roleid, item_data, slot) == ErrorCode.None then
            if old_item_data and old_item_data.common_info then
                -- 单独插入一条变更日志
                local write_log_datas = {}
                local new_write_log = ItemDef.newPBItemLog()
                new_write_log.uid = context.uid
                new_write_log.config_id = old_item_data.common_info.config_id
                new_write_log.old_num = 1
                new_write_log.new_num = 1
                new_write_log.mod_uniqid = msg.uniqid
                table.insert(new_write_log.old_item_data, old_item_data)
                table.insert(new_write_log.new_item_data, item_data)
                new_write_log.relation_roleid = msg.roleid
                new_write_log.change_type = ItemDef.LogType.ChangeInfo
                new_write_log.change_reason = ItemDef.ChangeReason.RoleEquipLight
                new_write_log.log_ts = moon.time()
                table.insert(write_log_datas, new_write_log)
                scripts.Item.SendLog(write_log_datas)
            end

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
        local old_item_data = table.copy(item_data, true)
        local err_code, change_log = scripts.Bag.Light(item_data)
        if err_code ~= ErrorCode.None or not change_log then
            return ErrorCode.LightDigramsCardFail
        end

        -- 存储背包数据
        -- local save_bags = {}
        -- for bagType, _ in pairs(change_log) do
        --     save_bags[bagType] = 1
        -- end
        -- if table.size(save_bags) > 0 then
        --     -- 只存储了背包变更数据
        --     scripts.Bag.SaveAndLog(save_bags, change_log)
        -- end
        if table.size(change_log) > 0 then
            -- 只存储了背包变更数据
            scripts.Bag.SaveAndLog(change_log, ItemDef.ChangeReason.GhostEquipLight)
        end
        -- 存储角色数据
        scripts.Ghost.ModDiagramsCard(msg.ghostid, item_data, slot)
        if old_item_data and old_item_data.common_info then
            -- 单独插入一条变更日志
            local write_log_datas = {}
            local new_write_log = ItemDef.newPBItemLog()
            new_write_log.uid = context.uid
            new_write_log.config_id = old_item_data.common_info.config_id
            new_write_log.old_num = 1
            new_write_log.new_num = 1
            new_write_log.mod_uniqid = msg.uniqid
            table.insert(new_write_log.old_item_data, old_item_data)
            table.insert(new_write_log.new_item_data, item_data)
            new_write_log.relation_ghostid = msg.ghostid
            new_write_log.relation_ghost_uniqid = msg.ghostid
            new_write_log.change_type = ItemDef.LogType.ChangeInfo
            new_write_log.change_reason = ItemDef.ChangeReason.GhostEquipLight
            new_write_log.log_ts = moon.time()
            table.insert(write_log_datas, new_write_log)
            scripts.Item.SendLog(write_log_datas)
        end
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
            for pos, old_itemdata in pairs(logs) do
                if table.size(old_itemdata) <= 0 then
                    light_bagid = bagType
                    light_pos = pos
                end
            end
        end

        -- 生成新唯一道具，进行保存
        -- scripts.Bag.SaveAndLog(save_bags, change_log)
        scripts.Bag.SaveAndLog(change_log, ItemDef.ChangeReason.BagLight)
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
    -- scripts.Bag.AddLog(change_log[light_bagid], light_pos, ItemDef.LogType.ChangeInfo, old_itemdata,common_info.config_id,old_itemdata.common_info.uniqid, old_itemdata.common_info.item_count, old_itemdata)
    scripts.Bag.AddLog(change_log[light_bagid], light_pos, old_itemdata)

    -- local save_bags = {}
    -- for bagType, _ in pairs(change_log) do
    --     save_bags[bagType] = 1
    -- end
    -- if table.size(save_bags) > 0 then
    --     scripts.Bag.SaveAndLog(save_bags, change_log)
    -- end
    if table.size(change_log) > 0 then
        scripts.Bag.SaveAndLog(change_log, ItemDef.ChangeReason.BagLight)
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
        }, req.msg_context.stub_id)
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
        }, req.msg_context.stub_id)
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
        -- local save_bags = {}
        -- for bagType, _ in pairs(change_log) do
        --     save_bags[bagType] = 1
        -- end
        -- --local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
        -- scripts.Bag.SaveAndLog(save_bags, change_log)
        scripts.Bag.SaveAndLog(change_log, ItemDef.ChangeReason.DsAddItems)
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
            code = err_code,
            error = "升级失败",
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
        -- local save_bags = {}
        -- for bagType, _ in pairs(change_log) do
        --     save_bags[bagType] = 1
        -- end
        -- if table.size(save_bags) > 0 then
        --     scripts.Bag.SaveAndLog(save_bags, change_log)
        -- end
        if table.size(change_log) > 0 then
            if RoleDef.RoleDefine.RoleID.Start <= req.msg.config_id
                and req.msg.config_id <= RoleDef.RoleDefine.RoleID.End then
                scripts.Bag.SaveAndLog(change_log, ItemDef.ChangeReason.ImageUpLv, req.msg.config_id)
            elseif GhostDef.GhostDefine.GhostID.Start <= req.msg.config_id
                and req.msg.config_id <= GhostDef.GhostDefine.GhostID.End then
                scripts.Bag.SaveAndLog(change_log, ItemDef.ChangeReason.ImageUpLv, 0, req.msg.config_id)
            else
                scripts.Bag.SaveAndLog(change_log, ItemDef.ChangeReason.ImageUpLv, 0, 0, 0, req.msg.config_id)
            end
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
    if not req.msg.target_id or not req.msg.cost_items or table.size(req.msg.cost_items) <= 0 then
        return context.S2C(context.net_id, CmdCode.PBUseItemUpLvRspCmd, {
            code = ErrorCode.ParamInvalid,
            error = "无效请求参数",
            uid = context.uid,
            target_id = req.msg.target_id or 0,
            cost_items = req.msg.cost_items or {},
        }, req.msg_context.stub_id)
    end

    local cost_items, item_exps = {}, {}
    local up_exp_id, up_exp_total = 0, 0
    for _, cost_item in pairs(req.msg.cost_items) do
        local item_cfg = GameCfg.Item[cost_item.config_id]
        if not item_cfg or not item_cfg.use_award or table.size(item_cfg.use_award) ~= 1 then
            return context.S2C(context.net_id, CmdCode.PBUseItemUpLvRspCmd, {
                code = ErrorCode.ConfigError,
                error = "道具配置错误",
                uid = context.uid,
                target_id = req.msg.target_id,
                cost_items = {},
            }, req.msg_context.stub_id)
        end

        for exp_id, exp_cnt in pairs(item_cfg.use_award) do
            if up_exp_id ~= 0 and up_exp_id ~= exp_id then
                return context.S2C(context.net_id, CmdCode.PBUseItemUpLvRspCmd, {
                    code = ErrorCode.ConfigError,
                    error = "道具配置错误",
                    uid = context.uid,
                    target_id = req.msg.target_id,
                    cost_items = {},
                }, req.msg_context.stub_id)
            end
            up_exp_id = exp_id

            if not item_exps[cost_item.config_id] then
                item_exps[cost_item.config_id] = {
                    exp_cnt = exp_cnt,
                    num = 0,
                }
            end
            -- item_exps[cost_item.config_id].num = item_exps[cost_item.config_id].num + cost_item.item_count
            up_exp_total = up_exp_total + exp_cnt * cost_item.item_count
        end

        if not cost_items[cost_item.config_id] then
            cost_items[cost_item.config_id] = {
                id = cost_item.config_id,
                count = 0,
                pos = 0,
            }
        end
        cost_items[cost_item.config_id].count = cost_items[cost_item.config_id].count - cost_item.item_count
    end
    for cost_id, cost_item in pairs(cost_items) do
        if cost_item.count < 0 and item_exps[cost_id] then
            item_exps[cost_id].num = -cost_item.count
        end
    end

    -- 检测道具是否足够
    local bag_cost_code = scripts.Bag.CheckItemsEnough(BagDef.BagType.Cangku, cost_items, {})
    if bag_cost_code ~= ErrorCode.None then
        return context.S2C(context.net_id, CmdCode.PBUseItemUpLvRspCmd, {
            code = bag_cost_code,
            error = "道具不足",
            uid = context.uid,
            target_id = req.msg.target_id,
            cost_items = {},
        }, req.msg_context.stub_id)
    end

    local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
    -- 检查经验增加
    local err_code, up_exp_cnt, real_cost_items = ErrorCode.None, 0, {}
    if RoleDef.RoleDefine.RoleID.Start <= req.msg.target_id
        and req.msg.target_id <= RoleDef.RoleDefine.RoleID.End then
        err_code, up_exp_cnt, real_cost_items = scripts.Role.CheckUseItemUpLv(req.msg.target_id, up_exp_id, up_exp_total, item_exps)
    elseif GhostDef.GhostDefine.GhostID.Start <= req.msg.target_id
        and req.msg.target_id <= GhostDef.GhostDefine.GhostID.End then
        err_code, up_exp_cnt, real_cost_items = scripts.Ghost.CheckUseItemUpLv(req.msg.target_id, up_exp_id, up_exp_cnt)
    else
        -- 图鉴升级
        err_code, up_exp_cnt, real_cost_items = scripts.ItemImage.CheckUseItemUpLv(req.msg.target_id, up_exp_id,
        up_exp_cnt)
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
    if table.size(real_cost_items) > 0 then
        err_code_del = scripts.Bag.DelItems(BagDef.BagType.Cangku, real_cost_items, {}, bag_change_log)
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
        -- local save_bags = {}
        -- for bagType, _ in pairs(bag_change_log) do
        --     save_bags[bagType] = 1
        -- end
        -- if table.size(save_bags) > 0 then
        --     scripts.Bag.SaveAndLog(save_bags, bag_change_log)
        -- end
        if table.size(bag_change_log) > 0 then
            if RoleDef.RoleDefine.RoleID.Start <= req.msg.target_id
                and req.msg.target_id <= RoleDef.RoleDefine.RoleID.End then
                scripts.Bag.SaveAndLog(bag_change_log, ItemDef.ChangeReason.UseItemUpLv, req.msg.target_id)
            elseif GhostDef.GhostDefine.GhostID.Start <= req.msg.target_id
                and req.msg.target_id <= GhostDef.GhostDefine.GhostID.End then
                scripts.Bag.SaveAndLog(bag_change_log, ItemDef.ChangeReason.UseItemUpLv, 0, req.msg.target_id)
            else
                scripts.Bag.SaveAndLog(bag_change_log, ItemDef.ChangeReason.UseItemUpLv, 0, 0, 0, req.msg.target_id)
            end
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
    if err_code ~= ErrorCode.None and err_code ~= ErrorCode.UpStarProbFail then
        return context.S2C(context.net_id, CmdCode.PBClientItemUpStarRspCmd, {
            code = err_code,
            error = "升星失败",
            uid = context.uid,
            config_id = req.msg.config_id,
        }, req.msg_context.stub_id)
    end

    context.S2C(context.net_id, CmdCode.PBClientItemUpStarRspCmd, {
        code = err_code,
        error = "",
        uid = context.uid,
        config_id = req.msg.config_id,
    }, req.msg_context.stub_id)

    -- 存储背包变更
    if change_log then
        -- local save_bags = {}
        -- for bagType, _ in pairs(change_log) do
        --     save_bags[bagType] = 1
        -- end
        -- if table.size(save_bags) > 0 then
        --     scripts.Bag.SaveAndLog(save_bags, change_log)
        -- end
        if table.size(change_log) > 0 then
            if RoleDef.RoleDefine.RoleID.Start <= req.msg.config_id
                and req.msg.config_id <= RoleDef.RoleDefine.RoleID.End then
                scripts.Bag.SaveAndLog(change_log, ItemDef.ChangeReason.ImageUpStar, req.msg.config_id)
            elseif GhostDef.GhostDefine.GhostID.Start <= req.msg.config_id
                and req.msg.config_id <= GhostDef.GhostDefine.GhostID.End then
                scripts.Bag.SaveAndLog(change_log, ItemDef.ChangeReason.ImageUpStar, 0, req.msg.config_id)
            else
                scripts.Bag.SaveAndLog(change_log, ItemDef.ChangeReason.ImageUpStar, 0, 0, 0, req.msg.config_id)
            end
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
            grade_show_infos = res.grade_show_infos,
        }, req.msg_context.stub_id)
    else
        return context.S2C(context.net_id, CmdCode.PBGetOtherDetailRspCmd, {
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

        -- 消耗配置
        local common_cfg = CommonCfgDef.getConf("MaintenanceCost")
        if not common_cfg then
            return ErrorCode.ConfigError
        end
        local cost_items = {}
        local cost_coins = {}
        local change_logs = {}
        local add_durability = 0

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

            local add_durability = math.min(magic_cfg.durability - item_data.special_info.magic_item.cur_durability,
                item_data.special_info.magic_item.strong_value)
            ItemDefine.GetItemsFromCfg(common_cfg.items, add_durability, true, cost_items, cost_coins)
        elseif smallType == ItemDefine.EItemSmallType.HumanDiagrams
            or smallType == ItemDefine.EItemSmallType.GhostDiagrams then
            if item_data.special_info.diagrams_item.strong_value <= 0 then
                return ErrorCode.StrongNotEnough
            end
            local uniq_cfg = GameCfg.UniqueItem[item_data.common_info.config_id]
            if not uniq_cfg then
                return ErrorCode.ConfigError
            end
            if item_data.special_info.diagrams_item.cur_durability >= uniq_cfg.durability then
                return ErrorCode.DurabilityMax
            end

            local add_durability = math.min(uniq_cfg.durability - item_data.special_info.diagrams_item.cur_durability,
                item_data.special_info.diagrams_item.strong_value)
            ItemDefine.GetItemsFromCfg(common_cfg.items, add_durability, true, cost_items, cost_coins)
        elseif smallType == ItemDefine.EItemSmallType.SpaceRing then
            if item_data.special_info.space_ring.strong_value <= 0 then
                return ErrorCode.StrongNotEnough
            end
            local uniq_cfg = GameCfg.UniqueItem[item_data.common_info.config_id]
            if not uniq_cfg then
                return ErrorCode.ConfigError
            end
            if item_data.special_info.space_ring.cur_durability >= uniq_cfg.durability then
                return ErrorCode.DurabilityMax
            end

            add_durability = math.min(uniq_cfg.durability - item_data.special_info.space_ring.cur_durability,
                item_data.special_info.space_ring.strong_value)
            ItemDefine.GetItemsFromCfg(common_cfg.items, add_durability, true, cost_items, cost_coins)
        else
            return ErrorCode.ItemTypeMismatch
        end
        
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

        if smallType == ItemDefine.EItemSmallType.MagicItem then
            -- 增加法器耐久度
            item_data.special_info.magic_item.cur_durability = item_data.special_info.magic_item.cur_durability
                + add_durability
            item_data.special_info.magic_item.strong_value = item_data.special_info.magic_item.strong_value
                - add_durability

        elseif smallType == ItemDefine.EItemSmallType.HumanDiagrams
            or smallType == ItemDefine.EItemSmallType.GhostDiagrams then
            -- 增加八卦牌耐久度
            item_data.special_info.diagrams_item.cur_durability = item_data.special_info.diagrams_item.cur_durability
                + add_durability
            item_data.special_info.diagrams_item.strong_value = item_data.special_info.diagrams_item.strong_value
                - add_durability

        elseif smallType == ItemDefine.EItemSmallType.SpaceRing then
            -- 增加戒指耐久度
            item_data.special_info.space_ring.cur_durability = item_data.special_info.space_ring.cur_durability
                + add_durability
            item_data.special_info.space_ring.strong_value = item_data.special_info.space_ring.strong_value
                - add_durability

        end

        -- 存储数据
        if not change_logs[BagDef.BagType.Cangku] then
            change_logs[BagDef.BagType.Cangku] = {}
        end
        scripts.Bag.AddLog(change_logs[BagDef.BagType.Cangku], req.msg.pos, old_item_data)
        if table.size(change_logs) > 0 then
            scripts.Bag.SaveAndLog(change_logs, ItemDef.ChangeReason.ItemRepair)
        end

        return ErrorCode.None, item_data
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

-- function User.PBUseSkinGiftReqCmd(req)
--     -- 参数验证
--     if not req.msg.uid or not req.msg.gift_id then
--         return context.S2C(context.net_id, CmdCode.PBUseSkinGiftRspCmd, {
--             code = ErrorCode.ParamInvalid,
--             error = "无效请求参数",
--             uid = context.uid,
--             gift_id = req.msg.gift_id or 0,
--         }, req.msg_context.stub_id)
--     end

--     -- 读取皮肤礼包表
-- end

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
            and composite_ret.code ~= ErrorCode.CompositeFail then
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
        rsp_msg.code = scripts.Bag.DelItems(BagDef.BagType.Cangku, cost_items, {}, bag_change_log)
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
    -- local save_bags = {}
    -- for bagType, _ in pairs(bag_change_log) do
    --     save_bags[bagType] = 1
    -- end
    -- scripts.Bag.SaveAndLog(save_bags, bag_change_log)
    scripts.Bag.SaveAndLog(bag_change_log, ItemDef.ChangeReason.ItemComposite)
    
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

    -- local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()

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
        rsp_msg.code = scripts.Bag.DelItems(BagDef.BagType.Cangku, cost_items, {}, bag_change_log)
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
    -- local save_bags = {}
    -- for bagType, _ in pairs(bag_change_log) do
    --     save_bags[bagType] = 1
    -- end
    -- scripts.Bag.SaveAndLog(save_bags, bag_change_log)
    scripts.Bag.SaveAndLog(bag_change_log, ItemDef.ChangeReason.ItemComposite)

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
    local change_ghost_config_id = nil
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
            rsp_msg.code, bag_change_log, change_ghost_config_id = scripts.Ghost.InlayTabooWord(req.msg.ghost_uniqid,
            req.msg.tabooword_id, req.msg.inlay_type, req.msg.uniqid)
            change_ghosts[req.msg.ghost_uniqid] = "InlayTabooWord"
        else
            rsp_msg.code, bag_change_log = scripts.Bag.InlayTabooWord(req.msg.tabooword_id, req.msg.inlay_type,
                req.msg.uniqid)
        end
    elseif req.msg.inlay_type == 3 then
        -- 戒指
        if req.msg.roleid and req.msg.roleid > 0 then
            rsp_msg.code, bag_change_log = scripts.Role.InlayTabooWord(req.msg.roleid, req.msg.tabooword_id,
                req.msg.inlay_type, req.msg.uniqid)
            change_roles[req.msg.roleid] = "InlayTabooWord"
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
    -- local save_bags = {}
    -- for bagType, _ in pairs(bag_change_log) do
    --     save_bags[bagType] = 1
    -- end
    -- scripts.Bag.SaveAndLog(save_bags, bag_change_log)
    if table.size(change_roles) > 0 then
        scripts.Bag.SaveAndLog(bag_change_log, ItemDef.ChangeReason.InlayItem, req.msg.roleid)
    elseif table.size(change_ghosts) > 0 and change_ghost_config_id then
        scripts.Bag.SaveAndLog(bag_change_log, ItemDef.ChangeReason.InlayItem, 0, change_ghost_config_id,
            req.msg.ghost_uniqid)
    else
        scripts.Bag.SaveAndLog(bag_change_log, ItemDef.ChangeReason.InlayItem)
    end

    if table.size(change_roles) > 0 then
        scripts.Role.SaveAndLog(change_roles)
    elseif table.size(change_ghosts) > 0 then
        scripts.Ghost.SaveAndLog(change_ghosts)
    end
end

function User.PBModNickNameReqCmd(req)
    -- 参数验证
    if not req.msg.uid
        or not req.msg.nick_name
        or req.msg.nick_name == "" then
        return context.S2C(context.net_id, CmdCode.PBModNickNameRspCmd, {
            code = ErrorCode.ParamInvalid,
            error = "无效请求参数",
            uid = req.msg.uid,
            nick_name = req.msg.nick_name or "",
        }, req.msg_context.stub_id)
    end

    local nick_info = Database.RedisGetNick(context.addr_db_redis, req.msg.nick_name)
    moon.warn(string.format("nick_info res = %s", json.pretty_encode(nick_info)))
    if nick_info and table.size(nick_info) > 0 then
        return context.S2C(context.net_id, CmdCode.PBModNickNameRspCmd, {
            code = ErrorCode.NicknameAlreadyExist,
            error = "昵称已存在",
            uid = req.msg.uid,
            nick_name = req.msg.nick_name or "",
        }, req.msg_context.stub_id)
    end

    local nickname_fields = {
        ProtoEnum.UserAttrType.nick_name,
    }
    local user_attr = User.GetOnlineUserAttr(nickname_fields)
    moon.warn(string.format("user_attr res = %s", json.pretty_encode(user_attr)))
    if not user_attr[ProtoEnum.UserAttrType.nick_name]
        or user_attr[ProtoEnum.UserAttrType.nick_name] == "" then
        -- 修复调用SetUserAttr的方式，创建一个包含属性和值的表
        local update_user_attr = {}
        update_user_attr[ProtoEnum.UserAttrType.nick_name] = req.msg.nick_name
        User.SetUserAttr(update_user_attr, true)
        Database.RedisSetNick(context.addr_db_redis, req.msg.nick_name, context.uid)
    else
        local old_nick_name = user_attr[ProtoEnum.UserAttrType.nick_name]
        if old_nick_name == req.msg.nick_name then
            return context.S2C(context.net_id, CmdCode.PBModNickNameRspCmd, {
                code = ErrorCode.NicknameAlreadyExist,
                error = "昵称与当前昵称相同",
                uid = req.msg.uid,
                nick_name = user_attr[ProtoEnum.UserAttrType.nick_name],
            }, req.msg_context.stub_id)
        end

        local init_cfg = GameCfg.Init[1]
        if not init_cfg then
            return context.S2C(context.net_id, CmdCode.PBModNickNameRspCmd, {
                code = ErrorCode.ConfigError,
                error = "初始化配置错误",
                uid = req.msg.uid,
                nick_name = old_nick_name,
            }, req.msg_context.stub_id)
        end

        local cost_items = {}
        cost_items[init_cfg.named_item] = {
            id = init_cfg.named_item,
            count = -1,
            pos = 0,
        }
        -- 检测道具是否足够
        local bag_cost_code = scripts.Bag.CheckItemsEnough(BagDef.BagType.Cangku, cost_items, {})
        if bag_cost_code ~= ErrorCode.None then
            return context.S2C(context.net_id, CmdCode.PBModNickNameRspCmd, {
                code = bag_cost_code,
                error = "道具不足",
                uid = req.msg.uid,
                nick_name = old_nick_name,
            }, req.msg_context.stub_id)
        end

        if table.size(cost_items) > 0 then
            local bag_change_log = {}
            local errcode = scripts.Bag.DelItems(BagDef.BagType.Cangku, cost_items, {}, bag_change_log)
            if errcode ~= ErrorCode.None then
                scripts.Bag.RollBackWithChange(bag_change_log)
                return context.S2C(context.net_id, CmdCode.PBModNickNameRspCmd, {
                    code = errcode,
                    error = "道具不足",
                    uid = req.msg.uid,
                    nick_name = old_nick_name,
                }, req.msg_context.stub_id)
            end
            scripts.Bag.SaveAndLog(bag_change_log, ItemDef.ChangeReason.ModNickName)
        end

        Database.RedisDelNick(context.addr_db_redis, old_nick_name)
        local update_user_attr = {}
        update_user_attr[ProtoEnum.UserAttrType.nick_name] = req.msg.nick_name
        User.SetUserAttr(update_user_attr, true)
        Database.RedisSetNick(context.addr_db_redis, req.msg.nick_name, context.uid)
    end

    return context.S2C(context.net_id, CmdCode.PBModNickNameRspCmd, {
        code = ErrorCode.None,
        error = "",
        uid = req.msg.uid,
        nick_name = req.msg.nick_name,
    }, req.msg_context.stub_id)
end

function User.OpenGift(item_cfg, msg_data, bag_change_log)
    local err_code = ErrorCode.ItemTypeMismatch
    local item_list = {}
    if item_cfg.use_type == 4 then
        -- 普通礼包
        if not item_cfg.use_award or table.size(item_cfg.use_award) == 0 then
            err_code = ErrorCode.ConfigError
            return err_code
        end
        for item_id, item_cnt in pairs(item_cfg.use_award) do
            if not item_list[item_id] then
                item_list[item_id] = {
                    id = item_id,
                    count = 0,
                    pos = 0,
                }
            end
            item_list[item_id].count = item_list[item_id].count + (item_cnt * msg_data.use_item_cnt)
        end
    elseif item_cfg.use_type == 5 then
        -- 自选礼包
        if not item_cfg.use_award or table.size(item_cfg.use_award) == 0 then
            err_code = ErrorCode.ConfigError
            return err_code
        end
        if not item_cfg.award_count
            or item_cfg.award_count <= 0
            or item_cfg.award_count >= table.size(item_cfg.use_award) then
            err_code = ErrorCode.ConfigError
            return err_code
        end
        if not msg_data.choose_item_ids or table.size(msg_data.choose_item_ids) ~= item_cfg.award_count then
            err_code = ErrorCode.ParamInvalid
            return err_code
        end
        for item_id, _ in pairs(msg_data.choose_item_ids) do
            if not item_cfg.use_award[item_id] then
                err_code = ErrorCode.ParamInvalid
                return err_code
            end
            if not item_list[item_id] then
                item_list[item_id] = {
                    id = item_id,
                    count = 0,
                    pos = 0,
                }
            end
            item_list[item_id].count = item_list[item_id].count + (item_cfg.use_award[item_id] * msg_data.use_item_cnt)
        end
    elseif item_cfg.use_type == 6 then
        -- 随机礼包
        if not item_cfg.use_award or table.size(item_cfg.use_award) == 0 then
            err_code = ErrorCode.ConfigError
            return err_code
        end
        if not item_cfg.award_count
            or item_cfg.award_count <= 0
            or item_cfg.award_count >= table.size(item_cfg.use_award) then
            err_code = ErrorCode.ConfigError
            return err_code
        end
        if not item_cfg.award_weight or table.size(item_cfg.award_weight) ~= item_cfg.award_count then
            err_code = ErrorCode.ConfigError
            return err_code
        else
            for item_id, item_cnt in pairs(item_cfg.use_award) do
                if not item_cfg.award_weight[item_id] then
                    err_code = ErrorCode.ConfigError
                    return err_code
                end
            end
        end
        if not item_cfg.award_repetition
            or (item_cfg.award_repetition ~= 1 and item_cfg.award_repetition ~= 2) then
            err_code = ErrorCode.ConfigError
            return err_code
        end
        local id_weight = table.copy(item_cfg.award_weight, true)
        for i = 1, item_cfg.award_count do
            local rand_item_id = scripts.Item.RangeTags(id_weight)
            if rand_item_id == 0 then
                moon.error(string.format("User.OpenGift Item.RangeTags err:\n%s", json.pretty_encode(id_weight)))
                err_code = ErrorCode.ConfigError
                return err_code
            end
            if not item_cfg.use_award[rand_item_id] then
                err_code = ErrorCode.ConfigError
                return err_code
            end
            if not item_list[rand_item_id] then
                item_list[rand_item_id] = {
                    id = rand_item_id,
                    count = 0,
                    pos = 0,
                }
            end
            item_list[rand_item_id].count = item_list[rand_item_id].count +
                (item_cfg.use_award[rand_item_id] * msg_data.use_item_cnt)

            if item_cfg.award_repetition == 1 then
                id_weight[rand_item_id] = nil
            end
        end
    else
        return err_code
    end

    if table.size(item_list) == 0 then
        err_code = ErrorCode.ConfigError
        return err_code
    end

    local stack_items, unstack_items, deal_coins = {}, {}, {}
    local ok = ItemDefine.GetItemDataFromIdCount(item_list, {}, stack_items, unstack_items, deal_coins)
    if not ok then
        moon.error(string.format("User.OpenGift GetItemDataFromIdCount err:\n%s", json.pretty_encode(item_list)))
        err_code = ErrorCode.ConfigError
        return err_code
    end
    err_code = scripts.Bag.CheckEmptyEnough(BagDef.BagType.Cangku, item_list, 0)
    if err_code ~= ErrorCode.None then
        return err_code
    end
    -- 添加道具
    if table.size(stack_items) + table.size(unstack_items) > 0 then
        err_code = scripts.Bag.AddItems(BagDef.BagType.Cangku, stack_items, unstack_items, bag_change_log)
        if err_code ~= ErrorCode.None then
            scripts.Bag.RollBackWithChange(bag_change_log)
            moon.error(string.format("User.OpenGift AddItems stack_items err:\n%s",
                json.pretty_encode(stack_items)))
            moon.error(string.format("User.OpenGift AddItems unstack_items err:\n%s",
                json.pretty_encode(unstack_items)))
        end

        return err_code
    end

    return err_code
end

function User.AddAccountBuff(item_cfg, msg_data)
    local err_code = ErrorCode.ItemTypeMismatch
    if not item_cfg.buff_type or not item_cfg.buff_count then
        err_code = ErrorCode.ConfigError
        return err_code
    end
    local buff_cfg = GameCfg.AccountBuffConfig[item_cfg.buff_type]
    if not buff_cfg then
        err_code = ErrorCode.ConfigError
        return err_code
    end

    local now_ts = moon.time()
    local query_user_attr = {}
    table.insert(query_user_attr, ProtoEnum.UserAttrType.buff_datas)
    local query_res = User.QueryUserAttr(query_user_attr)
    local buff_datas = query_res.user_attr[ProtoEnum.UserAttrType.buff_datas]
    if buff_datas then
        if buff_datas[buff_cfg.buff_effect] then
            local old_buff_data = buff_datas[buff_cfg.buff_effect]
            if old_buff_data.buff_id == buff_cfg.id then
                if buff_cfg.period_type == 1 then
                    old_buff_data.surplus_cnt = old_buff_data.surplus_cnt + (item_cfg.buff_count * msg_data.use_item_cnt)
                elseif buff_cfg.period_type == 2 then
                    if now_ts > old_buff_data.end_ts then
                        old_buff_data.end_ts = now_ts + (item_cfg.buff_count * msg_data.use_item_cnt)
                    else
                        old_buff_data.end_ts = old_buff_data.end_ts + (item_cfg.buff_count * msg_data.use_item_cnt)
                    end
                else
                    err_code = ErrorCode.ConfigError
                    return err_code
                end
            else
                local new_buff_data = UserAttrDef.newBuffData()
                new_buff_data.buff_id = buff_cfg.id
                new_buff_data.buff_effect = buff_cfg.buff_effect
                new_buff_data.period_type = buff_cfg.period_type
                new_buff_data.end_ts = 0
                new_buff_data.surplus_cnt = 0
                if buff_cfg.period_type == 1 then
                    new_buff_data.surplus_cnt = item_cfg.buff_count * msg_data.use_item_cnt
                elseif buff_cfg.period_type == 2 then
                    new_buff_data.end_ts = now_ts + (item_cfg.buff_count * msg_data.use_item_cnt)
                else
                    err_code = ErrorCode.ConfigError
                    return err_code
                end
                buff_datas[buff_cfg.buff_effect] = new_buff_data
            end
        else
            local new_buff_data = UserAttrDef.newBuffData()
            new_buff_data.buff_id = buff_cfg.id
            new_buff_data.buff_effect = buff_cfg.buff_effect
            new_buff_data.period_type = buff_cfg.period_type
            new_buff_data.end_ts = 0
            new_buff_data.surplus_cnt = 0
            if buff_cfg.period_type == 1 then
                new_buff_data.surplus_cnt = item_cfg.buff_count * msg_data.use_item_cnt
            elseif buff_cfg.period_type == 2 then
                new_buff_data.end_ts = now_ts + (item_cfg.buff_count * msg_data.use_item_cnt)
            else
                err_code = ErrorCode.ConfigError
                return err_code
            end
            buff_datas[buff_cfg.buff_effect] = new_buff_data
        end
    else
        moon.error(string.format("User.AddAccountBuff QueryUserAttr err:\n%s", json.pretty_encode(query_res)))
        err_code = ErrorCode.ServerInternalError
        return err_code
    end

    return ErrorCode.None, buff_datas
end

-- 客户端请求--使用道具
function User.PBUseItemReqCmd(req)
    -- 参数验证
    if not req.msg.use_item_id or not req.msg.use_item_cnt then
        return context.S2C(context.net_id, CmdCode.PBUseItemRspCmd, {
            code = ErrorCode.ParamInvalid,
            error = "无效请求参数",
            uid = context.uid,
            use_item_id = req.msg.use_item_id or 0,
            use_item_cnt = req.msg.use_item_cnt or 0,
        }, req.msg_context.stub_id)
    end

    local cost_items = {}
    cost_items[req.msg.use_item_id] = {
        id = req.msg.use_item_id,
        count = -req.msg.use_item_cnt,
        pos = 0,
    }
    -- 检测道具是否足够
    local bag_cost_code = scripts.Bag.CheckItemsEnough(BagDef.BagType.Cangku, cost_items, {})
    if bag_cost_code ~= ErrorCode.None then
        return context.S2C(context.net_id, CmdCode.PBUseItemRspCmd, {
            code = bag_cost_code,
            error = "道具不足",
            uid = context.uid,
            use_item_id = req.msg.use_item_id,
            use_item_cnt = req.msg.use_item_cnt,
        }, req.msg_context.stub_id)
    end

    local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
    -- 不同使用类型
    local change_image_ids = {}
    local bag_change_log = {}
    local update_user_attr = {}
    local item_cfg = GameCfg.Item[req.msg.use_item_id]
    if item_cfg and item_cfg.use_type then
        if item_cfg.use_type == 1
            or item_cfg.use_type == 2
            or item_cfg.use_type == 3 then
            local err_code = scripts.ItemImage.UseItemAddImage(item_cfg, req.msg, change_image_ids)
            if err_code ~= ErrorCode.None then
                return context.S2C(context.net_id, CmdCode.PBUseItemRspCmd, {
                    code = err_code,
                    error = "使用道具失败",
                    uid = context.uid,
                    use_item_id = req.msg.use_item_id,
                    use_item_cnt = req.msg.use_item_cnt,
                }, req.msg_context.stub_id)
            end
        elseif item_cfg.use_type == 4
            or item_cfg.use_type == 5
            or item_cfg.use_type == 6 then
            -- 使用礼包
            local err_code = User.OpenGift(item_cfg, req.msg, bag_change_log)
            if err_code ~= ErrorCode.None then
                return context.S2C(context.net_id, CmdCode.PBUseItemRspCmd, {
                    code = err_code,
                    error = "使用道具失败",
                    uid = context.uid,
                    use_item_id = req.msg.use_item_id,
                    use_item_cnt = req.msg.use_item_cnt,
                }, req.msg_context.stub_id)
            end
        elseif item_cfg.use_type == 7 then
            -- 使用账户功能buff卡
            local err_code, buff_datas = User.AddAccountBuff(item_cfg, req.msg)
            if err_code ~= ErrorCode.None then
                return context.S2C(context.net_id, CmdCode.PBUseItemRspCmd, {
                    code = err_code,
                    error = "使用道具失败",
                    uid = context.uid,
                    use_item_id = req.msg.use_item_id,
                    use_item_cnt = req.msg.use_item_cnt,
                }, req.msg_context.stub_id)
            end
            update_user_attr[ProtoEnum.UserAttrType.buff_datas] = buff_datas
        else
            return context.S2C(context.net_id, CmdCode.PBUseItemRspCmd, {
                code = ErrorCode.ItemTypeMismatch,
                error = "道具类型错误",
                uid = context.uid,
                use_item_id = req.msg.use_item_id,
                use_item_cnt = req.msg.use_item_cnt,
            }, req.msg_context.stub_id)
        end
    else
        return context.S2C(context.net_id, CmdCode.PBUseItemRspCmd, {
            code = ErrorCode.ItemTypeMismatch,
            error = "道具类型错误",
            uid = context.uid,
            use_item_id = req.msg.use_item_id,
            use_item_cnt = req.msg.use_item_cnt,
        }, req.msg_context.stub_id)
    end

    -- 扣除消耗
    local errcode = scripts.Bag.DelItems(BagDef.BagType.Cangku, cost_items, {}, bag_change_log)
    if errcode ~= ErrorCode.None then
        scripts.Bag.RollBackWithChange(bag_change_log)
        return context.S2C(context.net_id, CmdCode.PBUseItemRspCmd, {
            code = errcode,
            error = "道具不足",
            uid = context.uid,
            use_item_id = req.msg.use_item_id,
            use_item_cnt = req.msg.use_item_cnt,
        }, req.msg_context.stub_id)
    end

    context.S2C(context.net_id, CmdCode.PBUseItemRspCmd, {
        code = ErrorCode.None,
        error = "success",
        uid = context.uid,
        use_item_id = req.msg.use_item_id,
        use_item_cnt = req.msg.use_item_cnt,
    }, req.msg_context.stub_id)

    -- 存储背包变更
    if bag_change_log then
        if table.size(bag_change_log) > 0 then
            scripts.Bag.SaveAndLog(bag_change_log, ItemDef.ChangeReason.UseItemUpLv, 0, 0, 0, req.msg.target_id)
        end
    end
    -- 图鉴信息变更
    if table.size(change_image_ids) > 0 then
        scripts.ItemImage.SaveAndLog(change_image_ids)
    end
    -- 账户数据变更
    if table.size(update_user_attr) > 0 then
        User.SetUserAttr(update_user_attr, true)
    end
end

function User.PBRefuseReturnRoomReqCmd(req)
    -- 参数验证
    if not req.msg.uid or not req.msg.roomid then
        return context.S2C(context.net_id, CmdCode.PBRefuseReturnRoomRspCmd, {
            code = ErrorCode.ParamInvalid,
            error = "无效请求参数",
            uid = context.uid,
            roomid = req.msg.roomid or 0,
        }, req.msg_context.stub_id)
    end

    if context.roomid ~= req.msg.roomid then
        return context.S2C(context.net_id, CmdCode.PBRefuseReturnRoomRspCmd, {
            code = ErrorCode.RoomNotFound,
            error = "无效请求参数",
            uid = context.uid,
            roomid = req.msg.roomid or 0,
        }, req.msg_context.stub_id)
    end

    -- 玩家强制退出房间
    local out_data = {
        roomid = req.msg.roomid,
        need_exit_room = true,
    }
    User.OutPlay(out_data)

    -- 清空消耗品背包
    local bag_change_log = {}
    local sync_baginfo = {
        capacity = 0,
        items = {}
    }
    local capacitys = scripts.Bag.GetBagCapacity({ BagDef.BagType.Consume })
    if capacitys and capacitys[BagDef.BagType.Consume] then
        sync_baginfo.capacity = capacitys[BagDef.BagType.Consume]
    end
    local errcode = scripts.Bag.SyncBagInfo(BagDef.BagType.Consume, sync_baginfo, bag_change_log)
    if errcode ~= ErrorCode.None then
        scripts.Bag.RollBackWithChange(bag_change_log)
        moon.error(string.format("PBRefuseReturnRoomReqCmd SyncBagInfo err:\n%s", json.pretty_encode(sync_baginfo)))
        return context.S2C(context.net_id, CmdCode.PBRefuseReturnRoomRspCmd, {
            code = ErrorCode.BagSortOutFailed,
            error = "背包清理失败",
            uid = context.uid,
            roomid = req.msg.roomid or 0,
        }, req.msg_context.stub_id)
    end
    if table.size(bag_change_log) > 0 then
        scripts.Bag.SaveAndLog(bag_change_log, ItemDef.ChangeReason.BattleRunAway)
    end

    return context.S2C(context.net_id, CmdCode.PBRefuseReturnRoomRspCmd, {
        code = ErrorCode.None,
        error = "",
        uid = context.uid,
        roomid = req.msg.roomid or 0,
    }, req.msg_context.stub_id)
end

function User.PBItemChangeSkinReqCmd(req)
    -- 参数验证
    if not req.msg.item_config_id or not req.msg.skin_id then
        return context.S2C(context.net_id, CmdCode.PBItemChangeSkinRspCmd, {
            code = ErrorCode.ParamInvalid,
            error = "无效请求参数",
            uid = context.uid,
            item_config_id = req.msg.item_config_id or 0,
            skin_id = req.msg.skin_id or 0,
        }, req.msg_context.stub_id)
    end

    local err_code = scripts.ItemImage.ItemChangeSkin(req.msg.item_config_id, req.msg.skin_id)
    if err_code ~= ErrorCode.None then
        return context.S2C(context.net_id, CmdCode.PBItemChangeSkinRspCmd, {
            code = err_code,
            error = "更换皮肤失败",
            uid = context.uid,
            item_config_id = req.msg.item_config_id or 0,
            skin_id = req.msg.skin_id or 0,
        }, req.msg_context.stub_id)
    end

    return context.S2C(context.net_id, CmdCode.PBItemChangeSkinRspCmd, {
        code = ErrorCode.None,
        error = "",
        uid = context.uid,
        item_config_id = req.msg.item_config_id or 0,
        skin_id = req.msg.skin_id or 0,
    }, req.msg_context.stub_id)
end

return User