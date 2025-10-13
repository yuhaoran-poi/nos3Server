local moon = require "moon"
local common = require "common"
local clusterd = require("cluster")
local json = require("json")
local GameCfg = common.GameCfg
local ErrorCode = common.ErrorCode
local CmdCode = common.CmdCode
local Database = common.Database
local ProtoEnum = require("tools.ProtoEnum")
local MailDef = require("common.def.MailDef")
local ItemDef = require("common.def.ItemDef")
local BagDef = require("common.def.BagDef")
local ItemDefine = require("common.logic.ItemDefine")

---@type user_context
local context = ...
local scripts = context.scripts

local MAX_MAIL_COUNT = 100
local MAIL_EXPIRE_TIME = 30 * 24 * 60 * 60
local AFTER_READ_MAIL_EXPIRE_TIME = 7 * 24 * 60 * 60

---@class Mail
local Mail = {}

function Mail.Init()
    --加载邮件数据
    local mails_data = Mail.LoadMails()
    if mails_data then
        scripts.UserModel.SetMails(mails_data)
    end

    local mails = scripts.UserModel.GetMails()
    if not mails then
        mails = MailDef.newUserMailBox()
        mails.last_system_mail_id = Mail.GetLastSystemMailId()
        scripts.UserModel.SetMails(mails)
    end
end

function Mail.Start()
    local mails = scripts.UserModel.GetMails()
    if not mails then
        return
    end
    
    -- 检查并删除过期邮件
    Mail.CheckExpireMail()
    -- 获取离线期间的系统邮件
    Mail.CheckSystemMail()

    Mail.SaveMailsNow()
end

function Mail.CheckExpireMail()
    local mails = scripts.UserModel.GetMails()
    if not mails then
        return
    end

    local del_num = 0
    local now_ts = moon.time()
    for mail_id, mail_info in pairs(mails.mails_info) do
        if mail_info.simple_data.end_ts and mail_info.simple_data.end_ts <= now_ts then
            mails.mails_info[mail_id] = nil
            del_num = del_num + 1
        end
    end
    if del_num > 0 then
        Mail.SaveMailsNow()
    end
end

function Mail.CheckSystemMail()
    local mails = scripts.UserModel.GetMails()
    if not mails then
        return
    end

    local now_ts = moon.time()
    local req_data = {
        uid = context.uid,
        last_system_mail_id = mails.last_system_mail_id,
        now_ts = now_ts
    }
    local res, err = clusterd.call(3999, "mailmgr", "Mailmgr.GetSystemMailIds", req_data)
    if err then
        moon.error("Mail.CheckSystemMail Mailmgr.GetSystemMailIds err:%s", err)
    else
        if res then
            -- 先删除失效的系统邮件
            if res.del_mailids then
                for mail_id, _ in pairs(res.del_mailids) do
                    if mails.mails_info[mail_id] then
                        local mail_info = mails.mails_info[mail_id]
                        if mail_info.simple_data.is_have_items == 0
                            or mail_info.simple_data.is_get == 0 then
                            mails.mails_info[mail_id] = nil
                        end
                    end
                end
            end
            
            -- 添加离线期间的系统邮件
            local query_mail_ids = {}
            for mail_id, _ in pairs(res.add_mailids) do
                -- 查询为接收的邮件详情
                if not mails.mails_info[mail_id] then
                    table.insert(query_mail_ids, mail_id)
                end
            end
            if table.size(query_mail_ids) > 0 then
                local new_mails_info = Database.RedisGetSystemMailsInfo(context.addr_db_redis, query_mail_ids)
                for mail_id, new_mail_info in pairs(new_mails_info) do
                    local ret = Mail.AddMail(mails, new_mail_info)
                    if ret and mail_id > mails.last_system_mail_id then
                        -- 更新最后系统邮件ID
                        mails.last_system_mail_id = mail_id
                    end
                end
            end
        end
    end
end

