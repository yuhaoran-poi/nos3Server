local moon = require "moon"
local common = require "common"
local json = require("json")
local MailDef = require("common.def.MailDef")
local ItemDef = require("common.def.ItemDef")
local ItemDefine = require("common.logic.ItemDefine")
local GameCfg = common.GameCfg

local MailLogic = {}

function MailLogic.DealSystemMail(send_info_str)
    moon.debug("MailLogic.DealSystemMail send_info_str: %s", send_info_str)
    local send_info = json.decode(send_info_str)
    if not send_info then
        return false, "send_info_str error"
    end
    if not send_info.uids or type(send_info.uids) ~= "table" or table.size(send_info.uids) == 0 then
        return false, "send_info_str uids error"
    end
    if table.size(send_info.uids) > 1 then
        for _, uid in pairs(send_info.uids) do
            if uid == 0 then
                return false, "send_info_str uids error"
            end
        end
    end
    if not send_info.beg_ts or type(send_info.beg_ts) ~= "number" then
        return false, "send_info_str beg_ts error"
    end
    if not send_info.end_ts or type(send_info.end_ts) ~= "number" then
        return false, "send_info_str end_ts error"
    end
    if (not send_info.mail_title_id or type(send_info.mail_title_id) ~= "number")
        and (not send_info.mail_title or type(send_info.mail_title) ~= "string") then
        return false, "send_info_str mail_title_id or mail_title error"
    end
    if not send_info.mail_icon_id or type(send_info.mail_icon_id) ~= "number" then
        return false, "send_info_str mail_icon_id error"
    end
    if (not send_info.mail_content_id or type(send_info.mail_content_id) ~= "number")
        and (not send_info.mail_content or type(send_info.mail_content) ~= "string") then
        return false, "send_info_str mail_content_id or mail_content error"
    end
    if not send_info.sign or type(send_info.sign) ~= "string" then
        return false, "send_info_str sign error"
    end
    if send_info.attachments and type(send_info.attachments) ~= "table" then
        return false, "send_info_str attachments error"
    end

    local mail_info = MailDef.newMailData()
    mail_info.simple_data.mail_type = MailDef.MailType.System
    mail_info.simple_data.beg_ts = send_info.beg_ts
    mail_info.simple_data.end_ts = send_info.end_ts
    if send_info.mail_title_id then
        mail_info.simple_data.mail_title_id = send_info.mail_title_id
    end
    if send_info.mail_title then
        mail_info.simple_data.mail_title = send_info.mail_title
    end
    mail_info.mail_icon_id = send_info.mail_icon_id
    if send_info.mail_content_id then
        mail_info.mail_content_id = send_info.mail_content_id
    end
    if send_info.mail_content then
        mail_info.mail_content = send_info.mail_content
    end
    mail_info.sign = send_info.sign
    if send_info.attachments and table.size(send_info.attachments) > 0 then
        mail_info.simple_data.is_have_items = 1
    end

    if send_info.attachments then
        for _, attachment in pairs(send_info.attachments) do
            if not attachment.config_id
                or type(attachment.config_id) ~= "number"
                or attachment.config_id == 0 then
                return false, "send_info_str attachments config_id error"
            end
            if attachment.uniqid and type(attachment.uniqid) ~= "number" then
                return false, "send_info_str attachments uniqid error"
            end
            if not attachment.item_count
                or type(attachment.item_count) ~= "number"
                or attachment.item_count < 1 then
                return false, "send_info_str attachments item_count error"
            end
            if attachment.item_type and type(attachment.item_type) ~= "number" then
                return false, "send_info_str attachments item_type error"
            end
            if attachment.trade_cnt and type(attachment.trade_cnt) ~= "number" then
                return false, "send_info_str attachments trade_cnt error"
            end
            if attachment.special_info and type(attachment.special_info) ~= "table" then
                return false, "send_info_str attachments special_info error"
            end
            if attachment.special_info then
                if attachment.special_info.cur_durability
                    and type(attachment.special_info.cur_durability) ~= "number" then
                    return false, "send_info_str attachments special_info cur_durability error"
                end
                if attachment.special_info.strong_value
                    and type(attachment.special_info.strong_value) ~= "number" then
                    return false, "send_info_str attachments special_info strong_value error"
                end
                if attachment.special_info.tabooword_id
                    and type(attachment.special_info.tabooword_id) ~= "number" then
                    return false, "send_info_str attachments special_info tabooword_id error"
                end
                if attachment.special_info.light_cnt
                    and type(attachment.special_info.light_cnt) ~= "number" then
                    return false, "send_info_str attachments special_info light_cnt error"
                end
                if attachment.special_info.tags
                    and type(attachment.special_info.tags) ~= "table" then
                    return false, "send_info_str attachments special_info tags error"
                end
                if attachment.special_info.ability_tag
                    and type(attachment.special_info.ability_tag) ~= "table" then
                    return false, "send_info_str attachments special_info ability_tag error"
                end
            end

            local big_type = ItemDefine.GetItemPosType(attachment.config_id)
            if big_type == ItemDefine.EItemBigType.Coin then
                if not mail_info.coins[attachment.config_id] then
                    mail_info.coins[attachment.config_id] = ItemDef.newCoin()
                    mail_info.coins[attachment.config_id].coin_id = attachment.config_id
                end
                mail_info.coins[attachment.config_id].coin_count = attachment.item_count
            elseif big_type == ItemDefine.EItemBigType.StackItem then
                local item_cfg = GameCfg.Item[attachment.config_id]
                if not item_cfg then
                    return false, "send_info_str attachments error, config_id not exist"
                end
                if not mail_info.items_simple[attachment.config_id] then
                    mail_info.items_simple[attachment.config_id] = ItemDef.newItemSimple()
                    mail_info.items_simple[attachment.config_id].config_id = attachment.config_id
                end
                mail_info.items_simple[attachment.config_id].item_count = attachment.item_count
            elseif big_type == ItemDefine.EItemBigType.UnStackItem then
                local item_cfg = GameCfg.Item[attachment.config_id]
                if not item_cfg then
                    return false, "send_info_str attachments error, config_id not exist"
                end

                if (attachment.uniqid and attachment.uniqid ~= 0)
                    or (attachment.special_info) then
                    local small_type = ItemDefine.GetItemType(attachment.config_id)
                    local new_item_data = ItemDef.newItemData()
                    new_item_data.itype = small_type
                    new_item_data.common_info.config_id = attachment.config_id
                    if attachment.uniqid then
                        if attachment.uniqid ~= 0 and attachment.item_count > 1 then
                            return false, "send_info_str attachments uniqid error"
                        end
                        new_item_data.common_info.uniqid = attachment.uniqid
                    end
                    new_item_data.common_info.item_count = 1
                    new_item_data.common_info.item_type = item_cfg.type1
                    if attachment.trade_cnt then
                        new_item_data.common_info.trade_cnt = attachment.trade_cnt
                    end
                    new_item_data.special_info.durab_item = ItemDef.newDurabItem()
                    if attachment.special_info and attachment.special_info.cur_durability then
                        new_item_data.special_info.durab_item.cur_durability = attachment.special_info.cur_durability
                    end
                    if attachment.special_info and attachment.special_info.strong_value then
                        new_item_data.special_info.durab_item.strong_value = attachment.special_info.strong_value
                    end
                    for i = 1, attachment.item_count, 1 do
                        table.insert(mail_info.item_datas, new_item_data)
                    end
                else
                    if not mail_info.items_simple[attachment.config_id] then
                        mail_info.items_simple[attachment.config_id] = ItemDef.newItemSimple()
                        mail_info.items_simple[attachment.config_id].config_id = attachment.config_id
                    end
                    mail_info.items_simple[attachment.config_id].item_count = attachment.item_count
                end
            elseif big_type == ItemDefine.EItemBigType.UniqueItem then
                local item_cfg = GameCfg.UniqueItem[attachment.config_id]
                if not item_cfg then
                    return false, "send_info_str attachments error, config_id not exist"
                end

                if (attachment.uniqid and attachment.uniqid ~= 0)
                    or (attachment.special_info) then
                    local small_type = ItemDefine.GetItemType(attachment.config_id)
                    local new_item_data = ItemDef.newItemData()
                    new_item_data.itype = small_type
                    new_item_data.common_info.config_id = attachment.config_id
                    if attachment.uniqid then
                        if attachment.uniqid ~= 0 and attachment.item_count > 1 then
                            return false, "send_info_str attachments uniqid error"
                        end
                        new_item_data.common_info.uniqid = attachment.uniqid
                    end
                    new_item_data.common_info.item_count = 1
                    new_item_data.common_info.item_type = item_cfg.type1
                    if attachment.trade_cnt then
                        new_item_data.common_info.trade_cnt = attachment.trade_cnt
                    end

                    if small_type == ItemDefine.EItemSmallType.MagicItem then
                        new_item_data.special_info.magic_item = ItemDef.newMagicItem()
                        if attachment.special_info and attachment.special_info.cur_durability then
                            new_item_data.special_info.magic_item.cur_durability = attachment.special_info
                                .cur_durability
                        end
                        if attachment.special_info and attachment.special_info.strong_value then
                            new_item_data.special_info.magic_item.strong_value = attachment.special_info.strong_value
                        end
                        if attachment.special_info and attachment.special_info.tabooword_id then
                            new_item_data.special_info.magic_item.tabooword_id = attachment.special_info.tabooword_id
                        end
                        if attachment.special_info and attachment.special_info.light_cnt then
                            new_item_data.special_info.magic_item.light_cnt = attachment.special_info.light_cnt
                        end
                        if attachment.special_info and attachment.special_info.tags then
                            new_item_data.special_info.magic_item.tags = attachment.special_info.tags
                        end
                        if attachment.special_info and attachment.special_info.ability_tag then
                            new_item_data.special_info.magic_item.ability_tag = attachment.special_info.ability_tag
                        end
                    elseif small_type == ItemDefine.EItemSmallType.DiagramsCard then
                        new_item_data.special_info.diagrams_item = ItemDef.newDiagramsCard()
                        if attachment.special_info and attachment.special_info.cur_durability then
                            new_item_data.special_info.diagrams_item.cur_durability = attachment.special_info
                                .cur_durability
                        end
                        if attachment.special_info and attachment.special_info.strong_value then
                            new_item_data.special_info.diagrams_item.strong_value = attachment.special_info.strong_value
                        end
                        if attachment.special_info and attachment.special_info.tabooword_id then
                            new_item_data.special_info.diagrams_item.tabooword_id = attachment.special_info.tabooword_id
                        end
                        if attachment.special_info and attachment.special_info.light_cnt then
                            new_item_data.special_info.diagrams_item.light_cnt = attachment.special_info.light_cnt
                        end
                        if attachment.special_info and attachment.special_info.tags then
                            new_item_data.special_info.diagrams_item.tags = attachment.special_info.tags
                        end
                        if attachment.special_info and attachment.special_info.ability_tag then
                            new_item_data.special_info.diagrams_item.ability_tag = attachment.special_info.ability_tag
                        end
                    else
                        return false, "send_info_str attachments error, config_id not exist"
                    end
                    for i = 1, attachment.item_count, 1 do
                        table.insert(mail_info.item_datas, new_item_data)
                    end
                else
                    if not mail_info.items_simple[attachment.config_id] then
                        mail_info.items_simple[attachment.config_id] = ItemDef.newItemSimple()
                        mail_info.items_simple[attachment.config_id].config_id = attachment.config_id
                    end
                    mail_info.items_simple[attachment.config_id].item_count = attachment.item_count
                end
            end
        end
    end

    local all_user = 0
    moon.debug("MailLogic.DealSystemMail table.size(send_info.uids)", table.size(send_info.uids))
    moon.debug("MailLogic.DealSystemMail send_info.uids[1]", send_info.uids[1])
    if table.size(send_info.uids) == 1 and send_info.uids[1] == 0 then
        all_user = 1
    end

    return true, {mail_data = mail_info, all_user = all_user, recv_uids = send_info.uids}
end

return MailLogic
