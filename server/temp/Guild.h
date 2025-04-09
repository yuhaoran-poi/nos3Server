#pragma once
#include "Entity.h"
#include "CommonCmd.pb.h"
#include "GuildCmd.pb.h"
#include "LobbyGateCmd.pb.h"
#include "ReasonDef.h"

enum enPBGuildRightType
{
    enRT_Invite = 1,				//邀请
    enRT_KickoutNormal = 2,		//踢出普通成员
    enRT_AnswerApply = 3,		//同意申请
    enRT_SetDuty = 4,			//任免职位
    enRT_JoinGuildRoom = 5,	//参加战队排位
    enRT_ModifyAnnouncement = 6,	//修改公告
    enRT_ModifyApplyCondition = 7,	//修改申请条件
    enRT_UseGuildStorage = 8		//使用战队仓库
};

#define GUILD_ACTIVENESS_ID 26

enum PlayerStatusType
{
    e_Offline = 0,
    e_Online = 1,
};

struct GuildPlayerInfo
{
public:
    uint32_t m_nPlayerDbid = 0;
    EntityMailBox mb;
    PBGuildUserData m_GuildUserData;    //公会玩家数据

public:

    uint32_t GetDutyId() {
        return m_GuildUserData.mutable_guild_data()->playerdutyid();
    }
    const string& GetNickname()
    {
        return m_GuildUserData.playersimpleinfo().nick_name();
    }
	bool IsSpoilsMgr() {
		return m_GuildUserData.mutable_guild_data()->bspoilsmgr();
	}

    bool IsOnline()
    {
        return mb.IsOk();
    }
};

enum UpDataType
{
	e_TypeNone = 0,
	e_UpGuildUserList,
	e_UpGuildUserStatus,
	e_UpGuildBaseInfo,


	e_MaxUpGuildAllData,
};

//公会脏数据
enum GuildDirtyType
{
    GDT_ALL             = 1,
    GDT_MEMBERS         = 2,           //成员列表
    GDT_APPLY_LIST      = 3,           //申请列表


    GDT_OHTER_INFO           //其他信息
};


class CDelayCallback
{
public:
    void SetDelay(uint32_t nDelayTime, std::function<void()> cb)
    {
        if (m_delayTimerId > 0)
            return;
        m_delayTimerId = CHeapTimer::Instance().AddTimer(nDelayTime, nDelayTime, 1, [this, cb]() {
            m_delayTimerId = 0;
            cb();
        });
    }
    uint64_t m_delayTimerId = 0;
};


class Guild : public TDynamicEntity<Guild>
{
public:
	Guild();
	~Guild()
	{
		XLOG("~Guild! guild_id:%d,eid:%llu", m_guild_id, GetEId());
	}

public:
    //初始化数据接口（有底层自动调用）
    bool InitWithData(const string& data);

    void RefreshManager();

    //玩家上线消息
    bool OnPlayerOnline(EntityMailBox& sender_mb, PBLobbyGateUserOnlineReq* pCmd);
    //玩家下线消息
    bool OnPlayerOffline(EntityMailBox& sender_mb, PBLobbyGateUserOfflineReq* pCmd);

    bool OnPlayerBaseDataSimpleSyn(EntityMailBox& sender_mb, PBPlayerBaseDataSimpleSyn* pBaseDataCmd);
    void SetGuildDirty();
public:
    //公会自动存档接口
    void OnSave2Db();
    //定时自动刷新接口
    virtual void OnTimerRefresh();

public:
    inline PBGuildInfo& GetGuildInfo() { return m_guildInfo; }
    inline bool IsMaster(uint32_t uid) { return (uid == m_guildInfo.president_id()); }

