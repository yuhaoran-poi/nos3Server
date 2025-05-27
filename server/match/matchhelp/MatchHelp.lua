--[[
* @file : MatchHelp.lua
* @type: single service
* @brief : 匹配管理服务
* @author : yq
]]

local moon = require "moon"
local uuid = require "uuid"
local coqueue = require "moon.queue"
local common = require "common"
 
 
---@type matchhelp_context
local context = ...
local scripts = context.scripts ---方便访问同服务的其它lua模块
 
---@class MatchHelp
local MatchHelp = {}

function MatchHelp.Init()
    context.matchmgr_addr = moon.queryservice("matchmgr")
    return true
end

function MatchHelp.Start()
    
    moon.async(function()
        while true do
            moon.sleep(3000) -- 每3秒
            --MatchHelp.DoMatch()
            local ret, err = moon.call("lua", context.matchmgr_addr, "MatchMgr.DoMatch")
        end
    end)

    return true
end

 
function MatchHelp.Shutdown()
    moon.quit()
    return true
end
 
 
return MatchHelp