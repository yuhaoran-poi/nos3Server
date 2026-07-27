-- AntiqueShowcase.lua
--require("common.LuaPanda").start("127.0.0.1", 8818)
local moon    = require "moon"
local common  = require "common"
local uuid    = require "uuid"
local GameCfg = common.GameCfg
local ErrorCode = common.ErrorCode
local CmdCode = common.CmdCode
local Database = common.Database
local BagDef = require("common.def.BagDef")
local ItemDef         = require("common.def.ItemDef")
local MissionDef = require("common.def.MissionDef")
local ItemDefine = require("common.logic.ItemDefine")

---@type user_context
local context = ...
local scripts = context.scripts

---@class AntiqueShowcase
local AntiqueShowcase = {}

function AntiqueShowcase.Init()
    --加载全部展柜数据
    local showcaseInfos = AntiqueShowcase.LoadShowcases()
    if showcaseInfos then
        scripts.UserModel.SetAntiqueShowcase(showcaseInfos)
    end

    local showcases = scripts.UserModel.GetAntiqueShowcase()
    if not showcases then
        -- 初始化展示柜数据结构
        showcases = ItemDef.newAntiqueShowcaseS()

        -- 根据配置表动态创建展示柜
        local showcaseConfig = GameCfg.AntiqueSlot
        if not showcaseConfig or next(showcaseConfig) == nil then
            return ErrorCode.ConfigError, "配置错误"
        end

        for _, config in pairs(showcaseConfig) do
            local newShowcase = ItemDef.newAntiqueShowcase()
            newShowcase.showcase_id = config.id
            newShowcase.box_num = config.num

            showcases.antique_showcase_list[newShowcase.showcase_id] = newShowcase
        end

        scripts.UserModel.SetAntiqueShowcase(showcases)
    end
end

function AntiqueShowcase.Start(isnew)
    local showcases = scripts.UserModel.GetAntiqueShowcase()
    if not showcases then
        return false
    end

    if isnew then
        AntiqueShowcase.SaveShowcasesNow()
    end
end

function AntiqueShowcase.SaveShowcasesNow()
    local showcases = scripts.UserModel.GetAntiqueShowcase()
    if not showcases then
        return false
    end

    local success = Database.saveuserantiqueshowcase(context.addr_db_user, context.uid, showcases)
    return success
end

function AntiqueShowcase.LoadShowcases()
    local showcaseInfos = Database.loaduserantiqueshowcase(context.addr_db_user, context.uid)
    return showcaseInfos
end

-- 同步客户端更新用
function AntiqueShowcase.SaveAndLog(update_showcase_ids)
    local showcases = scripts.UserModel.GetAntiqueShowcase()
    if not showcases then
        return false
    end

    local update_msg = {
        antique_showcase_list = {}
    }

    for _, sid in pairs(update_showcase_ids) do
        local showcase = showcases.antique_showcase_list[sid]
        if showcase then
            update_msg.antique_showcase_list[sid] = showcase
        end
    end

    context.S2C(context.net_id, CmdCode["PBAntiqueShowcaseUpdateSyncCmd"], update_msg, 0)

    AntiqueShowcase.SaveShowcasesNow()
end

-- 新增展柜（如果不存在）
function AntiqueShowcase.AddShowcase(showcase_id, change_ids)
    local showcases = scripts.UserModel.GetAntiqueShowcase()
    if not showcases then
        return false
    end

    if not showcases[showcase_id] then
        local newShowcase = ItemDef.newAntiqueShowcase()
        newShowcase.showcase_id = showcase_id
        newShowcase.box_num = 0
        showcases.antique_showcase_list[showcase_id] = newShowcase

        table.insert(change_ids, showcase_id)
    end

    return true
end

-- 获取目标展柜
function AntiqueShowcase.GetShowcase(showcase_id)
    local showcases = scripts.UserModel.GetAntiqueShowcase()
    if not showcases then
        return nil
    end

    return showcases.antique_showcase_list[showcase_id]
