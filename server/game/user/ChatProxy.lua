local moon = require "moon"
local common = require "common"
local cluster = require("cluster")
local GameCfg = common.GameCfg
local ErrorCode = common.ErrorCode
local CmdCode = common.CmdCode

---@type user_context
local context = ...
local scripts = context.scripts

---@class ChatProxy
local ChatProxy = {}

function ChatProxy.Init()
    local data = scripts.UserModel.MutGetUserData()
    local ret = LuaPanda and LuaPanda.BP and LuaPanda.BP()
    if not data.chat then
        data.chat = {
             
        }
    else
        -- 向聊天管理器查询节点和地址
       
    end
end

function ChatProxy.Start()
    -- body
end

 

return ChatProxy
