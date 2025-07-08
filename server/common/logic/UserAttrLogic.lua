local moon = require "moon"
local common = require "common"
local ErrorCode = common.ErrorCode --逻辑错误码
local CmdCode = common.CmdCode     --命令码
local Database = common.Database

local UserAttrLogic = {}

function UserAttrLogic.GetOtherUserAttr(context, quest_uid, fields)
    local res, err = context.call_user(quest_uid, "User.GetOnlineUserAttr", fields)
    if not res then
        moon.error("GetOtherUserAttr failed:", err)
        return nil
    end

    return res
end

function UserAttrLogic.QueryOtherUserAttr(context, quest_uid, fields)
    local res = UserAttrLogic.GetOtherUserAttr(context, quest_uid, fields)
    if not res or table.size(res) <= 0 then
        --内存中不存在则查询数据库
        local user_attr = Database.RedisGetUserAttr(context.addr_db_redis, quest_uid, fields)
        if not user_attr or table.size(user_attr) <= 0 then
            local db_data = Database.loaduser_attr(context.addr_db_user, quest_uid)
            if not db_data then
                return nil
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

                return res_attr
            end
        else
            return user_attr
        end
    end

    return res
end

function UserAttrLogic.GetOtherOnlineUserDetails(context, quest_uid)
    local res, err = context.call_user(quest_uid, "User.GetUserDetails")
    if err then
        moon.error("GetOtherOnlineUserDetails failed:", err)
        return nil
    end

    return res
end

function UserAttrLogic.QueryOtherUsersSimpleAttr(context, quest_uids)
    local users_attr = Database.RedisGetSimpleUserAttr(context.addr_db_redis, quest_uids)
    if not users_attr or table.size(users_attr) <= 0 then
        return nil
    else
        return users_attr
    end
end

return UserAttrLogic
