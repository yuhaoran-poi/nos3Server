-- local moon = require "moon"
-- local common = require "common"
-- local cluster = require("cluster")
-- local GameCfg = common.GameCfg
-- local ErrorCode = common.ErrorCode
-- local CmdCode = common.CmdCode
-- local Database = common.Database

-- ---@type user_context
-- local context = ...
-- local scripts = context.scripts

-- ---@class Friend
-- local Friend = {}

-- function Friend.Init()

-- end

-- function Friend.Start()
--     --加载好友数据
--     local friends_data = Friend.LoadFriends()
--     if friends_data then
--         scripts.UserModel.SetFriends(friends_data)
--     end

--     local friends = scripts.UserModel.GetFriends()
--     if not friends then
--         roles = RoleDef.newUserRoleDatas()
--         scripts.UserModel.SetRoles(roles)

--         for k, v in pairs(init_cfg.item) do
--             if k >= RoleDef.RoleDefine.RoleID.Start and k <= RoleDef.RoleDefine.RoleID.End then
--                 --local retxx = LuaPanda and LuaPanda.BP and LuaPanda.BP()
--                 Role.AddRole(k)
--             end
--         end
--         Role.SetRoleBattle(init_cfg.battle_role, false)

--         Role.SaveRolesNow()
--     end

--     local data = scripts.UserModel.MutGetUserAttr()
--     if data.guild_id == 0 then
--         return
--     end
--     -- 向公会管理器查询公会节点和地址
--     local res, err = cluster.call(CmdEnum.FixedNodeId.MANAGER, "guildmgr", "GuildMgr.GetGuildNodeAndAddr",
--         data.guild.guild_id)
--     if res and res.code == ErrorCode.None then
--         guild_node = res.guild_node
--         addr_guild = res.addr_guild
--     else
--         -- 处理查询失败的情况，例如记录日志或返回错误码
--         print("Failed to query guild node and address:", err)
--         guild_node = 0
--         addr_guild = 0
--     end
-- end

-- function Friend.LoadFriends()
--     local friends_data = Database.loadfriends(context.addr_db_user, context.uid)
--     return friends_data
-- end

-- -- 添加公会物品
-- function Friend.PBGuildAddItemsCmd(req)
-- end

-- -- 删除公会物品
-- function Friend.PBGuildDelItemsCmd(req)
-- end

-- -- 升公会最大人数的请求
-- function Friend.PBGuildUpgradeMemberMaxcountReqCmd(req)
-- end

-- -- 会捐赠请求
-- function Friend.PBGuildDonateReqCmd(req)
-- end

-- -- 公会领工资请求
-- function Friend.PBGuildGetSalaryReqCmd(req)
-- end

-- -- 获取公会成员请求
-- function Friend.PBGuildGetMembersReqCmd(req)
-- end

-- -- 获取公会列表
-- function Friend.PBGuildGetGuildListReqCmd(req)
-- end

-- -- 创建公会请求
-- function Friend.PBGuildCreateGuildReqCmd(req)
 
--     local DB = scripts.UserModel.GetUserAttr()
--     if DB.guild.guild_id ~= 0 then
--         context.R2C(CmdCode.PBGuildCreateGuildRspCmd, {
--             code = ErrorCode.GuildAlreadyInGuild,
--         },req)
--         return ErrorCode.GuildAlreadyInGuild
--     end

--     local res, err = cluster.call(3999, "guildmgr", "GuildMgr.CreateGuild", context.uid, req.msg.guild_name)
--     if not res then
--         print("CreateGuild failed:", err)
--         context.R2C(CmdCode.PBGuildCreateGuildRspCmd, {
--             code = ErrorCode.GuildCreateFailed,
--         }, req)
--         return ErrorCode.GuildCreateFailed
--     end
--     if res.code ~= ErrorCode.None then
--         context.R2C(CmdCode.PBGuildCreateGuildRspCmd, {
--             code = res.code,
--         }, req)
--         return res.code
--     end
--     scripts.UserModel.MutGet()
--     -- 保存公会信息
--     DB.guild.guild_id = res.guild_id
--     DB.guild.guild_node = res.guild_node
--     DB.guild.addr_guild = res.addr_guild
--     -- 返回创建公会信息
--     context.R2C(CmdCode.PBGuildCreateGuildRspCmd, {
--         code = ErrorCode.None,
--         guild_id = res.guild_id,
--         guild_name = res.guild_name,
--     },req)

-- end

-- -- 加入公会请求
-- function Friend.PBGuildJoinGuildReqCmd(req)

-- end

