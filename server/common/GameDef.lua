local fs = require("fs")

---游戏逻辑相关配置

local M = {
    PTYPE_C2S = 100,--- client to server
    PTYPE_S2C = 101,--- server to client
    PTYPE_SBC = 102,---server broadcast to client
    
    PTYPE_C2D = 200, --- client to ds server
    PTYPE_D2C = 201, --- ds to client
    PTYPE_D2D = 202, --- ds to ds
    PTYPE_S2D = 203, --- extern sys to ds
    PTYPE_D2S = 204,
    ---Entity Type Define
    TypeRoom = 1,
    TypeFood = 2,
    TypeMail = 3,
    ---

    AoiEvent = {
        UpdateDir = 10,
        UpdateRadius = 11,
    },

    ---@enum MailFlag
    MailFlag = {
        --- 已领取
        Taked = 1,
        --- 只展示
        ShowOnly = 2,
        --- 已读
        Read = 4,
        --- 已锁定
        Locked = 8,
        --- 已收藏
        Marked = 16,
    },
    --@enum DSGateConst
    DSGateConst = {
        -- 转发到ds全局服务器
        GlobalGateNetId = 0,
        -- 转发到外围服处理
        ExternalGateNetId = 1,
        -- 带有Node最小Id
        MinNodeGateNetId = 0x1000000,
        -- 无效Id
        InvalidGateNetId =  0xffffffff,
    },
}

function M.LogShrinkToFit(dir, nameprefix, maxcount)
    local logfiles = {}
    local log_filename_start = nameprefix
    local list = fs.listdir(dir)
    for _, file in ipairs(list) do
        if not fs.isdir(file) then
            local match = string.gmatch(fs.stem(file), "%a+-%d+")()
            if match and match == log_filename_start then
                table.insert(logfiles, file)
            end
        end
    end

    table.sort(logfiles)
    while #logfiles > maxcount do
        fs.remove(table.remove(logfiles, 1))
    end
end

return M
