local moon = require "moon"
local datetime = require("moon.datetime")
local common = require "common"
local clusterd = require("cluster")
local GameCfg = common.GameCfg
local ErrorCode = common.ErrorCode
local CmdCode = common.CmdCode
local Database = common.Database
local GradeDef = require("common.def.GradeDef")
local ItemDefine = require("common.logic.ItemDefine")
local BagDef = require("common.def.BagDef")
local ItemDef = require("common.def.ItemDef")
local ProtoEnum = require("tools.ProtoEnum")

---@type user_context
local context = ...
local scripts = context.scripts

---@class Grade
local Grade = {}

function Grade.Init()
    --加载段位数据
    local Grade_player_data = Grade.LoadGradeInfo()
    if Grade_player_data then
        scripts.UserModel.SetGrades(Grade_player_data)
    end

    local Grades = scripts.UserModel.GetGrades()
    if not Grades then
        Grades = GradeDef.newGradePlayerData()
        Grades.cur_season_id = 1
        local grade_info = GradeDef.newGradeInfo()
        grade_info.season_id = Grades.cur_season_id
        Grades.grade_infos[Grades.cur_season_id] = grade_info
        scripts.UserModel.SetGrades(Grades)
    end
end

function Grade.Start()
    local Grades = scripts.UserModel.GetGrades()
    if not Grades then
        return
    end

    Grade.SaveGradesNow()
end

function Grade.SaveGradesNow()
    local Grades = scripts.UserModel.GetGrades()
    if not Grades then
        return false
    end

    local success = Database.savegradeinfo(context.addr_db_user, context.uid, Grades)
    return success
end

function Grade.LoadGradeInfo()
    local trade_info = Database.loadgradeinfo(context.addr_db_user, context.uid)
    return trade_info
end

---@return PBGradeShowInfo
function Grade.GetGradeShowInfo(grade_info)
    local grade_show_info = GradeDef.newGradeShowInfo()
    grade_show_info.season_id = grade_info.season_id
    grade_show_info.grade_show_data.grade_id = grade_info.grade_data.grade_id
    grade_show_info.grade_show_data.now_grade_score = grade_info.grade_data.now_grade_score

    return grade_show_info
end

function Grade.GetGradeShowInfos()
    local Grades = scripts.UserModel.GetGrades()
    if not Grades or not Grades.grade_infos then
        return nil
    end

    local grade_show_infos = {}
    for season_id, grade_info in pairs(Grades.grade_infos) do
        local grade_show_info = Grade.GetGradeShowInfo(grade_info)
        if grade_show_info then
            grade_show_infos[season_id] = grade_show_info
        end
    end

    return grade_show_infos
end

function Grade.ChangeScore(grade_id, change_score)
    local Grades = scripts.UserModel.GetGrades()
    if not Grades or not Grades.grade_infos then
        return
    end

    local grade_info = Grades.grade_infos[Grades.cur_season_id]
    if not grade_info then
        grade_info = GradeDef.newGradeInfo()
        grade_info.season_id = Grades.cur_season_id
        Grades.grade_infos[Grades.cur_season_id] = grade_info
    end
    
    if not grade_info.grade_data then
        grade_info.grade_data = GradeDef.newGradeData()
        grade_info.grade_data.grade_id = grade_id
    end

    local grade_cfg = GameCfg.RankConfig[grade_id]
    if not grade_cfg then
        return
    end
    if grade_info.grade_data.now_grade_score + change_score < 0 then
        grade_info.grade_data.now_grade_score = 0
    elseif grade_info.grade_data.now_grade_score + change_score > grade_cfg.maxexp then
        grade_info.grade_data.now_grade_score = grade_cfg.maxexp
    else
        grade_info.grade_data.now_grade_score = grade_info.grade_data.now_grade_score + change_score
    end

    if grade_info.grade_data.now_grade_score > grade_info.grade_data.highest_grade_score then
        grade_info.grade_data.highest_grade_score = grade_info.grade_data.now_grade_score
    end

    Grades.grade_infos[Grades.cur_season_id] = grade_info
    Grade.SaveGradesNow()

    -- 同步到玩家属性上
    local grade_show_info = Grade.GetGradeShowInfo(grade_info)
    local update_user_attr = {}
    update_user_attr[ProtoEnum.UserAttrType.grade_show_info] = grade_show_info
    scripts.User.SetUserAttr(update_user_attr, true)