    PBGuildApplyUserBaseInfo* GetApplyInfo(uint32_t uid);
    GuildPlayerInfo* GetPlayerInfo(uint32_t uid);
    EntityMailBox* GetPlayerMb(uint32_t uid);
    bool AddMember(uint32_t uid, const PBUserGameBaseSimpleData & simpleData, const EntityMailBox & mb);
    bool AddApplyInfo(uint32_t uid, const PBUserGameBaseSimpleData & simple_data);
    bool DelApplyInfo(uint32_t uid);
    void PlayerJoin(uint32_t uid);
    bool PlayerLeave(uint32_t uid);
    bool SetSpoiMgr(uint32_t uid, bool bset, int& errcode);
    void GenMemberList();
	void GenGuildBag();
    void GenGuildShop();
    void NotifyManagerApply();
    void NotifyPlayerJoin(GuildPlayerInfo & playerInfo);
    void NotifyPlayerExit(uint32_t uid);
    void NotifyGuildDismiss();
    void UpdateApplyInfo2GuildMgr(eApplyOpt opt, uint32_t uid, uint64_t apply_time);
    void SendShowTextId(const EntityMailBox & mb, uint32_t nTextId, const std::vector<string>& params);
    void SendShowTextId(const EntityMailBox & mb, uint32_t nTextId);
    bool IsSpoilsMgr(GuildPlayerInfo* pPlayerInfo);
	//增加公会活跃度
	void AddGuildActiveness(uint32_t nValue, ReasonDef rf);
    //增加公会贡献值
    void AddGuildContribute(uint32_t nValue, ReasonDef rf);

    PBGuildDutyInfo* GetDutyInfo(uint32_t nDutyId);

	//玩家增加贡献
	bool PlayerAddContribute(uint32_t nPlayerId, uint32_t nNum, ReasonDef reason);

public:	//公会仓库相关
	bool AddItem(uint32_t uItemId, uint32_t nNum, ReasonDef reason);
	bool DelItem(uint32_t uItemId, uint32_t nNum, ReasonDef reason);
	uint32_t GetItemCount(uint32_t uItemId);
	bool CheckItemEnough(uint32_t uItemId, uint32_t nNum);

public:
    bool IsPlayerHasRight(GuildPlayerInfo* playerInfo, enPBGuildRightType eRight);

    bool IsDutyHasRight(PBGuildDutyInfo* pDutyInfo, enPBGuildRightType eRight);

    //广播最新的职位列表
    void BoardcastDutyList();

    uint32_t GetPlayerStatus(uint64_t uid)
    {
        auto playerInfo = GetPlayerInfo(uid);
        if (playerInfo)
        {
            return playerInfo->m_GuildUserData.mutable_guild_data()->playerstatus();
        }
        return e_Offline;
    }

    void AddGuildRecord(PBGuildRecordInfo& recordInfo)
    {
		recordInfo.set_record_time(time(0));

        auto pRecordList = m_guildInfo.mutable_record_list();
		*pRecordList->add_record_list() = recordInfo;
        if (pRecordList->mutable_record_list()->size() > 1000)
        {
            pRecordList->mutable_record_list()->DeleteSubrange(0, 10);
        }
        //if(pRecordList->mutable_record_list())
        /*
        if (recordInfo.record_type() == ERT_SPOILS_GRANT)
        {
            //只保留100条记录
            int nCount = 0;
            auto clsmates = pRecordList->mutable_record_list();
			for (auto it = clsmates->begin(); it != clsmates->end(); ++it) {
                if ((*it).record_type() == ERT_SPOILS_GRANT)
                {
                    nCount++;
					if (nCount >= 100)
					{
                        clsmates->erase(it);
                        break;
					}
                 }
			}
            
        }*/
    }

public:
    void UpdateGuildShopList(int nDelay = 5);
    void UpdateSimpleInfo2GuildMgr();
    bool UpdateGuildDataToPlayer(uint32_t uid);
	bool UpdateGuildRank(uint32_t uid, GuildPlayerInfo * playInfo);
    bool CleanGuildMbToPlayer(uint32_t uid);
	bool UpdateGuildBag();
	void SendGuildInfoToDB(const PBGuildInfo& guildInfo, UInt32 create_or_dismiss);
public:
	template<class TMsg>
    void BoardcastMsgToClient(const TMsg& msg);
	template<class TMsg>
    void BoardcastMsgToEntity(const TMsg& msg);
public:

    //玩家修改了昵称
    bool OnPBLobbyGateSetNicknamReq(EntityMailBox& sender_mb, ::google::protobuf::Message *pMsg);