end

-- 获取所有展柜
function AntiqueShowcase.GetShowcaseS()
    local showcases = scripts.UserModel.GetAntiqueShowcase()
    if not showcases then
        return { errcode = ErrorCode.ServerInternalError }
    end

    return { errcode = ErrorCode.None, showcase_data = showcases }
end

-- 鉴定古董
function AntiqueShowcase.IdentifyAntique(config_id, uniqid, bag_pos)
    -- 参数检查
    if not config_id or config_id <= 0 or bag_pos <= 0 then
        return ErrorCode.ParamInvalid, "无效请求参数"
    end

    local err_code, item_data = scripts.Bag.MutOneItemData(BagDef.BagType.Cangku, bag_pos)
    if err_code ~= ErrorCode.None or not item_data then
        return err_code, "未拥有古董"
    end

    local change_logs = {}

    -- 检查是否为可堆叠古董（鉴定前）
    local is_stack_antique = item_data.itype == ItemDefine.EItemSmallType.StackAntique

    -- 如果是可堆叠古董，需要先转换为唯一古董
    if is_stack_antique then
        -- 使用 GetSpecialItemFromCommonItem 方法转换为唯一古董
        local special_err_code, change_log = scripts.Bag.GetSpecialItemFromCommonItem(BagDef.BagType.Cangku, bag_pos, config_id)
        if special_err_code ~= ErrorCode.None then
            return special_err_code, "转换古董失败"
        end

        -- 从 change_log 中获取新位置，并合并物品变化日志
        if change_log then
            if not change_logs then
                change_logs = {}
            end
            for bag_type, logs in pairs(change_log) do
                change_logs[bag_type] = change_logs[bag_type] or {}
                for pos, old_item in pairs(logs) do
                    if table.size(old_item) == 0 then
                        -- 新增物品的位置
                        bag_pos = pos
                    else
                        -- 被删除的物品记录到日志
                        change_logs[bag_type][pos] = old_item
                    end
                end
            end
        end

        -- 获取转换后的古董数据
        err_code, item_data = scripts.Bag.MutOneItemData(BagDef.BagType.Cangku, bag_pos)
        if err_code ~= ErrorCode.None or not item_data then
            return err_code, "获取转换后的古董失败"
        end
    else
        -- 已鉴定的古董需要检查唯一性
        if not uniqid or uniqid <= 0 then
            return ErrorCode.ParamInvalid, "无效请求参数"
        end

        local u_i_cfg = GameCfg.UniqueItem[config_id]
        if not u_i_cfg then
            return ErrorCode.ItemNotExist, "道具不存在"
        end

        -- 检查古董信息是否存在
        if not item_data.special_info or not item_data.special_info.antique_item then
            return ErrorCode.ItemNotExist, "古董信息不存在"
        end

        -- 古董不存在或剩余可鉴定次数不足或是赝品
        if item_data.special_info.antique_item.remain_identify_num <= 0 or item_data.special_info.antique_item.is_fake == 1 then
            return ErrorCode.IdentifyInvalid, "古董剩余可鉴定次数不足或是赝品"
        end
    end

    local old_item_data = table.copy(item_data, true)

    local real_config_id = config_id
    local a_cfg
    if(is_stack_antique) then
        local convert_config_id = GameCfg.LightConvert[config_id].getid
        if not convert_config_id or convert_config_id <= 0 then
            return ErrorCode.ItemNotExist, "道具不存在"
        end
        real_config_id = convert_config_id
    end

    a_cfg = GameCfg.AntiqueItem[real_config_id]
    if not a_cfg then
        return ErrorCode.ItemNotExist, "道具不存在"
    end

    -- 获取消耗
    local cost_items = {}
    local cost_coins = {}
    ItemDefine.GetItemsFromCfg(a_cfg.identifycost, 1, true, cost_items, cost_coins)

    -- 检测道具是否足够
    err_code = scripts.Bag.CheckItemsEnough(BagDef.BagType.Cangku, cost_items, {})
    if err_code ~= ErrorCode.None then
        return err_code, "道具不足"
    end

    err_code = scripts.Bag.CheckCoinsEnough(cost_coins)
    if err_code ~= ErrorCode.None then
        return err_code, "金币不足"
    end

    -- 扣除道具消耗
    if table.size(cost_items) > 0 then
        err_code = scripts.Bag.DelItems(BagDef.BagType.Cangku, cost_items, {}, change_logs)
        if err_code ~= ErrorCode.None then
            scripts.Bag.RollBackWithChange(change_logs)
            return err_code, "道具不足"
        end
    end

    -- 扣除金币消耗
    if table.size(cost_coins) > 0 then
        err_code = scripts.Bag.DealCoins(cost_coins, change_logs)
        if err_code ~= ErrorCode.None then
            scripts.Bag.RollBackWithChange(change_logs)
            return err_code, "金币不足"
        end
    end

    -- 消耗一次鉴定次数
    local rsp_remain_identify_num = item_data.special_info.antique_item.remain_identify_num - 1

    local r_s_code, is_succ = scripts.Bag.RandomSucc(a_cfg.trueprobability)
    if r_s_code ~= ErrorCode.None then
        return r_s_code, "鉴定失败"
    end

    local rsp_is_fake = 0
    local rsp_price = 0
    -- 价格的降平升
    local price_probability = 0

    if is_succ == 0 then
        rsp_is_fake = 1
    else
        -- 获得随机该古董的降平升的权重池
        local random_pool = {}
        for probability_id, weight in pairs(a_cfg.priceprobability) do
            random_pool[probability_id] = weight
        end

        -- 通过随机一次升降平拿到价格变化率
        local g_r_e_code, random_probability_id = scripts.Bag.RandomWeightedIndex(random_pool)
        if g_r_e_code ~= ErrorCode.None then
            return g_r_e_code, "鉴定失败"
        end

        price_probability = random_probability_id or 0

        local a_p_t_cfgmap = GameCfg.AntiquePriceTagChangeRate
        if not a_p_t_cfgmap or next(a_p_t_cfgmap) == nil then
            return ErrorCode.ConfigError, "配置错误"
        end

        -- 找到与品质和价格变化率相同的配置
        local tar_config_id = 0
        for cid, cfg in pairs(a_p_t_cfgmap) do
            if cfg.type == item_data.special_info.antique_item.quality and cfg.pricechange == price_probability then
                tar_config_id = cid
                break
            end
        end

        local a_p_t_cfg = GameCfg.AntiquePriceTagChangeRate[tar_config_id]
        if not a_p_t_cfg then
            return ErrorCode.ConfigError, "配置错误"
        end

        -- 获取价格变化率
        local r_v_code, price_rate_val = scripts.Bag.RandomValue(a_p_t_cfg.lowlimit, a_p_t_cfg.upperlimit)
        if r_v_code ~= ErrorCode.None then
            return r_v_code, "鉴定失败"
        end

        local price_rate = price_rate_val * 0.01

        -- 计算价格
        rsp_price = math.floor(item_data.special_info.antique_item.price.coin_count * (1 + price_rate))

        -- 词条权重map
        local tag_weight_map = {}

        local tagpool = a_p_t_cfg.pooltype
        if not tagpool or next(tagpool) == nil then
            return ErrorCode.ConfigError, "配置错误"
        end

        local r_w_i_code, tagpool_id = scripts.Bag.RandomWeightedIndex(tagpool)
        if r_w_i_code ~= ErrorCode.None then
            return r_w_i_code, "鉴定失败"
        end

        local a_t_p_cfg = GameCfg.AllTagPool[tagpool_id]
        if not a_t_p_cfg then
            return ErrorCode.ConfigError, "配置错误"
        end

        for tag_id, weight in pairs(a_t_p_cfg.all_tag) do
            tag_weight_map[tag_id] = weight
        end

        local r_w_code, tag_id = scripts.Bag.RandomWeightedIndex(tag_weight_map)
        if r_w_code ~= ErrorCode.None then
            return r_w_code, "鉴定失败"
        end

        local a_t_cfg = GameCfg.AllTag[tag_id]
        if not a_t_cfg then
            return ErrorCode.ConfigError, "配置错误"
        end

        local r_v_code_ex, tag_val = scripts.Bag.RandomValue(a_t_cfg.min, a_t_cfg.max)
        if r_v_code_ex ~= ErrorCode.None then
            return r_v_code_ex, "鉴定失败"
        end

        local new_tag = {
            tag_id = tag_id,
            val = tag_val,
        }
        table.insert(item_data.special_info.antique_item.tags, new_tag)
        table.insert(item_data.special_info.antique_item.identify_histroy, price_probability)
    end

    item_data.special_info.antique_item.remain_identify_num = rsp_remain_identify_num
    item_data.special_info.antique_item.is_fake = rsp_is_fake
    item_data.special_info.antique_item.price.coin_count = rsp_price

    if not change_logs[BagDef.BagType.Cangku] then
        change_logs[BagDef.BagType.Cangku] = {}
    end
    scripts.Bag.AddLog(change_logs[BagDef.BagType.Cangku], bag_pos, old_item_data)

    if table.size(change_logs) > 0 then
        scripts.Bag.SaveAndLog(change_logs, ItemDef.ChangeReason.AntiqueIdentify)
    end

    -- 触发鉴定古董次数
    scripts.Mission.TriggerCondition(MissionDef.EConditionIds.APPRAISE_ANTIQUE_CNT, { a_cfg.quality }, 1)
    if(rsp_price > 0) then
        -- 更新古董榜
        scripts.Rank.UpdateRank_Antique(real_config_id, rsp_price)
    end

    moon.info(string.format("IdentifyAntique - uid=%d, config_id=%d, uniqid=%s, pos=%d, is_succ=%d, is_fake=%d, price=%d, final_price=%d",
    context.uid, config_id, tostring(uniqid), bag_pos, is_succ, rsp_is_fake, price_probability, rsp_price))

    local rsp_config_id = real_config_id
    local rsp_uniqid = item_data.common_info.uniqid
    local rsp_pos = bag_pos

    if is_succ == 1 then
        return ErrorCode.None, "鉴定完成 古董为真品", price_probability, rsp_config_id, rsp_uniqid, rsp_pos
    elseif is_succ ==0 then
        return ErrorCode.None, "鉴定完成 古董为赝品", price_probability, rsp_config_id, rsp_uniqid, rsp_pos
    end
