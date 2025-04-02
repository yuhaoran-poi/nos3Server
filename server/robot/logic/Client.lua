local moon = require("moon")
local socket = require("moon.socket")
local common = require("common")
--local driver = require "robot.common.net_driver"
 
local protocol = common.protocol

---@class Client
---@field index number 客户端索引
---@field username string 用户名
---@field password string 密码
---@field login_ok boolean 是否登录成功
---@field host string 服务器地址
---@field port number 服务器端口
---@field cb_map table<number,function> 回调函数表
---@field stub_id number 客户端ID
---@field ok boolean 是否连接成功
local Client = {}
 
 
function Client:Init()
 
    
end
 

function Client:OnPBxxxCmd(msg)
    
end

function Client:GetOnFunctions()
    local onFunctions = {}
    for name, func in pairs(getmetatable(self).__index) do
        if type(name) == "string" and type(func) == "function" and name:sub(1,2) == "On" then
            table.insert(onFunctions, {name = name, func = func})
        end
    end
    return onFunctions
end
 

return Client
