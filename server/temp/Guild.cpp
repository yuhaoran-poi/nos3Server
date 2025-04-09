#include "Guild.h"
#include "SqlMgr.h"
#include "SearchUserMgr.h"
#include "xErrorCode.pb.h"
#include "util.h"
#include "xBitOperator.h"
#include "stopword.h"
#include "SearchUserMgr.h"
#include "GuildMemberNumDataMgr.h"
#include "CoinConfigDataMgr.h"
#include "ItemConfigDataMgr.h"
#include "SkinConfigDataMgr.h"
#include "LogRecordMgr.h"
#include <math.h>
#include "LobbyUserManager.h"
#include "GuildExpConfig.h"
#include "MailMgr.h"
#include "GuildShopDataMgr.h"
#include "guildshopConfig.h"
#include "TreasureBoxConfig.h"
#include "guildHeadConfig.h"
const int ModifyGuildNameCold = 168 * 3600;
const int ModifyGuildNameCostGuBi = 1000;
const int GuildNewMemberGetSalaryTime = 72 * 3600;
const int GuildNewMemberDonateTime = 72 * 3600;


Guild::Guild() {

	//XLOG("Guild! eid:%llu", GetEId());

	RegHandler<PBLobbyGateSetNicknamReq>(std::bind(&Guild::OnPBLobbyGateSetNicknamReq, this, _1, _2));   //玩家改名消息

	RegHandler<PBGuildQuitReqCmd>(std::bind(&Guild::OnPBGuildQuitReqCmd, this, _1, _2));  //退出公会
	RegHandler<PBGuildExpelQuitReqCmd>(std::bind(&Guild::OnPBGuildExpelQuitReqCmd, this, _1, _2));  //踢出公会
	RegHandler<PBGuildGrantReqCmd>(std::bind(&Guild::OnPBGuildGrantReqCmd, this, _1, _2));  //公会授予职位
	RegHandler<PBGuildDemiseReqCmd>(std::bind(&Guild::OnPBGuildDemiseReqCmd, this, _1, _2));  //公会转让职位
	RegHandler<PBGuildDismissReqCmd>(std::bind(&Guild::OnPBGuildDismissReqCmd, this, _1, _2));  //公会解散

	RegHandler<PBGuildGetMembersReq>(std::bind(&Guild::OnPBGuildGetMembersReq, this, _1, _2));  //获取公会成员列表

	RegHandler<PBGuildApplyJoinGuildReqCmd>(std::bind(&Guild::OnPBGuildApplyJoinGuildReqCmd, this, _1, _2));   //申请加入请求
	RegHandler<PBGuildAnswerApplyJoinGuildReqCmd>(std::bind(&Guild::OnPBGuildAnswerApplyJoinGuildReqCmd, this, _1, _2));   //回复申请加入请求
	RegHandler<PBGuildInviteJoinGuildReqCmd>(std::bind(&Guild::OnPBGuildInviteJoinGuildReqCmd, this, _1, _2));   //邀请加入公会
	RegHandler<PBGuildAnswerInviteJoinGuildReqCmd>(std::bind(&Guild::OnPBGuildAnswerInviteJoinGuildReqCmd, this, _1, _2));   //回复邀请加入公会

	RegHandler<PBGuildThawReqCmd>(std::bind(&Guild::OnPBGuildThawReqCmd, this, _1, _2));  //公会解冻
	RegHandler<PBGuildModifyAnnouncementReqCmd>(std::bind(&Guild::OnPBGuildModifyAnnouncementReqCmd, this, _1, _2));  //公会修改公告
	RegHandler<PBGuildAddDutyReqCmd>(std::bind(&Guild::OnPBGuildAddDutyReqCmd, this, _1, _2));  //公会增加职位
	RegHandler<PBGuildDelDutyReqCmd>(std::bind(&Guild::OnPBGuildDelDutyReqCmd, this, _1, _2));  //公会删除职位
	RegHandler<PBGuildModifyDutyRightReqCmd>(std::bind(&Guild::OnPBGuildModifyDutyRightReqCmd, this, _1, _2));  //公会修改职位权限
	RegHandler<PBGuildModifyDutyNameReq>(std::bind(&Guild::OnPBGuildModifyDutyNameReqCmd, this, _1, _2));  //公会修改职位名称
	RegHandler<PBGuildModifyDutyLevelReq>(std::bind(&Guild::OnPBGuildModifyDutyLevelReqCmd, this, _1, _2));  //公会修改职位等级

	RegHandler<PBGuildUpgradeReqCmd>(std::bind(&Guild::OnPBGuildUpgradeReqCmd, this, _1, _2));  //公会升级
	RegHandler<PBGuildGetApplyListReqCmd>(std::bind(&Guild::OnPBGuildGetApplyListReqCmd, this, _1, _2));  //获取申请列表

	RegHandler<PBSendChatReqCmd>(std::bind(&Guild::OnPBGuildSendChatReqCmd, this, _1, _2));  //公会聊天

	RegHandler<PBGuildUpgradeMemberMaxcountReq>(std::bind(&Guild::OnPBGuildUpgradeMemberMaxcountReq, this, _1, _2)); //提升公会最大人数的请求
	RegHandler<PBGuildDonateReq>(std::bind(&Guild::OnPBGuildDonateReq, this, _1, _2));  //公会捐赠请求
	RegHandler<PBGuildGetSalaryReq>(std::bind(&Guild::OnPBGuildGetSalaryReq, this, _1, _2));  //战队领工资请求

	RegHandler<PBGuildModifyGuildNameReqCmd>(std::bind(&Guild::OnPBGuildModifyGuildNameReqCmd, this, _1, _2));  //战队改名
	RegHandler<PBGuildModifyGuildNameRspCmd>(std::bind(&Guild::OnPBGuildModifyGuildNameRspCmd, this, _1, _2));  //战队改名 从Entity返回

	RegHandler<PBGuildAddItems>(std::bind(&Guild::OnPBGuildAddItems, this, _1, _2));  //公会添加物品
	RegHandler<PBGuildDelItems>(std::bind(&Guild::OnPBGuildDelItems, this, _1, _2));  //公会添加物品
	RegHandler<PBSetGuildJoinConditionReqCmd>(std::bind(&Guild::OnPBSetGuildJoinConditionCmd, this, _1, _2));  //公会加入条件

	RegHandler<PBGuildSetSpoilsMgrReq>(std::bind(&Guild::OnPBGuildSetSpoilsMgrReq, this, _1, _2));  //设置公会管理员
	RegHandler<PBGuildDkpChangeReq>(std::bind(&Guild::OnPBGuildDkpChangeReq, this, _1, _2));        //修改公会DKP值
	RegHandler<PBGuildSendSpoilsReq>(std::bind(&Guild::OnPBGuildSendSpoilReq, this, _1, _2));       //发放战利品

	RegHandler<PBGuildDayMissionAwardReqCmd>(std::bind(&Guild::OnPBGuildDayMissionAwardReqCmd, this, _1, _2));       //公会日常任务奖励领取

	RegHandler<PBGuildUpdateShopReq>(std::bind(&Guild::OnPBGuildUpdateShopReq, this, _1, _2)); //请求商店信息
	RegHandler<PBGuildShopBuyItemReq>(std::bind(&Guild::OnPBGuildShopBuyItemReq, this, _1, _2)); //请求购买商品

	RegHandler<PBGuildRecordListReq>(std::bind(&Guild::OnPBGuildRecordListReq, this, _1, _2)); //获取公会记录
	RegHandler<PBGuildBuyRecommentReqCmd>(std::bind(&Guild::OnPBGuildBuyRecommentReqCmd, this, _1, _2)); //购买推荐公会

	RegHandler<PBPlayerRechargeSyn>(std::bind(&Guild::OnPBPlayerRechargeSyn, this, _1, _2)); //玩家充值数据（灵石）刷新

	RegHandler<PBGuildSetHeadReqCmd>(std::bind(&Guild::OnPBGuildSetHeadReqCmd, this, _1, _2)); //设置头像
	RegHandler<PBSetGuildStatus>(std::bind(&Guild::OnPBGMSetGuildStatus, this, _1, _2));  //GM修改公会状态
	RegHandler<PBOpenGuildJuanZeng>(std::bind(&Guild::OnPBOpenGuildJuanZeng, this, _1, _2));  //GM修改公会捐赠
}

PBGuildApplyUserBaseInfo* Guild::GetApplyInfo(uint32_t uid)
{
	auto iter = m_ApplyList.find(uid);
	if (iter == m_ApplyList.end())
		return nullptr;
	return &iter->second;
}

GuildPlayerInfo* Guild::GetPlayerInfo(uint32_t uid)
{
	auto iter = m_PlayerList.find(uid);
	if (iter == m_PlayerList.end())
		return nullptr;
	return &iter->second;
}

EntityMailBox* Guild::GetPlayerMb(uint32_t uid)
{
	auto playerInfo = GetPlayerInfo(uid);
	if (!playerInfo)
		return nullptr;
	return &playerInfo->mb;
}

bool Guild::AddMember(uint32_t uid, const PBUserGameBaseSimpleData& simpleData, const EntityMailBox& mb)
{
	if (GetPlayerInfo(uid))
	{
		return false;
	}
	if (uid <= 0)return false;

	//assert(uid > 0);
	auto& p = m_PlayerList[uid];
	p.mb = mb;
	p.m_nPlayerDbid = uid;
	p.m_GuildUserData.set_uid(uid);
	*p.m_GuildUserData.mutable_playersimpleinfo() = simpleData;

	auto pGuildMemberData = p.m_GuildUserData.mutable_guild_data();
	pGuildMemberData->set_uid(uid);
	pGuildMemberData->set_playerstatus(mb.IsOk() ? e_Online : e_Offline);
	pGuildMemberData->set_join_time(time(0));
	pGuildMemberData->set_bspoilsmgr(false);

	if (IsSpoilsMgr(&p))
	{
		int errcode = 0;
		SetSpoiMgr(uid, true, errcode);

	}

	//添加公会记录
	PBGuildRecordInfo record;
	record.set_record_type(eRT_JOIN);
	record.set_nickname(simpleData.nick_name());
	record.set_target_uid(uid);
	AddGuildRecord(record);

	NotifyPlayerJoin(p);

	if (p.mb.IsOk())
	{
		//更新公会信息给玩家
		UpdateGuildDataToPlayer(uid);
	}

	SetGuildDirty();
	return true;
}


bool Guild::AddApplyInfo(uint32_t uid, const PBUserGameBaseSimpleData& simple_data)
{
	auto pApplyInfo = GetApplyInfo(uid);
	if (pApplyInfo)
	{//已经申请过，重复申请
		XERR("Guild::AddApplyInfo!had Apply!guild_id:%llu, uid:%d", m_guild_id, uid);
		return false;
	}
	PBGuildApplyUserBaseInfo applyInfo;
	applyInfo.set_apply_time(time(0));
	*applyInfo.mutable_playersimpleinfo() = simple_data;
	m_ApplyList[uid] = applyInfo;

	*m_guildInfo.mutable_apply_list()->add_apply_list() = applyInfo;

	//通知GuildMgr添加
	UpdateApplyInfo2GuildMgr(AO_ADD, uid, applyInfo.apply_time());

	SetGuildDirty();
	return true;
}

bool Guild::DelApplyInfo(uint32_t uid)
{
	auto iter = m_ApplyList.find(uid);
	if (iter == m_ApplyList.end())
	{//没有找到申请
		XERR("Guild::DelApplyInfo!not find Apply!guild_id:%llu, uid:%d", m_guild_id, uid);
		return false;
	}
	m_ApplyList.erase(iter);

	//通知GuildMgr删除
	UpdateApplyInfo2GuildMgr(AO_DEL, uid, 0);

	auto pPBApplyList = m_guildInfo.mutable_apply_list();
	for (auto i = 0; i < pPBApplyList->apply_list_size(); ++i)
	{
		if (pPBApplyList->apply_list(i).playersimpleinfo().uid() == uid)
		{
			pPBApplyList->mutable_apply_list()->DeleteSubrange(i, 1);
			break;
		}
	}
	NotifyManagerApply();
	SetGuildDirty();
	return true;
}


void Guild::PlayerJoin(uint32_t uid)
{
	if (GetPlayerInfo(uid))
	{
		XERR("Guild::PlayerJoin! not find player!guild_id:%llu, uid:%d", m_guild_id, uid);
		return;
	}

	std::vector<uint32_t> uids;
	uids.push_back(uid);
	SearchUserMgr::GetUserBaseDataReq(uids, [this](const PBUserGameBaseSimpleDataList& data_list)
		{
			for (int i = 0; i < data_list.data_list_size(); ++i)
			{
				auto& simple_data = data_list.data_list(i);
				auto uid = simple_data.uid();

				AddMember(uid, simple_data, data_list.mb_list(i));
			}
		});
}

bool Guild::PlayerLeave(uint32_t uid)
{
	auto it = m_PlayerList.find(uid);
	if (it == m_PlayerList.end()) {
		return false;
	}
	if (IsSpoilsMgr(&it->second))
	{
		int errcode = 0;
		SetSpoiMgr(uid, false, errcode);
		//通知会长刷新
		PBGuildSetSpoilsMgrRsp rspMsg;
		rspMsg.set_sucess(true);
		rspMsg.set_bset(false);
		rspMsg.set_des_uid(uid);
		auto master = GetPlayerInfo(m_guildInfo.president_id());
		if (master)
			SendToClientEntity(master->mb, rspMsg);
	}


	//添加公会记录
	PBGuildRecordInfo record;
	record.set_record_type(eRT_QUIT);
	record.set_nickname(it->second.GetNickname());
	record.set_target_uid(uid);
	AddGuildRecord(record);

	//清空玩家对公会mb的引用
	CleanGuildMbToPlayer(uid);
	NotifyPlayerExit(uid);
	SetGuildDirty();

	m_managerMap.erase(uid);

	m_PlayerList.erase(it);
	return true;
}

bool Guild::SetSpoiMgr(uint32_t uid, bool bset, int& errcode)
{
	auto playerinfo = GetPlayerInfo(uid);
	if (!playerinfo)
	{
		return true;
	}
	bool boldIsMgr = playerinfo->m_GuildUserData.mutable_guild_data()->bspoilsmgr();
	std::map <uint32_t, uint32_t> mapIds;
	for (int i = 0; i < m_guildInfo.spoilsmgr_ids_size(); i++)
	{
		auto tid = m_guildInfo.spoilsmgr_ids().Get(i);
		mapIds.insert(make_pair(tid, tid));
	}

	if (bset)
	{
		//判断目标是不是管理员
		if (IsMaster(uid))
			return true;
		//任命战利品管理员
		if (mapIds.size() >= 3)
		{
			errcode = ERR_GUILD_FULL_SPOIL_MGR;
			return false;
		}
		mapIds.insert(make_pair(uid, uid));
		playerinfo->m_GuildUserData.mutable_guild_data()->set_bspoilsmgr(true);
	}
	else
	{
		//取消战利品管理员
		mapIds.erase(uid);
		playerinfo->m_GuildUserData.mutable_guild_data()->set_bspoilsmgr(false);
	}
	//刷新列表
	m_guildInfo.mutable_spoilsmgr_ids()->Clear();
	for (auto& iter : mapIds)
	{
		m_guildInfo.mutable_spoilsmgr_ids()->Add(iter.first);
	}
	if (boldIsMgr != bset)
	{
		PBGuildSetSpoilsMgrRsp rspMsg;
		rspMsg.set_sucess(true);
		rspMsg.set_bset(bset);
		rspMsg.set_des_uid(uid);
		BoardcastMsgToClient(rspMsg);
	}
	SetGuildDirty();
	return true;
}

void Guild::GenMemberList()
{
	m_guildInfo.clear_user_list();
	for (auto& v : m_PlayerList)
	{
		*m_guildInfo.add_user_list() = v.second.m_GuildUserData;
	}
	m_guildInfo.set_member_count(m_PlayerList.size());
}