-- 按结束时间升序排序
local function sort_mails_by_beg_time(mail_list)
    table.sort(mail_list, function(a, b)
        return a.beg_ts < b.beg_ts
    end)
end

function Mail.AddMail(mails, mail_info)
    if mails.mails_info[mail_info.mail_id] then
        return false
    end

    if table.size(mails.mails_info) >= MAX_MAIL_COUNT then
        local tmp_mails_time = {}
        for mail_id, mail_info in pairs(mails.mails_info) do
            table.insert(tmp_mails_time, {
                mail_id = mail_id,
                beg_ts = mail_info.simple_data.beg_ts,
            })
        end
        sort_mails_by_beg_time(tmp_mails_time)

        table.remove(mails.mails_info, tmp_mails_time[1].mail_id)
    end

    mails.mails_info[mail_info.simple_data.mail_id] = mail_info

    return true
end

function Mail.SaveMailsNow()
    local mails = scripts.UserModel.GetMails()
    if not mails then
        return false
    end

    local success = Database.savemails(context.addr_db_user, context.uid, mails)
    return success
end

function Mail.LoadMails()
    --local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
    local mails_data = Database.loadmails(context.addr_db_user, context.uid)
    return mails_data
end

function Mail.GetLastSystemMailId()
    --local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
    local last_system_mail_id = Database.get_last_system_mail_id(context.addr_db_user)
    return last_system_mail_id
end

-- 计算附件资源
-- param attachment_cfg {[1] = 1, [2] = 1}
-- return attachment_items {[PBItemSimple.config_id] = PBItemSimple}
-- return attachment_coins {[PBCoin.coin_id] = PBCoin}
function Mail.GetAttachmentFromCfg(attachment_cfg, attachment_items, attachment_coins)
    local items, coins = {}, {}
    ItemDefine.GetItemsFromCfg(attachment_cfg, 1, false, items, coins)
    for item_id, item in pairs(items) do
        local item_cfg = nil
        if GameCfg.Item[item_id] then
            item_cfg = GameCfg.Item[item_id]
        elseif GameCfg.UniqueItem[item_id] then
            item_cfg = GameCfg.UniqueItem[item_id]
        end
        if not item_cfg then
            return ErrorCode.ConfigError
        end

        if not attachment_items[item_id] then
            local item_simple = ItemDef.newItemSimple()
            item_simple.config_id = item_id
            attachment_items[item_id] = item_simple
        end
        attachment_items[item_id].item_count = attachment_items[item_id].item_count + item.count
    end
    for coin_id, coin in pairs(coins) do
        if not attachment_coins[coin_id] then
            local new_coin = ItemDef.newCoin()
            new_coin.coin_id = coin_id
            attachment_coins[coin_id] = new_coin
        end
        attachment_coins[coin_id].coin_count = attachment_coins[coin_id].coin_count + coin.coin_count
    end

    return ErrorCode.None
end

function Mail.RecvSystemMail(new_mail_info)
    -- 检查并删除过期邮件
    Mail.CheckExpireMail()
    local mails = scripts.UserModel.GetMails()
    if not mails then
        return false
    end

    local ret = Mail.AddMail(mails, new_mail_info)
    if ret then
        local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
        if new_mail_info.simple_data.mail_id > mails.last_system_mail_id then
            -- 更新最后系统邮件ID
            mails.last_system_mail_id = new_mail_info.simple_data.mail_id
        end
        
        Mail.SaveMailsNow()

        local sycn_msg = {
            add_mail_ids = {},
            del_mail_ids = {},
            update_mail_ids = {},
        }
        table.insert(sycn_msg.add_mail_ids, new_mail_info.simple_data.mail_id)
        context.S2C(context.net_id, CmdCode["PBMailSyncCmd"], sycn_msg, 0)
    end
end

