local moon = require("moon")
local common = require("common")
local Database = common.Database

----DB Model 标准定义格式

---@type user_context
local context = ...

---定时存储标记
local dirty = false


local DBData

---@class UserModel
local UserModel = {}

function UserModel.Create(data)
    if DBData then
        return DBData
    end

    DBData = data
    return data
end

function UserModel.SaveRun()
    ---定义自动存储
    moon.async(function()
        while true do
            moon.sleep(5000)
            if dirty then
                local ok, err = xpcall(UserModel.Save, debug.traceback, true)
                if not ok then
                    moon.error(err)
                end
            end
        end
    end)
end

---需要立刻保存重要数据时,使用这个函数,参数使用默认值即可
---@param checkDirty? boolean
function UserModel.Save(checkDirty)
    if checkDirty and not dirty then
        return
    end
    
    --Database.saveuserdata(context.addr_db_user, DBData.user_data.user_id, DBData.user_data)
    Database.saveuser_attr(context.addr_db_user, DBData.user_attr.uid, DBData.user_attr)
    dirty = false
end

---只读,使用这个函数
function UserModel.Get()
    return DBData
end
-- function UserModel.GetUserData()
--     return DBData.user_data
-- end

-- function UserModel.MutGetUserData()
--     dirty = true
--     return DBData.user_data
-- end

---需要修改数据时,使用这个函数
function UserModel.MutGet()
    dirty = true
    return DBData
end

-- ---@return PBUserSimpleInfo ? nil
-- function UserModel.GetSimple()
--     if DBData and DBData.simple then
--         return DBData.simple
--     end
--     return nil
-- end

-- function UserModel.SetSimple(simple_data)
--     DBData.simple = simple_data
-- end

---@return PBUserAttr
function UserModel.GetUserAttr()
    return DBData.user_attr
end

---@return PBUserAttr
function UserModel.MutGetUserAttr()
    dirty = true
    return DBData.user_attr
end

---@return PBBags ? nil
function UserModel.GetBagData()
    if DBData and DBData.bagdata then
        return DBData.bagdata
    end
    return nil
end

function UserModel.SetBagData(baginfos)
    if not DBData then
        return
    end

    if not DBData.bagdata then
        DBData.bagdata = baginfos
    else
        for bagtype, baginfo in pairs(baginfos) do
            DBData.bagdata[bagtype] = baginfo
        end
    end
end

---@return PBUserRoleDatas ? nil
function UserModel.GetRoles()
    if DBData and DBData.roles then
        return DBData.roles
    end
    return nil
end

function UserModel.SetRoles(roleinfos)
    DBData.roles = roleinfos
end

---@return PBUserGhostDatas ? nil
function UserModel.GetGhosts()
    if DBData and DBData.ghosts then
        return DBData.ghosts
    end
    return nil
end

function UserModel.SetGhosts(ghostinfos)
    DBData.ghosts = ghostinfos
end

---@return PBUserImage ? nil
function UserModel.GetItemImages()
    if DBData and DBData.itemimages then
        return DBData.itemimages
    end
    return nil
end

function UserModel.SetItemImages(itemImageinfos)
    DBData.itemimages = itemImageinfos
end

---@return PBUserCoins ? nil
function UserModel.GetCoinsData()
    if DBData and DBData.coinsdata then
        return DBData.coinsdata
    end
    return nil
end

function UserModel.SetCoinsData(coininfos)
    if not DBData then
        return
    end

    if not DBData.coinsdata then
        DBData.coinsdata = coininfos
    else
        for coin_id, coin_info in pairs(coininfos) do
            DBData.coinsdata[coin_id] = coin_info
        end
    end
end

---@return PBUserFriendDatas ? nil
function UserModel.GetFriends()
    if DBData and DBData.friends then
        return DBData.friends
    end
    return nil
end

function UserModel.SetFriends(friendinfos)
    DBData.friends = friendinfos
end

---@return PBUserMailBox ? nil
function UserModel.GetMails()
    if DBData and DBData.mails then
        return DBData.mails
    end
    return nil
end

function UserModel.SetMails(mailinfos)
    DBData.mails = mailinfos
end

---@return PBSelfTradeData ? nil
function UserModel.GetTradeData()
    if DBData and DBData.trade_data then
        return DBData.trade_data
    end
    return nil
end

function UserModel.SetTradeData(trade_data)
    DBData.trade_data = trade_data
end

---@return PBShopPlayerData ? nil
function UserModel.GetShopData()
    if DBData and DBData.shops then
        return DBData.shops
    end
    return nil
end

function UserModel.SetShopData(shopinfos)
    DBData.shops = shopinfos
end

---@return PBUserGods ? nil
function UserModel.GetGods()
    if DBData and DBData.gods then
        return DBData.gods
    end
    return nil
end

function UserModel.SetGods(godsinfo)
    DBData.gods = godsinfo
end

---@return PBAntiqueShowcaseDataS ? nil
function UserModel.GetAntiqueShowcase()
    if DBData and DBData.antique_showcase then
        return DBData.antique_showcase
    end
    return nil
end

function UserModel.SetAntiqueShowcase(antique_showcase)
    DBData.antique_showcase = antique_showcase
    -- if not DBData then
    --     return
    -- end

    -- if not DBData.antique_showcase then
    --     -- 第一次直接赋值整张表
    --     DBData.antique_showcase = antique_showcase
    -- else
    --     -- 如果要按 showcase_id 更新/合并
    --     for _, showcase in pairs(antique_showcase) do
    --         local sid = showcase.showcase_id
    --         DBData.antique_showcase[sid] = showcase
    --     end
    -- end
end

return UserModel