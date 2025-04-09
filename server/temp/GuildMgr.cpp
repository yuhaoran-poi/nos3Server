#include "GuildMgr.h"
#include "Guild.h"
#include "SqlMgr.h"
#include "util.h"
#include "xErrorCode.pb.h"
#include "stopword.h"
#include "GlobalConfigDataMgr.h"
#include "LobbyUserManager.h"

GuildMgr::GuildMgr()
{
	EntityMgr::RegisterGlobalEntity("GuildMgr", this);

	RegHandler<PBNotifyNewerMailboxReq>(std::bind(&GuildMgr::OnPBNotifyNewerMailboxReq, this, _1, _2));    //公会初创建成功通知

	RegHandler<PBGuildUpdateApplyList2GuildMgr>(std::bind(&GuildMgr::OnPBGuildUpdateApplyList2GuildMgr, this, _1, _2));   //更新公会的申请列表
	RegHandler<PBGuildUpdateSimpleInfo2GuildMgr>(std::bind(&GuildMgr::OnPBGuildUpdateSimpleInfo2GuildMgr, this, _1, _2));   //更新公会简略信息

	RegHandler<PBGuildGetGuildListReqCmd>(std::bind(&GuildMgr::OnPBGuildGetGuildListReqCmd, this, _1, _2));    //获取公会列表
	RegHandler<PBGuildCreateGuildReqCmd>(std::bind(&GuildMgr::OnPBGuildCreateGuildReqCmd, this, _1, _2));    //创建公会请求
	RegHandler<PBGuildApplyJoinGuildReqCmd>(std::bind(&GuildMgr::OnPBGuildApplyJoinGuildReqCmd, this, _1, _2));   //申请加入请求
	RegHandler<PBGuildAnswerApplyJoinGuildReqCmd>(std::bind(&GuildMgr::OnPBGuildAnswerApplyJoinGuildReqCmd, this, _1, _2));   //回复申请加入请求
	RegHandler<PBGuildSearchGuildReqCmd>(std::bind(&GuildMgr::OnPBGuildSearchGuildReqCmd, this, _1, _2));   //搜索公会

	RegHandler<PBGuildBoardcastPlayerJoin>(std::bind(&GuildMgr::OnPBGuildBoardcastPlayerJoin, this, _1, _2));   //玩家加入公会消息
	RegHandler<PBGuildBoardcastPlayerExit>(std::bind(&GuildMgr::OnPBGuildBoardcastPlayerExit, this, _1, _2));   //玩家退出公会消息
	RegHandler<PBGuildBoardcastGuildDismiss>(std::bind(&GuildMgr::OnPBGuildBoardcastGuildDismiss, this, _1, _2));   //公会解散消息
	RegHandler<PBLobbyGateSetNicknamReq>(std::bind(&GuildMgr::OnPBLobbyGateSetNicknamReq, this, _1, _2));   //玩家改名消息

	RegHandler<PBGuildModifyGuildNameReqCmd>(std::bind(&GuildMgr::OnPBGuildModifyGuildNameReqCmd, this, _1, _2));   //战队改名消息

	RegHandler<PBGuildInviteJoinGuildReqCmd>(std::bind(&GuildMgr::OnPBGuildInviteJoinGuildReqCmd, this, _1, _2));   //邀请加入公会
	RegHandler<PBGuildAnswerInviteJoinGuildReqCmd>(std::bind(&GuildMgr::OnPBGuildAnswerInviteJoinGuildReqCmd, this, _1, _2));   //回复邀请加入公会
	RegHandler<PBGuildAddItems2Bag>(std::bind(&GuildMgr::OnPBGuildAddItems2Bag, this, _1, _2));   //GM命令-增加/减小公会物品
	RegHandler<PBSetGuildStatus>(std::bind(&GuildMgr::OnPBSetGuildStatus, this, _1, _2));   //GM命令-修改公会状态
	RegHandler<PBOpenGuildJuanZeng>(std::bind(&GuildMgr::OnPBOpenGuildJuanZeng, this, _1, _2));   //GM命令-修改公会捐赠

	//RegHandler<PBGuildPlayerSetGuildInfoCmd>(std::bind(&GuildMgr::OnPBGuildPlayerSetGuildInfoCmd, this, _1, _2));   //设置GuildInfo
}

bool GuildMgr::OnInit()
{
	//return true;
	XLOG("GuildMgr::OnInit! ");
	m_InitDelay.SetDelay(60, [this]()
		{
			//查询公会数量
			SqlMgr::SelectCount("t_guild_data", "", [this](uint32_t count) {
				StartLoadGuilds(count);
				});
		});


	m_bInitSucc = false;
	return true;
}

//玩家申请公会
bool GuildMgr::PlayerAddApplyGuild(uint32_t guildId, uint32_t uid, uint32_t apply_time)
{
	auto pGuildInfo = GetGuild(guildId);
	if (!pGuildInfo)
		return false;

	auto& p = m_PlayerApplyMap[uid];
	auto& g = p.m_applyMap[guildId];
	g.set_guild_id(guildId);
	g.set_apply_time(apply_time);

	pGuildInfo->applyCount_++;
	return true;
}

//玩家取消申请公会
bool GuildMgr::PlayerDelApplyGuild(uint32_t guildId, uint32_t uid)
{
	auto pGuildInfo = GetGuild(guildId);
	if (!pGuildInfo)
		return false;

	auto& p = m_PlayerApplyMap[uid];
	auto iter = p.m_applyMap.find(guildId);
	if (iter == p.m_applyMap.end())
	{//该公会没有申请过，无法取消申请
		return false;
	}
	p.m_applyMap.erase(guildId);

	pGuildInfo->applyCount_--;
	return true;
}

tagGuildInfo* GuildMgr::GetGuild(uint32_t nGuildDbid)
{
	auto iter = m_GuildList.find(nGuildDbid);
	if (iter == m_GuildList.end() || iter->second.guidSimpleInfo_.status() < eGS_Normal)
	{
		//XERR("GuildMgr::GetGuild Failed! nGuildDbid:%d", nGuildDbid);
		return nullptr;
	}
	return &iter->second;
}

tagGuildInfo* GuildMgr::GetPlayerGuild(uint32_t nPlayerDbid)
{
	auto playerInfo = GetPlayerInfo(nPlayerDbid);
	if (!playerInfo)
	{
		//XERR("GuildMgr::GetPlayerGuild Failed! uid:%d", nPlayerDbid);
		return nullptr;
	}
	return GetGuild(playerInfo->m_guild_id);
}

