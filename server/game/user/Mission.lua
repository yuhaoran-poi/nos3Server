local moon = require "moon"
local datetime = require("moon.datetime")
local common = require "common"
local clusterd = require("cluster")
local json = require("json")
local GameCfg = common.GameCfg
local ErrorCode = common.ErrorCode
local CmdCode = common.CmdCode
local Database = common.Database
local MissionDef = require("common.def.MissionDef")
local ItemDefine = require("common.logic.ItemDefine")
local BagDef = require("common.def.BagDef")
local ItemDef = require("common.def.ItemDef")
local CommonCfgDef = require("common.def.CommonCfgDef")
local ProtoEnum = require("tools.ProtoEnum")
local MissionLogic = require("common.logic.MissionLogic")

---@type user_context
local context = ...
local scripts = context.scripts

---@class Mission
local Mission = {}

function Mission.Init()
    -- --加载任务数据
    -- local player_mission_info = Mission.LoadMissionInfo()
    -- if player_mission_info then
    --     scripts.UserModel.SetMissionInfo(player_mission_info)
    -- end

    -- local mission_info = scripts.UserModel.GetMissionInfo()
    -- if not mission_info then
    --     mission_info = MissionDef.newPlayerMissionInfo()
    --     scripts.UserModel.SetMissionInfo(mission_info)
    -- else
    --     -- 兼容旧存档：无活动任务数据时初始化
    --     if not mission_info.activity_info then
    --         mission_info.activity_info = MissionDef.newActivityMissionInfo()
    --         scripts.UserModel.SetMissionInfo(mission_info)
    --     end
    -- end
end

function Mission.Start()
    -- local mission_info = scripts.UserModel.GetMissionInfo()
    -- if not mission_info then
    --     return
    -- end

    -- -- 账号初始化时进行一次周期任务随机（last_update_ts 为 0 会触发首次刷新）
    -- local now_ts = moon.time()
    -- local new_complete_period_ids = {}
    -- if Mission.CheckPeriodInfo(mission_info, now_ts, new_complete_period_ids) then
    --     if table.size(new_complete_period_ids) > 0 then
    --         Mission.PeriodMissionComplete(mission_info, new_complete_period_ids)
    --     end
    --     Mission.makePeriodMap(mission_info)
    -- end

    -- -- 检查活动任务
    -- local new_complete_activity_ids = {}
    -- if Mission.CheckActivityInfo(mission_info, now_ts, new_complete_activity_ids) then
    --     if table.size(new_complete_activity_ids) > 0 then
    --         Mission.ActivityMissionComplete(mission_info, new_complete_activity_ids)
    --     end
    --     Mission.makeActivityMap(mission_info)
    -- end

    -- Mission.SaveMissionsNow()
end

function Mission.SaveMissionsNow()
    local mission_info = scripts.UserModel.GetMissionInfo()
    if not mission_info then
        return false
    end

    local success = Database.savemissioninfo(context.addr_db_user, context.uid, mission_info.linear_info, mission_info.period_info, mission_info.achivement_info, mission_info.activity_info)
    return success
end

function Mission.LoadMissionInfo()
    local player_mission_info = Database.loadmissioninfo(context.addr_db_user, context.uid)
    return player_mission_info
end

function Mission.SaveAndSync(change_log)
    local mission_info = scripts.UserModel.GetMissionInfo()
    if not mission_info then
        return
    end

    if not change_log then
        return
    end

    local update_msg = {
        update_mission_datas = {},
        update_complete_ids = {},
        update_period_info = {},
        -- update_activity_info 故意不初始化：仅活动任务整体刷新时整包下发，平时保持 nil（proto3 编码会跳过未设置字段），否则会破坏下方空消息过滤判断
    }
    if change_log.achivements then
        for mission_id, mission_state in pairs(change_log.achivements) do
            if mission_state == MissionDef.ETaskState.COMPLETE then
                update_msg.update_complete_ids[mission_id] = mission_state
            elseif mission_state == MissionDef.ETaskState.NO_COMPLETE then
                update_msg.update_mission_datas[mission_id] = mission_info.achivement_info.now_mission_datas[mission_id]
            end
        end
    end
    if change_log.linears then
        for mission_id, mission_state in pairs(change_log.linears) do
            if mission_state == MissionDef.ETaskState.COMPLETE then
                update_msg.update_complete_ids[mission_id] = mission_state
            elseif mission_state == MissionDef.ETaskState.NO_COMPLETE then
                update_msg.update_mission_datas[mission_id] = mission_info.linear_info.now_mission_datas[mission_id]
            end
        end
    end
    if change_log.periods_all_change then
        update_msg.update_period_info = mission_info.period_info
    else
        for mission_id, mission_state in pairs(change_log.periods) do
            if mission_state == MissionDef.ETaskState.COMPLETE then
                update_msg.update_complete_ids[mission_id] = mission_state
            elseif mission_state == MissionDef.ETaskState.NO_COMPLETE then
                if mission_info.period_info.now_day_mission_datas[mission_id] then
                    update_msg.update_mission_datas[mission_id] = mission_info.period_info.now_day_mission_datas
                        [mission_id]
                elseif mission_info.period_info.now_week_mission_datas[mission_id] then
                    update_msg.update_mission_datas[mission_id] = mission_info.period_info.now_week_mission_datas
                        [mission_id]
                elseif mission_info.period_info.now_month_mission_datas[mission_id] then
                    update_msg.update_mission_datas[mission_id] = mission_info.period_info.now_month_mission_datas
                        [mission_id]
                end
            end
        end
    end
    -- 活动任务：整体刷新时整包下发，否则增量混入通用字段
    if change_log.activitys_all_change then
        update_msg.update_activity_info = mission_info.activity_info
    elseif change_log.activitys then
        for mission_id, mission_state in pairs(change_log.activitys) do
            if mission_state == MissionDef.ETaskState.COMPLETE then
                update_msg.update_complete_ids[mission_id] = mission_state
            elseif mission_state == MissionDef.ETaskState.NO_COMPLETE then
                update_msg.update_mission_datas[mission_id] = mission_info.activity_info.now_mission_datas[mission_id]
            end
        end
    end

    -- 没有任何实际变更时不发送空同步消息
    if not update_msg.update_activity_info
        and table.size(update_msg.update_complete_ids) <= 0
        and table.size(update_msg.update_mission_datas) <= 0
        and table.size(update_msg.update_period_info) <= 0 then
        scripts.UserModel.SetMissionInfo(mission_info)
        Mission.SaveMissionsNow()
        return
    end

    context.S2C(context.net_id, CmdCode.PBUpdateMissionSyncCmd, update_msg, 0)

    scripts.UserModel.SetMissionInfo(mission_info)

    Mission.SaveMissionsNow()
end

function Mission.newLinearMission(mission_info, linear_cfg, now_ts, new_complete_ids, change_log)
    local new_mission_data = MissionDef.newMissionData()
    new_mission_data.mission_id = linear_cfg.id
    new_mission_data.mission_type = linear_cfg.type
    new_mission_data.mission_state = MissionDef.ETaskState.NO_COMPLETE
    new_mission_data.beg_ts = linear_cfg.start_time
    new_mission_data.end_ts = linear_cfg.end_time
    if linear_cfg.target1 > 0 then
        local new_cond_data = MissionDef.newConditionData()
        new_cond_data.cond_id = linear_cfg.target1
        new_cond_data.target_value = linear_cfg.target1_data
        new_cond_data.now_value = 0
        new_cond_data.is_complete = 0
        if linear_cfg.target1_param1 then
            table.insert(new_cond_data.params, linear_cfg.target1_param1)
        end
        if linear_cfg.target1_param2 then
            table.insert(new_cond_data.params, linear_cfg.target1_param2)
        end
        if linear_cfg.target1_arr and table.size(linear_cfg.target1_arr) > 0 then
            new_cond_data.arr_params = linear_cfg.target1_arr
        end
        table.insert(new_mission_data.cond_datas, new_cond_data)
    end
    if linear_cfg.target2 > 0 then
        local new_cond_data = MissionDef.newConditionData()
        new_cond_data.cond_id = linear_cfg.target2
        new_cond_data.target_value = linear_cfg.target2_data
        new_cond_data.now_value = 0
        new_cond_data.is_complete = 0
        if linear_cfg.target2_param1 then
            table.insert(new_cond_data.params, linear_cfg.target2_param1)
        end
        if linear_cfg.target2_param2 then
            table.insert(new_cond_data.params, linear_cfg.target2_param2)
        end
        if linear_cfg.target2_arr and table.size(linear_cfg.target2_arr) > 0 then
            new_cond_data.arr_params = linear_cfg.target2_arr
        end
        table.insert(new_mission_data.cond_datas, new_cond_data)
    end

    if new_mission_data.beg_ts ~= 0 and now_ts < new_mission_data.beg_ts then
        mission_info.linear_info.wait_beg_mission_datas[linear_cfg.id] = new_mission_data
    else
        Mission.CheckNewMissionCond(new_mission_data)
        if new_mission_data.mission_state == MissionDef.ETaskState.COMPLETE then
            mission_info.linear_info.complete_ids[linear_cfg.id] = MissionDef.ETaskState.COMPLETE
            table.insert(new_complete_ids, linear_cfg.id)
            if change_log and change_log.linears then
                change_log.linears[linear_cfg.id] = MissionDef.ETaskState.COMPLETE
            end
        else
            mission_info.linear_info.now_mission_datas[linear_cfg.id] = new_mission_data
            if change_log and change_log.linears then
                change_log.linears[linear_cfg.id] = MissionDef.ETaskState.NO_COMPLETE
            end
        end
    end
end

function Mission.newPeriodMission(mission_info, period_cfg, now_ts, new_complete_ids)
    local new_mission_data = MissionDef.newMissionData()
    new_mission_data.mission_id = period_cfg.id
    new_mission_data.mission_type = period_cfg.cyclical_date
    new_mission_data.mission_state = MissionDef.ETaskState.NO_COMPLETE
    new_mission_data.beg_ts = now_ts
    if period_cfg.cyclical_date == 1 then
        new_mission_data.end_ts = now_ts + (24 * 60 * 60)
    elseif period_cfg.cyclical_date == 2 then
        new_mission_data.end_ts = now_ts + (7 * 24 * 60 * 60)
    elseif period_cfg.cyclical_date == 3 then
        new_mission_data.end_ts = now_ts + (31 * 24 * 60 * 60)
    end

    if period_cfg.target1 > 0 then
        local new_cond_data = MissionDef.newConditionData()
        new_cond_data.cond_id = period_cfg.target1
        new_cond_data.target_value = period_cfg.target1_data
        new_cond_data.now_value = 0
        new_cond_data.is_complete = 0
        if period_cfg.target1_param1 then
            table.insert(new_cond_data.params, period_cfg.target1_param1)
        end
        if period_cfg.target1_param2 then
            table.insert(new_cond_data.params, period_cfg.target1_param2)
        end
        if period_cfg.target1_arr and table.size(period_cfg.target1_arr) > 0 then
            new_cond_data.arr_params = period_cfg.target1_arr
        end
        table.insert(new_mission_data.cond_datas, new_cond_data)
    end
    if period_cfg.target2 > 0 then
        local new_cond_data = MissionDef.newConditionData()
        new_cond_data.cond_id = period_cfg.target2
        new_cond_data.target_value = period_cfg.target2_data
        new_cond_data.now_value = 0
        new_cond_data.is_complete = 0
        if period_cfg.target2_param1 then
            table.insert(new_cond_data.params, period_cfg.target2_param1)
        end
        if period_cfg.target2_param2 then
            table.insert(new_cond_data.params, period_cfg.target2_param2)
        end
        if period_cfg.target2_arr and table.size(period_cfg.target2_arr) > 0 then
            new_cond_data.arr_params = period_cfg.target2_arr
        end
        table.insert(new_mission_data.cond_datas, new_cond_data)
    end

    Mission.CheckNewMissionCond(new_mission_data)
    if period_cfg.cyclical_date == 1 then
        if new_mission_data.mission_state == MissionDef.ETaskState.COMPLETE then
            mission_info.period_info.complete_day_ids[period_cfg.id] = MissionDef.ETaskState.COMPLETE
            table.insert(new_complete_ids, period_cfg.id)
        else
            mission_info.period_info.now_day_mission_datas[period_cfg.id] = new_mission_data
        end
    elseif period_cfg.cyclical_date == 2 then
        if new_mission_data.mission_state == MissionDef.ETaskState.COMPLETE then
            mission_info.period_info.complete_week_ids[period_cfg.id] = MissionDef.ETaskState.COMPLETE
            table.insert(new_complete_ids, period_cfg.id)
        else
            mission_info.period_info.now_week_mission_datas[period_cfg.id] = new_mission_data
        end
    elseif period_cfg.cyclical_date == 3 then
        if new_mission_data.mission_state == MissionDef.ETaskState.COMPLETE then
            mission_info.period_info.complete_month_ids[period_cfg.id] = MissionDef.ETaskState.COMPLETE
            table.insert(new_complete_ids, period_cfg.id)
        else
            mission_info.period_info.now_month_mission_datas[period_cfg.id] = new_mission_data
        end
    end
end

function Mission.newAchivementMission(mission_info, achivement_cfg, now_ts, new_complete_ids)
    local new_mission_data = MissionDef.newMissionData()
    new_mission_data.mission_id = achivement_cfg.id
    new_mission_data.mission_type = achivement_cfg.type
    new_mission_data.mission_state = MissionDef.ETaskState.NO_COMPLETE
    new_mission_data.beg_ts = now_ts
    new_mission_data.end_ts = now_ts
    if achivement_cfg.target1 > 0 then
        local new_cond_data = MissionDef.newConditionData()
        new_cond_data.cond_id = achivement_cfg.target1
        new_cond_data.target_value = achivement_cfg.target1_data
        new_cond_data.now_value = 0
        new_cond_data.is_complete = 0
        if achivement_cfg.target1_param1 then
            table.insert(new_cond_data.params, achivement_cfg.target1_param1)
        end
        if achivement_cfg.target1_param2 then
            table.insert(new_cond_data.params, achivement_cfg.target1_param2)
        end
        if achivement_cfg.target1_arr and table.size(achivement_cfg.target1_arr) > 0 then
            new_cond_data.arr_params = achivement_cfg.target1_arr
        end
        table.insert(new_mission_data.cond_datas, new_cond_data)
    end
    if achivement_cfg.target2 > 0 then
        local new_cond_data = MissionDef.newConditionData()
        new_cond_data.cond_id = achivement_cfg.target2
        new_cond_data.target_value = achivement_cfg.target2_data
        new_cond_data.now_value = 0
        new_cond_data.is_complete = 0
        if achivement_cfg.target2_param1 then
            table.insert(new_cond_data.params, achivement_cfg.target2_param1)
        end
        if achivement_cfg.target2_param2 then
            table.insert(new_cond_data.params, achivement_cfg.target2_param2)
        end
        if achivement_cfg.target2_arr and table.size(achivement_cfg.target2_arr) > 0 then
            new_cond_data.arr_params = achivement_cfg.target2_arr
        end
        table.insert(new_mission_data.cond_datas, new_cond_data)
    end

    Mission.CheckNewMissionCond(new_mission_data)
    if new_mission_data.mission_state == MissionDef.ETaskState.COMPLETE then
        mission_info.linear_info.complete_ids[achivement_cfg.id] = MissionDef.ETaskState.COMPLETE
        table.insert(new_complete_ids, achivement_cfg.id)
    else
        mission_info.linear_info.now_mission_datas[achivement_cfg.id] = new_mission_data
    end
end