function Mail.InvalidSystemMail(mail_id)
    local mails = scripts.UserModel.GetMails()
    if not mails then
        return false
    end

    local mail_info = mails.mails_info[mail_id]
    if mail_info and mail_info.simple_data.mail_type == MailDef.MailType.System
        and (mail_info.simple_data.is_have_items == 0 or mail_info.simple_data.is_get == 0) then
        mails.mails_info[mail_id] = nil

        Mail.SaveMailsNow()

        local sycn_msg = {
            add_mail_ids = {},
            del_mail_ids = {},
            update_mail_ids = {},
        }
        table.insert(sycn_msg.del_mail_ids, mail_id)
        context.S2C(context.net_id, CmdCode["PBMailSyncCmd"], sycn_msg, 0)
    end
end

function Mail.RecvTriggerMail(config_id)
    -- 检查并删除过期邮件
    Mail.CheckExpireMail()
    local mails = scripts.UserModel.GetMails()
    if not mails then
        return false
    end

    local mail_common_config = GameCfg.TriggerEmailTemplateConfig[config_id]
    if not mail_common_config or not mail_common_config.is_active then
        return false
    end

    local new_mail_info = MailDef.newMailData()
    new_mail_info.simple_data.mail_id = mails.last_trigger_mail_id + 1
    new_mail_info.simple_data.mail_config_id = config_id
    new_mail_info.simple_data.mail_type = MailDef.MailType.TriggerConfig
    new_mail_info.simple_data.beg_ts = moon.time()
    new_mail_info.simple_data.end_ts = new_mail_info.simple_data.beg_ts + mail_common_config.validity_period
    new_mail_info.simple_data.mail_title_id = mail_common_config.title
    new_mail_info.simple_data.is_read = 0
    if table.size(mail_common_config.attachment) > 0 then
        new_mail_info.simple_data.is_have_items = 1
    end
    new_mail_info.simple_data.is_get = 0
    new_mail_info.mail_icon_id = mail_common_config.icon
    new_mail_info.mail_content_id = mail_common_config.content
    new_mail_info.sign = tostring(mail_common_config.signature)

    local ret = Mail.AddMail(mails, new_mail_info)
    if ret then
        mails.last_trigger_mail_id = mails.last_trigger_mail_id + 1
        Mail.SaveMailsNow()
    end

    return ret
end

function Mail.RecvImmediateMail(config_id, items_simple, item_datas, coins)
    -- 检查并删除过期邮件
    Mail.CheckExpireMail()
    local mails = scripts.UserModel.GetMails()
    if not mails then
        return false
    end

    local mail_common_config = GameCfg.ImmediatelyEmailTemplateConfig[config_id]
    if not mail_common_config or not mail_common_config.is_active then
        return false
    end

    local new_mail_info = MailDef.newMailData()
    new_mail_info.simple_data.mail_id = mails.last_immediate_mail_id + 1
    new_mail_info.simple_data.mail_config_id = config_id
    new_mail_info.simple_data.mail_type = MailDef.MailType.ImmediateConfig
    new_mail_info.simple_data.beg_ts = moon.time()
    new_mail_info.simple_data.end_ts = new_mail_info.simple_data.beg_ts + mail_common_config.validity_period
    new_mail_info.simple_data.mail_title_id = mail_common_config.title
    new_mail_info.simple_data.is_read = 0
    if table.size(items_simple) + table.size(item_datas) + table.size(coins) > 0 then
        new_mail_info.simple_data.is_have_items = 1
    end
    new_mail_info.simple_data.is_get = 0
    new_mail_info.mail_icon_id = mail_common_config.icon
    new_mail_info.mail_content_id = mail_common_config.content
    new_mail_info.sign = tostring(mail_common_config.signature)

    new_mail_info.items_simple = items_simple
    new_mail_info.item_datas = item_datas
    new_mail_info.coins = coins

    local ret = Mail.AddMail(mails, new_mail_info)
    if ret then
        mails.last_immediate_mail_id = mails.last_immediate_mail_id + 1
        Mail.SaveMailsNow()
    end

    return true
end

