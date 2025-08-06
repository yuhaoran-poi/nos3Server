local LuaExt = require "common.LuaExt"

local MailDef = {
    MailType = {
        System = 1,
        TriggerConfig = 2,
        ImmediateConfig = 3,
    },
}

local defaultPBMailSimpleData = {
    mail_id = 0,
    mail_config_id = 0,
    mail_type = 0,
    beg_ts = 0,
    end_ts = 0,
    mail_title_id = 0,
    mail_title = "",
    is_read = 0,
    is_have_items = 0,
    is_get = 0,
}

local defaultPBMailData = {
    simple_data = LuaExt.const(table.copy(defaultPBMailSimpleData)),
    mail_icon_id = 0,
    mail_content_id = 0,
    mail_content = "",
    sign = "",
    items = {},
}

local defaultPBUserMailBox = {
    last_system_mail_id = 0,
    last_trigger_mail_id = 0,
    last_immediate_mail_id = 0,
    mails_info = {},
}

---@return PBMailSimpleData
function MailDef.newMailSimpleData()
    return LuaExt.const(table.copy(defaultPBMailSimpleData))
end

---@return PBMailData
function MailDef.newMailData()
    return LuaExt.const(table.copy(defaultPBMailData))
end

---@return PBUserMailBox
function MailDef.newUserMailBox()
    return LuaExt.const(table.copy(defaultPBUserMailBox))
end

return MailDef
