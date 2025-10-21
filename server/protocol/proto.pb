
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
ä!

item.proto"@
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
star (Rstar"W
PBDurabItem%
cur_durability (RcurDurability!
strong_value (RstrongValue"‹
PBMagicItem%
cur_durability (RcurDurability!
strong_value (RstrongValue!
tabooword_id (RtaboowordId
	light_cnt (RlightCnt
tags (2.PBTagRtags'
ability_tag (2.PBTagR
abilityTag"ﬂ
PBDiagramsCard%
cur_durability (RcurDurability!
strong_value (RstrongValue!
tabooword_id (RtaboowordId
	light_cnt (RlightCnt
tags (2.PBTagRtags'
ability_tag (2.PBTagR
abilityTag"B
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
played_gods_data (2.PBPlayedGodsDataSRplayedGodsData"ø
	PBItemLog
uid (Ruid
	config_id (RconfigId
old_num (RoldNum
new_num (RnewNum

mod_uniqid (R	modUniqid
del_uniqids (R
delUniqids
add_uniqids (R
addUniqids/
old_item_data (2.PBItemDataRoldItemData/
new_item_data	 (2.PBItemDataRnewItemData'
relation_roleid
 (RrelationRoleid)
relation_ghostid (RrelationGhostid2
relation_ghost_uniqid (RrelationGhostUniqid)
relation_imageid (RrelationImageid
change_type (R
changeType#
change_reason (RchangeReason
log_ts (RlogTs"W
PBImage
	config_id (RconfigId

star_level (R	starLevel
exp (Rexp"*
PBSkinImage
	config_id (RconfigId"Ñ
PBUserImage:

item_image (2.PBUserImage.ItemImageEntryR	itemImageJ
magic_item_image (2 .PBUserImage.MagicItemImageEntryRmagicItemImageV
human_diagrams_image (2$.PBUserImage.HumanDiagramsImageEntryRhumanDiagramsImageV
ghost_diagrams_image (2$.PBUserImage.GhostDiagramsImageEntryRghostDiagramsImage:

skin_image (2.PBUserImage.SkinImageEntryR	skinImageF
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
value (2.PBImageRvalue:8J
SkinImageEntry
key (Rkey"
value (2.PBSkinImageRvalue:8"(
PBImageGetDataReqCmd
uid (Ruid"
PBImageGetDataRspCmd
code (Rcode
error (	Rerror
uid (Ruid+

image_data (2.PBUserImageR	imageData"I
PBImageUpdateSyncCmd1
update_images (2.PBUserImageRupdateImagesbproto3
ñ
	bag.proto
item.proto"∑
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
value (2.PBBagRvalue:8"C
PBBagGetDataReqCmd
uid (Ruid
	bags_name (	RbagsName"’
PBBagGetDataRspCmd
code (Rcode
error (	Rerror
uid (Ruid>
	bag_datas (2!.PBBagGetDataRspCmd.BagDatasEntryRbagDatasC
BagDatasEntry
key (	Rkey
value (2.PBBagRvalue:8"'
PBBagGetCoinsReqCmd
uid (Ruid"~
PBBagGetCoinsRspCmd
code (Rcode
error (	Rerror
uid (Ruid+

coin_datas (2.PBUserCoinsR	coinDatas"∑
PBBagUpdateSyncCmdG
update_items (2$.PBBagUpdateSyncCmd.UpdateItemsEntryRupdateItemsG
update_coins (2$.PBBagUpdateSyncCmd.UpdateCoinsEntryRupdateCoinsF
UpdateItemsEntry
key (	Rkey
value (2.PBBagRvalue:8G
UpdateCoinsEntry
key (Rkey
value (2.PBCoinRvalue:8"÷
PBBagOperateItemReqCmd
uid (Ruid!
operate_type (RoperateType
src_bag (	RsrcBag
src_pos (RsrcPos
dest_bag (	RdestBag
dest_pos (RdestPos
split_count (R
splitCount"T
PBBagOperateItemRspCmd
code (Rcode
error (	Rerror
uid (Ruid"w
PBDecomposeItem
	config_id (RconfigId
uniqid (Runiqid

item_count (R	itemCount
pos (Rpos"`
PBDecomposeReqCmd
uid (Ruid9
decompose_items (2.PBDecomposeItemRdecomposeItems"ä
PBDecomposeRspCmd
code (Rcode
error (	Rerror
uid (Ruid9
decompose_items (2.PBDecomposeItemRdecomposeItems"m
PBBagAddCapacityReqCmd
uid (Ruid
bag_name (	RbagName&
add_capacity_id (RaddCapacityId"í
PBBagAddCapacityRspCmd
code (Rcode
error (	Rerror
uid (Ruid
bag_name (	RbagName!
bag_data (2.PBBagRbagData"A
PBBagSortOutReqCmd
uid (Ruid
bag_name (	RbagName"k
PBBagSortOutRspCmd
code (Rcode
error (	Rerror
uid (Ruid
bag_name (	RbagNamebproto3
ò

chat.proto"Ã
PBChatMsgInfo!
channel_type (RchannelType
uid (Ruid
name (	Rname
msg_content (	R
msgContent

msg_attach (R	msgAttach
	send_time (RsendTime
to_uid (RtoUid"à
PBChatReqCmd!
channel_type (RchannelType
msg_content (	R
msgContent

msg_attach (R	msgAttach
to_uid (RtoUid""
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
worldIndex*–
PBChannelType
CHANNEL_TYPE_NONE 
CHANNEL_TYPE_NEARBY
CHANNEL_TYPE_WORLD
CHANNEL_TYPE_TEAM
CHANNEL_TYPE_GUILD
CHANNEL_TYPE_PRIVATE
CHANNEL_TYPE_SYSTEM
CHANNEL_TYPE_ROOMbproto3
Ø

city.proto"*
PBApplyLoginCityReqCmd
uid (Ruid"¶
PBApplyLoginCityRspCmd
code (Rcode
error (	Rerror
cityid (Rcityid
region (	Rregion

ds_address (	R	dsAddress
ds_ip (	RdsIp"D
PBNotifyDsDestorySyncCmd
uid (Ruid
cityid (Rcityidbproto3
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
†,

role.proto
item.proto"4
PBPinchFaceData!
setting_data (	RsettingData"{
PBStudyBook
book_id (RbookId

start_time (R	startTime
end_time (RendTime
now_time (RnowTime"¡
PBSimpleRoleData
	config_id (RconfigId2
skins (2.PBSimpleRoleData.SkinsEntryRskins"
magic_item_id (RmagicItemId8

SkinsEntry
key (Rkey
value (Rvalue:8"™

PBRoleData
	config_id (RconfigId

star_level (R	starLevel
exp (Rexp*

magic_item (2.PBItemDataR	magicItemB
digrams_cards (2.PBRoleData.DigramsCardsEntryRdigramsCards<
equip_books (2.PBRoleData.EquipBooksEntryR
equipBooks<
study_books (2.PBRoleData.StudyBooksEntryR
studyBooks&
last_check_time (RlastCheckTime,
skins	 (2.PBRoleData.SkinsEntryRskins)
cur_main_skill_id
 (RcurMainSkillId9

main_skill (2.PBRoleData.MainSkillEntryR	mainSkill-
cur_minor_skill1_id (RcurMinorSkill1Id?
minor_skill1 (2.PBRoleData.MinorSkill1EntryRminorSkill1-
cur_minor_skill2_id (RcurMinorSkill2Id?
minor_skill2 (2.PBRoleData.MinorSkill2EntryRminorSkill2/
cur_passive_skill_id (RcurPassiveSkillIdB
passive_skill (2.PBRoleData.PassiveSkillEntryRpassiveSkill
emoji (Remoji@
up_lv_rewards (2.PBRoleData.UpLvRewardsEntryRupLvRewardsL
DigramsCardsEntry
key (Rkey!
value (2.PBItemDataRvalue:8=
EquipBooksEntry
key (Rkey
value (Rvalue:8K
StudyBooksEntry
key (Rkey"
value (2.PBStudyBookRvalue:88

SkinsEntry
key (Rkey
value (Rvalue:8F
MainSkillEntry
key (Rkey
value (2.PBSkillRvalue:8H
MinorSkill1Entry
key (Rkey
value (2.PBSkillRvalue:8H
MinorSkill2Entry
key (Rkey
value (2.PBSkillRvalue:8I
PassiveSkillEntry
key (Rkey
value (2.PBSkillRvalue:8>
UpLvRewardsEntry
key (Rkey
value (Rvalue:8"æ
PBUserRoleDatas$
battle_role_id (RbattleRoleId;
	role_list (2.PBUserRoleDatas.RoleListEntryRroleListH
RoleListEntry
key (Rkey!
value (2.PBRoleDataRvalue:8"1
PBClientGetUsrRolesInfoReqCmd
uid (Ruid"å
PBClientGetUsrRolesInfoRspCmd
code (Rcode
error (	Rerror
uid (Ruid/

roles_info (2.PBUserRoleDatasR	rolesInfo"E
PBClientGetRoleInfoReqCmd
uid (Ruid
roleid (Rroleid"Å
PBClientGetRoleInfoRspCmd
code (Rcode
error (	Rerror
uid (Ruid(
	role_info (2.PBRoleDataRroleInfo"D
PBRoleInfoSyncCmd/

roles_info (2.PBUserRoleDatasR	rolesInfo"÷
PBRoleWearEquipReqCmd
uid (Ruid
roleid (Rroleid
bag_name (	RbagName
pos (Rpos&
equip_config_id (RequipConfigId!
equip_uniqid (RequipUniqid
	equip_idx (RequipIdx"Ä
PBRoleWearEquipRspCmd
code (Rcode
error (	Rerror
uid (Ruid
roleid (Rroleid
bag_name (	RbagName
pos (Rpos&
equip_config_id (RequipConfigId!
equip_uniqid (RequipUniqid
	equip_idx	 (RequipIdx"”
PBRoleTakeOffEquipReqCmd
uid (Ruid
roleid (Rroleid
bag_name (	RbagName*
takeoff_config_id (RtakeoffConfigId%
takeoff_uniqid (RtakeoffUniqid
takeoff_idx (R
takeoffIdx"˝
PBRoleTakeOffEquipRspCmd
code (Rcode
error (	Rerror
uid (Ruid
roleid (Rroleid
bag_name (	RbagName*
takeoff_config_id (RtakeoffConfigId%
takeoff_uniqid (RtakeoffUniqid
takeoff_idx (R
takeoffIdx"≤
PBRoleWearSkinReqCmd
uid (Ruid
roleid (Rroleid6
skins (2 .PBRoleWearSkinReqCmd.SkinsEntryRskins8

SkinsEntry
key (Rkey
value (Rvalue:8"‹
PBRoleWearSkinRspCmd
code (Rcode
error (	Rerror
uid (Ruid
roleid (Rroleid6
skins (2 .PBRoleWearSkinRspCmd.SkinsEntryRskins8

SkinsEntry
key (Rkey
value (Rvalue:8"Y
PBRoleChangeEmojiReqCmd
uid (Ruid
roleid (Rroleid
emoji (Remoji"É
PBRoleChangeEmojiRspCmd
code (Rcode
error (	Rerror
uid (Ruid
roleid (Rroleid
emoji (Remoji"D
PBChangeBattleRoleReqCmd
uid (Ruid
roleid (Rroleid"n
PBChangeBattleRoleRspCmd
code (Rcode
error (	Rerror
uid (Ruid
roleid (Rroleid"^
PBRoleSkillUpStarReqCmd
uid (Ruid
roleid (Rroleid
skill_id (RskillId"à
PBRoleSkillUpStarRspCmd
code (Rcode
error (	Rerror
uid (Ruid
roleid (Rroleid
skill_id (RskillId"b
PBRoleGetUpLvRewardReqCmd
uid (Ruid
roleid (Rroleid
	reward_id (RrewardId"å
PBRoleGetUpLvRewardRspCmd
code (Rcode
error (	Rerror
uid (Ruid
roleid (Rroleid
	reward_id (RrewardId"Z
PBRoleStudyBookReqCmd
uid (Ruid
roleid (Rroleid
book_id (RbookId"Ñ
PBRoleStudyBookRspCmd
code (Rcode
error (	Rerror
uid (Ruid
roleid (Rroleid
book_id (RbookId"i
PBRoleSkillCompositeReqCmd
uid (Ruid
roleid (Rroleid!
composite_id (RcompositeId"ì
PBRoleSkillCompositeRspCmd
code (Rcode
error (	Rerror
uid (Ruid
roleid (Rroleid!
composite_id (RcompositeId"}
PBRoleSkillSwitchReqCmd
uid (Ruid
roleid (Rroleid

skill_type (R	skillType
skill_id (RskillId"ß
PBRoleSkillSwitchRspCmd
code (Rcode
error (	Rerror
uid (Ruid
roleid (Rroleid

skill_type (R	skillType
skill_id (RskillIdbproto3
Û
ghost.proto
item.proto"I
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

gourd_list (2.PBGourdR	gourdList"2
PBClientGetUsrGhostsInfoReqCmd
uid (Ruid"ê
PBClientGetUsrGhostsInfoRspCmd
code (Rcode
error (	Rerror
uid (Ruid2
ghosts_info (2.PBUserGhostDatasR
ghostsInfo"H
PBGhostInfoSyncCmd2
ghosts_info (2.PBUserGhostDatasR
ghostsInfo"‚
PBGhostWearEquipReqCmd
uid (Ruid!
ghost_uniqid (RghostUniqid
bag_name (	RbagName
pos (Rpos&
equip_config_id (RequipConfigId!
equip_uniqid (RequipUniqid
	equip_idx (RequipIdx"å
PBGhostWearEquipRspCmd
code (Rcode
error (	Rerror
uid (Ruid!
ghost_uniqid (RghostUniqid
bag_name (	RbagName
pos (Rpos&
equip_config_id (RequipConfigId!
equip_uniqid (RequipUniqid
	equip_idx	 (RequipIdx"ﬂ
PBGhostTakeOffEquipReqCmd
uid (Ruid!
ghost_uniqid (RghostUniqid
bag_name (	RbagName*
takeoff_config_id (RtakeoffConfigId%
takeoff_uniqid (RtakeoffUniqid
takeoff_idx (R
takeoffIdx"â
PBGhostTakeOffEquipRspCmd
code (Rcode
error (	Rerror
uid (Ruid!
ghost_uniqid (RghostUniqid
bag_name (	RbagName*
takeoff_config_id (RtakeoffConfigId%
takeoff_uniqid (RtakeoffUniqid
takeoff_idx (R
takeoffIdx"e
PBGhostWearSkinReqCmd
uid (Ruid&
ghost_config_id (RghostConfigId
skin (Rskin"è
PBGhostWearSkinRspCmd
code (Rcode
error (	Rerror
uid (Ruid&
ghost_config_id (RghostConfigId
skin (Rskinbproto3
¿(

user.proto
item.proto	bag.proto
role.protoghost.proto"£

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
human_top_rank (2.PBRankNodeRhumanTopRank"’

PBUserAttr
uid (Ruid!
plateform_id (	RplateformId
	nick_name (	RnickName
	head_icon (RheadIcon
sex (Rsex

praise_num (R	praiseNum

head_frame (R	headFrame.
account_create_time (RaccountCreateTime#
account_level	 (RaccountLevel
account_exp
 (R
accountExp
guild_id (RguildId

guild_name (	R	guildName+

rank_level (2.PBRankLevelR	rankLevel5
cur_show_role (2.PBSimpleRoleDataRcurShowRole8
pinch_face_data (2.PBPinchFaceDataRpinchFaceData
title (Rtitle
player_flag (R
playerFlag
online_time (R
onlineTime&
sum_online_time (RsumOnlineTime8
cur_show_ghost (2.PBSimpleGhostDataRcurShowGhost
	is_online (RisOnline
chat_ban (RchatBan"
chat_ban_time (RchatBanTime$
last_chat_time (RlastChatTime"/
PBClientGetUsrSimInfoReqCmd
uid (Ruid"z
PBClientGetUsrSimInfoRspCmd
code (Rcode
error (	Rerror
uid (Ruid
info (2.PBUserAttrRinfo"0
PBClientGetAllUserAttrReqCmd
uid (Ruid"{
PBClientGetAllUserAttrRspCmd
code (Rcode
error (	Rerror
uid (Ruid
info (2.PBUserAttrRinfo"Q
PBSetUserAttrReqCmd
uid (Ruid
type (Rtype
value (Rvalue"i
PBSetUserAttrRspCmd
code (Rcode
error (	Rerror
type (Rtype
value (Rvalue"4
PBUserAttrSyncCmd
attr (2.PBUserAttrRattr"0
PBClientGetUsrBagsInfoReqCmd
uid (Ruid"≠
PBClientGetUsrBagsInfoRspCmd
code (Rcode
error (	Rerror
uid (Ruid$
	bags_info (2.PBBagsRbagsInfo+

coins_info (2.PBUserCoinsR	coinsInfo"ª
PBClientLightReqCmd
uid (Ruid
roleid (Rroleid
ghostid (Rghostid
bag_name (	RbagName
pos (Rpos
	config_id (RconfigId
uniqid (Runiqid"Â
PBClientLightRspCmd
code (Rcode
error (	Rerror
uid (Ruid
roleid (Rroleid
ghostid (Rghostid
bag_name (	RbagName
pos (Rpos
	config_id (RconfigId
uniqid	 (Runiqid"`
PBClientItemUpLvReqCmd
uid (Ruid
	config_id (RconfigId
add_exp (RaddExp"ä
PBClientItemUpLvRspCmd
code (Rcode
error (	Rerror
uid (Ruid
	config_id (RconfigId
add_exp (RaddExp"x
PBUseItemUpLvReqCmd
uid (Ruid
	target_id (RtargetId
cost_id (RcostId
cost_num (RcostNum"¢
PBUseItemUpLvRspCmd
code (Rcode
error (	Rerror
uid (Ruid
	target_id (RtargetId
cost_id (RcostId
cost_num (RcostNum"I
PBClientItemUpStarReqCmd
uid (Ruid
	config_id (RconfigId"s
PBClientItemUpStarRspCmd
code (Rcode
error (	Rerror
uid (Ruid
	config_id (RconfigId"c
PBClientItemRepairReqCmd
uid (Ruid#
repair_uniqid (RrepairUniqid
pos (Rpos"ç
PBClientItemRepairRspCmd
code (Rcode
error (	Rerror
uid (Ruid#
repair_uniqid (RrepairUniqid
pos (Rpos"G
PBGetOtherSimpleReqCmd
uid (Ruid
	quest_uid (RquestUid"í
PBGetOtherSimpleRspCmd
code (Rcode
error (	Rerror
uid (Ruid
	quest_uid (RquestUid
info (2.PBUserAttrRinfo"G
PBGetOtherDetailReqCmd
uid (Ruid
	quest_uid (RquestUid"È
PBGetOtherDetailRspCmd
code (Rcode
error (	Rerror
uid (Ruid
	quest_uid (RquestUid
info (2.PBUserAttrRinfo(
	role_data (2.PBRoleDataRroleData+

ghost_data (2.PBGhostDataR	ghostData"@
PBUseSkinGiftReqCmd
uid (Ruid
gift_id (RgiftId"j
PBUseSkinGiftRspCmd
code (Rcode
error (	Rerror
uid (Ruid
gift_id (RgiftId"q
PBSureCompositeReqCmd
uid (Ruid!
composite_id (RcompositeId#
composite_cnt (RcompositeCnt"õ
PBSureCompositeRspCmd
code (Rcode
error (	Rerror
uid (Ruid!
composite_id (RcompositeId#
composite_cnt (RcompositeCnt"s
PBRandomCompositeReqCmd
uid (Ruid!
composite_id (RcompositeId#
composite_cnt (RcompositeCnt"ù
PBRandomCompositeRspCmd
code (Rcode
error (	Rerror
uid (Ruid!
composite_id (RcompositeId#
composite_cnt (RcompositeCnt"ø
PBInlayTabooWordReqCmd
uid (Ruid
roleid (Rroleid!
ghost_uniqid (RghostUniqid

inlay_type (R	inlayType
uniqid (Runiqid!
tabooword_id (RtaboowordId"È
PBInlayTabooWordRspCmd
code (Rcode
error (	Rerror
uid (Ruid
roleid (Rroleid!
ghost_uniqid (RghostUniqid

inlay_type (R	inlayType
uniqid (Runiqid!
tabooword_id (RtaboowordIdbproto3
¨

gods.proto"9

PBGodImage
	config_id (RconfigId
lv (Rlv"5

PBGodBlock
idx (Ridx
god_id (RgodId"ò

PBUserGods9

gods_image (2.PBUserGods.GodsImageEntryR	godsImage9

gods_block (2.PBUserGods.GodsBlockEntryR	godsBlockI
GodsImageEntry
key (Rkey!
value (2.PBGodImageRvalue:8I
GodsBlockEntry
key (Rkey!
value (2.PBGodBlockRvalue:8"'
PBGodsGetInfoReqCmd
uid (Ruid"{
PBGodsGetInfoRspCmd
code (Rcode
error (	Rerror
uid (Ruid(
	gods_info (2.PBUserGodsRgodsInfo"=
PBGodsInfoSyncCmd(
	gods_info (2.PBUserGodsRgodsInfo"=
PBGodsUnlockReqCmd
uid (Ruid
god_id (RgodId"z
PBGodsUnlockRspCmd
code (Rcode
error (	Rerror
uid (Ruid(
	god_image (2.PBGodImageRgodImage";
PBGodsUpLvReqCmd
uid (Ruid
god_id (RgodId"x
PBGodsUpLvRspCmd
code (Rcode
error (	Rerror
uid (Ruid(
	god_image (2.PBGodImageRgodImage"J
PBGodsBlockUnlockReqCmd
uid (Ruid

unlock_idx (R	unlockIdx"
PBGodsBlockUnlockRspCmd
code (Rcode
error (	Rerror
uid (Ruid(
	god_block (2.PBGodBlockRgodBlock"a
PBGodsWearOrTakeoffReqCmd
uid (Ruid
	block_idx (RblockIdx
god_id (RgodId"Å
PBGodsWearOrTakeoffRspCmd
code (Rcode
error (	Rerror
uid (Ruid(
	god_block (2.PBGodBlockRgodBlockbproto3
ó
dsnode.proto
item.proto
user.proto	bag.proto
role.proto
gods.proto"=
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
error (	Rerror"x
PBAddItemsCityPlayerReqCmd
uid (Ruid
cityid (Rcityid0
simple_items (2.PBItemSimpleRsimpleItems"F
PBAddItemsCityPlayerRspCmd
code (Rcode
error (	Rerror"H
PBGetDsUserAttrReqCmd
dsid (Rdsid
	quest_uid (RquestUid"ì
PBGetDsUserAttrRspCmd
code (Rcode
error (	Rerror
dsid (Rdsid
	quest_uid (RquestUid
info (2.PBUserAttrRinfo"e
PBGetDsUserBagsReqCmd
dsid (Rdsid
	quest_uid (RquestUid
	bags_name (	RbagsName"˙
PBGetDsUserBagsRspCmd
code (Rcode
error (	Rerror
dsid (Rdsid
	quest_uid (RquestUidA
	bag_datas (2$.PBGetDsUserBagsRspCmd.BagDatasEntryRbagDatasC
BagDatasEntry
key (	Rkey
value (2.PBBagRvalue:8"c
PBGetDsUserRolesReqCmd
dsid (Rdsid
	quest_uid (RquestUid
roleids (Rroleids"Ö
PBGetDsUserRolesRspCmd
code (Rcode
error (	Rerror
dsid (Rdsid
	quest_uid (RquestUidE

role_datas (2&.PBGetDsUserRolesRspCmd.RoleDatasEntryR	roleDatasI
RoleDatasEntry
key (Rkey!
value (2.PBRoleDataRvalue:8"1
PBGetDsCreateDataReqCmd
roomid (Rroomid"v
PBGetDsCreateDataRspCmd
code (Rcode
error (	Rerror
roomid (Rroomid
room_str (	RroomStr"I
PBGetDsUserImageReqCmd
dsid (Rdsid
	quest_uid (RquestUid"†
PBGetDsUserImageRspCmd
code (Rcode
error (	Rerror
dsid (Rdsid
	quest_uid (RquestUid+

image_data (2.PBUserImageR	imageData"I
PBDsNotifyPlayerEnterReqCmd
roomid (Rroomid
uids (Ruids"s
PBDsNotifyPlayerEnterRspCmd
code (Rcode
error (	Rerror
roomid (Rroomid
uids (Ruids"H
PBDsNotifyPlayerExitReqCmd
roomid (Rroomid
uids (Ruids"r
PBDsNotifyPlayerExitRspCmd
code (Rcode
error (	Rerror
roomid (Rroomid
uids (Ruids"1
PBDsNotifyPlayEndReqCmd
roomid (Rroomid"[
PBDsNotifyPlayEndRspCmd
code (Rcode
error (	Rerror
roomid (Rroomid".
PBNotifyDsPlayerOffSyncCmd
uid (Ruid"N
PBGetDsUserBattleGodsReqCmd
dsid (Rdsid
	quest_uid (RquestUid"¢
PBGetDsUserBattleGodsRspCmd
code (Rcode
error (	Rerror
dsid (Rdsid
	quest_uid (RquestUid(
	gods_info (2.PBUserGodsRgodsInfobproto3
Å
friend.proto
user.proto"6
PBFriendData
uid (Ruid
notes (	Rnotes"Û
PBApplyFriendData
uid (Ruid
	head_icon (RheadIcon
	nick_name (	RnickName#
account_level (RaccountLevel

head_frame (R	headFrame
title (Rtitle
guild_id (RguildId

guild_name (	R	guildName"Ë
PBFriendGroupData
group_id (RgroupId

group_name (	R	groupNameI
group_friends (2$.PBFriendGroupData.GroupFriendsEntryRgroupFriendsN
GroupFriendsEntry
key (Rkey#
value (2.PBFriendDataRvalue:8"‚
PBUserFriendDatasI
friend_groups (2$.PBUserFriendDatas.FriendGroupsEntryRfriendGroupsI
apply_friends (2$.PBUserFriendDatas.ApplyFriendsEntryRapplyFriends@

black_list (2!.PBUserFriendDatas.BlackListEntryR	blackListS
FriendGroupsEntry
key (Rkey(
value (2.PBFriendGroupDataRvalue:8S
ApplyFriendsEntry
key (Rkey(
value (2.PBApplyFriendDataRvalue:8K
BlackListEntry
key (Rkey#
value (2.PBFriendDataRvalue:8")
PBGetFriendInfoReqCmd
uid (Ruid"º
PBGetFriendInfoRspCmd
code (Rcode
error (	Rerror
uid (Ruid5
friend_datas (2.PBUserFriendDatasRfriendDatas]
friends_simple_attr (2-.PBGetFriendInfoRspCmd.FriendsSimpleAttrEntryRfriendsSimpleAttrQ
FriendsSimpleAttrEntry
key (Rkey!
value (2.PBUserAttrRvalue:8"Ù
PBFriendSyncCmd5
friend_datas (2.PBUserFriendDatasRfriendDatasW
friends_simple_attr (2'.PBFriendSyncCmd.FriendsSimpleAttrEntryRfriendsSimpleAttrQ
FriendsSimpleAttrEntry
key (Rkey!
value (2.PBUserAttrRvalue:8"S
PBFriendOnlineSyncCmd

change_uid (R	changeUid
	is_online (RisOnline"F
PBApplyFriendReqCmd
uid (Ruid

target_uid (R	targetUid"p
PBApplyFriendRspCmd
code (Rcode
error (	Rerror
uid (Ruid

target_uid (R	targetUid"e
PBFriendDealApplyReqCmd
uid (Ruid
	quest_uid (RquestUid
	deal_type (RdealType"r
PBFriendDealApplyRspCmd
code (Rcode
error (	Rerror
uid (Ruid
	quest_uid (RquestUid";
PBFriendOtherRefuseSyncCmd

refuse_uid (R	refuseUid">
PBFriendDelReqCmd
uid (Ruid
del_uid (RdelUid"h
PBFriendDelRspCmd
code (Rcode
error (	Rerror
uid (Ruid
del_uid (RdelUid"G
PBFriendAddBlackReqCmd
uid (Ruid
	black_uid (RblackUid"q
PBFriendAddBlackRspCmd
code (Rcode
error (	Rerror
uid (Ruid
	black_uid (RblackUid"G
PBFriendDelBlackReqCmd
uid (Ruid
	black_uid (RblackUid"q
PBFriendDelBlackRspCmd
code (Rcode
error (	Rerror
uid (Ruid
	black_uid (RblackUid"_
PBFriendSetNotesReqCmd
uid (Ruid

target_uid (R	targetUid
notes (	Rnotes"s
PBFriendSetNotesRspCmd
code (Rcode
error (	Rerror
uid (Ruid

target_uid (R	targetUid"L
PBFriendCreateGroupReqCmd
uid (Ruid

group_name (	R	groupName"ë
PBFriendCreateGroupRspCmd
code (Rcode
error (	Rerror
uid (Ruid
group_id (RgroupId

group_name (	R	groupName"H
PBFriendDeleteGroupReqCmd
uid (Ruid
group_id (RgroupId"r
PBFriendDeleteGroupRspCmd
code (Rcode
error (	Rerror
uid (Ruid
group_id (RgroupId"â
PBFriendMoveReqCmd
uid (Ruid

target_uid (R	targetUid 
old_group_id (R
oldGroupId 
new_group_id (R
newGroupId"≥
PBFriendMoveRspCmd
code (Rcode
error (	Rerror
uid (Ruid

target_uid (R	targetUid 
old_group_id (R
oldGroupId 
new_group_id (R
newGroupId"h
PBFriendSetGroupNameReqCmd
uid (Ruid
group_id (RgroupId

group_name (	R	groupName"í
PBFriendSetGroupNameRspCmd
code (Rcode
error (	Rerror
uid (Ruid
group_id (RgroupId

group_name (	R	groupNamebproto3
ˆw
guild.proto
item.proto
user.proto"y
PBGuildItemData
grid_id (RgridId
item_uid (RitemUid
item_id (RitemId
item_num (RitemNum"D
PBGuildItemListData-
	item_list (2.PBGuildItemDataRitemList"r
PBGuildApplyUserBaseInfo7
playerSimpleInfo (2.PBUserAttrRplayerSimpleInfo

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
last_get_salary_time (RlastGetSalaryTime
	join_time (RjoinTime
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
record_time (R
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
∏

mail.proto
item.proto"≥
PBMailSimpleData
mail_id (RmailId$
mail_config_id (RmailConfigId
	mail_type (RmailType
beg_ts (RbegTs
end_ts (RendTs"
mail_title_id (RmailTitleId

mail_title (	R	mailTitle
is_read (RisRead"
is_have_items	 (RisHaveItems
is_get
 (RisGet"Ó

PBMailData2
simple_data (2.PBMailSimpleDataR
simpleData 
mail_icon_id (R
mailIconId&
mail_content_id (RmailContentId!
mail_content (	RmailContent
sign (	Rsign?
items_simple (2.PBMailData.ItemsSimpleEntryRitemsSimple*

item_datas (2.PBItemDataR	itemDatas,
coins (2.PBMailData.CoinsEntryRcoinsM
ItemsSimpleEntry
key (Rkey#
value (2.PBItemSimpleRvalue:8A

CoinsEntry
key (Rkey
value (2.PBCoinRvalue:8"≠
PBUserMailBox-
last_system_mail_id (RlastSystemMailId/
last_trigger_mail_id (RlastTriggerMailId3
last_immediate_mail_id (RlastImmediateMailId<

mails_info (2.PBUserMailBox.MailsInfoEntryR	mailsInfoI
MailsInfoEntry
key (Rkey!
value (2.PBMailDataRvalue:8"{
PBMailSyncCmd 
add_mail_ids (R
addMailIds 
del_mail_ids (R
delMailIds&
update_mail_ids (RupdateMailIds"&
PBGetAllMailReqCmd
uid (Ruid"ç
PBGetAllMailRspCmd
code (Rcode
error (	Rerror
uid (Ruid;
mail_simple_list (2.PBMailSimpleDataRmailSimpleList"D
PBGetMailDetailReqCmd
uid (Ruid
mail_ids (RmailIds"ò
PBGetMailDetailRspCmd
code (Rcode
error (	Rerror
uid (Ruid
mail_ids (RmailIds(
	mail_list (2.PBMailDataRmailList"=
PBReadMailReqCmd
uid (Ruid
mail_id (RmailId"ë
PBReadMailRspCmd
code (Rcode
error (	Rerror
uid (Ruid
mail_id (RmailId(
	mail_data (2.PBMailDataRmailData"@
PBGetRewardReqCmd
uid (Ruid
mail_ids (RmailIds"j
PBGetRewardRspCmd
code (Rcode
error (	Rerror
uid (Ruid
mail_ids (RmailIds">
PBDelMailReqCmd
uid (Ruid
mail_ids (RmailIds"h
PBDelMailRspCmd
code (Rcode
error (	Rerror
uid (Ruid
mail_ids (RmailIdsbproto3
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
ê+

room.proto
user.proto"≠
PBRoomSearchInfo
roomid (Rroomid
chapter (Rchapter

difficulty (R
difficulty
	playercnt (R	playercnt
	master_id (RmasterId
master_name (	R
masterName
is_open (RisOpen
	needcheck (R	needcheck
needpwd	 (Rneedpwd
describe
 (	Rdescribe"p
PBRoomMemberInfo
seat_idx (RseatIdx
is_ready (RisReady&
mem_info (2.PBUserAttrRmemInfo"Ù

PBRoomInfo
roomid (Rroomid
is_open (RisOpen
	needcheck (R	needcheck
needpwd (Rneedpwd
pwd (	Rpwd
chapter (Rchapter

difficulty (R
difficulty
state (Rstate
describe	 (	Rdescribe
map_id
 (RmapId
boss_id (RbossId
	master_id (RmasterId

ds_address (	R	dsAddress
ds_ip (	RdsIp"n
PBRoomApplyInfo
uid (Ruid*

apply_info (2.PBUserAttrR	applyInfo

apply_time (R	applyTime"J
PBRoomInviteInfo

invite_uid (R	inviteUid
mem_uid (RmemUid"ã
PBRoomWholeInfo(
	room_data (2.PBRoomInfoRroomData
	master_id (RmasterId
master_name (	R
masterName+
players (2.PBRoomMemberInfoRplayers/

apply_list (2.PBRoomApplyInfoR	applyList2
invite_list (2.PBRoomInviteInfoR
inviteList"ﬂ
PBCreateRoomReqCmd
uid (Ruid
is_open (RisOpen
	needcheck (R	needcheck
needpwd (Rneedpwd
pwd (	Rpwd
chapter (Rchapter

difficulty (R
difficulty
describe (	Rdescribe"V
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
searchData"Ù
PBModRoomReqCmd
uid (Ruid
roomid (Rroomid
is_open (RisOpen
	needcheck (R	needcheck
needpwd (Rneedpwd
pwd (	Rpwd
chapter (Rchapter

difficulty (R
difficulty
describe	 (	Rdescribe"ÿ
PBModRoomRspCmd
code (Rcode
error (	Rerror
is_open (RisOpen
	needcheck (R	needcheck
needpwd (Rneedpwd
pwd (	Rpwd
chapter (Rchapter

difficulty (R
difficulty"s
PBRoomSyncCmd
roomid (Rroomid
	sync_type (RsyncType-
	sync_info (2.PBRoomWholeInfoRsyncInfo"=
PBApplyRoomReqCmd
uid (Ruid
roomid (Rroomid"U
PBApplyRoomRspCmd
code (Rcode
error (	Rerror
roomid (Rroomid"K
PBDealApplyRoomReqCmd
deal_uid (RdealUid
deal_op (RdealOp"u
PBDealApplyRoomRspCmd
code (Rcode
error (	Rerror
deal_uid (RdealUid
deal_op (RdealOp"I
PBDealApplyRoomSyncCmd
deal_op (RdealOp
roomid (Rroomid"O
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
kick_uid (RkickUid"]
PBInviteRoomReqCmd
uid (Ruid
roomid (Rroomid

invite_uid (R	inviteUid"á
PBInviteRoomRspCmd
code (Rcode
error (	Rerror
uid (Ruid
roomid (Rroomid

invite_uid (R	inviteUid"ã
PBInviteRoomSyncCmd
roomid (Rroomid
mem_uid (RmemUid
mem_name (	RmemName(
	room_info (2.PBRoomInfoRroomInfo"[
PBDealInviteRoomReqCmd
uid (Ruid
roomid (Rroomid
deal_op (RdealOp"Ö
PBDealInviteRoomRspCmd
code (Rcode
error (	Rerror
uid (Ruid
roomid (Rroomid
deal_op (RdealOp"Q
PBDealInviteRoomSyncCmd

invite_uid (R	inviteUid
deal_op (RdealOp"X
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
ds_ip (	RdsIp"+
PBCheckReturnRoomReqCmd
uid (Ruid"£
PBCheckReturnRoomRspCmd
code (Rcode
error (	Rerror(
	room_data (2.PBRoomInfoRroomData4
member_datas (2.PBRoomMemberInfoRmemberDatasbproto3
Ó

shop.proto"Ÿ
PBShopBuySingle

product_id (R	productId
product_num (R
productNumD
single_price (2!.PBShopBuySingle.SinglePriceEntryRsinglePriceA
total_price (2 .PBShopBuySingle.TotalPriceEntryR
totalPrice>
SinglePriceEntry
key (Rkey
value (Rvalue:8=
TotalPriceEntry
key (Rkey
value (Rvalue:8"ñ
PBShopBuyLog
order_id (RorderId
	buyer_uid (RbuyerUid
buy_ts (RbuyTsH
log_total_price (2 .PBShopBuyLog.LogTotalPriceEntryRlogTotalPrice+
buy_data (2.PBShopBuySingleRbuyData@
LogTotalPriceEntry
key (Rkey
value (Rvalue:8"∞
PBShopPlayerData
uid (Ruid"
last_check_ts (RlastCheckTs"
self_order_id (RselfOrderIdO
buy_product_list (2%.PBShopPlayerData.BuyProductListEntryRbuyProductListC
buy_car_data (2!.PBShopPlayerData.BuyCarDataEntryR
buyCarData*
	shop_logs (2.PBShopBuyLogRshopLogsA
BuyProductListEntry
key (Rkey
value (Rvalue:8=
BuyCarDataEntry
key (Rkey
value (Rvalue:8"'
PBGetShopDataReqCmd
uid (Ruid"ø
PBGetShopDataRspCmd
code (Rcode
error (	Rerror
uid (Ruid

now_sys_ts (RnowSysTs;
shop_player_data (2.PBShopPlayerDataRshopPlayerDataO
shop_server_buy (2'.PBGetShopDataRspCmd.ShopServerBuyEntryRshopServerBuy@
ShopServerBuyEntry
key (Rkey
value (Rvalue:8"i
PBShopAddBuyCarReqCmd
uid (Ruid

product_id (R	productId
product_num (R
productNum"˙
PBShopAddBuyCarRspCmd
code (Rcode
error (	Rerror
uid (Ruid

now_sys_ts (RnowSysTsH
buy_car_data (2&.PBShopAddBuyCarRspCmd.BuyCarDataEntryR
buyCarData=
BuyCarDataEntry
key (Rkey
value (Rvalue:8"∫
PBShopDelBuyCarReqCmd
uid (RuidN
product_id_num (2(.PBShopDelBuyCarReqCmd.ProductIdNumEntryRproductIdNum?
ProductIdNumEntry
key (Rkey
value (Rvalue:8"˙
PBShopDelBuyCarRspCmd
code (Rcode
error (	Rerror
uid (Ruid

now_sys_ts (RnowSysTsH
buy_car_data (2&.PBShopDelBuyCarRspCmd.BuyCarDataEntryR
buyCarData=
BuyCarDataEntry
key (Rkey
value (Rvalue:8"π
PBShopBuyReqCmd
uid (Ruid
with_car (RwithCar<

buy_id_num (2.PBShopBuyReqCmd.BuyIdNumEntryRbuyIdNum;
BuyIdNumEntry
key (Rkey
value (Rvalue:8"Ê
PBShopBuyRspCmd
code (Rcode
error (	Rerror
uid (Ruid

now_sys_ts (RnowSysTs<

buy_id_num (2.PBShopBuyRspCmd.BuyIdNumEntryRbuyIdNum;
BuyIdNumEntry
key (Rkey
value (Rvalue:8bproto3
é

team.proto
user.proto"¢

PBTeamInfo
team_id (RteamId
	master_id (RmasterId(
	user_list (2.PBUserAttrRuserList
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
	team_info (2.PBTeamInfoRteamInfo"o
PBTeamCreateReqCmd
uid (Ruid(
	base_data (2.PBUserAttrRbaseData

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

target_uid (R	targetUid"Ü
PBTeamJoinReqCmd
uid (Ruid

master_uid (R	masterUid
team_id (RteamId(
	base_data (2.PBUserAttrRbaseData"^
PBTeamJoinRspCmd
code (Rcode

master_uid (R	masterUid
team_id (RteamIdbproto3
Ä 
trade.proto
item.proto"K
PBTradeData!
single_price (RsinglePrice
sale_num (RsaleNum"ç
PBAuctionData
start_price (R
startPrice!
buyout_price (RbuyoutPrice
	cur_price (RcurPrice
	buyer_uid (RbuyerUid"†
PBTradeProductBaseData
trade_id (RtradeId

seller_uid (R	sellerUid(
	item_data (2.PBItemDataRitemData
beg_ts (RbegTs
end_ts (RendTs
state (Rstate+

trade_data (2.PBTradeDataR	tradeData1
auction_data (2.PBAuctionDataRauctionData"ˇ
PBTradeLogData
log_id (RlogId
trade_id (RtradeId(
	item_data (2.PBItemDataRitemData

deal_price (R	dealPrice

seller_uid (R	sellerUid
	buyer_uid (RbuyerUid
trade_ts (RtradeTs
	trade_tax (RtradeTax"¡
PBTradeSearchData
	config_id (RconfigId
	min_price (RminPrice&
last_deal_price (RlastDealPrice*
yes_average_price (RyesAveragePrice"
min_price_num (RminPriceNum=
	price_num (2 .PBTradeSearchData.PriceNumEntryRpriceNum;
PriceNumEntry
key (Rkey
value (Rvalue:8"b
PBPriceAndNum
price (Rprice
now_num (RnowNum"
trade_id_list (RtradeIdList"ö
PBTradeRecordInfo&
trade_config_id (RtradeConfigId
sale_num (RsaleNum(
sale_total_price (RsaleTotalPrice&
last_deal_price (RlastDealPrice
	update_ts (RupdateTs 
yes_sale_num (R
yesSaleNum/
yes_sale_total_price (RyesSaleTotalPrice*
yes_average_price (RyesAveragePrice
	min_price	 (RminPrice"
min_price_num
 (RminPriceNumD
price_to_num (2".PBTradeRecordInfo.PriceToNumEntryR
priceToNumM
PriceToNumEntry
key (Rkey$
value (2.PBPriceAndNumRvalue:8"j
PBSelfTradeInfo!
box_capacity (RboxCapacity
	trade_ids (RtradeIds
log_ids (RlogIds"Í
PBSelfTradeData1
simple_info (2.PBSelfTradeInfoR
simpleInfoD
product_list (2!.PBSelfTradeData.ProductListEntryRproductList8
log_list (2.PBSelfTradeData.LogListEntryRlogListW
ProductListEntry
key (Rkey-
value (2.PBTradeProductBaseDataRvalue:8K
LogListEntry
key (Rkey%
value (2.PBTradeLogDataRvalue:8"(
PBGetTradeInfoReqCmd
uid (Ruid"å
PBGetTradeInfoRspCmd
code (Rcode
error (	Rerror
uid (Ruid8
self_trade_info (2.PBSelfTradeDataRselfTradeInfo"ß
PBSearchTradeProductReqCmd
uid (Ruid

config_ids (R	configIds

condition1 (R
condition1

condition2 (R
condition2

condition3 (R
condition3

condition4 (R
condition4

condition5 (R
condition5
	sort_type (RsortType
	start_idx	 (RstartIdx"ï
PBSearchTradeProductRspCmd
code (Rcode
error (	Rerror
uid (Ruid;
search_products (2.PBTradeSearchDataRsearchProducts"÷
PBSearchAuctionProductReqCmd
uid (Ruid

config_ids (R	configIds

condition1 (R
condition1

condition2 (R
condition2

condition3 (R
condition3

condition4 (R
condition4

condition5 (R
condition5+
custom_conditions (RcustomConditions
	sort_type	 (RsortType
	start_idx
 (RstartIdx"í
PBSearchAuctionProductRspCmd
code (Rcode
error (	Rerror
uid (RuidZ
search_products (21.PBSearchAuctionProductRspCmd.SearchProductsEntryRsearchProductsZ
SearchProductsEntry
key (Rkey-
value (2.PBTradeProductBaseDataRvalue:8"´
PBTradeSaleReqCmd
uid (Ruid
	config_id (RconfigId
pos (Rpos
sale_num (RsaleNum!
single_price (RsinglePrice
sale_ts (RsaleTs"j
PBTradeSaleRspCmd
code (Rcode
error (	Rerror
uid (Ruid
trade_id (RtradeId"À
PBAuctionSaleReqCmd
uid (Ruid
	config_id (RconfigId
uniqid (Runiqid
pos (Rpos
start_price (R
startPrice!
buyout_price (RbuyoutPrice
sale_ts (RsaleTs"l
PBAuctionSaleRspCmd
code (Rcode
error (	Rerror
uid (Ruid
trade_id (RtradeIdbproto3
‰
google/protobuf/any.protogoogle.protobuf"6
Any
type_url (	RtypeUrl
value (RvalueBv
com.google.protobufBAnyProtoPZ,google.golang.org/protobuf/types/known/anypb¢GPB™Google.Protobuf.WellKnownTypesbproto3