function Mail.MergeAttachment(mail_info, attach_items, attach_item_datas, attach_coins)
    for config_id, item_simple in pairs(mail_info.items_simple) do
        if not attach_items[config_id] then
            attach_items[config_id] = {
                id = config_id,
                count = 0,
                pos = 0,
            }
        end
        attach_items[config_id].count = attach_items[config_id].count + item_simple.item_count
    end
    for _, item_data in pairs(mail_info.item_datas) do
        table.insert(attach_item_datas, item_data)
    end
    for coin_id, coin in pairs(mail_info.coins) do
        if not attach_coins[coin_id] then
            attach_coins[coin_id] = coin
        else
            attach_coins[coin_id].coin_count = attach_coins[coin_id].coin_count + coin.coin_count
        end
    end
end

function Mail.PBGetAllMailReqCmd(req)
    -- 检查并删除过期邮件
    Mail.CheckExpireMail()
    local mails = scripts.UserModel.GetMails()
    if not mails then
        return context.S2C(context.net_id, CmdCode["PBGetAllMailRspCmd"],
            { code = ErrorCode.ServerInternalError, error = "数据加载出错", uid = context.uid }, req.msg_context.stub_id)
    end

    local rsp = {
        code = ErrorCode.None,
        error = "",
        uid = context.uid,
        mail_simple_list = {}
    }
    if mails.mails_info then
        for _, mail_info in pairs(mails.mails_info) do
            table.insert(rsp.mail_simple_list, mail_info.simple_data)
        end
    end

    return context.S2C(context.net_id, CmdCode["PBGetAllMailRspCmd"], rsp, req.msg_context.stub_id)
end

function Mail.PBGetMailDetailReqCmd(req)
    -- 检查并删除过期邮件
    Mail.CheckExpireMail()
    local mails = scripts.UserModel.GetMails()
    if not mails or not mails.mails_info then
        return context.S2C(context.net_id, CmdCode["PBGetMailDetailRspCmd"],
            { code = ErrorCode.ServerInternalError, error = "数据加载出错", uid = context.uid }, req.msg_context.stub_id)
    end
    
    local rsp = {
        code = ErrorCode.None,
        error = "",
        uid = context.uid,
        mail_ids = req.msg.mail_ids,
        mail_list = {}
    }
    for _, mail_id in pairs(req.msg.mail_ids) do
        local mail_info = mails.mails_info[mail_id]
        if not mail_info then
            rsp.code = ErrorCode.MailNotExist
            rsp.error = "邮件不存在"
            return context.S2C(context.net_id, CmdCode["PBGetMailDetailRspCmd"], rsp, req.msg_context.stub_id)
        end

        if mail_info.simple_data.mail_type == MailDef.MailType.System then
            table.insert(rsp.mail_list, mails.mails_info[mail_id])
        elseif mail_info.simple_data.mail_type == MailDef.MailType.TriggerConfig then
            local mail_common_config = GameCfg.TriggerEmailTemplateConfig[mail_info.simple_data.mail_config_id]
            if not mail_common_config then
                rsp.code = ErrorCode.MailConfigError
                rsp.error = "邮件配置错误"
                return context.S2C(context.net_id, CmdCode["PBGetMailDetailRspCmd"], rsp, req.msg_context.stub_id)
            end

            local common_mail = table.copy(mail_info, true)
            if common_mail then
                common_mail.simple_data.mail_title_id = mail_common_config.title
                common_mail.simple_data.mail_title = ""
                common_mail.mail_content_id = mail_common_config.content
                common_mail.mail_content = ""
                if mail_common_config.attachment
                    and table.size(mail_common_config.attachment) > 0 then
                    local ret_code = Mail.GetAttachmentFromCfg(mail_common_config.attachment, common_mail.items_simple,
                        common_mail.coins)
                    if ret_code ~= ErrorCode.None then
                        rsp.code = ret_code
                        rsp.error = "获取附件失败"
                        return context.S2C(context.net_id, CmdCode["PBGetMailDetailRspCmd"], rsp, req.msg_context.stub_id)
                    end
                end
                table.insert(rsp.mail_list, common_mail)
            end
        elseif mail_info.simple_data.mail_type == MailDef.MailType.ImmediateConfig then
            local mail_common_config = GameCfg.ImmediatelyEmailTemplateConfig[mail_info.simple_data.mail_config_id]
            if not mail_common_config then
                rsp.code = ErrorCode.MailConfigError
                rsp.error = "邮件配置错误"
                return context.S2C(context.net_id, CmdCode["PBGetMailDetailRspCmd"], rsp, req.msg_context.stub_id)
            end

            local common_mail = table.copy(mail_info, true)
            if common_mail then
                common_mail.simple_data.mail_title_id = mail_common_config.title
                common_mail.simple_data.mail_title = ""
                common_mail.mail_content_id = mail_common_config.content
                common_mail.mail_content = ""
                table.insert(rsp.mail_list, common_mail)
            end
        else
            rsp.code = ErrorCode.MailTypeError
            rsp.error = "邮件类型错误"
            return context.S2C(context.net_id, CmdCode["PBGetMailDetailRspCmd"], rsp, req.msg_context.stub_id)
        end
    end

    return context.S2C(context.net_id, CmdCode["PBGetMailDetailRspCmd"], rsp, req.msg_context.stub_id)