GuildMgrPlayerInfo* GuildMgr::GetPlayerInfo(uint32_t nPlayerDbid)
{
	auto iter = m_PlayerList.find(nPlayerDbid);
	if (iter == m_PlayerList.end())
	{
		//XERR("GuildMgr::GetPlayerInfo Failed! uid:%d", nPlayerDbid);
		return nullptr;
	}
	return &iter->second;
}

bool GuildMgr::IsNameUsed(const string& name)
{
	return (m_GuildUsedName.find(name) != m_GuildUsedName.end());
}

void GuildMgr::PlayerJoinGuild(uint32_t guildId, uint32_t uid)
{
	auto pGuildInfo = GetGuild(guildId);
	if (!pGuildInfo)
		return;

	assert(uid > 0);
	//建立玩家和公会的关联
	auto& p = m_PlayerList[uid];
	p.m_nPlayerDbid = uid;
	p.m_guild_id = guildId;


	pGuildInfo->memberCount_++;
	//清理掉当前玩家所有公会邀请记录
	m_PlayerInviteMap.erase(uid);
}


void GuildMgr::PlayerExitGuild(uint32_t guildId, uint32_t uid)
{
	auto pGuildInfo = GetGuild(guildId);
	if (!pGuildInfo)
		return;

	//建立玩家和公会的关联
	auto& p = m_PlayerList[uid];
	p.m_nPlayerDbid = uid;
	p.m_guild_id = 0;

	pGuildInfo->memberCount_--;
}


bool GuildMgr::PlayerCanJoinGuild(uint32_t playerId, PBGuildSimpleInfo& sinfo)
{
	auto playerInfo = GetPlayerInfo(playerId);
	if (!playerInfo)
	{
		return false;
	}

	if (sinfo.has_join_con())
	{
		auto& con = sinfo.join_con();
		if (con.bcanjoin() == false)
		{
			return false;
		}

		//最低总星星
		auto& ghost_grade = playerInfo->m_baseData.rank_level().ghost_rank();
		auto& human_grade = playerInfo->m_baseData.rank_level().human_rank();

		int grade = con.minrank() >> 16;
		int level = con.minrank() & 0x0000FFFF;
		bool bCheckCon = false;
		do
		{
			if (ghost_grade.grade() > grade || (ghost_grade.grade() == grade && ghost_grade.level() >= level))
			{
				bCheckCon = true;
				break;
			}
			if (human_grade.grade() > grade || (human_grade.grade() == grade && human_grade.level() >= level))
			{
				bCheckCon = true;
				break;
			}
		} while (false);


		if (!bCheckCon)
		{

			return false;
		}

		//最低等级
		if (playerInfo->m_baseData.account_level() < con.minlevel())
		{
			return false;
		}


	}
	else
	{
		return true;
	}
	return false;
}

void GuildMgr::StartLoadGuilds(uint32_t count)
{
	static std::vector<dbCol> DBSelectGuildSqlCol = {
	{"id", DBDATA_TYPE_UInt64, sizeof(uint64_t)},
	{"data", DBDATA_TYPE_BIN2, 0},
	{"NULL", 0, 0},
	};
	//必须按1字节对齐
#pragma pack(1)
	struct SelectData_
	{
		uint64_t id;
		DBDataBin2 bin;
	}__attribute__((packed));
#pragma pack()



	m_nTotalGuildCount = count;
	XLOG("GuildMgr::StartLoadGuilds! guild count:%d", count);


	if (0 == count)
	{
		NotifyInitSucc();
		return;
	}

	enum { MAX_PAGE_COUNT = 1 };
	auto nMaxTimes = count / MAX_PAGE_COUNT + 1;

	for (int i = 0; i < nMaxTimes; ++i)
	{
		char tempWhere[128];
		sprintf(tempWhere, " 1 limit %d,%d", i * MAX_PAGE_COUNT, MAX_PAGE_COUNT);
		XLOG("GuildMgr::StartLoadGuilds!! where:%s", tempWhere);
		SqlMgr::Select("t_guild_data", DBSelectGuildSqlCol, tempWhere, [this, tempWhere](SeleteBuffer& data)
			{
				XLOG("GuildMgr::StartLoadGuilds rsp!! where:%s", tempWhere);
				data.Foreach<SelectData_>(true, [this](SelectData_& tBuffer)
					{

						PBGuildInfo guildInfo;
						if (guildInfo.ParseFromArray(tBuffer.bin.data, tBuffer.bin.size))
						{

							guildInfo.set_guildid(tBuffer.id);
							guildInfo.set_member_count(guildInfo.user_list_size());

							CreateGuildAnyWhere(guildInfo);
						}
						else
						{
							XLOG("GuildMgr::StartLoadGuilds! err guild id:%d", tBuffer.id);
						}

					});
			});

		Sleep(5);
	}

}

void GuildMgr::CreateGuildAnyWhere(const PBGuildInfo& guildInfo)
{
	XLOG("GuildMgr::CreateGuildAnyWhere! guild_id:%llu", guildInfo.guildid());
	m_GuildUsedName[guildInfo.name()] = 1;

	//更新
	auto& t_guildInfo = m_GuildList[guildInfo.guildid()];
	t_guildInfo.guildId_ = guildInfo.guildid();
	Util::GetSimpleGuildData(guildInfo, &t_guildInfo.guidSimpleInfo_);
	if (t_guildInfo.guidSimpleInfo_.status() < eGS_Normal)
	{
		m_nTotalGuildCount--;
		XLOG("GuildMgr::StartLoadGuilds! status=%d guild id:%d", t_guildInfo.guidSimpleInfo_.status(), t_guildInfo.guildId_);
		return;
	}

	//存入缓存
	m_cacheGuidInfo[guildInfo.guildid()] = guildInfo;
	m_lastLoadGuildTime = time(nullptr);

	//初始化公会申请列表
	auto& apply_list = guildInfo.apply_list();
	for (int i = 0; i < apply_list.apply_list_size(); i++)
	{
		auto& apply_data = apply_list.apply_list(i);
		auto applyer_uid = apply_data.playersimpleinfo().uid();
		PlayerAddApplyGuild(guildInfo.guildid(), applyer_uid, apply_data.apply_time());
	}

	//初始化玩家列表
	for (int i = 0; i < guildInfo.user_list_size(); i++)
	{
		auto& user_data = guildInfo.user_list(i);
		PlayerJoinGuild(guildInfo.guildid(), user_data.uid());
	}

	EntityMgr::CreateEntityAnyWhereWithData("Guild", &guildInfo);
	//发送GuildInfo to DataBase
	SendGuildInfoToDB(guildInfo, 0);

	m_CheckLoadGuild.SetDelay(20, [this]()
		{
			if (m_cacheGuidInfo.size() > 0 && time(nullptr) - m_lastLoadGuildTime > 10)
			{
				for (auto info : m_cacheGuidInfo)
				{
					EntityMgr::CreateEntityAnyWhereWithData("Guild", &info.second);
				}
			}
		});
}