function Mission.newActivityMission(mission_info, activity_cfg, now_ts, new_complete_ids)
    -- 类型未开启则跳过
    if not Mission.IsActivityTypeOpen(activity_cfg.type) then
        return
    end

    -- 时间范围判断：未到开始时间或已过结束时间则不创建
    if (activity_cfg.start_time and activity_cfg.start_time ~= 0 and now_ts < activity_cfg.start_time)
        or (activity_cfg.end_time and activity_cfg.end_time ~= 0 and now_ts >= activity_cfg.end_time) then
        return
    end

    local new_mission_data = MissionDef.newMissionData()
    new_mission_data.mission_id = activity_cfg.id
    new_mission_data.mission_type = activity_cfg.type
    new_mission_data.mission_state = MissionDef.ETaskState.NO_COMPLETE
    new_mission_data.beg_ts = activity_cfg.start_time or 0
    new_mission_data.end_ts = activity_cfg.end_time or 0

    -- 按活动类型分派构建任务数据
    Mission.BuildActivityMissionData(activity_cfg, new_mission_data)

    Mission.CheckNewMissionCond(new_mission_data)
    if new_mission_data.mission_state == MissionDef.ETaskState.COMPLETE then
        mission_info.activity_info.complete_ids[activity_cfg.id] = MissionDef.ETaskState.COMPLETE
        table.insert(new_complete_ids, activity_cfg.id)
    else
        mission_info.activity_info.now_mission_datas[activity_cfg.id] = new_mission_data
    end
end

function Mission.BuildActivityCondData(activity_cfg, new_mission_data, target_no)
    if activity_cfg[target_no] and activity_cfg[target_no] > 0 then
        local new_cond_data = MissionDef.newConditionData()
        new_cond_data.cond_id = activity_cfg[target_no]
        new_cond_data.target_value = activity_cfg[target_no .. "_data"]
        new_cond_data.now_value = 0
        new_cond_data.is_complete = 0
        if activity_cfg[target_no .. "_param1"] then
            table.insert(new_cond_data.params, activity_cfg[target_no .. "_param1"])
        end
        if activity_cfg[target_no .. "_param2"] then
            table.insert(new_cond_data.params, activity_cfg[target_no .. "_param2"])
        end
        if activity_cfg[target_no .. "_arr"] and table.size(activity_cfg[target_no .. "_arr"]) > 0 then
            new_cond_data.arr_params = activity_cfg[target_no .. "_arr"]
        end
        table.insert(new_mission_data.cond_datas, new_cond_data)
    end
end

function Mission.BuildActivityMissionData(activity_cfg, new_mission_data)
    local mission_type = activity_cfg.type
    if mission_type == MissionDef.ActivityMissionType.SEVEN_SIGN then
        -- 七日签到·灵宝阁：每日签到1次，累积签满7天
        Mission.BuildActivityCondData(activity_cfg, new_mission_data, "target1")
        Mission.BuildActivityCondData(activity_cfg, new_mission_data, "target2")
    elseif mission_type == MissionDef.ActivityMissionType.LEVEL_SPRINT then
        -- 道法精进·等级冲刺：账户等级达档位
        Mission.BuildActivityCondData(activity_cfg, new_mission_data, "target1")
        Mission.BuildActivityCondData(activity_cfg, new_mission_data, "target2")
    elseif mission_type == MissionDef.ActivityMissionType.SEVEN_TARGET then
        -- 天师下山·七日目标：完成任务积攒积分领档位
        Mission.BuildActivityCondData(activity_cfg, new_mission_data, "target1")
        Mission.BuildActivityCondData(activity_cfg, new_mission_data, "target2")
    elseif mission_type == MissionDef.ActivityMissionType.GHOST_GATE then
        -- 鬼门关·幽冥试炼：赛季制通关任务
        Mission.BuildActivityCondData(activity_cfg, new_mission_data, "target1")
        Mission.BuildActivityCondData(activity_cfg, new_mission_data, "target2")
    elseif mission_type == MissionDef.ActivityMissionType.GHOST_KING then
        -- 鬼王入侵·讨伐令：赛季制讨伐任务
        Mission.BuildActivityCondData(activity_cfg, new_mission_data, "target1")
        Mission.BuildActivityCondData(activity_cfg, new_mission_data, "target2")
    elseif mission_type == MissionDef.ActivityMissionType.DEMON_TOWER then
        -- 封魔塔·镇魔之路：赛季制层数冲刺
        Mission.BuildActivityCondData(activity_cfg, new_mission_data, "target1")
        Mission.BuildActivityCondData(activity_cfg, new_mission_data, "target2")
    else
        Mission.BuildActivityCondData(activity_cfg, new_mission_data, "target1")
        Mission.BuildActivityCondData(activity_cfg, new_mission_data, "target2")
    end
end

function Mission.CheckNewMissions()
    local mission_info = scripts.UserModel.GetMissionInfo()
    if not mission_info then
        return
    end

    local now_ts = moon.time()

    local new_complete_achivement_ids = {}
    Mission.CheckAchivementInfo(mission_info, now_ts, new_complete_achivement_ids)
    if table.size(new_complete_achivement_ids) > 0 then
        -- Mission.AchivementMissionComplete(mission_info, new_complete_achivement_ids)
        Mission.AchivementMissionComplete_new(mission_info, new_complete_achivement_ids, nil, false)
    end
    Mission.makeAchivementMap(mission_info)

    local new_complete_linear_ids = {}
    Mission.CheckLinearInfo(mission_info, now_ts, new_complete_linear_ids)
    if table.size(new_complete_linear_ids) > 0 then
        -- Mission.LinearMissionComplete(mission_info, new_complete_linear_ids)
        Mission.LinearMissionComplete_new(mission_info, new_complete_linear_ids, nil, false)
    end
    Mission.makeLinearMap(mission_info)

    local new_complete_period_ids = {}
    Mission.CheckPeriodInfo(mission_info, now_ts, new_complete_period_ids)
    if table.size(new_complete_period_ids) > 0 then
        -- Mission.PeriodMissionComplete(mission_info, new_complete_period_ids)
        Mission.PeriodMissionComplete_new(mission_info, new_complete_period_ids, nil, false)
    end
    Mission.makePeriodMap(mission_info)

    local new_complete_activity_ids = {}
    if Mission.CheckActivityInfo(mission_info, now_ts, new_complete_activity_ids) then
        if table.size(new_complete_activity_ids) > 0 then
            -- Mission.ActivityMissionComplete(mission_info, new_complete_activity_ids)
            Mission.ActivityMissionComplete_new(mission_info, new_complete_activity_ids, nil, false)
        end
        Mission.makeActivityMap(mission_info)
    end

    Mission.SaveMissionsNow()
end

function Mission.CheckLinearInfo(mission_info, now_ts, new_complete_linear_ids)
    mission_info.linear_info.last_check_ts = now_ts

    -- 清理已过期线性任务
    for mission_id, mission_data in pairs(mission_info.linear_info.now_mission_datas) do
        if mission_data.end_ts ~= 0 and now_ts >= mission_data.end_ts then
            mission_info.linear_info.now_mission_datas[mission_id] = nil
        end
    end

    -- 检查新线性任务
    local linear_cfgs = GameCfg.LinearMissionConfig
    if linear_cfgs and table.size(linear_cfgs) > 0 then
        for _, linear_cfg in pairs(linear_cfgs) do
            local need_new_mission = false
            if linear_cfg.unlock_level <= scripts.User.GetNowLevel()
                and (linear_cfg.start_time == 0 or now_ts >= linear_cfg.start_time)
                and (linear_cfg.end_time == 0 or now_ts < linear_cfg.end_time)
                and not mission_info.linear_info.now_mission_datas[linear_cfg.id]
                and not mission_info.linear_info.complete_ids[linear_cfg.id] then
                need_new_mission = true
                for _, need_complete_id in pairs(linear_cfg.front_mission) do
                    if not mission_info.linear_info.complete_ids[need_complete_id]
                        and not mission_info.achivement_info.complete_ids[need_complete_id] then
                        need_new_mission = false
                        break
                    end
                end
            end

            if need_new_mission then
                Mission.newLinearMission(mission_info, linear_cfg, now_ts, new_complete_linear_ids)
            end
        end
    end
end

function Mission.makeLinearMap(mission_info)
    Mission.linear_cond_map = {}
    for mission_id, mission_data in pairs(mission_info.linear_info.now_mission_datas) do
        for _, cond_data in pairs(mission_data.cond_datas) do
            if cond_data.is_complete == 0 then
                if not Mission.linear_cond_map[cond_data.cond_id] then
                    Mission.linear_cond_map[cond_data.cond_id] = {}
                end
                if not Mission.linear_cond_map[cond_data.cond_id][mission_id] then
                    Mission.linear_cond_map[cond_data.cond_id][mission_id] = mission_data
                end
            end
        end
    end
end

function Mission.CheckPeriodInfo(mission_info, now_ts, new_complete_period_ids)
    -- 尝试清理周期任务
    local day_fresh, week_fresh, month_fresh = false, false, false
    if not datetime.is_same_day(mission_info.period_info.last_update_ts, now_ts) then
        day_fresh = true

        mission_info.period_info.now_day_mission_datas = {}
        local delete_complete_ids = {}
        for mission_id, _ in pairs(mission_info.period_info.complete_day_ids) do
            local period_cfg = GameCfg.PeriodMissionConfig[mission_id]
            if period_cfg then
                -- 循环任务或随机任务（默认循环）周期结束后重置
                if period_cfg.is_loop == 1 or period_cfg.cyclical_type == 2 then
                    table.insert(delete_complete_ids, mission_id)
                end
            end
        end
        for _, mission_id in pairs(delete_complete_ids) do
            mission_info.period_info.complete_day_ids[mission_id] = nil
        end
    end
    if not datetime.is_same_week(mission_info.period_info.last_update_ts, now_ts) then
        week_fresh = true

        mission_info.period_info.now_week_mission_datas = {}
        local delete_complete_ids = {}
        for mission_id, _ in pairs(mission_info.period_info.complete_week_ids) do
            local period_cfg = GameCfg.PeriodMissionConfig[mission_id]
            if period_cfg then
                -- 循环任务或随机任务（默认循环）周期结束后重置
                if period_cfg.is_loop == 1 or period_cfg.cyclical_type == 2 then
                    table.insert(delete_complete_ids, mission_id)
                end
            end
        end
        for _, mission_id in pairs(delete_complete_ids) do
            mission_info.period_info.complete_week_ids[mission_id] = nil
        end
    end
    if not datetime.is_same_month(mission_info.period_info.last_update_ts, now_ts) then
        month_fresh = true

        mission_info.period_info.now_month_mission_datas = {}
        local delete_complete_ids = {}
        for mission_id, _ in pairs(mission_info.period_info.complete_month_ids) do
            local period_cfg = GameCfg.PeriodMissionConfig[mission_id]
            if period_cfg then
                -- 循环任务或随机任务（默认循环）周期结束后重置
                if period_cfg.is_loop == 1 or period_cfg.cyclical_type == 2 then
                    table.insert(delete_complete_ids, mission_id)
                end
            end
        end
        for _, mission_id in pairs(delete_complete_ids) do
            mission_info.period_info.complete_month_ids[mission_id] = nil
        end
    end

    if not day_fresh and not week_fresh and not month_fresh then
        return false
    end
    mission_info.period_info.last_update_ts = now_ts

    -- 检查新周期任务
    local period_cfgs = GameCfg.PeriodMissionConfig
    if period_cfgs and table.size(period_cfgs) > 0 then
        local random_day_ids, random_week_ids, random_month_ids = {}, {}, {}
        for _, period_cfg in pairs(period_cfgs) do
            if (period_cfg.cyclical_date == 1 and day_fresh)
                and period_cfg.unlock_level <= scripts.User.GetNowLevel()
                and (period_cfg.start_time == 0 or now_ts >= period_cfg.start_time)
                and (period_cfg.end_time == 0 or now_ts < period_cfg.end_time)
                and not mission_info.period_info.now_day_mission_datas[period_cfg.id]
                and not mission_info.period_info.complete_day_ids[period_cfg.id] then
                local need_new_mission = true
                for _, need_complete_id in pairs(period_cfg.front_mission) do
                    if not mission_info.linear_info.complete_ids[need_complete_id]
                        and not mission_info.achivement_info.complete_ids[need_complete_id] then
                        need_new_mission = false
                        break
                    end
                end

                if need_new_mission then
                    if period_cfg.cyclical_type == 1 then
                        Mission.newPeriodMission(mission_info, period_cfg, now_ts, new_complete_period_ids)
                    else
                        random_day_ids[period_cfg.id] = period_cfg.weight
                    end
                end
            elseif (period_cfg.cyclical_date == 2 and week_fresh)
                and period_cfg.unlock_level <= scripts.User.GetNowLevel()
                and (period_cfg.start_time == 0 or now_ts >= period_cfg.start_time)
                and (period_cfg.end_time == 0 or now_ts < period_cfg.end_time)
                and not mission_info.period_info.now_week_mission_datas[period_cfg.id]
                and not mission_info.period_info.complete_week_ids[period_cfg.id] then
                local need_new_mission = true
                for _, need_complete_id in pairs(period_cfg.front_mission) do
                    if not mission_info.linear_info.complete_ids[need_complete_id]
                        and not mission_info.achivement_info.complete_ids[need_complete_id] then
                        need_new_mission = false
                        break
                    end
                end

                if need_new_mission then
                    if period_cfg.cyclical_type == 1 then
                        Mission.newPeriodMission(mission_info, period_cfg, now_ts, new_complete_period_ids)
                    else
                        random_week_ids[period_cfg.id] = period_cfg.weight
                    end
                end
            elseif (period_cfg.cyclical_date == 3 and month_fresh)
                and period_cfg.unlock_level <= scripts.User.GetNowLevel()
                and (period_cfg.start_time == 0 or now_ts >= period_cfg.start_time)
                and (period_cfg.end_time == 0 or now_ts < period_cfg.end_time)
                and not mission_info.period_info.now_month_mission_datas[period_cfg.id]
                and not mission_info.period_info.complete_month_ids[period_cfg.id] then
                local need_new_mission = true
                for _, need_complete_id in pairs(period_cfg.front_mission) do
                    if not mission_info.linear_info.complete_ids[need_complete_id]
                        and not mission_info.achivement_info.complete_ids[need_complete_id] then
                        need_new_mission = false
                        break
                    end
                end

                if need_new_mission then
                    if period_cfg.cyclical_type == 1 then
                        Mission.newPeriodMission(mission_info, period_cfg, now_ts, new_complete_period_ids)
                    else
                        random_month_ids[period_cfg.id] = period_cfg.weight
                    end
                end
            end
        end

        if table.size(random_day_ids) > 0 then
            local daily_cfg = CommonCfgDef.getConf("DailyTaskCount")
            if not daily_cfg or not daily_cfg.value then
                moon.error("CommonCfgDef.getConf DailyTaskCount err")
            else
                if table.size(random_day_ids) > daily_cfg.value then
                    for i = 1, daily_cfg.value do
                        local random_id = scripts.Item.RangeTags(random_day_ids)
                        if random_id > 0 then
                            local period_cfg = GameCfg.PeriodMissionConfig[random_id]
                            if period_cfg then
                                Mission.newPeriodMission(mission_info, period_cfg, now_ts, new_complete_period_ids)
                            end
                            random_day_ids[random_id] = nil
                        end
                    end
                else
                    for id, _ in pairs(random_day_ids) do
                        local period_cfg = GameCfg.PeriodMissionConfig[id]
                        if period_cfg then
                            Mission.newPeriodMission(mission_info, period_cfg, now_ts, new_complete_period_ids)
                        end
                    end
                end
            end
        end

        if table.size(random_week_ids) > 0 then
            local week_cfg = CommonCfgDef.getConf("WeeklyTaskCount")
            if not week_cfg or not week_cfg.value then
                moon.error("CommonCfgDef.getConf WeeklyTaskCount err")
            else
                if table.size(random_week_ids) > week_cfg.value then
                    for i = 1, week_cfg.value do
                        local random_id = scripts.Item.RangeTags(random_week_ids)
                        if random_id > 0 then
                            local period_cfg = GameCfg.PeriodMissionConfig[random_id]
                            if period_cfg then
                                Mission.newPeriodMission(mission_info, period_cfg, now_ts, new_complete_period_ids)
                            end
                            random_week_ids[random_id] = nil
                        end
                    end
                else
                    for id, _ in pairs(random_week_ids) do
                        local period_cfg = GameCfg.PeriodMissionConfig[id]
                        if period_cfg then
                            Mission.newPeriodMission(mission_info, period_cfg, now_ts, new_complete_period_ids)
                        end
                    end
                end
            end
        end

        -- 每月随机任务（随机任务数量不足时终止随机，仅添加满足条件的任务）
        if table.size(random_month_ids) > 0 then
            local month_cfg = CommonCfgDef.getConf("MonthlyTaskCount")
            if not month_cfg or not month_cfg.value then
                moon.error("CommonCfgDef.getConf MonthlyTaskCount err")
            else
                if table.size(random_month_ids) > month_cfg.value then
                    for i = 1, month_cfg.value do
                        local random_id = scripts.Item.RangeTags(random_month_ids)
                        if random_id > 0 then
                            local period_cfg = GameCfg.PeriodMissionConfig[random_id]
                            if period_cfg then
                                Mission.newPeriodMission(mission_info, period_cfg, now_ts, new_complete_period_ids)
                            end
                            random_month_ids[random_id] = nil
                        end
                    end
                else
                    for id, _ in pairs(random_month_ids) do
                        local period_cfg = GameCfg.PeriodMissionConfig[id]
                        if period_cfg then
                            Mission.newPeriodMission(mission_info, period_cfg, now_ts, new_complete_period_ids)
                        end
                    end
                end
            end
        end
    end

    return true
