#pragma once
#include "Entity.h"
#include "GuildCmd.pb.h"
#include "LobbyGateCmd.pb.h"
#include "CommonCmd.pb.h"

struct PlayerApplyInfo
{
    std::unordered_map<uint32_t, PBUserApplyInfo> m_applyMap;        //已申请的公会列表
};
struct PlayerInviteInfo
{
	std::unordered_map<uint32_t, PBGuildInviteRecordInfo> m_inviteMap;        //被邀请的公会列表
};
struct GuildMgrPlayerInfo
{
    uint32_t m_nPlayerDbid = 0;
    uint64_t m_guild_id = 0;        //所在公会
    EntityMailBox mb;
    PBUserGameBaseData m_baseData;

    bool IsOnline()
    {
        return mb.IsOk();
    }
};

struct tagGuildInfo
{
    uint64_t guildId_;
    EntityMailBox mb_;
    PBGuildSimpleInfo guidSimpleInfo_;

    //申请数量
    uint32_t applyCount_ = 0;
    //玩家人数
    uint32_t memberCount_ = 0;
};
class CDelayCallback2
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
class GuildMgr : public TGlobalEntity<GuildMgr>
{
public:
	GuildMgr();
    //初始化消息
    virtual bool OnInit();
public:
    PlayerApplyInfo * GetPlayerApplyInfo(uint32_t uid);
    tagGuildInfo* GetGuild(uint32_t nGuildDbid);
    tagGuildInfo* GetPlayerGuild(uint32_t nPlayerDbid);
    GuildMgrPlayerInfo* GetPlayerInfo(uint32_t nPlayerDbid);
    bool IsNameUsed(const string& name);
public:
    bool PlayerAddApplyGuild(uint32_t guildId, uint32_t uid, uint32_t apply_time);
    bool PlayerDelApplyGuild(uint32_t guildId, uint32_t uid);
    void PlayerJoinGuild(uint32_t guildId, uint32_t uid);
    void PlayerExitGuild(uint32_t guildId, uint32_t uid);
	//判断是否可以加入公会(简单判断)
    bool PlayerCanJoinGuild(uint32_t playerId, PBGuildSimpleInfo& sinfo);
    //玩家上线消息
    virtual bool OnPlayerOnline(EntityMailBox& sender_mb, PBLobbyGateUserOnlineReq* pCmd);
    //玩家下线消息
    virtual bool OnPlayerOffline(EntityMailBox& sender_mb, PBLobbyGateUserOfflineReq* pCmd);
public:
    void StartLoadGuilds(uint32_t count);
    void CreateGuildAnyWhere(const PBGuildInfo & guildInfo);

    //发送提示文字接口
    void SendShowTextId(const EntityMailBox& mb, uint32_t nTextId, const std::vector<string>& params);
    //发送提示文字接口
    void SendShowTextId(const EntityMailBox& mb, uint32_t nTextId);
public:
    //公会初始化成功的消息
    bool OnPBNotifyNewerMailboxReq(EntityMailBox & sender_mb, ::google::protobuf::Message * pMsg);
    //获取公会列表
    bool OnPBGuildGetGuildListReqCmd(EntityMailBox& sender_mb, ::google::protobuf::Message *pMsg);
    //创建公会请求
    bool OnPBGuildCreateGuildReqCmd(EntityMailBox& sender_mb, ::google::protobuf::Message *pMsg);
    //申请加入请求
    bool OnPBGuildApplyJoinGuildReqCmd(EntityMailBox& sender_mb, ::google::protobuf::Message *pMsg);
    //回复申请请求
    bool OnPBGuildAnswerApplyJoinGuildReqCmd(EntityMailBox & sender_mb, ::google::protobuf::Message * pMsg);

    bool UpdatePlayerApplyInfoToClient(uint32_t uid);
    //更新公会的申请列表
    bool OnPBGuildUpdateApplyList2GuildMgr(EntityMailBox& sender_mb, ::google::protobuf::Message *pMsg);

	bool UpdatePlayerInviteInfoToClient(uint32_t uid);
	//更新公会的邀请列表
	bool OnPBUpdatePlayerInviteInfoTo2GuildMgr(EntityMailBox& sender_mb, ::google::protobuf::Message *pMsg);


    //更新公会的简略信息
    bool OnPBGuildUpdateSimpleInfo2GuildMgr(EntityMailBox& sender_mb, ::google::protobuf::Message *pMsg);
    
    //搜索公会
    bool OnPBGuildSearchGuildReqCmd(EntityMailBox& sender_mb, ::google::protobuf::Message *pMsg);
    //玩家加入公会消息
    bool OnPBGuildBoardcastPlayerJoin(EntityMailBox& sender_mb, ::google::protobuf::Message *pMsg);
    //玩家退出公会消息
    bool OnPBGuildBoardcastPlayerExit(EntityMailBox& sender_mb, ::google::protobuf::Message *pMsg);
    //公会解散消息
    bool OnPBGuildBoardcastGuildDismiss(EntityMailBox& sender_mb, ::google::protobuf::Message *pMsg);
    //成员改名消息
    bool OnPBLobbyGateSetNicknamReq(EntityMailBox& sender_mb, ::google::protobuf::Message *pMsg);
	//公会改名消息
	bool OnPBGuildModifyGuildNameReqCmd(EntityMailBox& sender_mb, ::google::protobuf::Message *pMsg);

	//邀请玩家加入公会
	bool OnPBGuildInviteJoinGuildReqCmd(EntityMailBox& sender_mb, ::google::protobuf::Message *pMsg);
	//玩家回复邀请加入公会
	bool OnPBGuildAnswerInviteJoinGuildReqCmd(EntityMailBox& sender_mb, ::google::protobuf::Message *pMsg);

	//GM命令-公会增加/删除公会背包物品
	bool OnPBGuildAddItems2Bag(EntityMailBox& sender_mb, ::google::protobuf::Message *pMsg);

	//GM命令-修改公会状态
	bool OnPBSetGuildStatus(EntityMailBox& sender_mb, ::google::protobuf::Message *pMsg);
    //GM命令-修改公会捐赠
    bool OnPBOpenGuildJuanZeng(EntityMailBox& sender_mb, ::google::protobuf::Message* pMsg);
private:
	void SendGuildInfoToDB(const PBGuildInfo& guildInfo, UInt32 create_or_dismiss);
private:
    //系统加载数据
    uint32_t    m_nTotalGuildCount = 0;

    std::unordered_map<uint32_t, bool> m_GuildInitSuccList;
    std::unordered_map<uint32_t, bool> m_GuildLoadSuccList;

    //逻辑数据
private:
    std::unordered_map<uint32_t, tagGuildInfo> m_GuildList;
    //玩家列表
    std::unordered_map<uint32_t, GuildMgrPlayerInfo> m_PlayerList;
    //公会已使用的名称
    std::unordered_map<string, uint8_t> m_GuildUsedName;

    //玩家的申请信息
    std::unordered_map<uint32_t, PlayerApplyInfo> m_PlayerApplyMap;
	//玩家的邀请信息
	std::unordered_map<uint32_t, PlayerInviteInfo> m_PlayerInviteMap;
    //公会数据缓存，用来确保成功创建公会
    std::unordered_map<uint32_t, PBGuildInfo> m_cacheGuidInfo;
    uint64_t m_lastLoadGuildTime;
	//初始化数据定时器
	CDelayCallback2      m_InitDelay;
    CDelayCallback2      m_CheckLoadGuild;
};