//发送提示文字接口
void GuildMgr::SendShowTextId(const EntityMailBox& mb, uint32_t nTextId, const std::vector<string>& params)
{
	PBShowTextID showTextMsg;
	showTextMsg.set_ntextid(nTextId);
	for (auto& str : params)
		showTextMsg.add_params(str);
	SendToClientEntity(mb, showTextMsg);
}
//发送提示文字接口
void GuildMgr::SendShowTextId(const EntityMailBox& mb, uint32_t nTextId)
{
	PBShowTextID showTextMsg;
	showTextMsg.set_ntextid(nTextId);
	SendToClientEntity(mb, showTextMsg);
}

//公会初始化成功通知
bool GuildMgr::OnPBNotifyNewerMailboxReq(EntityMailBox& sender_mb, ::google::protobuf::Message* pMsg)
{
	PBNotifyNewerMailboxReq* pCmd = (PBNotifyNewerMailboxReq*)pMsg;
	uint64_t guidId = pCmd->reserved1();
	XLOG("GuildMgr::OnPBNotifyNewerMailboxReq! guid_id:%llu", guidId);

	auto& t_guildInfo = m_GuildList[guidId];
	t_guildInfo.mb_ = sender_mb;
	m_cacheGuidInfo.erase(guidId);
	auto masterPlayerInfo = GetPlayerInfo(t_guildInfo.guidSimpleInfo_.president_id());
	if (masterPlayerInfo && masterPlayerInfo->mb.IsOk())
	{//如果会长在线，发送会长在线信息（这种情况表示新建公会）
		PBLobbyGateUserOnlineReq online;
		online.set_uid(masterPlayerInfo->m_baseData.uid());
		masterPlayerInfo->mb.CopyTo(online.mutable_mailbox());
		*online.mutable_base_data() = masterPlayerInfo->m_baseData;
		SendToEntity(sender_mb, online);
	}

	if (!m_bInitSucc)
	{//表示服务器启动时的统计
		//记录已加载列表
		m_GuildLoadSuccList[guidId] = guidId;
		XLOG("GuildMgr::OnPBNotifyNewerMailboxReq 23! guid_id:%llu! cur_count:%d,need_count:%d", guidId, m_GuildLoadSuccList.size(), m_nTotalGuildCount);
		if (m_GuildLoadSuccList.size() == m_nTotalGuildCount)
		{//初始化成功
			NotifyInitSucc();
		}
	}

	return true;
}


bool GuildMgr::OnPlayerOnline(EntityMailBox& sender_mb, PBLobbyGateUserOnlineReq* pCmd)
{
	auto& playerInfo = m_PlayerList[pCmd->uid()];
	playerInfo.m_nPlayerDbid = pCmd->uid();
	playerInfo.mb = sender_mb;
	playerInfo.m_baseData = pCmd->base_data();
	// if(pCmd->base_data().guild_uid()!=0)
	// playerInfo.m_guild_id = pCmd->base_data().guild_uid();

	XLOG("GuildMgr::OnPlayerOnline! uid:%d,guild_id:%llu! total_player_count:%d, total_guild:%d", pCmd->uid(), playerInfo.m_guild_id, m_PlayerList.size(), m_GuildList.size());

	auto pGuildInfo = GetPlayerGuild(pCmd->uid());
	if (!pGuildInfo || pGuildInfo->guidSimpleInfo_.status() == eGS_Destory)
	{//玩家没有公会
		XERR("GuildMgr::OnPlayerOnline! No Guild! uid:%d,guild_id:%llu", pCmd->uid(), playerInfo.m_guild_id);
		//申请列表
		UpdatePlayerApplyInfoToClient(pCmd->uid());
		//邀请列表
		UpdatePlayerInviteInfoToClient(pCmd->uid());
		//同步gate清除公会数据
		playerInfo.m_guild_id = 0;
		//设置公会的mb关联
		PBGuildPlayerSetGuildInfoCmd guildMsg;
		guildMsg.set_guild_id(0);
		guildMsg.set_guild_name("");
		guildMsg.set_guild_level(0);
		guildMsg.set_guild_prosperity(0);
		guildMsg.mutable_mb()->set_entity_id(0);
		guildMsg.mutable_mb()->set_server_id(0);
		SendToEntity(playerInfo.mb, guildMsg);

		return true;
	}

	XLOG("GuildMgr::OnPlayerOnline!Send to Guild! uid:%d,guild_id:%llu! total_player_count:%d, total_guild:%d", pCmd->uid(), playerInfo.m_guild_id, m_PlayerList.size(), m_GuildList.size());

	//转发给公会
	SendToEntity(pGuildInfo->mb_, *pCmd);
	return true;
}

bool GuildMgr::OnPlayerOffline(EntityMailBox& sender_mb, PBLobbyGateUserOfflineReq* pCmd)
{
	auto uid = pCmd->uid();
	XLOG("GuildMgr::OnPlayerOffline! uid:%d", uid);

	auto pGuildInfo = GetPlayerGuild(uid);
	if (pGuildInfo)
	{//转发给公会
		SendToEntity(pGuildInfo->mb_, *pCmd);
	}

	auto playerInfo = GetPlayerInfo(uid);
	if (playerInfo)
	{//清理玩家数据
		playerInfo->m_baseData.Clear();
		playerInfo->mb.Clear();
	}

	return true;
}

PlayerApplyInfo* GuildMgr::GetPlayerApplyInfo(uint32_t uid)
{
	auto iter = m_PlayerApplyMap.find(uid);
	if (iter == m_PlayerApplyMap.end())
		return nullptr;
	return &iter->second;
}