void Guild::GenGuildBag()
{
	auto pGuildBag = m_guildInfo.mutable_guild_bag();
	pGuildBag->clear_item_list();
	for (auto& v : m_guildBag)
	{
		auto pItem = pGuildBag->add_item_list();
		pItem->set_config_id(v.first);
		pItem->set_item_count(v.second);
	}
}

void Guild::GenGuildShop()
{
	auto pGuildShop = m_guildInfo.mutable_slist();
	pGuildShop->clear_items();
	for (auto& v : m_shopItem)
	{
		*pGuildShop->add_items() = v.second;
	}
}

void Guild::OnSave2Db()
{
	//重新生成成员列表
	GenMemberList();
	//重新生成仓库数据
	GenGuildBag();
	//重新生成公会商店数据
	GenGuildShop();
	//定时存档
	SqlMgr::Update("t_guild_data", m_guild_id, m_guildInfo, [this](bool bUpdateSucc) {
		if (!bUpdateSucc)
		{
			XERR("Guild::SaveToDb Failed! guild_id:%llu", m_guild_id);
			return;
		}
		XLOG("Guild::SaveToDb Succ! guild_id:%llu", m_guild_id);
		});
}

void Guild::OnTimerRefresh()
{
	auto now = time(0);
	if (xTime::isSameDay(now, m_guildInfo.last_shoprefreshtime()))
	{
		//每天只执行一次，测试的时候放开
		return;
	}

	//扣钱，公会维护费用1%灵币
	auto num = GetItemCount(SCT_Guild_LingBi) / 100;
	DelItem(SCT_Guild_LingBi, num, RD_GuildMaintain);
	m_guildInfo.set_last_shoprefreshtime(now);

	//商店物品数量刷新 
	for (auto& iter : m_shopItem)
	{
		//判断该道具刷新类型
		auto data = GuildShopDataMgr::getMe().getMarketItemInfo(iter.first);
		if (!data)continue;
		if (data->cfg->atuo_refresh == 0)continue;
		else if (data->cfg->atuo_refresh == 1)
		{
			//每日刷新
			auto now = time(0);
			if (!xTime::isSameDay(now, iter.second.pre_time()))
			{
				iter.second.set_pre_time(now);
				iter.second.set_buy_count(0);
			}
		}
		else if (data->cfg->atuo_refresh == 2)
		{
			//每周刷新
			auto now = time(0);
			if (!xTime::isSameWeek(now, iter.second.pre_time()))
			{
				iter.second.set_pre_time(now);
				iter.second.set_buy_count(0);
			}
		}
		else if (data->cfg->atuo_refresh == 3)
		{
			//每月刷新
			if (!xTime::isSameMonth(now, iter.second.pre_time()))
			{
				iter.second.set_pre_time(now);
				iter.second.set_buy_count(0);
			}
		}
	}
	UpdateGuildShopList(1);
	SetGuildDirty();
}

bool Guild::InitWithData(const string& data)
{
	if (!m_guildInfo.ParseFromString(data))
	{
		XERR("Guild::InitWithData Failed!");
		return false;
	}
	//解析成功
	auto now = time(0);
	m_guild_id = m_guildInfo.guildid();

	if (0 == m_guildInfo.mutable_duty_list()->duty_list_size())
	{//容错。添加两个默认的职位，等级是100和0，不能删除
		auto pDutyInfo = m_guildInfo.mutable_duty_list()->add_duty_list();
		pDutyInfo->set_duty_id(0);
		pDutyInfo->set_duty_name("");
		pDutyInfo->set_duty_level(0);
		pDutyInfo->set_duty_right(0);

		pDutyInfo = m_guildInfo.mutable_duty_list()->add_duty_list();
		pDutyInfo->set_duty_id(1);
		pDutyInfo->set_duty_name("");
		pDutyInfo->set_duty_level(100);
		pDutyInfo->set_duty_right(0);

		SetGuildDirty();
	}

	if (0 == m_guildInfo.member_num_level() || 0 == m_guildInfo.member_max_num())
	{//容错。设置最大公会人数
		m_guildInfo.set_member_num_level(1);

		auto pConfig = GuildMemberNumDataMgr::getMe().GetConfig(1);
		if (pConfig)
			m_guildInfo.set_member_max_num(pConfig->cfg->num);
		else
			m_guildInfo.set_member_max_num(100);
		SetGuildDirty();
	}



	//初始化申请列表
	auto pApplyList = m_guildInfo.mutable_apply_list();
	for (int i = 0; i < pApplyList->apply_list_size(); ++i)
	{
		auto& applyInfo = pApplyList->apply_list(i);
		m_ApplyList[applyInfo.playersimpleinfo().uid()] = applyInfo;
	}

	//初始化成员列表
	for (int i = 0; i < m_guildInfo.user_list_size(); ++i)
	{
		auto& pUserInfo = m_guildInfo.user_list(i);
		auto& p = m_PlayerList[pUserInfo.uid()];
		p.m_nPlayerDbid = pUserInfo.uid();
		p.m_GuildUserData = pUserInfo;
		p.m_GuildUserData.mutable_guild_data()->set_playerstatus(e_Offline);

		//assert(p.m_nPlayerDbid > 0);

		if (0 == p.m_GuildUserData.mutable_guild_data()->join_time())
		{//容错。
			p.m_GuildUserData.mutable_guild_data()->set_join_time(now);
		}
		if (p.m_GuildUserData.guild_data().playerdutyid() > 0)
		{//记录管理员列表
			m_managerMap[p.m_nPlayerDbid] = p.m_GuildUserData.guild_data().playerdutyid();
		}
	}
	if (m_guildInfo.member_count() > m_guildInfo.member_max_num())
		m_guildInfo.set_member_max_num(m_guildInfo.member_count());


	int oldMemberMax = m_guildInfo.member_max_num();

	while (true)
	{
		auto member_num_level = m_guildInfo.member_num_level();
		auto pConfig = GuildMemberNumDataMgr::getMe().GetConfig(member_num_level);
		if (!pConfig)break;

		m_guildInfo.set_member_max_num(pConfig->cfg->num);
		if (oldMemberMax > pConfig->cfg->num)
		{
			m_guildInfo.set_member_num_level(member_num_level + 1);
		}
		else
		{
			break;
		}
	}



	//初始化公会背包
	auto& guild_bag = m_guildInfo.guild_bag();
	for (int i = 0; i < guild_bag.item_list_size(); ++i)
	{
		auto& item = guild_bag.item_list(i);
		m_guildBag[item.config_id()] = item.item_count();
	}
	//初始化公会头像
	if (m_guildInfo.has_item_headid() && m_guildInfo.has_item_frameid())
	{
		if (GetItemCount(440001) <= 0 || GetItemCount(450001) <= 0)
		{
			AddItem(440001, 1, RD_SYS);
			AddItem(450001, 1, RD_SYS);
			GenGuildBag();
		}
	}
	else
	{
		AddItem(440001, 1, RD_SYS);
		AddItem(450001, 1, RD_SYS);
		GenGuildBag();
		//设置头像
		m_guildInfo.set_item_headid(440001);
		m_guildInfo.set_item_frameid(450001);
	}

	//初始化公会商店
	auto& vecShop = guildshopConfigManager::getMe().GetConfigVec();
	for (auto& item : vecShop)
	{
		//XLOG("Guild::InitWithData vecShop! guild_id:%llu", m_guild_id);
		auto data = GuildShopDataMgr::getMe().getMarketItemInfo(item->id);
		if (data)
		{
			PBGuildShopItemInfo info;
			info.set_s_id(item->id);
			info.mutable_item_price()->set_npricetype(data->nPriceType);
			info.mutable_item_price()->set_npricecount(data->nPriceCount);
			info.set_buy_count(0);
			info.set_item_id(item->itemID);
			m_shopItem[item->id] = info;
		}

	}
	auto& guild_shop = m_guildInfo.slist();
	for (int i = 0; i < guild_shop.items_size(); i++)
	{
		auto& item = guild_shop.items(i);
		if (m_shopItem.find(item.s_id()) != m_shopItem.end())
		{
			m_shopItem[item.s_id()].set_buy_count(item.buy_count());
			m_shopItem[item.s_id()].set_pre_time(item.pre_time());
		}
	}
	UpdateGuildShopList(1);
	UpdateSimpleInfo2GuildMgr();

	XLOG("Guild::InitWithData Successed! guild_id:%llu", m_guild_id);

	//公会初始化成功后，需要通知GuildMgr保存自己的Mailbox
	PBNotifyNewerMailboxReq msg;
	msg.set_entity_name("Guild");
	CopyMbTo(msg.mutable_entity_mb());
	msg.set_reserved1(m_guild_id);
	SendToGlobalEntity("GuildMgr", msg);

	StartTimerRefresh();
	SetGuildDirty();
	return true;
}

void Guild::RefreshManager()
{
	//初始化成员列表
	for (int i = 0; i < m_guildInfo.user_list_size(); ++i)
	{
		auto& pUserInfo = m_guildInfo.user_list(i);
		auto playerdutyid = pUserInfo.guild_data().playerdutyid();
		if (playerdutyid > 0)
		{
			m_managerMap[pUserInfo.uid()] = playerdutyid; //记录管理员列表
		}
	}
}

void Guild::UpdateGuildShopList(int nDelay)
{
	m_shopUpdateDelay.SetDelay(nDelay, [this]()
		{
			m_shopList.clear();
			map<int, map<int, PBGuildShopItemInfo> > mapTabTop;
			map<int, map<int, PBGuildShopItemInfo> > mapTabNomal;
			for (auto& iter : m_shopItem)
			{
				auto data = GuildShopDataMgr::getMe().getMarketItemInfo(iter.first);
				if (data)
				{
					if (time(0) < data->delTime || data->delTime == 0)
					{
						if (data->cfg->top > 0)
							mapTabTop[data->cfg->shop_type][iter.first] = iter.second;
						else
							mapTabNomal[data->cfg->shop_type][iter.first] = iter.second;
					}
				}
			}
			//先插入top
			for (auto& maptop : mapTabTop)
			{
				for (auto& item : maptop.second)
				{
					*m_shopList[maptop.first].add_items() = item.second;
				}
			}
			//再插入普通的
			for (auto& mapNomal : mapTabNomal)
			{
				for (auto& item : mapNomal.second)
				{
					*m_shopList[mapNomal.first].add_items() = item.second;
				}
			}

		});
}

void Guild::UpdateSimpleInfo2GuildMgr()
{
	m_simpleDataUpdateDelay.SetDelay(10, [this]()
		{
			m_guildInfo.set_member_count(m_PlayerList.size());
			PBGuildUpdateSimpleInfo2GuildMgr updateMsg;
			Util::GetSimpleGuildData(m_guildInfo, updateMsg.mutable_simple_info());
			SendToGlobalEntity("GuildMgr", updateMsg);
		});
}

bool Guild::UpdateGuildDataToPlayer(uint32_t uid)
{
	auto playerInfo = GetPlayerInfo(uid);
	if (!playerInfo)
	{
		XERR("Guild::SendGuildMbToPlayer Error! not find player! uid:%d", uid);
		return false;
	}

	auto masterPlayerInfo = GetPlayerInfo(m_guildInfo.president_id());
	if (masterPlayerInfo)
	{
		//如由更改则更新到排行榜，更新相关数据
		UpdateGuildRank(uid, masterPlayerInfo);
	}

	//设置公会的mb关联
	PBGuildPlayerSetGuildInfoCmd guildMsg;
	guildMsg.set_guild_id(m_guild_id);
	guildMsg.set_guild_name(m_guildInfo.name());
	CopyMbTo(guildMsg.mutable_mb());
	SendToEntity(playerInfo->mb, guildMsg);

	//设置战队人数
	m_guildInfo.set_member_count(m_PlayerList.size());
	//设置申请数量
	m_guildInfo.set_apply_count(m_ApplyList.size());

	//更新整个公会的信息
	PBGuildUpdateGuildInfoRspCmd rspGuildInfo;
	auto pGuildInfo = rspGuildInfo.mutable_guildinfo();
	*pGuildInfo->mutable_guildinfo() = m_guildInfo;
	*pGuildInfo->mutable_self_guild_data() = playerInfo->m_GuildUserData.guild_data();

	//清除玩家列表和申请列表。这两个列表要通过接口来获取
	pGuildInfo->mutable_guildinfo()->clear_user_list();
	pGuildInfo->mutable_guildinfo()->clear_apply_list();
	//清除公会记录列表
	pGuildInfo->mutable_guildinfo()->clear_record_list();
	//清除商店列表
	pGuildInfo->mutable_guildinfo()->clear_slist();

	SendToClientEntity(playerInfo->mb, rspGuildInfo);
	return true;
}

bool Guild::UpdateGuildRank(uint32_t uid, GuildPlayerInfo* playInfo)
{
	if (!playInfo)return false;

	//判断原有公会长名字和现有名字是否相同，不同则需要更新
	auto name1 = m_guildInfo.president_name();
	auto name2 = playInfo->m_GuildUserData.playersimpleinfo().nick_name();

	if (name1 != name2) {
		m_guildInfo.set_president_name(playInfo->m_GuildUserData.playersimpleinfo().nick_name());
		if (m_guildInfo.status() == eGS_Normal) {
			//状态为Normal，则发送到排行榜
			SendGuildInfoToDB(m_guildInfo, 0);
		}
	}
	return true;
}

void Guild::SendGuildInfoToDB(const PBGuildInfo& guildInfo, UInt32 create_or_dismiss)
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

//清空玩家对公会mb的引用
bool Guild::CleanGuildMbToPlayer(uint32_t uid)
{
	PBGuildPlayerSetGuildInfoCmd guildMsg;
	guildMsg.set_guild_id(0);
	guildMsg.set_guild_name("");
	if (0 != uid)
	{
		auto playerInfo = GetPlayerInfo(uid);
		if (!playerInfo)
		{
			XERR("Guild::CleanGuildMbToPlayer Error! not find player! uid:%d", uid);
			return false;
		}

		SendToEntity(playerInfo->mb, guildMsg);
	}
	else
	{
		BoardcastMsgToEntity(guildMsg);
	}

	return true;
}

bool Guild::OnPlayerOnline(EntityMailBox& sender_mb, PBLobbyGateUserOnlineReq* pCmd)
{
	XLOG("Guild::OnPlayerOnline! uid:%d guild_id:%d", pCmd->uid(), m_guild_id);
	auto playerInfo = GetPlayerInfo(pCmd->uid());
	if (!playerInfo)
	{
		XERR("Guild::OnPlayerOnline! no find player! uid:%d", pCmd->uid());

		auto& p = m_PlayerList[pCmd->uid()];
		p.m_GuildUserData.set_uid(pCmd->uid());
		//*p.m_GuildUserData.mutable_playersimpleinfo() = pCmd->base_data();
		p.m_nPlayerDbid = pCmd->uid();
		auto pGuildMemberData = p.m_GuildUserData.mutable_guild_data();
		pGuildMemberData->set_uid(pCmd->uid());
		pGuildMemberData->set_join_time(time(0));
		pGuildMemberData->set_bspoilsmgr(false);
		if (IsSpoilsMgr(&p))
		{
			int errCode = 0;
			SetSpoiMgr(pCmd->uid(), true, errCode);
		}
		playerInfo = &p;
		SetGuildDirty();
	}
	playerInfo->m_nPlayerDbid = pCmd->uid();
	playerInfo->mb = pCmd->mailbox();
	//设置状态
	auto pGuildMemberData = playerInfo->m_GuildUserData.mutable_guild_data();
	pGuildMemberData->set_playerstatus(e_Online);

	Util::GetSimpleBaseData(pCmd->base_data(), playerInfo->m_GuildUserData.mutable_playersimpleinfo());

	//设置公会的mb的引用
	UpdateGuildDataToPlayer(pCmd->uid());
	return true;
}