    //公会修改公告
    bool OnPBGuildModifyAnnouncementReqCmd(EntityMailBox& sender_mb, ::google::protobuf::Message *pMsg);
    //退出公会
    bool OnPBGuildQuitReqCmd(EntityMailBox& sender_mb, ::google::protobuf::Message *pMsg);
    //获取申请列表
    bool OnPBGuildGetApplyListReqCmd(EntityMailBox& sender_mb, ::google::protobuf::Message *pMsg);

    bool OnPBGuildGetMembersReq(EntityMailBox& sender_mb, ::google::protobuf::Message *pMsg);
    

    //邀请加入公会
    bool OnPBGuildInviteJoinGuildReqCmd(EntityMailBox& sender_mb, ::google::protobuf::Message *pMsg);
    //回复邀请加入公会
    bool OnPBGuildAnswerInviteJoinGuildReqCmd(EntityMailBox& sender_mb, ::google::protobuf::Message *pMsg);

    //申请加入请求
    bool OnPBGuildApplyJoinGuildReqCmd(EntityMailBox& sender_mb, ::google::protobuf::Message *pMsg);

    //回复申请加入请求
    bool OnPBGuildAnswerApplyJoinGuildReqCmd(EntityMailBox& sender_mb, ::google::protobuf::Message *pMsg);

    //踢出公会
    bool OnPBGuildExpelQuitReqCmd(EntityMailBox& sender_mb, ::google::protobuf::Message *pMsg);
    //公会授予职位
    bool OnPBGuildGrantReqCmd(EntityMailBox& sender_mb, ::google::protobuf::Message *pMsg);
    //公会转让
    bool OnPBGuildDemiseReqCmd(EntityMailBox& sender_mb, ::google::protobuf::Message *pMsg);
    //公会解散
    bool OnPBGuildDismissReqCmd(EntityMailBox& sender_mb, ::google::protobuf::Message *pMsg);
    //公会解冻
    bool OnPBGuildThawReqCmd(EntityMailBox& sender_mb, ::google::protobuf::Message *pMsg);
    //公会新增职位
    bool OnPBGuildAddDutyReqCmd(EntityMailBox& sender_mb, ::google::protobuf::Message *pMsg);
    //公会删除职位
    bool OnPBGuildDelDutyReqCmd(EntityMailBox& sender_mb, ::google::protobuf::Message *pMsg);
    bool OnPBGuildModifyDutyRightReqCmd(EntityMailBox& sender_mb, ::google::protobuf::Message *pMsg);//公会修改职位权限
    bool OnPBGuildModifyDutyNameReqCmd(EntityMailBox& sender_mb, ::google::protobuf::Message *pMsg);//公会修改职位名称
    bool OnPBGuildModifyDutyLevelReqCmd(EntityMailBox& sender_mb, ::google::protobuf::Message *pMsg);//公会修改职位等级
    //公会升级
    bool OnPBGuildUpgradeReqCmd(EntityMailBox& sender_mb, ::google::protobuf::Message *pMsg);
	//公会聊天
    bool OnPBGuildSendChatReqCmd(EntityMailBox& sender_mb, ::google::protobuf::Message *pMsg);
	//升级公会最大成员数量
	bool OnPBGuildUpgradeMemberMaxcountReq(EntityMailBox& sender_mb, ::google::protobuf::Message *pMsg);
	//公会捐赠
	bool OnPBGuildDonateReq(EntityMailBox& sender_mb, ::google::protobuf::Message *pMsg);

	bool UpdateGuildUserData(GuildPlayerInfo * playerInfo);

