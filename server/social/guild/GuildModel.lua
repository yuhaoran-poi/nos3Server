local moon = require("moon")
local common = require("common")
local Database = common.Database
local protocol = common.protocol
local GuildDef = require("common.def.GuildDef")
----DB Model 标准定义格式

---@type guild_context
local context = ...

---定时存储标记
local dirty = false

 
local DBData

 
---@class GuildModel
local GuildModel = {}

function GuildModel.Create(data)

    if DBData then
        return DBData
    end
    dirty = true
    DBData =
    {
        GuildInfo = {
                      db_data = data.GuildInfo,
                      dirty = true,
                   },
        GuildShop = {
                      db_data = data.GuildShop,
                      dirty = true,
                   }, 
        GuildBag = {
                      db_data = data.GuildBag,
                      dirty = true,
                   },
        GuildRecord = {
                      db_data = data.GuildRecord,
                      dirty = true,
                    },
    }

    ---定义自动存储
    moon.async(function()
        while true do
            moon.sleep(5000)
            if dirty then
                local ok, err = xpcall(GuildModel.Save, debug.traceback, true)
                if not ok then
                    moon.error(err)
                end
            end
        end
    end)

    return data
end

---需要立刻保存重要数据时,使用这个函数,参数使用默认值即可
---@param checkDirty? boolean
function GuildModel.Save(checkDirty)
    if checkDirty and not dirty then
        return
    end
    if DBData.GuildInfo.dirty then
        
        local ok, err = Database.save_guildinfo(context.addr_db_game, context.guild_id, DBData.GuildInfo.db_data)
        if not ok then
            moon.error(err)
            return
        end
        DBData.GuildInfo.dirty = false
    end

    if DBData.GuildShop.dirty then
        local ok, err = Database.save_guildshop(context.addr_db_game, context.guild_id, DBData.GuildShop.db_data)
        if not ok then
            moon.error(err)
            return
        end
        DBData.GuildShop.dirty = false
    end

    if DBData.GuildBag.dirty then
        local ok, err = Database.save_guildbag(context.addr_db_game, context.guild_id, DBData.GuildBag.db_data)
        if not ok then
            moon.error(err)
            return
        end
        DBData.GuildBag.dirty = false
    end

    if DBData.GuildRecord.dirty then
        local ok, err = Database.save_guildrecord(context.addr_db_game, context.guild_id, DBData.GuildRecord.db_data)
        if not ok then
            moon.error(err)
            return
        end
        DBData.GuildRecord.dirty = false
    end

    dirty = false
end

---只读,使用这个函数
function GuildModel.Get()
    return DBData
end
---只读,使用这个函数
---@return PBGuildInfoDB
function GuildModel.GetGuildInfoDB()
    return DBData.GuildInfo.db_data
end

---需要修改数据时,使用这个函数
---@return PBGuildInfoDB
function GuildModel.MutGetGuildInfoDB()
    dirty = true
    DBData.GuildInfo.dirty = true
    return DBData.GuildInfo.db_data
end
---只读,使用这个函数
---@return PBGuildShopDB
function GuildModel.GetGuildShopDB()
    return DBData.GuildShop.db_data
end

---需要修改数据时,使用这个函数
---@return PBGuildShopDB
function GuildModel.MutGetGuildShopDB()
    dirty = true
    DBData.GuildShop.dirty = true
    return DBData.GuildShop.db_data
end
---只读,使用这个函数
---@return PBGuildBagDB
function GuildModel.GetGuildBagDB()
    return DBData.GuildBag.db_data
end

---需要修改数据时,使用这个函数
---@return PBGuildBagDB
function GuildModel.MutGetGuildBagDB()
    dirty = true
    DBData.GuildBag.dirty = true
    return DBData.GuildBag.db_data
end
---只读,使用这个函数
---@return PBGuildRecordDB
function GuildModel.GetGuildRecordDB()
    return DBData.GuildRecord.db_data
end

---需要修改数据时,使用这个函数
---@return PBGuildRecordDB
function GuildModel.MutGetGuildRecordDB()
    dirty = true
    DBData.GuildRecord.dirty = true
    return DBData.GuildRecord.db_data
end

 

return GuildModel