bool Guild::OnPlayerOffline(EntityMailBox& sender_mb, PBLobbyGateUserOfflineReq* pCmd)
{
	XLOG("Guild::OnPlayerOffline! uid:%u", pCmd->uid());
	auto playerInfo = GetPlayerInfo(pCmd->uid());
	if (!playerInfo)
	{
		XERR("Guild::OnPlayerOffline! no find player! uid:%u! guild_id:%d", pCmd->uid(), m_guild_id);
		return true;
	}
	playerInfo->mb.Clear();

	//设置在线状态
	auto pGuildMemberData = playerInfo->m_GuildUserData.mutable_guild_data();
	pGuildMemberData->set_playerstatus(e_Offline);
	return true;
}


bool Guild::OnPlayerBaseDataSimpleSyn(EntityMailBox& sender_mb, PBPlayerBaseDataSimpleSyn* pBaseDataCmd)
{
	auto uid = pBaseDataCmd->data().uid();
	XLOG("Guild::OnPlayerBaseDataSimpleSyn! uid:%d", uid);
	auto playerInfo = GetPlayerInfo(uid);
	if (!playerInfo)
	{
		XERR("Guild::OnPlayerBaseDataSimpleSyn! no find player! uid:%d", uid);
		return true;
	}
	playerInfo->mb = pBaseDataCmd->mb();
	*playerInfo->m_GuildUserData.mutable_playersimpleinfo() = pBaseDataCmd->data();

	//如果是会长，且有VIP，则进行同步到排行榜
	if (m_guildInfo.president_id() == uid) {
		if (pBaseDataCmd->data().has_vip_info()) {
			//同步到排行榜去
			SendGuildInfoToDB(m_guildInfo, 0);
		}
	}

	return true;
}

void Guild::SetGuildDirty()
{
	StartSaveToDb();
}


bool Guild::OnPBGuildQuitReqCmd(EntityMailBox& sender_mb, ::google::protobuf::Message* pMsg)
{
	PBGuildQuitReqCmd* pCmd = (PBGuildQuitReqCmd*)pMsg;
	XLOG("Guild::PBGuildQuitReqCmd! uid:%d", pCmd->uid());

	if (pCmd->uid() == GetGuildInfo().president_id()) {
		//会长不能退出自己的公会
		return false;
	}

	if (!PlayerLeave(pCmd->uid()))
	{
		return false;
	}

	//退出公会返回
	PBGuildQuitRspCmd rspMsg;
	rspMsg.set_code(ERR_SUCCESS);
	SendToClientEntity(sender_mb, rspMsg);
	return true;
}

//踢人
bool Guild::OnPBGuildExpelQuitReqCmd(EntityMailBox& sender_mb, ::google::protobuf::Message* pMsg)
{
	PBGuildExpelQuitReqCmd* pCmd = (PBGuildExpelQuitReqCmd*)pMsg;
	XLOG("Guild::PBGuildExpelQuitReqCmd! uid:%d", pCmd->uid());
	UInt32 prisend_uid = pCmd->uid();
	UInt32 target_uid = pCmd->expel_uid();

	auto pPlayerInfo = GetPlayerInfo(prisend_uid);
	if (!pPlayerInfo)
	{//没有找到玩家
		return true;
	}

	if (eGS_Normal != m_guildInfo.status()) {
		//公会已冻结或删除
		SendShowTextId(pPlayerInfo->mb, ERR_GUILD_IN_FREEZE_OR_DELETE);
		return false;
	}

	if (prisend_uid == target_uid)
	{//不能踢自己
		SendShowTextId(pPlayerInfo->mb, ERR_GUILD_CANNOT_KICKOUT_SELF);
		return true;
	}

	auto pPlayerDutyInfo = GetDutyInfo(pPlayerInfo->GetDutyId());
	if (!pPlayerDutyInfo)
	{//没有这个职位
		SendShowTextId(pPlayerInfo->mb, ERR_GUILD_NOT_FIND_DUTY_ERROR);
		return true;
	}

	if (!IsDutyHasRight(pPlayerDutyInfo, enRT_KickoutNormal))
	{//没有踢人权限
		SendShowTextId(pPlayerInfo->mb, ERR_GUILD_U_NOT_HAVE_RIGHT);
		return true;
	}

	if (IsMaster(target_uid))
	{//不能踢会长
		SendShowTextId(pPlayerInfo->mb, ERR_GUILD_CANNOT_KICKOUT_SELF);
		return true;
	}

	auto pTargetPlayerInfo = GetPlayerInfo(target_uid);
	if (!pTargetPlayerInfo)
	{//没有找到玩家
		SendShowTextId(pPlayerInfo->mb, ERR_GUILD_CANNOT_KICKOUT_MANAGER);
		return true;
	}

	auto pTargetDutyInfo = GetDutyInfo(pTargetPlayerInfo->GetDutyId());
	if (!pTargetDutyInfo)
	{//没有这个职位
		SendShowTextId(pPlayerInfo->mb, ERR_GUILD_NOT_FIND_DUTY);
		return true;
	}

	if (pTargetDutyInfo->duty_level() >= pPlayerDutyInfo->duty_level())
	{//只能踢低于自己的职位
		SendShowTextId(pPlayerInfo->mb, ERR_GUILD_U_ONLY_KICKOUT_LOW_MANAGER);
		return true;
	}

	if (!PlayerLeave(target_uid))
	{//没找到玩家
		SendShowTextId(pPlayerInfo->mb, ERR_GUILD_TARGET_NOT_IN_GUILD);
		return true;
	}

	PBGuildExpelQuitRspCmd rspMsg;
	rspMsg.set_expel_uid(target_uid);
	SendToClientEntity(pPlayerInfo->mb, rspMsg);

	if (pTargetPlayerInfo->IsOnline())
	{//通知被踢玩家
		SendToClientEntity(pTargetPlayerInfo->mb, rspMsg);
	}
	return true;
}

bool Guild::OnPBGuildGrantReqCmd(EntityMailBox& sender_mb, ::google::protobuf::Message* pMsg)
{
	PBGuildGrantReqCmd* pCmd = (PBGuildGrantReqCmd*)pMsg;
	XLOG("Guild::PBGuildGrantReqCmd! uid:%d", pCmd->uid());

	auto uid = pCmd->uid();
	auto target_uid = pCmd->target_uid();
	auto new_duty_id = pCmd->duty_id();
	auto pPlayerInfo = GetPlayerInfo(uid);
	if (!pPlayerInfo)
	{//你没有战队
		SendShowTextId(sender_mb, ERR_GUILD_U_NOT_HAVE_GUILD);
		return true;
	}

	if (IsMaster(target_uid))
	{
		SendShowTextId(sender_mb, ERR_GUILD_U_NOT_HAVE_RIGHT);
		return true;
	}

	if (uid == target_uid)
	{
		//SendShowTextId(sender_mb, ERR_GUILD_U_NOT_HAVE_RIGHT);
		return true;
	}

	auto pTargetPlayerInfo = GetPlayerInfo(target_uid);
	if (!pTargetPlayerInfo)
	{//目标不在战队内
		SendShowTextId(pPlayerInfo->mb, ERR_GUILD_TARGET_NOT_IN_GUILD);
		return true;
	}

	auto pPlayerDutyInfo = GetDutyInfo(pPlayerInfo->GetDutyId());
	if (!pPlayerDutyInfo)
	{//没有这个职位
		SendShowTextId(pPlayerInfo->mb, ERR_GUILD_NOT_FIND_DUTY_ERROR);
		return true;
	}

	if (!IsDutyHasRight(pPlayerDutyInfo, enRT_SetDuty))
	{//您没有任免职位权限
		SendShowTextId(pPlayerInfo->mb, ERR_GUILD_U_NOT_HAVE_RIGHT);
		return true;
	}

	auto pTargetDutyInfo = GetDutyInfo(new_duty_id);
	if (!pTargetDutyInfo)
	{//没有这个职位
		SendShowTextId(pPlayerInfo->mb, ERR_GUILD_NOT_FIND_DUTY);
		return true;
	}

	if (pTargetDutyInfo->duty_level() >= pPlayerDutyInfo->duty_level())
	{//只能授予低于自己的职位
		SendShowTextId(pPlayerInfo->mb, ERR_GUILD_CANNOT_GRANT_DUTY_BIGGER);
		return true;
	}

	auto player_duty_id = pTargetPlayerInfo->m_GuildUserData.mutable_guild_data()->playerdutyid();
	if (new_duty_id == player_duty_id)
	{//相同职位，直接抛弃
		SendShowTextId(pPlayerInfo->mb, ERR_GUILD_DUTY_SAME_ERROR);
		return true;
	}

	//if (m_managerMap.size() > 10)
	//{//达到职位上限
	//	SendShowTextId(pPlayerInfo->mb, ERR_GUILD_DUTY_COUNT_LIMIT_ERROR);
	//	return true;
	//}

	pTargetPlayerInfo->m_GuildUserData.mutable_guild_data()->set_playerdutyid(new_duty_id);

	if (new_duty_id > 0)
		m_managerMap[target_uid] = new_duty_id;
	else
		m_managerMap.erase(target_uid);

	//添加公会记录
	PBGuildRecordInfo record;
	record.set_record_type(eRT_DUTY_CHANGE);
	record.set_nickname(pTargetPlayerInfo->GetNickname());
	record.set_duty_id(new_duty_id);
	record.set_duty_name(pTargetDutyInfo->duty_name());
	record.set_target_uid(target_uid);
	AddGuildRecord(record);

	PBGuildGrantRspCmd rspMsg;
	rspMsg.set_duty_id(new_duty_id);
	rspMsg.set_target_uid(target_uid);
	SendToClientEntity(pPlayerInfo->mb, rspMsg);
	UpdateGuildDataToPlayer(target_uid);
	if (pTargetPlayerInfo->IsOnline())
	{//给对方也发送消息作为通知
		SendToClientEntity(pTargetPlayerInfo->mb, rspMsg);
	}
	return true;
}

//公会转让
bool Guild::OnPBGuildDemiseReqCmd(EntityMailBox& sender_mb, ::google::protobuf::Message* pMsg)
{
	PBGuildDemiseReqCmd* pCmd = (PBGuildDemiseReqCmd*)pMsg;
	XLOG("Guild::PBGuildDemiseReqCmd! uid:%d", pCmd->uid());
	UInt32 uid = pCmd->uid();
	auto target_uid = pCmd->target_uid();
	auto pPlayerInfo = GetPlayerInfo(uid);
	if (!pPlayerInfo)
	{//没有找到玩家
		SendShowTextId(sender_mb, ERR_GUILD_U_NOT_HAVE_GUILD);
		return true;
	}

	if (uid == target_uid)
	{//不能操作自己
		//SendShowTextId(sender_mb, ERR_GUILD_U_NOT_HAVE_RIGHT);
		return true;
	}

	auto pTargetPlayerInfo = GetPlayerInfo(target_uid);
	if (!pTargetPlayerInfo)
	{//没有找到玩家
		SendShowTextId(pPlayerInfo->mb, ERR_GUILD_TARGET_NOT_IN_GUILD);
		return true;
	}

	if (!IsMaster(uid))
	{//不是公会长
		SendShowTextId(pPlayerInfo->mb, ERR_GUILD_NOT_MASTER);
		return true;
	}

	m_guildInfo.set_president_id(target_uid);
	m_guildInfo.set_president_name(pTargetPlayerInfo->GetNickname());

	pPlayerInfo->m_GuildUserData.mutable_guild_data()->set_playerdutyid(0);
	pTargetPlayerInfo->m_GuildUserData.mutable_guild_data()->set_playerdutyid(1);

	//记录管理员列表
	m_managerMap.erase(uid);
	m_managerMap[target_uid] = 1;
	//战利品管理员
	int errcode = 0;
	SetSpoiMgr(target_uid, false, errcode);
	UpdateSimpleInfo2GuildMgr();

	//设置脏数据
	SetGuildDirty();

	PBGuildDemiseRspCmd rspMsg;
	rspMsg.set_new_master_uid(target_uid);
	rspMsg.set_new_master_name(pTargetPlayerInfo->m_GuildUserData.playersimpleinfo().nick_name());
	//转让结果
	BoardcastMsgToClient(rspMsg);
	return true;
}

bool Guild::OnPBGuildDismissReqCmd(EntityMailBox& sender_mb, ::google::protobuf::Message* pMsg)
{
	PBGuildDismissReqCmd* pCmd = (PBGuildDismissReqCmd*)pMsg;
	XLOG("Guild::PBGuildDismissReqCmd! uid:%d", pCmd->uid());

	UInt32 uid = pCmd->uid();
	auto PlayerInfo = GetPlayerInfo(uid);
	if (!PlayerInfo)
	{//没有找到玩家
		return true;
	}

	//获取此人公会信息
	auto& guildinfo = GetGuildInfo();
	if (!IsMaster(uid)) {
		//不是公会长
		SendShowTextId(PlayerInfo->mb, ERR_GUILD_NOT_MASTER_CANNOT_DISMISS);
		return true;
	}

	if (eGS_Normal != guildinfo.status()) {
		//公会状态不是Normal,已处于冻结或解散状态
		SendShowTextId(PlayerInfo->mb, ERR_GUILD_IN_FREEZE_OR_DELETE);
		return true;
	}

	if (m_PlayerList.size() > 1)
	{
		SendShowTextId(PlayerInfo->mb, ERR_GUILD_HAD_MEMBER_CANNOT_DISMISS);
		return true;
	}

	guildinfo.set_status(eGS_Destory);
	guildinfo.set_destory_time(time(0));
	PBGuildDismissRspCmd rspMsg;
	SendToClientEntity(PlayerInfo->mb, rspMsg);
	auto pl = m_PlayerList;
	for (auto iter : pl)
		PlayerLeave(iter.first);
	//通知公会更新
	UpdateSimpleInfo2GuildMgr();
	NotifyGuildDismiss();
	//设置脏数据
	SetGuildDirty();

	if (m_guildInfo.status() == eGS_Destory) {
		//状态为解散，则发送到排行榜(更新排行榜)
		SendGuildInfoToDB(m_guildInfo, 1);
	}

	return true;
}

//公会解冻
bool Guild::OnPBGuildThawReqCmd(EntityMailBox& sender_mb, ::google::protobuf::Message* pMsg)
{
	PBGuildThawReqCmd* pCmd = (PBGuildThawReqCmd*)pMsg;
	XLOG("Guild::PBGuildThawReqCmd! uid:%d", pCmd->uid());

	UInt32 uid = pCmd->uid();

	auto PlayerInfo = GetPlayerInfo(uid);
	if (!PlayerInfo)
	{//没有找到玩家

		return true;
	}

	//获取此人公会信息
	auto& guildinfo = GetGuildInfo();
	if (!IsMaster(uid)) {
		//不是公会长
		SendShowTextId(PlayerInfo->mb, ERR_GUILD_NOT_MASTER_CANNOT_thaw);
		return true;
	}

	//只有冻结或解散的公会才会使用到公会解冻功能
	if (eGS_Freeze != guildinfo.status() || eGS_Destory != guildinfo.status()) {
		SendShowTextId(PlayerInfo->mb, ERR_GUILD_NOT_IN_FREEZE);
		return true;
	}

	guildinfo.set_status(eGS_Normal);
	guildinfo.set_freeze_time(0);

	//通知公会更新
	UpdateSimpleInfo2GuildMgr();

	//设置脏数据
	SetGuildDirty();

	PBGuildThawRspCmd rspMsg;
	SendToClientEntity(sender_mb, rspMsg);
	return true;
}

bool Guild::OnPBLobbyGateSetNicknamReq(EntityMailBox& sender_mb, ::google::protobuf::Message* pMsg)
{
	PBLobbyGateSetNicknamReq* pCmd = (PBLobbyGateSetNicknamReq*)pMsg;
	XLOG("GuildMgr::OnPBLobbyGateSetNicknamReq! uid:%d", pCmd->uid());

	UInt32 uid = pCmd->uid();
	auto pPlayerInfo = GetPlayerInfo(uid);
	if (!pPlayerInfo)
	{
		return true;
	}

	pPlayerInfo->m_GuildUserData.mutable_playersimpleinfo()->set_nick_name(pCmd->nickname());
	return true;
}