bool GuildMgr::OnPBGuildGetGuildListReqCmd(EntityMailBox& sender_mb, ::google::protobuf::Message* pMsg)
{
	PBGuildGetGuildListReqCmd* pCmd = (PBGuildGetGuildListReqCmd*)pMsg;
	uint32_t minLevel = pCmd->has_min_level() ? pCmd->min_level() : 0;
	uint32_t maxLevel = pCmd->has_max_level() ? pCmd->max_level() : 999;
	uint32_t minMember = pCmd->has_min_member_count() ? pCmd->min_member_count() : 0;
	uint32_t maxMember = pCmd->has_max_member_count() ? pCmd->max_member_count() : 999;

	uint32_t page_count = pCmd->pagecount();
	if (page_count <= 0 || page_count > 50)
		page_count = 50;

	auto nIdx = pCmd->idx();

	auto nStartIndex = page_count * nIdx;
	auto nEndIndex = page_count * (nIdx + 1);

std:; vector<PBGuildSimpleInfo*> vecRecord;
	int nTotal = m_GuildList.size();
	vecRecord.reserve(nTotal);
	auto now = time(0);

	for (auto& v : m_GuildList)
	{
		auto& sinfo = v.second.guidSimpleInfo_;
		if (eGS_Destory == sinfo.status())
			continue;

		if (sinfo.level() < minLevel || sinfo.level() > maxLevel ||
			sinfo.member_count() < minMember || sinfo.member_count() > maxMember)
			continue;
		//推荐公会过滤
		if (pCmd->brecomment() && now > sinfo.recommend_endtime())
			continue;
		//加入条件过滤
		if (pCmd->bjoin_con())
		{
			if (!PlayerCanJoinGuild(pCmd->uid(), sinfo))
				continue;
		}
		vecRecord.push_back(&v.second.guidSimpleInfo_);
	}
	//排序

	if (pCmd->b_asc())
	{
		//1,战队ID，2国籍，3战队名，4战队等级，5战队赛季积分，6活跃度，7战队人数
		if (pCmd->sort_type() == 1)
		{
			std::sort(vecRecord.begin(), vecRecord.end(), [&](PBGuildSimpleInfo* lhs, PBGuildSimpleInfo* rhs) {return lhs->guildid() > rhs->guildid(); });
		}
		else if (pCmd->sort_type() == 3)
		{
			std::sort(vecRecord.begin(), vecRecord.end(), [&](PBGuildSimpleInfo* lhs, PBGuildSimpleInfo* rhs) {return lhs->name() > rhs->name(); });
		}
		else if (pCmd->sort_type() == 4)
		{
			std::sort(vecRecord.begin(), vecRecord.end(), [&](PBGuildSimpleInfo* lhs, PBGuildSimpleInfo* rhs) {return lhs->level() > rhs->level(); });
		}
		else if (pCmd->sort_type() == 6)
		{
			std::sort(vecRecord.begin(), vecRecord.end(), [&](PBGuildSimpleInfo* lhs, PBGuildSimpleInfo* rhs) {return lhs->activeness() > rhs->activeness(); });
		}
		else if (pCmd->sort_type() == 7)
		{
			std::sort(vecRecord.begin(), vecRecord.end(), [&](PBGuildSimpleInfo* lhs, PBGuildSimpleInfo* rhs) {return lhs->member_count() > rhs->member_count(); });
		}
	}
	else
	{
		if (pCmd->sort_type() == 1)
		{
			std::sort(vecRecord.begin(), vecRecord.end(), [&](PBGuildSimpleInfo* lhs, PBGuildSimpleInfo* rhs) {return lhs->guildid() < rhs->guildid(); });
		}
		else if (pCmd->sort_type() == 2)
		{
			std::sort(vecRecord.begin(), vecRecord.end(), [&](PBGuildSimpleInfo* lhs, PBGuildSimpleInfo* rhs) {return lhs->name() < rhs->name(); });
		}
		else if (pCmd->sort_type() == 4)
		{
			std::sort(vecRecord.begin(), vecRecord.end(), [&](PBGuildSimpleInfo* lhs, PBGuildSimpleInfo* rhs) {return lhs->level() < rhs->level(); });
		}
		else if (pCmd->sort_type() == 6)
		{
			std::sort(vecRecord.begin(), vecRecord.end(), [&](PBGuildSimpleInfo* lhs, PBGuildSimpleInfo* rhs) {return lhs->activeness() < rhs->activeness(); });
		}
		else if (pCmd->sort_type() == 7)
		{
			std::sort(vecRecord.begin(), vecRecord.end(), [&](PBGuildSimpleInfo* lhs, PBGuildSimpleInfo* rhs) {return lhs->member_count() < rhs->member_count(); });
		}
	}

	PBGuildGetGuildListRspCmd rspMsg;
	rspMsg.set_sort_type(pCmd->sort_type());
	rspMsg.set_b_asc(pCmd->b_asc());
	rspMsg.set_min_level(pCmd->min_level());
	rspMsg.set_max_level(pCmd->max_level());
	rspMsg.set_min_member_count(pCmd->min_member_count());
	rspMsg.set_max_member_count(pCmd->max_member_count());
	rspMsg.set_max_count(vecRecord.size());
	rspMsg.set_pagecount(page_count);
	rspMsg.set_brecomment(pCmd->brecomment());
	rspMsg.set_bjoin_con(pCmd->bjoin_con());
	int i = 0;
	for (auto& v : vecRecord)
	{
		if (i >= nEndIndex)
		{
			break;
		}

		if (i >= nStartIndex)
		{
			*rspMsg.mutable_guildlist()->add_guildlist() = *v; //= *v;
		}
		++i;
	}
	XLOG("GuildMgr::OnPBGuildGetGuildListReqCmd! uid:%d,guild_max_size:%d,cur_get_size:%d", pCmd->uid(), m_GuildList.size(), i);
	//发送给玩家
	SendToClientEntity(sender_mb, rspMsg);
	return true;
}