end

function Mail.PBReadMailReqCmd(req)
    -- 检查并删除过期邮件
    Mail.CheckExpireMail()
    local mails = scripts.UserModel.GetMails()
    if not mails or not mails.mails_info then
        return context.S2C(context.net_id, CmdCode["PBReadMailRspCmd"],
            { code = ErrorCode.ServerInternalError, error = "数据加载出错", uid = context.uid }, req.msg_context.stub_id)
    end

    local rsp = {
        code = ErrorCode.None,
        error = "",
        uid = context.uid,
        mail_id = req.msg.mail_id,
        mail_data = {}
    }
    local mail_info = mails.mails_info[req.msg.mail_id]
    if not mail_info then
        rsp.code = ErrorCode.MailNotExist
        rsp.error = "邮件不存在"
        return context.S2C(context.net_id, CmdCode["PBReadMailRspCmd"], rsp, req.msg_context.stub_id)
    end

    if mail_info.simple_data.mail_type == MailDef.MailType.System then
        rsp.mail_data = mail_info
    elseif mail_info.simple_data.mail_type == MailDef.MailType.TriggerConfig then
        local mail_common_config = GameCfg.TriggerEmailTemplateConfig[mail_info.simple_data.mail_config_id]
        if not mail_common_config then
            rsp.code = ErrorCode.MailConfigError
            rsp.error = "邮件配置错误"
            return context.S2C(context.net_id, CmdCode["PBGetMailDetailRspCmd"], rsp, req.msg_context.stub_id)
        end

        local common_mail = table.copy(mail_info, true)
        if common_mail then
            common_mail.simple_data.mail_title_id = mail_common_config.title
            common_mail.simple_data.mail_title = ""
            common_mail.mail_content_id = mail_common_config.content
            common_mail.mail_content = ""
            if mail_common_config.attachment
                and table.size(mail_common_config.attachment) > 0 then
                local ret_code = Mail.GetAttachmentFromCfg(mail_common_config.attachment, common_mail.items_simple,
                    common_mail.coins)
                if ret_code ~= ErrorCode.None then
                    rsp.code = ret_code
                    rsp.error = "获取附件失败"
                    return context.S2C(context.net_id, CmdCode["PBGetMailDetailRspCmd"], rsp, req.msg_context.stub_id)
                end
            end
            rsp.mail_data = common_mail
        end
    elseif mail_info.simple_data.mail_type == MailDef.MailType.ImmediateConfig then
        local mail_common_config = GameCfg.ImmediatelyEmailTemplateConfig[mail_info.simple_data.mail_config_id]
        if not mail_common_config then
            rsp.code = ErrorCode.MailConfigError
            rsp.error = "邮件配置错误"
            return context.S2C(context.net_id, CmdCode["PBGetMailDetailRspCmd"], rsp, req.msg_context.stub_id)
        end

        local common_mail = table.copy(mail_info, true)
        if common_mail then
            common_mail.simple_data.mail_title_id = mail_common_config.title
            common_mail.simple_data.mail_title = ""
            common_mail.mail_content_id = mail_common_config.content
            common_mail.mail_content = ""
            rsp.mail_data = common_mail
        end
    else
        rsp.code = ErrorCode.MailTypeError
        rsp.error = "邮件类型错误"
        return context.S2C(context.net_id, CmdCode["PBGetMailDetailRspCmd"], rsp, req.msg_context.stub_id)
    end

    -- 数据存储更新
    mail_info.simple_data.is_read = 1
    local now_ts = moon.time()
    if mail_info.simple_data.mail_type == MailDef.MailType.System then
        if now_ts + AFTER_READ_MAIL_EXPIRE_TIME < mail_info.simple_data.end_ts then
            mail_info.simple_data.end_ts = now_ts + AFTER_READ_MAIL_EXPIRE_TIME
        end
    elseif mail_info.simple_data.mail_type == MailDef.MailType.TriggerConfig then
        local mail_common_config = GameCfg.TriggerEmailTemplateConfig[mail_info.simple_data.mail_id]
        if mail_common_config
            and now_ts + mail_common_config.read_validity_period < mail_info.simple_data.end_ts then
            mail_info.simple_data.end_ts = now_ts + mail_common_config.read_validity_period
        end
    elseif mail_info.simple_data.mail_type == MailDef.MailType.ImmediateConfig then
        local mail_time_config = GameCfg.ImmediatelyEmailTemplateConfig[mail_info.simple_data.mail_id]
        if mail_time_config
            and now_ts + mail_time_config.read_validity_period < mail_info.simple_data.end_ts then
            mail_info.simple_data.end_ts = now_ts + mail_time_config.read_validity_period
        end
    end
    Mail.SaveMailsNow()

    return context.S2C(context.net_id, CmdCode["PBReadMailRspCmd"], rsp, req.msg_context.stub_id)
