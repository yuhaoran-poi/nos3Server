
∂
activity.proto"_
PBActivityData
activity_id (R
activityId
beg_ts (RbegTs
end_ts (RendTs"+
PBGetActivityInfoReqCmd
uid (Ruid"ç
PBGetActivityInfoRspCmd
code (Rcode
error (	Rerror
uid (Ruid6
activity_datas (2.PBActivityDataRactivityDatasbproto3
Ï

auth.proto"™
PBUserLoginData
uid (Ruid
steam_id (RsteamId
auth_key (	RauthKey
auth_ticket (	R
authTicket
macid (Rmacid
version (	Rversion"w
PBLobbyLoginData
uid (Ruid
	login_key (	RloginKey
version (	Rversion
password (	Rpassword"F
PBClientLoginReqCmd/

login_data (2.PBUserLoginDataR	loginData"h
PBClientLoginRspCmd
code (Rcode
error (	Rerror
uid (Ruid
net_id (RnetIdbproto3
ﬂ
common.proto"ì
PBMessagePack
net_id (RnetId
	broadcast (R	broadcast
stub_id (RstubId
msg_type (RmsgType
msg_body (RmsgBody"9
PBPacketCmd*
messages (2.PBMessagePackRmessages":
	PBPingCmd
src_gnId (RsrcGnId
time (Rtime":
	PBPongCmd
src_gnId (RsrcGnId
time (Rtimebproto3
È
friend.proto"Ú
PBFriendData
uid (Ruid
head_id (RheadId
	nick_name (	RnickName#
account_level (RaccountLevel!
online_state (RonlineState!
friend_level (RfriendLevel
group_id (RgroupId
friend_time (R
friendTime

head_frame	 (R	headFrame
title
 (Rtitle

guild_name (	R	guildName
name_remark (	R
nameRemark"Û
PBApplyFriendData
uid (Ruid
head_id (RheadId
	nick_name (	RnickName#
account_level (RaccountLevel

apply_time (R	applyTime

head_frame (R	headFrame
title (Rtitle

guild_name (	R	guildName")
PBGetFriendInfoReqCmd
uid (Ruid"∫
PBGetFriendInfoRspCmd
code (Rcode
error (	Rerror
uid (Ruid0
friend_datas (2.PBFriendDataRfriendDatas3
apply_datas (2.PBApplyFriendDataR
applyDatasbproto3
©
guild.proto"”
PBApplyGuildData
uid (Ruid
head_id (RheadId
	nick_name (	RnickName#
account_level (RaccountLevel

apply_time (R	applyTime

head_frame (R	headFrame
title (Rtitle"j
PBApplyGuildReqCmd.
	user_data (2.PBApplyGuildDataRuserData$
apply_guild_id (RapplyGuildId"P
PBApplyGuildRspCmd
code (Rcode
error (	Rerror
uid (Ruidbproto3
∏

mail.proto"D

PBMailItem
item_id (RitemId

item_count (R	itemCount"ú

PBMailData
mail_id (RmailId
	mail_type (RmailType
beg_ts (RbegTs
end_ts (RendTs

mail_title (	R	mailTitle!
mail_content (	RmailContent
is_read (RisRead
is_get (RisGet
is_del	 (RisDel!
items
 (2.PBMailItemRitems"@
PBGetMailItemReqCmd
uid (Ruid
mail_id (RmailId"{
PBGetMailItemRspCmd
code (Rcode
error (	Rerror
uid (Ruid(
	mail_data (2.PBMailDataRmailDatabproto3
ù
mission.proto"•
PBConditionData
cond_id (RcondId
	cond_type (RcondType
cond_target (R
condTarget
progress (Rprogress
is_complete (R
isComplete"Ë
PBMissionData

mission_id (R	missionId!
mission_type (RmissionType
is_complete (R
isComplete
is_get (RisGet
beg_ts (RbegTs
end_ts (RendTs/

cond_datas (2.PBConditionDataR	condDatas"é
PBUpdateMissionSeverSyncCmd
uid (Ruid
cond_id (RcondId
	cond_type (RcondType'
update_progress (RupdateProgress"`
PBUpdateMissionClientSyncCmd@
update_mission_datas (2.PBMissionDataRupdateMissionDatasbproto3
Ÿ

rank.proto"a

PBRankData
id (Rid
idx (Ridx
score (Rscore
	rank_data (	RrankData"v

PBRankInfo
rank_id (RrankId
beg_ts (RbegTs
end_ts (RendTs!
datas (2.PBRankDataRdatas"@
PBGetRankInfoReqCmd
uid (Ruid
rank_id (RrankId"•
PBGetRankInfoRspCmd
code (Rcode
error (	Rerror
uid (Ruid(
	rank_info (2.PBRankInfoRrankInfo(
	self_data (2.PBRankDataRselfDatabproto3
“

team.proto"≥
PBTeamApplyData
uid (Ruid
head_id (RheadId
	nick_name (	RnickName#
account_level (RaccountLevel

head_frame (R	headFrame
title (Rtitle"n
PBApplyTeamReqCmd
uid (Ruid
teamid (Rteamid/

apply_info (2.PBTeamApplyDataR	applyInfo"O
PBApplyTeamRspCmd
code (Rcode
error (	Rerror
uid (Ruid"E
PBApplyTeamSyncCmd/

apply_data (2.PBTeamApplyDataR	applyDatabproto3
È
trade.proto"ç
PBTradeBankProductData
trade_id (RtradeId

product_id (R	productId
cur_num (RcurNum
book_num (RbookNum
sale_num (RsaleNum
price (Rprice
uid (Ruid
beg_ts (RbegTs
end_ts	 (RendTs
state
 (Rstate"t
PBSelfTradeBankData!
box_capacity (RboxCapacity:
product_list (2.PBTradeBankProductDataRproductList",
PBGetTradeBankInfoReqCmd
uid (Ruid"ù
PBGetTradeBankInfoRspCmd
code (Rcode
error (	Rerror
uid (RuidE
self_trade_bank_info (2.PBSelfTradeBankDataRselfTradeBankInfobproto3
ç

user.proto"^
PBGetOpenBoxReqCmd
uid (Ruid
item_id (RitemId

item_count (R	itemCount"ñ
PBGetOpenBoxRspCmd
code (Rcode
error (	Rerror
uid (Ruid
get_item_id (R	getItemId$
get_item_count (RgetItemCountbproto3
‰
google/protobuf/any.protogoogle.protobuf"6
Any
type_url (	RtypeUrl
value (RvalueBv
com.google.protobufBAnyProtoPZ,google.golang.org/protobuf/types/known/anypb¢GPB™Google.Protobuf.WellKnownTypesbproto3