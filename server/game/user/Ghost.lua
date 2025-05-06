local moon = require "moon"
local common = require "common"
local uuid = require "uuid"
local GameCfg = common.GameCfg
local ErrorCode = common.ErrorCode
local CmdCode = common.CmdCode
local Database = common.Database
local GhostDef = require("common.def.GhostDef")

---@type user_context
local context = ...
local scripts = context.scripts

local GhostDefine = {
    GhostID = { Start = 1017000, End = 1017999 },
    GhostSkin = { Start = 1070000, End = 1119999 },
}

---@class Ghost
local Ghost = {}

function Ghost.Init()
    --加载全部角色数据
    local ghostinfos = Ghost.LoadGhosts()
    if ghostinfos then
        scripts.UserModel.SetGhosts(ghostinfos)
    end

    local ghosts = scripts.UserModel.GetGhosts()
    if not ghosts then
        ghosts = GhostDef.newUserGhostDatas()

        local init_cfg = GameCfg.Init[1]
        if not init_cfg then
            return { code = ErrorCode.ConfigError, error = "no init_cfg" }
        end

        for k, v in pairs(init_cfg.item) do
            if k >= GhostDefine.GhostID.Start and k <= GhostDefine.GhostID.End then
                local ghost_cfg = GameCfg.GhostInfo[k]
                if not ghost_cfg then
                    return { code = ErrorCode.ConfigError, error = "no ghost_cfg" }
                end

                local ghost_info = GhostDef.newGhostData()
                ghost_info.config_id = k
                ghost_info.uniqid = uuid.next()

                ghosts.ghost_list[ghost_info.uniqid] = ghost_info

                if not ghosts.ghost_image_list[k] then
                    local ghost_image = GhostDef.newGhostImage()
                    ghost_image.config_id = k

                    ghosts.ghost_image_list[k] = ghost_image
                end
            end
        end

        if ghosts.ghost_list[init_cfg.battle_ghost] then
            ghosts.battle_ghost_id = init_cfg.battle_ghost
            local battle_ghost_info = ghosts.ghost_list[init_cfg.battle_ghost]
            local battle_ghost_image = ghosts.ghost_image_list[battle_ghost_info.config_id]
            scripts.User.SimpleSetShowGhost(battle_ghost_info, battle_ghost_image)
        end

        scripts.UserModel.SetGhosts(ghosts)
        Ghost.SaveGhostsNow()
    end

    return { code = ErrorCode.None }
end

function Ghost.Start()
    -- body
end

function Ghost.SaveGhostsNow(ghostTypes)
    local ghosts = scripts.UserModel.GetGhosts()
    if not ghosts then
        return false
    end

    local success = Database.saveuserghosts(context.addr_db_user, context.uid, ghosts)
    return success
end

function Ghost.LoadGhosts()
    local ghostinfos = Database.loaduserghosts(context.addr_db_user, context.uid)
    return ghostinfos
end

return Ghost