end

function Mail.PBGetRewardReqCmd(req)
    -- 检查并删除过期邮件
    Mail.CheckExpireMail()
    local mails = scripts.UserModel.GetMails()
    if not mails or not mails.mails_info then
        return context.S2C(context.net_id, CmdCode["PBGetRewardRspCmd"],
            { code = ErrorCode.ServerInternalError, error = "数据加载出错", uid = context.uid }, req.msg_context.stub_id)
    end

    local rsp = {
        code = ErrorCode.None,
        error = "",
        uid = context.uid,
        mail_ids = req.msg.mail_ids,
        mail_data = {}
    }
    --local stack_items, unstack_items, stack_coins = {}, {}, {}
    local attach_items, attach_item_datas, attach_coins = {}, {}, {}
    for _, mail_id in pairs(req.msg.mail_ids) do
        local mail_info = mails.mails_info[mail_id]
        if not mail_info then
            rsp.code = ErrorCode.MailNotExist
            rsp.error = "邮件不存在"
            return context.S2C(context.net_id, CmdCode["PBGetRewardRspCmd"], rsp, req.msg_context.stub_id)
        end
        if mail_info.simple_data.is_have_items == 0 or mail_info.simple_data.is_get == 1 then
            rsp.code = ErrorCode.MailHasGet
            rsp.error = "邮件已领取"
            return context.S2C(context.net_id, CmdCode["PBGetRewardRspCmd"], rsp, req.msg_context.stub_id)
        end

        if mail_info.simple_data.mail_type == MailDef.MailType.System then
            -- 统计附件
            Mail.MergeAttachment(mail_info, attach_items, attach_item_datas, attach_coins)
        elseif mail_info.simple_data.mail_type == MailDef.MailType.TriggerConfig then
            -- 从配置表添加附件
            local mail_common_config = GameCfg.TriggerEmailTemplateConfig[mail_info.simple_data.mail_config_id]
            if not mail_common_config then
                rsp.code = ErrorCode.MailConfigError
                rsp.error = "邮件配置错误"
                return context.S2C(context.net_id, CmdCode["PBGetRewardRspCmd"], rsp, req.msg_context.stub_id)
            end

            if mail_common_config.attachment
                and table.size(mail_common_config.attachment) > 0 then
                local ret_code = Mail.GetAttachmentFromCfg(mail_common_config.attachment, mail_info.items_simple,
                    mail_info.coins)
                if ret_code ~= ErrorCode.None then
                    rsp.code = ret_code
                    rsp.error = "获取附件失败"
                    return context.S2C(context.net_id, CmdCode["PBGetRewardRspCmd"], rsp, req.msg_context.stub_id)
                end

                -- 统计附件
                Mail.MergeAttachment(mail_info, attach_items, attach_item_datas, attach_coins)
            end
        elseif mail_info.simple_data.mail_type == MailDef.MailType.ImmediateConfig then
            local mail_common_config = GameCfg.ImmediatelyEmailTemplateConfig[mail_info.simple_data.mail_config_id]
            if not mail_common_config then
                rsp.code = ErrorCode.MailConfigError
                rsp.error = "邮件配置错误"
                return context.S2C(context.net_id, CmdCode["PBGetRewardRspCmd"], rsp, req.msg_context.stub_id)
            end

            -- 统计附件
            Mail.MergeAttachment(mail_info, attach_items, attach_item_datas, attach_coins)
        else
            rsp.code = ErrorCode.MailTypeError
            rsp.error = "邮件类型错误"
            return context.S2C(context.net_id, CmdCode["PBGetRewardRspCmd"], rsp, req.msg_context.stub_id)
        end
    end

    if table.size(attach_items) + table.size(attach_item_datas) + table.size(attach_coins) <= 0 then
        rsp.code = ErrorCode.MailNoReward
        rsp.error = "邮件没有奖励"
        return context.S2C(context.net_id, CmdCode["PBGetRewardRspCmd"], rsp, req.msg_context.stub_id)
    end

    -- 领取奖励
    -- 检查背包容量
    rsp.code = scripts.Bag.CheckEmptyEnough(BagDef.BagType.Cangku, attach_items, table.size(attach_item_datas))
    if rsp.code ~= ErrorCode.None then
        rsp.error = "背包已满"
        return context.S2C(context.net_id, CmdCode["PBGetRewardRspCmd"], rsp, req.msg_context.stub_id)
    end

    local stack_items, unstack_items, deal_coins = {}, {}, {}
    if table.size(attach_items) > 0 then
        local ok = ItemDefine.GetItemDataFromIdCount(attach_items, {}, stack_items, unstack_items, deal_coins)
        if not ok then
            rsp.code = ErrorCode.ConfigError
            rsp.error = "获取附件失败"
            return context.S2C(context.net_id, CmdCode["PBGetRewardRspCmd"], rsp, req.msg_context.stub_id)
        end
    end
    for _, item_data in pairs(attach_item_datas) do
        table.insert(unstack_items, item_data)
    end
    for coin_id, coin in pairs(attach_coins) do
        if not deal_coins[coin_id] then
            deal_coins[coin_id] = coin
        else
            deal_coins[coin_id].coin_count = deal_coins[coin_id].coin_count + coin.coin_count
        end
    end

    -- 添加道具
    local bag_change_log = {}
    if table.size(stack_items) + table.size(unstack_items) > 0 then
        rsp.code = scripts.Bag.AddItems(BagDef.BagType.Cangku, stack_items, unstack_items, bag_change_log)
        if rsp.code ~= ErrorCode.None then
            scripts.Bag.RollBackWithChange(bag_change_log)

            rsp.error = "添加物品失败"
            return context.S2C(context.net_id, CmdCode["PBGetRewardRspCmd"], rsp, req.msg_context.stub_id)
        end
    end
    if table.size(deal_coins) > 0 then
        rsp.code = scripts.Bag.DealCoins(deal_coins, bag_change_log)
        if rsp.code ~= ErrorCode.None then
            scripts.Bag.RollBackWithChange(bag_change_log)

            rsp.error = "添加金币失败"
            return context.S2C(context.net_id, CmdCode["PBGetRewardRspCmd"], rsp, req.msg_context.stub_id)
        end
    end

    -- 数据存储更新
    local now_ts = moon.time()
    for _, mail_id in pairs(req.msg.mail_ids) do
        local mail_info = mails.mails_info[mail_id]
        if mail_info then
            mail_info.simple_data.is_read = 1
            mail_info.simple_data.is_get = 1
            if mail_info.simple_data.mail_type == MailDef.MailType.System then
                if now_ts + AFTER_READ_MAIL_EXPIRE_TIME < mail_info.simple_data.end_ts then
                    mail_info.simple_data.end_ts = now_ts + AFTER_READ_MAIL_EXPIRE_TIME
                end
            elseif mail_info.simple_data.mail_type == MailDef.MailType.TriggerConfig then
                local mail_common_config = GameCfg.TriggerEmailTemplateConfig[mail_info.simple_data.mail_config_id]
                if mail_common_config
                    and now_ts + mail_common_config.read_validity_period < mail_info.simple_data.end_ts then
                    mail_info.simple_data.end_ts = now_ts + mail_common_config.read_validity_period
                end
            elseif mail_info.simple_data.mail_type == MailDef.MailType.ImmediateConfig then
                local mail_time_config = GameCfg.ImmediatelyEmailTemplateConfig[mail_info.simple_data.mail_config_id]
                if mail_time_config
                    and now_ts + mail_time_config.read_validity_period < mail_info.simple_data.end_ts then
                    mail_info.simple_data.end_ts = now_ts + mail_time_config.read_validity_period
                end
            end
        end
    end
    Mail.SaveMailsNow()

    -- local save_bags = {}
    -- for bagType, _ in pairs(bag_change_log) do
    --     save_bags[bagType] = 1
    -- end
    -- scripts.Bag.SaveAndLog(save_bags, bag_change_log)
    scripts.Bag.SaveAndLog(bag_change_log, ItemDef.ChangeReason.GetMailAttach)

    return context.S2C(context.net_id, CmdCode["PBGetRewardRspCmd"], rsp, req.msg_context.stub_id)
end

function Mail.PBDelMailReqCmd(req)
    -- 检查并删除过期邮件
    Mail.CheckExpireMail()
    local mails = scripts.UserModel.GetMails()
    if not mails or not mails.mails_info then
        return context.S2C(context.net_id, CmdCode["PBDelMailRspCmd"],
            { code = ErrorCode.ServerInternalError, error = "数据加载出错", uid = context.uid }, req.msg_context.stub_id)
    end

    local rsp = {
        code = ErrorCode.None,
        error = "",
        uid = context.uid,
        mail_ids = req.msg.mail_ids,
    }
    for _, mail_id in pairs(req.msg.mail_ids) do
        local mail_info = mails.mails_info[mail_id]
        if not mail_info then
            rsp.code = ErrorCode.MailNotExist
            rsp.error = "邮件不存在"
            return context.S2C(context.net_id, CmdCode["PBDelMailRspCmd"], rsp, req.msg_context.stub_id)
        end

        mails.mails_info[mail_id] = nil
    end

    Mail.SaveMailsNow()

    return context.S2C(context.net_id, CmdCode["PBDelMailRspCmd"], rsp, req.msg_context.stub_id)
end

return Mail