end

function Grade.PBGetGradeDataReqCmd(req)
    local Grades = scripts.UserModel.GetGrades()
    if not Grades or not Grades.grade_infos then
        return context.S2C(context.net_id, CmdCode["PBGetGradeDataRspCmd"],
            { code = ErrorCode.ServerInternalError, error = "数据加载出错", uid = context.uid }, req.msg_context.stub_id)
    end

    local rsp = {
        code = ErrorCode.None,
        error = "",
        uid = context.uid,
        now_sys_ts = moon.time(),
        grade_player_data = Grades,
    }
    return context.S2C(context.net_id, CmdCode["PBGetGradeDataRspCmd"], rsp, req.msg_context.stub_id)
end

function Grade.PBGetGradeRewardReqCmd(req)
    -- 参数验证
    if not req.msg.grade_id
        or not req.msg.level_ids
        or table.size(req.msg.level_ids) == 0 then
        return context.S2C(context.net_id, CmdCode.PBShopAddBuyCarRspCmd, {
            code = ErrorCode.ParamInvalid,
            error = "无效请求参数",
            uid = context.uid,
        }, req.msg_context.stub_id)
    end

    local Grades = scripts.UserModel.GetGrades()
    if not Grades or not Grades.grade_infos then
        return context.S2C(context.net_id, CmdCode["PBGetGradeRewardRspCmd"],
            { code = ErrorCode.ServerInternalError, error = "数据加载出错", uid = context.uid }, req.msg_context.stub_id)
    end

    local grade_info = Grades.grade_infos[Grades.cur_season_id]
    if not grade_info then
        return context.S2C(context.net_id, CmdCode["PBGetGradeRewardRspCmd"],
            { code = ErrorCode.GradeNoData, error = "段位数据不存在", uid = context.uid }, req.msg_context.stub_id)
    end

    local grade_data = grade_info.grade_data
    if not grade_data then
        return context.S2C(context.net_id, CmdCode["PBGetGradeRewardRspCmd"],
            { code = ErrorCode.GradeUnlock, error = "段位未解锁", uid = context.uid }, req.msg_context.stub_id)
    end

    local grade_cfg = GameCfg.RankConfig[req.msg.grade_id]
    if not grade_cfg or not grade_cfg.exp_type or not grade_cfg.reward_type then
        return context.S2C(context.net_id, CmdCode["PBGetGradeRewardRspCmd"],
            { code = ErrorCode.ConfigError, error = "段位配置不存在", uid = context.uid }, req.msg_context.stub_id)
    end

    local add_items = {}
    for _, level_id in pairs(req.msg.level_ids) do
        if grade_data.already_get_reward_ids[level_id] then
            return context.S2C(context.net_id, CmdCode["PBGetGradeRewardRspCmd"],
                { code = ErrorCode.GradeRewardAlreadyGet, error = "段位奖励已领取", uid = context.uid, grade_data = grade_data },
                req.msg_context.stub_id)
        end
        if level_id > grade_cfg.maxlv then
            return context.S2C(context.net_id, CmdCode["PBGetGradeRewardRspCmd"],
                { code = ErrorCode.ParamInvalid, error = "段位等级超出范围", uid = context.uid }, req.msg_context.stub_id)
        end

        local grade_level_cfg = GameCfg.RankLevel[level_id]
        if not grade_level_cfg
            or not grade_level_cfg[grade_cfg.exp_type]
            or not grade_level_cfg[grade_cfg.reward_type] then
            return context.S2C(context.net_id, CmdCode["PBGetGradeRewardRspCmd"],
                { code = ErrorCode.ConfigError, error = "段位等级配置不存在", uid = context.uid }, req.msg_context.stub_id)
        end
        if grade_data.highest_grade_score < grade_level_cfg[grade_cfg.exp_type] then
            return context.S2C(context.net_id, CmdCode["PBGetGradeRewardRspCmd"],
                { code = ErrorCode.GradeScoreNotEnough, error = "段位未到等级", uid = context.uid, grade_data = grade_data },
                req.msg_context.stub_id)
        end

        local grade_reward_cfg = GameCfg.RankRewardPool[grade_level_cfg[grade_cfg.reward_type]]
        if not grade_reward_cfg then
            return context.S2C(context.net_id, CmdCode["PBGetGradeRewardRspCmd"],
                { code = ErrorCode.ConfigError, error = "段位奖励配置不存在", uid = context.uid }, req.msg_context.stub_id)
        end
        for item_id, item_cnt in pairs(grade_reward_cfg.reward) do
            if not add_items[item_id] then
                add_items[item_id] = {
                    id = item_id,
                    count = 0,
                    pos = 0,
                }
            end
            add_items[item_id].count = add_items[item_id].count + item_cnt
        end
    end

    local stack_items, unstack_items, deal_coins = {}, {}, {}
    if table.size(add_items) > 0 then
        local ok = ItemDefine.GetItemDataFromIdCount(add_items, {}, stack_items, unstack_items, deal_coins)
        if not ok then
            return context.S2C(context.net_id, CmdCode["PBGetGradeRewardRspCmd"],
                { code = ErrorCode.ConfigError, error = "段位奖励配置不存在", uid = context.uid }, req.msg_context.stub_id)
        end
    end
    local bag_err_code = scripts.Bag.CheckEmptyEnough(BagDef.BagType.Cangku, stack_items, table.size(unstack_items))
    if bag_err_code ~= ErrorCode.None then
        return context.S2C(context.net_id, CmdCode["PBGetGradeRewardRspCmd"],
            { code = bag_err_code, error = "背包空间不足", uid = context.uid }, req.msg_context.stub_id)
    end
    -- 添加道具
    local bag_change_log = {}
    if table.size(stack_items) + table.size(unstack_items) > 0 then
        bag_err_code = scripts.Bag.AddItems(BagDef.BagType.Cangku, stack_items, unstack_items, bag_change_log)
        if bag_err_code ~= ErrorCode.None then
            scripts.Bag.RollBackWithChange(bag_change_log)
            return context.S2C(context.net_id, CmdCode["PBGetGradeRewardRspCmd"],
                { code = bag_err_code, error = "背包空间不足", uid = context.uid }, req.msg_context.stub_id)
        end
    end
    if table.size(deal_coins) > 0 then
        bag_err_code = scripts.Bag.DealCoins(deal_coins, bag_change_log)
        if bag_err_code ~= ErrorCode.None then
            scripts.Bag.RollBackWithChange(bag_change_log)
            return context.S2C(context.net_id, CmdCode["PBGetGradeRewardRspCmd"],
                { code = bag_err_code, error = "添加货币失败", uid = context.uid }, req.msg_context.stub_id)
        end
    end

    -- 标记已领取
    for _, level_id in pairs(req.msg.level_ids) do
        grade_data.already_get_reward_ids[level_id] = 1
    end
    -- 保存数据
    scripts.Bag.SaveAndLog(bag_change_log, ItemDef.ChangeReason.GradeReward)
    Grade.SaveGradesNow()

    return context.S2C(context.net_id, CmdCode["PBGetGradeRewardRspCmd"],
        { code = ErrorCode.None, error = "", uid = context.uid, grade_data = grade_data }, req.msg_context.stub_id)
end

return Grade