end

function Mission.makePeriodMap(mission_info)
    Mission.period_cond_map = {}
    for mission_id, mission_data in pairs(mission_info.period_info.now_day_mission_datas) do
        for _, cond_data in pairs(mission_data.cond_datas) do
            if cond_data.is_complete == 0 then
                if not Mission.period_cond_map[cond_data.cond_id] then
                    Mission.period_cond_map[cond_data.cond_id] = {}
                end
                if not Mission.period_cond_map[cond_data.cond_id][mission_id] then
                    Mission.period_cond_map[cond_data.cond_id][mission_id] = mission_data
                end
            end
        end
    end
    for mission_id, mission_data in pairs(mission_info.period_info.now_week_mission_datas) do
        for _, cond_data in pairs(mission_data.cond_datas) do
            if cond_data.is_complete == 0 then
                if not Mission.period_cond_map[cond_data.cond_id] then
                    Mission.period_cond_map[cond_data.cond_id] = {}
                end
                if not Mission.period_cond_map[cond_data.cond_id][mission_id] then
                    Mission.period_cond_map[cond_data.cond_id][mission_id] = mission_data
                end
            end
        end
    end
    for mission_id, mission_data in pairs(mission_info.period_info.now_month_mission_datas) do
        for _, cond_data in pairs(mission_data.cond_datas) do
            if cond_data.is_complete == 0 then
                if not Mission.period_cond_map[cond_data.cond_id] then
                    Mission.period_cond_map[cond_data.cond_id] = {}
                end
                if not Mission.period_cond_map[cond_data.cond_id][mission_id] then
                    Mission.period_cond_map[cond_data.cond_id][mission_id] = mission_data
                end
            end
        end
    end
end

function Mission.CheckAchivementInfo(mission_info, now_ts, new_complete_achivement_ids)
    -- 检查新成就任务
    local achivement_cfgs = GameCfg.AchievementMissionConfig
    if achivement_cfgs and table.size(achivement_cfgs) > 0 then
        for _, achivement_cfg in pairs(achivement_cfgs) do
            if not mission_info.achivement_info.now_mission_datas[achivement_cfg.id]
                and not mission_info.achivement_info.complete_ids[achivement_cfg.id] then
                Mission.newAchivementMission(mission_info, achivement_cfg, now_ts, new_complete_achivement_ids)
            end
        end
    end
end

function Mission.makeAchivementMap(mission_info)
    Mission.achivement_cond_map = {}
    for mission_id, mission_data in pairs(mission_info.achivement_info.now_mission_datas) do
        for _, cond_data in pairs(mission_data.cond_datas) do
            if cond_data.is_complete == 0 then
                if not Mission.achivement_cond_map[cond_data.cond_id] then
                    Mission.achivement_cond_map[cond_data.cond_id] = {}
                end
                if not Mission.achivement_cond_map[cond_data.cond_id][mission_id] then
                    Mission.achivement_cond_map[cond_data.cond_id][mission_id] = mission_data
                end
            end
        end
    end
end

function Mission.JustCheckCondition(mission_info, condition_id, params, change_cnt, change_log,
                                new_complete_achivement_ids, new_complete_linear_ids, new_complete_period_ids)

    if Mission.achivement_cond_map and Mission.achivement_cond_map[condition_id] then
        local change_tasks = MissionLogic.CheckTask(condition_id, params, change_cnt,
            Mission.achivement_cond_map[condition_id])
        if table.size(change_tasks) > 0 then
            for _, mission_id in pairs(change_tasks) do
                local mission_data = mission_info.achivement_info.now_mission_datas[mission_id]
                if mission_data then
                    local mission_complete = true
                    for _, cond_data in pairs(mission_data.cond_datas) do
                        if cond_data.is_complete == 0 then
                            mission_complete = false
                            break
                        end
                    end
                    if mission_complete then
                        mission_data.mission_state = MissionDef.ETaskState.COMPLETE

                        mission_info.achivement_info.complete_ids[mission_id] = MissionDef.ETaskState.COMPLETE
                        mission_info.achivement_info.now_mission_datas[mission_id] = nil
                        if Mission.achivement_cond_map[condition_id]
                            and Mission.achivement_cond_map[condition_id][mission_id] then
                            Mission.achivement_cond_map[condition_id][mission_id] = nil
                        end
                        table.insert(new_complete_achivement_ids, mission_id)
                        change_log.achivements[mission_id] = MissionDef.ETaskState.COMPLETE
                    else
                        change_log.achivements[mission_id] = MissionDef.ETaskState.NO_COMPLETE
                    end
                end
            end
        end
    end

    -- 检查线性任务
    if Mission.linear_cond_map and Mission.linear_cond_map[condition_id] then
        local change_tasks = MissionLogic.CheckTask(condition_id, params, change_cnt,
            Mission.linear_cond_map[condition_id])
        if table.size(change_tasks) > 0 then
            for _, mission_id in pairs(change_tasks) do
                local mission_data = mission_info.linear_info.now_mission_datas[mission_id]
                if mission_data then
                    local mission_complete = true
                    for _, cond_data in pairs(mission_data.cond_datas) do
                        if cond_data.is_complete == 0 then
                            mission_complete = false
                            break
                        end
                    end
                    if mission_complete then
                        mission_data.mission_state = MissionDef.ETaskState.COMPLETE

                        mission_info.linear_info.complete_ids[mission_id] = MissionDef.ETaskState.COMPLETE
                        mission_info.linear_info.now_mission_datas[mission_id] = nil
                        if Mission.linear_cond_map[condition_id]
                            and Mission.linear_cond_map[condition_id][mission_id] then
                            Mission.linear_cond_map[condition_id][mission_id] = nil
                        end
                        table.insert(new_complete_linear_ids, mission_id)
                        change_log.linears[mission_id] = MissionDef.ETaskState.COMPLETE
                    else
                        change_log.linears[mission_id] = MissionDef.ETaskState.NO_COMPLETE
                    end
                end
            end
        end
    end

    -- 检查周期任务
    if Mission.period_cond_map and Mission.period_cond_map[condition_id] then
        local change_tasks = MissionLogic.CheckTask(condition_id, params, change_cnt,
            Mission.period_cond_map[condition_id])
        if table.size(change_tasks) > 0 then
            for _, mission_id in pairs(change_tasks) do
                if mission_info.period_info.now_day_mission_datas[mission_id] then
                    local mission_data = mission_info.period_info.now_day_mission_datas[mission_id]
                    if mission_data then
                        local mission_complete = true
                        for _, cond_data in pairs(mission_data.cond_datas) do
                            if cond_data.is_complete == 0 then
                                mission_complete = false
                                break
                            end
                        end
                        if mission_complete then
                            mission_data.mission_state = MissionDef.ETaskState.COMPLETE

                            mission_info.period_info.complete_day_ids[mission_id] = MissionDef.ETaskState.COMPLETE
                            mission_info.period_info.now_day_mission_datas[mission_id] = nil
                            if Mission.period_cond_map[condition_id]
                                and Mission.period_cond_map[condition_id][mission_id] then
                                Mission.period_cond_map[condition_id][mission_id] = nil
                            end
                            table.insert(new_complete_period_ids, mission_id)
                            change_log.periods[mission_id] = MissionDef.ETaskState.COMPLETE
                        else
                            change_log.periods[mission_id] = MissionDef.ETaskState.NO_COMPLETE
                        end
                    end
                elseif mission_info.period_info.now_week_mission_datas[mission_id] then
                    local mission_data = mission_info.period_info.now_week_mission_datas[mission_id]
                    if mission_data then
                        local mission_complete = true
                        for _, cond_data in pairs(mission_data.cond_datas) do
                            if cond_data.is_complete == 0 then
                                mission_complete = false
                                break
                            end
                        end
                        if mission_complete then
                            mission_data.mission_state = MissionDef.ETaskState.COMPLETE

                            mission_info.period_info.complete_week_ids[mission_id] = MissionDef.ETaskState.COMPLETE
                            mission_info.period_info.now_week_mission_datas[mission_id] = nil
                            if Mission.period_cond_map[condition_id]
                                and Mission.period_cond_map[condition_id][mission_id] then
                                Mission.period_cond_map[condition_id][mission_id] = nil
                            end
                            table.insert(new_complete_period_ids, mission_id)
                            change_log.periods[mission_id] = MissionDef.ETaskState.COMPLETE
                        else
                            change_log.periods[mission_id] = MissionDef.ETaskState.NO_COMPLETE
                        end
                    end
                elseif mission_info.period_info.now_month_mission_datas[mission_id] then
                    local mission_data = mission_info.period_info.now_month_mission_datas[mission_id]
                    if mission_data then
                        local mission_complete = true
                        for _, cond_data in pairs(mission_data.cond_datas) do
                            if cond_data.is_complete == 0 then
                                mission_complete = false
                                break
                            end
                        end
                        if mission_complete then
                            mission_data.mission_state = MissionDef.ETaskState.COMPLETE

                            mission_info.period_info.complete_month_ids[mission_id] = MissionDef.ETaskState.COMPLETE
                            mission_info.period_info.now_month_mission_datas[mission_id] = nil
                            if Mission.period_cond_map[condition_id]
                                and Mission.period_cond_map[condition_id][mission_id] then
                                Mission.period_cond_map[condition_id][mission_id] = nil
                            end
                            table.insert(new_complete_period_ids, mission_id)
                            change_log.periods[mission_id] = MissionDef.ETaskState.COMPLETE
                        else
                            change_log.periods[mission_id] = MissionDef.ETaskState.NO_COMPLETE
                        end
                    end
                end
            end
        end
    end

    scripts.UserModel.SetMissionInfo(mission_info)
end

function Mission.IsActivityTypeOpen(activity_type)
    local type_cfgs = GameCfg.ActivityMissionTypeConfig
    if not type_cfgs then
        return true
    end
    local type_cfg = type_cfgs[activity_type]
    if not type_cfg then
        return true
    end
    return type_cfg.type == 1
end

function Mission.CheckActivityInfo(mission_info, now_ts, new_complete_activity_ids)
    local activity_cfgs = GameCfg.ActivityMissionConfig
    if not activity_cfgs or table.size(activity_cfgs) <= 0 then
        return false
    end

    -- 清理已过期的活动任务
    for mission_id, mission_data in pairs(mission_info.activity_info.now_mission_datas) do
        if mission_data.end_ts ~= 0 and now_ts >= mission_data.end_ts then
            mission_info.activity_info.now_mission_datas[mission_id] = nil
        end
    end

    -- 检查新活动任务
    local is_change = false
    for _, activity_cfg in pairs(activity_cfgs) do
        -- 类型未开启：移除该类型未完成任务
        if not Mission.IsActivityTypeOpen(activity_cfg.type) then
            if mission_info.activity_info.now_mission_datas[activity_cfg.id] then
                mission_info.activity_info.now_mission_datas[activity_cfg.id] = nil
                is_change = true
            end
        elseif not mission_info.activity_info.now_mission_datas[activity_cfg.id]
            and not mission_info.activity_info.complete_ids[activity_cfg.id] then
            if (activity_cfg.start_time == 0 or now_ts >= activity_cfg.start_time)
                and (activity_cfg.end_time == 0 or now_ts < activity_cfg.end_time) then
                Mission.newActivityMission(mission_info, activity_cfg, now_ts, new_complete_activity_ids)
                is_change = true
            end
        end
    end

    mission_info.activity_info.last_update_ts = now_ts
    return is_change
end

function Mission.makeActivityMap(mission_info)
    Mission.activity_cond_map = {}
    for mission_id, mission_data in pairs(mission_info.activity_info.now_mission_datas) do
        -- 类型未开启的任务不加入条件映射
        if Mission.IsActivityTypeOpen(mission_data.mission_type) then
            for _, cond_data in pairs(mission_data.cond_datas) do
                if cond_data.is_complete == 0 then
                    if not Mission.activity_cond_map[cond_data.cond_id] then
                        Mission.activity_cond_map[cond_data.cond_id] = {}
                    end
                    if not Mission.activity_cond_map[cond_data.cond_id][mission_id] then
                        Mission.activity_cond_map[cond_data.cond_id][mission_id] = mission_data
                    end
                end
            end
        end
    end
end

function Mission.TriggerCondition(condition_id, params, change_cnt)
end

