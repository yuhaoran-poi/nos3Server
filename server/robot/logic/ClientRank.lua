--[[
* @file : ClientRank.lua
* @brief : 排行榜相关接口
]]
local moon = require("moon")
---@class Client
local Client = require "robot.logic.Client"

-- 获取排行榜信息
function Client:get_rank_info(rank_type, rank_id)
    if not self.ok then
        print("connect failed, err = ", err)
        return
    end
    local req_msg = {
        uid = self.uid,
        rank_type = rank_type,
        rank_id = rank_id or 1,
    }

    self:send("PBRankGetInfoReqCmd", req_msg, function(msg)
        print("rpc PBRankGetInfoReqCmd ret = ", self.index, msg)
        print_r(msg)
    end)
end

-- 领取排行榜奖励
function Client:get_rank_reward(rank_type)
    if not self.ok then
        print("connect failed, err = ", err)
        return
    end
    local req_msg = {
        uid = self.uid,
        rank_type = rank_type,
    }

    self:send("PBRankGetRewardReqCmd", req_msg, function(msg)
        print("rpc PBRankGetRewardReqCmd ret = ", self.index, msg)
        print_r(msg)
    end)
end

-- 更新段位榜
function Client:update_rank_duanwei(duanwei_level)
    if not self.ok then
        print("connect failed, err = ", err)
        return
    end
    local req_msg = {
        uid = self.uid,
        duanwei = duanwei_level,
    }

    self:send("PBRankUpdateDuanweiReqCmd", req_msg, function(msg)
        print("rpc PBRankUpdateDuanweiReqCmd ret = ", self.index, msg)
        print_r(msg)
    end)
end

-- 更新主线榜
function Client:update_rank_mainline(difficulty, clear_time)
    if not self.ok then
        print("connect failed, err = ", err)
        return
    end
    local req_msg = {
        uid = self.uid,
        difficulty = difficulty,
        clear_time = clear_time,
    }

    self:send("PBRankUpdateMainlineReqCmd", req_msg, function(msg)
        print("rpc PBRankUpdateMainlineReqCmd ret = ", self.index, msg)
        print_r(msg)
    end)
end

-- 更新封塔榜
function Client:update_rank_fengta(difficulty, clear_time)
    if not self.ok then
        print("connect failed, err = ", err)
        return
    end
    local req_msg = {
        uid = self.uid,
        difficulty = difficulty,
        clear_time = clear_time,
    }

    self:send("PBRankUpdateFengtaReqCmd", req_msg, function(msg)
        print("rpc PBRankUpdateFengtaReqCmd ret = ", self.index, msg)
        print_r(msg)
    end)
end

-- 更新发电榜
function Client:update_rank_fadian(amount)
    if not self.ok then
        print("connect failed, err = ", err)
        return
    end
    local req_msg = {
        uid = self.uid,
        amount = amount,
    }

    self:send("PBRankUpdateFadianReqCmd", req_msg, function(msg)
        print("rpc PBRankUpdateFadianReqCmd ret = ", self.index, msg)
        print_r(msg)
    end)
end

-- 更新玩家榜
function Client:update_rank_player(level)
    if not self.ok then
        print("connect failed, err = ", err)
        return
    end
    local req_msg = {
        uid = self.uid,
        level = level,
    }

    self:send("PBRankUpdatePlayerReqCmd", req_msg, function(msg)
        print("rpc PBRankUpdatePlayerReqCmd ret = ", self.index, msg)
        print_r(msg)
    end)
end

-- 更新角色榜
function Client:update_rank_role(role_id, role_level, role_skin)
    if not self.ok then
        print("connect failed, err = ", err)
        return
    end
    local req_msg = {
        uid = self.uid,
        role_id = role_id,
        role_level = role_level,
        role_skin = role_skin,
    }

    self:send("PBRankUpdateRoleReqCmd", req_msg, function(msg)
        print("rpc PBRankUpdateRoleReqCmd ret = ", self.index, msg)
        print_r(msg)
    end)
end

-- 更新古董榜
function Client:update_rank_antique(antique_id, value)
    if not self.ok then
        print("connect failed, err = ", err)
        return
    end
    local req_msg = {
        uid = self.uid,
        antique_id = antique_id,
        value = value,
    }

    self:send("PBRankUpdateAntiqueReqCmd", req_msg, function(msg)
        print("rpc PBRankUpdateAntiqueReqCmd ret = ", self.index, msg)
        print_r(msg)
    end)
end