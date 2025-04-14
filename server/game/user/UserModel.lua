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

    return data
end

---需要立刻保存重要数据时,使用这个函数,参数使用默认值即可
---@param checkDirty? boolean
function UserModel.Save(checkDirty)
    if checkDirty and not dirty then
        return
    end

    local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
    Database.saveuserdata(context.addr_db_user, DBData.user_data.user_id, DBData.user_data)
    dirty = false
end

---只读,使用这个函数
 
function UserModel.Get()
    return DBData
end
function UserModel.GetUserData()
    return DBData.user_data
end
function UserModel.MutGetUserData()
    local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
    dirty = true
    return DBData.user_data
end

---需要修改数据时,使用这个函数
---@return UserData
function UserModel.MutGet()
    dirty = true
    return DBData
end

function UserModel.SetSimple(simple_data)
    local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
    DBData.simple = simple_data
end

return UserModel