function Mission.TriggerCondition_old(condition_id, params, change_cnt)
    local mission_info = scripts.UserModel.GetMissionInfo()
    if not mission_info then
        return false
    end

    local change_log = {
        linears = {},
        periods = {},
        achivements = {},
        activitys = {},
        periods_all_change = false,
        activitys_all_change = false,
    }
    local now_ts = moon.time()

    -- 定期检查活动任务整体变化（新增/清理/类型开关变化），有变化则整包同步
    local new_check_activity_ids = {}
    if not mission_info.activity_info.last_update_ts
        or mission_info.activity_info.last_update_ts + 60 < now_ts then
        if Mission.CheckActivityInfo(mission_info, now_ts, new_check_activity_ids) then
            if table.size(new_check_activity_ids) > 0 then
                Mission.ActivityMissionComplete(mission_info, new_check_activity_ids)
            end
            Mission.makeActivityMap(mission_info)
            change_log.activitys_all_change = true
        end
    end

    local new_complete_achivement_ids = {}
    if Mission.achivement_cond_map and Mission.achivement_cond_map[condition_id] then
        local change_tasks = MissionLogic.CheckTask(condition_id, params, change_cnt,
            Mission.achivement_cond_map[condition_id])
        if table.size(change_tasks) > 0 then
            for _, mission_id in pairs(change_tasks) do
                local mission_data = mission_info.achivement_info.now_mission_datas[mission_id]
                if mission_data then
                    local mission_complete = true
                    for _, cond_data in pairs(mission_data.cond_datas) do
                        if cond_data.is_complete == 0 then
                            mission_complete = false
                            break
                        end
                    end
                    if mission_complete then
                        mission_data.mission_state = MissionDef.ETaskState.COMPLETE

                        mission_info.achivement_info.complete_ids[mission_id] = MissionDef.ETaskState.COMPLETE
                        mission_info.achivement_info.now_mission_datas[mission_id] = nil
                        if Mission.achivement_cond_map[condition_id]
                            and Mission.achivement_cond_map[condition_id][mission_id] then
                            Mission.achivement_cond_map[condition_id][mission_id] = nil
                        end
                        table.insert(new_complete_achivement_ids, mission_id)
                        change_log.achivements[mission_id] = MissionDef.ETaskState.COMPLETE
                    else
                        change_log.achivements[mission_id] = MissionDef.ETaskState.NO_COMPLETE
                    end
                end
            end
        end
    end
    if table.size(new_complete_achivement_ids) > 0 then
        Mission.AchivementMissionComplete(mission_info, new_complete_achivement_ids)
    end

    -- 检查活动任务
    local new_complete_activity_ids = {}
    if Mission.activity_cond_map and Mission.activity_cond_map[condition_id] then
        local change_tasks = MissionLogic.CheckTask(condition_id, params, change_cnt,
            Mission.activity_cond_map[condition_id])
        if table.size(change_tasks) > 0 then
            for _, mission_id in pairs(change_tasks) do
                local mission_data = mission_info.activity_info.now_mission_datas[mission_id]
                if mission_data then
                    local mission_complete = true
                    for _, cond_data in pairs(mission_data.cond_datas) do
                        if cond_data.is_complete == 0 then
                            mission_complete = false
                            break
                        end
                    end
                    if mission_complete then
                        mission_data.mission_state = MissionDef.ETaskState.COMPLETE

                        mission_info.activity_info.complete_ids[mission_id] = MissionDef.ETaskState.COMPLETE
                        mission_info.activity_info.now_mission_datas[mission_id] = nil
                        if Mission.activity_cond_map[condition_id]
                            and Mission.activity_cond_map[condition_id][mission_id] then
                            Mission.activity_cond_map[condition_id][mission_id] = nil
                        end
                        table.insert(new_complete_activity_ids, mission_id)
                        change_log.activitys[mission_id] = MissionDef.ETaskState.COMPLETE
                    else
                        change_log.activitys[mission_id] = MissionDef.ETaskState.NO_COMPLETE
                    end
                end
            end
        end
    end
    if table.size(new_complete_activity_ids) > 0 then
        Mission.ActivityMissionComplete(mission_info, new_complete_activity_ids)
    end

    -- 检查未开始的线性任务
    local new_complete_linear_ids = {}
    if mission_info.linear_info.last_check_ts + 60 < now_ts then
        for mission_id, mission_data in pairs(mission_info.linear_info.wait_beg_mission_datas) do
            if (mission_data.beg_ts == 0 or now_ts >= mission_data.beg_ts)
             and (mission_data.end_ts == 0 or now_ts < mission_data.end_ts) then
                Mission.CheckNewMissionCond(mission_data)
                if mission_data.mission_state == MissionDef.ETaskState.COMPLETE then
                    mission_info.linear_info.complete_ids[mission_id] = MissionDef.ETaskState.COMPLETE
                    table.insert(new_complete_linear_ids, mission_id)
                    change_log.linears[mission_id] = MissionDef.ETaskState.COMPLETE
                else
                    mission_info.linear_info.now_mission_datas[mission_id] = mission_data
                    change_log.linears[mission_id] = MissionDef.ETaskState.NO_COMPLETE
                end
                mission_info.linear_info.now_mission_datas[mission_id] = mission_data
                mission_info.linear_info.wait_beg_mission_datas[mission_id] = nil
                for _, cond_data in pairs(mission_data.cond_datas) do
                    if cond_data.is_complete == 0 then
                        if not Mission.linear_cond_map[cond_data.cond_id] then
                            Mission.linear_cond_map[cond_data.cond_id] = {}
                        end
                        if not Mission.linear_cond_map[cond_data.cond_id][mission_id] then
                            Mission.linear_cond_map[cond_data.cond_id][mission_id] = mission_data
                        end
                    end
                end
            elseif mission_data.end_ts ~= 0 and now_ts >= mission_data.end_ts then
                mission_info.linear_info.wait_beg_mission_datas[mission_id] = nil
                change_log.linears[mission_id] = MissionDef.ETaskState.NO_PROGRESS
            end
        end

        mission_info.linear_info.last_check_ts = now_ts
    end
    -- 检查线性任务
    if Mission.linear_cond_map and Mission.linear_cond_map[condition_id] then
        local change_tasks = MissionLogic.CheckTask(condition_id, params, change_cnt,
            Mission.linear_cond_map[condition_id])
        if table.size(change_tasks) > 0 then
            for _, mission_id in pairs(change_tasks) do
                local mission_data = mission_info.linear_info.now_mission_datas[mission_id]
                if mission_data then
                    local mission_complete = true
                    for _, cond_data in pairs(mission_data.cond_datas) do
                        if cond_data.is_complete == 0 then
                            mission_complete = false
                            break
                        end
                    end
                    if mission_complete then
                        mission_data.mission_state = MissionDef.ETaskState.COMPLETE

                        mission_info.linear_info.complete_ids[mission_id] = MissionDef.ETaskState.COMPLETE
                        mission_info.linear_info.now_mission_datas[mission_id] = nil
                        if Mission.linear_cond_map[condition_id]
                            and Mission.linear_cond_map[condition_id][mission_id] then
                            Mission.linear_cond_map[condition_id][mission_id] = nil
                        end
                        table.insert(new_complete_linear_ids, mission_id)
                        change_log.linears[mission_id] = MissionDef.ETaskState.COMPLETE
                    else
                        change_log.linears[mission_id] = MissionDef.ETaskState.NO_COMPLETE
                    end
                end
            end
        end
    end
    if table.size(new_complete_linear_ids) > 0 then
        Mission.LinearMissionComplete(mission_info, new_complete_linear_ids)
    end

    -- 检查周期是否刷新
    local new_complete_period_ids = {}
    if Mission.CheckPeriodInfo(mission_info, now_ts, new_complete_period_ids) then
        Mission.makePeriodMap(mission_info)
        change_log.periods_all_change = true
    end
    -- 检查周期任务
    if Mission.period_cond_map and Mission.period_cond_map[condition_id] then
        local change_tasks = MissionLogic.CheckTask(condition_id, params, change_cnt,
            Mission.period_cond_map[condition_id])
        if table.size(change_tasks) > 0 then
            for _, mission_id in pairs(change_tasks) do
                if mission_info.period_info.now_day_mission_datas[mission_id] then
                    local mission_data = mission_info.period_info.now_day_mission_datas[mission_id]
                    if mission_data then
                        local mission_complete = true
                        for _, cond_data in pairs(mission_data.cond_datas) do
                            if cond_data.is_complete == 0 then
                                mission_complete = false
                                break
                            end
                        end
                        if mission_complete then
                            mission_data.mission_state = MissionDef.ETaskState.COMPLETE

                            mission_info.period_info.complete_day_ids[mission_id] = MissionDef.ETaskState.COMPLETE
                            mission_info.period_info.now_day_mission_datas[mission_id] = nil
                            if Mission.period_cond_map[condition_id]
                                and Mission.period_cond_map[condition_id][mission_id] then
                                Mission.period_cond_map[condition_id][mission_id] = nil
                            end
                            table.insert(new_complete_period_ids, mission_id)
                            change_log.periods[mission_id] = MissionDef.ETaskState.COMPLETE
                        else
                            change_log.periods[mission_id] = MissionDef.ETaskState.NO_COMPLETE
                        end
                    end
                elseif mission_info.period_info.now_week_mission_datas[mission_id] then
                    local mission_data = mission_info.period_info.now_week_mission_datas[mission_id]
                    if mission_data then
                        local mission_complete = true
                        for _, cond_data in pairs(mission_data.cond_datas) do
                            if cond_data.is_complete == 0 then
                                mission_complete = false
                                break
                            end
                        end
                        if mission_complete then
                            mission_data.mission_state = MissionDef.ETaskState.COMPLETE

                            mission_info.period_info.complete_week_ids[mission_id] = MissionDef.ETaskState.COMPLETE
                            mission_info.period_info.now_week_mission_datas[mission_id] = nil
                            if Mission.period_cond_map[condition_id]
                                and Mission.period_cond_map[condition_id][mission_id] then
                                Mission.period_cond_map[condition_id][mission_id] = nil
                            end
                            table.insert(new_complete_period_ids, mission_id)
                            change_log.periods[mission_id] = MissionDef.ETaskState.COMPLETE
                        else
                            change_log.periods[mission_id] = MissionDef.ETaskState.NO_COMPLETE
                        end
                    end
                elseif mission_info.period_info.now_month_mission_datas[mission_id] then
                    local mission_data = mission_info.period_info.now_month_mission_datas[mission_id]
                    if mission_data then
                        local mission_complete = true
                        for _, cond_data in pairs(mission_data.cond_datas) do
                            if cond_data.is_complete == 0 then
                                mission_complete = false
                                break
                            end
                        end
                        if mission_complete then
                            mission_data.mission_state = MissionDef.ETaskState.COMPLETE

                            mission_info.period_info.complete_month_ids[mission_id] = MissionDef.ETaskState.COMPLETE
                            mission_info.period_info.now_month_mission_datas[mission_id] = nil
                            if Mission.period_cond_map[condition_id]
                                and Mission.period_cond_map[condition_id][mission_id] then
                                Mission.period_cond_map[condition_id][mission_id] = nil
                            end
                            table.insert(new_complete_period_ids, mission_id)
                            change_log.periods[mission_id] = MissionDef.ETaskState.COMPLETE
                        else
                            change_log.periods[mission_id] = MissionDef.ETaskState.NO_COMPLETE
                        end
                    end
                end
            end
        end
    end
    if table.size(new_complete_period_ids) > 0 then
        Mission.PeriodMissionComplete(mission_info, new_complete_period_ids, change_log)
    end

    Mission.SaveAndSync(change_log)

    return true
end

---
-- 新增: 循环驱动版 (解除 TriggerCondition <-> XxxComplete 的互递归).
-- 用 while 队列替代嵌套递归, 复用 JustCheckCondition 原子推进单个条件,
-- 完成项由 enqueue_followups 入队其连锁条件/解锁, 最后只 SaveAndSync 一次.
-- 与 Mission.TriggerCondition 行为等价, 供阅读/对比用.
function Mission.TriggerCondition_new(condition_id, params, change_cnt)
    local mission_info = scripts.UserModel.GetMissionInfo()
    if not mission_info then
        return
    end

    local change_log = {
        linears = {},
        periods = {},
        achivements = {},
        activitys = {},
        periods_all_change = false,
        activitys_all_change = false,
    }
    local now_ts = moon.time()

    -- 累积本次调用里所有"完成"的任务, 用于驱动连锁:
    --   成就完成 -> ACHIEVEMENT_CNT
    --   线性完成 -> OUT_TASK_CNT + 解锁后继任务
    --   周期完成 -> OUT_TASK_CNT
    local new_complete_achivement_ids = {}
    local new_complete_linear_ids = {}
    local new_complete_period_ids = {}

    -- 去重集合: 防止同一任务被重复入队 / 重复触发连锁
    local completed = {}

    local function mark(cat, id)
        local key = cat .. ":" .. id
        if completed[key] then
            return false
        end
        completed[key] = true
        return true
    end

    -- 已消费完成的偏移: 让 enqueue_followups 每次只扫描本次"新增"的完成项,
    -- 避免每 pop 一个队列条目就全量遍历累计表(O(M*N) -> O(N)).
    local done_ach, done_lin, done_per = 0, 0, 0

    -- 工作队列: 用循环替代 TriggerCondition <-> XxxComplete 的互递归调用,
    -- 避免嵌套 SaveAndSync 造成重复同步/重复落库, 以及深层递归耗尽协程栈.
    -- 队列条目:
    --   {cond_id=, params=, change_cnt=}   处理一个条件 (交给 JustCheckCondition)
    --   {unlock=true, id=}                 解锁某线性任务的后继
    local queue = {}

    -- 把三类完成列表里的新完成任务入队其连锁条件/解锁
    local function enqueue_followups()
        -- 只扫描本次"新增"的完成项: 偏移量记录上次已消费到的位置,
        -- 每个条目最多被遍历一次, 将 O(M*N) 降为 O(N). 保留 mark 做防御性去重.
        for i = done_ach + 1, #new_complete_achivement_ids do
            local mission_id = new_complete_achivement_ids[i]
            if mark("ach", mission_id) then
                local cfg = GameCfg.AchievementMissionConfig[mission_id]
                if cfg and cfg.type then
                    table.insert(queue, {
                        cond_id = MissionDef.EConditionIds.ACHIEVEMENT_CNT,
                        params = { cfg.type, mission_id },
                        change_cnt = 1,
                    })
                end
            end
        end
        done_ach = #new_complete_achivement_ids
        for i = done_lin + 1, #new_complete_linear_ids do
            local mission_id = new_complete_linear_ids[i]
            if mark("lin", mission_id) then
                local cfg = GameCfg.LinearMissionConfig[mission_id]
                if cfg and cfg.type then
                    table.insert(queue, {
                        cond_id = MissionDef.EConditionIds.OUT_TASK_CNT,
                        params = { cfg.type, mission_id },
                        change_cnt = 1,
                    })
                end
                table.insert(queue, { unlock = true, id = mission_id })
            end
        end
        done_lin = #new_complete_linear_ids
        for i = done_per + 1, #new_complete_period_ids do
            local mission_id = new_complete_period_ids[i]
            if mark("per", mission_id) then
                local cfg = GameCfg.PeriodMissionConfig[mission_id]
                if cfg and cfg.type then
                    table.insert(queue, {
                        cond_id = MissionDef.EConditionIds.OUT_TASK_CNT,
                        params = { cfg.type, mission_id },
                        change_cnt = 1,
                    })
                end
            end
        end
        done_per = #new_complete_period_ids
    end

    -- 解锁某线性任务的后继 (back_mission). 复用 newLinearMission, 立即完成的后继会
    -- 塞进 new_complete_linear_ids, 再由 enqueue_followups 继续驱动连锁.
    local function handle_linear_unlock(mission_id)
        local linear_cfgs = GameCfg.LinearMissionConfig
        if not linear_cfgs or table.size(linear_cfgs) == 0 then
            return
        end
        local linear_cfg = linear_cfgs[mission_id]
        if not linear_cfg or linear_cfg.back_mission <= 0 then
            return
        end
        -- 防止配置成环: 同一后继只解锁一次
        if not mark("ulock", linear_cfg.back_mission) then
            return
        end
        local new_linear_cfg = linear_cfgs[linear_cfg.back_mission]
        if not new_linear_cfg then
            return
        end
        if new_linear_cfg.unlock_level > scripts.User.GetNowLevel() then
            return
        end
        if new_linear_cfg.start_time ~= 0 and now_ts < new_linear_cfg.start_time then
            return
        end
        if new_linear_cfg.end_time ~= 0 and now_ts >= new_linear_cfg.end_time then
            return
        end
        if mission_info.linear_info.now_mission_datas[new_linear_cfg.id] then
            return
        end
        if mission_info.linear_info.complete_ids[new_linear_cfg.id] then
            return
        end
        local can_new_mission = true
        for _, need_complete_id in pairs(new_linear_cfg.front_mission) do
            if not mission_info.linear_info.complete_ids[need_complete_id]
                and not mission_info.achivement_info.complete_ids[need_complete_id] then
                can_new_mission = false
                break
            end
        end
        if not can_new_mission then
            return
        end
        Mission.newLinearMission(mission_info, new_linear_cfg, now_ts, new_complete_linear_ids, change_log)
        -- 新增的完成项由入队后的 enqueue_followups 驱动
    end

    -- 未开始的线性任务检查 (每个 TriggerConditionV2 调用仅执行一次)
    if mission_info.linear_info.last_check_ts + 60 < now_ts then
        for mission_id, mission_data in pairs(mission_info.linear_info.wait_beg_mission_datas) do
            if (mission_data.beg_ts == 0 or now_ts >= mission_data.beg_ts)
                and (mission_data.end_ts == 0 or now_ts < mission_data.end_ts) then
                Mission.CheckNewMissionCond(mission_data)
                if mission_data.mission_state == MissionDef.ETaskState.COMPLETE then
                    mission_info.linear_info.complete_ids[mission_id] = MissionDef.ETaskState.COMPLETE
                    table.insert(new_complete_linear_ids, mission_id)
                    change_log.linears[mission_id] = MissionDef.ETaskState.COMPLETE
                else
                    mission_info.linear_info.now_mission_datas[mission_id] = mission_data
                    change_log.linears[mission_id] = MissionDef.ETaskState.NO_COMPLETE
                end
                mission_info.linear_info.now_mission_datas[mission_id] = mission_data
                mission_info.linear_info.wait_beg_mission_datas[mission_id] = nil
                for _, cond_data in pairs(mission_data.cond_datas) do
                    if cond_data.is_complete == 0 then
                        if not Mission.linear_cond_map[cond_data.cond_id] then
                            Mission.linear_cond_map[cond_data.cond_id] = {}
                        end
                        if not Mission.linear_cond_map[cond_data.cond_id][mission_id] then
                            Mission.linear_cond_map[cond_data.cond_id][mission_id] = mission_data
                        end
                    end
                end
            elseif mission_data.end_ts ~= 0 and now_ts >= mission_data.end_ts then
                mission_info.linear_info.wait_beg_mission_datas[mission_id] = nil
                change_log.linears[mission_id] = MissionDef.ETaskState.NO_PROGRESS
            end
        end
        mission_info.linear_info.last_check_ts = now_ts
    end

    -- 周期刷新检查: 只在跨天/跨周/跨月时才真正刷新. 放在循环前一次执行,
    -- 顶出的已完成周期任务纳入 new_complete_period_ids, 由 enqueue_followups 连锁.
    if Mission.CheckPeriodInfo(mission_info, now_ts, new_complete_period_ids) then
        Mission.makePeriodMap(mission_info)
        change_log.periods_all_change = true
    end

    scripts.UserModel.SetMissionInfo(mission_info)

    -- 初始条件入队
    table.insert(queue, { cond_id = condition_id, params = params or {}, change_cnt = change_cnt or 1 })

    -- 主事件循环: 每 pop 一个事件用 JustCheckCondition 原子推进条件, 收集新完成任务,
    -- 再 enqueue_followups 驱动连锁, 直到队列为空. 深度上限兜底配置自环.
    local depth = 0
    while #queue > 0 do
        depth = depth + 1
        if depth > 100 then
            moon.error("uid Mission.TriggerConditionV2 传播深度超限(疑似配置自环): ", context.uid, condition_id)
            break
        end
        local evt = table.remove(queue, 1)
        if evt.unlock then
            handle_linear_unlock(evt.id)
        else
            Mission.JustCheckCondition(mission_info, evt.cond_id, evt.params, evt.change_cnt, change_log,
                new_complete_achivement_ids, new_complete_linear_ids, new_complete_period_ids)
        end
        enqueue_followups()
    end

    Mission.SaveAndSync(change_log)
