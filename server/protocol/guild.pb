
«ñ

user.proto"^
PBGetOpenBoxReqCmd
uid (Ruid
item_id (RitemId

item_count (R	itemCount"–
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
idx (Ridx"á
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
uniqid (Runiqid"§
PBMagicItem$
	item_info (2.PBItemRitemInfo
uniqid (Runiqid
used_id (RusedId
idx (Ridx
	light_cnt (RlightCnt
tags (Rtags"«
PBMagicItemImage
	config_id (RconfigId
get_ts (RgetTs
up_level (RupLevel
up_exp (RupExp

star_level (R	starLevel
tier (Rtier"N
PBMagicItemImageS9
item_image_list (2.PBMagicItemImageRitemImageList"ª
PBDiagramsCard$
	item_info (2.PBItemRitemInfo
uniqid (Runiqid
used_id (RusedId
idx (Ridx
	light_cnt (RlightCnt
tags (Rtags"®
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
idx (Ridx"Ø
PBSkin$
	item_info (2.PBItemRitemInfo;
experience_card_start_time (RexperienceCardStartTime7
experience_card_end_time (RexperienceCardEndTime
add_time (RaddTime
used_id (RusedId"ú
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
idx (Ridx"
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
diagrams_card_list (2.PBDiagramsCardRdiagramsCardList"ş
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
	is_unlock (RisUnlock"¥

PBMainStar$
	item_info (2.PBItemRitemInfo
used_id (RusedId
	is_unlock (RisUnlock;
main_star_effect (2.PBMainStarEffectRmainStarEffect"ğ
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
main_star_effect_list (2.PBMainStarEffectRmainStarEffectList"€
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
entry_quality (RentryQuality"œ
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
.PBAntiqueRantiqueList"â
PBBagNormal%
	coin_data (2.PBCoinSRcoinData%
	item_data (2.PBItemSRitemData3
treasurebox_data (2.PBItemSRtreasureboxData%
	gift_data (2.PBItemSRgiftData;
secret_paper_data (2.PBSecretPaperSRsecretPaperData5
taboo_word_data (2.PBTabooWordSRtabooWordData5
minor_star_data (2.PBMinorStarSRminorStarData"Ÿ
	PBBagUniq2
uniq_item_data (2.PBUniqItemSRuniqItemData.
trigram_data (2.PBTrigramSRtrigramData.
antique_data (2.PBAntiqueSRantiqueData"ş
PBBagOnlyOne'

title_data (2.PBItemSR	titleData/
awe_item_data (2.PBAweItemSRaweItemData8
star_symbol_data (2.PBStarSymbolSRstarSymbolData5
item_image_data (2.PBItemImageSRitemImageData2
main_star_data (2.PBMainStarSRmainStarDataE
main_star_effect_data (2.PBMainStarEffectSRmainStarEffectData(

gourd_data (2	.PBGourdSR	gourdData"2
	PBBagSkin%
	skin_data (2.PBSkinSRskinData"Š

PBBagMagic5
magic_item_data (2.PBMagicItemSRmagicItemDataE
magic_item_image_data (2.PBMagicItemImageSRmagicItemImageData"Ù
PBBagSealMonster;
seal_monster_data (2.PBSealMonsterSRsealMonsterData>
monster_equip_data (2.PBMonsterEquipSRmonsterEquipDataH
seal_monster_skin_data (2.PBSealMonsterSkinSRsealMonsterSkinData"£
PBBagDiagramsCard>
diagrams_card_data (2.PBDiagramsCardSRdiagramsCardDataN
diagrams_card_image_data (2.PBDiagramsCardImageSRdiagramsCardImageData"Ú
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
diagrams_card_bag (2.PBBagDiagramsCardRdiagramsCardBag"£

PBRankNode
grade (Rgrade
level (Rlevel
star (Rstar
score (Rscore"
zhu_ji_points (RzhuJiPoints
	all_stars (RallStars"Ë
PBRankLevel*

ghost_rank (2.PBRankNodeR	ghostRank*

human_rank (2.PBRankNodeR	humanRank1
ghost_top_rank (2.PBRankNodeRghostTopRank1
human_top_rank (2.PBRankNodeRhumanTopRank"4
PBPinchFaceData!
setting_data (	RsettingData"H
PBCurUseShowRole
role_id (RroleId
	skin_list (RskinList"Î
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

rank_level (2.PBRankLevelR	rankLevel5
cur_show_role (2.PBCurUseShowRoleRcurShowRole8
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
mons_skin_list (RmonsSkinList"/
PBClientGetUsrSimInfoReqCmd
uid (Ruid"€
PBClientGetUsrSimInfoRspCmd
code (Rcode
error (	Rerror
uid (Ruid%
info (2.PBUserSimpleInfoRinfo*
ITEM_OPERATION_TYPE
ITEM_OPERATION_TYPE_NONE 
ITEM_OPERATION_TYPE_UPDATA
ITEM_OPERATION_TYPE_DELETE
ITEM_OPERATION_TYPE_ADDJí¡
  ş

  
#
  	 å®¢æˆ·ç«¯å¼€å¯å®åŒ£



 

  $ åè®®æ•°æ®


  	

  


  "#

 $

 

 

 "#

 $

 

 

 "#
0
 $ å®¢æˆ·ç«¯å¼€å¯å®åŒ£ è¿”å›ä¿¡æ¯




3
 "& æœåŠ¡å™¨è¿”å›,0æˆåŠŸ,å…¶ä»–å¤±è´¥


 	

 


 

" é”™è¯¯ä¿¡æ¯









 åè®®æ•°æ®


	






$

	




"#

$





"#
&
    èƒŒåŒ…é“å…·æ›´æ–°ç±»å‹



 

  %

   

  #$
!
 # æ›´æ–°é“å…·æ•°æ®


 

 !"

 # åˆ é™¤é“å…·


 

 !"
!
   æ–°å¢åŠ çš„é“å…·


 

 

# ' è´§å¸



#

 %

 %	

 %

 %

&

&	

&

&

* - èµç¦æ•°æ®



*

 +

 +

 +

 +

,

,

,

,

0 4 é€šç”¨å±æ€§



0

 2$

 2

 2

 2"#

3 

3

3

3

7 ; é€šç”¨æŠ€èƒ½



7

 9,

 9

 9!

 9*+

:4

:

:

:23

> G é€šç”¨é“å…·



>

 @$

 @	

 @

 @"#

A,

A	

A"

A*+

B4"é“å…·ç±»å‹


B

B )

B23

C4"å‡çº§


C

C (

C23

D4

D

D &

D23

E4"å‡æ˜Ÿ


E

E *

E23

F4"é¢å¤–å±æ€§	


F

F

F +

F23
 
J O é“å…·ç®€åŒ–ä¿¡æ¯



J

 L,

 L

 L!

 L*+

M4

M

M *

M23

N4

N

N &

N23

R X é€šç”¨æ§½ä½



R

 T,

 T

 T

 T*+

U,

U

U!

U*+

V,

V

V

V*+
+
W,"æ’æ§½é“å…·è¯¦æƒ…(å¯çœç•¥)


W

W#

W*+
 
	[ _ ä¸å¯å †å é“å…·



	[

	 ],

	 ]

	 ]!

	 ]*+

	^,

	^

	^

	^*+


b j æ³•å™¨




b


 d,


 d


 d!


 d*+


e,


e


e


e*+
"

f,"è¢«è£…å¤‡çš„å…³è”id



f


f


f*+


g4


g


g


g23


h,


h


h!


h*+


i4"éšæœºè¯æ¡id



i


i


i $


i23

m u æ³•å™¨å›¾é‰´



m

 o,"	é“å…·id


 o

 o!

 o*+
 
p,"å›¾é‰´è§£é”æ—¶é—´


p

p

p*+

q,"å‡çº§


q

q 

q*+

r,

r

r

r*+

s,"å‡æ˜Ÿ


s

s"

s*+

t,"å‡é˜¶


t

t

t*+


w z


w

 y8

 y

 y!

 y"1

 y67

} … å…«å¦ç‰Œ



}

 ,

 

 !

 *+

€,

€

€

€*+
#
,"è¢«è£…å¤‡çš„å…³è”id






*+

‚4

‚

‚

‚23

ƒ,

ƒ

ƒ!

ƒ*+

„4"éšæœºè¯æ¡id


„

„

„ $

„23

ˆ  å…«å¦ç‰Œå›¾é‰´


ˆ

 Š,"	é“å…·id


 Š

 Š!

 Š*+
!
‹,"å›¾é‰´è§£é”æ—¶é—´


‹

‹

‹*+

Œ,"å‡çº§


Œ

Œ 

Œ*+

,





*+

,"å‡æ˜Ÿ




"

*+

,"å‡é˜¶






*+

’ •

’

 ”;

 ”

 ”$

 ”%4

 ”9:

˜ œ ç§˜ç±


˜

 š,

 š

 š!

 š*+

›," è¢«å…³è”id


›

›

›*+

Ÿ ¤ è®³å­—


Ÿ

 ¡,

 ¡

 ¡!

 ¡*+
#
¢,"è¢«è£…å¤‡çš„å…³è”id


¢

¢

¢*+

£4" æ§½ä½


£

£

£23

§ ° çš®è‚¤


§

 ©4

 ©


 ©!

 ©23
?
«<1ä½“éªŒå¼€å§‹æ—¶é—´(ä¸º0è¡¨ç¤ºæ°¸ä¹…ï¼Œéä½“éªŒ)


«

«2

«:;
?
­<1ä½“éªŒç»“æŸæ—¶é—´(ä¸º0è¡¨ç¤ºæ°¸ä¹…ï¼Œéä½“éªŒ)


­

­0

­:;

®4

®

® 

®23
)
¯4"è¢«è£…å¤‡çš„å…³è”è§’è‰²id


¯

¯

¯23
"
³ º å¬å”¤æ€ªç‰©çš®è‚¤


³

 µ4

 µ

 µ!

 µ23
@
¶<"2 ä½“éªŒå¼€å§‹æ—¶é—´(ä¸º0è¡¨ç¤ºæ°¸ä¹…ï¼Œéä½“éªŒ)


¶

¶2

¶:;
@
·<"2 ä½“éªŒç»“æŸæ—¶é—´(ä¸º0è¡¨ç¤ºæ°¸ä¹…ï¼Œéä½“éªŒ)


·

·0

·:;
%
¸4" è·å¾—æ—¶å€™çš„æ—¶é—´


¸

¸ 

¸23
8
¹<"* è¢«è£…å¤‡çš„é¬¼æ€ªid(å¯ä»¥è¢«å¤šä¸ªè£…)


¹

¹

¹ 3

¹:;

½ Á è¾…æ˜Ÿ


½

 ¿,

 ¿

 ¿!

 ¿*+
#
À4"è¢«è£…å¤‡çš„å…³è”id


À

À

À '

À23

Ä Ê å¦è±¡


Ä

 Æ,

 Æ

 Æ!

 Æ*+

Ç,

Ç

Ç

Ç*+
#
È,"è¢«è£…å¤‡çš„å…³è”id


È

È

È*+

É4

É

É

É23

Í Ó é•‡å±±ä¹‹å®


Í

 Ï,

 Ï

 Ï!

 Ï*+

Ğ,

Ğ

Ğ

Ğ*+

Ñ4

Ñ

Ñ

Ñ23
.
Ò+"  å½“å‰ç­‰çº§å‡çº§å¤±è´¥æ¬¡æ•°


Ò

Ò&

Ò)*

Ö Ü æ€ªç‰©è£…å¤‡


Ö

 Ø,

 Ø

 Ø!

 Ø*+

Ù,

Ù

Ù

Ù*+
#
Ú,"è¢«è£…å¤‡çš„å…³è”id


Ú

Ú

Ú*+

Û4

Û

Û

Û23
"
ß â æ€ªç‰©è£…å¤‡åˆ—è¡¨


ß

 á9

 á

 á

 á 2

 á78

å è è®³å­—åˆ—è¡¨


å

 ç6

 ç

 ç

 ç /

 ç45

ê í å…«å¦ç‰Œåˆ—è¡¨


ê

 ì9

 ì

 ì

 ì 2

 ì78
$
ğ ş å¬å”¤ä»¤ç‰Œ(æ€ªç‰©)


ğ

 ò,

 ò

 ò!

 ò*+

ó,

ó

ó

ó*+

ô,"é˜´å¯¿


ô

ô

ô*+

õ,"é˜´æ°”


õ

õ!

õ*+

ö4"é¬¼æ€ªæŠ€èƒ½


ö

ö

ö .

ö23
!
÷4"åˆ·æ–°ç¼“å­˜æŠ€èƒ½


÷

÷

÷ ,

÷23

ø/"é¬¼æ€ªè£…å¤‡


ø

ø*

ø-.
!
ù-"è§£é”è£…å¤‡æ•°é‡


ù

ù(

ù+,
!
ú*" ç©¿æˆ´çš„çš®è‚¤id


ú

ú%

ú()

	û-"æ€ªç‰©æ˜µç§°


	û

	û!

	û*,


ü*" è®³å­—



ü


ü$


ü')

ı0" å…«å¦ç‰Œæ•°æ®


ı

ı*

ı-/

 … æ³•å°




 ƒ"	é“å…·id


 ƒ

 ƒ

 ƒ

„$"è§£é”æ—¶é—´


„

„

„"#

ˆ ‹ æ˜Ÿè±¡


ˆ

 Š,

 Š

 Š!

 Š*+

’ — ä¸»æ˜Ÿæ•ˆæœ


’

 ”,

 ”

 ”!

 ”*+
$
•$" è¢«è£…å¤‡çš„å…³è”id


•

•

•"#

–," æ˜¯å¦è§£é”


–

–!

–*+

™ Ÿ ä¸»æ˜Ÿ


™

 ›,

 ›

 ›!

 ›*+
$
œ," è¢«è£…å¤‡çš„å…³è”id


œ

œ

œ*+

," æ˜¯å¦è§£é”




!

*+

5" ä¸»æ˜Ÿæ•ˆæœ




 0

34
%
 ¢ ± æ‹å–è¡Œé¢å¤–æ•°æ®


 ¢

  ¤4"å‡çº§


  ¤

  ¤ (

  ¤23

 ¥4

 ¥

 ¥ &

 ¥23

 ¦4"å‡æ˜Ÿ


 ¦

 ¦ *

 ¦23

 §4"é¢å¤–å±æ€§


 §

 §

 § +

 §23
&
 ©<æ³•å™¨
"å…ƒç´ è¯æ¡id


 ©

 ©

 ©(4

 ©:;

 ªD"æ™®é€šè¯æ¡id


 ª

 ª

 ª(,

 ªBC

 ¬,é¬¼æ€ª
"é˜´å¯¿


 ¬

 ¬

 ¬*+

 ­,"é˜´æ°”


 ­

 ­!

 ­*+

 ®4"é¬¼æ€ªæŠ€èƒ½


 ®

 ®

 ® .

 ®23
!
 	¯."è§£é”è£…å¤‡æ•°é‡


 	¯

 	¯(

 	¯+-

 
°-"æ€ªç‰©æ˜µç§°


 
°

 
°!

 
°*,

!´ · è´§å¸åˆ—è¡¨


!´

! ¶(

! ¶

! ¶

! ¶!

! ¶&'
%
"º ½ å¯å †å é“å…·åˆ—è¡¨


"º

" ¼(

" ¼

" ¼

" ¼!

" ¼&'
(
#À Ã ä¸å¯å †å é“å…·åˆ—è¡¨


#À

# Â5

# Â

# Â

# Â .

# Â34

$Æ É çš®è‚¤åˆ—è¡¨


$Æ

$ È(

$ È

$ È

$ È!

$ È&'
(
%Ì Ï å¬å”¤æ€ªç‰©çš®è‚¤åˆ—è¡¨


%Ì

% ÎC

% Î

% Î"

% Î(>

% ÎAB

&Ò Õ æ³•å™¨åˆ—è¡¨


&Ò

& Ô6

& Ô

& Ô

& Ô /

& Ô45

'Ú İ ç§˜ç±åˆ—è¡¨


'Ú

' Ü8

' Ü

' Ü

' Ü 1

' Ü67

(à ã è¾…æ˜Ÿåˆ—è¡¨


(à

( â6

( â

( â

( â /

( â45

)æ é å¦è±¡åˆ—è¡¨


)æ

) è+

) è

) è

) è$

) è)*
"
*ì ï é•‡å±±ä¹‹å®åˆ—è¡¨


*ì

* î,

* î

* î

* î%

* î*+
*
+ò õ å¬å”¤ä»¤ç‰Œ(æ€ªç‰©)åˆ—è¡¨


+ò

+ ô8

+ ô

+ ô

+ ô 1

+ ô67

,ø û æ³•å°åˆ—è¡¨


,ø

, ú6

, ú

, ú

, ú /

, ú45

-ş  æ˜Ÿè±¡åˆ—è¡¨


-ş

- €7

- €

- €

- € 0

- €56
"
.„ ˆ é“å…·å›¾é‰´åˆ—è¡¨


.„

. †"	é“å…·id


. †

. †

. †
!
.‡$"å›¾é‰´è§£é”æ—¶é—´


.‡

.‡

.‡"#

/Š 

/Š

/ Œ3

/ Œ

/ Œ

/ Œ,

/ Œ12

0 “ ä¸»æ˜Ÿ


0

0 ’3" ä¸»æ˜Ÿåˆ—è¡¨


0 ’

0 ’

0 ’ .

0 ’12

1– ™ ä¸»æ˜Ÿæ•ˆæœ


1–
"
1 ˜<" ä¸»æ˜Ÿæ•ˆæœåˆ—è¡¨


1 ˜

1 ˜!

1 ˜"7

1 ˜:;

2› ¥

2›

2 %"	è‘«èŠ¦id


2 

2  

2 #$

2&"è‘«èŠ¦æ˜µç§°


2

2!

2$%

2Ÿ"è‘«èŠ¦ç­‰çº§


2Ÿ

2Ÿ

2Ÿ

2 "è‘«èŠ¦ç»éªŒ


2 

2 

2 

2¡)"æ€»å¤©èµ‹ç‚¹


2¡

2¡$

2¡'(

2¢"å½“å‰å¤©èµ‹ç‚¹


2¢

2¢

2¢

2£0"å¤©èµ‹å±æ€§


2£

2£

2£ +

2£./
!
2¤&"è‘«èŠ¦å†·å´æ—¶é—´


2¤

2¤!

2¤$%

3§ ª

3§

3 ©*

3 ©

3 ©

3 ©#

3 ©()

4¬ °

4¬

4 ®" æ§½ä½


4 ®

4 ®

4 ®

4¯"
 ç¥æ˜id


4¯

4¯

4¯

5² µ

5²

5 ´7

5 ´

5 ´!

5 ´"2

5 ´56

6¸ ¼ ç¥æ˜


6¸

6 º." ç¥æ˜åˆ—è¡¨


6 º

6 º

6 º )

6 º,-
%
6»=" å‡ºæˆ˜çš„ç¥æ˜æ•°æ®


6»

6»(8

6»;<

7¾ Â

7¾

7 À"
 è¯æ¡id


7 À

7 À

7 À

7Á*" è¯æ¡å“è´¨


7Á

7Á%

7Á()

8Ä Î

8Ä

8 Æ$"
 å”¯ä¸€id


8 Æ

8 Æ

8 Æ"#

8Ç$" å“è´¨


8Ç

8Ç

8Ç"#

8È"" ä»·æ ¼


8È

8È

8È !
"
8É0" å‰©ä½™é‰´å®šæ¬¡æ•°


8É

8É+

8É./

8Ê," é‰´å®šç»“æœ


8Ê

8Ê'

8Ê*+
"
8Ë$" æ˜¯å¦åœ¨å±•ç¤ºä¸­


8Ë

8Ë

8Ë"#

8Ì&" ç‰©å“ä¿¡æ¯


8Ì

8Ì!

8Ì$%

8Í&" è¯æ¡åˆ—è¡¨


8Í

8Í

8Í"

8Í$%

9Ğ Ó

9Ğ

9 Ò9

9 Ò

9 Ò

9 Ò(4

9 Ò78

:Õ å

:Õ
8
: Ø<* è´§å¸æ•°æ® æ‰€æœ‰è´§å¸ç±»å‹çš„æ•°æ®


: Ø

: Ø

: Ø:;
%
:Ú< å¯å †å é“å…·ä¿¡æ¯


:Ú

:Ú

:Ú:;

:Ü, å®åŒ£


:Ü

:Ü

:Ü*+

:Ş< ç¤¼åŒ…


:Ş

:Ş

:Ş:;

:à4 ç§˜ç±


:à

:à(

:à23

:â4 è®³å­—


:â

:â$

:â23

:ä4 è¾…æ˜Ÿ


:ä

:ä$

:ä23

;ç ï

;ç
"
; ê, ä¸å¯å †å é“å…·


; ê

; ê"

; ê*+

;ì$ å¦è±¡


;ì

;ì

;ì"#

;î$ å¤è‘£


;î

;î

;î"#

<ñ 

<ñ
+
< ôL ç§°å·ã€å¤´åƒã€å¤´åƒæ¡†


< ô

< ô

< ôJK

<öL é•‡å±±ä¹‹å®


<ö

<ö 

<öJK

<øD æ˜Ÿè±¡


<ø

<ø&

<øBC

<úD é“å…·å›¾é‰´


<ú

<ú$

<úBC

<üL ä¸»æ˜Ÿ


<ü

<ü"

<üJK

<ş< ä¸»æ˜Ÿæ•ˆæœ


<ş

<ş 5

<ş:;

<€L ç‚¼é¬¼è‘«èŠ¦


<€

<€

<€JK

=ƒ ‡

=ƒ
%
= †$ æ‰€æœ‰çš„çš®è‚¤æ•°æ®


= †

= †

= †"#

>‰ 

>‰

> ŒD æ³•å™¨


> Œ

> Œ$

> ŒBC

>4 æ³•å™¨å›¾é‰´


>

>/

>23

?“ ›

?“
$
? –D å¬å”¤ä»¤ç‰Œ(æ€ªç‰©)


? –

? –(

? –BC

?˜D æ€ªç‰©è£…å¤‡


?˜

?˜*

?˜BC
(
?š< å¬å”¤æ€ªç‰©çš®è‚¤æ•°æ®


?š

?š 6

?š:;

@ £

@

@  T å…«å¦ç‰Œ


@  

@  (:

@  RS

@¢D å…«å¦ç‰Œå›¾é‰´


@¢

@¢ 8

@¢BC

A¥ ®

A¥

A §<

A §

A §"

A §:;

A¨D

A¨

A¨ (

A¨BC

A©4

A©

A©$

A©23

AªD

Aª

Aª (

AªBC

A«D

A«

A« )

A«BC

A¬<

A¬

A¬ 0

A¬:;

A­<

A­

A­ 1

A­:;
a
B± ¸S----------------------------------æ–°å¢åè®®----------------------------------//


B±

B ² "å“é˜¶


B ²

B ²

B ²

B³ "å“çº§


B³

B³

B³
!
B´"å½“å‰æ˜Ÿæ˜Ÿæ•°é‡


B´

B´

B´

Bµ "
éšè—åˆ†


Bµ

Bµ

Bµ
9
B¶("+ç­‘åŸºç‚¹ï¼ˆç”¨äºå‡æ˜Ÿæˆ–æŠµæ‰£æ˜Ÿæ˜Ÿï¼‰


B¶

B¶#

B¶&'
i
B·$"[æ‰€æœ‰æ˜Ÿæ˜Ÿæ•°ï¼ˆè®°å½•ç©å®¶æ‰€æœ‰çš„æ˜Ÿæ˜Ÿæ•°é‡ï¼Œç”¨äºæ¢ç®—å“é˜¶ã€å“çº§è¿™äº›ï¼‰


B·

B·

B·"#

Cº Â æ®µä½


Cº

C ½"

C ½

C ½

C ½ !

C¾"

C¾

C¾

C¾ !
"
CÀ& å†å²æœ€é«˜æ®µä½


CÀ

CÀ!

CÀ$%

CÁ&

CÁ

CÁ!

CÁ$%
"
DÅ È æè„¸æ•°æ®å®šä¹‰


DÅ

D Ç

D Ç


D Ç

D Ç
(
EË Ï å½“å‰å±•ç¤ºè§’è‰²ä¿¡æ¯


EË
'
E Í," å½“å‰å±•ç¤ºçš„è§’è‰²id


E Í	

E Í


E Í*+
%
EÎ$" ç©¿æˆ´çš„çš®è‚¤åˆ—è¡¨


EÎ

EÎ

EÎ

EÎ"#

FÑ î

FÑ

F Ó"

F Ó

F Ó

F Ó !

FÔ

FÔ


FÔ

FÔ

FÕ"

FÕ

FÕ

FÕ !

FÖ

FÖ	

FÖ


FÖ
$
F×" 0-æœªé€‰ 1-ç”· 2-å¥³


F×	

F×


F×

FØ" ç‚¹èµ


FØ	

FØ


FØ

FÙ" å¤´åƒæ¡†


FÙ	

FÙ


FÙ
"
FÚ"" è´¦æˆ·åˆ›å»ºæ—¶é—´


FÚ	

FÚ


FÚ !
)
FÜ è´¦æˆ·ç»éªŒ è´¦æˆ·ç­‰çº§


FÜ	

FÜ


FÜ

F	İ

F	İ	

F	İ


F	İ
B
F
Ş%"4æ€»çš„ç»éªŒç‚¹ï¼ˆè®°å½•æ‰€æœ‰è·å¾—çš„ç»éªŒç‚¹ï¼‰


F
Ş

F
Ş

F
Ş"$

Fà
 æˆ˜é˜ŸID


Fà	

Fà


Fà

Fá

Fá	

Fá


Fá

Fã% æ®µä½ä¿¡æ¯


Fã

Fã

Fã"$

Fä(

Fä

Fä"

Fä%'

Få)" æè„¸æ•°æ®


Få

Få#

Få&(
$
Fæ"å½“å‰ä½©æˆ´çš„ç§°å·


Fæ

Fæ

Fæ

Fç "ç©å®¶æ ‡ç­¾


Fç

Fç

Fç
'
Fè!"æœ€åä¸€æ¬¡åœ¨çº¿æ—¶é—´


Fè

Fè

Fè 
+
Fé#"ç´¯è®¡åœ¨çº¿æ—¶é•¿ å•ä½ç§’


Fé

Fé

Fé "
%
Fê" æ˜¯å¦ç¦è¨€ç­‰æ“ä½œ


Fê

Fê

Fê
&
Fë%"å‡ºæˆ˜çš„é¬¼å® å”¯ä¸€id


Fë

Fë

Fë"$
&
Fì%"å‡ºæˆ˜çš„é¬¼å® é…ç½®id


Fì

Fì

Fì"$
4
Fí-"& å‡ºæˆ˜çš„é¬¼å® ç©¿æˆ´çš„çš®è‚¤åˆ—è¡¨


Fí

Fí

Fí%

Fí*,
+
Gñ õ å®¢æˆ·ç«¯è¯·æ±‚ç®€ç•¥æ•°æ®


Gñ#

G ô åè®®æ•°æ®


G ô	

G ô


G ô
8
Hø ş* å®¢æˆ·ç«¯è¯·æ±‚ç®€ç•¥æ•°æ® è¿”å›ä¿¡æ¯


Hø#
:
H ú", æœåŠ¡å™¨éªŒè¯è¿”å›,0æˆåŠŸ,å…¶ä»–å¤±è´¥


H ú	

H ú


H ú

Hû" é”™è¯¯ä¿¡æ¯


Hû


Hû

Hû

Hü"
 ç”¨æˆ·ID


Hü	

Hü


Hü

Hı" ç®€ç•¥ä¿¡æ¯


Hı

Hı

Hıbproto3
õ•
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

apply_list (2.PBGuildApplyUserBaseInfoR	applyList"å
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

guild_data (2.PBGuildMemberDataR	guildData"í
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
contribute)
spoils_item (2.PBItemSR
spoilsItem!
season_point (RseasonPoint
op_mgr_name (	R	opMgrName
rechage_num (R
rechageNum!
operater_uid (RoperaterUid"…
PBGuildDutyInfo
duty_id (RdutyId
	duty_name (RdutyName

duty_right (R	dutyRight

duty_level (R	dutyLevel"™
PBGuidJoinCon
can_join (RcanJoin
min_rank (RminRank
	min_level (RminLevel
notice (	Rnotice

join_check (R	joinCheck"×
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
priceCount"¯
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
value (2.PBGuildMemberDataRvalue:8"–
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
recordList"…
PBGuildUserGuildFullData-

guild_info (2.PBGuildInfoDBR	guildInfo:
self_guild_data (2.PBGuildMemberDataRselfGuildData"
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
uid (Ruid"‰
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
	full_data (2.PBGuildUserGuildFullDataRfullData"½
PBGuildPlayerSetGuildInfoCmd
node_id (RnodeId
guild_id (RguildId

guild_name (R	guildName
guild_level (R
guildLevel)
guild_prosperity (RguildProsperity"Û
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
	bjoin_con (RbjoinCon"‡
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

guild_name (R	guildName"„
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
invitedUid"‘
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
me_invite_list (2.PBGuildInviteListRmeInviteList"ß
PBGuildRecordListReqCmd
log_type (RlogType
idx (Ridx
uid (Ruid
	sort_type (RsortType
b_asc (RbAsc
	b_manager (RbManager
des_uid (RdesUid

page_count (R	pageCount"ı
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

item_count (R	itemCount"
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
eGS_Destory*œ
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

AO_DELJ™
  ©	

  
	
  


  


 

  

  	

  

 "
åˆ›å»ºä¸­


 

 

 "åˆå§‹åŒ–ä¸­


 

 

 "æ­£å¸¸


 

 

 	"
å†»ç»“ä¸­


 	

 	

 
"
å·²é”€æ¯


 


 


   å…¬ä¼šé“å…·



 

  "èƒŒåŒ…æ ¼å­ID


  	

  


  

 "ç‰©å“å®ä¾‹ID


 	

 


 

 " é…ç½®æ–‡ä»¶ID


 	

 


 

 " æ•°é‡


 	

 


 
 
  å…¬ä¼šé“å…·åˆ—è¡¨





 +

 

 

 &

 )*
 
  å…¬ä¼šç”³è¯·ä¿¡æ¯



 

 .

 

 )

 ,-

"ç”³è¯·æ—¶é—´








" $ç”³è¯·åˆ—è¡¨



"

 #9

 #

 #)

 #*4

 #78
&
( 5 å…¬ä¼šä¸­çš„ç©å®¶æ•°æ®



(
'
 * åŸºç¡€ä¿¡æ¯
"
ç©å®¶uID


 *

 *

 *

+"ç©å®¶æ˜µç§°


+


+

+

,"ç©å®¶èŒåŠ¡Id


,

,

,

-"ç©å®¶è´¡çŒ®


-

-

-
 
.!"ç©å®¶æœ¬å‘¨è´¡çŒ®


.

.

. 
<
/"/ç©å®¶åœ¨çº¿çŠ¶æ€ true åœ¨çº¿ false ä¸åœ¨çº¿


/

/

/
/
0'""ä¸Šä¸€æ¬¡è·å–å·¥èµ„çš„æ—¶é—´æˆ³


0

0"

0%&
 
1"åŠ å…¥å…¬ä¼šæ—¶é—´


1

1

1

2"ä¸ªäººçš„DKPå€¼


2

2

2
&
	3"æ˜¯å¦æˆ˜åˆ©å“ç®¡ç†å‘˜


	3

	3

	3
/

4!""ä¸Šæ¬¡å‘æ”¾æˆ˜åˆ©å“çš„æ—¶é—´æˆ³



4


4


4 
&
8 < å…¬ä¼šä¸­çš„ç©å®¶æ•°æ®



8
'
 : åŸºç¡€ä¿¡æ¯
"
ç©å®¶uID


 :

 :

 :
#
;)"ç©å®¶å…¬ä¼šçš„æ•°æ®


;

;$

;'(
 
? O å…¬ä¼šè®°å½•ç±»å‹



?

 A"æ‰€æœ‰è®°å½•


 A

 A
-
B" èº«ä»½å˜æ›´ï¼ˆèŒä½å˜æ›´ï¼‰+


B

B

C"	åŠ å…¥ +


C

C

D"	é€€å‡º +


D

D

E""æˆ˜é˜Ÿæ”¹å +


E

E !

F"æˆ˜é˜Ÿæèµ  +


F

F

G"æˆ˜é˜Ÿå‡çº§


G

G
 
H"ä½¿ç”¨æˆ˜é˜Ÿä»“åº“


H

H
,
I "æˆ˜é˜Ÿæ’ä½ç§¯åˆ†å˜æ›´è®°å½•


I

I
#
	J"æˆ˜é˜ŸGKDå˜åŒ–è®°å½•


	J

	J
#

K"æˆ˜åˆ©å“å‘æ”¾è®°å½•



K


K
&
L"èµ›å­£ç§¯åˆ†å˜åŒ–è®°å½•


L

L
 
M"ç©å®¶å……å€¼è®°å½•


M

M
!
R f å…¬ä¼šè®°å½•ä¿¡æ¯ 



R

 S

 S

 S

 S
 
T"ç›®æ ‡ç©å®¶æ˜µç§°


T

T

T

U

U

U

U
A
V"4åªåœ¨ eRT_DUTY_CHANGE æœ‰ç”¨ï¼ˆè¡¨ç¤ºèŒä½åç§°)


V

V

V
+
W"åªåœ¨ eRT_GUILD_LV_UP æœ‰ç”¨


W

W

W
1
X"$åªåœ¨ eRT_CHANGE_GUILD_NAME æœ‰ç”¨


X

X

X

Y"ç›®æ ‡ç©å®¶UID


Y

Y

Y
>
Z"1åªåœ¨ eRT_DUTY_CHANGE æœ‰ç”¨ ï¼ˆè¡¨ç¤ºèŒä½ID)


Z

Z

Z
*
[""eRT_GuildGKDå˜åŒ–è®°å½• ,  


[

[

[ !
'
	\#"eRT_GuildGKD GKDå½“å‰å€¼


	\

	\

	\ "
!

]"eRT_GuildGKD å¤‡æ³¨



]


]


]
)
^"åªåœ¨ERT_JUANZENGæ—¶ä½¿ç”¨


^

^

^
8
_"+åªåœ¨ERT_JUANZENGæ—¶ä½¿ç”¨ï¼Œå¤å¸æ•°é‡


_

_

_

`"
è´¡çŒ®å€¼


`

`

`
7
a!"*åªåœ¨æˆ˜åˆ©å“å‘æ”¾æ—¶ä½¿ç”¨ï¼Œç‰©å“id


a

a

a 
-
b"" åªåœ¨ERT_SEASON_POINTæ—¶ä½¿ç”¨


b

b

b!
#
c"å‘æ”¾ç®¡ç†å‘˜åå­—


c


c

c
*
d""ç©å®¶å……å€¼çš„çµçŸ³æ•°é‡ 


d	

d

d!

e "æ“ä½œç©å®¶UID


e

e

e
 
l q å…¬ä¼šèŒä½ä¿¡æ¯



l

 m

 m

 m

 m

n

n

n

n

o"æŒ‰ä½è¯»å–


o

o

o

p"	èŒä½ç­‰çº§


p

p

p
 
t { åŠ å…¥å…¬ä¼šæ¡ä»¶



t

 v"å…è®¸åŠ å…¥


 v	

 v


 v
1
w	"$æœ€ä½æ®µä½ï¼ˆå“é˜¶<<16+å“çº§ï¼‰


w	

w

w

x	"æœ€ä½ç­‰çº§


x	

x

x

y	"
å®£ä¼ è¯­


y	

y

y
&
z	"åŠ å…¥å·¥ä¼šéœ€è¦å®¡æ ¸


z	

z

z
#
	~ ‘å…¬ä¼šçš„ç®€ç•¥ä¿¡æ¯



	~
 
	 "æ‰€å±èŠ‚ç‚¹åç§°


	 


	 

	 

	€"
å…¬ä¼šuid


	€	

	€


	€

	"
å…¬ä¼šå


	

	

	

	‚"å…¬ä¼šç­‰çº§


	‚

	‚

	‚

	ƒ"å…¬ä¼šé•¿ID


	ƒ

	ƒ

	ƒ

	„!"å…¬ä¼šé•¿åç§°


	„

	„

	„ 

	…"åˆ›å»ºæ—¶é—´


	…

	…

	…

	†"å…¬ä¼šç»éªŒ


	†

	†

	†

	‡"å…¬ä¼šè´¡çŒ®å€¼


	‡

	‡

	‡

		ˆ"å…¬ä¼šæ´»è·ƒåº¦


		ˆ

		ˆ

		ˆ
<
	
‰".å…¬ä¼šçŠ¶æ€ï¼ˆæ­£å¸¸ï¼Œå†»ç»“æˆ–è€…é”€æ¯ï¼‰


	
‰

	
‰

	
‰

	Š!"å…¬ä¼šå…¬å‘Š


	Š

	Š

	Š 
-
	‹ "å…¬ä¼šæˆå‘˜äººæ•°ï¼ˆå½“å‰ï¼‰


	‹

	‹

	‹
!
	Œ$"å…¬ä¼šäººæ•°ä¸Šé™


	Œ

	Œ

	Œ!#
!
	#"å…¬ä¼šåŠ å…¥æ¡ä»¶


	

	

	 "
'
	%"å…¬ä¼šæ¨èåˆ°æœŸæ—¶é—´


	

	

	"$

	"å…¬ä¼šå¤´åƒID


	

	

	
 
	 "å…¬ä¼šå¤´åƒæ¡†ID


	

	

	
(

” — å…¬ä¼šç®€ç•¥ä¿¡æ¯åˆ—è¡¨



”


 –1"å…¬ä¼šåˆ—è¡¨



 –


 –"


 –#-


 –/0
"
š  å…¬ä¼šæˆå‘˜åˆ—è¡¨


š

 œ1"æˆå‘˜åˆ—è¡¨


 œ

 œ 

 œ!,

 œ/0
"
  £ å…¬ä¼šèŒä½åˆ—è¡¨


 

 ¢/"èŒä½åˆ—è¡¨


 ¢

 ¢ 

 ¢!*

 ¢-.

ª ®å¥–åŠ±ä¿¡æ¯


ª

 ¬"å¥–åŠ±ç‰©å“ID


 ¬	

 ¬


 ¬

­"å¥–åŠ±æ•°é‡


­	

­


­
!
± ´å…¬ä¼šå¥–åŠ±åˆ—è¡¨


±

 ³+"å¥–åŠ±åˆ—è¡¨


 ³

 ³

 ³&

 ³)*
!
¸ ¾å…¬ä¼šä»»åŠ¡ä¿¡æ¯


¸
 
 º"ä»»åŠ¡é…ç½®è¡¨ID


 º	

 º


 º
!
»"æ¥å—ä»»åŠ¡æ—¶é—´


»	

»


»
3
¼"%å½“å‰å®Œæˆæ•°é‡ï¼ˆä»»åŠ¡è¿›åº¦ï¼‰


¼	

¼


¼
|
½"nä»»åŠ¡çŠ¶æ€ã€‚0è¡¨ç¤ºæœªæ¥å—ï¼Œ1è¡¨ç¤ºå·²æ¥å—æœªå®Œæˆï¼Œ2è¡¨ç¤ºå·²å®Œæˆæœªé¢†å¥–ï¼Œ3è¡¨ç¤ºå·²é¢†å¥–ã€‚


½	

½


½

Á Ää»»åŠ¡åˆ—è¡¨


Á

 Ã'"


 Ã

 Ã

 Ã"

 Ã%&
'
Æ Êå…¬ä¼šå•†åº—ç‰©å“ä»·æ ¼


Æ

 È

 È

 È	

 È

É

É

É	

É
'
Ì Óå…¬ä¼šå•†åº—ç‰©å“ä¿¡æ¯


Ì

 Î"	å”¯ä¸€ID


 Î

 Î	

 Î

Ï'"ä»·æ ¼


Ï

Ï"

Ï%&
!
Ğ"å·²è´­ä¹°çš„æ•°é‡


Ğ

Ğ	

Ğ

Ñ"	ç‰©å“id


Ñ

Ñ	

Ñ
!
Ò"ä¸Šæ¬¡åˆ·æ–°æ—¶é—´


Ò

Ò	

Ò
'
Õ Øå…¬ä¼šå•†åº—ç‰©å“åˆ—è¡¨


Õ

 ×+

 ×

 ×

 ×!&

 ×)*

Û úå…¬ä¼šä¿¡æ¯


Û

 Ü"
å…¬ä¼šuid


 Ü	

 Ü


 Ü

İ"
å…¬ä¼šå


İ

İ

İ

Ş"å…¬ä¼šç­‰çº§


Ş

Ş

Ş

ß"å…¬ä¼šé•¿ID


ß

ß

ß

à!"å…¬ä¼šé•¿åç§°


à

à

à 

á"åˆ›å»ºæ—¶é—´


á

á

á

â"å…¬ä¼šç»éªŒ


â

â

â

ã"å…¬ä¼šè´¡çŒ®å€¼


ã

ã

ã

ä"å…¬ä¼šæ´»è·ƒåº¦


ä

ä

ä
<
	å".å…¬ä¼šçŠ¶æ€ï¼ˆæ­£å¸¸ï¼Œå†»ç»“æˆ–è€…é”€æ¯ï¼‰


	å

	å

	å
$

æ'"å…¬ä¼šç®¡ç†å‘˜åˆ—è¡¨



æ


æ


æ!


æ$&

ç3"ç©å®¶åˆ—è¡¨


ç$

ç&-

ç02
-
è"å…¬ä¼šæˆå‘˜äººæ•°ï¼ˆå½“å‰ï¼‰


è	

è


è
1
é "#æˆå‘˜äººæ•°ç­‰çº§(ç¬¬å‡ ç­‰çº§ï¼‰


é	

é


é
!
ê""æœ€å¤§æˆå‘˜äººæ•°


ê

ê

ê!

ë!"å…¬ä¼šå…¬å‘Š


ë

ë

ë 
!
ì-"å…¬ä¼šç”³è¯·åˆ—è¡¨


ì

ì'

ì*,
!
í"å†»ç»“å¼€å§‹æ—¶é—´


í

í

í
!
î"å…¬ä¼šç”³è¯·æ•°é‡


î

î

î

ï "é”€æ¯æ—¶é—´


ï

ï

ï

ğ'"èŒä½åˆ—è¡¨


ğ

ğ!

ğ$&
'
ñ-"å…¬å‘Šä¸Šæ¬¡ä¿®æ”¹æ—¶é—´


ñ

ñ'

ñ*,
!
ò%"æœ¬èµ›å­£æ´»è·ƒåº¦


ò

ò

ò"$
!
ó$"å…¬ä¼šåŠ å…¥æ¡ä»¶


ó

ó

ó!#
-
ô$"å…¬ä¼šåå­—ä¸Šæ¬¡ä¿®æ”¹æ—¶é—´


ô

ô

ô!#
'
õ*"å…¬ä¼šæˆ˜åˆ©å“ç®¡ç†å‘˜


õ

õ

õ$

õ')
'
ö%"å…¬ä¼šæ¨èåˆ°æœŸæ—¶é—´


ö

ö

ö"$

÷"å…¬ä¼šå¤´åƒID


÷

÷

÷
 
ø "å…¬ä¼šå¤´åƒæ¡†ID


ø

ø

ø

ù""æ‰“å¼€æèµ 


ù

ù

ù!
"
ü € å…¬ä¼šå•†åº—ä¿¡æ¯


ü

 ı	"
å…¬ä¼šuid


 ı	

 ı

 ı
!
ş	4"å•†åº—ç‰©å“ä¿¡æ¯


ş	 

ş!/

ş23
!
ÿ	%"ä¸Šæ¬¡åˆ·æ–°æ—¶é—´


ÿ	

ÿ 

ÿ#$
"
ƒ † å…¬ä¼šèƒŒåŒ…ä¿¡æ¯


ƒ

 „	"
å…¬ä¼šuid


 „	

 „

 „
H
…	#":å…¬ä¼šä»“åº“ï¼ˆåŒ…å«è´§å¸ã€æ™®é€šç‰©å“ã€çš®è‚¤ç­‰ï¼‰


…	

…

…!"
"
‰  å…¬ä¼šè®°å½•åˆ—è¡¨


‰

 ‹"
å…¬ä¼šuid


 ‹

 ‹

 ‹

Œ3"è®°å½•åˆ—è¡¨


Œ

Œ"

Œ#.

Œ12
D
 ”6 ç©å®¶çš„å…¬ä¼šæ•°æ® ç™»å½•æˆåŠŸä¹‹åè¯·æ±‚è¿”å›


 

 ’! å…¬ä¼šä¿¡æ¯


 ’

 ’

 ’ 
$
“."ç©å®¶è‡ªå·±çš„ä¿¡æ¯


“

“)

“,-
$
˜ ç©å®¶è¢«é‚€è¯·è®°å½•


˜

 š

 š	

 š


 š

›

›


›

›

œ2

œ

œ-

œ01
$
  £ç©å®¶è¢«é‚€è¯·åˆ—è¡¨


 

 ¢2

 ¢

 ¢$

 ¢&-

 ¢01
$
¥ ©å‘æ”¾æˆ˜åˆ©å“é“å…·


¥
n
 §"` é“å…·IDä¸ºé…ç½®æ–‡ä»¶ä¸­çš„ID ä½¿ç”¨åˆ†æ®µæ¥åŒºåˆ†é“å…·ç±»å‹ [è´§å¸/æ™®é€šé“å…·/çš®è‚¤]


 §	

 §


 §

¨

¨	

¨


¨
$
« ®æˆ˜åˆ©å“å‘æ”¾åˆ—è¡¨


«

 ­-

 ­

 ­

 ­(

 ­+,

² ¶

²

 ´

 ´

 ´

 ´

µ

µ

µ

µ

¸ »

¸
'
 º0"å·²ç”³è¯·çš„å…¬ä¼šåˆ—è¡¨


 º

 º 

 º!+

 º./
0
Á È" GMå‘½ä»¤æ›´æ–°å…¬ä¼šèƒŒåŒ…æ•°æ®


Á
5
 Å åè®®æ•°æ®
 å…¬ä¼šè®°å½•
"	å…¬ä¼šID


 Å

 Å

 Å
!
Æ"æ·»åŠ ç‰©å“åˆ—è¡¨


Æ

Æ

Æ
'
Ç"åŠ æ“ä½œè¿˜æ˜¯å‡æ“ä½œ


Ç

Ç

Ç
"
 Ë Ğ æ·»åŠ å…¬ä¼šç‰©å“


 Ë
?
  Ï åè®®æ•°æ®
 å…¬ä¼šè®°å½•
"æ·»åŠ ç‰©å“åˆ—è¡¨


  Ï

  Ï

  Ï
"
!Ó Ø åˆ é™¤å…¬ä¼šç‰©å“


!Ó
?
! × åè®®æ•°æ®
 å…¬ä¼šè®°å½•
"æ·»åŠ ç‰©å“åˆ—è¡¨


! ×

! ×

! ×
1
"Ü á# æ›´æ–°è‡ªå·±çš„å…¬ä¼šç©å®¶æ•°æ®


"Ü%
H
" à( åè®®æ•°æ®
 å…¬ä¼šè®°å½•
"è‡ªå·±çš„æœ€æ–°å…¬ä¼šæ•°æ®


" à

" à#

" à&'
"
#ä é æ›´æ–°å…¬ä¼šä»“åº“


#ä 
H
# è åè®®æ•°æ®
 å…¬ä¼šè®°å½•
"å˜åŒ–çš„ä»“åº“ç‰©å“åˆ—è¡¨


# è

# è

# è
"
$ì ñ æ›´æ–°å…¬ä¼šç­‰çº§


$ì"
9
$ ğ åè®®æ•°æ®
 å…¬ä¼šè®°å½•
"æœ€æ–°ç­‰çº§


$ ğ

$ ğ

$ ğ
0
%ô ø"æå‡å…¬ä¼šæœ€å¤§äººæ•°çš„è¯·æ±‚


%ô*

% ÷ åè®®æ•°æ®


% ÷

% ÷

% ÷
0
&û "æå‡å…¬ä¼šæœ€å¤§äººæ•°çš„è¿”å›


&û*
-
& ÿ" åè®®æ•°æ®
 ç©å®¶çš„æ•°æ®


& ÿ	

& ÿ


& ÿ !
+
&€"1æˆåŠŸ 0æç¤ºçµå¸ä¸è¶³ 


&€

&€

&€
!
'„ Šå…¬ä¼šæèµ è¯·æ±‚


'„

' ‡ åè®®æ•°æ®


' ‡

' ‡

' ‡
-
'ˆ"æèµ æ•°é‡ï¼ˆåªèƒ½çµçŸ³ï¼‰


'ˆ

'ˆ

'ˆ
R
'‰"Dæ³¨æ„è¿™ä¸ªå€¼å¦‚æœä¸ä¸º0å°±æ˜¯æçµçŸ³ï¼Œå¦åˆ™å°±æ˜¯æˆ˜åˆ©å“


'‰

'‰

'‰
!
( “å…¬ä¼šæèµ è¿”å›


(
N
( ‘ åè®®æ•°æ®
 ç©å®¶çš„æ•°æ®
"æèµ æ•°é‡ï¼ˆåªèƒ½çµçŸ³ï¼‰


( ‘

( ‘

( ‘
R
(’"Dæ³¨æ„è¿™ä¸ªå€¼å¦‚æœä¸ä¸º0å°±æ˜¯æçµçŸ³ï¼Œå¦åˆ™å°±æ˜¯æˆ˜åˆ©å“


(’

(’

(’
$
)— ›æˆ˜é˜Ÿé¢†å·¥èµ„è¯·æ±‚


)—

) š åè®®æ•°æ®


) š

) š

) š
$
* £æˆ˜é˜Ÿé¢†å·¥èµ„è¿”å›


*
K
* ¢ åè®®æ•°æ®
 ç©å®¶çš„æ•°æ®
"è·å¾—çš„ç‰©å“ï¼ˆåˆ—è¡¨ï¼‰


* ¢

* ¢

* ¢
A
+¨ ­3 æ›´æ–°å…¬ä¼šèŒä½åˆ—è¡¨ä¿¡æ¯ï¼ˆå»¶è¿Ÿ5~10ç§’ï¼‰


+¨ 
9
+ ¬& åè®®æ•°æ®
 å…¬ä¼šè®°å½•
"èŒä½åˆ—è¡¨


+ ¬

+ ¬!

+ ¬$%

± ¶æ›´æ–°æ“ä½œ


±

 ³

 ³

 ³

´

´

´

µ

µ

µ
(
,º ¿ æ›´æ–°å…¬ä¼šè®°å½•ä¿¡æ¯


,º'
*
, ¾$ åè®®æ•°æ®
 å…¬ä¼šè®°å½•


, ¾

, ¾

, ¾"#
'
-Ã Êè·å–å…¬ä¼šæˆå‘˜è¯·æ±‚


-Ã
>
- È0 åè®®æ•°æ®
 åˆ†é¡µç´¢å¼•ï¼Œä¸€é¡µé»˜è®¤50ä¸ª


- È	

- È


- È

-É

-É

-É

-É
0
.Í Ô"è·å–å…¬ä¼šæˆå‘˜è¯·æ±‚çš„è¿”å›


.Í
<
. Ñ åè®®æ•°æ®
 ç©å®¶çš„æ•°æ®
"åˆ†é¡µç´¢å¼•


. Ñ

. Ñ

. Ñ

.Ò"æˆå‘˜æ€»æ•°


.Ò

.Ò

.Ò

.Ó"

.Ó

.Ó

.Ó !
6
/× Û(å¹¿æ’­å…¨å…¬ä¼šï¼Œé€šçŸ¥æœ‰ç©å®¶ç”³è¯·


/×&
1
/ Ú åè®®æ•°æ®
"ç”³è¯·æ¶ˆæ¯æ•°é‡


/ Ú	

/ Ú


/ Ú
<
0ß å.å¹¿æ’­å…¨å…¬ä¼šï¼Œé€šçŸ¥æœ‰ç©å®¶åŠ å…¥å…¬ä¼š


0ß%
-
0 ã" åè®®æ•°æ®
 ç©å®¶çš„æ•°æ®


0 ã

0 ã

0 ã !

0ä"	å…¬ä¼šID


0ä

0ä

0ä
<
1é ï.å¹¿æ’­å…¨å…¬ä¼šï¼Œé€šçŸ¥æœ‰ç©å®¶é€€å‡ºå…¬ä¼š


1é%
*
1 í åè®®æ•°æ®
 å…¬ä¼šè®°å½•


1 í	

1 í


1 í

1î"	å…¬ä¼šID


1î

1î

1î
3
2ò ÷%å¹¿æ’­å…¨å…¬ä¼šï¼Œé€šçŸ¥å…¬ä¼šè§£æ•£


2ò'
5
2 ö åè®®æ•°æ®
 å…¬ä¼šè®°å½•
"	å…¬ä¼šID


2 ö

2 ö

2 ö
(
3û  æ›´æ–°å…¬ä¼šè®°å½•ä¿¡æ¯


3û(
*
3 ÿ+ åè®®æ•°æ®
 å…¬ä¼šè®°å½•


3 ÿ

3 ÿ&

3 ÿ)*
$
3€"ç”³è¯·è¿˜æ˜¯å–æ¶ˆï¼Ÿ


3€

3€

3€
8
4† Œ* ç™»å½•è¯·æ±‚è‡ªå·±çš„å…¬ä¼šæ•°æ® è¿”å›


4† 
?
4 ‹+1 åè®®æ•°æ®
 ç™»å½•ä¹‹åçš„æˆåŠŸè¿”å›æ•°æ®


4 ‹

4 ‹&

4 ‹)*
Q
5‘ ™Cè®¾ç½®ç©å®¶çš„å…¬ä¼šä¿¡æ¯åˆ°ç©å®¶å¯¹è±¡ä¸Šï¼Œç”¨äºå¿«æ·è®¿é—®


5‘$
3
5 ” åè®®æ•°æ®
"å…¬ä¼šæ‰€åœ¨èŠ‚ç‚¹ID


5 ”

5 ”

5 ”

5•"	å…¬ä¼šid


5•

5•

5•

5–"å…¬ä¼šname


5–

5–

5–

5—"å…¬ä¼šç­‰çº§


5—

5—

5—

5˜#"å…¬ä¼šç¹è£åº¦


5˜

5˜

5˜!"
!
6 ¬è·å–å…¬ä¼šåˆ—è¡¨


6!

6 ¡ åè®®æ•°æ®


6 ¡

6 ¡

6 ¡

6¢

6¢

6¢

6¢

6£"æ’åºç±»å‹ã€‚1


6£

6£

6£

6¤"æ˜¯å¦å‡åº


6¤

6¤

6¤

6¥"æœ€ä½ç­‰çº§


6¥

6¥

6¥

6¦"æœ€é«˜ç­‰çº§


6¦

6¦

6¦

6§"æœ€ä½äººæ•°


6§	

6§


6§

6¨"æœ€é«˜äººæ•°


6¨	

6¨


6¨
*
6©"å›ºå®šæ¯é¡µå¤šå°‘æ¡è®°å½•


6©	

6©


6©
$
6	ª"åªæœç´¢æ¨èåˆ—è¡¨


6	ª

6	ª

6	ª
.
6
«" åªæœç´¢å¯ä»¥åŠ å…¥çš„å…¬ä¼š	


6
«

6
«

6
«
'
7¯ ¾è·å–å…¬ä¼šåˆ—è¡¨è¿”å›


7¯!
+
7 ³% åè®®æ•°æ®
"å…¬ä¼šåˆ—è¡¨


7 ³

7 ³ 

7 ³#$

7´"æ’åºç±»å‹ã€‚1


7´

7´

7´

7µ"æ˜¯å¦å‡åº


7µ

7µ

7µ

7¶"æœ€ä½ç­‰çº§


7¶

7¶

7¶

7·"æœ€é«˜ç­‰çº§


7·

7·

7·

7¸"æœ€ä½äººæ•°


7¸	

7¸


7¸

7¹"æœ€é«˜äººæ•°


7¹	

7¹


7¹

7º"æ€»äººæ•°	


7º	

7º


7º
+
7»"å›ºå®šæ¯é¡µå¤šå°‘æ¡è®°å½•	


7»

7»

7»
$
7	¼"åªæœç´¢æ¨èåˆ—è¡¨


7	¼

7	¼

7	¼
.
7
½" åªæœç´¢å¯ä»¥åŠ å…¥çš„å…¬ä¼š	


7
½

7
½

7
½
!
8Â Çåˆ›å»ºå…¬ä¼šè¯·æ±‚


8Â 

8 Å åè®®æ•°æ®


8 Å

8 Å

8 Å

8Æ"
å…¬ä¼šå


8Æ

8Æ

8Æ
!
9Ê Ïåˆ›å»ºå…¬ä¼šè¿”å›


9Ê 

9 Ì"
é”™è¯¯ç 


9 Ì	

9 Ì


9 Ì

9Í"	å…¬ä¼šid


9Í

9Í

9Í

9Î"
å…¬ä¼šå


9Î	

9Î


9Î
!
:Ó Úç”³è¯·åŠ å…¥è¯·æ±‚


:Ó#
'
: Ö åè®®æ•°æ®
"	å…¬ä¼šid


: Ö	

: Ö


: Ö

:×

:×

:×

:×
2
:Ø"$æ˜¯å¦ç”³è¯·ã€‚falseä¸ºå–æ¶ˆç”³è¯·


:Ø

:Ø

:Ø

:Ù"ç”³è¯·äººuid


:Ù

:Ù

:Ù
!
;İ âç”³è¯·åŠ å…¥è¿”å›


;İ#

; ß"
é”™è¯¯ç 


; ß	

; ß


; ß

;à"	å…¬ä¼šid


;à	

;à


;à

;á"
å…¬ä¼šå


;á

;á

;á
'
<å ëå›å¤ç”³è¯·åŠ å…¥è¯·æ±‚


<å)
+
< è åè®®æ•°æ®
"ç”³è¯·äººuid


< è	

< è


< è

<é"æ˜¯å¦åŒæ„


<é

<é

<é

<ê

<ê

<ê

<ê
'
=î óå›å¤ç”³è¯·åŠ å…¥è¿”å›


=î)
+
= ñ åè®®æ•°æ®
"ç”³è¯·äººuid


= ñ	

= ñ


= ñ

=ò"æ˜¯å¦åŒæ„


=ò

=ò

=ò

>÷ üæœç´¢å…¬ä¼š


>÷ 

> ú åè®®æ•°æ®


> ú	

> ú


> ú

>û

>û

>û

>û
!
?ÿ ƒæœç´¢å…¬ä¼šè¿”å›


?ÿ 
1
? ‚' åè®®æ•°æ®
"å…¬ä¼šç®€ç•¥ä¿¡æ¯


? ‚

? ‚#

? ‚%&
!
@‡ é‚€è¯·åŠ å…¥å…¬ä¼š


@‡$

@ Š åè®®æ•°æ®


@ Š	

@ Š


@ Š
5
@‹"'è¢«é‚€è¯·äººçš„åç§°ã€uidæˆ–steam_id


@‹

@‹

@‹

@Œ "è¢«é‚€è¯·äººuid


@Œ

@Œ

@Œ
'
A ”é‚€è¯·åŠ å…¥å…¬ä¼šè¿”å›


A$
.
A “ åè®®æ•°æ®
"è¢«é‚€è¯·äººuid


A “

A “

A “
'
B˜ Ÿå›å¤é‚€è¯·åŠ å…¥å…¬ä¼š


B˜*
+
B › åè®®æ•°æ®
"é‚€è¯·äººuid


B ›

B ›

B ›

Bœ"æ˜¯å¦åŒæ„


Bœ

Bœ

Bœ

B"å›å¤äººuid


B

B

B

B"å›å¤äººuid


B

B

B

C£ ¦é€€å‡ºå…¬ä¼š


C£

C ¥

C ¥

C ¥

C ¥
!
D© ¬é€€å‡ºå…¬ä¼šè¿”å›


D©

D «

D «

D «

D «

E° µè¸¢å‡ºå…¬ä¼š


E°
.
E ³ åè®®æ•°æ®
"è¢«è¸¢ç©å®¶uid


E ³

E ³

E ³

E´

E´

E´

E´
!
F¸ ¼è¸¢å‡ºå…¬ä¼šè¿”å›


F¸

F º

F º	

F º


F º

F»"è¢«è¸¢ç©å®¶uid


F»

F»

F»
!
GÀ Æå…¬ä¼šæˆäºˆèŒä½


GÀ
.
G Ã åè®®æ•°æ®
"ç›®æ ‡ç©å®¶uid


G Ã

G Ã

G Ã

GÄ"	èŒåŠ¡ID


GÄ

GÄ

GÄ

GÅ

GÅ

GÅ

GÅ
(
HÉ Î å…¬ä¼šæˆäºˆèŒä½è¿”å›


HÉ
.
H Ì åè®®æ•°æ®
"ç›®æ ‡ç©å®¶uid


H Ì

H Ì

H Ì

HÍ"	èŒåŠ¡ID


HÍ

HÍ

HÍ
"
IÓ Ø å…¬ä¼šè½¬è®©èŒä½


IÓ
.
I Ö åè®®æ•°æ®
"ç›®æ ‡ç©å®¶uid


I Ö

I Ö

I Ö

I×

I×

I×

I×
"
JÛ à å…¬ä¼šè½¬è®©è¿”å›


JÛ
*
J Ş! åè®®æ•°æ®
"æ–°ä¼šé•¿ID


J Ş

J Ş

J Ş 

Jß#"æ–°ä¼šé•¿åç§°


Jß

Jß

Jß!"

Kå éå…¬ä¼šè§£æ•£


Kå

K è åè®®æ•°æ®


K è

K è

K è
!
Lì ïå…¬ä¼šè§£æ•£è¿”å›


Lì

Mô ÷å…¬ä¼šè§£å†»


Mô

M ö

M ö

M ö

M ö
!
Nú ıå…¬ä¼šè§£å†»è¿”å›


Nú
!
O€ …å…¬ä¼šä¿®æ”¹å…¬å‘Š


O€'

O ƒ# åè®®æ•°æ®


O ƒ

O ƒ

O ƒ!"

O„

O„

O„

O„
'
Pˆ å…¬ä¼šä¿®æ”¹å…¬å‘Šè¿”å›


Pˆ'

P ‹# åè®®æ•°æ®


P ‹

P ‹

P ‹!"

PŒ

PŒ

PŒ

PŒ
!
Q •å…¬ä¼šå¢åŠ èŒä½


Q
+
Q “ åè®®æ•°æ®
"èŒä½åç§°


Q “

Q “

Q “

Q”

Q”

Q”

Q”
'
R˜ å…¬ä¼šå¢åŠ èŒä½è¿”å›


R˜
*
R › åè®®æ•°æ®
"æ–°èŒä½ID


R ›

R ›

R ›

Rœ"èŒä½åç§°


Rœ

Rœ

Rœ
'
S  ¥åˆ é™¤å…¬ä¼šèŒä½è¯·æ±‚


S 

S £ åè®®æ•°æ®


S £	

S £


S £

S¤

S¤

S¤

S¤
*
T¨ ­åˆ é™¤å…¬ä¼šèŒä½çš„è¿”å›


T¨
-
T ¬ åè®®æ•°æ®
 ç©å®¶çš„æ•°æ®


T ¬	

T ¬


T ¬
'
U° ·å…¬ä¼šä¿®æ”¹èŒä½æƒé™


U°$

U ³ åè®®æ•°æ®


U ³	

U ³


U ³

U´"	èŒä½ID


U´

U´

U´
'
Uµ"æ–°å¢æˆ–åˆ é™¤çš„æƒé™


Uµ

Uµ

Uµ
-
U¶"trueä¸ºè®¾ç½®ï¼Œfalseä¸ºå–æ¶ˆ


U¶

U¶

U¶
-
Vº ¿å…¬ä¼šä¿®æ”¹æˆå‘˜æƒé™è¿”å›


Vº$
'
V ½ åè®®æ•°æ®
"	èŒä½ID


V ½

V ½

V ½

V¾"æœ€æ–°çš„æƒé™


V¾

V¾

V¾
'
WÃ Éä¿®æ”¹å…¬ä¼šèŒä½åç§°


WÃ#

W Æ åè®®æ•°æ®


W Æ

W Æ

W Æ

WÇ

WÇ	

WÇ


WÇ

WÈ

WÈ

WÈ

WÈ
0
XÌ Ñ"ä¿®æ”¹å…¬ä¼šèŒä½åç§°DE è¿”å›


XÌ#

X Ï åè®®æ•°æ®


X Ï

X Ï

X Ï

XĞ

XĞ	

XĞ


XĞ
'
YÕ Ûä¿®æ”¹å…¬ä¼šèŒä½ç­‰çº§


YÕ$

Y Ø åè®®æ•°æ®


Y Ø

Y Ø

Y Ø

YÙ

YÙ	

YÙ


YÙ

YÚ

YÚ

YÚ

YÚ
0
ZŞ ã"ä¿®æ”¹å…¬ä¼šèŒä½ç­‰çº§DE è¿”å›


ZŞ$

Z á åè®®æ•°æ®


Z á

Z á

Z á

Zâ

Zâ	

Zâ


Zâ

[æ éå…¬ä¼šå‡çº§


[æ

[ è

[ è

[ è

[ è
!
\ì ğå…¬ä¼šå‡çº§è¿”å›


\ì
(
\ ï åè®®æ•°æ®
"
æ–°ç­‰çº§


\ ï

\ ï

\ ï
!
]õ ûå…¬ä¼šå¤´åƒä¿®æ”¹


]õ#

] ù åè®®æ•°æ®


] ù

] ù

] ù

]ú

]ú

]ú

]ú
'
^ş ‚å…¬ä¼šå¤´åƒä¿®æ”¹è¿”å›


^ş#

^  åè®®æ•°æ®


^ 

^ 

^ 
!
_† Šè·å–ç”³è¯·åˆ—è¡¨


_†!

_ ‰ åè®®æ•°æ®


_ ‰

_ ‰

_ ‰
'
` ’è·å–ç”³è¯·åˆ—è¡¨è¿”å›


`!

` , åè®®æ•°æ®


` 

` '

` *+

`‘"æ€»ç”³è¯·æ•°


`‘

`‘

`‘
!
a– ›ä¿®æ”¹å…¬ä¼šåç§°


a–$

a ™ åè®®æ•°æ®


a ™

a ™

a ™

aš

aš

aš

aš
'
bŸ ¤ä¿®æ”¹å…¬ä¼šåç§°è¿”å›


bŸ$

b ¢ åè®®æ•°æ®


b ¢

b ¢

b ¢

b£

b£

b£

b£

c§ ­ç‰©å“å…‘æ¢


c§!

c ª åè®®æ•°æ®


c ª	

c ª


c ª

c«"å…‘æ¢ç‰©å“ID


c«

c«

c«
!
c¬"å…‘æ¢ç‰©å“æ•°é‡


c¬

c¬

c¬
!
d± ¶ç‰©å“å…‘æ¢è¿”å›


d±!
-
d ´ åè®®æ•°æ®
"å…‘æ¢ç‰©å“ID


d ´

d ´

d ´
!
dµ"å…‘æ¢ç‰©å“æ•°é‡


dµ

dµ

dµ

eº ¿æ¥å—ä»»åŠ¡


eº

e ½ åè®®æ•°æ®


e ½	

e ½


e ½

e¾"	ä»»åŠ¡ID


e¾

e¾

e¾
!
fÃ Çæ¥å—ä»»åŠ¡è¿”å›


fÃ
'
f Æ åè®®æ•°æ®
"	ä»»åŠ¡ID


f Æ

f Æ

f Æ
!
gË Ğé¢†å–ä»»åŠ¡å¥–åŠ±


gË"

g Î åè®®æ•°æ®


g Î	

g Î


g Î

gÏ"	ä»»åŠ¡ID


gÏ

gÏ

gÏ
'
hÔ Ùé¢†å–ä»»åŠ¡å¥–åŠ±è¿”å›


hÔ"
'
h × åè®®æ•°æ®
"	ä»»åŠ¡ID


h ×

h ×

h ×
!
hØ*"ä»»åŠ¡å¥–åŠ±ä¿¡æ¯


hØ

hØ%

hØ()
!
iÜ àæ›´æ–°ä»»åŠ¡çŠ¶æ€


iÜ#
1
i ß& åè®®æ•°æ®
"ä»»åŠ¡å¥–åŠ±ä¿¡æ¯


i ß

i ß!

i ß$%
!
jã çæ›´æ–°ä»»åŠ¡åˆ—è¡¨


jã#

j æ" åè®®æ•°æ®


j æ

j æ

j æ !
!
kê îæ›´æ–°æˆå‘˜åˆ—è¡¨


kê$

k í, åè®®æ•°æ®


k í

k í'

k í*+
'
lñ öè®¾ç½®åŠ å…¥å…¬ä¼šæ¡ä»¶


lñ%

l ô åè®®æ•°æ®


l ô

l ô

l ô

lõ

lõ

lõ

lõ
-
mø ûè®¾ç½®åŠ å…¥å…¬ä¼šæ¡ä»¶è¿”å›


mø%

m ú

m ú

m ú

m ú
4
nş ƒ& æ›´æ–°ç©å®¶å…¬ä¼šé‚€è¯·åŠ å…¥è®°å½•


nş)
0
n ‚)" åè®®æ•°æ®
 é‚€è¯·è®°å½•è®°å½•


n ‚

n ‚$

n ‚'(
"
o‡ “ æ‹‰å–å…¬ä¼šè®°å½•


o‡
.
o ‹ åè®®æ•°æ®
 å…¬ä¼šè®°å½•
"1


o ‹

o ‹

o ‹

oŒ"


oŒ	

oŒ


oŒ

o

o

o

o
?
o"1æ’åºç±»å‹ã€‚1æŒ‰è®°å½•æ—¶é—´ 2æŒ‰ç©å®¶æ˜µç§°


o

o

o

o"æ˜¯å¦å‡åº


o

o

o

o

o

o

o
E
o‘"7åˆ¶å®šç”¨æˆ·è®°å½• å¦‚æœdes_uid=0,æŸ¥è¯¢æ‰€æœ‰ç©å®¶	


o‘	

o‘


o‘
+
o’"å›ºå®šæ¯é¡µå¤šå°‘æ¡è®°å½•	


o’

o’

o’
(
p• ¡ æ‹‰å–å…¬ä¼šè®°å½•è¿”å›


p•
-
p ™ åè®®æ•°æ®
 å…¬ä¼šè®°å½•
"


p ™

p ™

p ™

pš"


pš	

pš


pš

p›

p›

p›

p›

pœ"æ’åºç±»å‹ã€‚1


pœ

pœ

pœ

p"æ˜¯å¦å‡åº


p

p

p

p(

p

p#

p&'

pŸ"æ€»è®°å½•æ¡æ•°


pŸ

pŸ

pŸ
+
p "å›ºå®šæ¯é¡µå¤šå°‘æ¡è®°å½•	


p 

p 

p 
(
q¤ ª è®¾ç½®æˆ˜åˆ©å“ç®¡ç†å‘˜


q¤!

q § åè®®æ•°æ®


q §

q §

q §
*
q¨"trueä»»å‘½ï¼Œfalseä¸ºå–æ¶ˆ


q¨

q¨

q¨

q©"
ç›®æ ‡uid


q©

q©

q©
.
r¬ ²  è®¾ç½®æˆ˜åˆ©å“ç®¡ç†å‘˜è¿”å›


r¬!
5
r ¯ åè®®æ•°æ®
"æˆåŠŸtrue,å¤±è´¥false


r ¯

r ¯

r ¯
*
r°"trueä»»å‘½ï¼Œfalseä¸ºå–æ¶ˆ


r°

r°	

r°

r±"ç›®æ ‡uid	


r±

r±

r±
*
sµ ¼ç®¡ç†å‘˜è®¾ç½®æˆå‘˜dkpå€¼


sµ	

s ¸ åè®®æ•°æ®


s ¸

s ¸

s ¸

s¹"ä¿®æ”¹çš„å€¼


s¹	

s¹

s¹

sº"
ç›®æ ‡uid


sº

sº

sº

s»"å¤‡æ³¨	


s»


s»

s»

t½ Ä

t½
+
t À åè®®æ•°æ®
"ä¿®æ”¹çš„å€¼


t À	

t À

t À

tÁ"
ç›®æ ‡uid


tÁ

tÁ

tÁ

tÂ"å½“å‰dkpçš„å€¼


tÂ

tÂ

tÂ

tÃ"å¤‡æ³¨


tÃ

tÃ

tÃ

uÅ Ë

uÅ

u È åè®®æ•°æ®


u È	

u È

u È

uÉ"
ç›®æ ‡uid


uÉ

uÉ

uÉ

uÊ&"å‘é€çš„ç‰©å“


uÊ

uÊ#

uÊ$%

vÌ Ğ

vÌ

v Ï åè®®æ•°æ®


v Ï

v Ï	

v Ï

wÑ Ö

wÑ

w Ô åè®®æ•°æ®


w Ô

w Ô

w Ô

wÕ"æ‰€åœ¨æ ‡ç­¾é¡µ


wÕ

wÕ

wÕ

x× Ü

x× 
.
x Ú åè®®æ•°æ®
"æ‰€åœ¨æ ‡ç­¾é¡µ


x Ú

x Ú

x Ú

xÛ."ç‰©å“åˆ—è¡¨


xÛ

xÛ )

xÛ,-

yİ ä

yİ 

y à åè®®æ•°æ®


y à

y à

y à

yá"æ‰€åœ¨æ ‡ç­¾é¡µ


yá

yá

yá

yâ"å•†åº—ç‰©å“id


yâ

yâ

yâ

yã"ç‰©å“æ•°é‡


yã

yã

yã

zå ì

zå 
.
z è åè®®æ•°æ®
"æ‰€åœ¨æ ‡ç­¾é¡µ


z è

z è

z è

zé"å•†åº—ç‰©å“id


zé

zé

zé

zê"ç‰©å“æ•°é‡


zê

zê

zê

zë"æ˜¯å¦æˆåŠŸ 


zë

zë

zë
.
{ğ ö  å…¬ä¼šæ—¥å¸¸ä»»åŠ¡å¥–åŠ±é¢†å–


{ğ$
5
{ ó' ä¸€é”®é¢†å– è¿˜æ˜¯æŒ‰ç…§ç§¯åˆ†é¢†å–


{ ó

{ ó

{ ó

{ô 

{ô

{ô

{ô

{õ%

{õ	

{õ

{õ#$
4
|ù ÿ& å…¬ä¼šæ—¥å¸¸ä»»åŠ¡å¥–åŠ±é¢†å–è¿”å›


|ù$

| ü  é¢†å–è¿”å›


| ü	

| ü

| ü

|ı 

|ı

|ı

|ı

|ş%

|ş

|ş

|ş#$

}‚	 †	 è´­ä¹°æ¨èä½


}‚	!

} …	

} …	

} …	

} …	
%
~ˆ	 	 è´­ä¹°æ¨èä½è¿”å›


~ˆ	!

~ Š	

~ Š	

~ Š	

~ Š	

~‹	"æ˜¯å¦æˆåŠŸ


~‹	

~‹	

~‹	
$
~Œ	$"æ¨èä½åˆ°æœŸæ—¶é—´


~Œ	

~Œ	

~Œ	"#

	 ”	

	

 ‘	

 ‘	

 ‘	

 ‘	

’	

’	

’	

’	

“	

“	

“	

“	

€–	 š	

€–	

€ ˜	

€ ˜	

€ ˜	

€ ˜	

€™	

€™	

€™	

€™	
+
	 ¡	 GMå‘½ä»¤è®¾ç½®å…¬ä¼šçŠ¶æ€


	

 Ÿ	"	å…¬ä¼šID


 Ÿ	

 Ÿ	

 Ÿ	

 	"çŠ¶æ€


 	

 	

 	
%
‚¤	 ©	 GMå‘½ä»¤å¼€å…³æèµ 


‚¤	

‚ §	"	å…¬ä¼šID


‚ §	

‚ §	

‚ §	
"
‚¨	"æ˜¯å¦å¼€å¯æèµ 


‚¨	

‚¨	

‚¨	bproto3