bool GuildMgr::OnPBGuildCreateGuildReqCmd(EntityMailBox& sender_mb, ::google::protobuf::Message* pMsg)
{
	PBGuildCreateGuildReqCmd* pCmd = (PBGuildCreateGuildReqCmd*)pMsg;
	XLOG("GuildMgr::PBGuildCreateGuildReqCmd! uid:%d", pCmd->uid());

	auto uid = pCmd->uid();
	std::string sGuildName = pCmd->name();
	auto playerInfo = GetPlayerInfo(uid);
	if (!playerInfo)
	{
		return true;
	}

	auto pGuildMb = GetPlayerGuild(uid);
	if (pGuildMb)
	{//玩家已有公会
		SendShowTextId(sender_mb, ERR_GUILD_U_HAD_GUILD_CANNOT_CREATE);
		return true;
	}

	//剔除两边的空格
//    sGuildName = Util::Trim(sGuildName);

	//只是3个字符
	if (sGuildName.size() <= 3 || sGuildName.size() > 20)
	{
		SendShowTextId(sender_mb, ERR_FRIEND_NICKNAME_STR_ERROR_ERROR);
		return true;
	}

	auto& globalConfig = GlobalConfigDataMgr::getMe().GetConfig();
	auto& m_CreateGuildConsume = globalConfig.m_CreateGuildConsume;
	if (m_CreateGuildConsume.empty()) {
		SendShowTextId(sender_mb, ERR_FRIEND_PARAM_ERROR);
		return true;
	}

	if (CStopWord::getMe().IsStopWord(sGuildName))
	{
		SendShowTextId(sender_mb, ERR_CANNOT_USE_STOP_WORD);
		return true;
	}

	if (IsNameUsed(sGuildName))
	{//名称已被使用
		SendShowTextId(sender_mb, ERR_GUILD_GUILD_NAME_HAD_USED);
		return true;
	}

	m_GuildUsedName[sGuildName] = 1;

	auto& playerBaseData = playerInfo->m_baseData;

	PBGuildInfo guildInfo;
	guildInfo.set_guildid(0);        //先占位
	guildInfo.set_name(sGuildName);
	guildInfo.set_level(1);
	guildInfo.set_president_id(uid);
	guildInfo.set_president_name(playerBaseData.nick_name());
	guildInfo.set_build_time(time(0));
	guildInfo.set_status(eGS_Normal);

	auto pUserData = guildInfo.add_user_list();
	Util::GetSimpleBaseData(playerBaseData, pUserData->mutable_playersimpleinfo());
	pUserData->set_uid(uid);
	pUserData->mutable_guild_data()->set_playerdutyid(1);
	pUserData->mutable_guild_data()->set_uid(uid);

	SqlMgr::Insert("t_guild_data", guildInfo,
		[guildInfo, this, uid](uint64_t guild_id) mutable
		{
			auto playerInfo = GetPlayerInfo(uid);

			if (0 == guild_id)
			{//Insert失败了
				m_GuildUsedName.erase(guildInfo.name());
				XERR("GuildMgr::Create Guild Failed! guid_name:%s", guildInfo.name().c_str());

				if (playerInfo)
				{
					SendShowTextId(playerInfo->mb, ERR_GUILD_DB_ERROR_CANNOT_CREATE);
				}
				return;
			}
			guildInfo.set_guildid(guild_id);
			guildInfo.set_member_count(guildInfo.user_list_size());
			CreateGuildAnyWhere(guildInfo);

			if (playerInfo)
			{
				PBGuildCreateGuildRspCmd rspMsg;
				rspMsg.set_name(guildInfo.name().c_str());
				SendToEntity(playerInfo->mb, rspMsg);
			}
		});

	return true;
}

bool GuildMgr::OnPBGuildSearchGuildReqCmd(EntityMailBox& sender_mb, ::google::protobuf::Message* pMsg)
{
	PBGuildSearchGuildReqCmd* pCmd = (PBGuildSearchGuildReqCmd*)pMsg;
	XLOG("GuildMgr::PBGuildSearchGuildReqCmd! uid:%d", pCmd->uid());

	auto& sKey = pCmd->key();
	uint32_t guildId = 0;
	if (Util::IsNum(sKey))
	{
		guildId = atoi(sKey.c_str());
	}

	tagGuildInfo* pGuildInfo = nullptr;
	for (auto& v : m_GuildList)
	{
		auto& guildInfo = v.second.guidSimpleInfo_;
		if (guildInfo.name() == sKey)
		{
			pGuildInfo = &v.second;
			break;
		}
		else if (guildId > 0 && guildId == guildInfo.guildid())
		{
			pGuildInfo = &v.second;
			break;
		}
	}

	PBGuildSearchGuildRspCmd rspMsg;
	if (pGuildInfo && pGuildInfo->guidSimpleInfo_.status() >= eGS_Normal)
	{

		*rspMsg.mutable_guid_info() = pGuildInfo->guidSimpleInfo_;
	}

	SendToClientEntity(sender_mb, rspMsg);
	return true;
}

bool GuildMgr::OnPBGuildBoardcastPlayerJoin(EntityMailBox& sender_mb, ::google::protobuf::Message* pMsg)
{
	PBGuildBoardcastPlayerJoin* pCmd = (PBGuildBoardcastPlayerJoin*)pMsg;

	auto uid = pCmd->user_info().uid();
	auto guildId = pCmd->guild_id();
	XLOG("GuildMgr::OnPBGuildBoardcastPlayerJoin! uid:%d, guild_id=%d", uid, guildId);

	//建立玩家和公会的关联
	PlayerJoinGuild(guildId, uid);
	return true;
}

bool GuildMgr::OnPBGuildBoardcastPlayerExit(EntityMailBox& sender_mb, ::google::protobuf::Message* pMsg)
{
	PBGuildBoardcastPlayerExit* pCmd = (PBGuildBoardcastPlayerExit*)pMsg;
	auto uid = pCmd->uid();
	auto guildId = pCmd->guild_id();
	XLOG("GuildMgr::OnPBGuildBoardcastPlayerExit! uid:%d, guild_id=%d", uid, guildId);

	//清空玩家和公会的关联
	PlayerExitGuild(guildId, uid);
	return true;
}

bool GuildMgr::OnPBGuildBoardcastGuildDismiss(EntityMailBox& sender_mb, ::google::protobuf::Message* pMsg)
{
	PBGuildBoardcastGuildDismiss* pCmd = (PBGuildBoardcastGuildDismiss*)pMsg;
	auto guildId = pCmd->guild_id();
	XLOG("GuildMgr::OnPBGuildBoardcastGuildDismiss! guild_id=%d", guildId);

	//清空玩家和公会的关联
	auto pGuildInfo = GetGuild(guildId);
	if (!pGuildInfo)
		return true;
	for (auto& v : m_PlayerList)
	{

		if (v.second.m_guild_id == guildId)
		{
			v.second.m_guild_id = 0;
			pGuildInfo->memberCount_--;
			if (pGuildInfo->memberCount_ < 0)
				pGuildInfo->memberCount_ = 0;
		}
	}

	//PBGuildInfo guild_info;
	//guild_info.set_guildid(pGuildInfo->guildId_);
	//SendGuildInfoToDB(guild_info, 1);
	return true;
}