end

function Mission.TriggerConditionList(condition_list, change_log, need_sync)
    local mission_info = scripts.UserModel.GetMissionInfo()
    if not mission_info then
        return
    end

    if not change_log then
        change_log = {
            linears = {},
            periods = {},
            achivements = {},
            activitys = {},
            periods_all_change = false,
            activitys_all_change = false,
        }
    end
    local now_ts = moon.time()

    -- 累积本次调用里所有"完成"的任务, 用于驱动连锁:
    --   成就完成 -> ACHIEVEMENT_CNT
    --   线性完成 -> OUT_TASK_CNT + 解锁后继任务
    --   周期完成 -> OUT_TASK_CNT
    local new_complete_achivement_ids = {}
    local new_complete_linear_ids = {}
    local new_complete_period_ids = {}

    -- 去重集合: 防止同一任务被重复入队 / 重复触发连锁
    local completed = {}

    local function mark(cat, id)
        local key = cat .. ":" .. id
        if completed[key] then
            return false
        end
        completed[key] = true
        return true
    end

    -- 已消费完成的偏移: 让 enqueue_followups 每次只扫描本次"新增"的完成项,
    -- 避免每 pop 一个队列条目就全量遍历累计表(O(M*N) -> O(N)).
    local done_ach, done_lin, done_per = 0, 0, 0

    -- 工作队列: 用循环替代 TriggerCondition <-> XxxComplete 的互递归调用,
    -- 避免嵌套 SaveAndSync 造成重复同步/重复落库, 以及深层递归耗尽协程栈.
    -- 队列条目:
    --   {cond_id=, params=, change_cnt=}   处理一个条件 (交给 JustCheckCondition)
    --   {unlock=true, id=}                 解锁某线性任务的后继
    local queue = {}

    -- 把三类完成列表里的新完成任务入队其连锁条件/解锁
    local function enqueue_followups()
        -- 只扫描本次"新增"的完成项: 偏移量记录上次已消费到的位置,
        -- 每个条目最多被遍历一次, 将 O(M*N) 降为 O(N). 保留 mark 做防御性去重.
        for i = done_ach + 1, #new_complete_achivement_ids do
            local mission_id = new_complete_achivement_ids[i]
            if mark("ach", mission_id) then
                local cfg = GameCfg.AchievementMissionConfig[mission_id]
                if cfg and cfg.type then
                    table.insert(queue, {
                        cond_id = MissionDef.EConditionIds.ACHIEVEMENT_CNT,
                        params = { cfg.type, mission_id },
                        change_cnt = 1,
                    })
                end
            end
        end
        done_ach = #new_complete_achivement_ids
        for i = done_lin + 1, #new_complete_linear_ids do
            local mission_id = new_complete_linear_ids[i]
            if mark("lin", mission_id) then
                local cfg = GameCfg.LinearMissionConfig[mission_id]
                if cfg and cfg.type then
                    table.insert(queue, {
                        cond_id = MissionDef.EConditionIds.OUT_TASK_CNT,
                        params = { cfg.type, mission_id },
                        change_cnt = 1,
                    })
                end
                table.insert(queue, { unlock = true, id = mission_id })
            end
        end
        done_lin = #new_complete_linear_ids
        for i = done_per + 1, #new_complete_period_ids do
            local mission_id = new_complete_period_ids[i]
            if mark("per", mission_id) then
                local cfg = GameCfg.PeriodMissionConfig[mission_id]
                if cfg and cfg.type then
                    table.insert(queue, {
                        cond_id = MissionDef.EConditionIds.OUT_TASK_CNT,
                        params = { cfg.type, mission_id },
                        change_cnt = 1,
                    })
                end
            end
        end
        done_per = #new_complete_period_ids
    end

    -- 解锁某线性任务的后继 (back_mission). 复用 newLinearMission, 立即完成的后继会
    -- 塞进 new_complete_linear_ids, 再由 enqueue_followups 继续驱动连锁.
    local function handle_linear_unlock(mission_id)
        local linear_cfgs = GameCfg.LinearMissionConfig
        if not linear_cfgs or table.size(linear_cfgs) == 0 then
            return
        end
        local linear_cfg = linear_cfgs[mission_id]
        if not linear_cfg or linear_cfg.back_mission <= 0 then
            return
        end
        -- 防止配置成环: 同一后继只解锁一次
        if not mark("ulock", linear_cfg.back_mission) then
            return
        end
        local new_linear_cfg = linear_cfgs[linear_cfg.back_mission]
        if not new_linear_cfg then
            return
        end
        if new_linear_cfg.unlock_level > scripts.User.GetNowLevel() then
            return
        end
        if new_linear_cfg.start_time ~= 0 and now_ts < new_linear_cfg.start_time then
            return
        end
        if new_linear_cfg.end_time ~= 0 and now_ts >= new_linear_cfg.end_time then
            return
        end
        if mission_info.linear_info.now_mission_datas[new_linear_cfg.id] then
            return
        end
        if mission_info.linear_info.complete_ids[new_linear_cfg.id] then
            return
        end
        local can_new_mission = true
        for _, need_complete_id in pairs(new_linear_cfg.front_mission) do
            if not mission_info.linear_info.complete_ids[need_complete_id]
                and not mission_info.achivement_info.complete_ids[need_complete_id] then
                can_new_mission = false
                break
            end
        end
        if not can_new_mission then
            return
        end
        Mission.newLinearMission(mission_info, new_linear_cfg, now_ts, new_complete_linear_ids, change_log)
        -- 新增的完成项由入队后的 enqueue_followups 驱动
    end

    -- 未开始的线性任务检查 (每个 TriggerConditionV2 调用仅执行一次)
    if mission_info.linear_info.last_check_ts + 60 < now_ts then
        for mission_id, mission_data in pairs(mission_info.linear_info.wait_beg_mission_datas) do
            if (mission_data.beg_ts == 0 or now_ts >= mission_data.beg_ts)
                and (mission_data.end_ts == 0 or now_ts < mission_data.end_ts) then
                Mission.CheckNewMissionCond(mission_data)
                if mission_data.mission_state == MissionDef.ETaskState.COMPLETE then
                    mission_info.linear_info.complete_ids[mission_id] = MissionDef.ETaskState.COMPLETE
                    table.insert(new_complete_linear_ids, mission_id)
                    change_log.linears[mission_id] = MissionDef.ETaskState.COMPLETE
                else
                    mission_info.linear_info.now_mission_datas[mission_id] = mission_data
                    change_log.linears[mission_id] = MissionDef.ETaskState.NO_COMPLETE
                end
                mission_info.linear_info.now_mission_datas[mission_id] = mission_data
                mission_info.linear_info.wait_beg_mission_datas[mission_id] = nil
                for _, cond_data in pairs(mission_data.cond_datas) do
                    if cond_data.is_complete == 0 then
                        if not Mission.linear_cond_map[cond_data.cond_id] then
                            Mission.linear_cond_map[cond_data.cond_id] = {}
                        end
                        if not Mission.linear_cond_map[cond_data.cond_id][mission_id] then
                            Mission.linear_cond_map[cond_data.cond_id][mission_id] = mission_data
                        end
                    end
                end
            elseif mission_data.end_ts ~= 0 and now_ts >= mission_data.end_ts then
                mission_info.linear_info.wait_beg_mission_datas[mission_id] = nil
                change_log.linears[mission_id] = MissionDef.ETaskState.NO_PROGRESS
            end
        end
        mission_info.linear_info.last_check_ts = now_ts
    end

    -- 周期刷新检查: 只在跨天/跨周/跨月时才真正刷新. 放在循环前一次执行,
    -- 顶出的已完成周期任务纳入 new_complete_period_ids, 由 enqueue_followups 连锁.
    if Mission.CheckPeriodInfo(mission_info, now_ts, new_complete_period_ids) then
        Mission.makePeriodMap(mission_info)
        change_log.periods_all_change = true
    end

    scripts.UserModel.SetMissionInfo(mission_info)

    -- 初始条件入队
    for _, cond_info in ipairs(condition_list) do
        table.insert(queue, {
            cond_id = cond_info.cond_id,
            params = cond_info.params or {},
            change_cnt = cond_info.change_cnt or 1,
        })
    end

    -- 主事件循环: 每 pop 一个事件用 JustCheckCondition 原子推进条件, 收集新完成任务,
    -- 再 enqueue_followups 驱动连锁, 直到队列为空. 深度上限兜底配置自环.
    local depth = 0
    while #queue > 0 do
        depth = depth + 1
        if depth > 100 then
            moon.error(string.format("uid=%d Mission.TriggerConditionList 传播深度超限(疑似配置自环):%s", context.uid, json.stringify(condition_list)))
            break
        end
        local evt = table.remove(queue, 1)
        if evt.unlock then
            handle_linear_unlock(evt.id)
        else
            Mission.JustCheckCondition(mission_info, evt.cond_id, evt.params, evt.change_cnt, change_log,
                new_complete_achivement_ids, new_complete_linear_ids, new_complete_period_ids)
        end
        enqueue_followups()
    end

    if need_sync then
        Mission.SaveAndSync(change_log)
    end
end

function Mission.TriggerConditionSingleMission(condition_id, params, change_cnt, mission_data)
    local is_change = MissionLogic.CheckSingleTask(condition_id, params, change_cnt, mission_data)
    if is_change then
        local mission_complete = true
        for _, cond_data in pairs(mission_data.cond_datas) do
            if cond_data.is_complete == 0 then
                mission_complete = false
                break
            end
        end
        if mission_complete then
            mission_data.mission_state = MissionDef.ETaskState.COMPLETE
        end
    end
end