bool Guild::OnPBGuildModifyAnnouncementReqCmd(EntityMailBox& sender_mb, ::google::protobuf::Message* pMsg)
{
	PBGuildModifyAnnouncementReqCmd* pCmd = (PBGuildModifyAnnouncementReqCmd*)pMsg;
	XLOG("Guild::PBGuildModifyAnnouncementReqCmd! uid:%d", pCmd->uid());

	UInt32 uid = pCmd->uid();

	auto sNewAnnounncement = pCmd->newannouncement();

	auto pPlayerInfo = GetPlayerInfo(uid);
	if (!pPlayerInfo || !pPlayerInfo->IsOnline())
	{
		return true;
	}

	if (!IsPlayerHasRight(pPlayerInfo, enRT_ModifyAnnouncement))
	{//没有权限
		SendShowTextId(pPlayerInfo->mb, ERR_GUILD_U_NOT_HAVE_RIGHT);
		return true;
	}

	auto& guildinfo = GetGuildInfo();
	if (eGS_Normal != guildinfo.status()) {
		//公会状态不是Normal
		SendShowTextId(sender_mb, ERR_GUILD_IN_FREEZE_OR_DELETE);
		return true;
	}

	if (sNewAnnounncement.size() > 1024)
	{//公会公告过长
		SendShowTextId(sender_mb, ERR_GUILD_Announcement_TOOO_LONG);
		return true;
	}
	//过滤屏蔽字
	sNewAnnounncement = CStopWord::getMe().replaceStopWord(sNewAnnounncement);

	guildinfo.set_accouncenment(sNewAnnounncement);
	guildinfo.set_announcenmentlastmodifytime(time(0));


	//通知公会更新
	UpdateSimpleInfo2GuildMgr();

	//设置脏数据
	SetGuildDirty();

	PBGuildModifyAnnouncementRspCmd rspMsg;
	rspMsg.set_newannouncement(guildinfo.accouncenment());
	rspMsg.set_modify_time(guildinfo.announcenmentlastmodifytime());
	BoardcastMsgToClient(rspMsg);
	return true;
}

bool Guild::OnPBGuildAddDutyReqCmd(EntityMailBox& sender_mb, ::google::protobuf::Message* pMsg)
{
	PBGuildAddDutyReqCmd* pCmd = (PBGuildAddDutyReqCmd*)pMsg;
	XLOG("Guild::PBGuildAddDutyReqCmd! uid:%d", pCmd->uid());

	auto uid = pCmd->uid();
	auto playerInfo = GetPlayerInfo(uid);
	if (!playerInfo || !playerInfo->IsOnline())
	{
		return true;
	}

	if (!IsMaster(uid))
	{
		SendShowTextId(sender_mb, ERR_GUILD_NOT_MASTER);
		return true;
	}

	auto& duty_name = pCmd->duty_name();
	if (CStopWord::getMe().IsStopWord(duty_name))
	{
		XERR("Guild::OnPBGuildAddDutyReqCmd has stop word! newName=%s", duty_name.c_str());
		SendShowTextId(sender_mb, ERR_CANNOT_USE_STOP_WORD);
		return true;
	}

	auto pDutyList = m_guildInfo.mutable_duty_list();
	int nMaxDutyId = 2; //(0和1默认被系统职位占用),所以从2开始
	for (int i = 0; i < pDutyList->duty_list_size(); ++i)
	{
		auto& dutyInfo = pDutyList->duty_list(i);
		if (dutyInfo.duty_name() == duty_name)
		{//已存在相同名称的职位
			SendShowTextId(sender_mb, ERR_GUILD_DUTY_NAME_HAD_USED);
			return true;
		}

		if (dutyInfo.duty_id() > nMaxDutyId)
			nMaxDutyId = dutyInfo.duty_id();
	}

	auto pNewDutyInfo = pDutyList->add_duty_list();
	pNewDutyInfo->set_duty_name(duty_name);
	pNewDutyInfo->set_duty_id(nMaxDutyId + 1);
	pNewDutyInfo->set_duty_level(1);

	BoardcastDutyList();
	SetGuildDirty();

	PBGuildAddDutyRspCmd rspMsg;
	rspMsg.set_duty_name(duty_name);
	rspMsg.set_new_duty_id(pNewDutyInfo->duty_id());
	SendToClientEntity(sender_mb, rspMsg);
	return true;
}

bool Guild::OnPBGuildDelDutyReqCmd(EntityMailBox& sender_mb, ::google::protobuf::Message* pMsg)
{
	PBGuildDelDutyReqCmd* pCmd = (PBGuildDelDutyReqCmd*)pMsg;
	XLOG("Guild::OnPBGuildDelDutyReqCmd! uid:%d", pCmd->uid());

	auto duty_id = pCmd->duty_id();
	auto playerInfo = GetPlayerInfo(pCmd->uid());
	if (!playerInfo || !playerInfo->IsOnline())
	{
		return true;
	}

	if (!IsMaster(pCmd->uid()))
	{
		SendShowTextId(sender_mb, ERR_GUILD_NOT_MASTER);
		return true;
	}

	if (0 == duty_id || 1 == duty_id)
	{//这是系统职位，不能删除
		SendShowTextId(sender_mb, ERR_GUILD_CANNOT_DEL_SYSTEM_DUTY);
		return true;
	}

	auto dutyInfo = GetDutyInfo(duty_id);
	if (!dutyInfo)
	{//没找到这个职位
		SendShowTextId(sender_mb, ERR_GUILD_NOT_FIND_DUTY);
		return true;
	}

	if (0 == dutyInfo->duty_level() || 100 == dutyInfo->duty_level())
	{//这是系统职位，不能删除
		SendShowTextId(sender_mb, ERR_GUILD_CANNOT_DEL_SYSTEM_DUTY);
		return true;
	}

	for (auto& v : m_managerMap)
	{
		if (v.second == duty_id)
		{//找到这个职位的玩家。
			SendShowTextId(sender_mb, ERR_GUILD_DUTY_HAD_PLAYER);
			return true;
		}
	}

	auto pPBDutyList = m_guildInfo.mutable_duty_list();
	for (int i = 0; i < pPBDutyList->duty_list_size(); ++i)
	{
		auto pDutyInfo = pPBDutyList->mutable_duty_list(i);
		if (pDutyInfo->duty_id() == pCmd->duty_id())
		{
			pPBDutyList->mutable_duty_list()->DeleteSubrange(i, 1);

			BoardcastDutyList();
			SetGuildDirty();

			XLOG("Guild::OnPBGuildDelDutyReqCmd Succ! uid:%d, duty_id:%d", pCmd->uid(), pCmd->duty_id());

			PBGuildDelDutyRspCmd rspMsg;
			rspMsg.set_duty_id(pCmd->duty_id());
			SendToClientEntity(sender_mb, rspMsg);
			return true;
		}
	}

	SendShowTextId(sender_mb, ERR_GUILD_NOT_FIND_DUTY);
	return true;
}

bool Guild::OnPBGuildModifyDutyRightReqCmd(EntityMailBox& sender_mb, ::google::protobuf::Message* pMsg)
{
	PBGuildModifyDutyRightReqCmd* pCmd = (PBGuildModifyDutyRightReqCmd*)pMsg;
	XLOG("Guild::PBGuildModifyDutyRightReqCmd! uid:%d", pCmd->uid());
	auto uid = pCmd->uid();
	auto playerInfo = GetPlayerInfo(uid);
	if (!playerInfo || !playerInfo->IsOnline())
	{
		return true;
	}

	if (!IsMaster(uid))
	{//只有会长可以修改权限
		SendShowTextId(sender_mb, ERR_GUILD_NOT_MASTER);
		return true;
	}

	auto pDutyInfo = GetDutyInfo(pCmd->duty());
	if (!pDutyInfo)
	{
		SendShowTextId(sender_mb, ERR_GUILD_NOT_FIND_DUTY);
		return true;
	}

	uint64_t nDutyRight = pDutyInfo->duty_right();
	setFlag(nDutyRight, pCmd->newright(), pCmd->b_set());
	pDutyInfo->set_duty_right(nDutyRight);

	BoardcastDutyList();
	SetGuildDirty();

	PBGuildModifyDutyRightRspCmd rspMsg;
	rspMsg.set_newright(nDutyRight);
	rspMsg.set_duty(pCmd->duty());
	SendToClientEntity(sender_mb, rspMsg);
	return true;
}

bool Guild::OnPBGuildModifyDutyNameReqCmd(EntityMailBox& sender_mb, ::google::protobuf::Message* pMsg)
{
	PBGuildModifyDutyNameReq* pCmd = (PBGuildModifyDutyNameReq*)pMsg;
	XLOG("Guild::OnPBGuildModifyDutyLeOnPBGuildModifyDutyNameReqCmdvelReqCmd! uid:%d,duty_id:%d, new_name:%s", pCmd->uid(), pCmd->duty_id(), pCmd->new_name().c_str());

	auto uid = pCmd->uid();
	auto playerInfo = GetPlayerInfo(uid);
	if (!playerInfo || !playerInfo->IsOnline())
	{
		return true;
	}

	if (!IsMaster(uid))
	{//只有会长可以修改权限
		SendShowTextId(sender_mb, ERR_GUILD_NOT_MASTER);
		return true;
	}

	auto dutyInfo = GetDutyInfo(pCmd->duty_id());
	if (!dutyInfo)
	{//没有这个职位
		SendShowTextId(sender_mb, ERR_GUILD_NOT_FIND_DUTY);
		return true;
	}

	auto& newName = pCmd->new_name();
	if (newName.size() < 3 || newName.size() > 20)
	{
		SendShowTextId(sender_mb, ERR_GUILD_DUTY_NAME_LEN_ERROR);
		return true;
	}

	if (CStopWord::getMe().IsStopWord(newName))
	{
		XERR("Guild::OnPBGuildModifyDutyNameReqCmd has stop word! newName=%s", newName.c_str());
		SendShowTextId(sender_mb, ERR_CANNOT_USE_STOP_WORD);
		return true;
	}

	dutyInfo->set_duty_name(pCmd->new_name());

	BoardcastDutyList();
	SetGuildDirty();

	PBGuildModifyDutyNameRsp rspMsg;
	rspMsg.set_duty_id(pCmd->duty_id());
	rspMsg.set_new_name(newName);
	SendToClientEntity(sender_mb, rspMsg);
	return true;
}

bool Guild::OnPBGuildModifyDutyLevelReqCmd(EntityMailBox& sender_mb, ::google::protobuf::Message* pMsg)
{
	PBGuildModifyDutyLevelReq* pCmd = (PBGuildModifyDutyLevelReq*)pMsg;
	XLOG("Guild::OnPBGuildModifyDutyLevelReqCmd! uid:%d,duty_id:%d, new_level:%d", pCmd->uid(), pCmd->duty_id(), pCmd->new_level());
	auto uid = pCmd->uid();
	auto playerInfo = GetPlayerInfo(uid);
	if (!playerInfo || !playerInfo->IsOnline())
	{
		return true;
	}

	if (!IsMaster(uid))
	{//只有会长可以修改权限
		SendShowTextId(sender_mb, ERR_GUILD_NOT_MASTER);
		return true;
	}

	auto dutyInfo = GetDutyInfo(pCmd->duty_id());
	if (!dutyInfo)
	{//没有这个职位
		SendShowTextId(sender_mb, ERR_GUILD_NOT_FIND_DUTY);
		return true;
	}

	if (pCmd->new_level() >= 10)
	{
		SendShowTextId(sender_mb, ERR_GUILD_DUTY_LEVEL_ERROR);
		return true;
	}

	dutyInfo->set_duty_level(pCmd->new_level());

	BoardcastDutyList();
	SetGuildDirty();

	PBGuildModifyDutyLevelRsp rspMsg;
	rspMsg.set_duty_id(pCmd->duty_id());
	rspMsg.set_new_level(pCmd->new_level());
	SendToClientEntity(sender_mb, rspMsg);
	return true;
}

bool Guild::OnPBGuildUpgradeReqCmd(EntityMailBox& sender_mb, ::google::protobuf::Message* pMsg)
{
	PBGuildUpgradeReqCmd* pCmd = (PBGuildUpgradeReqCmd*)pMsg;
	XLOG("Guild::PBGuildUpgradeReqCmd! uid:%d", pCmd->uid());
	return true;
}

bool Guild::OnPBGuildSendChatReqCmd(EntityMailBox& sender_mb, ::google::protobuf::Message* pMsg)
{
	PBSendChatReqCmd* pCmd = (PBSendChatReqCmd*)pMsg;
	XLOG("Guild::OnPBGuildSendChatReqCmd! uid:%d", pCmd->uid());

	auto playerInfo = GetPlayerInfo(pCmd->uid());
	if (!playerInfo || !playerInfo->IsOnline())
	{
		return true;
	}

	auto pChatMsg = m_chatList.add_chat_list();
	pChatMsg->set_uid(playerInfo->m_nPlayerDbid);
	pChatMsg->set_nickname(playerInfo->m_GuildUserData.playersimpleinfo().nick_name());
	pChatMsg->set_chatmsg(pCmd->chatmsg());
	pChatMsg->set_role_title_id(pCmd->role_title_id());
	pChatMsg->set_title_id(pCmd->title_id());

	auto chat_channel = pCmd->chat_channel();
	//延迟1秒
	m_chatDelay.SetDelay(1, [this, chat_channel]() {
		PBSendChatRspCmd rspMsg;
		rspMsg.set_chat_channel(chat_channel);
		*rspMsg.mutable_chat_list() = m_chatList;
		BoardcastMsgToClient(rspMsg);

		m_chatList.Clear();
		});
	return true;
}

bool Guild::OnPBGuildUpgradeMemberMaxcountReq(EntityMailBox& sender_mb, ::google::protobuf::Message* pMsg)
{
	PBGuildUpgradeMemberMaxcountReq* pCmd = (PBGuildUpgradeMemberMaxcountReq*)pMsg;
	XLOG("Guild::OnPBGuildUpgradeMemberMaxcountReq! uid:%d", pCmd->uid());

	auto playerInfo = GetPlayerInfo(pCmd->uid());
	if (!playerInfo || !playerInfo->IsOnline())
	{
		return true;
	}

	auto member_num_level = m_guildInfo.member_num_level();
	if (member_num_level <= 0)
		member_num_level = 1;
	auto pConfig = GuildMemberNumDataMgr::getMe().GetConfig(member_num_level);
	if (!pConfig)
	{
		SendShowTextId(sender_mb, ERR_GUILD_CONFIG_ERROR);
		return true;
	}

	int nSucess = 0;
	if (GetItemCount(SCT_Guild_GuBi) >= pConfig->cfg->cost && GetItemCount(SCT_Guild_LingBi) >= pConfig->cfg->cost2)
	{
		DelItem(SCT_Guild_GuBi, pConfig->cfg->cost, RD_GuildUpGrageMember);
		DelItem(SCT_Guild_LingBi, pConfig->cfg->cost2, RD_GuildUpGrageMember);
		UpdateGuildBag();
		nSucess = 1;
		m_guildInfo.set_member_max_num(pConfig->cfg->num + pConfig->cfg->num_up);
		m_guildInfo.set_member_num_level(member_num_level + 1);
	}
	else
	{
		SendShowTextId(sender_mb, ERR_GUILD_GUBI_LINGBI_NOT_ENOUGH);
		return true;
	}

	UpdateSimpleInfo2GuildMgr();
	SetGuildDirty();
	PBGuildUpgradeMemberMaxcountRsp rspMsg;
	rspMsg.set_cur_member_maxcount(m_guildInfo.member_max_num());
	rspMsg.set_sucucess(nSucess);
	SendToClientEntity(sender_mb, rspMsg);
	return true;
}

