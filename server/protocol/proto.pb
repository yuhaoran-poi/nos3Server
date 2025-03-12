
ﬂ
Common.proto"ì
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
‘A
GameDataItem.proto"D
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
played_gods_data (2.PBPlayedGodsDataSRplayedGodsData"K
PBEntry
	config_id (RconfigId#
entry_quality (RentryQuality"û
	PBAntique
uniq_id (RuniqId
quality (Rquality
price (2.PBCoinRprice.
remain_identify_num (RremainIdentifyNum'
identify_result (RidentifyResult
is_show (RisShow$
	item_info (2.PBItemRitemInfo'

entry_list (2.PBEntryR	entryList";

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
diagrams_card_bag (2.PBBagDiagramsCardRdiagramsCardBag*ê
ITEM_OPERATION_TYPE
ITEM_OPERATION_TYPE_NONE 
ITEM_OPERATION_TYPE_UPDATA
ITEM_OPERATION_TYPE_DELETE
ITEM_OPERATION_TYPE_ADDbproto3
Ù
LoginGateCmd.proto"™
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
‰
google/protobuf/any.protogoogle.protobuf"6
Any
type_url (	RtypeUrl
value (RvalueBv
com.google.protobufBAnyProtoPZ,google.golang.org/protobuf/types/known/anypb¢GPB™Google.Protobuf.WellKnownTypesbproto3