function Mission.CheckNewMissionCond(new_mission_data)
    for _, cond_data in pairs(new_mission_data.cond_datas) do
        if cond_data.cond_id == MissionDef.EConditionIds.ACCOUNT_LEVEL then
            Mission.TriggerConditionSingleMission(MissionDef.EConditionIds.ACCOUNT_LEVEL, {},
                scripts.User.GetNowLevel(), new_mission_data)
        elseif cond_data.cond_id == MissionDef.EConditionIds.UNLOCK_ROLE_SKIN_CNT then
            local now_cnt, _ = scripts.ItemImage.GetSkinTypeCnt()
            Mission.TriggerConditionSingleMission(MissionDef.EConditionIds.UNLOCK_ROLE_SKIN_CNT, {}, now_cnt,
                new_mission_data)
        elseif cond_data.cond_id == MissionDef.EConditionIds.UNLOCK_ROLE_SKIN then
            if table.size(cond_data.params) >= 1 then
                local skin_id = cond_data.params[1]
                local item_image, item_type = scripts.ItemImage.GetImage(skin_id)
                if item_image
                    and item_type == ItemDefine.EItemSmallType.RoleSkin
                    and item_image.valid_ts == 0 then
                    Mission.TriggerConditionSingleMission(MissionDef.EConditionIds.UNLOCK_ROLE_SKIN, { skin_id },
                        1, new_mission_data)
                end
            end
        elseif cond_data.cond_id == MissionDef.EConditionIds.UNLOCK_ROLE_CNT then
            Mission.TriggerConditionSingleMission(MissionDef.EConditionIds.UNLOCK_ROLE_CNT, {},
                scripts.Role.GetRoleCnt(), new_mission_data)
        elseif cond_data.cond_id == MissionDef.EConditionIds.UNLOCK_ROLE then
            if table.size(cond_data.params) >= 1 then
                local roleid = cond_data.params[1]
                local role_info = scripts.Role.GetRoleInfo(roleid)
                if role_info then
                    Mission.TriggerConditionSingleMission(MissionDef.EConditionIds.UNLOCK_ROLE, { roleid }, 1,
                        new_mission_data)
                end
            end
        elseif cond_data.cond_id == MissionDef.EConditionIds.GET_TREASURE_CNT then
            if table.size(cond_data.params) >= 1 then
                local treasure_id = cond_data.params[1]
                if treasure_id == 0 then
                    local total_get_count = scripts.Shop.GetTreasureTotalCnt()
                    Mission.TriggerConditionSingleMission(MissionDef.EConditionIds.GET_TREASURE_CNT, { 0 },
                        total_get_count, new_mission_data)
                else
                    local treasure_data = scripts.Shop.GetTreasureData(treasure_id)
                    if treasure_data and treasure_data.get_count and treasure_data.get_count > 0 then
                        Mission.TriggerConditionSingleMission(MissionDef.EConditionIds.GET_TREASURE_CNT, { treasure_id },
                            treasure_data.get_count, new_mission_data)
                    end
                end
            end
        elseif cond_data.cond_id == MissionDef.EConditionIds.OPEN_TREASURE_CNT then
            if table.size(cond_data.params) >= 1 then
                local treasure_id = cond_data.params[1]
                if treasure_id == 0 then
                    local total_open_count = scripts.Shop.GetTreasureTotalOpenCnt()
                    Mission.TriggerConditionSingleMission(MissionDef.EConditionIds.OPEN_TREASURE_CNT, { 0 },
                        total_open_count, new_mission_data)
                else
                    local treasure_data = scripts.Shop.GetTreasureData(treasure_id)
                    if treasure_data and treasure_data.open_count and treasure_data.open_count > 0 then
                        Mission.TriggerConditionSingleMission(MissionDef.EConditionIds.OPEN_TREASURE_CNT, { treasure_id },
                            treasure_data.open_count, new_mission_data)
                    end
                end
            end
        elseif cond_data.cond_id == MissionDef.EConditionIds.ROLE_STAR_CNT then
            if table.size(cond_data.params) >= 1 then
                local num = scripts.Role.GetStarMoreThanNum(0, cond_data.params[1])
                Mission.TriggerConditionSingleMission(MissionDef.EConditionIds.ROLE_STAR_CNT, { cond_data.params[1] },
                    num, new_mission_data)
            end
        elseif cond_data.cond_id == MissionDef.EConditionIds.ROLE_LEVEL_CNT then
            if table.size(cond_data.params) >= 1 then
                local up_exp_cfg = GameCfg.RoleUpLv[cond_data.params[1]]
                if up_exp_cfg and up_exp_cfg.allexp then
                    local roleid_exps = scripts.Role.GetSingleExpMoreThanIds(up_exp_cfg.allexp)
                    Mission.TriggerConditionSingleMission(MissionDef.EConditionIds.ROLE_LEVEL_CNT,
                        { cond_data.params[1] }, table.size(roleid_exps), new_mission_data)
                end
            end
        elseif cond_data.cond_id == MissionDef.EConditionIds.ROLE_STAR then
            if table.size(cond_data.params) >= 1 then
                if cond_data.params[1] == 0 then
                    local max_star, cur_roleid = scripts.Role.GetMaxStarRoleid()
                    if cur_roleid > 0 then
                        Mission.TriggerConditionSingleMission(MissionDef.EConditionIds.ROLE_STAR, { cur_roleid },
                            max_star, new_mission_data)
                    end
                else
                    local role_info = scripts.Role.GetRoleInfo(cond_data.params[1])
                    if role_info then
                        Mission.TriggerConditionSingleMission(MissionDef.EConditionIds.ROLE_STAR, { cond_data.params[1] },
                            role_info.star_level, new_mission_data)
                    end
                end
            end
        elseif cond_data.cond_id == MissionDef.EConditionIds.ROLE_LEVEL then
            if table.size(cond_data.params) >= 1 then
                if cond_data.params[1] == 0 then
                    local max_exp, cur_roleid = scripts.Role.GetMaxExpRoleid()
                    if cur_roleid > 0 then
                        local up_exp_cfgs = GameCfg.RoleUpLv
                        if up_exp_cfgs and table.size(up_exp_cfgs) > 0 then
                            local max_lv = 0
                            for id, up_exp_cfg in pairs(up_exp_cfgs) do
                                if up_exp_cfg.exp <= max_exp then
                                    max_lv = id
                                else
                                    break
                                end
                            end
                            Mission.TriggerConditionSingleMission(MissionDef.EConditionIds.ROLE_LEVEL, { cur_roleid },
                                max_lv, new_mission_data)
                        end
                    end
                else
                    local role_info = scripts.Role.GetRoleInfo(cond_data.params[1])
                    if role_info then
                        local up_exp_cfgs = GameCfg.RoleUpLv
                        if up_exp_cfgs and table.size(up_exp_cfgs) > 0 then
                            local max_lv = 0
                            for id, up_exp_cfg in pairs(up_exp_cfgs) do
                                if up_exp_cfg.exp <= role_info.exp then
                                    max_lv = id
                                else
                                    break
                                end
                            end
                            Mission.TriggerConditionSingleMission(MissionDef.EConditionIds.ROLE_LEVEL,
                                { cond_data.params[1] },
                                max_lv, new_mission_data)
                        end
                    end
                end
            end
        elseif cond_data.cond_id == MissionDef.EConditionIds.ROLE_UNLOCK_SKILL_CNT then
            if table.size(cond_data.params) >= 1 then
                if cond_data.params[1] == 0 then
                    local max_skill_num, cur_roleid = scripts.Role.GetMaxSkillNum()
                    if cur_roleid > 0 then
                        Mission.TriggerConditionSingleMission(MissionDef.EConditionIds.ROLE_UNLOCK_SKILL_CNT,
                            { cur_roleid },
                            max_skill_num, new_mission_data)
                    end
                else
                    local role_info = scripts.Role.GetRoleInfo(cond_data.params[1])
                    if role_info then
                        local num = table.size(role_info.main_skill) + table.size(role_info.minor_skill1) +
                            table.size(role_info.minor_skill2) + table.size(role_info.passive_skill)
                        Mission.TriggerConditionSingleMission(MissionDef.EConditionIds.ROLE_UNLOCK_SKILL_CNT,
                            { cond_data.params[1] }, num, new_mission_data)
                    end
                end
            end
        elseif cond_data.cond_id == MissionDef.EConditionIds.ROLE_UNLOCK_SKILL then
            if table.size(cond_data.params) >= 2 then
                local target_role_id = cond_data.params[1]
                local target_skill_id = cond_data.params[2]
                local role_info = scripts.Role.GetRoleInfo(target_role_id)
                if role_info then
                    local is_unlock = false
                    for skill_id, _ in pairs(role_info.main_skill) do
                        if skill_id == target_skill_id then
                            is_unlock = true
                            break
                        end
                    end
                    if not is_unlock then
                        for skill_id, _ in pairs(role_info.minor_skill1) do
                            if skill_id == target_skill_id then
                                is_unlock = true
                                break
                            end
                        end
                    end
                    if not is_unlock then
                        for skill_id, _ in pairs(role_info.minor_skill2) do
                            if skill_id == target_skill_id then
                                is_unlock = true
                                break
                            end
                        end
                    end
                    if not is_unlock then
                        for skill_id, _ in pairs(role_info.passive_skill) do
                            if skill_id == target_skill_id then
                                is_unlock = true
                                break
                            end
                        end
                    end
                    if is_unlock then
                        Mission.TriggerConditionSingleMission(MissionDef.EConditionIds.ROLE_UNLOCK_SKILL,
                            { target_role_id, target_skill_id }, 1, new_mission_data)
                    end
                end
            end
        elseif cond_data.cond_id == MissionDef.EConditionIds.UNLOCK_GOD_CNT then
            local gods_images = scripts.Gods.GetGodsImages()
            if gods_images then
                Mission.TriggerConditionSingleMission(MissionDef.EConditionIds.UNLOCK_GOD_CNT, {},
                    table.size(gods_images), new_mission_data)
            end
        elseif cond_data.cond_id == MissionDef.EConditionIds.UNLOCK_GOD then
            if table.size(cond_data.params) >= 1 then
                local gods_images = scripts.Gods.GetGodsImages()
                if gods_images and gods_images[cond_data.params[1]] then
                    Mission.TriggerConditionSingleMission(MissionDef.EConditionIds.UNLOCK_GOD, { cond_data.params[1] }, 1,
                        new_mission_data)
                end
            end
        elseif cond_data.cond_id == MissionDef.EConditionIds.GOD_LEVEL then
            if table.size(cond_data.params) >= 1 then
                if cond_data.params[1] == 0 then
                    local max_level, cur_god_id = scripts.Gods.GetMaxLevelGodid()
                    if cur_god_id > 0 then
                        Mission.TriggerConditionSingleMission(MissionDef.EConditionIds.GOD_LEVEL, { cur_god_id },
                            max_level, new_mission_data)
                    end
                else
                    local gods_images = scripts.Gods.GetGodsImages()
                    if gods_images and gods_images[cond_data.params[1]] then
                        Mission.TriggerConditionSingleMission(MissionDef.EConditionIds.GOD_LEVEL, { cond_data.params[1] },
                            gods_images[cond_data.params[1]].lv, new_mission_data)
                    end
                end
            end
        elseif cond_data.cond_id == MissionDef.EConditionIds.UNLOCK_ITEM_SKIN_CNT then
            local _, now_cnt = scripts.ItemImage.GetSkinTypeCnt()
            Mission.TriggerConditionSingleMission(MissionDef.EConditionIds.UNLOCK_ITEM_SKIN_CNT, {}, now_cnt,
                new_mission_data)
        elseif cond_data.cond_id == MissionDef.EConditionIds.TOTAL_RECHARGE_CNT then
            Mission.TriggerConditionSingleMission(MissionDef.EConditionIds.TOTAL_RECHARGE_CNT, {},
                scripts.Bill.GetTotalAmount(), new_mission_data)
        elseif cond_data.cond_id == MissionDef.EConditionIds.UNLOCK_SKIN_CNT then
            -- 累积解锁X类型皮肤总数：按Skin表type字段统计当前已永久解锁的皮肤
            if table.size(cond_data.params) >= 1 then
                local target_type = cond_data.params[1]
                local itemImages = scripts.UserModel.GetItemImages()
                local skin_cnt = 0
                if itemImages and itemImages.skin_image then
                    for config_id, skin in pairs(itemImages.skin_image) do
                        if skin.valid_ts == 0 then
                            local skin_cfg = GameCfg.Skin[config_id]
                            if skin_cfg and skin_cfg.type
                                and (target_type == 0 or skin_cfg.type == target_type) then
                                skin_cnt = skin_cnt + 1
                            end
                        end
                    end
                end
                if skin_cnt > 0 then
                    Mission.TriggerConditionSingleMission(MissionDef.EConditionIds.UNLOCK_SKIN_CNT,
                        { target_type }, skin_cnt, new_mission_data)
                end
            end
        elseif cond_data.cond_id == MissionDef.EConditionIds.ROLE_MAX_LEVEL then
            if table.size(cond_data.params) >= 1 then
                if cond_data.params[1] == 0 then
                    local max_exp, cur_roleid = scripts.Role.GetMaxExpRoleid()
                    if cur_roleid > 0 then
                        local up_exp_cfgs = GameCfg.RoleUpLv
                        if up_exp_cfgs and table.size(up_exp_cfgs) > 0 then
                            local max_lv = 0
                            for id, up_exp_cfg in pairs(up_exp_cfgs) do
                                if up_exp_cfg.exp <= max_exp then
                                    max_lv = id
                                else
                                    break
                                end
                            end
                            Mission.TriggerConditionSingleMission(MissionDef.EConditionIds.ROLE_MAX_LEVEL,
                                { cur_roleid },
                                max_lv, new_mission_data)
                        end
                    end
                else
                    local role_info = scripts.Role.GetRoleInfo(cond_data.params[1])
                    if role_info then
                        local up_exp_cfgs = GameCfg.RoleUpLv
                        if up_exp_cfgs and table.size(up_exp_cfgs) > 0 then
                            local max_lv = 0
                            for id, up_exp_cfg in pairs(up_exp_cfgs) do
                                if up_exp_cfg.exp <= role_info.exp then
                                    max_lv = id
                                else
                                    break
                                end
                            end
                            Mission.TriggerConditionSingleMission(MissionDef.EConditionIds.ROLE_MAX_LEVEL,
                                { cond_data.params[1] },
                                max_lv, new_mission_data)
                        end
                    end
                end
            end
        elseif cond_data.cond_id == MissionDef.EConditionIds.ROLE_MAX_STAR then
            if table.size(cond_data.params) >= 1 then
                if cond_data.params[1] == 0 then
                    local max_star, cur_roleid = scripts.Role.GetMaxStarRoleid()
                    if cur_roleid > 0 then
                        Mission.TriggerConditionSingleMission(MissionDef.EConditionIds.ROLE_MAX_STAR, { cur_roleid },
                            max_star, new_mission_data)
                    end
                else
                    local role_info = scripts.Role.GetRoleInfo(cond_data.params[1])
                    if role_info then
                        Mission.TriggerConditionSingleMission(MissionDef.EConditionIds.ROLE_MAX_STAR,
                            { cond_data.params[1] },
                            role_info.star_level, new_mission_data)
                    end
                end
            end
        --else
            -- 未实现创建时初始化的条件，属于常规事件型条件（从任务创建后开始累计），无需告警
            -- moon.debug("Mission.CheckNewMissionCond: cond_id not found: " .. cond_data.cond_id)
        end
    end
end

function Mission.LinearMissionComplete(mission_info, complete_ids)
    local linear_cfgs = GameCfg.LinearMissionConfig
    if not linear_cfgs or table.size(linear_cfgs) == 0 then
        return
    end

    -- 检查是否有可以新开启的任务
    local now_ts = moon.time()
    local new_complete_ids = {}
    for _, mission_id in pairs(complete_ids) do
        local linear_cfg = linear_cfgs[mission_id]
        if linear_cfg and linear_cfg.type then
            -- 触发完成任务条件
            scripts.UserModel.SetMissionInfo(mission_info)
            Mission.TriggerCondition(MissionDef.EConditionIds.OUT_TASK_CNT, { linear_cfg.type, mission_id }, 1)
            mission_info = scripts.UserModel.GetMissionInfo()
        end

        if linear_cfg and linear_cfg.back_mission > 0 then
            local new_linear_cfg = linear_cfgs[linear_cfg.back_mission]
            if new_linear_cfg
                and new_linear_cfg.unlock_level <= scripts.User.GetNowLevel()
                and (new_linear_cfg.start_time == 0 or now_ts >= new_linear_cfg.start_time)
                and (new_linear_cfg.end_time == 0 or now_ts < new_linear_cfg.end_time)
                and not mission_info.linear_info.now_mission_datas[new_linear_cfg.id]
                and not mission_info.linear_info.complete_ids[new_linear_cfg.id] then
                local can_new_mission = true
                for _, need_complete_id in pairs(new_linear_cfg.front_mission) do
                    if not mission_info.linear_info.complete_ids[need_complete_id]
                        and not mission_info.achivement_info.complete_ids[need_complete_id] then
                        can_new_mission = false
                        break
                    end
                end
                if can_new_mission then
                    Mission.newLinearMission(mission_info, new_linear_cfg, now_ts, new_complete_ids, change_log)
                end
            end
        end
    end
    if table.size(new_complete_ids) > 0 then
        Mission.LinearMissionComplete(mission_info, new_complete_ids)
    end
end

function Mission.LinearMissionComplete_new(mission_info, complete_ids, change_log, need_sync)
    local linear_cfgs = GameCfg.LinearMissionConfig
    if not linear_cfgs or table.size(linear_cfgs) == 0 then
        return
    end

    if not change_log or table.size(change_log) == 0 then
        change_log = {
            linears = {},
            periods = {},
            achivements = {},
            activitys = {},
            periods_all_change = false,
            activitys_all_change = false,
        }
    end

    local now_ts = moon.time()
    local new_condition_queue = {} -- 条件队列
    while #complete_ids > 0 do
        local cur_mission_id = table.remove(complete_ids, 1)

        local linear_cfg = linear_cfgs[cur_mission_id]
        if linear_cfg and linear_cfg.type then
            -- 触发完成任务条件
            table.insert(new_condition_queue, {
                cond_id = MissionDef.EConditionIds.OUT_TASK_CNT,
                params = { linear_cfg.type, cur_mission_id },
                change_cnt = 1,
            })
        end

        if linear_cfg and linear_cfg.back_mission > 0 then
            local new_linear_cfg = linear_cfgs[linear_cfg.back_mission]
            if new_linear_cfg
                and new_linear_cfg.unlock_level <= scripts.User.GetNowLevel()
                and (new_linear_cfg.start_time == 0 or now_ts >= new_linear_cfg.start_time)
                and (new_linear_cfg.end_time == 0 or now_ts < new_linear_cfg.end_time)
                and not mission_info.linear_info.now_mission_datas[new_linear_cfg.id]
                and not mission_info.linear_info.complete_ids[new_linear_cfg.id] then
                local can_new_mission = true
                for _, need_complete_id in pairs(new_linear_cfg.front_mission) do
                    if not mission_info.linear_info.complete_ids[need_complete_id]
                        and not mission_info.achivement_info.complete_ids[need_complete_id] then
                        can_new_mission = false
                        break
                    end
                end
                if can_new_mission then
                    Mission.newLinearMission(mission_info, new_linear_cfg, now_ts, complete_ids, change_log)
                end
            end
        end
    end

    scripts.UserModel.SetMissionInfo(mission_info)
    if table.size(new_condition_queue) > 0 then
        Mission.TriggerConditionList(new_condition_queue, change_log, need_sync)
    else
        if need_sync then
            Mission.SaveAndSync(change_log)
        end
    end
end

function Mission.PeriodMissionComplete(mission_info, complete_ids, change_log)
    local period_cfgs = GameCfg.PeriodMissionConfig
    if not period_cfgs or table.size(period_cfgs) == 0 then
        return
    end

    for _, mission_id in pairs(complete_ids) do
        local period_cfg = period_cfgs[mission_id]
        if period_cfg and period_cfg.type then
            -- 触发完成任务条件
            scripts.UserModel.SetMissionInfo(mission_info)
            Mission.TriggerCondition(MissionDef.EConditionIds.OUT_TASK_CNT, { period_cfg.type, mission_id }, 1)
            mission_info = scripts.UserModel.GetMissionInfo()
        end
    end
end

function Mission.PeriodMissionComplete_new(mission_info, complete_ids, change_log, need_sync)
    local period_cfgs = GameCfg.PeriodMissionConfig
    if not period_cfgs or table.size(period_cfgs) == 0 then
        return
    end

    if not change_log or table.size(change_log) == 0 then
        change_log = {
            linears = {},
            periods = {},
            achivements = {},
            activitys = {},
            periods_all_change = false,
            activitys_all_change = false,
        }
    end

    local new_condition_queue = {} -- 条件队列
    while #complete_ids > 0 do
        local cur_mission_id = table.remove(complete_ids, 1)

        local period_cfg = period_cfgs[cur_mission_id]
        if period_cfg and period_cfg.type then
            -- 触发完成任务条件
            table.insert(new_condition_queue, {
                cond_id = MissionDef.EConditionIds.OUT_TASK_CNT,
                params = { period_cfg.type, cur_mission_id },
                change_cnt = 1,
            })
        end
    end

    scripts.UserModel.SetMissionInfo(mission_info)
    if table.size(new_condition_queue) > 0 then
        Mission.TriggerConditionList(new_condition_queue, change_log, need_sync)
    else
        if need_sync then
            Mission.SaveAndSync(change_log)
        end
    end