bool Guild::OnPBGuildDonateReq(EntityMailBox& sender_mb, ::google::protobuf::Message* pMsg)
{
	//直接关闭
	//return true;

	PBGuildDonateReq* pCmd = (PBGuildDonateReq*)pMsg;
	XLOG("Guild::OnPBGuildDonateReq! uid:%d", pCmd->uid());
	uint32_t uid = pCmd->uid();
	auto playerInfo = GetPlayerInfo(uid);
	if (!playerInfo || !playerInfo->IsOnline())
	{
		return true;
	}
	auto now = time(nullptr);
	if (now - playerInfo->m_GuildUserData.guild_data().join_time() < GuildNewMemberDonateTime)
	{
		//新成员要3天才能捐赠
		SendShowTextId(sender_mb, ERR_GUILD_NEW_MEMBER_3DAY);
		return true;
	}

	uint32_t nDonateNum = pCmd->num();
	if (nDonateNum < 0)
	{
		return true;
	}
	uint32_t nItem_Id = pCmd->item_id();
	PBRpcData_ReduceConsum_Req reqData;
	reqData.set_config_id(nItem_Id);
	reqData.set_reduce_count(nDonateNum);
	reqData.set_reason(RD_GuildDonate);
	auto pConfig = SkinConfigDataMgr::getMe().GetConfig(nItem_Id);
	if (pConfig && pConfig->cfg->effect_type > 0)
	{
		//effect_type 不为0，不能交易
		SendShowTextId(sender_mb, ERR_GUILD_OP_ITEM_BIND);
		return true;
	}
	if (nItem_Id == SCT_LingBi || nItem_Id == SCT_LingShi)
	{

	}
	else
	{
		if (m_guildInfo.has_open_juanzeng() && m_guildInfo.open_juanzeng())
		{
			//打开了捐赠的战队可以捐物品
		}
		else
		{
			SendShowTextId(sender_mb, ERR_GUILD_OP_ITEM_BIND);
			return true;
		}

	}
	SearchUserMgr::ExeGateUserRpcCall(playerInfo->mb, reqData, [nDonateNum, &sender_mb, playerInfo, uid, nItem_Id, this](bool bSucess, const std::string& rspParam)
		{
			if (!bSucess)
			{
				XLOG("SearchUserMgr::ExeGateUserRpcCall uid:%d fail itemid:%d,donatenum:%d", uid, nItem_Id, nDonateNum);
				return;
			}
			uint32_t nContributeNum = 0;

			if (nItem_Id == SCT_LingBi)
			{
				//捐灵币
				nContributeNum = nDonateNum * 12 / 10000;
				AddItem(SCT_Guild_LingBi, nDonateNum, RD_GuildDonate);
				PlayerAddContribute(uid, nContributeNum, RD_GuildDonate);
			}
			else if (nItem_Id == SCT_LingShi)
			{
				nContributeNum = nDonateNum * 12 / 100;
				//捐灵石
				AddItem(SCT_Guild_GuBi, nDonateNum, RD_GuildDonate);
				PlayerAddContribute(uid, nContributeNum, RD_GuildDonate);
			}
			else
			{
				//捐战利品
				AddItem(nItem_Id, nDonateNum, RD_GuildDonate);

				auto pConfig = SkinConfigDataMgr::getMe().GetConfig(nItem_Id);
				if (pConfig)
				{//如果是皮肤，要做绑定转化

					//绑定的Skin ID(base_skin_id)
					auto base_skin_id = pConfig->cfg->base_skin_id;
					if (base_skin_id > 0)
					{
						//pConfig->consume
						for (auto& item : pConfig->consume)
						{
							if (item.config_id == SCT_LingShi)
							{
								nContributeNum = item.item_count * nDonateNum * 12 / 100;
								PlayerAddContribute(uid, nContributeNum, RD_GuildDonate);
								break;
							}
						}
					}


				}

			}
			UpdateGuildBag();
			//存入一条记录
			//添加公会记录
			PBGuildRecordInfo record;
			record.set_record_type(ERT_JUANZENG);
			record.set_nickname(playerInfo->GetNickname());
			record.set_target_uid(uid);
			record.set_gubi_num(nDonateNum);
			record.set_contribute(nContributeNum);
			record.set_item_id(nItem_Id);
			AddGuildRecord(record);


			//更新自己的公会信息
			UpdateGuildUserData(playerInfo);
			PBGuildDonateRsp rspMsg;
			rspMsg.set_num(nDonateNum);
			rspMsg.set_item_id(nItem_Id);
			SendToClientEntity(sender_mb, rspMsg);
		});

	return true;
}

bool Guild::UpdateGuildUserData(GuildPlayerInfo* playerInfo)
{
	if (!playerInfo)
		return false;
	//playerInfo->m_GuildUserData.mutable_guild_data()->set_bspoilsmgr(playerInfo->IsSpoilsMgr());
	playerInfo->m_GuildUserData.mutable_guild_data()->set_bspoilsmgr(false);
	for (int i = 0; i < m_guildInfo.spoilsmgr_ids_size(); i++)
	{
		auto tid = m_guildInfo.spoilsmgr_ids().Get(i);
		if (tid == playerInfo->m_nPlayerDbid)
		{
			playerInfo->m_GuildUserData.mutable_guild_data()->set_bspoilsmgr(true);
			break;
		}
	}
	PBGuildUpdateGuildUserData updateDataMsg;
	*updateDataMsg.mutable_user_data() = playerInfo->m_GuildUserData.guild_data();
	SendToClientEntity(playerInfo->mb, updateDataMsg);
	return true;
}

bool Guild::UpdateGuildBag()
{
	m_GuildBagDelay.SetDelay(3, [this]()
		{
			GenGuildBag();
			PBGuildUpdateGuildBagCmd updateMsg;
			*updateMsg.mutable_items() = m_guildInfo.guild_bag();
			BoardcastMsgToClient(updateMsg);
		});
	return true;
}

bool Guild::OnPBGuildGetSalaryReq(EntityMailBox& sender_mb, ::google::protobuf::Message* pMsg)
{
	PBGuildGetSalaryReq* pCmd = (PBGuildGetSalaryReq*)pMsg;
	XLOG("Guild::OnPBGuildGetSalaryReq! uid:%d", pCmd->uid());

	auto playerInfo = GetPlayerInfo(pCmd->uid());
	if (!playerInfo || !playerInfo->IsOnline())
	{
		return true;
	}
	time_t now = time(nullptr);
	if (xTime::isSameDay(now, playerInfo->m_GuildUserData.guild_data().last_get_salary_time()))
	{//如果是同一天，不能重复领取
		SendShowTextId(sender_mb, ERR_GUILD_SALARY_AREADY_GET);
		return true;
	}
	if (now - playerInfo->m_GuildUserData.guild_data().join_time() < GuildNewMemberGetSalaryTime)
	{
		//新成员要72小时候才能领工资
		SendShowTextId(sender_mb, ERR_GUILD_SALARY_NEWMEMBER);
		return true;
	}

	uint32_t nMemberCount = m_guildInfo.member_count();
	if (nMemberCount < 1)
	{
		return true;
	}

	auto nNeedGuBiCount = GetItemCount(SCT_Guild_GuBi) / (30 * nMemberCount);
	auto nLingBiCount = GetItemCount(SCT_Guild_LingBi) / (30 * nMemberCount);
	if (nNeedGuBiCount < 5 && nLingBiCount < 50)
	{
		SendShowTextId(sender_mb, ERR_GUILD_ZIJIN_NOT_ENOUGH);
		return true;
	}

	PBGuildGetSalaryRsp rspMsg;

	if (nNeedGuBiCount >= 5)
	{
		//扣除公会的古币和灵币
		DelItem(SCT_Guild_GuBi, nNeedGuBiCount, RD_GuildGetSalary);

		auto pItem = rspMsg.mutable_get_items()->add_item_list();
		pItem->set_config_id(SCT_GuBi);
		pItem->set_item_count(nNeedGuBiCount);
	}

	if (nLingBiCount >= 50)
	{
		DelItem(SCT_Guild_LingBi, nLingBiCount, RD_GuildGetSalary);
		auto pItem2 = rspMsg.mutable_get_items()->add_item_list();
		pItem2->set_config_id(SCT_LingBi);
		pItem2->set_item_count(nLingBiCount);

	}
	UpdateGuildBag();
	playerInfo->m_GuildUserData.mutable_guild_data()->set_last_get_salary_time(now);
	SendToEntity(sender_mb, rspMsg);
	return true;
}

bool Guild::OnPBGuildModifyGuildNameReqCmd(EntityMailBox& sender_mb, ::google::protobuf::Message* pMsg)
{
	PBGuildModifyGuildNameReqCmd* pCmd = (PBGuildModifyGuildNameReqCmd*)pMsg;
	XLOG("Guild::OnPBGuildModifyGuildNameReqCmd! uid:%d", pCmd->uid());

	auto playerInfo = GetPlayerInfo(pCmd->uid());
	if (!playerInfo)
	{//玩家不在线或不存在
		return true;
	}

	if (!IsMaster(pCmd->uid()))
	{//只有会长可以修改名称
		SendShowTextId(sender_mb, ERR_GUILD_NOT_MASTER);
		return true;
	}
	auto nNeedGuBiCount = GetItemCount(SCT_Guild_GuBi);

	if (nNeedGuBiCount < ModifyGuildNameCostGuBi)
	{
		SendShowTextId(sender_mb, ERR_GUILD_GU_BI_NOT_ENOUGH);
		return true;
	}


	int nColdTime = time(0) - m_guildInfo.namelastmodifytime();
	if (nColdTime < ModifyGuildNameCold)
	{
		std::vector<string> sParams;
		sParams.push_back(std::to_string(ceil(nColdTime / 3600.0f)));

		SendShowTextId(sender_mb, ERR_GUILD_MODIFYNAME_COLD, sParams);
		return true;
	}
	//转发给GuildMgr验证是否重名等
	SendToGlobalEntity("GuildMgr", *pCmd);
	return true;
}

bool Guild::OnPBGuildModifyGuildNameRspCmd(EntityMailBox& sender_mb, ::google::protobuf::Message* pMsg)
{
	PBGuildModifyGuildNameRspCmd* pCmd = (PBGuildModifyGuildNameRspCmd*)pMsg;
	XLOG("Guild::OnPBGuildModifyGuildNameRspCmd! uid:%d", pCmd->uid());
	m_guildInfo.set_name(pCmd->newname());
	m_guildInfo.set_namelastmodifytime(time(0));
	//扣除公会的古币
	DelItem(SCT_Guild_GuBi, ModifyGuildNameCostGuBi, RD_GuildChangeName);
	UpdateGuildBag();

	UpdateSimpleInfo2GuildMgr();
	//广播改名消息（给全公会玩家）
	BoardcastMsgToClient(*pCmd);

	//auto playerInfo = GetPlayerInfo(pCmd->uid());
	//if (!playerInfo)
	//{//玩家不在线或不存在
	//	return true;
	//}

	//SendToClientEntity(playerInfo->mb, *pCmd);


	return true;
}

bool Guild::OnPBGuildAddItems(EntityMailBox& sender_mb, ::google::protobuf::Message* pMsg)
{
	PBGuildAddItems* pCmd = (PBGuildAddItems*)pMsg;
	XLOG("Guild::OnPBGuildAddItems! guild_id:%d", m_guild_id);

	for (auto i = 0; i < pCmd->mutable_items()->item_list_size(); ++i)
	{
		auto& pbItem = pCmd->mutable_items()->item_list(i);
		AddItem(pbItem.config_id(), pbItem.item_count(), RD_GM);
	}
	UpdateGuildBag();
	return true;
}

bool Guild::OnPBGuildDelItems(EntityMailBox& sender_mb, ::google::protobuf::Message* pMsg)
{
	PBGuildDelItems* pCmd = (PBGuildDelItems*)pMsg;
	XLOG("Guild::OnPBGuildDelItems! guild_id:%d", m_guild_id);

	for (auto i = 0; i < pCmd->mutable_items()->item_list_size(); ++i)
	{
		auto& pbItem = pCmd->mutable_items()->item_list(i);
		DelItem(pbItem.config_id(), pbItem.item_count(), RD_GM);
	}
	UpdateGuildBag();
	return true;
}

bool Guild::OnPBSetGuildJoinConditionCmd(EntityMailBox& sender_mb, ::google::protobuf::Message* pMsg)
{
	PBSetGuildJoinConditionReqCmd* pCmd = (PBSetGuildJoinConditionReqCmd*)pMsg;
	XLOG("Guild::OnPBSetGuildJoinConditionCmd! guild_id:%d", m_guild_id);

	auto playerInfo = GetPlayerInfo(pCmd->uid());
	if (!playerInfo)
	{//玩家不在线或不存在
		return true;
	}
	if (!IsPlayerHasRight(playerInfo, enRT_ModifyApplyCondition))
	{
		SendShowTextId(sender_mb, ERR_GUILD_U_NOT_HAVE_RIGHT);
		return true;
	}
	string sNewAnnounncement = pCmd->joincon().notice();
	if (sNewAnnounncement.size() > 1024)
	{//公会公告过长
		SendShowTextId(sender_mb, ERR_GUILD_Announcement_TOOO_LONG);
		return true;
	}
	//过滤屏蔽字
	sNewAnnounncement = CStopWord::getMe().replaceStopWord(sNewAnnounncement);
	pCmd->mutable_joincon()->set_notice(sNewAnnounncement);
	*m_guildInfo.mutable_join_con() = pCmd->joincon();
	UpdateSimpleInfo2GuildMgr();
	//设置脏数据
	SetGuildDirty();


	PBSetGuildJoinConditionRspCmd rspMsg;
	*rspMsg.mutable_joincon() = pCmd->joincon();
	SendToClientEntity(sender_mb, rspMsg);
	return true;

}

bool Guild::OnPBGuildRecordListReq(EntityMailBox& sender_mb, ::google::protobuf::Message* pMsg)
{
	PBGuildRecordListReq* pCmd = (PBGuildRecordListReq*)pMsg;
	auto playerInfo = GetPlayerInfo(pCmd->uid());
	if (!playerInfo)
	{//玩家不在线或不存在
		return true;
	}
	/*if (pCmd->bmanager() && !IsSpoilsMgr(playerInfo))
	{
		SendShowTextId(sender_mb, ERR_GUILD_U_NOT_HAVE_RIGHT);
		return true;
	}*/
std:; vector<PBGuildRecordInfo*> vecRecord;
	int nTotal = m_guildInfo.record_list().record_list_size();
	vecRecord.reserve(nTotal);
	for (int i = 0; i < nTotal; i++)
	{
		auto p = m_guildInfo.mutable_record_list()->mutable_record_list(i);
		if (!p)
			continue;
		//玩家过滤
		/*if (pCmd->bmanager())
		{*/

		if (pCmd->des_uid() != 0 && p->target_uid() != pCmd->des_uid())
			continue;
		/*}*/
	/*	else
		{
			if(pCmd->uid()!=p->target_uid())
				continue;
		}*/
		//记录类型过滤
		if (pCmd->etype() != eRT_ALL_RECORD && !isSetFlag(pCmd->etype(), p->record_type()))
			continue;
		vecRecord.push_back(p);
	}
	//排序
	uint32_t page_count = pCmd->pagecount();
	if (page_count <= 0 || page_count > 50)
		page_count = 50;

	auto nIdx = pCmd->idx();

	auto nStartIndex = page_count * nIdx;
	auto nEndIndex = page_count * (nIdx + 1);

	if (pCmd->b_asc())
	{
		if (pCmd->sort_type() == 1)
		{
			std::sort(vecRecord.begin(), vecRecord.end(), [&](PBGuildRecordInfo* lhs, PBGuildRecordInfo* rhs) {return lhs->record_time() > rhs->record_time(); });
		}
		else if (pCmd->sort_type() == 2)
		{
			std::sort(vecRecord.begin(), vecRecord.end(), [&](PBGuildRecordInfo* lhs, PBGuildRecordInfo* rhs) {return lhs->nickname() > rhs->nickname(); });
		}
	}
	else
	{
		if (pCmd->sort_type() == 1)
		{
			std::sort(vecRecord.begin(), vecRecord.end(), [&](PBGuildRecordInfo* lhs, PBGuildRecordInfo* rhs) {return lhs->record_time() < rhs->record_time(); });
		}
		else if (pCmd->sort_type() == 2)
		{
			std::sort(vecRecord.begin(), vecRecord.end(), [&](PBGuildRecordInfo* lhs, PBGuildRecordInfo* rhs) {return lhs->nickname() < rhs->nickname(); });
		}
	}
	PBGuildRecordListRsp rspMsg;
	rspMsg.set_etype(pCmd->etype());
	rspMsg.set_idx(pCmd->idx());
	rspMsg.set_uid(pCmd->des_uid());
	rspMsg.set_sort_type(pCmd->sort_type());
	rspMsg.set_ntotalcount(vecRecord.size());
	rspMsg.set_pagecount(page_count);

	int i = 0;
	for (auto& v : vecRecord)
	{
		if (i >= nEndIndex)
		{
			break;
		}

		if (i >= nStartIndex)
		{
			*rspMsg.mutable_record_list()->add_record_list() = *v; //= *v;
		}
		++i;
	}


	//发送给玩家
	SendToClientEntity(sender_mb, rspMsg);
	return true;
}