bool GuildMgr::OnPBLobbyGateSetNicknamReq(EntityMailBox& sender_mb, ::google::protobuf::Message* pMsg)
{
	PBLobbyGateSetNicknamReq* pCmd = (PBLobbyGateSetNicknamReq*)pMsg;
	XLOG("GuildMgr::OnPBLobbyGateSetNicknamReq! uid:%d", pCmd->uid());

	auto pGuildInfo = GetPlayerGuild(pCmd->uid());
	if (!pGuildInfo)
	{//玩家没有公会
		return true;
	}

	SendToEntity(pGuildInfo->mb_, *pCmd);
	return true;
}

bool GuildMgr::OnPBGuildModifyGuildNameReqCmd(EntityMailBox& sender_mb, ::google::protobuf::Message* pMsg)
{
	PBGuildModifyGuildNameReqCmd* pCmd = (PBGuildModifyGuildNameReqCmd*)pMsg;
	XLOG("GuildMgr::OnPBGuildModifyGuildNameReqCmd! uid:%d", pCmd->uid());

	auto pGuildInfo = GetPlayerGuild(pCmd->uid());
	if (!pGuildInfo)
	{//玩家没有公会
		return true;
	}
	auto playerInfo = GetPlayerInfo(pCmd->uid());
	if (!playerInfo)
	{
		return true;
	}
	auto& sGuildName = pCmd->newname();

	//只是3个字符
	if (sGuildName.size() <= 3 || sGuildName.size() > 20)
	{
		SendShowTextId(playerInfo->mb, ERR_FRIEND_NICKNAME_STR_ERROR_ERROR);
		return true;
	}

	if (CStopWord::getMe().IsStopWord(sGuildName))
	{
		SendShowTextId(playerInfo->mb, ERR_CANNOT_USE_STOP_WORD);
		return true;
	}

	if (IsNameUsed(sGuildName))
	{//名称已被使用
		SendShowTextId(playerInfo->mb, ERR_GUILD_GUILD_NAME_HAD_USED);
		return true;
	}

	m_GuildUsedName[sGuildName] = 1;

	//通知Guild改名成功
	PBGuildModifyGuildNameRspCmd rspMsg;
	rspMsg.set_uid(pCmd->uid());
	rspMsg.set_newname(sGuildName);
	SendToEntity(pGuildInfo->mb_, rspMsg);
	return true;
}

bool GuildMgr::OnPBGuildInviteJoinGuildReqCmd(EntityMailBox& sender_mb, ::google::protobuf::Message* pMsg)
{
	PBGuildInviteJoinGuildReqCmd* pCmd = (PBGuildInviteJoinGuildReqCmd*)pMsg;
	auto uid = pCmd->uid();
	auto be_invite_uid = pCmd->be_invite_uid();

	XLOG("GuildMgr::OnPBGuildInviteJoinGuildReqCmd! uid:%d,applyer_uid:%d", uid, be_invite_uid);
	auto pPlayerInfo = GetPlayerInfo(uid);
	if (!pPlayerInfo)
	{
		SendShowTextId(sender_mb, ERR_GUILD_U_NOT_FIND_INFO);
		return true;
	}

	auto pPlayerGuildInfo = GetGuild(pPlayerInfo->m_guild_id);
	if (!pPlayerGuildInfo)
	{//您没有战队
		SendShowTextId(pPlayerInfo->mb, ERR_GUILD_U_NOT_HAVE_GUILD);
		return true;
	}
	auto pInviteGuildInfo = GetPlayerGuild(be_invite_uid);
	if (pInviteGuildInfo)
	{////对方已有战队
		SendShowTextId(pPlayerInfo->mb, ERR_GUILD_PEER_HAD_GUILD);
		return true;
	}

	//添加一个邀请记录
	PBGuildInviteRecordInfo info;
	info.set_inviteplayerid(uid);
	info.set_inviteplayername(pPlayerInfo->m_baseData.nick_name());
	*info.mutable_inviteguildsinfo() = pPlayerGuildInfo->guidSimpleInfo_;

	auto& p = m_PlayerInviteMap[be_invite_uid];
	p.m_inviteMap[uid] = info;

	//通知被邀请人
	UpdatePlayerInviteInfoToClient(be_invite_uid);
	//通知邀请人消息发送成功
	PBGuildInviteJoinGuildRspCmd retmsg;
	retmsg.set_invited_uid(be_invite_uid);
	SendToClientEntity(pPlayerInfo->mb, retmsg);
	return true;
}

bool GuildMgr::OnPBGuildAnswerInviteJoinGuildReqCmd(EntityMailBox& sender_mb, ::google::protobuf::Message* pMsg)
{
	PBGuildAnswerInviteJoinGuildReqCmd* pCmd = (PBGuildAnswerInviteJoinGuildReqCmd*)pMsg;

	auto uid = pCmd->uid();
	auto inviter_uid = pCmd->inviter_uid();
	XLOG("GuildMgr::OnPBGuildAnswerInviteJoinGuildReqCmd! uid:%d,applyer_uid:%d", uid, inviter_uid);
	//判断当前是否有邀请记录，没有直接返回
	auto& p = m_PlayerInviteMap[uid];
	auto iter = p.m_inviteMap.find(inviter_uid);
	if (iter == p.m_inviteMap.end())
	{
		return true;
	}
	// 删除本条邀请记录
	p.m_inviteMap.erase(inviter_uid);
	UpdatePlayerInviteInfoToClient(uid);

	auto pPlayerGuildInfo = GetPlayerGuild(uid);
	if (pPlayerGuildInfo)
	{//您已经有战队
		SendShowTextId(sender_mb, ERR_GUILD_U_ALREADY_HAD_GUILD);
		return true;
	}
	auto pInviterGuildInfo = GetPlayerGuild(inviter_uid);
	if (!pInviterGuildInfo)
	{//目标战队没找到
		SendShowTextId(sender_mb, ERR_GUILD_TARGET_GUILD_NOT_FIND);
		return true;
	}
	if (pCmd->b_agree())
	{//同意时 转发给所在公会
		SendToEntity(pInviterGuildInfo->mb_, *pCmd);
	}
	return true;
}