end

function Mission.AchivementMissionComplete(mission_info, complete_ids)
    local achievement_cfgs = GameCfg.AchievementMissionConfig
    if not achievement_cfgs or table.size(achievement_cfgs) == 0 then
        return
    end

    for _, mission_id in pairs(complete_ids) do
        local achievement_cfg = achievement_cfgs[mission_id]
        if achievement_cfg and achievement_cfg.type then
            -- 触发完成任务条件
            scripts.UserModel.SetMissionInfo(mission_info)
            Mission.TriggerCondition(MissionDef.EConditionIds.ACHIEVEMENT_CNT, { achievement_cfg.type, mission_id }, 1)
            mission_info = scripts.UserModel.GetMissionInfo()
        end
    end
end

function Mission.AchivementMissionComplete_new(mission_info, complete_ids, change_log, need_sync)
    local achievement_cfgs = GameCfg.AchievementMissionConfig
    if not achievement_cfgs or table.size(achievement_cfgs) == 0 then
        return
    end

    if not change_log or table.size(change_log) == 0 then
        change_log = {
            linears = {},
            periods = {},
            achivements = {},
            activitys = {},
            periods_all_change = false,
            activitys_all_change = false,
        }
    end

    local new_condition_queue = {} -- 条件队列
    while #complete_ids > 0 do
        local cur_mission_id = table.remove(complete_ids, 1)

        local achievement_cfg = achievement_cfgs[cur_mission_id]
        if achievement_cfg and achievement_cfg.type then
            -- 触发完成任务条件
            table.insert(new_condition_queue, {
                cond_id = MissionDef.EConditionIds.ACHIEVEMENT_CNT,
                params = { achievement_cfg.type, cur_mission_id },
                change_cnt = 1,
            })
        end
    end

    scripts.UserModel.SetMissionInfo(mission_info)
    if table.size(new_condition_queue) > 0 then
        Mission.TriggerConditionList(new_condition_queue, change_log, need_sync)
    else
        if need_sync then
            Mission.SaveAndSync(change_log)
        end
    end
end

function Mission.ActivityMissionComplete(mission_info, complete_ids)
    local activity_cfgs = GameCfg.ActivityMissionConfig
    if not activity_cfgs or table.size(activity_cfgs) == 0 then
        return
    end

    for _, mission_id in pairs(complete_ids) do
        local activity_cfg = activity_cfgs[mission_id]
        if activity_cfg and activity_cfg.type then
            -- 触发完成任务条件
            scripts.UserModel.SetMissionInfo(mission_info)
            Mission.TriggerCondition(MissionDef.EConditionIds.OUT_TASK_CNT, { activity_cfg.type, mission_id }, 1)
            mission_info = scripts.UserModel.GetMissionInfo()
        end
    end
end

function Mission.ActivityMissionComplete_new(mission_info, complete_ids, change_log, need_sync)
    local activity_cfgs = GameCfg.ActivityMissionConfig
    if not activity_cfgs or table.size(activity_cfgs) == 0 then
        return
    end

    if not change_log or table.size(change_log) == 0 then
        change_log = {
            linears = {},
            periods = {},
            achivements = {},
            activitys = {},
            periods_all_change = false,
            activitys_all_change = false,
        }
    end

    local now_ts = moon.time()
    local new_condition_queue = {} -- 条件队列
    while #complete_ids > 0 do
        local cur_mission_id = table.remove(complete_ids, 1)

        local activity_cfg = activity_cfgs[cur_mission_id]
        if activity_cfg and activity_cfg.type then
            -- 触发完成任务条件
            table.insert(new_condition_queue, {
                cond_id = MissionDef.EConditionIds.OUT_TASK_CNT,
                params = { activity_cfg.type, cur_mission_id },
                change_cnt = 1,
            })
        end
    end

    scripts.UserModel.SetMissionInfo(mission_info)
    if table.size(new_condition_queue) > 0 then
        Mission.TriggerConditionList(new_condition_queue, change_log, need_sync)
    else
        if need_sync then
            Mission.SaveAndSync(change_log)
        end
    end
end

function Mission.ReplaceMission(mission_info, old_mission_id)
    if not mission_info.period_info.now_day_mission_datas
        or not mission_info.period_info.now_day_mission_datas[old_mission_id] then
        return ErrorCode.MissionNotFound
    end

    local period_cfgs = GameCfg.PeriodMissionConfig
    if not period_cfgs or table.size(period_cfgs) == 0 then
        return ErrorCode.ConfigError
    end
    local old_period_cfg = period_cfgs[old_mission_id]
    if not old_period_cfg or old_period_cfg.is_refresh ~= 2 then
        return ErrorCode.MissionNotRefresh
    end

    local now_ts = moon.time()
    local random_ids = {}
    for _, period_cfg in pairs(period_cfgs) do
        if (period_cfg.cyclical_date == 1 and period_cfg.is_refresh == 2)
            and period_cfg.unlock_level <= scripts.User.GetNowLevel()
            and (period_cfg.start_time == 0 or now_ts >= period_cfg.start_time)
            and (period_cfg.end_time == 0 or now_ts < period_cfg.end_time)
            and not mission_info.period_info.now_day_mission_datas[period_cfg.id]
            and not mission_info.period_info.complete_day_ids[period_cfg.id] then
            local can_new_mission = true
            for _, need_complete_id in pairs(period_cfg.front_mission) do
                if not mission_info.linear_info.complete_ids[need_complete_id]
                    and not mission_info.achivement_info.complete_ids[need_complete_id] then
                    can_new_mission = false
                    break
                end
            end
            if can_new_mission then
                random_ids[period_cfg.id] = period_cfg.weight
            end
        end
    end
    if table.size(random_ids) <= 0 then
        return ErrorCode.NoMissionCanReplace
    end

    local replace_id = 0
    if table.size(random_ids) > 1 then
        replace_id = scripts.Item.RangeTags(random_ids)
    else
        replace_id = random_ids[1]
    end
    if replace_id <= 0 or not GameCfg.PeriodMissionConfig[replace_id] then
        return ErrorCode.ConfigError
    end

    mission_info.period_info.now_day_mission_datas[old_mission_id] = nil
    local new_complete_period_ids = {}
    local new_period_cfg = GameCfg.PeriodMissionConfig[replace_id]
    if new_period_cfg then
        Mission.newPeriodMission(mission_info, new_period_cfg, now_ts, new_complete_period_ids)
    end
    if table.size(new_complete_period_ids) > 0 then
        -- Mission.PeriodMissionComplete(mission_info, new_complete_period_ids)
        Mission.PeriodMissionComplete_new(mission_info, new_complete_period_ids, nil, false)
    end

    return ErrorCode.None, replace_id
end

function Mission.DelOverTimeLinearMission(mission_info)
    local linear_cfgs = GameCfg.LinearMissionConfig
    if not linear_cfgs or table.size(linear_cfgs) == 0 then
        return
    end
    if not mission_info.linear_info.now_mission_datas
        or table.size(mission_info.linear_info.now_mission_datas) <= 0 then
        return
    end

    local del_ids = {}
    local now_ts = moon.time()
    for mission_id, _ in pairs(mission_info.linear_info.now_mission_datas) do
        if linear_cfgs[mission_id]
            and linear_cfgs[mission_id].end_time ~= 0
            and now_ts > linear_cfgs[mission_id].end_time then
            table.insert(del_ids, mission_id)
        end
    end
    if table.size(del_ids) > 0 then
        for _, mission_id in pairs(del_ids) do
            mission_info.linear_info.now_mission_datas[mission_id] = nil
        end
        Mission.SaveMissionsNow()
    end
end

function Mission.GetLinearMissionReward(mission_info, linear_ids)
    if not mission_info.linear_info.complete_ids
        or table.size(mission_info.linear_info.complete_ids) <= 0 then
        return ErrorCode.MissionNotFound
    end

    local now_ts = moon.time()
    local add_list = {}
    local add_vitality = 0
    for _, mission_id in pairs(linear_ids) do
        local mission_state = mission_info.linear_info.complete_ids[mission_id]
        if not mission_state then
            return ErrorCode.MissionNotFound
        end
        if mission_state ~= MissionDef.ETaskState.COMPLETE then
            return ErrorCode.MissionAlreadyGetReward
        end
        local linear_cfg = GameCfg.LinearMissionConfig[mission_id]
        if not linear_cfg or not linear_cfg.rewards then
            return ErrorCode.ConfigError
        end
        if linear_cfg.end_time and now_ts > linear_cfg.end_time then
            return ErrorCode.MissionOverTime
        end
        for re_id, re_cnt in pairs(linear_cfg.rewards) do
            if not add_list[re_id] then
                add_list[re_id] = re_cnt
            else
                add_list[re_id] = add_list[re_id] + re_cnt
            end
        end
        if linear_cfg.vitality > 0 then
            add_vitality = add_vitality + linear_cfg.vitality
        end
    end

    -- 整理道具奖励
    local add_items, add_coins = {}, {}
    ItemDefine.GetItemsFromCfg(add_list, 1, false, add_items, add_coins)
    if table.size(add_items) + table.size(add_coins) <= 0 then
        moon.error(string.format("ItemDefine.GetItemsFromCfg config error add_list=%s", json.pretty_encode(add_list)))
        return ErrorCode.ConfigError
    end
    if table.size(add_items) > 0 then
        local ret_code = scripts.Bag.TryEmptyEnough(BagDef.BagType.Cangku, add_items, 0)
        if ret_code ~= ErrorCode.None then
            return ret_code
        end
    end

    local stack_items, unstack_items, deal_coins = {}, {}, {}
    local ok = ItemDefine.GetItemDataFromIdCount(add_items, add_coins, stack_items, unstack_items, deal_coins)
    if not ok then
        moon.error(string.format("ItemDefine.GetItemDataFromIdCount config error add_items=%s",
            json.pretty_encode(add_items)))
        moon.error(string.format("ItemDefine.GetItemDataFromIdCount config error add_coins=%s",
            json.pretty_encode(add_coins)))
        return ErrorCode.ConfigError
    end

    local bag_change_log = {}
    if table.size(stack_items) + table.size(unstack_items) > 0 then
        local err_code_items = scripts.Bag.AddItems(BagDef.BagType.Cangku, stack_items, unstack_items, bag_change_log)
        if err_code_items ~= ErrorCode.None then
            scripts.Bag.RollBackWithChange(bag_change_log)
            return err_code_items
        end
    end
    scripts.Bag.SaveAndLog(bag_change_log, ItemDef.ChangeReason.TakeMissionReward)

    -- 触发添加活跃度
    Mission.TriggerCondition(MissionDef.EConditionIds.ACTIVITY_CNT, {}, add_vitality)

    return ErrorCode.None
end

function Mission.GetActivityMissionReward(mission_info, activity_ids)
    if not mission_info.activity_info.complete_ids
        or table.size(mission_info.activity_info.complete_ids) <= 0 then
        return ErrorCode.MissionNotFound
    end

    local now_ts = moon.time()
    local add_list = {}
    local add_vitality = 0
    for _, mission_id in pairs(activity_ids) do
        local mission_state = mission_info.activity_info.complete_ids[mission_id]
        if not mission_state then
            return ErrorCode.MissionNotFound
        end
        if mission_state ~= MissionDef.ETaskState.COMPLETE then
            return ErrorCode.MissionAlreadyGetReward
        end
        local activity_cfg = GameCfg.ActivityMissionConfig[mission_id]
        if not activity_cfg or not activity_cfg.rewards then
            return ErrorCode.ConfigError
        end
        -- 类型未开启不允许领取
        if not Mission.IsActivityTypeOpen(activity_cfg.type) then
            return ErrorCode.MissionOverTime
        end
        if activity_cfg.end_time and activity_cfg.end_time ~= 0 and now_ts > activity_cfg.end_time then
            return ErrorCode.MissionOverTime
        end
        for re_id, re_cnt in pairs(activity_cfg.rewards) do
            if not add_list[re_id] then
                add_list[re_id] = re_cnt
            else
                add_list[re_id] = add_list[re_id] + re_cnt
            end
        end
        if activity_cfg.vitality > 0 then
            add_vitality = add_vitality + activity_cfg.vitality
        end
    end

    -- 整理道具奖励
    local add_items, add_coins = {}, {}
    ItemDefine.GetItemsFromCfg(add_list, 1, false, add_items, add_coins)
    if table.size(add_items) + table.size(add_coins) <= 0 then
        moon.error(string.format("ItemDefine.GetItemsFromCfg config error add_list=%s", json.pretty_encode(add_list)))
        return ErrorCode.ConfigError
    end
    if table.size(add_items) > 0 then
        local ret_code = scripts.Bag.TryEmptyEnough(BagDef.BagType.Cangku, add_items, 0)
        if ret_code ~= ErrorCode.None then
            return ret_code
        end
    end

    local stack_items, unstack_items, deal_coins = {}, {}, {}
    local ok = ItemDefine.GetItemDataFromIdCount(add_items, add_coins, stack_items, unstack_items, deal_coins)
    if not ok then
        moon.error(string.format("ItemDefine.GetItemDataFromIdCount config error add_items=%s",
            json.pretty_encode(add_items)))
        moon.error(string.format("ItemDefine.GetItemDataFromIdCount config error add_coins=%s",
            json.pretty_encode(add_coins)))
        return ErrorCode.ConfigError
    end

    local bag_change_log = {}
    if table.size(stack_items) + table.size(unstack_items) > 0 then
        local err_code_items = scripts.Bag.AddItems(BagDef.BagType.Cangku, stack_items, unstack_items, bag_change_log)
        if err_code_items ~= ErrorCode.None then
            scripts.Bag.RollBackWithChange(bag_change_log)
            return err_code_items
        end
    end
    scripts.Bag.SaveAndLog(bag_change_log, ItemDef.ChangeReason.TakeMissionReward)

    -- 触发添加活跃度
    Mission.TriggerCondition(MissionDef.EConditionIds.ACTIVITY_CNT, {}, add_vitality)

    return ErrorCode.None
end

function Mission.GetAchievementMissionReward(mission_info, achivement_ids)
    if not mission_info.achivement_info.complete_ids
        or table.size(mission_info.achivement_info.complete_ids) <= 0 then
        return ErrorCode.MissionNotFound
    end

    local now_ts = moon.time()
    local add_list = {}
    local add_vitality = 0
    for _, mission_id in pairs(achivement_ids) do
        local mission_state = mission_info.achivement_info.complete_ids[mission_id]
        if not mission_state then
            return ErrorCode.MissionNotFound
        end
        if mission_state ~= MissionDef.ETaskState.COMPLETE then
            return ErrorCode.MissionAlreadyGetReward
        end
        local achievement_cfg = GameCfg.AchievementMissionConfig[mission_id]
        if not achievement_cfg or not achievement_cfg.rewards then
            return ErrorCode.ConfigError
        end
        for re_id, re_cnt in pairs(achievement_cfg.rewards) do
            if not add_list[re_id] then
                add_list[re_id] = re_cnt
            else
                add_list[re_id] = add_list[re_id] + re_cnt
            end
        end
        if achievement_cfg.vitality > 0 then
            add_vitality = add_vitality + achievement_cfg.vitality
        end
    end

    -- 整理道具奖励
    local add_items, add_coins = {}, {}
    ItemDefine.GetItemsFromCfg(add_list, 1, false, add_items, add_coins)
    if table.size(add_items) + table.size(add_coins) <= 0 then
        moon.error(string.format("ItemDefine.GetItemsFromCfg config error add_list=%s", json.pretty_encode(add_list)))
        return ErrorCode.ConfigError
    end
    if table.size(add_items) > 0 then
        local ret_code = scripts.Bag.TryEmptyEnough(BagDef.BagType.Cangku, add_items, 0)
        if ret_code ~= ErrorCode.None then
            return ret_code
        end
    end

    local stack_items, unstack_items, deal_coins = {}, {}, {}
    local ok = ItemDefine.GetItemDataFromIdCount(add_items, add_coins, stack_items, unstack_items, deal_coins)
    if not ok then
        moon.error(string.format("ItemDefine.GetItemDataFromIdCount config error add_items=%s",
            json.pretty_encode(add_items)))
        moon.error(string.format("ItemDefine.GetItemDataFromIdCount config error add_coins=%s",
            json.pretty_encode(add_coins)))
        return ErrorCode.ConfigError
    end

    local bag_change_log = {}
    if table.size(stack_items) + table.size(unstack_items) > 0 then
        local err_code_items = scripts.Bag.AddItems(BagDef.BagType.Cangku, stack_items, unstack_items, bag_change_log)
        if err_code_items ~= ErrorCode.None then
            scripts.Bag.RollBackWithChange(bag_change_log)
            return err_code_items
        end
    end
    scripts.Bag.SaveAndLog(bag_change_log, ItemDef.ChangeReason.TakeMissionReward)

    -- 触发添加活跃度
    Mission.TriggerCondition(MissionDef.EConditionIds.ACTIVITY_CNT, {}, add_vitality)

    return ErrorCode.None