bool Guild::OnPBGuildSetSpoilsMgrReq(EntityMailBox& sender_mb, ::google::protobuf::Message* pMsg)
{
	PBGuildSetSpoilsMgrReq* pCmd = (PBGuildSetSpoilsMgrReq*)pMsg;
	XLOG("Guild::OnPBGuildSetSpoilsMgrReq! uid:%d", pCmd->uid());

	auto playerInfo = GetPlayerInfo(pCmd->uid());
	if (!playerInfo)
	{//玩家不在线或不存在
		return true;
	}
	if (!IsMaster(pCmd->uid())) {
		//不是公会长
		SendShowTextId(playerInfo->mb, ERR_GUILD_NOT_MASTER);
		return true;
	}
	uint32_t des_id = pCmd->des_uid();
	if (pCmd->uid() == des_id) {
		SendShowTextId(playerInfo->mb, ERR_GUILD_SET_SPOIL_SELF);
		return true;
	}
	int errcode = 0;
	if (!SetSpoiMgr(des_id, pCmd->bset(), errcode))
		SendShowTextId(playerInfo->mb, errcode);

	SetGuildDirty();
	auto Des_playerInfo = GetPlayerInfo(des_id);
	if (Des_playerInfo)
	{
		UpdateGuildUserData(Des_playerInfo);
	}


	//SendToClientEntity(sender_mb, rspMsg);
	return true;

}
bool Guild::OnPBGuildDkpChangeReq(EntityMailBox& sender_mb, ::google::protobuf::Message* pMsg)
{
	PBGuildDkpChangeReq* pCmd = (PBGuildDkpChangeReq*)pMsg;
	XLOG("Guild::OnPBGuildSetSpoilsMgrReq! uid:%d", pCmd->uid());

	auto playerInfo = GetPlayerInfo(pCmd->uid());
	if (!playerInfo)
	{//玩家不在线或不存在
		return true;
	}
	auto Des_playerInfo = GetPlayerInfo(pCmd->des_uid());
	if (!Des_playerInfo)
	{
		return true;
	}
	//权限判断
	if (!IsSpoilsMgr(playerInfo))
	{
		SendShowTextId(sender_mb, ERR_GUILD_U_NOT_HAVE_RIGHT);
		return true;
	}
	//扣灵币
	auto nLingBiCount = GetItemCount(SCT_Guild_LingBi);
	if (nLingBiCount < 100)
	{
		SendShowTextId(sender_mb, ERR_GUILD_LING_BI_NOT_ENOUGH);
		return true;
	}
	//修改后玩家的dkp值应大于0
	int32_t nCurNum = pCmd->changenum() + Des_playerInfo->m_GuildUserData.guild_data().dkp();
	if (nCurNum < 0)
	{
		SendShowTextId(sender_mb, ERR_GUILD_SET_DKP_VALUE);
		return true;
	}

	DelItem(SCT_Guild_LingBi, 100, RD_GuildModifyDKP);
	UpdateGuildBag();
	UpdateSimpleInfo2GuildMgr();

	Des_playerInfo->m_GuildUserData.mutable_guild_data()->set_dkp(nCurNum);
	SetGuildDirty();
	UpdateGuildUserData(Des_playerInfo);
	//添加公会记录
	PBGuildRecordInfo record;
	record.set_record_type(ERT_GUILDGKD);
	record.set_nickname(Des_playerInfo->m_GuildUserData.playersimpleinfo().nick_name());
	record.set_target_uid(pCmd->des_uid());
	record.set_gkd_change_num(pCmd->changenum());
	record.set_gkd_cur_num(nCurNum);
	record.set_gkd_desc(pCmd->desc());
	AddGuildRecord(record);

	//反馈回去
	PBGuildDkpChangeRsp rspMsg;
	rspMsg.set_changenum(pCmd->changenum());
	rspMsg.set_des_uid(pCmd->des_uid());
	rspMsg.set_curdkp(nCurNum);
	rspMsg.set_desc(pCmd->desc());
	SendToClientEntity(sender_mb, rspMsg);


	return true;
}
bool Guild::OnPBGuildGetApplyListReqCmd(EntityMailBox& sender_mb, ::google::protobuf::Message* pMsg)
{
	PBGuildGetApplyListReqCmd* pCmd = (PBGuildGetApplyListReqCmd*)pMsg;
	XLOG("Guild::OnPBGuildGetApplyListReqCmd! uid:%d", pCmd->uid());

	auto playerInfo = GetPlayerInfo(pCmd->uid());
	if (!playerInfo)
	{//玩家不在线或不存在
		return true;
	}

	if (!IsPlayerHasRight(playerInfo, enRT_AnswerApply))
	{//没有权限
		SendShowTextId(playerInfo->mb, ERR_GUILD_U_NOT_HAVE_RIGHT);
		return true;
	}

	if (eGS_Normal != m_guildInfo.status()) {
		//公会已冻结或删除
		SendShowTextId(sender_mb, ERR_GUILD_IN_FREEZE_OR_DELETE);
		return false;
	}

	PBGuildGetApplyListRspCmd rspMsg;
	for (auto& v : m_ApplyList)
	{
		*rspMsg.mutable_applylist()->add_apply_list() = v.second;
	}

	SendToClientEntity(sender_mb, rspMsg);
	return true;
}

bool Guild::OnPBGuildGetMembersReq(EntityMailBox& sender_mb, ::google::protobuf::Message* pMsg)
{
	PBGuildGetMembersReq* pCmd = (PBGuildGetMembersReq*)pMsg;
	XLOG("Guild::OnPBGuildGetMembersReq! page:%d", pCmd->npage());

	enum { MAX_MEMBER_COUNT = 500 };
	auto nPage = pCmd->npage();

	PBGuildGetMembersRsp rspMsg;

	int i = 0;
	for (auto& v : m_PlayerList)
	{
		auto bHasSimpleInfo = v.second.m_GuildUserData.has_playersimpleinfo();
		if (!bHasSimpleInfo) {
			continue;
		}
		auto bHasNickName = v.second.m_GuildUserData.playersimpleinfo().has_nick_name();
		if (!bHasNickName) {
			continue;
		}

		auto size = v.second.m_GuildUserData.mutable_playersimpleinfo()->mutable_nick_name()->size();
		if (size <= 0 || size >= 50) {
			continue;
		}

		*rspMsg.mutable_members()->add_member_list() = v.second.m_GuildUserData;

		++i;
		if (i >= MAX_MEMBER_COUNT)
		{
			SendToClientEntity(sender_mb, rspMsg);
			i = 0;
			rspMsg.Clear();
		}
	}

	if (i > 0)
	{
		SendToClientEntity(sender_mb, rspMsg);
	}
	return true;
}


bool Guild::OnPBGuildApplyJoinGuildReqCmd(EntityMailBox& sender_mb, ::google::protobuf::Message* pMsg)
{
	PBGuildApplyJoinGuildReqCmd* pCmd = (PBGuildApplyJoinGuildReqCmd*)pMsg;
	XLOG("Guild::OnPBGuildApplyJoinGuildReqCmd! uid:%d", pCmd->uid());

	if (eGS_Normal != m_guildInfo.status()) {
		//公会状态不是Normal
		SendShowTextId(pCmd->applyer_mb(), ERR_GUILD_IN_FREEZE_OR_DELETE);
		return false;
	}
	if (m_guildInfo.has_join_con())
	{
		auto& con = m_guildInfo.join_con();
		if (con.bcanjoin() == false)
		{
			SendShowTextId(pCmd->applyer_mb(), ERR_GUILD_CON_CANJOIN_ERROR);
			return false;
		}

		//最低总星星
		auto& ghost_grade = pCmd->simple_info().rank_level().ghost_rank();
		auto& human_grade = pCmd->simple_info().rank_level().human_rank();

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
			SendShowTextId(pCmd->applyer_mb(), ERR_GUILD_CON_JOIN_RANKLEVEL_ERROR);
			return false;
		}

		//最低等级
		if (pCmd->simple_info().account_level() < con.minlevel())
		{
			SendShowTextId(pCmd->applyer_mb(), ERR_GUILD_CON_JOIN_LEVEL_ERROR);
			return false;
		}


	}
	auto uid = pCmd->uid();
	if (pCmd->b_apply())
	{   // 如果加入条件无需审核
		if (m_guildInfo.has_join_con())
		{
			auto& con = m_guildInfo.join_con();
			if (!con.has_bjoincheck() || con.bjoincheck() == false)
			{
				if (m_PlayerList.size() >= m_guildInfo.member_max_num())
				{//超过最大人数
					SendShowTextId(sender_mb, ERR_GUILD_MAX_GUILD_MEMBER_COUNT);
					return true;
				}
				//玩家直接加入公会
				PlayerJoin(uid);
				return true;
			}
		}
		else
		{
			if (m_PlayerList.size() >= m_guildInfo.member_max_num())
			{//超过最大人数
				SendShowTextId(sender_mb, ERR_GUILD_MAX_GUILD_MEMBER_COUNT);
				return true;
			}
			//玩家直接加入公会
			PlayerJoin(uid);
			return true;
		}

		//申请加入公会
		if (!AddApplyInfo(uid, pCmd->simple_info()))
		{
			SendShowTextId(pCmd->applyer_mb(), ERR_GUILD_U_HAD_APPLY_GUILD);
			return true;
		}
	}
	else
	{//取消申请加入
		if (!DelApplyInfo(uid))
		{
			SendShowTextId(pCmd->applyer_mb(), ERR_GUILD_NOT_APPLY_GUILD);
			return true;
		}
	}
	//判断是否一周内被拒绝过
	/*if (m_rejectApply.find(uid) != m_rejectApply.end())
	{
		if (time(0) - m_rejectApply[uid] < 7 * 24 * 3600)
		{
			SendShowTextId(pCmd->applyer_mb(), ERR_GUILD_APPLY_REJECT_CD);
			return true;
		}
	}*/


	NotifyManagerApply();

	PBGuildApplyJoinGuildRspCmd rspMsg;
	rspMsg.set_guildid(m_guild_id);
	SendToClientEntity(pCmd->applyer_mb(), rspMsg);
	return true;
}

void Guild::NotifyManagerApply()
{
	PBGuildBoardcastPlayerApply notifyApply;
	notifyApply.set_apply_count(m_ApplyList.size());

	auto masterInfo = GetPlayerInfo(m_guildInfo.president_id());
	if (masterInfo && masterInfo->IsOnline())
	{//通知会长
		SendToClientEntity(masterInfo->mb, notifyApply);
	}
	for (auto& v : m_PlayerList)
	{
		auto uinfo = v.second;
		if (uinfo.IsOnline() && IsPlayerHasRight(&uinfo, enRT_AnswerApply))
		{
			SendToClientEntity(uinfo.mb, notifyApply);
		}
	}

}

void Guild::NotifyPlayerJoin(GuildPlayerInfo& playerInfo)
{
	//广播玩家进入
	PBGuildBoardcastPlayerJoin joinMsg;
	joinMsg.set_guild_id(m_guild_id);
	*joinMsg.mutable_user_info() = playerInfo.m_GuildUserData;
	BoardcastMsgToClient(joinMsg);

	//通知GuildMgr
	SendToGlobalEntity("GuildMgr", joinMsg);

	//通知公会更新
	UpdateSimpleInfo2GuildMgr();
}


void Guild::NotifyPlayerExit(uint32_t uid)
{
	PBGuildBoardcastPlayerExit exitMsg;
	exitMsg.set_guild_id(m_guild_id);
	exitMsg.set_uid(uid);

	BoardcastMsgToClient(exitMsg);

	//通知GuildMgr
	SendToGlobalEntity("GuildMgr", exitMsg);

	//通知公会更新
	UpdateSimpleInfo2GuildMgr();
}

//通知公会解散消息
void Guild::NotifyGuildDismiss()
{
	PBGuildBoardcastGuildDismiss dismissMsg;
	dismissMsg.set_guild_id(m_guild_id);
	//通知公会玩家，公会解散。
	//BoardcastMsgToClient(dismissMsg);

	//通知GuildMgr，这个公会解散了
	SendToGlobalEntity("GuildMgr", dismissMsg);

	//通知公会更新
	UpdateSimpleInfo2GuildMgr();
}


void Guild::UpdateApplyInfo2GuildMgr(eApplyOpt opt, uint32_t uid, uint64_t apply_time)
{
	PBGuildUpdateApplyList2GuildMgr updateApplyMsg;
	updateApplyMsg.mutable_apply_info()->set_apply_time(apply_time);
	updateApplyMsg.mutable_apply_info()->set_guild_id(m_guild_id);
	updateApplyMsg.set_uid(uid);
	updateApplyMsg.set_opt(opt);
	SendToGlobalEntity("GuildMgr", updateApplyMsg);
}

//发送提示文字接口
void Guild::SendShowTextId(const EntityMailBox& mb, uint32_t nTextId, const std::vector<string>& params)
{
	PBShowTextID showTextMsg;
	showTextMsg.set_ntextid(nTextId);
	for (auto& str : params)
		showTextMsg.add_params(str);
	SendToClientEntity(mb, showTextMsg);
}
//发送提示文字接口
void Guild::SendShowTextId(const EntityMailBox& mb, uint32_t nTextId)
{
	PBShowTextID showTextMsg;
	showTextMsg.set_ntextid(nTextId);
	SendToClientEntity(mb, showTextMsg);
}


bool Guild::IsSpoilsMgr(GuildPlayerInfo* pPlayerInfo)
{
	if (!pPlayerInfo)
		return false;
	if (IsMaster(pPlayerInfo->m_nPlayerDbid))
		return true;
	for (int i = 0; i < m_guildInfo.spoilsmgr_ids_size(); i++)
	{
		auto tid = m_guildInfo.spoilsmgr_ids().Get(i);
		if (tid == pPlayerInfo->m_nPlayerDbid)
			return true;
	}
	return false;
}


void Guild::AddGuildActiveness(uint32_t nValue, ReasonDef rf)
{
	AddItem(SCT_Guild_Activeness, nValue, rf);
	m_guildInfo.set_activeness(GetItemCount(SCT_Guild_Activeness));

	uint32_t nLevel = m_guildInfo.level();
	uint32_t nExp = m_guildInfo.activeness();
	uint32_t nNextLev = nLevel + 1;
	uint32_t nTobeLevel = nLevel;

	auto pNode = GuildExpConfigManager::getMe().GetConfigNode(nNextLev);
	int i = 0;
	while (pNode && i < 1000)
	{
		i++;
		if (nExp >= pNode->EXP)
		{
			nTobeLevel = nNextLev;
		}
		else
		{
			break;
		}
		nNextLev++;
		pNode = GuildExpConfigManager::getMe().GetConfigNode(nNextLev);
	}
	m_guildInfo.set_level(nTobeLevel);
	UpdateGuildBag();
	//通知公会更新
	UpdateSimpleInfo2GuildMgr();
	SetGuildDirty();
}

