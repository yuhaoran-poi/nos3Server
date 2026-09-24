--[[
* @file : ClientMission.lua
* @brief : 任务系统相关协议测试
]]
local moon = require("moon")
---@class Client
local Client = require "robot.logic.Client"

-- 获取玩家任务信息（含线性/周期/成就/活动任务）
function Client:get_player_mission_info()
    if not self.ok then
        print("connect failed, err = ", err)
        return
    end

    local req_msg = {
        uid = self.uid,
    }
    self:send("PBGetPlayerMissionInfoReqCmd", req_msg, function(msg)
        print("rpc PBGetPlayerMissionInfoRspCmd ret = ", self.index, msg)
        print_r(msg)
    end)
end

-- 领取任务奖励（四类任务可同时传，服务端互斥校验只允许一次一类）
-- @param linear_ids 线性任务id数组
-- @param period_ids 周期任务id数组
-- @param achivement_ids 成就任务id数组
-- @param activity_ids 活动任务id数组
function Client:get_mission_reward(linear_ids, period_ids, achivement_ids, activity_ids)
    if not self.ok then
        print("connect failed, err = ", err)
        return
    end

    local req_msg = {
        uid = self.uid,
        linear_ids = linear_ids or {},
        period_ids = period_ids or {},
        achivement_ids = achivement_ids or {},
        activity_ids = activity_ids or {},
    }
    self:send("PBGetMissionRewardReqCmd", req_msg, function(msg)
        print("rpc PBGetMissionRewardRspCmd ret = ", self.index, msg)
        print_r(msg)
    end)
end

-- 将命令行的若干 id 参数归一化为数字数组: 单个数字/字符串 -> {n}, 多参数 -> {n1,n2,...}
function Client:normalize_ids(...)
    local ids = {}
    for _, v in ipairs({ ... }) do
        if type(v) == "table" then
            for _, sub in ipairs(v) do
                table.insert(ids, tonumber(sub))
            end
        else
            table.insert(ids, tonumber(v))
        end
    end
    return ids
end

-- 领线性任务奖励
function Client:get_linear_mission_reward(...)
    self:get_mission_reward(self:normalize_ids(...), nil, nil, nil)
end

-- 领周期任务奖励
function Client:get_period_mission_reward(...)
    self:get_mission_reward(nil, self:normalize_ids(...), nil, nil)
end

-- 领成就任务奖励
function Client:get_achivement_mission_reward(...)
    self:get_mission_reward(nil, nil, self:normalize_ids(...), nil)
end

-- 领活动任务奖励
function Client:get_activity_mission_reward(...)
    self:get_mission_reward(nil, nil, nil, self:normalize_ids(...))
end

-- 刷新（重随）每日随机任务
function Client:refresh_mission(old_mission_id)
    if not self.ok then
        print("connect failed, err = ", err)
        return
    end

    local req_msg = {
        uid = self.uid,
        old_mission_id = old_mission_id,
    }
    self:send("PBRrefreshMissionReqCmd", req_msg, function(msg)
        print("rpc PBRrefreshMissionRspCmd ret = ", self.index, msg)
        print_r(msg)
    end)
end
