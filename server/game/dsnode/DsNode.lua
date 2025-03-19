local moon = require("moon")
local common = require("common")
local CmdCode = common.CmdCode
local GameCfg = common.GameCfg

---@type user_context
local context = ...
local scripts = context.scripts

--- 内存中的状态
local state = { 
    online = false,
    ismatching = false
}
---@class DsNode
local DsNode = {}
function DsNode.Load(req)
    local function fn()
        local isnew = false
        local data = {
                openid = req.openid,
                net_id = req.net_id,
                name = req.openid,
                level = 10,
                score = 0
        }
        --scripts.UserModel.Create(data)
        ---初始化自己数据
        context.batch_invoke("Init", isnew)
        ---初始化互相引用的数据
        context.batch_invoke("Start")
        return data
    end

    local ok, res = xpcall(fn, debug.traceback, req)
    if not ok then
        return ok, res
    end

    if not res then
        local errmsg = string.format("user init failed, can not find user %d", req.net_id)
        moon.error(errmsg)
        return false, errmsg
    end

    context.net_id = res.net_id
    return true
end

function DsNode.Login(req)
    if state.online then
        context.batch_invoke("Offline")
    end
    context.batch_invoke("Online")
    return 0
    --return scripts.UserModel.Get().openid
end

function DsNode.Logout()
    context.batch_invoke("Offline")
    return true
end

function DsNode.Init()
    GameCfg.Load()
end

function DsNode.Start()

end

function DsNode.Online()
    state.online = true
    --scripts.UserModel.MutGet().logintime = moon.time()
end

function DsNode.Offline()
    if not state.online then
        return
    end

    print(context.net_id, "offline")
    state.online = false

	if state.ismatching then
        state.ismatching = false
        moon.send("lua", context.addr_center, "Center.UnMatch", context.net_id)
    end
end


function DsNode.Exit()
    local ok, err = xpcall(scripts.UserModel.Save, debug.traceback)
    if not ok then
        moon.error("user exit save db error", err)
    end
    moon.quit()
    return true
end

function DsNode.C2SPing(req)
    req.stime = moon.time()
    context.S2C(CmdCode.S2CPong, req)
end
 
return DsNode