void Guild::AddGuildContribute(uint32_t nValue, ReasonDef rf)
{
	//公会贡献值增加
	AddItem(SCT_Guild_Contribution, nValue, RD_GuildDonate);
	//公会活跃度增加
	int nCurContribution = GetItemCount(SCT_Guild_Contribution);
	int nActive = (nCurContribution - m_guildInfo.contribute()) / 20;
	if (nActive > 0)
	{
		AddGuildActiveness(nActive, RD_GuildContribute);
		m_guildInfo.set_activeness(GetItemCount(SCT_Guild_Activeness));
		m_guildInfo.set_contribute(m_guildInfo.contribute() + 20 * nActive);
	}
	UpdateGuildBag();
	//通知公会更新
	UpdateSimpleInfo2GuildMgr();
	SetGuildDirty();
}

PBGuildDutyInfo* Guild::GetDutyInfo(uint32_t nDutyId)
{
	auto pPBDutyList = m_guildInfo.mutable_duty_list();
	for (int i = 0; i < pPBDutyList->duty_list_size(); ++i)
	{
		auto pDutyInfo = pPBDutyList->mutable_duty_list(i);
		if (pDutyInfo->duty_id() == nDutyId)
		{
			return pDutyInfo;
		}
	}
	return nullptr;
}

bool Guild::AddItem(uint32_t uItemId, uint32_t nNum, ReasonDef reason) {
	if (nNum <= 0)
		return false;

	auto pConfig = CoinConfigManager::getMe().GetConfigNode(uItemId);
	if (!pConfig) {
		auto pConfig = ItemConfigDataMgr::getMe().GetConfig(uItemId);
		if (!pConfig) {
			auto pConfig = SkinConfigDataMgr::getMe().GetConfig(uItemId);
			if (!pConfig) {
				auto pRoleConfig = HumanRoleConfigDataMgr::getMe().GetConfig(uItemId);
				if (!pRoleConfig) {
					auto pRoleConfig = GhostRoleConfigDataMgr::getMe().GetConfig(uItemId);
					if (!pRoleConfig) {
						auto pTruereBox = TreasureBoxConfigManager::getMe().GetConfigNode(uItemId);
						if (!pTruereBox) {
							auto pHeadConfig = guildHeadConfigManager::getMe().GetConfigNode(uItemId);
							if (!pHeadConfig) {
								XERR("Guild::AddItem - !pCoinConfig configID:%d,count:%d", uItemId, nNum);
								return false;
							}
						}
					}
				}
			}
		}
	}

	auto beforeCount = m_guildBag[uItemId];
	int afterCount = beforeCount + nNum;
	if (afterCount < 0) {
		XERR("Guild::AddItem - !after_count<0!item_id:%d beforeCount:%d,nNum:%d", uItemId, beforeCount, nNum);
		afterCount = 0;
	}

	m_guildBag[uItemId] = afterCount;
	//统计变化日志
	LogRecordMgr::LogItemChange(0, uItemId, nNum, beforeCount, afterCount, reason, m_guild_id);
	if (uItemId == GUILD_ACTIVENESS_ID) {
		//公会活跃度变化后，对排行榜进行修改
		auto activeness = m_guildInfo.activeness();
		activeness += nNum;
		m_guildInfo.set_activeness(activeness);

		if (m_guildInfo.status() == eGS_Normal) {
			//状态为Normal，则发送到排行榜
			SendGuildInfoToDB(m_guildInfo, 0);
		}
	}

	return true;
}

bool Guild::PlayerAddContribute(uint32_t nPlayerId, uint32_t nNum, ReasonDef reason)
{
	auto pPlayerInfo = GetPlayerInfo(nPlayerId);
	if (!pPlayerInfo)
	{
		return false;
	}

	auto uPlayerContribute = pPlayerInfo->m_GuildUserData.mutable_guild_data()->playercontribute();
	pPlayerInfo->m_GuildUserData.mutable_guild_data()->set_playercontribute(uPlayerContribute + nNum);
	AddGuildContribute(nNum, reason);
	return true;
}


bool Guild::DelItem(uint32_t uItemId, uint32_t nNum, ReasonDef reason)
{
	if (nNum <= 0)
		return false;

	auto beforeCount = GetItemCount(uItemId);
	if (beforeCount <= 0)
		return false;

	int afterCount = beforeCount - nNum;
	if (afterCount < 0)
	{
		XERR("Guild::DelItem - !after_count<0!item_id:%d beforeCount:%d,nNum:%d", uItemId, beforeCount, nNum);
		afterCount = 0;
	}

	m_guildBag[uItemId] = afterCount;
	GenGuildBag();
	//统计变化日志
	LogRecordMgr::LogItemChange(0, uItemId, nNum, beforeCount, afterCount, reason, m_guild_id);

	if (uItemId == GUILD_ACTIVENESS_ID) {
		//公会活跃度变化后，对排行榜进行修改
		auto activeness = m_guildInfo.activeness();
		if (activeness > nNum) {
			activeness -= nNum;
		}
		else {
			activeness = 0;
		}

		m_guildInfo.set_activeness(activeness);

		if (m_guildInfo.status() == eGS_Normal) {
			//状态为Normal，则发送到排行榜
			SendGuildInfoToDB(m_guildInfo, 0);
		}
	}
	return true;
}

uint32_t Guild::GetItemCount(uint32_t uItemId)
{
	auto iter = m_guildBag.find(uItemId);
	if (iter == m_guildBag.end())
		return 0;
	return iter->second;
}

bool Guild::CheckItemEnough(uint32_t uItemId, uint32_t nNum)
{
	return (GetItemCount(uItemId) >= nNum);
}

bool Guild::IsPlayerHasRight(GuildPlayerInfo* pPlayerInfo, enPBGuildRightType eRight)
{
	if (!pPlayerInfo)
		return false;
	if (IsMaster(pPlayerInfo->m_nPlayerDbid))   //公会长有所有权限
		return true;
	auto pDutyInfo = GetDutyInfo(pPlayerInfo->GetDutyId());
	if (!pDutyInfo)
		return false;

	return IsDutyHasRight(pDutyInfo, eRight);
}

bool Guild::IsDutyHasRight(PBGuildDutyInfo* pDutyInfo, enPBGuildRightType eRight)
{
	if (!pDutyInfo)
		return false;
	if (100 == pDutyInfo->duty_level()) //会长有全部权限
		return true;
	return isSetFlag(pDutyInfo->duty_right(), eRight);
}

void Guild::BoardcastDutyList()
{
	//延迟10秒后广播最新的职位列表给公会成员
	m_dutyListDelay.SetDelay(10, [this]()
		{
			PBGuildUpdateDutyListCmd rspMsg;
			*rspMsg.mutable_duty_list() = m_guildInfo.duty_list();
			BoardcastMsgToClient(rspMsg);
			NotifyManagerApply();
		});
}

bool Guild::OnPBGuildAnswerApplyJoinGuildReqCmd(EntityMailBox& sender_mb, ::google::protobuf::Message* pMsg)
{
	PBGuildAnswerApplyJoinGuildReqCmd* pCmd = (PBGuildAnswerApplyJoinGuildReqCmd*)pMsg;

	auto uid = pCmd->uid();
	auto applyer_uid = pCmd->applyer_uid();
	XLOG("Guild::OnPBGuildAnswerApplyJoinGuildReqCmd! uid:%d,applyer_uid:%d", uid, applyer_uid);

	auto pPlayerInfo = GetPlayerInfo(uid);
	if (!pPlayerInfo)
	{//不是公会成员
		return true;
	}

	if (eGS_Normal != m_guildInfo.status()) {
		//公会已冻结或删除
		SendShowTextId(pPlayerInfo->mb, ERR_GUILD_IN_FREEZE_OR_DELETE);
		return false;
	}

	if (!IsPlayerHasRight(pPlayerInfo, enRT_AnswerApply))
	{//没有权限
		SendShowTextId(pPlayerInfo->mb, ERR_GUILD_U_NOT_HAVE_RIGHT);
		return true;
	}
	auto pApplyInfo = GetApplyInfo(applyer_uid);
	if (!pApplyInfo)
	{//没找到
		SendShowTextId(pPlayerInfo->mb, ERR_GUILD_INVALID_APPLY_INFO);
		XERR("Guild::OnPBGuildAnswerApplyJoinGuildReqCmd!guild_id:%llu, uid:%d", m_guild_id, applyer_uid);
		return true;
	}

	auto apply_time = pApplyInfo->apply_time();
	//删除申请
	DelApplyInfo(applyer_uid);


	auto pApplerPlayerInfo = GetPlayerInfo(applyer_uid);
	if (pApplerPlayerInfo)
	{//申请人已是公会成员
		SendShowTextId(pPlayerInfo->mb, ERR_GUILD_TARGET_PLAYER_HAD_IN_GUILD);
		return true;
	}




	if (pCmd->b_agree())
	{//同意接口
		if (m_PlayerList.size() >= m_guildInfo.member_max_num())
		{//超过最大人数
			SendShowTextId(pPlayerInfo->mb, ERR_GUILD_MAX_GUILD_MEMBER_COUNT);
			return true;
		}

		enum { MAX_APPLY_TIME = 48 * 3600 };//最大48个小时
		auto now = time(0);
		//todo : 判断是否过期
		if (now - apply_time >= MAX_APPLY_TIME)
		{
			SendShowTextId(pPlayerInfo->mb, ERR_GUILD_INVALID_TIME_OUT);
			//过期了
			return true;
		}

		//玩家加入公会
		PlayerJoin(applyer_uid);
	}
	else
	{
		m_rejectApply[applyer_uid] = time(0);
	}

	//返回申请回复结果
	if (pPlayerInfo->IsOnline())
	{
		PBGuildAnswerApplyJoinGuildRspCmd rspMsg;
		rspMsg.set_b_agree(pCmd->b_agree());
		rspMsg.set_applyer_uid(applyer_uid);
		SendToClientEntity(pPlayerInfo->mb, rspMsg);
	}

	return true;
}

//邀请加入公会
bool Guild::OnPBGuildInviteJoinGuildReqCmd(EntityMailBox& sender_mb, ::google::protobuf::Message* pMsg)
{
	PBGuildInviteJoinGuildReqCmd* pCmd = (PBGuildInviteJoinGuildReqCmd*)pMsg;
	auto uid = pCmd->uid();
	auto be_invite_uid = pCmd->be_invite_uid();
	XLOG("Guild::PBGuildInviteJoinGuildReqCmd! uid:%d,be_invited_uid:%d", uid, be_invite_uid);

	auto pPlayerInfo = GetPlayerInfo(uid);
	if (!pPlayerInfo)
	{//不是公会成员
		return true;
	}

	if (!IsPlayerHasRight(pPlayerInfo, enRT_Invite))
	{//没有权限
		SendShowTextId(pPlayerInfo->mb, ERR_GUILD_U_NOT_HAVE_RIGHT);
		return true;
	}

	if (eGS_Normal != m_guildInfo.status()) {
		//公会已冻结或删除
		SendShowTextId(pPlayerInfo->mb, ERR_GUILD_IN_FREEZE_OR_DELETE);
		return true;
	}
	if (m_PlayerList.size() >= m_guildInfo.member_max_num())
	{//超过最大人数
		SendShowTextId(pPlayerInfo->mb, ERR_GUILD_MAX_GUILD_MEMBER_COUNT);
		return true;
	}

	//转发到公会管理器，判断目标是否有公会等
	SendToGlobalEntity("GuildMgr", *pCmd);
	return true;
}
//回复邀请加入公会
bool Guild::OnPBGuildAnswerInviteJoinGuildReqCmd(EntityMailBox& sender_mb, ::google::protobuf::Message* pMsg)
{
	PBGuildAnswerInviteJoinGuildReqCmd* pCmd = (PBGuildAnswerInviteJoinGuildReqCmd*)pMsg;
	if (pCmd->b_agree())
	{

		//同意接口
		if (m_PlayerList.size() >= m_guildInfo.member_max_num())
		{//超过最大人数
			SendShowTextId(pCmd->applyer_mb(), ERR_GUILD_MAX_GUILD_MEMBER_COUNT);
			return true;
		}

		//enum { MAX_APPLY_TIME = 48 * 3600 };//最大48个小时
		//auto now = time(0);
		////todo : 判断是否过期
		//if (now - apply_time >= MAX_APPLY_TIME)
		//{
		//	SendShowTextId(pPlayerInfo->mb, ERR_GUILD_INVALID_TIME_OUT);
		//	//过期了
		//	return true;
		//}

		//玩家加入公会
		PlayerJoin(pCmd->uid());
	}
	return true;
}

bool Guild::OnPBGuildSendSpoilReq(EntityMailBox& sender_mb, ::google::protobuf::Message* pMsg)
{
	if (m_guildInfo.level() < 20)
	{
		//todo,暂时关闭，2021年8月18日
		SendShowTextId(sender_mb, ERR_GUILD_LEVEL_NOT_ENOUGH);
		return true;
	}

	PBGuildSendSpoilsReq* pCmd = (PBGuildSendSpoilsReq*)pMsg;
	auto playerInfo = GetPlayerInfo(pCmd->uid());
	if (!playerInfo)
	{//玩家不在线或不存在
		return true;
	}

	if (!IsSpoilsMgr(playerInfo))
	{
		SendShowTextId(sender_mb, ERR_GUILD_U_NOT_HAVE_RIGHT);
		return true;
	}
	auto desPlayerInfo = GetPlayerInfo(pCmd->des_uid());
	if (!desPlayerInfo)
	{//玩家不在线或不存在
		return true;
	}
	auto now = time(nullptr);
	if (now - desPlayerInfo->m_GuildUserData.guild_data().join_time() < GuildNewMemberDonateTime)
	{
		//新成员要3天才能发道具
		SendShowTextId(sender_mb, ERR_GUILD_DES_NEW_MEMBER_3DAY);
		return true;
	}
	if (desPlayerInfo->m_GuildUserData.guild_data().has_last_send_spoil() && xTime::isSameDay(now, desPlayerInfo->m_GuildUserData.guild_data().last_send_spoil()))
	{
		//每天只能发放一次
		SendShowTextId(sender_mb, ERR_GUILD_DES_SENDSPOIL_ONEDAY_ONETIME);
		return true;
	}
	if (pCmd->mutable_slist()->item_list_size() > 5)
	{
		return true;
	}

	//检查公会背包物品是否足够，检查物品对应的绑定物品ID
	bool bcheckitem = true;

	//判断公会灵币是否大于1000
	auto nLinBiCount = GetItemCount(SCT_Guild_LingBi);
	if (nLinBiCount < 1000)
	{
		SendShowTextId(sender_mb, ERR_GUILD_LING_BI_NOT_ENOUGH);
		return true;
	}
	CItemVector vCCItem;
	for (int i = 0; i < pCmd->mutable_slist()->item_list_size(); i++)
	{
		auto& item = pCmd->mutable_slist()->item_list(i);
		if (!CheckItemEnough(item.item_id(), item.item_count()))
		{
			bcheckitem = false;
			SendShowTextId(sender_mb, ERR_GUILD_ITEM_NOT_ENOUGH);
			break;
		}
		uint32_t item_id = item.item_id();

		auto pConfig = SkinConfigDataMgr::getMe().GetConfig(item.item_id());
		if (pConfig)
		{//如果是皮肤，要做绑定转化

			//绑定的Skin ID(base_skin_id)
			auto base_skin_id = pConfig->cfg->base_skin_id;
			if (base_skin_id <= 0)
			{
				base_skin_id = item_id;
			}
			else
			{
				if (pConfig->cfg->effect_type > 0)
				{
					//effect_type 不为0，不能交易
					SendShowTextId(sender_mb, ERR_GUILD_OP_ITEM_BIND);
					return true;
				}
			}

			auto pBaseSkinConfig = SkinConfigDataMgr::getMe().GetConfig(base_skin_id);
			if (!pBaseSkinConfig)
			{//没有找到配置
				SendShowTextId(sender_mb, ERR_LOBBYGATE_SENDITEM_CANT_ERROR);
				bcheckitem = false;
				break;
			}
			item_id = base_skin_id;
		}

		if (item.item_count() > 1)
		{
			bcheckitem = false;
			break;
		}

		CCItem xitem;
		xitem.config_id = item_id;
		xitem.item_count = item.item_count();
		vCCItem.push_back(xitem);
		break; //只能发一个物品，并且只能一个

	}
	PBGuildSendSpoilsRsp rspMsg;
	rspMsg.set_sucess(false);
	if (bcheckitem)
	{
		DelItem(SCT_Guild_LingBi, 1000, RD_GuildSendSpoil);
		PBGuildRecordInfo record;
		record.set_record_type(ERT_SPOILS_GRANT);
		record.set_op_mgr_name(playerInfo->GetNickname());
		record.set_nickname(desPlayerInfo->GetNickname());
		record.set_target_uid(desPlayerInfo->m_nPlayerDbid);

		//扣除公会物品
		for (int i = 0; i < pCmd->mutable_slist()->item_list_size(); i++)
		{
			auto& item = pCmd->mutable_slist()->item_list(i);
			DelItem(item.item_id(), item.item_count(), RD_GuildSendSpoil);
			UpdateGuildBag();
			PBItem pbitem;
			pbitem.set_config_id(item.item_id());
			pbitem.set_item_count(item.item_count());
			*record.mutable_spoils_item()->add_item_list() = pbitem;
		}
		//添加公会记录
		AddGuildRecord(record);
		desPlayerInfo->m_GuildUserData.mutable_guild_data()->set_last_send_spoil(now);
		//发放邮件
		SendMailInfo mailInfo;
		mailInfo.eMailType = MAIL_TYPE_PLAYER;
		mailInfo.nTitleId = STI_GUILD_SPOILS_TITLE_ID;
		mailInfo.nContextId = STI_GUILD_SPOILS_CONTEXT_ID;
		mailInfo.senderUid = pCmd->uid();
		mailInfo.senderUserName = playerInfo->GetNickname();
		mailInfo.targetUid = pCmd->des_uid();
		mailInfo.targetUserName = "";
		mailInfo.invaild_time = time(0) + 30 * 3600 * 24;
		mailInfo.itemList = std::move(vCCItem);
		MailMgr::getMe().SendMailReq(mailInfo, RD_GuildSendSpoil);
		//
		rspMsg.set_sucess(true);
	}
	SendToClientEntity(sender_mb, rspMsg);
	return true;
}

