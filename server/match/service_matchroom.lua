--require("common.LuaPanda").start("127.0.0.1", 8818)
local moon = require("moon")
local setup = require("common.setup")

---@class matchroom_context:base_context
---@field scripts matchroom_scripts
local context = {
    room_id = 0,        -- 房间ID
    match_type = 0,     -- 匹配类型
    room_addr = 0,      -- 房间地址
    room_status = 0,    -- 房间状态
    memember_uids = {}, -- 房间玩家
    ob_uids = {},       -- 房间观战列表
    create_ds = {
        create_count = 0, -- 创建房间次数
        qurey_count = 0,  -- 查询房间次数
        join_count = 0,   -- 加入房间次数
    },
    ds_info = {
        ds_ip = "", -- ds ip
        ds_port = 0, -- ds port
    },       -- ds房间信息
    teams = {},           -- 房间队伍
    ob_teams = {},        -- 房间观战队伍
    
    scripts = {},
}

local command = setup(context,"selection")
context.addr_db_redis = moon.queryservice("db_user")
if moon.queryservice("db_game") > 0 then
    context.addr_db_game = moon.queryservice("db_game")
end
---@diagnostic disable-next-line: duplicate-set-field
command.hotfix = function(names)
    
end

moon.shutdown(function()
    print("selection %d shutdown", context.room_id)
end)

---垃圾收集器间歇率控制着收集器需要在开启新的循环前要等待多久。
---增大这个值会减少收集器的积极性。
---当这个值比 100 小的时候，收集器在开启新的循环前不会有等待。
---设置这个值为 200 就会让收集器等到总内存使用量达到 之前的两倍时才开始新的循环。
---params: 垃圾收集器间歇率, 垃圾收集器步进倍率, 垃圾收集器单次运行步长“大小”
collectgarbage("incremental", 120)
