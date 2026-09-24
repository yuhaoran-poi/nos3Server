local moon = require "moon"
local common = require "common"
local json = require("json")
local ItemDefine = require("common.logic.ItemDefine")
local MissionDef = require("common.def.MissionDef")
local GameCfg = common.GameCfg

local MissionLogic = {}

-- 判断条件参数是否视为"不限"：
--   nil / 0            : 配置文档语义，0 = 不限
-- 其余数值按具体 id 精确匹配: 策划后续配置任何具体道具/分类/来源 id，均无需改动此处代码。
local function IsUnlimitParam(v)
    return v == nil or v == 0
end

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
                if table.size(params) >= 3 then
                    local is_match_arr_param = false
                    if not condition.arr_params or table.size(condition.arr_params) == 0 then
                        is_match_arr_param = true
                    else
                        for _, c_param in pairs(condition.arr_params) do
                            if c_param == 0 or params[3] == c_param then
                                is_match_arr_param = true
                                break
                            end
                        end
                    end
                    if is_match_arr_param
                        and (IsUnlimitParam(condition.params[1]) or params[1] == condition.params[1])
                        and (IsUnlimitParam(condition.params[2]) or params[2] == condition.params[2]) then
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
                if table.size(params) >= 2 then
                    local is_match_arr = false
                    for _, c_param in pairs(condition.arr_params) do
                        if c_param == 0 or params[1] == c_param then
                            is_match_arr = true
                            break
                        end
                    end
                    if is_match_arr
                        and (condition.params[1] == nil or condition.params[1] == 0
                            or params[2] == condition.params[1]) then
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
                if table.size(params) >= 3 then
                    local is_match_arr_param = false
                    if not condition.arr_params or table.size(condition.arr_params) == 0 then
                        is_match_arr_param = true
                    else
                        for _, c_param in pairs(condition.arr_params) do
                            if c_param == 0 or params[1] == c_param then
                                is_match_arr_param = true
                                break
                            end
                        end
                    end
                    if is_match_arr_param
                        and (IsUnlimitParam(condition.params[1]) or params[2] == condition.params[1])
                        and (IsUnlimitParam(condition.params[2]) or params[3] == condition.params[2]) then
                        condition.now_value = condition.now_value + change_cnt
                        if condition.now_value >= condition.target_value then
                            condition.is_complete = 1
                        end
                        is_change = true
                    end
                end
            elseif condition_id == MissionDef.EConditionIds.CONSUME_ITEM_CNT then
                if table.size(params) >= 3 then
                    local is_match_arr_param = false
                    if not condition.arr_params or table.size(condition.arr_params) == 0 then
                        is_match_arr_param = true
                    else
                        for _, c_param in pairs(condition.arr_params) do
                            if c_param == 0 or params[3] == c_param then
                                is_match_arr_param = true
                                break
                            end
                        end
                    end
                    if is_match_arr_param
                        and (IsUnlimitParam(condition.params[1]) or params[1] == condition.params[1])
                        and (IsUnlimitParam(condition.params[2]) or params[2] == condition.params[2]) then
                        condition.now_value = condition.now_value + change_cnt
                        if condition.now_value >= condition.target_value then
                            condition.is_complete = 1
                        end
                        is_change = true
                    end
                end
            elseif condition_id == MissionDef.EConditionIds.GET_LINGBI_COIN_CNT then
                condition.now_value = condition.now_value + change_cnt
                if condition.now_value >= condition.target_value then
                    condition.is_complete = 1
                end
                is_change = true
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
            elseif condition_id == MissionDef.EConditionIds.BATTLE_FINISH_CNT then
                condition.now_value = condition.now_value + change_cnt
                if condition.now_value >= condition.target_value then
                    condition.is_complete = 1
                end
                is_change = true
            elseif condition_id == MissionDef.EConditionIds.SUCCESS_LEAVE_CNT then
                condition.now_value = condition.now_value + change_cnt
                if condition.now_value >= condition.target_value then
                    condition.is_complete = 1
                end
                is_change = true
            elseif condition_id == MissionDef.EConditionIds.CLEAR_KILL_CNT then
                if table.size(params) >= 2 and table.size(condition.params) >= 2 then
                    local is_match_arr = false
                    for _, c_param in pairs(condition.arr_params) do
                        if c_param == 0 or params[1] == c_param then
                            is_match_arr = true
                            break
                        end
                    end
                    if is_match_arr
                        and (condition.params[1] == 0 or params[2] == condition.params[1])
                        and (condition.params[2] == 0 or params[3] == condition.params[2]) then
                        condition.now_value = condition.now_value + change_cnt
                        if condition.now_value >= condition.target_value then
                            condition.is_complete = 1
                        end
                        is_change = true
                    end
                end
            elseif condition_id == MissionDef.EConditionIds.TEAM_BATTLE_FINISH_CNT then
                condition.now_value = condition.now_value + change_cnt
                if condition.now_value >= condition.target_value then
                    condition.is_complete = 1
                end
                is_change = true
            elseif condition_id == MissionDef.EConditionIds.SINGLE_DAMAGE_REACH then
                condition.now_value = change_cnt
                if condition.now_value >= condition.target_value then
                    condition.is_complete = 1
                end
                is_change = true
            elseif condition_id == MissionDef.EConditionIds.TOTAL_DAMAGE then
                condition.now_value = condition.now_value + change_cnt
                if condition.now_value >= condition.target_value then
                    condition.is_complete = 1
                end
                is_change = true
            elseif condition_id == MissionDef.EConditionIds.SINGLE_HEAL_REACH then
                condition.now_value = change_cnt
                if condition.now_value >= condition.target_value then
                    condition.is_complete = 1
                end
                is_change = true
            elseif condition_id == MissionDef.EConditionIds.TOTAL_HEAL then
                condition.now_value = condition.now_value + change_cnt
                if condition.now_value >= condition.target_value then
                    condition.is_complete = 1
                end
                is_change = true
            elseif condition_id == MissionDef.EConditionIds.OPEN_CONTAINER_CNT then
                if table.size(params) >= 2 and table.size(condition.params) >= 2 then
                    if (condition.params[1] == 0 or params[1] == condition.params[1])
                        and (condition.params[2] == 0 or params[2] == condition.params[2]) then
                        condition.now_value = change_cnt
                        if condition.now_value >= condition.target_value then
                            condition.is_complete = 1
                        end
                        is_change = true
                    end
                end
            elseif condition_id == MissionDef.EConditionIds.TOTAL_OPEN_CONTAINER_CNT then
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
            elseif condition_id == MissionDef.EConditionIds.FALL_LIMIT_CNT then
                if table.size(condition.params) >= 1 then
                    if change_cnt <= condition.params[1] then
                        condition.now_value = condition.now_value + 1
                        if condition.now_value >= condition.target_value then
                            condition.is_complete = 1
                        end
                        is_change = true
                    end
                end
            elseif condition_id == MissionDef.EConditionIds.TOTAL_FALL_CNT then
                condition.now_value = condition.now_value + change_cnt
                if condition.now_value >= condition.target_value then
                    condition.is_complete = 1
                end
                is_change = true
            elseif condition_id == MissionDef.EConditionIds.TOTAL_RESCUE_CNT then
                condition.now_value = condition.now_value + change_cnt
                if condition.now_value >= condition.target_value then
                    condition.is_complete = 1
                end
                is_change = true
            elseif condition_id == MissionDef.EConditionIds.TOTAL_GAME_TIME then
                condition.now_value = condition.now_value + change_cnt
                if condition.now_value >= condition.target_value then
                    condition.is_complete = 1
                end
                is_change = true
            elseif condition_id == MissionDef.EConditionIds.CLEAR_TIME_LIMIT then
                -- 通关param_arr章节(0=任意)且完美通关(param2=1时要求)且时长<=param1秒的次数
                -- params: {1=本局通关时长秒, 2=是否完美通关(0/1), 3=章节id}
                if table.size(params) >= 3 then
                    local is_match_arr = false
                    if not condition.arr_params or table.size(condition.arr_params) == 0 then
                        is_match_arr = true
                    else
                        for _, c_param in pairs(condition.arr_params) do
                            if c_param == 0 or params[3] == c_param then
                                is_match_arr = true
                                break
                            end
                        end
                    end
                    if is_match_arr
                        and (IsUnlimitParam(condition.params[1]) or params[1] <= condition.params[1])
                        and (IsUnlimitParam(condition.params[2]) or params[2] == 1) then
                        condition.now_value = condition.now_value + 1
                        if condition.now_value >= condition.target_value then
                            condition.is_complete = 1
                        end
                        is_change = true
                    end
                end
            elseif condition_id == MissionDef.EConditionIds.BRING_OUT_ITEM_CNT then
                if table.size(params) >= 2 and table.size(condition.params) >= 2 then
                    if (condition.params[1] == 0 or params[1] == condition.params[1])
                        and (condition.params[2] == 0 or params[2] == condition.params[2]) then
                        condition.now_value = change_cnt
                        if condition.now_value >= condition.target_value then
                            condition.is_complete = 1
                        end
                        is_change = true
                    end
                end
            elseif condition_id == MissionDef.EConditionIds.TOTAL_BRING_OUT_ITEM_CNT then
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
            elseif condition_id == MissionDef.EConditionIds.SPECIFY_ROLE_BATTLE_CNT then
                if table.size(params) >= 1 and table.size(condition.params) >= 1 then
                    if condition.params[1] == 0 or params[1] == condition.params[1] then
                        condition.now_value = condition.now_value + change_cnt
                        if condition.now_value >= condition.target_value then
                            condition.is_complete = 1
                        end
                        is_change = true
                    end
                end
            elseif condition_id == MissionDef.EConditionIds.BATTLE_WEIGHT_LOAD then
                condition.now_value = change_cnt
                if condition.now_value >= condition.target_value then
                    condition.is_complete = 1
                end
                is_change = true
            elseif condition_id == MissionDef.EConditionIds.TRADE_HOUSE_EARN then
                condition.now_value = condition.now_value + change_cnt
                if condition.now_value >= condition.target_value then
                    condition.is_complete = 1
                end
                is_change = true
            elseif condition_id == MissionDef.EConditionIds.TRADE_HOUSE_SHELF_CNT then
                condition.now_value = condition.now_value + change_cnt
                if condition.now_value >= condition.target_value then
                    condition.is_complete = 1
                end
                is_change = true
            elseif condition_id == MissionDef.EConditionIds.TOTAL_ACCOUNT_EXP then
                condition.now_value = condition.now_value + change_cnt
                if condition.now_value >= condition.target_value then
                    condition.is_complete = 1
                end
                is_change = true
            elseif condition_id == MissionDef.EConditionIds.TOTAL_ROLE_EXP then
                condition.now_value = condition.now_value + change_cnt
                if condition.now_value >= condition.target_value then
                    condition.is_complete = 1
                end
                is_change = true
            elseif condition_id == MissionDef.EConditionIds.TOTAL_GRADE_SCORE then
                condition.now_value = condition.now_value + change_cnt
                if condition.now_value >= condition.target_value then
                    condition.is_complete = 1
                end
                is_change = true
            elseif condition_id == MissionDef.EConditionIds.SINGLE_IN_TASK_CNT then
                if table.size(params) >= 1 and table.size(condition.params) >= 1 then
                    if condition.params[1] == 0 or params[1] == condition.params[1] then
                        condition.now_value = change_cnt
                        if condition.now_value >= condition.target_value then
                            condition.is_complete = 1
                        end
                        is_change = true
                    end
                end
            elseif condition_id == MissionDef.EConditionIds.SINGLE_KILL_MONSTER_CNT then
                if table.size(params) >= 2 and table.size(condition.params) >= 2 then
                    if (condition.params[1] == 0 or params[1] == condition.params[1])
                        and (condition.params[2] == 0 or params[2] == condition.params[2]) then
                        condition.now_value = change_cnt
                        if condition.now_value >= condition.target_value then
                            condition.is_complete = 1
                        end
                        is_change = true
                    end
                end
            elseif condition_id == MissionDef.EConditionIds.SINGLE_GET_ITEM_CNT then
                if table.size(params) >= 3 and table.size(condition.params) >= 2 then
                    local is_match_arr_param = false
                    for _, c_param in pairs(condition.arr_params) do
                        if c_param == 0 or params[1] == c_param then
                            is_match_arr_param = true
                            break
                        end
                    end
                    if is_match_arr_param
                        and (condition.params[1] == 0 or params[2] == condition.params[1])
                        and (condition.params[2] == 0 or params[3] == condition.params[2]) then
                        condition.now_value = change_cnt
                        if condition.now_value >= condition.target_value then
                            condition.is_complete = 1
                        end
                        is_change = true
                    end
                end
            elseif condition_id == MissionDef.EConditionIds.CONTINUE_SIGN_CNT then
                if table.size(params) >= 1 then
                    if params[1] == 1 then
                        condition.now_value = condition.now_value + 1
                    else
                        condition.now_value = 1
                    end
                    if condition.now_value >= condition.target_value then
                        condition.is_complete = 1
                    end
                    is_change = true
                end
            elseif condition_id == MissionDef.EConditionIds.TOTAL_FAIL_CNT then
                condition.now_value = condition.now_value + change_cnt
                if condition.now_value >= condition.target_value then
                    condition.is_complete = 1
                end
                is_change = true
            elseif condition_id == MissionDef.EConditionIds.GAME_COLLECT_ITEM_CNT
                or condition_id == MissionDef.EConditionIds.GAME_CONSUME_ITEM_CNT then
                -- 局内收集/消耗道具(局内id局外无配置): param1类型(0不限,暂无类型数据源仅支持0) param2局内道具id
                if table.size(params) >= 2
                    and (IsUnlimitParam(condition.params[1]) or params[1] == condition.params[1])
                    and (IsUnlimitParam(condition.params[2]) or params[2] == condition.params[2]) then
                    condition.now_value = condition.now_value + change_cnt
                    if condition.now_value >= condition.target_value then
                        condition.is_complete = 1
                    end
                    is_change = true
                end
            elseif condition_id == MissionDef.EConditionIds.SINGLE_BOOTY_VALUE_CNT then
                if table.size(params) >= 2 then
                    local is_match_arr_param = false
                    for _, c_param in pairs(condition.arr_params) do
                        if c_param == 0 or params[1] == c_param then
                            is_match_arr_param = true
                            break
                        end
                    end
                    if is_match_arr_param
                        and (condition.params[1] == 0 or params[2] == condition.params[1]) then
                        condition.now_value = change_cnt
                        if condition.now_value >= condition.target_value then
                            condition.is_complete = 1
                        end
                        is_change = true
                    end
                end
            elseif condition_id == MissionDef.EConditionIds.UNLOCK_SKIN_CNT then
                if table.size(params) >= 1 and table.size(condition.params) >= 1 then
                    if condition.params[1] == 0 or params[1] == condition.params[1] then
                        condition.now_value = condition.now_value + change_cnt
                        if condition.now_value >= condition.target_value then
                            condition.is_complete = 1
                        end
                        is_change = true
                    end
                end
            elseif condition_id == MissionDef.EConditionIds.STRENGTHEN_EQP_CNT then
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
            elseif condition_id == MissionDef.EConditionIds.EQP_MAX_LEVEL then
                if table.size(params) >= 2 and table.size(condition.params) >= 2 then
                    if (condition.params[1] == 0 or params[1] == condition.params[1])
                        and (condition.params[2] == 0 or params[2] == condition.params[2])
                        and change_cnt > condition.now_value then
                        condition.now_value = change_cnt
                        if condition.now_value >= condition.target_value then
                            condition.is_complete = 1
                        end
                        is_change = true
                    end
                end
            elseif condition_id == MissionDef.EConditionIds.UPSTAR_EQP_CNT then
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
            elseif condition_id == MissionDef.EConditionIds.EQP_MAX_STAR then
                if table.size(params) >= 2 and table.size(condition.params) >= 2 then
                    if (condition.params[1] == 0 or params[1] == condition.params[1])
                        and (condition.params[2] == 0 or params[2] == condition.params[2])
                        and change_cnt > condition.now_value then
                        condition.now_value = change_cnt
                        if condition.now_value >= condition.target_value then
                            condition.is_complete = 1
                        end
                        is_change = true
                    end
                end
            elseif condition_id == MissionDef.EConditionIds.SKILL_MAX_LEVEL then
                if table.size(params) >= 2 and table.size(condition.params) >= 2 then
                    if (condition.params[1] == 0 or params[1] == condition.params[1])
                        and (condition.params[2] == 0 or params[2] == condition.params[2])
                        and change_cnt > condition.now_value then
                        condition.now_value = change_cnt
                        if condition.now_value >= condition.target_value then
                            condition.is_complete = 1
                        end
                        is_change = true
                    end
                end
            elseif condition_id == MissionDef.EConditionIds.SKILL_MAX_STAR then
                if table.size(params) >= 2 and table.size(condition.params) >= 2 then
                    if (condition.params[1] == 0 or params[1] == condition.params[1])
                        and (condition.params[2] == 0 or params[2] == condition.params[2])
                        and change_cnt > condition.now_value then
                        condition.now_value = change_cnt
                        if condition.now_value >= condition.target_value then
                            condition.is_complete = 1
                        end
                        is_change = true
                    end
                end
            elseif condition_id == MissionDef.EConditionIds.ROLE_MAX_LEVEL then
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
            elseif condition_id == MissionDef.EConditionIds.ROLE_MAX_STAR then
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
            elseif condition_id == MissionDef.EConditionIds.APPRAISE_SUCCESS_CNT then
                if table.size(params) >= 1 then
                    local is_match_arr_param = false
                    for _, c_param in pairs(condition.arr_params) do
                        if c_param == 0 or params[1] == c_param then
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
            elseif condition_id == MissionDef.EConditionIds.PERFECT_CLEAR_CNT then
                condition.now_value = condition.now_value + change_cnt
                if condition.now_value >= condition.target_value then
                    condition.is_complete = 1
                end
                is_change = true
            elseif condition_id == MissionDef.EConditionIds.MAIN_TASK_COMPLETE_CNT then
                condition.now_value = condition.now_value + change_cnt
                if condition.now_value >= condition.target_value then
                    condition.is_complete = 1
                end
                is_change = true
            elseif condition_id == MissionDef.EConditionIds.SUB_TASK_COMPLETE_CNT then
                condition.now_value = condition.now_value + change_cnt
                if condition.now_value >= condition.target_value then
                    condition.is_complete = 1
                end
                is_change = true
            elseif condition_id == MissionDef.EConditionIds.HISTORY_MAX_GRADE_SCORE then
                -- 账户历史最高段位积分: 取玩家达到过的最高值, 只升不降
                if change_cnt > condition.now_value then
                    condition.now_value = change_cnt
                    if condition.now_value >= condition.target_value then
                        condition.is_complete = 1
                    end
                    is_change = true
                end
            elseif condition_id == MissionDef.EConditionIds.DAILY_TASK_COMPLETE_CNT
                or condition_id == MissionDef.EConditionIds.WEEKLY_TASK_COMPLETE_CNT
                or condition_id == MissionDef.EConditionIds.TEAM_SUCCESS_LEAVE_CNT then
                -- 完成日常/周常任务次数、组队成功撤离次数: 纯累计计数
                condition.now_value = condition.now_value + change_cnt
                if condition.now_value >= condition.target_value then
                    condition.is_complete = 1
                end
                is_change = true
            elseif condition_id == MissionDef.EConditionIds.TEAM_KILL_MONSTER_CNT then
                -- 组队击杀X类型Y怪物数量: param1怪物类型0不限; param2怪物id 0不限
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
            elseif condition_id == MissionDef.EConditionIds.TEAM_BATTLE_CHAPTER_CNT then
                -- 组队完成X章节Y难度次数: param_arr章节(0=任意); param1难度(0=任意)
                if table.size(params) >= 2 then
                    local is_match_arr = false
                    if not condition.arr_params or table.size(condition.arr_params) == 0 then
                        is_match_arr = true
                    else
                        for _, c_param in pairs(condition.arr_params) do
                            if c_param == 0 or params[1] == c_param then
                                is_match_arr = true
                                break
                            end
                        end
                    end
                    if is_match_arr
                        and (IsUnlimitParam(condition.params[1]) or params[2] == condition.params[1]) then
                        condition.now_value = condition.now_value + change_cnt
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
        if task.mission_state == MissionDef.ETaskState.NO_COMPLETE
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
