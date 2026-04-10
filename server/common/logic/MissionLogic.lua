local moon = require "moon"
local common = require "common"
local json = require("json")
local ItemDefine = require("common.logic.ItemDefine")
local MissionDef = require("common.def.MissionDef")
local GameCfg = common.GameCfg

local MissionLogic = {}

function MissionLogic.CheckCondition(condition_id, params, change_cnt, cond_datas)
    local is_change = false
    for _, condition in pairs(cond_datas) do
        if condition.cond_id == condition_id then
            if condition.is_complete == 1 then
                return is_change
            end

            if condition_id == MissionDef.EConditionIds.SIGN_CNT then
                condition.now_value = condition.now_value + change_cnt
                if condition.now_value >= condition.target_value then
                    condition.is_complete = 1
                end
                is_change = true
            elseif condition_id == MissionDef.EConditionIds.ONLINE_TIME then
                condition.now_value = condition.now_value + change_cnt
                if condition.now_value >= condition.target_value then
                    condition.is_complete = 1
                end
                is_change = true
            elseif condition_id == MissionDef.EConditionIds.ACTIVITY_CNT then
                condition.now_value = condition.now_value + change_cnt
                if condition.now_value >= condition.target_value then
                    condition.is_complete = 1
                end
                is_change = true
            elseif condition_id == MissionDef.EConditionIds.ACCOUNT_LEVEL then
                condition.now_value = change_cnt
                if condition.now_value >= condition.target_value then
                    condition.is_complete = 1
                end
                is_change = true
            elseif condition_id == MissionDef.EConditionIds.OUT_TASK_CNT then
                if table.size(params) >= 2 and table.size(condition.params) >= 2 then
                    if (condition.params[1] == 0 or params[1] == condition.params[1])
                        and (condition.params[2] == 0 or params[2] == condition.params[2]) then
                        condition.now_value = condition.now_value + change_cnt
                        if condition.now_value >= condition.target_value then
                            condition.is_complete = 1
                        end
                        is_change = true
                    end
                end
            elseif condition_id == MissionDef.EConditionIds.IN_TASK_CNT then
                if table.size(params) >= 1 and table.size(condition.params) >= 1 then
                    if condition.params[1] == 0 or params[1] == condition.params[1] then
                        condition.now_value = condition.now_value + change_cnt
                        if condition.now_value >= condition.target_value then
                            condition.is_complete = 1
                        end
                        is_change = true
                    end
                end
            elseif condition_id == MissionDef.EConditionIds.KILL_MONSTER_CNT then
                if table.size(params) >= 2 and table.size(condition.params) >= 2 then
                    if (condition.params[1] == 0 or params[1] == condition.params[1])
                        and (condition.params[2] == 0 or params[2] == condition.params[2]) then
                        condition.now_value = condition.now_value + change_cnt
                        if condition.now_value >= condition.target_value then
                            condition.is_complete = 1
                        end
                        is_change = true
                    end
                end
            elseif condition_id == MissionDef.EConditionIds.GET_ITEM_CNT then
                if table.size(params) >= 3 and table.size(condition.params) >= 3 then
                    local is_match_arr_param = false
                    for _, c_param in pairs(condition.arr_params) do
                        if c_param == 0 or condition.params[3] == c_param then
                            is_match_arr_param = true
                            break
                        end
                    end
                    if is_match_arr_param
                        and (condition.params[1] == 0 or params[1] == condition.params[1])
                        and (condition.params[2] == 0 or params[2] == condition.params[2]) then
                        condition.now_value = condition.now_value + change_cnt
                        if condition.now_value >= condition.target_value then
                            condition.is_complete = 1
                        end
                        is_change = true
                    end
                end
            elseif condition_id == MissionDef.EConditionIds.UNLOCK_ROLE_SKIN_CNT then
                condition.now_value = change_cnt
                if condition.now_value >= condition.target_value then
                    condition.is_complete = 1
                end
                is_change = true
            elseif condition_id == MissionDef.EConditionIds.UNLOCK_ROLE_SKIN then
                if table.size(params) >= 1 and table.size(condition.params) >= 1 then
                    if params[1] == condition.params[1] then
                        condition.now_value = change_cnt
                        if condition.now_value >= condition.target_value then
                            condition.is_complete = 1
                        end
                        is_change = true
                    end
                end
            elseif condition_id == MissionDef.EConditionIds.UNLOCK_ROLE_CNT then
                condition.now_value = change_cnt
                if condition.now_value >= condition.target_value then
                    condition.is_complete = 1
                end
                is_change = true
            elseif condition_id == MissionDef.EConditionIds.UNLOCK_ROLE then
                if table.size(params) >= 1 and table.size(condition.params) >= 1 then
                    if params[1] == condition.params[1] then
                        condition.now_value = change_cnt
                        if condition.now_value >= condition.target_value then
                            condition.is_complete = 1
                        end
                        is_change = true
                    end
                end
            elseif condition_id == MissionDef.EConditionIds.BATTLE_CHAPTER_CNT then
                if table.size(params) >= 2 and table.size(condition.params) >= 2 then
                    local is_match_arr_param = false
                    for _, c_param in pairs(condition.arr_params) do
                        if c_param == 0 or condition.params[2] == c_param then
                            is_match_arr_param = true
                            break
                        end
                    end
                    if is_match_arr_param
                        and (condition.params[1] == 0 or params[1] == condition.params[1]) then
                        condition.now_value = condition.now_value + change_cnt
                        if condition.now_value >= condition.target_value then
                            condition.is_complete = 1
                        end
                        is_change = true
                    end
                end
            elseif condition_id == MissionDef.EConditionIds.RECHARGE_CNT then
                condition.now_value = condition.now_value + change_cnt
                if condition.now_value >= condition.target_value then
                    condition.is_complete = 1
                end
                is_change = true
            elseif condition_id == MissionDef.EConditionIds.GET_TREASURE_CNT then
                if table.size(params) >= 1 and table.size(condition.params) >= 1 then
                    if params[1] == condition.params[1] then
                        condition.now_value = change_cnt
                        if condition.now_value >= condition.target_value then
                            condition.is_complete = 1
                        end
                        is_change = true
                    end
                end
            elseif condition_id == MissionDef.EConditionIds.OPEN_TREASURE_CNT then
                if table.size(params) >= 1 and table.size(condition.params) >= 1 then
                    if params[1] == condition.params[1] then
                        condition.now_value = change_cnt
                        if condition.now_value >= condition.target_value then
                            condition.is_complete = 1
                        end
                        is_change = true
                    end
                end
            elseif condition_id == MissionDef.EConditionIds.LIGHT_EQP_CNT then
                if table.size(params) >= 2 and table.size(condition.params) >= 2 then
                    local is_match_arr_param = false
                    for _, c_param in pairs(condition.arr_params) do
                        if c_param == 0 or condition.params[2] == c_param then
                            is_match_arr_param = true
                            break
                        end
                    end
                    if is_match_arr_param
                        and (condition.params[1] == 0 or params[1] == condition.params[1]) then
                        condition.now_value = condition.now_value + change_cnt
                        if condition.now_value >= condition.target_value then
                            condition.is_complete = 1
                        end
                        is_change = true
                    end
                end
            elseif condition_id == MissionDef.EConditionIds.APPRAISE_ANTIQUE_CNT then
                if table.size(params) >= 1 and table.size(condition.params) >= 1 then
                    local is_match_arr_param = false
                    for _, c_param in pairs(condition.arr_params) do
                        if c_param == 0 or condition.params[1] == c_param then
                            is_match_arr_param = true
                            break
                        end
                    end
                    if is_match_arr_param then
                        condition.now_value = condition.now_value + change_cnt
                        if condition.now_value >= condition.target_value then
                            condition.is_complete = 1
                        end
                        is_change = true
                    end
                end
            elseif condition_id == MissionDef.EConditionIds.ROLE_STAR_CNT then
                if table.size(params) >= 1 and table.size(condition.params) >= 1 then
                    if params[1] == condition.params[1] and change_cnt > condition.now_value then
                        condition.now_value = change_cnt
                        if condition.now_value >= condition.target_value then
                            condition.is_complete = 1
                        end
                        is_change = true
                    end
                end
            elseif condition_id == MissionDef.EConditionIds.ROLE_LEVEL_CNT then
                if table.size(params) >= 1 and table.size(condition.params) >= 1 then
                    if params[1] == condition.params[1] and change_cnt > condition.now_value then
                        condition.now_value = change_cnt
                        if condition.now_value >= condition.target_value then
                            condition.is_complete = 1
                        end
                        is_change = true
                    end
                end
            elseif condition_id == MissionDef.EConditionIds.ROLE_STAR then
                if table.size(params) >= 1 and table.size(condition.params) >= 1 then
                    if (condition.params[1] == 0 or params[1] == condition.params[1])
                        and change_cnt > condition.now_value then
                        condition.now_value = change_cnt
                        if condition.now_value >= condition.target_value then
                            condition.is_complete = 1
                        end
                        is_change = true
                    end
                end
            elseif condition_id == MissionDef.EConditionIds.ROLE_LEVEL then
                if table.size(params) >= 1 and table.size(condition.params) >= 1 then
                    if (condition.params[1] == 0 or params[1] == condition.params[1])
                        and change_cnt > condition.now_value then
                        condition.now_value = change_cnt
                        if condition.now_value >= condition.target_value then
                            condition.is_complete = 1
                        end
                        is_change = true
                    end
                end
            elseif condition_id == MissionDef.EConditionIds.ROLE_UNLOCK_SKILL_CNT then
                if table.size(params) >= 1 and table.size(condition.params) >= 1 then
                    if (condition.params[1] == 0 or params[1] == condition.params[1])
                        and change_cnt > condition.now_value then
                        condition.now_value = change_cnt
                        if condition.now_value >= condition.target_value then
                            condition.is_complete = 1
                        end
                        is_change = true
                    end
                end
            elseif condition_id == MissionDef.EConditionIds.ROLE_UNLOCK_SKILL then
                if table.size(params) >= 2 and table.size(condition.params) >= 2 then
                    if params[1] == condition.params[1]
                        and params[2] == condition.params[2] then
                        condition.now_value = change_cnt
                        if condition.now_value >= condition.target_value then
                            condition.is_complete = 1
                        end
                        is_change = true
                    end
                end
            elseif condition_id == MissionDef.EConditionIds.ROLE_EQUIP_MAGIC_ITEM_CNT then
                if table.size(params) >= 2 and table.size(condition.params) >= 2 then
                    if (condition.params[1] == 0 or params[1] == condition.params[1])
                        and params[2] == condition.params[2]
                        and change_cnt > condition.now_value then
                        condition.now_value = change_cnt
                        if condition.now_value >= condition.target_value then
                            condition.is_complete = 1
                        end
                        is_change = true
                    end
                end
            elseif condition_id == MissionDef.EConditionIds.INLAY_TABOO_WORD_CNT then
                if table.size(params) >= 2 and table.size(condition.params) >= 2 then
                    local is_match_arr_param = false
                    for _, c_param in pairs(condition.arr_params) do
                        if c_param == 0 or condition.params[2] == c_param then
                            is_match_arr_param = true
                            break
                        end
                    end
                    if is_match_arr_param
                        and (condition.params[1] == 0 or params[1] == condition.params[1]) then
                        condition.now_value = condition.now_value + change_cnt
                        if condition.now_value >= condition.target_value then
                            condition.is_complete = 1
                        end
                        is_change = true
                    end
                end
            elseif condition_id == MissionDef.EConditionIds.SHOW_ANTIQUE_CNT then
                if table.size(params) >= 1 and table.size(condition.params) >= 1 then
                    if params[1] == condition.params[1] and change_cnt > condition.now_value then
                        condition.now_value = change_cnt
                        if condition.now_value >= condition.target_value then
                            condition.is_complete = 1
                        end
                        is_change = true
                    end
                end
            elseif condition_id == MissionDef.EConditionIds.UNLOCK_GOD_CNT then
                if change_cnt > condition.now_value then
                    condition.now_value = change_cnt
                    if condition.now_value >= condition.target_value then
                        condition.is_complete = 1
                    end
                    is_change = true
                end
            elseif condition_id == MissionDef.EConditionIds.UNLOCK_GOD then
                if table.size(params) >= 1 and table.size(condition.params) >= 1 then
                    if params[1] == condition.params[1] then
                        condition.now_value = change_cnt
                        if condition.now_value >= condition.target_value then
                            condition.is_complete = 1
                        end
                        is_change = true
                    end
                end
            elseif condition_id == MissionDef.EConditionIds.GOD_LEVEL then
                if table.size(params) >= 1 and table.size(condition.params) >= 1 then
                    if (condition.params[1] == 0 or params[1] == condition.params[1])
                        and change_cnt > condition.now_value then
                        condition.now_value = change_cnt
                        if condition.now_value >= condition.target_value then
                            condition.is_complete = 1
                        end
                        is_change = true
                    end
                end
            elseif condition_id == MissionDef.EConditionIds.GOD_ENTER_BATTLE_CNT then
                if table.size(params) >= 1 and table.size(condition.params) >= 1 then
                    if condition.params[1] == 0 or params[1] == condition.params[1] then
                        condition.now_value = change_cnt
                        if condition.now_value >= condition.target_value then
                            condition.is_complete = 1
                        end
                        is_change = true
                    end
                end
            elseif condition_id == MissionDef.EConditionIds.MAKE_ITEM_CNT then
                if table.size(params) >= 3 and table.size(condition.params) >= 3 then
                    local is_match_arr_param = false
                    for _, c_param in pairs(condition.arr_params) do
                        if c_param == 0 or condition.params[3] == c_param then
                            is_match_arr_param = true
                            break
                        end
                    end
                    if is_match_arr_param
                        and (condition.params[1] == 0 or params[1] == condition.params[1])
                        and (condition.params[2] == 0 or params[2] == condition.params[2]) then
                        condition.now_value = condition.now_value + change_cnt
                        if condition.now_value >= condition.target_value then
                            condition.is_complete = 1
                        end
                        is_change = true
                    end
                end
            elseif condition_id == MissionDef.EConditionIds.CONSUME_ITEM_CNT then
                if table.size(params) >= 3 and table.size(condition.params) >= 3 then
                    local is_match_arr_param = false
                    for _, c_param in pairs(condition.arr_params) do
                        if c_param == 0 or condition.params[3] == c_param then
                            is_match_arr_param = true
                            break
                        end
                    end
                    if is_match_arr_param
                        and (condition.params[1] == 0 or params[1] == condition.params[1])
                        and (condition.params[2] == 0 or params[2] == condition.params[2]) then
                        condition.now_value = condition.now_value + change_cnt
                        if condition.now_value >= condition.target_value then
                            condition.is_complete = 1
                        end
                        is_change = true
                    end
                end
            elseif condition_id == MissionDef.EConditionIds.GET_LINGBI_COIN_CNT then
                if change_cnt > condition.now_value then
                    condition.now_value = change_cnt
                    if condition.now_value >= condition.target_value then
                        condition.is_complete = 1
                    end
                    is_change = true
                end
            elseif condition_id == MissionDef.EConditionIds.GET_LINGBI_COIN then
                if change_cnt > condition.now_value then
                    condition.now_value = change_cnt
                    if condition.now_value >= condition.target_value then
                        condition.is_complete = 1
                    end
                    is_change = true
                end
            elseif condition_id == MissionDef.EConditionIds.GET_BOOTY_VALUE_CNT then
                if table.size(params) >= 2 and table.size(condition.params) >= 2 then
                    local is_match_arr_param = false
                    for _, c_param in pairs(condition.arr_params) do
                        if c_param == 0 or condition.params[2] == c_param then
                            is_match_arr_param = true
                            break
                        end
                    end
                    if is_match_arr_param
                        and (condition.params[1] == 0 or params[1] == condition.params[1]) then
                        condition.now_value = condition.now_value + change_cnt
                        if condition.now_value >= condition.target_value then
                            condition.is_complete = 1
                        end
                        is_change = true
                    end
                end
            elseif condition_id == MissionDef.EConditionIds.UNLOCK_ITEM_SKIN_CNT then
                if change_cnt > condition.now_value then
                    condition.now_value = change_cnt
                    if condition.now_value >= condition.target_value then
                        condition.is_complete = 1
                    end
                    is_change = true
                end
            elseif condition_id == MissionDef.EConditionIds.TOTAL_RECHARGE_CNT then
                if change_cnt > condition.now_value then
                    condition.now_value = change_cnt
                    if condition.now_value >= condition.target_value then
                        condition.is_complete = 1
                    end
                    is_change = true
                end
            elseif condition_id == MissionDef.EConditionIds.ACHIEVEMENT_CNT then
                if change_cnt > condition.now_value then
                    condition.now_value = change_cnt
                    if condition.now_value >= condition.target_value then
                        condition.is_complete = 1
                    end
                    is_change = true
                end
            elseif condition_id == MissionDef.EConditionIds.ROLE_EQUIP_DIAGRAMS_CNT then
                if table.size(params) >= 2 and table.size(condition.params) >= 2 then
                    if (condition.params[1] == 0 or params[1] == condition.params[1])
                        and params[2] == condition.params[2]
                        and change_cnt > condition.now_value then
                        condition.now_value = change_cnt
                        if condition.now_value >= condition.target_value then
                            condition.is_complete = 1
                        end
                        is_change = true
                    end
                end
            end

            return is_change
        end
    end
end

function MissionLogic.CheckTask(condition_id, params, change_cnt, trigger_tasks)
    if not trigger_tasks or table.size(trigger_tasks) == 0 then
        return {}
    end

    local change_tasks = {}
    local now_ts = moon.time()
    for task_id, task in pairs(trigger_tasks) do
        if task.state == MissionDef.ETaskState.NO_COMPLETE
            and (task.beg_ts == 0 or task.beg_ts <= now_ts)
            and (task.end_ts == 0 or now_ts <= task.end_ts) then
            local is_change = MissionLogic.CheckCondition(condition_id, params, change_cnt, task.cond_datas)
            if is_change then
                table.insert(change_tasks, task_id)
            end
        end
    end

    return change_tasks
end

function MissionLogic.CheckSingleTask(condition_id, params, change_cnt, task_data)
    if not task_data then
        return
    end
    return MissionLogic.CheckCondition(condition_id, params, change_cnt, task_data.cond_datas)
end

return MissionLogic