bool GuildMgr::OnPBGuildApplyJoinGuildReqCmd(EntityMailBox& sender_mb, ::google::protobuf::Message* pMsg)
{
	PBGuildApplyJoinGuildReqCmd* pCmd = (PBGuildApplyJoinGuildReqCmd*)pMsg;

	auto uid = pCmd->uid();
	auto guildid = pCmd->guildid();

	XLOG("GuildMgr::PBGuildApplyJoinGuildReqCmd! uid:%d, guild_id:%llu", uid, guildid);

	auto pPlayerGuildInfo = GetPlayerGuild(uid);
	if (pPlayerGuildInfo)
	{//玩家已有公会，不能在申请
		XERR("GuildMgr::PBGuildApplyJoinGuildReqCmd! had in guild! uid:%d, guild_id:%llu", uid, guildid);
		SendShowTextId(sender_mb, ERR_GUILD_U_ALREADY_HAD_GUILD);
		return true;
	}

	auto pPlayerInfo = GetPlayerInfo(uid);
	if (!pPlayerInfo)
	{
		SendShowTextId(sender_mb, ERR_GUILD_U_NOT_FIND_INFO);
		return true;
	}

	auto pGuildInfo = GetGuild(guildid);
	if (!pGuildInfo)
	{
		SendShowTextId(sender_mb, ERR_GUILD_TARGET_GUILD_NOT_FIND);
		XERR("GuildMgr::PBGuildApplyJoinGuildReqCmd! No guild! uid:%d, guild_id:%llu", uid, guildid);
		return true;
	}

	auto& applyMap = m_PlayerApplyMap[uid].m_applyMap;

	if (pCmd->b_apply())
	{//申请加入公会
		if (applyMap.size() >= 3)
		{//申请名额已满
			SendShowTextId(sender_mb, ERR_GUILD_U_APPLY_FULL);
			return  true;
		}
		auto iter = applyMap.find(guildid);
		if (iter != applyMap.end())
		{//该公会已申请过，无法重复申请
			SendShowTextId(sender_mb, ERR_GUILD_U_HAD_APPLY_GUILD);
			return true;
		}

		if (pGuildInfo->applyCount_ > 100)
		{//最多存储100个申请
			SendShowTextId(sender_mb, ERR_GUILD_TARGET_GUILD_APPLY_FULL);
			return true;
		}

	}
	else
	{//取消申请
		auto iter = applyMap.find(guildid);
		if (iter == applyMap.end())
		{//该公会未申请过，无法取消申请
			SendShowTextId(sender_mb, ERR_GUILD_NOT_APPLY_GUILD);
			return true;
		}
	}

	//转发给所在公会
	sender_mb.CopyTo(pCmd->mutable_applyer_mb());
	SendToEntity(pGuildInfo->mb_, *pCmd);
	return true;
}

bool GuildMgr::OnPBGuildAnswerApplyJoinGuildReqCmd(EntityMailBox& sender_mb, ::google::protobuf::Message* pMsg)
{
	PBGuildAnswerApplyJoinGuildReqCmd* pCmd = (PBGuildAnswerApplyJoinGuildReqCmd*)pMsg;

	auto uid = pCmd->uid();
	auto applyer_uid = pCmd->applyer_uid();
	XLOG("GuildMgr::OnPBGuildAnswerApplyJoinGuildReqCmd! uid:%d,applyer_uid:%d", uid, applyer_uid);

	auto pPlayerGuildInfo = GetPlayerGuild(uid);
	if (!pPlayerGuildInfo)
	{//您没有战队
		SendShowTextId(sender_mb, ERR_GUILD_U_NOT_HAVE_GUILD);
		return true;
	}

	if (pCmd->b_agree())
	{//同意时，需要判断对方是否已有公会
		auto pApplyGuildInfo = GetPlayerGuild(applyer_uid);
		if (pApplyGuildInfo)
		{////对方已有战队
			SendShowTextId(sender_mb, ERR_GUILD_PEER_HAD_GUILD);
			pCmd->set_b_agree(false);
			//return true;
		}
	}

	//转发给所在公会
	SendToEntity(pPlayerGuildInfo->mb_, *pCmd);
	return true;
}

bool GuildMgr::UpdatePlayerApplyInfoToClient(uint32_t uid)
{
	auto playerInfo = GetPlayerInfo(uid);
	if (playerInfo)
	{   //更新玩家的申请信息
		auto& p = m_PlayerApplyMap[uid];
		//刷新玩家的申请列表
		PBGuildUpdateMeApplyGuildList meApplyList;
		for (auto& v : p.m_applyMap)
			*meApplyList.mutable_me_apply_list()->add_applylist() = v.second;
		SendToClientEntity(playerInfo->mb, meApplyList);
		XLOG("UpdatePlayerApplyInfoToClient! uid:%d,me_apply_count:%d", uid, p.m_applyMap.size());
	}
	return true;
}

bool GuildMgr::OnPBGuildUpdateApplyList2GuildMgr(EntityMailBox& sender_mb, ::google::protobuf::Message* pMsg)
{
	PBGuildUpdateApplyList2GuildMgr* pCmd = (PBGuildUpdateApplyList2GuildMgr*)pMsg;

	auto& apply_info = pCmd->apply_info();
	auto uid = pCmd->uid();
	auto guild_id = apply_info.guild_id();
	XLOG("GuildMgr::OnPBGuildAnswerApplyJoinGuildReqCmd! uid:%d", uid);

	auto pGuildInfo = GetGuild(guild_id);
	if (!pGuildInfo)
	{
		XERR("GuildMgr::OnPBGuildUpdateApplyList2GuildMgr! No guild! uid:%d", uid, guild_id);
		return true;
	}

	//更新公会的申请信息
	if (AO_ADD == pCmd->opt())
	{
		PlayerAddApplyGuild(guild_id, uid, apply_info.apply_time());
	}
	else
	{
		PlayerDelApplyGuild(guild_id, uid);
	}

	UpdatePlayerApplyInfoToClient(uid);
	return true;
}

