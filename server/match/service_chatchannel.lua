--require("common.LuaPanda").start("127.0.0.1", 8818)
local moon = require("moon")
local setup = require("common.setup")

---@class selection_context:base_context
---@field scripts selection_scripts
local context = {
    selection_id = 0,
    selection_type = 0,
    slection_addr = 0,
    memember_uids = {}, -- 房间玩家
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
    print("selection %d shutdown", context.selection_id)
end)

---垃圾收集器间歇率控制着收集器需要在开启新的循环前要等待多久。
---增大这个值会减少收集器的积极性。
---当这个值比 100 小的时候，收集器在开启新的循环前不会有等待。
---设置这个值为 200 就会让收集器等到总内存使用量达到 之前的两倍时才开始新的循环。
---params: 垃圾收集器间歇率, 垃圾收集器步进倍率, 垃圾收集器单次运行步长“大小”
collectgarbage("incremental", 120)
