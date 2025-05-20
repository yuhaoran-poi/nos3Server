
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
Õ

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

reconn_key (	R	reconnKey"±
PBDSLoginData
authkey (	Rauthkey
auth_ticket (	R
authTicket
version (	Rversion

pb_version (	R	pbVersion
ds_type (RdsType
ds_id (RdsId"@
PBDSLoginReqCmd-

login_data (2.PBDSLoginDataR	loginData"f
PBDSLoginRspCmd
code (Rcode
error (	Rerror
dsid (Rdsid
net_id (RnetIdbproto3
ÉB

user.proto"@
PBCoin
coin_id (RcoinId

coin_count (R	coinCount"
PBUserCoins-
coins (2.PBUserCoins.CoinsEntryRcoinsA

CoinsEntry
key (Rkey
value (2.PBCoinRvalue:8"9

PBBlessing
bless_id (RblessId
idx (Ridx"/
PBAttribute
id (Rid
val (Rval")
PBTag
id (Rid
val (Rval":
PBSkill
	config_id (RconfigId
star (Rstar"[
PBDurabItem%
cur_durability (RcurDurability%
max_durability (RmaxDurability"î
PBMagicItem%
cur_durability (RcurDurability%
max_durability (RmaxDurability
	light_cnt (RlightCnt
tags (2.PBTagRtags"ó
PBDiagramsCard%
cur_durability (RcurDurability%
max_durability (RmaxDurability
	light_cnt (RlightCnt
tags (2.PBTagRtags"B
	PBAweItem
idx (Ridx#
up_lv_fail_cnt (RupLvFailCnt"∫
	PBAntique
price (2.PBCoinRprice.
remain_identify_num (RremainIdentifyNum
tags (2.PBTagRtags
is_fake (RisFake)
identify_histroy (RidentifyHistroy"ú
PBItemCommon
	config_id (RconfigId
uniqid (Runiqid

item_count (R	itemCount
	item_type (RitemType
	trade_cnt (RtradeCnt"ı
PBItemSpecial+

durab_item (2.PBDurabItemR	durabItem+

magic_item (2.PBMagicItemR	magicItem4
diagrams_item (2.PBDiagramsCardRdiagramsItem%
awe_item (2
.PBAweItemRaweItem-
antique_item (2
.PBAntiqueRantiqueItem"Ö

PBItemData
itype (Ritype.
common_info (2.PBItemCommonR
commonInfo1
special_info (2.PBItemSpecialRspecialInfo"b
PBItemSimple
	config_id (RconfigId

item_count (R	itemCount
uniqid (Runiqid"Ä
PBAuctionExtra
up_level (RupLevel
up_exp (RupExp

star_level (R	starLevel-
exattr_list (2.PBAttributeR
exattrList)
element_tags (2.PBTagRelementTags
tags (2.PBTagRtags
life (Rlife
	ghost_air (RghostAir/
monster_skills	 (2.PBSkillRmonsterSkills(
unlock_equip_num
 (RunlockEquipNum
	nick_name (	RnickName"=
PBPlayedGodsData
idx (Ridx
gods_id (RgodsId"P
PBPlayedGodsDataS;
played_gods_list (2.PBPlayedGodsDataRplayedGodsList"h
PBGodsDataS
	gods_list (RgodsList<
played_gods_data (2.PBPlayedGodsDataSRplayedGodsData"∑
PBBag"
bag_item_type (RbagItemType
capacity (Rcapacity'
items (2.PBBag.ItemsEntryRitemsE

ItemsEntry
key (Rkey!
value (2.PBItemDataRvalue:8"p
PBBags%
bags (2.PBBags.BagsEntryRbags?
	BagsEntry
key (	Rkey
value (2.PBBagRvalue:8"£

PBRankNode
grade (Rgrade
level (Rlevel
star (Rstar
score (Rscore"
zhu_ji_points (RzhuJiPoints
	all_stars (RallStars"À
PBRankLevel*

ghost_rank (2.PBRankNodeR	ghostRank*

human_rank (2.PBRankNodeR	humanRank1
ghost_top_rank (2.PBRankNodeRghostTopRank1
human_top_rank (2.PBRankNodeRhumanTopRank"4
PBPinchFaceData!
setting_data (	RsettingData"™
PBSimpleRoleData
	config_id (RconfigId2
skins (2.PBSimpleRoleData.SkinsEntryRskinsE

SkinsEntry
key (Rkey!
value (2.PBItemDataRvalue:8"∂

PBRoleData
	config_id (RconfigId

star_level (R	starLevel
exp (Rexp*

magic_item (2.PBItemDataR	magicItemB
digrams_cards (2.PBRoleData.DigramsCardsEntryRdigramsCards
equip_books (R
equipBooks
study_books (R
studyBooks,
skins (2.PBRoleData.SkinsEntryRskins)
cur_main_skill_id	 (RcurMainSkillId9

main_skill
 (2.PBRoleData.MainSkillEntryR	mainSkill-
cur_minor_skill1_id (RcurMinorSkill1Id?
minor_skill1 (2.PBRoleData.MinorSkill1EntryRminorSkill1-
cur_minor_skill2_id (RcurMinorSkill2Id?
minor_skill2 (2.PBRoleData.MinorSkill2EntryRminorSkill2-
passive_skill (2.PBSkillRpassiveSkill
emoji (RemojiL
DigramsCardsEntry
key (Rkey!
value (2.PBItemDataRvalue:8E

SkinsEntry
key (Rkey!
value (2.PBItemDataRvalue:8F
MainSkillEntry
key (Rkey
value (2.PBSkillRvalue:8H
MinorSkill1Entry
key (Rkey
value (2.PBSkillRvalue:8H
MinorSkill2Entry
key (Rkey
value (2.PBSkillRvalue:8"æ
PBUserRoleDatas$
battle_role_id (RbattleRoleId;
	role_list (2.PBUserRoleDatas.RoleListEntryRroleListH
RoleListEntry
key (Rkey!
value (2.PBRoleDataRvalue:8"I
PBSimpleGhostData
	config_id (RconfigId
skin_id (RskinId"¢
PBGhostData
	config_id (RconfigId
uniqid (Runiqid

star_level (R	starLevel
exp (RexpC
digrams_cards (2.PBGhostData.DigramsCardsEntryRdigramsCards/
passive_skills (2.PBSkillRpassiveSkills-
active_skills (2.PBSkillRactiveSkills"
attrs (2.PBAttributeRattrs
nature	 (RnatureL
DigramsCardsEntry
key (Rkey!
value (2.PBItemDataRvalue:8"û
PBGhostImage
	config_id (RconfigId

star_level (R	starLevel
exp (Rexp
cur_skin_id (R	curSkinId 
skin_id_list (R
skinIdList"ö
PBUserGhostDatas&
battle_ghost_id (RbattleGhostId.
battle_ghost_uniqid (RbattleGhostUniqid?

ghost_list (2 .PBUserGhostDatas.GhostListEntryR	ghostListO
ghost_image_list (2%.PBUserGhostDatas.GhostImageListEntryRghostImageListJ
GhostListEntry
key (Rkey"
value (2.PBGhostDataRvalue:8P
GhostImageListEntry
key (Rkey#
value (2.PBGhostImageRvalue:8"Ä
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

gourd_list (2.PBGourdR	gourdList"W
PBImage
	config_id (RconfigId

star_level (R	starLevel
exp (Rexp"¸
PBUserImage:

item_image (2.PBUserImage.ItemImageEntryR	itemImageJ
magic_item_image (2 .PBUserImage.MagicItemImageEntryRmagicItemImageV
human_diagrams_image (2$.PBUserImage.HumanDiagramsImageEntryRhumanDiagramsImageV
ghost_diagrams_image (2$.PBUserImage.GhostDiagramsImageEntryRghostDiagramsImageF
ItemImageEntry
key (Rkey
value (2.PBImageRvalue:8K
MagicItemImageEntry
key (Rkey
value (2.PBImageRvalue:8O
HumanDiagramsImageEntry
key (Rkey
value (2.PBImageRvalue:8O
GhostDiagramsImageEntry
key (Rkey
value (2.PBImageRvalue:8"Ù
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
accountExp
	guild_uid (RguildUid

guild_name (R	guildName+

rank_level (2.PBRankLevelR	rankLevel5
cur_show_role (2.PBSimpleRoleDataRcurShowRole8
pinch_face_data (2.PBPinchFaceDataRpinchFaceData
title (Rtitle
player_flag (R
playerFlag
online_time (R
onlineTime&
sum_online_time (RsumOnlineTime
pa_flag (RpaFlag8
cur_show_ghost (2.PBSimpleGhostDataRcurShowGhost"/
PBClientGetUsrSimInfoReqCmd
uid (Ruid"Ä
PBClientGetUsrSimInfoRspCmd
code (Rcode
error (	Rerror
uid (Ruid%
info (2.PBUserSimpleInfoRinfo"0
PBClientGetUsrBagsInfoReqCmd
uid (Ruid"Ä
PBClientGetUsrBagsInfoRspCmd
code (Rcode
error (	Rerror
uid (Ruid$
	bags_info (2.PBBagsRbagsInfo"∂
PBClientLightReqCmd
uid (Ruid
roleid (Rroleid
ghostid (Rghostid
bagid (Rbagid
pos (Rpos
	config_id (RconfigId
uniqid (Runiqid"‡
PBClientLightRspCmd
code (Rcode
error (	Rerror
uid (Ruid
roleid (Rroleid
ghostid (Rghostid
bagid (Rbagid
pos (Rpos
	config_id (RconfigId
uniqid	 (Runiqid"e
PBClientMagicItemUpLvReqCmd
uid (Ruid
	config_id (RconfigId
add_exp (RaddExp"®
PBClientMagicItemUpLvRspCmd
code (Rcode
error (	Rerror
uid (Ruid
	config_id (RconfigId
add_exp (RaddExp
now_exp (RnowExpbproto3
˝
	bag.proto
user.proto"C
PBBagGetDataReqCmd
uid (Ruid
	bags_name (	RbagsName"v
PBBagGetDataRspCmd
code (Rcode
error (	Rerror
uid (Ruid$
	bag_datas (2.PBBagsRbagDatas"q
PBBagUpdateSyncCmd*
update_items (2.PBBagsRupdateItems/
update_coins (2.PBUserCoinsRupdateCoins"’
PBBagOperateItemReqCmd
uid (Ruid!
operate_type (RoperateType
src_bag (	RsrcBag
src_pos (RsrcPos
dest_bag (	RdestBag
dest_pos (RdestPos

splitCount (R
splitCount"T
PBBagOperateItemRspCmd
code (Rcode
error (	Rerror
uid (Ruidbproto3
¬

chat.proto"≠
PBChatMsgInfo!
channel_type (RchannelType
uid (Ruid
name (	Rname
msg_content (	R
msgContent
	send_time (RsendTime
to_uid (RtoUid"i
PBChatReqCmd!
channel_type (RchannelType
msg_content (	R
msgContent
to_uid (RtoUid""
PBChatRspCmd
code (Rcode"4
PBChatSynCmd$
infos (2.PBChatMsgInfoRinfos"5
PBSyncWorldChatCmd
world_index (R
worldIndex":
PBChooseWorldChatReqCmd
world_index (R
worldIndex"O
PBChooseWorldChatRespCmd
code (Rcode
world_index (R
worldIndex"7
PBNotifyWorldChatCmd
world_index (R
worldIndex*π
PBChannelType
CHANNEL_TYPE_NONE 
CHANNEL_TYPE_NEARBY
CHANNEL_TYPE_WORLD
CHANNEL_TYPE_TEAM
CHANNEL_TYPE_GUILD
CHANNEL_TYPE_PRIVATE
CHANNEL_TYPE_SYSTEMbproto3
È

city.proto"*
PBApplyLoginCityReqCmd
uid (Ruid"¶
PBApplyLoginCityRspCmd
code (Rcode
error (	Rerror
cityid (Rcityid
region (	Rregion

ds_address (	R	dsAddress
ds_ip (	RdsIpbproto3
ç
common.proto"ì
PBMessagePack
net_id (RnetId
	broadcast (R	broadcast
stub_id (RstubId
msg_type (RmsgType
msg_body (RmsgBody"·
PBDsCreateData
ds_id (RdsId
chapter (Rchapter

difficulty (R
difficulty
map_id (RmapId
boss_id (RbossId
	server_ip (	RserverIp
server_port (R
serverPort
uids (Ruids"9
PBPacketCmd*
messages (2.PBMessagePackRmessages"
	PBPingCmd
time (Rtime"
	PBPongCmd
time (Rtimebproto3
ù
dsnode.proto"=
PBEnterCityReqCmd
uid (Ruid
cityid (Rcityid"=
PBEnterCityRspCmd
code (Rcode
error (	Rerror"<
PBExitCityReqCmd
uid (Ruid
cityid (Rcityid"<
PBExitCityRspCmd
code (Rcode
error (	Rerror"K
PBUpdateCityReqCmd
cityid (Rcityid

player_num (R	playerNum">
PBUpdateCityRspCmd
code (Rcode
error (	Rerrorbproto3
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
w
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

guild_data (2.PBGuildMemberDataR	guildData"
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

target_uid (R	targetUid
duty_id (RdutyId$
gkd_change_num	 (RgkdChangeNum
gkd_cur_num
 (R	gkdCurNum
gkd_desc (	RgkdDesc
item_id (RitemId
gubi_num (RgubiNum

contribute (R
contribute,
spoils_item (2.PBItemDataR
spoilsItem!
season_point (RseasonPoint
op_mgr_name (	R	opMgrName
rechage_num (R
rechageNum!
operater_uid (RoperaterUid"Ö
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
last_refresh_time (RlastRefreshTime"Z
PBGuildBagDB
guild_id (RguildId/
bag_item_list (2.PBItemDataRbagItemList"a
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

apply_list (2.PBUserApplyInfoR	applyList"t
PBGuildAddItems2BagCmd
guild_id (RguildId!
items (2.PBItemDataRitems

add_or_del (RaddOrDel"7
PBGuildAddItemsCmd!
items (2.PBItemDataRitems"7
PBGuildDelItemsCmd!
items (2.PBItemDataRitems"P
PBGuildUpdateGuildUserDataCmd/
	user_data (2.PBGuildMemberDataRuserData"=
PBGuildUpdateGuildBagCmd!
items (2.PBItemDataRitems"9
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
uid (Ruid"B
PBGuildGetSalaryRspCmd(
	get_items (2.PBItemDataRgetItems"I
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

guild_name (R	guildName"Ñ
PBGuildApplyJoinGuildReqCmd
guild_id (RguildId
uid (Ruid
b_apply (RbApply
applyer_uid (R
applyerUid"k
PBGuildApplyJoinGuildRspCmd
code (Rcode
guild_id (RguildId

guild_name (R	guildName"o
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
uid (Ruid"I
PBGuildExpelQuitRspCmd
code (Rcode
	expel_uid (RexpelUid"^
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

mission_id (R	missionId"}
PBGuildDayMissionAwardRspCmd
code (Rcode(
	item_list (2.PBItemDataRitemList
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
˛
Match.proto"ø
PBUserSelectionOpt
op_type (RopType
uid (Ruid
	target_id (RtargetId

target_pos (R	targetPos!
confirm_role (RconfirmRole
ban_roleids (R
banRoleids"‚
PBUserSelection
uid (Ruid
	camp_type (RcampType$
disable_map_id (RdisableMapId(
disable_role_ids (RdisableRoleIds(
selection_map_id (RselectionMapId&
confirm_role_ok (RconfirmRoleOk"î
PBUserSelectionS
	cur_state (RcurState,
human_select_index (RhumanSelectIndex*
human_disable_map (RhumanDisableMap.
human_disable_roles (RhumanDisableRoles*
ghost_disable_map (RghostDisableMap.
ghost_disable_roles (RghostDisableRoles
rand_map_id (R	randMapId&
ghost (2.PBUserSelectionRghost5
humans	 (2.PBUserSelectionS.HumansEntryRhumans1
system_ban_config_ids
 (RsystemBanConfigIdsK
HumansEntry
key (Rkey&
value (2.PBUserSelectionRvalue:8"~
PBMatchCreateRoomReqCmd
uid (Ruid

match_type (R	matchType
	camp_type (RcampType
map_id (RmapId"v
PBMatchReqCmd
uid (Ruid

match_type (R	matchType
	camp_type (RcampType
need_ai (RneedAi"#
PBMatchRspCmd
code (Rcode".
PBNotifyMatchAckCmd
room_id (RroomId"X
PBMatchAckReqCmd
uid (Ruid
room_id (RroomId
is_agree (RisAgree"m
PBMatchSelectionOptReqCmd
uid (Ruid
room_id (RroomId%
opt (2.PBUserSelectionOptRopt"/
PBMatchSelectionOptRspCmd
code (Rcode"b
PBMatchNotifyEnterDSCmd
ds_ip (	RdsIp
ds_port (RdsPort
room_key (	RroomKey"G
PBMatchNotifyGameOverCmd
room_id (RroomId
code (Rcode"@
PBMatchCancelReqCmd
uid (Ruid
room_id (RroomId")
PBMatchCancelRspCmd
code (Rcode"C
PBMatchNotifyFailCmd
room_id (RroomId
code (Rcode"¥
PBMatchNotifyPlayerNumCmd
room_id (RroomId
	human_num (RhumanNum
	ghost_num (RghostNum 
red_team_num (R
redTeamNum"
blue_team_num (RblueTeamNum*ç
PBSelectionOpType
PBSelectionOp_None 
PBSelectionOp_Disable_Map
PBSelectionOp_Disable_Role
PBSelectionOp_Selection_Map 
PBSelectionOp_Selection_Role
PBSelectionOp_Setup_Item
PBSelectionOp_Setup_Skin"
PBSelectionOp_Setup_LRSVieItem*ª
PBSelectionStateType
PBSelectionState_None 
PBSelectionState_Disable
PBSelectionState_Selection
PBSelectionState_Setup
PBSelectionState_Succ
PBSelectionState_Close'
#PBSelectionState_LRS_SelectionGhost#
PBSelectionState_LRS_SetupGhost)
%PBSelectionState_SH_Ghost_Select_Skinbproto3
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
∂!

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
ds_ip (	RdsIp"`
PBDsGetPlayerDataReqCmd
uid (Ruid
roomid (Rroomid
	data_type (RdataType"ú
PBDsGetPlayerDataRspCmd
code (Rcode
error (	Rerror
	data_type (RdataType2
simple_data (2.PBUserSimpleInfoR
simpleData,
battle_role (2.PBRoleDataR
battleRole/
battle_ghost (2.PBGhostDataRbattleGhost'
consume_bag (2.PBBagR
consumeBagbproto3
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