bool Guild::OnPBGuildUpdateShopReq(EntityMailBox& sender_mb, ::google::protobuf::Message* pMsg)
{
	PBGuildUpdateShopReq* pCmd = (PBGuildUpdateShopReq*)pMsg;
	auto playerInfo = GetPlayerInfo(pCmd->uid());
	if (!playerInfo)
	{//玩家不在线或不存在
		return true;
	}
	if (!IsSpoilsMgr(playerInfo))
	{
		SendShowTextId(sender_mb, ERR_GUILD_U_NOT_HAVE_RIGHT);
		return true;
	}

	PBGuildUpdateShopInfo rspMsg;
	rspMsg.set_tab_index(pCmd->tab_index());
	if (m_shopList.find(pCmd->tab_index()) != m_shopList.end())
	{
		*rspMsg.mutable_item_list() = m_shopList[pCmd->tab_index()];
	}
	SendToClientEntity(sender_mb, rspMsg);
	return true;
}

bool Guild::OnPBGuildShopBuyItemReq(EntityMailBox& sender_mb, ::google::protobuf::Message* pMsg)
{
	PBGuildShopBuyItemReq* pCmd = (PBGuildShopBuyItemReq*)pMsg;
	auto playerInfo = GetPlayerInfo(pCmd->uid());
	if (!playerInfo)
	{//玩家不在线或不存在
		return true;
	}
	if (!IsSpoilsMgr(playerInfo))
	{
		SendShowTextId(sender_mb, ERR_GUILD_U_NOT_HAVE_RIGHT);
		return true;
	}
	//判断商品是否可以买
	auto data = GuildShopDataMgr::getMe().getMarketItemInfo(pCmd->s_id());
	if (data == nullptr)
	{
		//商品不存在
		SendShowTextId(sender_mb, ERR_GUILD_SHOP_ITEM_NOT_FIND);
		return true;
	}
	if (time(0) > data->delTime && data->delTime != 0)
	{
		//商品过期，不能购买
		SendShowTextId(sender_mb, ERR_GUILD_SHOP_ITEM_OUT_TIME);
		return true;
	}

	auto item = m_shopItem.find(pCmd->s_id());
	if (item == m_shopItem.end())
	{
		//商品信息没有找到
		SendShowTextId(sender_mb, ERR_GUILD_SHOP_ITEM_NOT_FIND);
		return true;
	}

	if (data->cfg->time > 0 && item->second.buy_count() + pCmd->item_count() > data->cfg->time)
	{
		//达到购买数量上限
		SendShowTextId(sender_mb, ERR_GUILD_SHOP_ITEM_COUNT_LIMIT);
		return true;
	}
	//判断钱够不够
	int nPriceCount = pCmd->item_count() * data->nPriceCount;
	if (nPriceCount <= 0 || pCmd->item_count() > 1000)
	{

		SendShowTextId(sender_mb, ERR_GUILD_GUBI_LINGBI_NOT_ENOUGH);
		return true;
	}

	if (data->nPriceType == 1)
	{
		//扣灵币
		auto nLingBiCount = GetItemCount(SCT_Guild_LingBi);
		if (nLingBiCount < nPriceCount)
		{
			SendShowTextId(sender_mb, ERR_GUILD_LING_BI_NOT_ENOUGH);
			return true;
		}
		DelItem(SCT_Guild_LingBi, nPriceCount, RD_GuildShopBuy);
	}
	else if (data->nPriceType == 2)
	{
		auto nGuBiCount = GetItemCount(SCT_Guild_GuBi);
		if (nGuBiCount < nPriceCount)
		{
			SendShowTextId(sender_mb, ERR_GUILD_GU_BI_NOT_ENOUGH);
			return true;
		}
		DelItem(SCT_Guild_GuBi, nPriceCount, RD_GuildShopBuy);
	}
	else
	{
		//货币类型配置错误
		SendShowTextId(sender_mb, ERR_GUILD_CONFIG_ERROR);
		return true;
	}
	item->second.set_buy_count(item->second.buy_count() + pCmd->item_count());
	bool bAdd = AddItem(data->cfg->itemID, pCmd->item_count(), RD_GuildShopBuy);

	if (bAdd)
	{
		UpdateGuildShopList();
		UpdateGuildBag();
		SetGuildDirty();
	}
	else
	{
		SendShowTextId(sender_mb, ERR_GUILD_SHOP_ITEM_NOT_FIND);
		return false;
	}

	PBGuildShopBuyItemRsp rspMsg;
	rspMsg.set_tab_index(pCmd->tab_index());
	rspMsg.set_s_id(pCmd->s_id());
	rspMsg.set_item_count(pCmd->item_count());
	rspMsg.set_sucess(true);
	SendToClientEntity(sender_mb, rspMsg);
	return true;
}

bool Guild::OnPBGuildDayMissionAwardReqCmd(EntityMailBox& sender_mb, ::google::protobuf::Message* pMsg)
{
	PBGuildDayMissionAwardReqCmd* pCmd = (PBGuildDayMissionAwardReqCmd*)pMsg;
	XLOG("Guild::PBGuildDayMissionAwardReqCmd! uid:%d", pCmd->uid());
	uint32_t uid = pCmd->uid();
	auto playerInfo = GetPlayerInfo(uid);
	if (!playerInfo || !playerInfo->IsOnline())
	{
		return true;
	}

	PBRpcGuildDayMissinAward_Req reqData;
	reqData.set_bdaymission(pCmd->bdaymission());
	reqData.set_missionid(pCmd->missionid());

	SearchUserMgr::ExeGateUserRpcCall(playerInfo->mb, reqData, [&sender_mb, playerInfo, uid, this](bool bSucess, const std::string& rspParam)
		{
			if (!bSucess)
			{
				XLOG("SearchUserMgr::ExeGateUserRpcCall  PBRpcGuildDayMissinAward_Req uid:%d fail", uid);
				return;
			}
			//RD_GuildDayMissionReward
			PBRpcGuildDayMissinAward_Rsp rpcRsp;
			bool bPaseSucess = rpcRsp.ParseFromArray(rspParam.data(), rspParam.size());
			if (bPaseSucess)
			{
				if (rpcRsp.code() == ERR_SUCCESS)
				{
					for (int i = 0; i < rpcRsp.item_list().item_list_size(); i++)
					{
						auto item = rpcRsp.item_list().item_list(i);
						switch (item.config_id())
						{
						case SCT_Guild_GuBi:
						{
							AddItem(SCT_Guild_GuBi, item.item_count(), rpcRsp.bdaymission() ? RD_GuildDayMissionReward : RD_GuildDayMissionWeekReward);
							UpdateGuildBag();
							break;
						}
						case SCT_Guild_LingBi:
						{
							AddItem(SCT_Guild_LingBi, item.item_count(), rpcRsp.bdaymission() ? RD_GuildDayMissionReward : RD_GuildDayMissionWeekReward);
							UpdateGuildBag();
							break;
						}
						case SCT_Guild_Contribution:
						{
							PlayerAddContribute(uid, item.item_count(), rpcRsp.bdaymission() ? RD_GuildDayMissionReward : RD_GuildDayMissionWeekReward);
							break;
						}
						default:
							break;
						}

					}
					//更新自己的公会信息
					UpdateGuildUserData(playerInfo);
					PBGuildDayMissionAwardRspCmd rspMsg;
					rspMsg.set_code(rpcRsp.code());
					*rspMsg.mutable_item_list() = rspMsg.item_list();
					rspMsg.set_bdaymission(rspMsg.bdaymission());
					SendToClientEntity(sender_mb, rspMsg);
				}
			}




		});

	return true;
}

bool Guild::OnPBGuildBuyRecommentReqCmd(EntityMailBox& sender_mb, ::google::protobuf::Message* pMsg)
{
	PBGuildBuyRecommentReqCmd* pCmd = (PBGuildBuyRecommentReqCmd*)pMsg;
	XLOG("Guild::OnPBGuildBuyRecommentReqCmd! uid:%d", pCmd->uid());
	uint32_t uid = pCmd->uid();
	auto playerInfo = GetPlayerInfo(uid);
	if (!playerInfo || !playerInfo->IsOnline())
	{
		return true;
	}

	auto pPlayerInfo = GetPlayerInfo(uid);
	if (!pPlayerInfo)
	{//你没有战队
		SendShowTextId(sender_mb, ERR_GUILD_U_NOT_HAVE_GUILD);
		return true;
	}

	if (!IsMaster(uid))
	{
		SendShowTextId(sender_mb, ERR_GUILD_U_NOT_HAVE_RIGHT);
		return true;
	}
	//判断是否已购买
	if (time(0) < m_guildInfo.recommend_endtime())
	{
		SendShowTextId(sender_mb, ERR_GUILD_YOU_AREADY_RECOMMENT);
		return true;
	}
	//判断古币够不够
	auto count = GetItemCount(SCT_Guild_GuBi);
	if (count < 5000)
	{
		SendShowTextId(sender_mb, ERR_GUILD_GU_BI_NOT_ENOUGH);
		return true;
	}
	DelItem(SCT_Guild_GuBi, 5000, RD_GuildBuyRecomment);

	m_guildInfo.set_recommend_endtime(time(0) + 3 * 24 * 3600);

	UpdateSimpleInfo2GuildMgr();
	UpdateGuildBag();
	SetGuildDirty();
	PBGuildBuyRecommentRspCmd rspMsg;
	rspMsg.set_sucess(true);
	rspMsg.set_recommend_endtime(m_guildInfo.recommend_endtime());
	SendToClientEntity(sender_mb, rspMsg);
	return true;
}



bool Guild::OnPBPlayerRechargeSyn(EntityMailBox& sender_mb, ::google::protobuf::Message* pMsg)
{
	PBPlayerRechargeSyn* pCmd = (PBPlayerRechargeSyn*)pMsg;
	auto uid = pCmd->uid();
	XLOG("Guild::OnPBPlayerBaseDataSimpleSyn! uid:%d", uid);
	auto playerInfo = GetPlayerInfo(uid);
	if (!playerInfo)
	{
		XERR("Guild::PBPlayerRechargeSyn! no find player! uid:%d", uid);
		return true;
	}
	uint32_t nContributeNum = 0;
	if (pCmd->coin_type() == SCT_LingShi)
	{
		//每充值100灵石获得1.2贡献值  实际获得数值向下取整

		nContributeNum = pCmd->coin_count() * 1.2 / 100;
		PlayerAddContribute(uid, nContributeNum, RD_Recharge);

		UpdateGuildBag();
		//存入一条记录
		//添加公会记录
		PBGuildRecordInfo record;
		record.set_record_type(ERT_PLAYER_RECHARGE);
		record.set_nickname(playerInfo->GetNickname());
		record.set_target_uid(uid);
		record.set_rechage_num(pCmd->coin_count());
		record.set_contribute(nContributeNum);
		record.set_item_id(pCmd->coin_type());
		AddGuildRecord(record);
	}



	return true;
}

bool Guild::OnPBGuildSetHeadReqCmd(EntityMailBox& sender_mb, ::google::protobuf::Message* pMsg)
{

	PBGuildSetHeadReqCmd* pCmd = (PBGuildSetHeadReqCmd*)pMsg;
	auto uid = pCmd->uid();
	XLOG("Guild::OnPBPlayerBaseDataSimpleSyn! uid:%d", uid);
	auto playerInfo = GetPlayerInfo(uid);
	if (!playerInfo)
	{
		XERR("Guild::PBPlayerRechargeSyn! no find player! uid:%d", uid);
		return true;
	}
	if (!IsMaster(uid))
	{
		SendShowTextId(sender_mb, ERR_GUILD_U_NOT_HAVE_RIGHT);
		return true;
	}
	//判断配置是否正确
	if (guildHeadConfigManager::getMe().GetConfigNode(pCmd->item_headid()) && guildHeadConfigManager::getMe().GetConfigNode(pCmd->item_frameid()))
	{

	}
	else
	{
		SendShowTextId(sender_mb, ERR_GUILD_CONFIG_ERROR);
		return true;
	}
	//判断是不是有头像和头像框
	if (GetItemCount(pCmd->item_headid()) >= 1 && GetItemCount(pCmd->item_frameid()) >= 1)
	{
		m_guildInfo.set_item_headid(pCmd->item_headid());
		m_guildInfo.set_item_frameid(pCmd->item_frameid());
		SetGuildDirty();
		UpdateSimpleInfo2GuildMgr();
		PBGuildSetHeadRspCmd rsp;
		rsp.set_item_headid(pCmd->item_headid());
		rsp.set_item_frameid(pCmd->item_frameid());
		//广播消息（给全公会玩家）
		BoardcastMsgToClient(rsp);

	}
	else
	{
		SendShowTextId(sender_mb, ERR_GUILD_ITEM_NOT_ENOUGH);
		return true;
	}
	return true;
}

//GM设置公会状态
bool Guild::OnPBGMSetGuildStatus(EntityMailBox& sender_mb, ::google::protobuf::Message* pMsg)
{
	PBSetGuildStatus* pCmd = (PBSetGuildStatus*)pMsg;
	XLOG("Guild::OnPBGMSetGuildStatus! guild_id:%d", m_guild_id);

	auto status = pCmd->status();
	m_guildInfo.set_status(status);
	UpdateSimpleInfo2GuildMgr();
	SetGuildDirty();
	return true;
}
//GM设置公会捐赠
bool Guild::OnPBOpenGuildJuanZeng(EntityMailBox& sender_mb, ::google::protobuf::Message* pMsg)
{
	PBOpenGuildJuanZeng* pCmd = (PBOpenGuildJuanZeng*)pMsg;
	XLOG("Guild::OnPBGMSetGuildStatus! guild_id:%d", m_guild_id);

	auto status = pCmd->open_juanzeng();
	m_guildInfo.set_open_juanzeng(status);
	//UpdateSimpleInfo2GuildMgr();
	SetGuildDirty();
	return true;
}
