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

        ---加载UserAttr数据
        local db_user_attr, err = Database.loaduser_attr(context.addr_db_user, req.uid)
        if db_user_attr then
            data = {
                user_id = db_user_attr.uid,
                authkey = req.msg.login_data.authkey,
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
                authkey = req.msg.login_data.authkey,
                user_id = req.uid,
                user_attr = UserAttrDef.newUserAttr(),
            }
            data.user_attr.uid = data.user_id
            data.user_attr.plateform_id = data.authkey
            data.user_attr.nick_name = data.name or data.authkey
            data.user_attr.account_create_time = moon.time()
            data.user_attr.online_time = moon.time()
        end

        scripts.UserModel.Create(data)
        context.uid = req.uid
        context.net_id = req.net_id

        ---初始化自己数据
        context.batch_invoke_throw("Init", isnew)
        ---初始化互相引用的数据
        context.batch_invoke_throw("Start")

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

        ---加载道具图鉴数据
        local image_res = scripts.ItemImage.Start()
        if image_res.code ~= ErrorCode.None then
            return false
        end
        ---加载背包数据
        scripts.Bag.Start()
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

        -- 同步到redis
        local to_redis_data = scripts.UserModel.GetUserAttr()
        Database.RedisSetUserAttr(context.addr_db_redis, context.uid, to_redis_data)
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
        return { code = ErrorCode.None, error = "success", user_attr = DB.user_attr }
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

    --local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
    -- 同步到客户端
    if sync_client then
        local msg_data = {
            attr = t
        }
        context.S2C(context.net_id, CmdCode["PBUserAttrSyncCmd"], msg_data, 0)
    end
end

function User.GetUserAttr(fields)
    local db_user_attr = scripts.UserModel.GetUserAttr()
    local user_attr = {}
    local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
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
    }
    local simple_data = User.GetUserAttr(simple_fields)

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
    local room_member_data = User.GetUserAttr(room_member_fields)

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
    local details_data = User.GetUserAttr(details_fields)
    local role_data = scripts.Role.GetRoleInfo(details_data.cur_show_role.config_id)
    local ghost_data = scripts.Ghost.GetGhostInfo(details_data.cur_show_ghost.config_id)

    return {user_attr = details_data, role_data = role_data, ghost_data = ghost_data}
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
    local simple_data = User.GetUserSimpleData()

    local ret = {
        code = ErrorCode.None,
        error = "success",
        uid = context.uid,
        info = simple_data,
    }
    context.S2C(context.net_id, CmdCode["PBClientGetUsrSimInfoRspCmd"], ret, req.msg_context.stub_id)
end

function User.PBClientGetAllUserAttrReqCmd(req)
    local total_attr = User.GetUserAttr()

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
end

function User.SimpleSetShowRole(role_info)
    local user_attr = scripts.UserModel.GetUserAttr()
    if not user_attr then
        return false
    end

    if not user_attr.cur_show_role then
        user_attr.cur_show_role = RoleDef.newSimpleRoleData()
    end
    user_attr.cur_show_role.config_id = role_info.config_id
    user_attr.cur_show_role.skins = role_info.skins

    return true
end

function User.SimpleSetShowGhost(ghost_info, ghost_image)
    local user_attr = scripts.UserModel.GetUserAttr()
    if not user_attr then
        return false
    end

    if not user_attr.cur_show_ghost then
        user_attr.cur_show_ghost = GhostDef.newSimpleGhostData()
    end
    user_attr.cur_show_ghost.config_id = ghost_info.config_id
    user_attr.cur_show_ghost.skin_id = ghost_image.cur_skin_id

    return true
end

local function LightRoleEquipment(msg)
    local err_role_code, role_info = scripts.Role.GetRoleInfo(msg.roleid)
    if err_role_code ~= ErrorCode.None or not role_info then
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
        if table.size(save_bags) then
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

    if table.size(save_bags) then
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
        local smallType = scripts.ItemDefine.GetItemType(item.config_id)
        if smallType == scripts.ItemDefine.EItemSmallType.Coin then
            add_coins[item.config_id] = {
                coin_id = item.config_id,
                count = item.item_count,
            }
        else
            add_items[item.config_id] = { count = item.item_count }
        end
    end

    local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
    if table.size(add_items) + table.size(add_coins) <= 0 then
        err_code = ErrorCode.ItemNotExist
    end

    if table.size(add_items) > 0 then
        err_code = scripts.Bag.AddItems(BagDef.BagType.Cangku, add_items, {}, change_log)
    end
    if table.size(add_coins) > 0 then
        err_code = scripts.Bag.DealCoins(add_coins, change_log)
    end

    if err_code == ErrorCode.None then
        local save_bags = {}
        for bagType, _ in pairs(change_log) do
            save_bags[bagType] = 1
        end
        local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
        scripts.Bag.SaveAndLog(save_bags, change_log)
    end
    return err_code
end

-- 客户端请求--法器升级
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

    -- 图鉴升级
    local err_code, change_log = scripts.ItemImage.UpLvImage(req.msg.config_id)
    if err_code ~= ErrorCode.None then
        return context.S2C(context.net_id, CmdCode.PBClientItemUpLvRspCmd, {
            code = ErrorCode.ItemNotExist,
            error = "图鉴不存在",
            uid = context.uid,
            config_id = req.msg.config_id,
            add_exp = req.msg.add_exp,
        }, req.msg_context.stub_id)
    end

    context.S2C(context.net_id, CmdCode.PBClientUpLvRspCmd, {
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

        if table.size(save_bags) then
            scripts.Bag.SaveAndLog(save_bags, change_log)
        end
    end
    -- 图鉴信息变更
    local change_image_ids = {}
    table.insert(change_image_ids, req.msg.config_id)
    scripts.ItemImage.UpdateAndSave(change_image_ids)

    return
end

-- 客户端请求--道具修复
function User.PBClientItemRepairReqCmd(req)
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

function User.PBGetOtherDetailReqCmd(req)
    if context.uid ~= req.msg.uid
        or req.msg.quest_uid == 0
        or req.msg.uid == req.msg.quest_uid then
        return context.S2C(context.net_id, CmdCode.PBGetOtherDetailReqCmd, {
            code = ErrorCode.ParamInvalid,
            error = "无效请求参数",
            uid = context.uid,
            quest_uid = req.msg.quest_uid or 0,
        }, req.msg_context.stub_id)
    end

    local user_attr_res = UserAttrLogic.GetOtherUserDetails(context, req.msg.quest_uid)
    if user_attr_res then
        return context.S2C(context.net_id, CmdCode.PBGetOtherDetailReqCmd, {
            code = ErrorCode.None,
            error = "",
            uid = context.uid,
            quest_uid = req.msg.quest_uid,
            user_attr = user_attr_res,
        })
    else
        return context.S2C(context.net_id, CmdCode.PBGetOtherDetailReqCmd, {
            code = ErrorCode.UserOffline,
            error = "用户离线",
            uid = context.uid,
            quest_uid = req.msg.quest_uid or 0,
        }, req.msg_context.stub_id)
    end
end

return User