bool GuildMgr::UpdatePlayerInviteInfoToClient(uint32_t uid)
{
	auto playerInfo = GetPlayerInfo(uid);
	if (playerInfo)
	{   //更新玩家的申请信息
		auto& p = m_PlayerInviteMap[uid];
		//刷新玩家的申请列表
		PBGuildUpdateMeInviteGuildList meInviteList;
		for (auto& v : p.m_inviteMap)
		{
			*meInviteList.mutable_me_invite_list()->add_invites() = v.second;
		}

		SendToClientEntity(playerInfo->mb, meInviteList);
		XLOG("UpdatePlayerApplyInfoToClient! uid:%d,me_apply_count:%d", uid, p.m_inviteMap.size());
	}
	return true;
}

bool GuildMgr::OnPBUpdatePlayerInviteInfoTo2GuildMgr(EntityMailBox& sender_mb, ::google::protobuf::Message* pMsg)
{
	PBGuildUpdateInviteList2GuildMgr* pCmd = (PBGuildUpdateInviteList2GuildMgr*)pMsg;

	auto& invite_info = pCmd->invite_info();
	auto be_uid = pCmd->be_invite_uid();
	//更新玩家的邀请信息
	auto& p = m_PlayerInviteMap[be_uid];
	if (p.m_inviteMap.size() > 9)
	{
		//todo 自动拒绝邀请,看是否给邀请人反馈消息
		return true;
	}
	p.m_inviteMap[invite_info.inviteplayerid()] = invite_info;


	UpdatePlayerInviteInfoToClient(be_uid);
	return true;
}

bool GuildMgr::OnPBGuildUpdateSimpleInfo2GuildMgr(EntityMailBox& sender_mb, ::google::protobuf::Message* pMsg)
{
	PBGuildUpdateSimpleInfo2GuildMgr* pCmd = (PBGuildUpdateSimpleInfo2GuildMgr*)pMsg;

	auto guild_id = pCmd->simple_info().guildid();
	XLOG("GuildMgr::OnPBGuildUpdateSimpleInfo2GuildMgr! guild_id:%d", guild_id);
	auto pGuildInfo = GetGuild(guild_id);
	if (!pGuildInfo)
	{
		XERR("GuildMgr::OnPBGuildUpdateSimpleInfo2GuildMgr!not find guild! guild_id:%d", guild_id);
		return true;
	}
	pGuildInfo->guidSimpleInfo_ = pCmd->simple_info();

	return true;
}

void GuildMgr::SendGuildInfoToDB(const PBGuildInfo& guildInfo, UInt32 create_or_dismiss)
{
	PBSendGuildInfoToDBCmd sendMsg;
	*sendMsg.mutable_guildinfo() = guildInfo;
	sendMsg.set_create_or_dismiss(create_or_dismiss);
	SGUID_UINT32 tempSGUID;
	tempSGUID.setSid(SERVER_SID_DATE_RECORD);
	tempSGUID.setGid(1);
	tempSGUID.setNid(0);
	xServerDispatcher::SendToOtherServer(tempSGUID.getSGUID(), sendMsg);
}

//GM命令-公会增加/删除公会背包物品
bool GuildMgr::OnPBGuildAddItems2Bag(EntityMailBox& sender_mb, ::google::protobuf::Message* pMsg) {
	PBGuildAddItems2Bag* pCmd = (PBGuildAddItems2Bag*)pMsg;

	auto guild_id = pCmd->guildid();
	XLOG("GuildMgr::OnPBGuildAddItems2Bag GM! guild_id:%d", guild_id);
	auto pGuildInfo = GetGuild(guild_id);
	if (!pGuildInfo)
	{
		XERR("GuildMgr::OnPBGuildAddItems2Bag GM!not find guild! guild_id:%d", guild_id);
		return true;
	}

	PBItemS items = pCmd->items();
	if (items.item_list_size() <= 0) {
		XERR("GuildMgr::OnPBGuildAddItems2Bag GM!guild_id:%d,item_list_size()<=0", guild_id);
		return true;
	}

	auto addOrDel = pCmd->add_or_del();
	if (addOrDel) {
		PBGuildAddItems sendMsg;
		*sendMsg.mutable_items() = items;
		SendToEntity(pGuildInfo->mb_, sendMsg);
	}
	else {
		PBGuildDelItems DelMsg;
		*DelMsg.mutable_items() = items;
		SendToEntity(pGuildInfo->mb_, DelMsg);
	}

	return true;
}

//修改公会状态
bool GuildMgr::OnPBSetGuildStatus(EntityMailBox& sender_mb, ::google::protobuf::Message* pMsg) {
	PBSetGuildStatus* pCmd = (PBSetGuildStatus*)pMsg;

	auto guild_id = pCmd->guildid();
	XLOG("GuildMgr::OnPBSetGuildStatus GM! guild_id:%d", guild_id);
	auto pGuildInfo = GetGuild(guild_id);
	if (!pGuildInfo)
	{
		XERR("GuildMgr::OnPBSetGuildStatus GM!not find guild! guild_id:%d", guild_id);
		return true;
	}

	auto status = pCmd->status();
	if (status < eGS_Creating || status > eGS_Destory) {
		XERR("GuildMgr::OnPBSetGuildStatus GM!guild_id:%d,status:%d", guild_id, status);
		return true;
	}

	SendToEntity(pGuildInfo->mb_, *pCmd);
	return true;
}
//修改公会捐赠
bool GuildMgr::OnPBOpenGuildJuanZeng(EntityMailBox& sender_mb, ::google::protobuf::Message* pMsg) {
	PBOpenGuildJuanZeng* pCmd = (PBOpenGuildJuanZeng*)pMsg;

	auto guild_id = pCmd->guildid();
	XLOG("GuildMgr::OnPBOpenGuildJuanZeng GM! guild_id:%d", guild_id);
	auto pGuildInfo = GetGuild(guild_id);
	if (!pGuildInfo)
	{
		XERR("GuildMgr::OnPBOpenGuildJuanZeng GM!not find guild! guild_id:%d", guild_id);
		return true;
	}

	SendToEntity(pGuildInfo->mb_, *pCmd);
	return true;
}

//发送到UserMgr设置玩家公会信息
//bool GuildMgr::OnPBGuildPlayerSetGuildInfoCmd(EntityMailBox& sender_mb, ::google::protobuf::Message *pMsg) {
//	PBGuildPlayerSetGuildInfoCmd* pCmd = (PBGuildPlayerSetGuildInfoCmd*)pMsg;
//	SendToGlobalEntity("UserMgr", *pCmd);
//	return true;
//}