end

function Mission.GetPeriodMissionReward(mission_info, period_ids)
    if not mission_info.period_info.complete_day_ids
        or not mission_info.period_info.complete_week_ids
        or not mission_info.period_info.complete_month_ids
        or (table.size(mission_info.period_info.complete_day_ids) <= 0
            and table.size(mission_info.period_info.complete_week_ids) <= 0
            and table.size(mission_info.period_info.complete_month_ids) <= 0) then
        return ErrorCode.MissionNotFound
    end

    local now_ts = moon.time()
    local add_list = {}
    local add_vitality = 0
    local add_treasures = {}
    for _, mission_id in pairs(period_ids) do
        local mission_state = MissionDef.ETaskState.NO_PROGRESS
        if mission_info.period_info.complete_day_ids[mission_id] then
            mission_state = mission_info.period_info.complete_day_ids[mission_id]
        elseif mission_info.period_info.complete_week_ids[mission_id] then
            mission_state = mission_info.period_info.complete_week_ids[mission_id]
        elseif mission_info.period_info.complete_month_ids[mission_id] then
            mission_state = mission_info.period_info.complete_month_ids[mission_id]
        end

        if mission_state ~= MissionDef.ETaskState.COMPLETE then
            return ErrorCode.MissionAlreadyGetReward
        end
        local period_cfg = GameCfg.PeriodMissionConfig[mission_id]
        if not period_cfg then
            return ErrorCode.ConfigError
        end
        if period_cfg.end_time and period_cfg.end_time ~= 0 and now_ts > period_cfg.end_time then
            return ErrorCode.MissionOverTime
        end
        if period_cfg.rewards then
            for re_id, re_cnt in pairs(period_cfg.rewards) do
                if not add_list[re_id] then
                    add_list[re_id] = re_cnt
                else
                    add_list[re_id] = add_list[re_id] + re_cnt
                end
            end
        end
        if period_cfg.vitality and period_cfg.vitality > 0 then
            add_vitality = add_vitality + period_cfg.vitality
        end
        if period_cfg.treasure_chest then
            for chest_id, chest_cnt in pairs(period_cfg.treasure_chest) do
                if not add_treasures[chest_id] then
                    add_treasures[chest_id] = chest_cnt
                else
                    add_treasures[chest_id] = add_treasures[chest_id] + chest_cnt
                end
            end
        end
    end

    -- 发放宝箱奖励（局外宝箱系统）
    for chest_id, chest_cnt in pairs(add_treasures) do
        scripts.Shop.AddTreasure(chest_id, chest_cnt)
    end

    -- 整理道具奖励
    local add_items, add_coins = {}, {}
    ItemDefine.GetItemsFromCfg(add_list, 1, false, add_items, add_coins)
    if table.size(add_items) + table.size(add_coins) <= 0 and table.size(add_treasures) <= 0 then
        moon.error(string.format("ItemDefine.GetItemsFromCfg config error add_list=%s", json.pretty_encode(add_list)))
        return ErrorCode.ConfigError
    end
    if table.size(add_items) > 0 then
        local ret_code = scripts.Bag.TryEmptyEnough(BagDef.BagType.Cangku, add_items, 0)
        if ret_code ~= ErrorCode.None then
            return ret_code
        end
    end

    local stack_items, unstack_items, deal_coins = {}, {}, {}
    local ok = ItemDefine.GetItemDataFromIdCount(add_items, add_coins, stack_items, unstack_items, deal_coins)
    if not ok then
        moon.error(string.format("ItemDefine.GetItemDataFromIdCount config error add_items=%s",
            json.pretty_encode(add_items)))
        moon.error(string.format("ItemDefine.GetItemDataFromIdCount config error add_coins=%s",
            json.pretty_encode(add_coins)))
        return ErrorCode.ConfigError
    end

    local bag_change_log = {}
    if table.size(stack_items) + table.size(unstack_items) > 0 then
        local err_code_items = scripts.Bag.AddItems(BagDef.BagType.Cangku, stack_items, unstack_items, bag_change_log)
        if err_code_items ~= ErrorCode.None then
            scripts.Bag.RollBackWithChange(bag_change_log)
            return err_code_items
        end
    end
    scripts.Bag.SaveAndLog(bag_change_log, ItemDef.ChangeReason.TakeMissionReward)

    -- 触发添加活跃度
    Mission.TriggerCondition(MissionDef.EConditionIds.ACTIVITY_CNT, {}, add_vitality)

    return ErrorCode.None
end

function Mission.PBGetPlayerMissionInfoReqCmd(req)
    if not req.msg.uid then
        return context.S2C(context.net_id, CmdCode.PBGetPlayerMissionInfoRspCmd, {
            code = ErrorCode.ParamInvalid,
            error = "无效请求参数",
            uid = context.uid,
        }, req.msg_context.stub_id)
    end

    local mission_info = scripts.UserModel.GetMissionInfo()
    if not mission_info then
        return context.S2C(context.net_id, CmdCode.PBGetPlayerMissionInfoRspCmd, {
            code = ErrorCode.ServerInternalError,
            error = "获取玩家任务信息失败",
            uid = context.uid,
        }, req.msg_context.stub_id)
    end

    Mission.DelOverTimeLinearMission(mission_info)

    local now_ts = moon.time()
    local new_complete_period_ids = {}
    if Mission.CheckPeriodInfo(mission_info, now_ts, new_complete_period_ids) then
        if table.size(new_complete_period_ids) > 0 then
            -- Mission.PeriodMissionComplete(mission_info, new_complete_period_ids)
            Mission.PeriodMissionComplete_new(mission_info, new_complete_period_ids, nil, false)
        end
        Mission.makePeriodMap(mission_info)
        Mission.SaveMissionsNow()
    end

    -- 检查活动任务
    local new_complete_activity_ids = {}
    if Mission.CheckActivityInfo(mission_info, now_ts, new_complete_activity_ids) then
        if table.size(new_complete_activity_ids) > 0 then
            -- Mission.ActivityMissionComplete(mission_info, new_complete_activity_ids)
            Mission.ActivityMissionComplete_new(mission_info, new_complete_activity_ids, nil, false)
        end
        Mission.makeActivityMap(mission_info)
        Mission.SaveMissionsNow()
    end

    return context.S2C(context.net_id, CmdCode.PBGetPlayerMissionInfoRspCmd, {
        code = ErrorCode.None,
        error = "获取玩家任务信息成功",
        uid = context.uid,
        player_mission_info = mission_info,
    }, req.msg_context.stub_id)
end

function Mission.PBGetMissionRewardReqCmd(req)
    if not req.msg.uid
        or { not req.msg.linear_ids and not req.msg.period_ids and not req.msg.achivement_ids
            and not req.msg.activity_ids } then
        return context.S2C(context.net_id, CmdCode.PBGetMissionRewardRspCmd, {
            code = ErrorCode.ParamInvalid,
            error = "无效请求参数",
            uid = context.uid,
        }, req.msg_context.stub_id)
    end

    local mission_info = scripts.UserModel.GetMissionInfo()
    if not mission_info then
        return context.S2C(context.net_id, CmdCode.PBGetMissionRewardRspCmd, {
            code = ErrorCode.ServerInternalError,
            error = "获取玩家任务信息失败",
            uid = context.uid,
        }, req.msg_context.stub_id)
    end

    local linear_ids = req.msg.linear_ids or {}
    local period_ids = req.msg.period_ids or {}
    local achivement_ids = req.msg.achivement_ids or {}
    local activity_ids = req.msg.activity_ids or {}
    if table.size(linear_ids) > 0 then
        if table.size(period_ids) > 0 or table.size(achivement_ids) > 0 or table.size(activity_ids) > 0 then
            return context.S2C(context.net_id, CmdCode.PBGetMissionRewardRspCmd, {
                code = ErrorCode.MissionManyType,
                error = "无效请求参数",
                uid = context.uid,
                linear_ids = linear_ids,
                period_ids = period_ids,
                achivement_ids = achivement_ids,
                activity_ids = activity_ids,
            }, req.msg_context.stub_id)
        end
    elseif table.size(period_ids) > 0 then
        if table.size(linear_ids) > 0 or table.size(achivement_ids) > 0 or table.size(activity_ids) > 0 then
            return context.S2C(context.net_id, CmdCode.PBGetMissionRewardRspCmd, {
                code = ErrorCode.MissionManyType,
                error = "无效请求参数",
                uid = context.uid,
                linear_ids = linear_ids,
                period_ids = period_ids,
                achivement_ids = achivement_ids,
                activity_ids = activity_ids,
            }, req.msg_context.stub_id)
        end
    elseif table.size(achivement_ids) > 0 then
        if table.size(linear_ids) > 0 or table.size(period_ids) > 0 or table.size(activity_ids) > 0 then
            return context.S2C(context.net_id, CmdCode.PBGetMissionRewardRspCmd, {
                code = ErrorCode.MissionManyType,
                error = "无效请求参数",
                uid = context.uid,
                linear_ids = linear_ids,
                period_ids = period_ids,
                achivement_ids = achivement_ids,
                activity_ids = activity_ids,
            }, req.msg_context.stub_id)
        end
    elseif table.size(activity_ids) > 0 then
        if table.size(linear_ids) > 0 or table.size(period_ids) > 0 or table.size(achivement_ids) > 0 then
            return context.S2C(context.net_id, CmdCode.PBGetMissionRewardRspCmd, {
                code = ErrorCode.MissionManyType,
                error = "无效请求参数",
                uid = context.uid,
                linear_ids = linear_ids,
                period_ids = period_ids,
                achivement_ids = achivement_ids,
                activity_ids = activity_ids,
            }, req.msg_context.stub_id)
        end
    end

    local change_log = {
        linears = {},
        periods = {},
        achievements = {},
        activitys = {},
        periods_all_change = false
    }
    local now_ts = moon.time()
    local new_complete_period_ids = {}
    if Mission.CheckPeriodInfo(mission_info, now_ts, new_complete_period_ids) then
        if table.size(new_complete_period_ids) > 0 then
            -- Mission.PeriodMissionComplete(mission_info, new_complete_period_ids)
            Mission.PeriodMissionComplete_new(mission_info, new_complete_period_ids, nil, false)
        end
        Mission.makePeriodMap(mission_info)
        change_log.periods_all_change = true
    end

    local ret_code = ErrorCode.None
    if table.size(linear_ids) > 0 then
        ret_code = Mission.GetLinearMissionReward(mission_info, linear_ids)
        if ret_code == ErrorCode.None then
            for _, mission_id in pairs(linear_ids) do
                mission_info.linear_info.complete_ids[mission_id] = MissionDef.ETaskState.GET_REWARD
                change_log.linears[mission_id] = MissionDef.ETaskState.GET_REWARD
            end
        end
    end
    if table.size(period_ids) > 0 then
        ret_code = Mission.GetPeriodMissionReward(mission_info, period_ids)
        if ret_code == ErrorCode.None then
            for _, mission_id in pairs(period_ids) do
                if mission_info.period_info.complete_day_ids[mission_id] then
                    mission_info.period_info.complete_day_ids[mission_id] = MissionDef.ETaskState.GET_REWARD
                elseif mission_info.period_info.complete_week_ids[mission_id] then
                    mission_info.period_info.complete_week_ids[mission_id] = MissionDef.ETaskState.GET_REWARD
                elseif mission_info.period_info.complete_month_ids[mission_id] then
                    mission_info.period_info.complete_month_ids[mission_id] = MissionDef.ETaskState.GET_REWARD
                end
                change_log.periods[mission_id] = MissionDef.ETaskState.GET_REWARD
            end
        end
    end
    if table.size(achivement_ids) > 0 then
        ret_code = Mission.GetAchievementMissionReward(mission_info, achivement_ids)
    end
    if table.size(activity_ids) > 0 then
        ret_code = Mission.GetActivityMissionReward(mission_info, activity_ids)
        if ret_code == ErrorCode.None then
            for _, mission_id in pairs(activity_ids) do
                mission_info.activity_info.complete_ids[mission_id] = MissionDef.ETaskState.GET_REWARD
                change_log.activitys[mission_id] = MissionDef.ETaskState.GET_REWARD
            end
        end
    end

    if ret_code ~= ErrorCode.None then
        return context.S2C(context.net_id, CmdCode.PBGetMissionRewardRspCmd, {
            code = ret_code,
            error = "获取任务奖励失败",
            uid = context.uid,
            linear_ids = linear_ids,
            period_ids = period_ids,
            achivement_ids = achivement_ids,
            activity_ids = activity_ids,
        }, req.msg_context.stub_id)
    end

    Mission.SaveAndSync(change_log)

    return context.S2C(context.net_id, CmdCode.PBGetMissionRewardRspCmd, {
        code = ErrorCode.None,
        error = "获取任务奖励成功",
        uid = context.uid,
        linear_ids = linear_ids,
        period_ids = period_ids,
        achivement_ids = achivement_ids,
        activity_ids = activity_ids,
    }, req.msg_context.stub_id)
end

function Mission.PBRrefreshMissionReqCmd(req)
    if not req.msg.uid
        or not req.msg.old_mission_id then
        return context.S2C(context.net_id, CmdCode.PBRrefreshMissionRspCmd, {
            code = ErrorCode.ParamInvalid,
            error = "无效请求参数",
            uid = context.uid,
        }, req.msg_context.stub_id)
    end

    local mission_info = scripts.UserModel.GetMissionInfo()
    if not mission_info then
        return context.S2C(context.net_id, CmdCode.PBGetMissionRewardRspCmd, {
            code = ErrorCode.ServerInternalError,
            error = "获取玩家任务信息失败",
            uid = context.uid,
        }, req.msg_context.stub_id)
    end

    Mission.DelOverTimeLinearMission(mission_info)

    local now_ts = moon.time()
    local new_complete_period_ids = {}
    if Mission.CheckPeriodInfo(mission_info, now_ts, new_complete_period_ids) then
        if table.size(new_complete_period_ids) > 0 then
            -- Mission.PeriodMissionComplete(mission_info, new_complete_period_ids)
            Mission.PeriodMissionComplete_new(mission_info, new_complete_period_ids, nil, false)
        end
        Mission.makePeriodMap(mission_info)
        Mission.SaveMissionsNow()
    end

    local ret_code, replace_id = Mission.ReplaceMission(mission_info, req.msg.old_mission_id)
    if ret_code ~= ErrorCode.None or not replace_id then
        return context.S2C(context.net_id, CmdCode.PBRrefreshMissionRspCmd, {
            code = ret_code,
            error = "刷新任务失败",
            uid = context.uid,
            old_mission_id = req.msg.old_mission_id,
        }, req.msg_context.stub_id)
    end

    local new_mission_data = mission_info.period_info.now_day_mission_datas[replace_id]
    local change_log = {
        periods = {},
    }
    if new_mission_data then
        change_log.periods[replace_id] = MissionDef.ETaskState.NO_COMPLETE
    else
        change_log.periods[replace_id] = MissionDef.ETaskState.COMPLETE
    end
    Mission.SaveAndSync(change_log)

    return context.S2C(context.net_id, CmdCode.PBRrefreshMissionRspCmd, {
        code = ErrorCode.None,
        error = "刷新任务成功",
        uid = context.uid,
        new_mission_data = new_mission_data,
        new_complete_id = replace_id,
    }, req.msg_context.stub_id)
end

return Mission