	//公会领取工资
	bool OnPBGuildGetSalaryReq(EntityMailBox& sender_mb, ::google::protobuf::Message *pMsg);
	//公会改名
	bool OnPBGuildModifyGuildNameReqCmd(EntityMailBox& sender_mb, ::google::protobuf::Message *pMsg);
	//公会改名成功（GuildMgr通知过来）
	bool OnPBGuildModifyGuildNameRspCmd(EntityMailBox& sender_mb, ::google::protobuf::Message *pMsg);
	//添加物品
	bool OnPBGuildAddItems(EntityMailBox& sender_mb, ::google::protobuf::Message *pMsg);
	//减少物品
	bool OnPBGuildDelItems(EntityMailBox& sender_mb, ::google::protobuf::Message *pMsg);
	//设置申请加入公会条件
	bool OnPBSetGuildJoinConditionCmd(EntityMailBox& sender_mb, ::google::protobuf::Message *pMsg);
	//查询公会记录
	bool OnPBGuildRecordListReq(EntityMailBox& sender_mb, ::google::protobuf::Message *pMsg);
	//设置战利品管理员
	bool OnPBGuildSetSpoilsMgrReq(EntityMailBox& sender_mb, ::google::protobuf::Message *pMsg);
	//修改成员DKP值
	bool OnPBGuildDkpChangeReq(EntityMailBox& sender_mb, ::google::protobuf::Message *pMsg);
    //发放战利品
    bool OnPBGuildSendSpoilReq(EntityMailBox& sender_mb, ::google::protobuf::Message* pMsg);
    //请求商店列表
    bool OnPBGuildUpdateShopReq(EntityMailBox& sender_mb, ::google::protobuf::Message* pMsg);
    //请求购买商品
    bool OnPBGuildShopBuyItemReq(EntityMailBox& sender_mb, ::google::protobuf::Message* pMsg);
    //公会日常任务奖励领取
    bool OnPBGuildDayMissionAwardReqCmd(EntityMailBox& sender_mb, ::google::protobuf::Message* pMsg);
    //购买公会推荐位
    bool OnPBGuildBuyRecommentReqCmd(EntityMailBox& sender_mb, ::google::protobuf::Message* pMsg);
    //玩家充值数据（灵石）刷新
    bool OnPBPlayerRechargeSyn(EntityMailBox& sender_mb, ::google::protobuf::Message* pMsg);
    //设置头像
    bool OnPBGuildSetHeadReqCmd(EntityMailBox& sender_mb, ::google::protobuf::Message* pMsg);
	//GM设置公会状态
	bool OnPBGMSetGuildStatus(EntityMailBox & sender_mb, ::google::protobuf::Message * pMsg);
    //GM设置公会捐赠
    bool OnPBOpenGuildJuanZeng(EntityMailBox& sender_mb, ::google::protobuf::Message* pMsg);
private:

    bool            m_bDirtyData = false;
    uint64_t        m_guild_id = 0;
    PBGuildInfo     m_guildInfo;

	std::unordered_map<uint32_t, uint32_t> m_guildBag;	//公会仓库

    //玩家列表
    std::unordered_map<uint32_t, GuildPlayerInfo> m_PlayerList;

    //玩家申请列表
    std::unordered_map<uint32_t, PBGuildApplyUserBaseInfo> m_ApplyList;

	//拒绝玩家列表
	std::unordered_map<uint32_t, time_t> m_rejectApply;

    //公会商店
    std::map<int32_t, PBGuildShopItemInfoList> m_shopList;
    std::map<int32_t, PBGuildShopItemInfo> m_shopItem;

    uint64_t m_uDirtyType = 0;

    //更新数据给GuildMgr缓存的定时器
    CDelayCallback      m_simpleDataUpdateDelay;
    //更新商店物品缓存的定时器
    CDelayCallback      m_shopUpdateDelay;
    //更新职位列表
    CDelayCallback      m_dutyListDelay;

    //聊天列表
    PBChatMsgList       m_chatList;
    CDelayCallback      m_chatDelay;

    //公会记录列表
    //PBGuildRecordList   m_GuildRecordList;
    CDelayCallback      m_GuildRecordDelay;

    //管理员列表<uid,duty_id>
    std::unordered_map<uint32_t, uint32_t> m_managerMap;

	//背包变化
	std::list<uint32_t>				m_changeItems;
	CDelayCallback					m_GuildBagDelay;

};


template<class TMsg>
void Guild::BoardcastMsgToClient(const TMsg& msg)
{
    for (auto& v : m_PlayerList)
    {
        if (v.second.mb.IsOk())
        {
            SendToClientEntity(v.second.mb, msg);
        }
    }
}

template<class TMsg>
void Guild::BoardcastMsgToEntity(const TMsg& msg)
{
    for (auto& v : m_PlayerList)
    {
        if (v.second.mb.IsOk())
        {
            SendToEntity(v.second.mb, msg);
        }
    }
}
