
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
Ô

auth.proto"»
PBUserLoginData
uid (Ruid
steam_id (RsteamId
authkey (	Rauthkey
auth_ticket (	R
authTicket
macid (Rmacid
version (	Rversion

pb_version (	R	pbVersion"É
PBClientLoginReqCmd/

login_data (2.PBUserLoginDataR	loginData
is_register (R
isRegister
password (	Rpassword"á
PBClientLoginRspCmd
code (Rcode
error (	Rerror
uid (Ruid
net_id (RnetId

reconn_key (	R	reconnKeybproto3
©
common.proto"ì
PBMessagePack
net_id (RnetId
	broadcast (R	broadcast
stub_id (RstubId
msg_type (RmsgType
msg_body (RmsgBody"9
PBPacketCmd*
messages (2.PBMessagePackRmessages"
	PBPingCmd
time (Rtime"
	PBPongCmd
time (Rtimebproto3
å
friend.proto"Í
PBFriendData
uid (Ruid
head_id (RheadId
	nick_name (	RnickName#
account_level (RaccountLevel!
online_state (RonlineState
group_id (RgroupId
friend_time (R
friendTime

head_frame (R	headFrame
title	 (Rtitle
guild_id
 (RguildId

guild_name (	R	guildName
name_remark (	R
nameRemark"Ô
PBApplyFriendData
uid (Ruid
head_id (RheadId
	nick_name (	RnickName#
account_level (RaccountLevel

head_frame (R	headFrame
title (Rtitle
guild_id (RguildId

guild_name (	R	guildName")
PBGetFriendInfoReqCmd
uid (Ruid"∫
PBGetFriendInfoRspCmd
code (Rcode
error (	Rerror
uid (Ruid0
friend_datas (2.PBFriendDataRfriendDatas3
apply_datas (2.PBApplyFriendDataR
applyDatas"Z
PBApplyFriendReqCmd
uid (Ruid1

apply_data (2.PBApplyFriendDataR	applyData"Q
PBApplyFriendRspCmd
code (Rcode
error (	Rerror
uid (Ruidbproto3
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
˚O

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
get_item_count (RgetItemCount"D
PBCoin
	coin_type (RcoinType

coin_count (R	coinCount"9

PBBlessing
bless_id (RblessId
idx (Ridx"/
PBAttribute
id (Rid
val (Rval"8
PBSkill
	config_id (RconfigId
idx (Ridx"·
PBItem
	config_id (RconfigId

item_count (R	itemCount
	item_type (RitemType
up_level (RupLevel
up_exp (RupExp

star_level (R	starLevel-
exattr_list (2.PBAttributeR
exattrList"b
PBItemSimple
	config_id (RconfigId

item_count (R	itemCount
uniqid (Runiqid"z
PBBlock
idx (Ridx
	config_id (RconfigId
uniqid (Runiqid(
item_detail (2.PBItemR
itemDetail"J

PBUniqItem$
	item_info (2.PBItemRitemInfo
uniqid (Runiqid"ß
PBMagicItem$
	item_info (2.PBItemRitemInfo
uniqid (Runiqid
used_id (RusedId
idx (Ridx
	light_cnt (RlightCnt
tags (Rtags"´
PBMagicItemImage
	config_id (RconfigId
get_ts (RgetTs
up_level (RupLevel
up_exp (RupExp

star_level (R	starLevel
tier (Rtier"N
PBMagicItemImageS9
item_image_list (2.PBMagicItemImageRitemImageList"™
PBDiagramsCard$
	item_info (2.PBItemRitemInfo
uniqid (Runiqid
used_id (RusedId
idx (Ridx
	light_cnt (RlightCnt
tags (Rtags"Æ
PBDiagramsCardImage
	config_id (RconfigId
get_ts (RgetTs
up_level (RupLevel
up_exp (RupExp

star_level (R	starLevel
tier (Rtier"T
PBDiagramsCardImageS<
item_image_list (2.PBDiagramsCardImageRitemImageList"N
PBSecretPaper$
	item_info (2.PBItemRitemInfo
used_id (RusedId"^
PBTabooWord$
	item_info (2.PBItemRitemInfo
used_id (RusedId
idx (Ridx"ÿ
PBSkin$
	item_info (2.PBItemRitemInfo;
experience_card_start_time (RexperienceCardStartTime7
experience_card_end_time (RexperienceCardEndTime
add_time (RaddTime
used_id (RusedId"˙
PBSealMonsterSkin$
	item_info (2.PBItemRitemInfo;
experience_card_start_time (RexperienceCardStartTime7
experience_card_end_time (RexperienceCardEndTime
add_time (RaddTime.
used_monster_uniqid (RusedMonsterUniqid"L
PBMinorStar$
	item_info (2.PBItemRitemInfo
used_id (RusedId"t
	PBTrigram$
	item_info (2.PBItemRitemInfo
uniqid (Runiqid
used_id (RusedId
idx (Ridx"Å
	PBAweItem$
	item_info (2.PBItemRitemInfo
used_id (RusedId
idx (Ridx#
up_lv_fail_cnt (RupLvFailCnt"y
PBMonsterEquip$
	item_info (2.PBItemRitemInfo
uniqid (Runiqid
used_id (RusedId
idx (Ridx"P
PBMonsterEquipS=
monster_equip_list (2.PBMonsterEquipRmonsterEquipList"D
PBTabooWordS4
taboo_word_list (2.PBTabooWordRtabooWordList"P
PBDiagramsCardS=
diagrams_card_list (2.PBDiagramsCardRdiagramsCardList"˛
PBSealMonster$
	item_info (2.PBItemRitemInfo
uniqid (Runiqid
life (Rlife
	ghost_air (RghostAir/
monster_skills (2.PBSkillRmonsterSkills+
cache_skills (2.PBSkillRcacheSkills>
monster_equip_data (2.PBMonsterEquipSRmonsterEquipData(
unlock_equip_num (RunlockEquipNum"
dress_skin_id	 (RdressSkinId
	nick_name
 (	RnickName5
taboo_word_data (2.PBTabooWordSRtabooWordData>
diagrams_card_data (2.PBDiagramsCardSRdiagramsCardData"A
PBMagicMark
	config_id (RconfigId
get_ts (RgetTs"4
PBStarSymbol$
	item_info (2.PBItemRitemInfo"n
PBMainStarEffect$
	item_info (2.PBItemRitemInfo
used_id (RusedId
	is_unlock (RisUnlock"•

PBMainStar$
	item_info (2.PBItemRitemInfo
used_id (RusedId
	is_unlock (RisUnlock;
main_star_effect (2.PBMainStarEffectRmainStarEffect"
PBAuctionExtra
up_level (RupLevel
up_exp (RupExp

star_level (R	starLevel-
exattr_list (2.PBAttributeR
exattrList!
element_tags (RelementTags
tags (Rtags
life (Rlife
	ghost_air (RghostAir/
monster_skills	 (2.PBSkillRmonsterSkills(
unlock_equip_num
 (RunlockEquipNum
	nick_name (	RnickName"/
PBCoinS$
	coin_list (2.PBCoinRcoinList"/
PBItemS$
	item_list (2.PBItemRitemList"@
PBUniqItemS1
uniq_item_list (2.PBUniqItemRuniqItemList"/
PBSkinS$
	skin_list (2.PBSkinRskinList"]
PBSealMonsterSkinSG
seal_monster_skin_list (2.PBSealMonsterSkinRsealMonsterSkinList"D
PBMagicItemS4
magic_item_list (2.PBMagicItemRmagicItemList"L
PBSecretPaperS:
secret_paper_list (2.PBSecretPaperRsecretPaperList"D
PBMinorStarS4
minor_star_list (2.PBMinorStarRminorStarList";

PBTrigramS-
trigram_list (2
.PBTrigramRtrigramList"<

PBAweItemS.
awe_item_list (2
.PBAweItemRaweItemList"L
PBSealMonsterS:
seal_monster_list (2.PBSealMonsterRsealMonsterList"D
PBMagicMarkS4
magic_mark_list (2.PBMagicMarkRmagicMarkList"H
PBStarSymbolS7
star_symbol_list (2.PBStarSymbolRstarSymbolList"A
PBItemImage
	config_id (RconfigId
get_ts (RgetTs"D
PBItemImageS4
item_image_list (2.PBItemImageRitemImageList"@
PBMainStarS1
main_star_list (2.PBMainStarRmainStarList"Y
PBMainStarEffectSD
main_star_effect_list (2.PBMainStarEffectRmainStarEffectList"Ä
PBGourd
gourd_id (RgourdId
	nick_name (	RnickName
up_level (RupLevel
up_exp (RupExp!
total_talent (RtotalTalent

cur_talent (R	curTalent-
talent_attr (2.PBAttributeR
talentAttr
	cd_end_ts	 (RcdEndTs"3
PBGourdS'

gourd_list (2.PBGourdR	gourdList"=
PBPlayedGodsData
idx (Ridx
gods_id (RgodsId"P
PBPlayedGodsDataS;
played_gods_list (2.PBPlayedGodsDataRplayedGodsList"h
PBGodsDataS
	gods_list (RgodsList<
played_gods_data (2.PBPlayedGodsDataSRplayedGodsData"I
PBEnt
	config_id (RconfigId#
entry_quality (RentryQuality"ú
	PBAntique
uniq_id (RuniqId
quality (Rquality
price (2.PBCoinRprice.
remain_identify_num (RremainIdentifyNum'
identify_result (RidentifyResult
is_show (RisShow$
	item_info (2.PBItemRitemInfo%

entry_list (2.PBEntR	entryList";

PBAntiqueS-
antique_list (2
.PBAntiqueRantiqueList"‚
PBBagNormal%
	coin_data (2.PBCoinSRcoinData%
	item_data (2.PBItemSRitemData3
treasurebox_data (2.PBItemSRtreasureboxData%
	gift_data (2.PBItemSRgiftData;
secret_paper_data (2.PBSecretPaperSRsecretPaperData5
taboo_word_data (2.PBTabooWordSRtabooWordData5
minor_star_data (2.PBMinorStarSRminorStarData"ü
	PBBagUniq2
uniq_item_data (2.PBUniqItemSRuniqItemData.
trigram_data (2.PBTrigramSRtrigramData.
antique_data (2.PBAntiqueSRantiqueData"˛
PBBagOnlyOne'

title_data (2.PBItemSR	titleData/
awe_item_data (2.PBAweItemSRaweItemData8
star_symbol_data (2.PBStarSymbolSRstarSymbolData5
item_image_data (2.PBItemImageSRitemImageData2
main_star_data (2.PBMainStarSRmainStarDataE
main_star_effect_data (2.PBMainStarEffectSRmainStarEffectData(

gourd_data (2	.PBGourdSR	gourdData"2
	PBBagSkin%
	skin_data (2.PBSkinSRskinData"ä

PBBagMagic5
magic_item_data (2.PBMagicItemSRmagicItemDataE
magic_item_image_data (2.PBMagicItemImageSRmagicItemImageData"Ÿ
PBBagSealMonster;
seal_monster_data (2.PBSealMonsterSRsealMonsterData>
monster_equip_data (2.PBMonsterEquipSRmonsterEquipDataH
seal_monster_skin_data (2.PBSealMonsterSkinSRsealMonsterSkinData"£
PBBagDiagramsCard>
diagrams_card_data (2.PBDiagramsCardSRdiagramsCardDataN
diagrams_card_image_data (2.PBDiagramsCardImageSRdiagramsCardImageData"⁄
PBBag+

normal_bag (2.PBBagNormalR	normalBag%
uniq_bag (2
.PBBagUniqRuniqBag/
only_one_bag (2.PBBagOnlyOneR
onlyOneBag%
skin_bag (2
.PBBagSkinRskinBag(
	magic_bag (2.PBBagMagicRmagicBag;
seal_monster_bag (2.PBBagSealMonsterRsealMonsterBag>
diagrams_card_bag (2.PBBagDiagramsCardRdiagramsCardBag"°
PBRankLevel6

ghost_rank (2.PBRankLevel.PBRankNodeR	ghostRank6

human_rank (2.PBRankLevel.PBRankNodeR	humanRank=
ghost_top_rank (2.PBRankLevel.PBRankNodeRghostTopRank=
human_top_rank (2.PBRankLevel.PBRankNodeRhumanTopRank£

PBRankNode
grade (Rgrade
level (Rlevel
star (Rstar
score (Rscore"
zhu_ji_points (RzhuJiPoints
	all_stars (RallStars"4
PBPinchFaceData!
setting_data (	RsettingData"©
PBUserSimpleInfo
uid (Ruid!
plateform_id (	RplateformId
	nick_name (RnickName
	head_icon (RheadIcon
sex (Rsex

praise_num (R	praiseNum

head_frame (R	headFrame.
account_create_time (RaccountCreateTime#
account_level	 (RaccountLevel
account_exp
 (R
accountExp*
account_total_exp (RaccountTotalExp
	guild_uid (RguildUid

guild_name (R	guildName+

rank_level (2.PBRankLevelR	rankLevelF
cur_show_role (2".PBUserSimpleInfo.PBCurUseShowRoleRcurShowRole8
pinch_face_data (2.PBPinchFaceDataRpinchFaceData
title (Rtitle
player_flag (R
playerFlag
online_time (R
onlineTime&
sum_online_time (RsumOnlineTime
pa_flag (RpaFlag
mons_uniqid (R
monsUniqid
mons_confid (R
monsConfid$
mons_skin_list (RmonsSkinListH
PBCurUseShowRole
role_id (RroleId
	skin_list (RskinList"/
PBClientGetUsrSimInfoReqCmd
uid (Ruid"Ä
PBClientGetUsrSimInfoRspCmd
code (Rcode
error (	Rerror
uid (Ruid%
info (2.PBUserSimpleInfoRinfo*ê
ITEM_OPERATION_TYPE
ITEM_OPERATION_TYPE_NONE 
ITEM_OPERATION_TYPE_UPDATA
ITEM_OPERATION_TYPE_DELETE
ITEM_OPERATION_TYPE_ADDbproto3
¥

room.proto
user.proto"π
PBRoomSearchInfo
roomid (Rroomid
chapter (Rchapter

difficulty (R
difficulty
	playercnt (R	playercnt
	master_id (RmasterId
needpwd (Rneedpwd"v
PBRoomMemberInfo
seat_idx (RseatIdx
is_ready (RisReady,
mem_info (2.PBUserSimpleInfoRmemInfo"¢

PBRoomInfo
roomid (Rroomid
isopen (Risopen
needpwd (Rneedpwd
pwd (	Rpwd
chapter (Rchapter

difficulty (R
difficulty"‘
PBCreateRoomReqCmd
uid (Ruid
isopen (Risopen
needpwd (Rneedpwd
pwd (	Rpwd
chapter (Rchapter

difficulty (R
difficulty.
	self_info (2.PBUserSimpleInfoRselfInfo"V
PBCreateRoomRspCmd
code (Rcode
error (	Rerror
roomid (Rroomid"ï
PBSearchRoomReqCmd
uid (Ruid
roomid (Rroomid
chapter (Rchapter

difficulty (R
difficulty
	start_idx (RstartIdx"·
PBSearchRoomRspCmd
code (Rcode
error (	Rerror
roomid (Rroomid
chapter (Rchapter

difficulty (R
difficulty
	start_idx (RstartIdx2
search_data (2.PBRoomSearchInfoR
searchData"π
PBModRoomReqCmd
uid (Ruid
roomid (Rroomid
isopen (Risopen
needpwd (Rneedpwd
pwd (	Rpwd
chapter (Rchapter

difficulty (R
difficulty"π
PBModRoomRspCmd
code (Rcode
error (	Rerror
isopen (Risopen
needpwd (Rneedpwd
pwd (	Rpwd
chapter (Rchapter

difficulty (R
difficulty"=
PBRoomInfoSyncCmd(
	room_data (2.PBRoomInfoRroomData"o
PBApplyRoomReqCmd
uid (Ruid
roomid (Rroomid0

apply_info (2.PBUserSimpleInfoR	applyInfo"U
PBApplyRoomRspCmd
code (Rcode
error (	Rerror
roomid (Rroomid"p
PBApplyRoomSyncCmd
uid (Ruid
roomid (Rroomid0

apply_info (2.PBUserSimpleInfoR	applyInfo"K
PBDealApplyRoomReqCmd
deal_uid (RdealUid
deal_op (RdealOp"u
PBDealApplyRoomRspCmd
code (Rcode
error (	Rerror
deal_uid (RdealUid
deal_op (RdealOp"õ
PBDealApplyRoomSyncCmd
roomid (Rroomid
deal_op (RdealOp

master_uid (R	masterUid
master_name (	R
masterName
pwd (	Rpwd"O
PBEnterRoomReqCmd
uid (Ruid
roomid (Rroomid
pwd (	Rpwd"g
PBEnterRoomRspCmd
code (Rcode
error (	Rerror
uid (Ruid
roomid (Rroomid"H
PBEnterRoomSyncCmd2
member_data (2.PBRoomMemberInfoR
memberData"<
PBExitRoomReqCmd
uid (Ruid
roomid (Rroomid"f
PBExitRoomRspCmd
code (Rcode
error (	Rerror
uid (Ruid
roomid (Rroomid"=
PBExitRoomSyncCmd
uid (Ruid
roomid (Rroomid"`
PBKickRoomReqCmd
self_uid (RselfUid
roomid (Rroomid
kick_uid (RkickUid"ä
PBKickRoomRspCmd
code (Rcode
error (	Rerror
self_uid (RselfUid
roomid (Rroomid
kick_uid (RkickUid"F
PBKickRoomSyncCmd
roomid (Rroomid
kick_uid (RkickUid"X
PBReadyRoomReqCmd
uid (Ruid
roomid (Rroomid
ready_op (RreadyOp"Ç
PBReadyRoomRspCmd
code (Rcode
error (	Rerror
uid (Ruid
roomid (Rroomid
is_ready (RisReady"Y
PBReadyRoomSyncCmd
uid (Ruid
roomid (Rroomid
is_ready (RisReady"?
PBGetRoomInfoReqCmd
uid (Ruid
roomid (Rroomid"ü
PBGetRoomInfoRspCmd
code (Rcode
error (	Rerror(
	room_data (2.PBRoomInfoRroomData4
member_datas (2.PBRoomMemberInfoRmemberDatasbproto3
†

team.proto
user.proto"®

PBTeamInfo
team_id (RteamId
	master_id (RmasterId.
	user_list (2.PBUserSimpleInfoRuserList
is_del (RisDel

match_type (R	matchType"K
PBTeamStatusCmd
team_id (RteamId
team_status (R
teamStatus"+
PBTeamInfoReqCmd
team_id (RteamId"P
PBTeamInfoRspCmd
code (Rcode(
	team_info (2.PBTeamInfoRteamInfo"u
PBTeamCreateReqCmd
uid (Ruid.
	base_data (2.PBUserSimpleInfoRbaseData

match_type (R	matchType"A
PBTeamCreateRspCmd
code (Rcode
team_id (RteamId"$
PBTeamExitReqCmd
uid (Ruid"&
PBTeamExitRspCmd
code (Rcode"F
PBTeamKickoutReqCmd
uid (Ruid

target_uid (R	targetUid"H
PBTeamKickoutRspCmd
code (Rcode

target_uid (R	targetUid"å
PBTeamJoinReqCmd
uid (Ruid

master_uid (R	masterUid
team_id (RteamId.
	base_data (2.PBUserSimpleInfoRbaseData"^
PBTeamJoinRspCmd
code (Rcode

master_uid (R	masterUid
team_id (RteamIdbproto3
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
‰
google/protobuf/any.protogoogle.protobuf"6
Any
type_url (	RtypeUrl
value (RvalueBv
com.google.protobufBAnyProtoPZ,google.golang.org/protobuf/types/known/anypb¢GPB™Google.Protobuf.WellKnownTypesbproto3