-- -- 申请加入请求
-- function Friend.PBGuildApplyJoinGuildReqCmd(req)
--     local DB = scripts.UserModel.GetUserAttr()
--     if DB.guild.guild_id ~= 0 then
--         context.R2C(CmdCode.PBGuildApplyJoinGuildRspCmd, {
--             code = ErrorCode.GuildAlreadyInGuild,
--         }, req)
--         return ErrorCode.GuildAlreadyInGuild
--     end
--     -- 查询公会节点和地址
--     local res, err = cluster.call(3999, "guildmgr", "GuildMgr.GetGuildNodeAndAddr", req.msg.guild_id)
--     if not res then
--         print("Failed to query guild node and address:", err)
--         context.R2C(CmdCode.PBGuildApplyJoinGuildRspCmd, {
--             code = ErrorCode.GuildGetGuildNodeFailed,     
--         })
--         return ErrorCode.GuildGetGuildNodeFailed
--     end
--     if res.code ~= ErrorCode.None then
--         context.R2C(CmdCode.PBGuildApplyJoinGuildRspCmd, {
--             code = res.code,
--         })
--         return res.code
--     end
--     -- 向公会服务发送申请加入请求
--     local res, err = cluster.call(res.guild_node, "guild", "Guild.ApplyJoinGuild", context.uid, req.msg.guild_id)
--     if not res then
--         print("Guild.ApplyJoinGuild failed:", err)
--         context.R2C(CmdCode.PBGuildApplyJoinGuildRspCmd, {
--             code = ErrorCode.GuildApplyJoinGuildFailed,
--         })
--         return ErrorCode.GuildApplyJoinGuildFailed
--     end
--     if res.code ~= ErrorCode.None then
--         context.R2C(CmdCode.PBGuildApplyJoinGuildRspCmd, {
--             code = res.code,
--         })
--         return res.code
--     end
--     -- 保存公会信息
--     DB.guild.guild_id = res.guild_id
--     DB.guild.guild_node = res.guild_node
--     DB.guild.addr_guild = res.addr_guild
--     -- 返回申请加入公会成功
--     context.R2C(CmdCode.PBGuildApplyJoinGuildRspCmd, {
--         code = ErrorCode.None,
--         guild_id = res.guild_id,
--         guild_name = res.guild_name,
--     })
--     return ErrorCode.None
-- end

-- -- 回复申请加入请求
-- function Friend.PBGuildAnswerApplyJoinGuildReqCmd(req)
--     -- 检查是否有公会
--     local DB = scripts.UserModel.GetUserAttr()
--     if DB.guild.guild_id == 0 then
--         context.R2C(CmdCode.PBGuildAnswerApplyJoinGuildRspCmd, {
--             code = ErrorCode.GuildNotInGuild,
--         }, req)
--         return ErrorCode.GuildNotInGuild
--     end
--     -- 发送到公会服务处理
--     local res, err = cluster.call(DB.guild.guild_node, DB.guild.addr_guild, "Guild.AnswerApplyJoinGuild", context.uid, req.msg.guild_id, req.msg.agree)
--     if not res then
--         print("Guild.AnswerApplyJoinGuild failed:", err)
--         context.R2C(CmdCode.PBGuildAnswerApplyJoinGuildRspCmd, {
--             code = ErrorCode.GuildAnswerApplyJoinGuildFailed,
--         })
--         return ErrorCode.GuildAnswerApplyJoinGuildFailed
--     end
--     if res.code ~= ErrorCode.None then
--         context.R2C(CmdCode.PBGuildAnswerApplyJoinGuildRspCmd, {
--             code = res.code,
--         })
--         return res.code
--     end
--     -- 返回处理结果
--     context.R2C(CmdCode.PBGuildAnswerApplyJoinGuildRspCmd, {
--         code = ErrorCode.None,
--     })
--     return ErrorCode.None
-- end

-- -- 搜索公会
-- function Friend.PBGuildSearchGuildReqCmd(req)
-- end

-- -- 邀请加入公会
-- function Friend.PBGuildInviteJoinGuildReqCmd(req)
--     -- 检查是否有公会
--     local DB = scripts.UserModel.GetUserAttr()
--     if DB.guild.guild_id == 0 then
--         context.R2C(CmdCode.PBGuildInviteJoinGuildRspCmd, {
--         }, req)
--         return ErrorCode.GuildNotInGuild
--     end
--     -- 发送到公会服务处理
--     local res, err = cluster.call(DB.guild.guild_node, DB.guild.addr_guild, "Guild.InviteJoinGuild", context.uid, req.msg.guild_id, req.msg.target_uid)
--     if not res then
--         print("Guild.InviteJoinGuild failed:", err)
--         context.R2C(CmdCode.PBGuildInviteJoinGuildRspCmd, {
--             code = ErrorCode.GuildInviteJoinGuildFailed, 
--         })
--         return ErrorCode.GuildInviteJoinGuildFailed
--     end
--     if res.code ~= ErrorCode.None then
--         context.R2C(CmdCode.PBGuildInviteJoinGuildRspCmd, {
--             code = res.code,
--         })
--         return res.code
--     end
--     -- 返回处理结果
--     context.R2C(CmdCode.PBGuildInviteJoinGuildRspCmd, {
--         code = ErrorCode.None,
--     })
--     return ErrorCode.None
-- end