end

-- 展示古董
function AntiqueShowcase.AntiqueShow(config_id, uniqid, showcase_id, showcase_idx, operate_type, bag_pos)
    -- 参数验证
    if not showcase_id or not showcase_idx or showcase_id <= 0 or showcase_idx <= 0 then
        return ErrorCode.ParamInvalid, "参数错误"
    end

    -- 获取配置并验证
    local antique_cfg = GameCfg.AntiqueItem[config_id]
    if not antique_cfg then
        return ErrorCode.ItemNotExist, "古董不存在"
    end

    local showcase_cfg = GameCfg.AntiqueSlot[showcase_id]
    if not showcase_cfg then
        return ErrorCode.ShowcaseNotFound, "展示柜不存在"
    end

    -- 查找并验证古董是否可以展示
    local tar_showcase = AntiqueShowcase.GetShowcase(showcase_id)
    if not tar_showcase then
        return ErrorCode.ShowcaseNotFound, "展示柜不存在"
    end

    -- 检查展示索引是否越界 因临时改表暂时改为按配置表上数量检查
    --if showcase_idx > showcase_cfg.box_num then
    if showcase_idx > showcase_cfg.num then
        return ErrorCode.ShowcaseIdxOutOfBounds, "展示索引越界"
    end

    -- 检测目标展示下标位置是否已有古董 有则交换 没有则直接展示
    local aimShowAntique = tar_showcase.antique_show_list[showcase_idx]
    local bag_change_log = {}

    if operate_type == 1 then
        -- 展示古董
        if not config_id or not uniqid or config_id <= 0 or uniqid <= 0 or not bag_pos or bag_pos <= 0 then
            return ErrorCode.ParamInvalid, "参数错误"
        end

        -- 检查品质是否符合展示要求
        if antique_cfg.quality ~= showcase_cfg.quality then
            return ErrorCode.QualityNotMatch, "品质不符合展示要求"
        end

        -- 查找用户的古董
        local err_code, item_data = scripts.Bag.MutOneItemData(BagDef.BagType.Cangku, bag_pos)
        if err_code ~= ErrorCode.None or not item_data then
            return err_code, "古董不存在"
        end

        -- 检查是否为可堆叠古董（未鉴定的古董）
        if item_data.itype == ItemDefine.EItemSmallType.StackAntique then
            return ErrorCode.IdentifyInvalid, "未鉴定的古董不能展示"
        end

        -- 检查唯一古董是否已鉴定（至少鉴定过一次）
        if item_data.special_info and item_data.special_info.antique_item then
            local antique_item = item_data.special_info.antique_item
            -- 未鉴定的古董：剩余鉴定次数等于初始次数（说明从未鉴定过）
            if antique_cfg and antique_item.remain_identify_num == antique_cfg.identifynum then
                return ErrorCode.IdentifyInvalid, "未鉴定的古董不能展示"
            end
        end

        local old_item_data = table.copy(item_data)

        if aimShowAntique and aimShowAntique.common_info and aimShowAntique.common_info.uniqid then
            local del_unique_items = { [uniqid] = { config_id = config_id, uniqid = uniqid, pos = bag_pos } }
            local takeoff_items = { [aimShowAntique.common_info.uniqid] = aimShowAntique }

            -- 删除背包内古董
            err_code = scripts.Bag.DelItems(BagDef.BagType.Cangku, {}, del_unique_items, bag_change_log)
            if err_code ~= ErrorCode.None then
                scripts.Bag.RollBackWithChange(bag_change_log)
                return err_code, "删除古董失败"
            end

            -- 添加被替换的古董
            err_code = scripts.Bag.AddItems(BagDef.BagType.Cangku, {}, takeoff_items, bag_change_log)
            if err_code ~= ErrorCode.None then
                scripts.Bag.RollBackWithChange(bag_change_log)
                return err_code, "添加古董失败"
            end
        else
            -- 删除背包内古董
            local del_unique_items = { [uniqid] = { config_id = config_id, uniqid = uniqid, pos = bag_pos } }
            err_code = scripts.Bag.DelItems(BagDef.BagType.Cangku, {}, del_unique_items, bag_change_log)
            if err_code ~= ErrorCode.None then
                scripts.Bag.RollBackWithChange(bag_change_log)
                return err_code, "删除古董失败"
            end
        end

        -- 展示目标古董
        tar_showcase.antique_show_list[showcase_idx] = old_item_data

        if not bag_change_log[BagDef.BagType.Cangku] then
            bag_change_log[BagDef.BagType.Cangku] = {}
        end
        scripts.Bag.AddLog(bag_change_log[BagDef.BagType.Cangku], bag_pos, item_data)
    elseif operate_type == 0 then
        -- 取消展示古董
        if not aimShowAntique or not aimShowAntique.common_info or aimShowAntique.common_info.uniqid ~= uniqid then
            return ErrorCode.AntiqueNotInShowcase, "古董不在展示框中"
        end

        local takeoff_items = { [aimShowAntique.common_info.uniqid] = aimShowAntique }

        -- 将古董返回背包
        local err_code = scripts.Bag.AddItems(BagDef.BagType.Cangku, {}, takeoff_items, bag_change_log)
        if err_code ~= ErrorCode.None then
            scripts.Bag.RollBackWithChange(bag_change_log)
            return err_code, "添加古董失败"
        end

        -- 清除展示的古董
        tar_showcase.antique_show_list[showcase_idx] = nil
    else
        return ErrorCode.InvalidOperateType, "操作类型错误"
    end

    -- 保存数据并同步给客户端
    local change_showcase_id = { showcase_id }
    AntiqueShowcase.SaveAndLog(change_showcase_id)

    if table.size(bag_change_log) > 0 then
        scripts.Bag.SaveAndLog(bag_change_log, ItemDef.ChangeReason.AntiqueShow)
    end

    -- 触发展示古董数量
    scripts.Mission.TriggerCondition(MissionDef.EConditionIds.SHOW_ANTIQUE_CNT, { showcase_id },
        table.size(tar_showcase.antique_show_list))

    return ErrorCode.None, "操作成功"
