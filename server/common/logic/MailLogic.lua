local moon = require "moon"
local common = require "common"
local json = require("json")
local MailDef = require("common.def.MailDef")
local ItemDef = require("common.def.ItemDef")
local ItemDefine = require("common.logic.ItemDefine")
local GameCfg = common.GameCfg

local MailLogic = {}

function MailLogic.DealSystemMail(send_info_str)
    local send_info = json.decode(send_info_str)
    if not send_info then
        return false, "send_info_str error"
    end
    if not send_info.uids or table.size(send_info.uids) == 0 then
        return false, "send_info_str uids error"
    end
    if table.size(send_info.uids) > 1 then
        for _, uid in pairs(send_info.uids) do
            if uid == 0 then
                return false, "send_info_str uids error"
            end
        end
    end
    if not send_info.beg_ts or not send_info.end_ts then
        return false, "send_info_str beg_ts or end_ts error"
    end
    if not send_info.mail_title_id and not send_info.mail_title then
        return false, "send_info_str mail_title_id or mail_title error"
    end
    if not send_info.mail_icon_id then
        return false, "send_info_str mail_icon_id error"
    end
    if not send_info.mail_content_id and not send_info.mail_content then
        return false, "send_info_str mail_content_id or mail_content error"
    end
    if not send_info.sign then
        return false, "send_info_str sign error"
    end

    local ok, stack_items, unstack_items, coins = ItemDefine.GetItemDataFromIdCount(send_info.items)
    if not ok then
        return false, "send_info_str items error"
    end

    local new_mail_info = MailDef.newMailData()
end

return MailLogic