-- -- 回复邀请加入公会
-- function Friend.PBGuildAnswerInviteJoinGuildReqCmd(req)
--     -- 有公会不能回复
--     local DB = scripts.UserModel.GetUserAttr()
--     if DB.guild.guild_id ~= 0 then
--         context.R2C(CmdCode.PBGuildAnswerInviteJoinGuildRspCmd, {
--             code = ErrorCode.GuildAlreadyInGuild,
--         }, req)
--         return ErrorCode.GuildAlreadyInGuild
--     end
--     -- 发送到公会服务处理
--     local res, err = cluster.call(DB.guild.guild_node, DB.guild.addr_guild, "Guild.AnswerInviteJoinGuild", context.uid,
--         req.msg.inviter_uid, req.msg.agree)
--     if not res then
--         print("Guild.AnswerInviteJoinGuild failed:", err)
--         context.R2C(CmdCode.PBGuildAnswerInviteJoinGuildRspCmd, {
--             code = ErrorCode.GuildAnswerInviteJoinGuildFailed, 
--         })
--         return ErrorCode.GuildAnswerInviteJoinGuildFailed
--     end
--     if res.code ~= ErrorCode.None then
--         context.R2C(CmdCode.PBGuildAnswerInviteJoinGuildRspCmd, {
--             code = res.code,
--         })
--         return res.code
--     end
--     -- 返回处理结果
--     context.R2C(CmdCode.PBGuildAnswerInviteJoinGuildRspCmd, {
--         code = ErrorCode.None,
--     })
-- end

-- -- 退出公会
-- function Friend.PBGuildQuitReqCmd(req)
--     -- 会长不能退出自己的公会
--     local DB = scripts.UserModel.MutGetUserAttr()
--     if DB.guild.guild_id == 0 then
--         context.R2C(CmdCode.PBGuildQuitRspCmd, {
--             code = ErrorCode.GuildNotInGuild,
--         }, req)
--         return ErrorCode.GuildNotInGuild
--     end
--     -- 向公会服务发送退出公会请求
--     local res, err = cluster.call(DB.guild.guild_node, DB.guild.addr_guild, "Guild.MemberQuit", context.uid)
--     if not res then
--         print("Guild.PBGuildQuitReqCmd failed:", err)
--         context.R2C(CmdCode.PBGuildQuitRspCmd, {
--             code = ErrorCode.GuildQuitFailed,
--         }, req)
--         return ErrorCode.GuildQuitFailed
--     end
--     if res.code ~= ErrorCode.None then
--         context.R2C(CmdCode.PBGuildQuitRspCmd, {
--             code = res.code,
--         }, req)
--         return res.code
--     end
--     -- 清空公会信息
--     DB.guild.guild_id = 0
--     DB.guild.guild_node = 0
--     DB.guild.addr_guild = 0
--     -- 返回退出公会成功
--     context.R2C(CmdCode.PBGuildQuitRspCmd, {
--         code = ErrorCode.None,
--     })
--     return ErrorCode.None
-- end

 
-- -- 踢出公会
-- function Friend.PBGuildExpelQuitReqCmd(req)
--     -- 检查是否有公会
--     local DB = scripts.UserModel.GetUserAttr()
--     if DB.guild.guild_id == 0 then
--         context.R2C(CmdCode.PBGuildExpelQuitRspCmd, {
--             code = ErrorCode.GuildNotInGuild,
--         }, req)
--         return ErrorCode.GuildNotInGuild
--     end
--     -- 发送到公会服务处理
--     local res, err = cluster.call(DB.guild.guild_node, DB.guild.addr_guild, "Guild.MemberExpel", context.uid,
--         req.msg.target_uid)
--     if not res then
--         print("Guild.MemberExpel failed:", err)
--         context.R2C(CmdCode.PBGuildExpelQuitRspCmd, {
--             code = ErrorCode.GuildExpelFailed,
--         })
--         return ErrorCode.GuildExpelFailed
--     end
--     if res.code ~= ErrorCode.None then
--         context.R2C(CmdCode.PBGuildExpelQuitRspCmd, {
--             code = res.code,
--         })
--         return res.code
--     end
--     -- 返回处理结果
--     context.R2C(CmdCode.PBGuildExpelQuitRspCmd, {
--         code = ErrorCode.None,
--     })
-- end

