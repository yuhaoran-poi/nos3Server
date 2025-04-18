local moon = require "moon"
local common = require "common"
local cluster = require("cluster")
local GameCfg = common.GameCfg
local ErrorCode = common.ErrorCode
local CmdCode = common.CmdCode

---@type user_context
local context = ...
local scripts = context.scripts

---@class GuildProxy
local GuildProxy = {}

function GuildProxy.Init()
    
    local data = scripts.UserModel.MutGetUserData()
    if not data.guild then
        data.guild = {
            guild_id = 0,
            guild_node = 0,
            addr_guild = 0,
        }
    else
        -- 向公会管理器查询公会节点和地址
        local res, err = cluster.call(3999, "guildmgr", "GuildMgr.GetGuildNodeAndAddr", data.guild.guild_id)
        if res and res.code == ErrorCode.None then
            data.guild.guild_node = res.guild_node
            data.guild.addr_guild = res.addr_guild
        else
            -- 处理查询失败的情况，例如记录日志或返回错误码
            print("Failed to query guild node and address:", err)
            data.guild.guild_node = 0
            data.guild.addr_guild = 0
        end
    end
end

function GuildProxy.Start()
    -- body
end
-- 添加公会物品
function GuildProxy.PBGuildAddItemsCmd(req)
end

-- 删除公会物品
function GuildProxy.PBGuildDelItemsCmd(req)
end

-- 升公会最大人数的请求
function GuildProxy.PBGuildUpgradeMemberMaxcountReqCmd(req)
end

-- 会捐赠请求
function GuildProxy.PBGuildDonateReqCmd(req)
end

-- 公会领工资请求
function GuildProxy.PBGuildGetSalaryReqCmd(req)
end

-- 获取公会成员请求
function GuildProxy.PBGuildGetMembersReqCmd(req)
end

-- 获取公会列表
function GuildProxy.PBGuildGetGuildListReqCmd(req)
end

-- 创建公会请求
function GuildProxy.PBGuildCreateGuildReqCmd(req)
    local DB = scripts.UserModel.MutGetUserData()
    if DB.guild.guild_id ~= 0 then
        context.R2C(CmdCode.PBGuildCreateGuildRspCmd, {
            code = ErrorCode.GuildAlreadyInGuild,
        },req)
        return ErrorCode.GuildAlreadyInGuild
    end

    local res, err = cluster.call(3999, "guildmgr", "GuildMgr.CreateGuild", context.uid, req.msg.guild_name)
    if not res then
        print("CreateGuild failed:", err)
        context.R2C(CmdCode.PBGuildCreateGuildRspCmd, {
            code = ErrorCode.GuildCreateFailed,
        }, req)
        return ErrorCode.GuildCreateFailed
    end
    if res.code ~= ErrorCode.None then
        context.R2C(CmdCode.PBGuildCreateGuildRspCmd, {
            code = res.code,
        }, req)
        return res.code
    end
    scripts.UserModel.MutGet()
    -- 保存公会信息
    DB.guild.guild_id = res.guild_id
    DB.guild.guild_node = res.guild_node
    DB.guild.addr_guild = res.addr_guild
    -- 返回创建公会信息
    context.R2C(CmdCode.PBGuildCreateGuildRspCmd, {
        code = ErrorCode.None,
        guild_id = res.guild_id,
        guild_name = res.guild_name,
    },req)

end

-- 加入公会请求
function GuildProxy.PBGuildJoinGuildReqCmd(req)

end

-- 申请加入请求
function GuildProxy.PBGuildApplyJoinGuildReqCmd(req)
end

-- 回复申请加入请求
function GuildProxy.PBGuildAnswerApplyJoinGuildReqCmd(req)
end

-- 搜索公会
function GuildProxy.PBGuildSearchGuildReqCmd(req)
end

-- 邀请加入公会
function GuildProxy.PBGuildInviteJoinGuildReqCmd(req)
end

-- 回复邀请加入公会
function GuildProxy.PBGuildAnswerInviteJoinGuildReqCmd(req)
end

-- 退出公会
function GuildProxy.PBGuildQuitReqCmd(req)
end

-- 踢出公会
function GuildProxy.PBGuildExpelQuitReqCmd(req)
end

-- 公会授予职位
function GuildProxy.PBGuildGrantReqCmd(req)

end

-- 公会转让职位
function GuildProxy.PBGuildDemiseReqCmd(req)
end

-- 公会解散
function GuildProxy.PBGuildDismissReqCmd(req)
end

-- 公会解冻
function GuildProxy.PBGuildThawReqCmd(req)
end

-- 公会修改公告
function GuildProxy.PBGuildModifyAnnouncementReqCmd(req)
end

-- 公会增加职位
function GuildProxy.PBGuildAddDutyReqCmd(req)
end

-- 删除公会职位请求
function GuildProxy.PBGuildDelDutyReqCmd(req)
end

-- 公会修改职位权限
function GuildProxy.PBGuildModifyDutyRightReqCmd(req)
end

-- 修改公会职位名称
function GuildProxy.PBGuildModifyDutyNameReqCmd(req)
end

-- 修改公会职位等级
function GuildProxy.PBGuildModifyDutyLevelReqCmd(req)
end

-- 公会升级
function GuildProxy.PBGuildUpgradeReqCmd(req)
end

-- 公会头像修改
function GuildProxy.PBGuildModifyHeadIconReqCmd(req)
end

-- 获取申请列表
function GuildProxy.PBGuildGetApplyListReqCmd(req)
end

-- 修改公会名称
function GuildProxy.PBGuildModifyGuildNameReqCmd(req)
end

-- 物品兑换
function GuildProxy.PBGuildExchangeItemReqCmd(req)
end

-- 设置加入公会条件
function GuildProxy.PBSetGuildJoinConditionReqCmd(req)
end

-- 拉取公会记录
function GuildProxy.PBGuildRecordListReqCmd(req)
end

-- 设置战利品管理员
function GuildProxy.PBGuildSetSpoilsMgrReqCmd(req)
end

-- 管理员设置成员dkp值
function GuildProxy.PBGuildDkpChangeReqCmd(req)
end

-- 公会捐赠
function GuildProxy.PBGuildSendSpoilsReqCmd(req)
end

-- 刷新商店
function GuildProxy.PBGuildUpdateShopReqCmd(req)
end

-- 购买商店
function GuildProxy.PBGuildShopBuyItemReqCmd(req)
end

-- 购买推荐位
function GuildProxy.PBGuildBuyRecommentReqCmd(req)
end

-- 设置头像
function GuildProxy.PBGuildSetHeadReqCmd(req)
end

-------------------------------任务相关--------------------------
-- 接受任务
function GuildProxy.PBGuildAcceptTaskReqCmd(req)
end

-- 领取任务奖励
function GuildProxy.PBGuildGetTaskRewardReqCmd(req)
end

-- 公会日常任务奖励领取
function GuildProxy.PBGuildDayMissionAwardReqCmd(req)
end

---------------------------------GM命令-----------------------------
--GM命令更新公会背包数据
function GuildProxy.PBGuildAddItems2BagCmd(req)
end

-- GM命令设置公会状态
function GuildProxy.PBSetGuildStatusCmd(req)
end

-- GM命令开关捐赠
function GuildProxy.PBOpenGuildJuanZengCmd(req)
end
 

return GuildProxy