end

function AntiqueShowcase.GetAntiqueShowcaseInfo()
    local antiqueShowcse = scripts.UserModel.GetAntiqueShowcase()
    if not antiqueShowcse then
        return { errcode = ErrorCode.ServerInternalError }
    end

    return { errcode = ErrorCode.None, antique_showcase_data = antiqueShowcse }
end

function AntiqueShowcase.PBAntiqueShowcaseDataReqCmd(req)
    local antiqueShowcse = scripts.UserModel.GetAntiqueShowcase()
    if not antiqueShowcse then
        return context.S2C(context.net_id, CmdCode["PBAntiqueShowcaseDataRspCmd"], {code = ErrorCode.ServerInternalError, error = "服务器内部错误"}, req.msg_context.stub_id)
    end

    local res = {
        code = ErrorCode.None,
        error = "",
        uid = context.uid,
        antique_showcase_data = antiqueShowcse
    }
    return context.S2C(context.net_id, CmdCode["PBAntiqueShowcaseDataRspCmd"], res, req.msg_context.stub_id)
end

function AntiqueShowcase.GetAntiqueInfo(config_id, uniqid, bag_pos)
    local err_code, item_data = scripts.Bag.MutOneItemData(BagDef.BagType.Cangku, bag_pos)
    if err_code ~= ErrorCode.None or not item_data then
        moon.error(string.format("AntiqueShowcase.GetAntiqueInfo111: uid %d, err_code %d, bag_pos %d not found", context.uid, err_code, bag_pos))
        return nil
    end

    if not item_data.common_info then
        moon.error(string.format("AntiqueShowcase.GetAntiqueInfo222: uid %d, config_id %d, uniqid %d, bag_pos %d no common_info", context.uid, config_id, uniqid, bag_pos))
        return nil
    end

    if item_data.common_info.config_id ~= config_id or item_data.common_info.uniqid ~= uniqid then
        moon.error(string.format("AntiqueShowcase.GetAntiqueInfo333: uid %d, config_id %d, uniqid %d, item_data.config_id %d, item_data.uniqid %d, bag_pos %d not match", context.uid, config_id, uniqid, item_data.common_info.config_id, item_data.common_info.uniqid, bag_pos, bag_pos))
        return nil
    end

    if not item_data.special_info or not item_data.special_info.antique_item then
        moon.error(string.format("AntiqueShowcase.GetAntiqueInfo444: uid %d, config_id %d, uniqid %d, bag_pos %d no antique_item", context.uid, config_id, uniqid, bag_pos))
        return nil
    end

    local antique_item = item_data.special_info.antique_item
    moon.info(string.format("GetAntiqueInfo - uid=%d, config_id=%d, uniqid=%d, bag_pos=%d, is_fake=%d, price=%d",
        context.uid, config_id, uniqid, bag_pos, antique_item.is_fake,
        antique_item.price.coin_count))

    return antique_item
end

return AntiqueShowcase