
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
¢w
guild.proto
user.proto"y
PBGuildItemData
grid_id (RgridId
item_uid (RitemUid
item_id (RitemId
item_num (RitemNum"D
PBGuildItemListData-
	item_list (2.PBGuildItemDataRitemList"x
PBGuildApplyUserBaseInfo=
playerSimpleInfo (2.PBUserSimpleInfoRplayerSimpleInfo

apply_time (R	applyTime"P
PBGuildUserApplyList8

apply_list (2.PBGuildApplyUserBaseInfoR	applyList"Â
PBGuildMemberData
uid (Ruid
nickname (	Rnickname
duty_id (RdutyId

contribute (R
contribute'
week_contribute (RweekContribute
online (Ronline/
last_get_salary_time (RlastGetSalaryTime
	join_time (RjoinTime
dkp	 (Rdkp 
b_spoils_mgr
 (R
bSpoilsMgr&
last_send_spoil (RlastSendSpoil"V
PBGuildUserData
uid (Ruid1

guild_data (2.PBGuildMemberDataR	guildData" 
PBGuildRecordInfo
record_type (R
recordType
nickname (Rnickname
record_time (R
recordTime
	duty_name (	RdutyName
guild_level (R
guildLevel

guild_name (	R	guildName

target_uid (R	targetUid
duty_id (RdutyId$
gkd_change_num	 (RgkdChangeNum
gkd_cur_num
 (R	gkdCurNum
gkd_desc (	RgkdDesc
item_id (RitemId
gubi_num (RgubiNum

contribute (R
contribute)
spoils_item (2.PBItemSR
spoilsItem!
season_point (RseasonPoint
op_mgr_name (	R	opMgrName
rechage_num (R
rechageNum"Ö
PBGuildDutyInfo
duty_id (RdutyId
	duty_name (RdutyName

duty_right (R	dutyRight

duty_level (R	dutyLevel"ô
PBGuidJoinCon
can_join (RcanJoin
min_rank (RminRank
	min_level (RminLevel
notice (	Rnotice

join_check (R	joinCheck"◊
PBGuildSimpleInfo
	node_name$ (	RnodeName
guild_id (RguildId
name (Rname
level (Rlevel!
president_id (RpresidentId%
president_name (RpresidentName

build_time (R	buildTime
exp (Rexp

contribute (R
contribute

activeness	 (R
activeness
status
 (Rstatus$
accouncenment (Raccouncenment!
member_count (RmemberCount(
member_max_count (RmemberMaxCount)
join_con (2.PBGuidJoinConRjoinCon+
recommend_endtime (RrecommendEndtime
item_headid (R
itemHeadid!
item_frameid (RitemFrameid"F
PBGuildSimpleList1

guild_list (2.PBGuildSimpleInfoR	guildList"F
PBGuildMemberList1
member_list (2.PBGuildUserDataR
memberList"@
PBGuildDutyList-
	duty_list (2.PBGuildDutyInfoRdutyList"O
PBGuildRewardInfo
	reward_id (RrewardId

reward_num (R	rewardNum"A
PBGuildRewardList,
rewards (2.PBGuildRewardInfoRrewards"x
PBGuildTaskInfo
task_id (RtaskId

start_time (R	startTime
cur_num (RcurNum
state (Rstate"9
PBGuildTaskList&
items (2.PBGuildTaskInfoRitems"Z
PBGuildShopItemPrice!
priclog_type (RpriclogType
price_count (R
priceCount"Ø
PBGuildShopItemInfo
s_id (RsId4

item_price (2.PBGuildShopItemPriceR	itemPrice
	buy_count (RbuyCount
item_id (RitemId
pre_time (RpreTime"E
PBGuildShopItemInfoList*
items (2.PBGuildShopItemInfoRitems"©	
PBGuildInfoDB
guild_id (RguildId
name (Rname
level (Rlevel!
president_id (RpresidentId%
president_name (RpresidentName

build_time (R	buildTime
exp (Rexp

contribute (R
contribute

activeness	 (R
activeness
status
 (Rstatus

master_ids (R	masterIds5
members (2.PBGuildInfoDB.MembersEntryRmembers!
member_count (RmemberCount(
member_num_level (RmemberNumLevel$
member_max_num (RmemberMaxNum$
accouncenment (Raccouncenment4

apply_list (2.PBGuildUserApplyListR	applyList
freeze_time (R
freezeTime
apply_count (R
applyCount!
destory_time (RdestoryTime-
	duty_list (2.PBGuildDutyListRdutyList:
announcenment_modify_time (RannouncenmentModifyTime+
season_activeness (RseasonActiveness)
join_con (2.PBGuidJoinConRjoinCon(
name_modify_time (RnameModifyTime#
spoilsmgr_ids (RspoilsmgrIds+
recommend_endtime (RrecommendEndtime
item_headid (R
itemHeadid!
item_frameid (RitemFrameid#
open_juanzeng (RopenJuanzengN
MembersEntry
key (Rkey(
value (2.PBGuildMemberDataRvalue:8"ñ
PBGuildShopDB
guild_id (RguildId>
shop_item_list (2.PBGuildShopItemInfoListRshopItemList*
last_refresh_time (RlastRefreshTime"W
PBGuildBagDB
guild_id (RguildId,
bag_item_list (2.PBItemSRbagItemList"a
PBGuildRecordDB
guild_id (RguildId3
record_list (2.PBGuildRecordInfoR
recordList"Ö
PBGuildUserGuildFullData-

guild_info (2.PBGuildInfoDBR	guildInfo:
self_guild_data (2.PBGuildMemberDataRselfGuildData"ù
PBGuildInviteRecordInfo

invite_uid (R	inviteUid
invite_name (	R
inviteNameB
invite_guild_simple (2.PBGuildSimpleInfoRinviteGuildSimple"G
PBGuildInviteList2
invites (2.PBGuildInviteRecordInfoRinvites"K
PBGuildSpoilsItem
item_id (RitemId

item_count (R	itemCount"H
PBGuildSpoilsItemList/
	item_list (2.PBGuildSpoilsItemRitemList"K
PBUserApplyInfo
guild_id (RguildId

apply_time (R	applyTime"G
PBUserGuildApplyList/

apply_list (2.PBUserApplyInfoR	applyList"q
PBGuildAddItems2BagCmd
guild_id (RguildId
items (2.PBItemSRitems

add_or_del (RaddOrDel"4
PBGuildAddItemsCmd
items (2.PBItemSRitems"4
PBGuildDelItemsCmd
items (2.PBItemSRitems"P
PBGuildUpdateGuildUserDataCmd/
	user_data (2.PBGuildMemberDataRuserData":
PBGuildUpdateGuildBagCmd
items (2.PBItemSRitems"9
PBGuildUpdateGuildLevelCmd
	new_level (RnewLevel"6
"PBGuildUpgradeMemberMaxcountReqCmd
uid (Ruid"p
"PBGuildUpgradeMemberMaxcountRspCmd.
cur_member_maxcount (RcurMemberMaxcount
sucucess (Rsucucess"R
PBGuildDonateReqCmd
uid (Ruid
num (Rnum
item_id (RitemId"@
PBGuildDonateRspCmd
num (Rnum
item_id (RitemId"*
PBGuildGetSalaryReqCmd
uid (Ruid"?
PBGuildGetSalaryRspCmd%
	get_items (2.PBItemSRgetItems"I
PBGuildUpdateDutyListCmd-
	duty_list (2.PBGuildDutyListRdutyList"T
PBGuildUpdateGuildRecordInfoCmd1
record_list (2.PBGuildRecordDBR
recordList"J
PBGuildGetMembersReqCmd

page_index (R	pageIndex
uid (Ruid"â
PBGuildGetMembersRspCmd

page_index (R	pageIndex!
member_count (RmemberCount,
members (2.PBGuildMemberListRmembers"A
PBGuildBoardcastPlayerApplyCmd
apply_count (R
applyCount"i
PBGuildBoardcastPlayerJoinCmd-
	user_info (2.PBGuildUserDataRuserInfo
guild_id (RguildId"L
PBGuildBoardcastPlayerExitCmd
uid (Ruid
guild_id (RguildId"<
PBGuildBoardcastGuildDismissCmd
guild_id (RguildId"v
 PBGuildUpdateMeApplyGuildListCmd9
me_apply_list (2.PBUserGuildApplyListRmeApplyList
b_apply (RbApply"R
PBGuildFullDataUpdateCmd6
	full_data (2.PBGuildUserGuildFullDataRfullData"Ω
PBGuildPlayerSetGuildInfoCmd
node_id (RnodeId
guild_id (RguildId

guild_name (R	guildName
guild_level (R
guildLevel)
guild_prosperity (RguildProsperity"€
PBGuildGetGuildListReqCmd
idx (Ridx
uid (Ruid
	sort_type (RsortType
b_asc (RbAsc
	min_level (RminLevel
	max_level (RmaxLevel(
min_member_count (RminMemberCount(
max_member_count (RmaxMemberCount

page_count	 (R	pageCount

brecomment
 (R
brecomment
	bjoin_con (RbjoinCon"á
PBGuildGetGuildListRspCmd1

guild_list (2.PBGuildSimpleListR	guildList
	sort_type (RsortType
b_asc (RbAsc
	min_level (RminLevel
	max_level (RmaxLevel(
min_member_count (RminMemberCount(
max_member_count (RmaxMemberCount
	max_count (RmaxCount

page_count	 (R	pageCount

brecomment
 (R
brecomment
	bjoin_con (RbjoinCon"K
PBGuildCreateGuildReqCmd
uid (Ruid

guild_name (R	guildName"h
PBGuildCreateGuildRspCmd
code (Rcode
guild_id (RguildId

guild_name (R	guildName"∏
PBGuildApplyJoinGuildReqCmd
guild_id (RguildId
uid (Ruid
b_apply (RbApply
applyer_uid (R
applyerUid2
simple_info (2.PBUserSimpleInfoR
simpleInfo"8
PBGuildApplyJoinGuildRspCmd
guild_id (RguildId"o
!PBGuildAnswerApplyJoinGuildReqCmd
applyer_uid (R
applyerUid
b_agree (RbAgree
uid (Ruid"]
!PBGuildAnswerApplyJoinGuildRspCmd
applyer_uid (R
applyerUid
b_agree (RbAgree">
PBGuildSearchGuildReqCmd
key (Rkey
uid (Ruid"K
PBGuildSearchGuildRspCmd/
	guid_info (2.PBGuildSimpleInfoRguidInfo"u
PBGuildInviteJoinGuildReqCmd
uid (Ruid
invited_key (	R
invitedKey"
be_invite_uid (RbeInviteUid"?
PBGuildInviteJoinGuildRspCmd
invited_uid (R
invitedUid"ë
"PBGuildAnswerInviteJoinGuildReqCmd
inviter_uid (R
inviterUid
b_agree (RbAgree
uid (Ruid
applyer_uid (R
applyerUid"%
PBGuildQuitReqCmd
uid (Ruid"'
PBGuildQuitRspCmd
code (Rcode"G
PBGuildExpelQuitReqCmd
	expel_uid (RexpelUid
uid (Ruid"5
PBGuildExpelQuitRspCmd
	expel_uid (RexpelUid"^
PBGuildGrantReqCmd

target_uid (R	targetUid
duty_id (RdutyId
uid (Ruid"L
PBGuildGrantRspCmd

target_uid (R	targetUid
duty_id (RdutyId"F
PBGuildDemiseReqCmd

target_uid (R	targetUid
uid (Ruid"c
PBGuildDemiseRspCmd$
new_master_uid (RnewMasterUid&
new_master_name (	RnewMasterName"(
PBGuildDismissReqCmd
uid (Ruid"
PBGuildDismissRspCmd"%
PBGuildThawReqCmd
uid (Ruid"
PBGuildThawRspCmd"^
PBGuildModifyAnnouncementReqCmd)
new_announcement (RnewAnnouncement
uid (Ruid"m
PBGuildModifyAnnouncementRspCmd)
new_announcement (RnewAnnouncement
modify_time (R
modifyTime"E
PBGuildAddDutyReqCmd
	duty_name (RdutyName
uid (Ruid"S
PBGuildAddDutyRspCmd
new_duty_id (R	newDutyId
	duty_name (RdutyName"A
PBGuildDelDutyReqCmd
duty_id (RdutyId
uid (Ruid"/
PBGuildDelDutyRspCmd
duty_id (RdutyId"v
PBGuildModifyDutyRightReqCmd
uid (Ruid
duty (Rduty
	new_right (RnewRight
b_set (RbSet"O
PBGuildModifyDutyRightRspCmd
duty (Rduty
	new_right (RnewRight"c
PBGuildModifyDutyNameReqCmd
duty_id (RdutyId
new_name (RnewName
uid (Ruid"Q
PBGuildModifyDutyNameRspCmd
duty_id (RdutyId
new_name (RnewName"f
PBGuildModifyDutyLevelReqCmd
duty_id (RdutyId
	new_level (RnewLevel
uid (Ruid"T
PBGuildModifyDutyLevelRspCmd
duty_id (RdutyId
	new_level (RnewLevel"(
PBGuildUpgradeReqCmd
uid (Ruid"3
PBGuildUpgradeRspCmd
	new_level (RnewLevel"L
PBGuildModifyHeadIconReqCmd
	head_icon (RheadIcon
uid (Ruid":
PBGuildModifyHeadIconRspCmd
	head_icon (RheadIcon"-
PBGuildGetApplyListReqCmd
uid (Ruid"r
PBGuildGetApplyListRspCmd4

apply_list (2.PBGuildUserApplyListR	applyList
total_count (R
totalCount"K
PBGuildModifyGuildNameReqCmd
new_name (	RnewName
uid (Ruid"K
PBGuildModifyGuildNameRspCmd
new_name (	RnewName
uid (Ruid"a
PBGuildExchangeItemReqCmd
uid (Ruid
item_id (RitemId
item_num (RitemNum"O
PBGuildExchangeItemRspCmd
item_id (RitemId
item_num (RitemNum"D
PBGuildAcceptTaskReqCmd
uid (Ruid
task_id (RtaskId"2
PBGuildAcceptTaskRspCmd
task_id (RtaskId"G
PBGuildGetTaskRewardReqCmd
uid (Ruid
task_id (RtaskId"j
PBGuildGetTaskRewardRspCmd
task_id (RtaskId3
reward_list (2.PBGuildRewardListR
rewardList"L
PBGuildUpdateTaskInfoRspCmd-
	task_info (2.PBGuildTaskInfoRtaskInfo"L
PBGuildUpdateTaskListRspCmd-
	all_tasks (2.PBGuildTaskListRallTasks"X
PBGuildUpdateGuildInfoRspCmd8

guild_info (2.PBGuildUserGuildFullDataR	guildInfo"\
PBSetGuildJoinConditionReqCmd
uid (Ruid)
join_con (2.PBGuidJoinConRjoinCon"J
PBSetGuildJoinConditionRspCmd)
join_con (2.PBGuidJoinConRjoinCon"]
!PBGuildUpdateMeInviteGuildListCmd8
me_invite_list (2.PBGuildInviteListRmeInviteList"ﬂ
PBGuildRecordListReqCmd
log_type (RlogType
idx (Ridx
uid (Ruid
	sort_type (RsortType
b_asc (RbAsc
	b_manager (RbManager
des_uid (RdesUid

page_count (R	pageCount"˝
PBGuildRecordListRspCmd
log_type (RlogType
idx (Ridx
uid (Ruid
	sort_type (RsortType
b_asc (RbAsc1
record_list (2.PBGuildRecordDBR
recordList
total_count	 (R
totalCount

page_count
 (R	pageCount"[
PBGuildSetSpoilsMgrReqCmd
uid (Ruid
b_set (RbSet
des_uid (RdesUid"a
PBGuildSetSpoilsMgrRspCmd
sucess (Rsucess
b_set (RbSet
des_uid (RdesUid"v
PBGuildDkpChangeReqCmd
uid (Ruid

change_num (R	changeNum
des_uid (RdesUid
desc (	Rdesc"}
PBGuildDkpChangeRspCmd

change_num (R	changeNum
des_uid (RdesUid
cur_dkp (RcurDkp
desc (	Rdesc"r
PBGuildSendSpoilsReqCmd
uid (Ruid
des_uid (RdesUid,
slist (2.PBGuildSpoilsItemListRslist"1
PBGuildSendSpoilsRspCmd
sucess (Rsucess"H
PBGuildUpdateShopReqCmd
uid (Ruid
	tab_index (RtabIndex"n
PBGuildUpdateShopInfoCmd
	tab_index (RtabIndex5
	item_list (2.PBGuildShopItemInfoListRitemList"{
PBGuildShopBuyItemReqCmd
uid (Ruid
	tab_index (RtabIndex
s_id (RsId

item_count (R	itemCount"Å
PBGuildShopBuyItemRspCmd
	tab_index (RtabIndex
s_id (RsId

item_count (R	itemCount
sucess (Rsucess"p
PBGuildDayMissionAwardReqCmd
uid (Ruid
day_mission (R
dayMission

mission_id (R	missionId"z
PBGuildDayMissionAwardRspCmd
code (Rcode%
	item_list (2.PBItemSRitemList
day_mission (R
dayMission"-
PBGuildBuyRecommentReqCmd
uid (Ruid"r
PBGuildBuyRecommentRspCmd
uid (Ruid
sucess (Rsucess+
recommend_endtime (RrecommendEndtime"l
PBGuildSetHeadReqCmd
uid (Ruid
item_headid (R
itemHeadid!
item_frameid (RitemFrameid"Z
PBGuildSetHeadRspCmd
item_headid (R
itemHeadid!
item_frameid (RitemFrameid"H
PBSetGuildStatusCmd
guild_id (RguildId
status (Rstatus"X
PBOpenGuildJuanZengCmd
guild_id (RguildId#
open_juanzeng (RopenJuanzeng*m
enPBGuildStatus	
eNone 
eGS_Creating
eGS_Init

eGS_Normal

eGS_Freeze
eGS_Destory*ú
enGuildRecordType
eRT_ALL_RECORD 
eRT_DUTY_CHANGE
eRT_JOIN
eRT_QUIT
eRT_CHANGE_GUILD_NAME
ERT_JUANZENG
eRT_GUILD_LV_UP
ERT_GUILDBAG
ERT_GUILDRANKRECORD
ERT_GUILDGKD	
ERT_SPOILS_GRANT

ERT_SEASON_POINT
ERT_PLAYER_RECHARGE*0
	eApplyOpt
AO_NONE 

AO_ADD

AO_DELbproto3
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
µ

room.proto
user.proto"⁄
PBRoomSearchInfo
roomid (Rroomid
chapter (Rchapter

difficulty (R
difficulty
	playercnt (R	playercnt
	master_id (RmasterId
master_name (	R
masterName
needpwd (Rneedpwd"v
PBRoomMemberInfo
seat_idx (RseatIdx
is_ready (RisReady,
mem_info (2.PBUserSimpleInfoRmemInfo"∏

PBRoomInfo
roomid (Rroomid
isopen (Risopen
needpwd (Rneedpwd
pwd (	Rpwd
chapter (Rchapter

difficulty (R
difficulty
state (Rstate"§
PBCreateRoomReqCmd
uid (Ruid
isopen (Risopen
needpwd (Rneedpwd
pwd (	Rpwd
chapter (Rchapter

difficulty (R
difficulty"V
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
	room_data (2.PBRoomInfoRroomData"=
PBApplyRoomReqCmd
uid (Ruid
roomid (Rroomid"U
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
roomid (Rroomid"`
PBEnterRoomSyncCmd
roomid (Rroomid2
member_data (2.PBRoomMemberInfoR
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
member_datas (2.PBRoomMemberInfoRmemberDatas"A
PBStartGameRoomReqCmd
uid (Ruid
roomid (Rroomid"k
PBStartGameRoomRspCmd
code (Rcode
error (	Rerror
uid (Ruid
roomid (Rroomid"b
PBEnterDsRoomSyncCmd
roomid (Rroomid

ds_address (	R	dsAddress
ds_ip (	RdsIpbproto3
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