-- -- 公会授予职位
-- function Friend.PBGuildGrantReqCmd(req)

-- end

-- -- 公会转让职位
-- function Friend.PBGuildDemiseReqCmd(req)
-- end

-- -- 公会解散
-- function Friend.PBGuildDismissReqCmd(req)
-- -- 检查是否有公会
-- local DB = scripts.UserModel.GetUserAttr()
--     if DB.guild.guild_id == 0 then
--         context.R2C(CmdCode.PBGuildDismissRspCmd, {
--             code = ErrorCode.GuildNotInGuild,
--         }, req)
--         return ErrorCode.GuildNotInGuild
--     end
--     -- 发送到公会服务处理
--     local res, err = cluster.call(DB.guild.guild_node, DB.guild.addr_guild, "Guild.DismissGuild", context.uid)
--     if not res then
--         print("Guild.DismissGuild failed:", err)
--         context.R2C(CmdCode.PBGuildDismissRspCmd, {
--             code = ErrorCode.GuildDismissFailed,    
--         })
--         return ErrorCode.GuildDismissFailed
--     end
--     if res.code ~= ErrorCode.None then
--         context.R2C(CmdCode.PBGuildDismissRspCmd, {
--             code = res.code,
--         })
--         return res.code
--     end
--     -- 清空公会信息
--     DB.guild.guild_id = 0
--     DB.guild.guild_node = 0
--     DB.guild.addr_guild = 0
--     -- 返回处理结果
--     context.R2C(CmdCode.PBGuildDismissRspCmd, {
--         code = ErrorCode.None,
--     })

-- end

-- -- 公会解冻
-- function Friend.PBGuildThawReqCmd(req)
-- end

-- -- 公会修改公告
-- function Friend.PBGuildModifyAnnouncementReqCmd(req)
-- end

-- -- 公会增加职位
-- function Friend.PBGuildAddDutyReqCmd(req)
-- end

-- -- 删除公会职位请求
-- function Friend.PBGuildDelDutyReqCmd(req)
-- end

-- -- 公会修改职位权限
-- function Friend.PBGuildModifyDutyRightReqCmd(req)
-- end

-- -- 修改公会职位名称
-- function Friend.PBGuildModifyDutyNameReqCmd(req)
-- end

-- -- 修改公会职位等级
-- function Friend.PBGuildModifyDutyLevelReqCmd(req)
-- end

-- -- 公会升级
-- function Friend.PBGuildUpgradeReqCmd(req)
-- end

-- -- 公会头像修改
-- function Friend.PBGuildModifyHeadIconReqCmd(req)
-- end

-- -- 获取申请列表
-- function Friend.PBGuildGetApplyListReqCmd(req)
-- end

-- -- 修改公会名称
-- function Friend.PBGuildModifyGuildNameReqCmd(req)
-- end

-- -- 物品兑换
-- function Friend.PBGuildExchangeItemReqCmd(req)
-- end

-- -- 设置加入公会条件
-- function Friend.PBSetGuildJoinConditionReqCmd(req)
-- end

-- -- 拉取公会记录
-- function Friend.PBGuildRecordListReqCmd(req)
-- end

-- -- 设置战利品管理员
-- function Friend.PBGuildSetSpoilsMgrReqCmd(req)
-- end

-- -- 管理员设置成员dkp值
-- function Friend.PBGuildDkpChangeReqCmd(req)
-- end

-- -- 公会捐赠
-- function Friend.PBGuildSendSpoilsReqCmd(req)
-- end

-- -- 刷新商店
-- function Friend.PBGuildUpdateShopReqCmd(req)
-- end

-- -- 购买商店
-- function Friend.PBGuildShopBuyItemReqCmd(req)
-- end

-- -- 购买推荐位
-- function Friend.PBGuildBuyRecommentReqCmd(req)
-- end

-- -- 设置头像
-- function Friend.PBGuildSetHeadReqCmd(req)
-- end

-- -------------------------------任务相关--------------------------
-- -- 接受任务
-- function Friend.PBGuildAcceptTaskReqCmd(req)
-- end

-- -- 领取任务奖励
-- function Friend.PBGuildGetTaskRewardReqCmd(req)
-- end

-- -- 公会日常任务奖励领取
-- function Friend.PBGuildDayMissionAwardReqCmd(req)
-- end

-- ---------------------------------GM命令-----------------------------
-- --GM命令更新公会背包数据
-- function Friend.PBGuildAddItems2BagCmd(req)
-- end

-- -- GM命令设置公会状态
-- function Friend.PBSetGuildStatusCmd(req)
-- end

-- -- GM命令开关捐赠
-- function Friend.PBOpenGuildJuanZengCmd(req)
-- end
 

-- return Friend