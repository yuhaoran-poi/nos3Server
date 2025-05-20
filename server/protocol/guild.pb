
Œ¸

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
max_durability (RmaxDurability"”
PBMagicItem%
cur_durability (RcurDurability%
max_durability (RmaxDurability
	light_cnt (RlightCnt
tags (2.PBTagRtags"—
PBDiagramsCard%
cur_durability (RcurDurability%
max_durability (RmaxDurability
	light_cnt (RlightCnt
tags (2.PBTagRtags"B
	PBAweItem
idx (Ridx#
up_lv_fail_cnt (RupLvFailCnt"º
	PBAntique
price (2.PBCoinRprice.
remain_identify_num (RremainIdentifyNum
tags (2.PBTagRtags
is_fake (RisFake)
identify_histroy (RidentifyHistroy"œ
PBItemCommon
	config_id (RconfigId
uniqid (Runiqid

item_count (R	itemCount
	item_type (RitemType
	trade_cnt (RtradeCnt"õ
PBItemSpecial+

durab_item (2.PBDurabItemR	durabItem+

magic_item (2.PBMagicItemR	magicItem4
diagrams_item (2.PBDiagramsCardRdiagramsItem%
awe_item (2
.PBAweItemRaweItem-
antique_item (2
.PBAntiqueRantiqueItem"…

PBItemData
itype (Ritype.
common_info (2.PBItemCommonR
commonInfo1
special_info (2.PBItemSpecialRspecialInfo"b
PBItemSimple
	config_id (RconfigId

item_count (R	itemCount
uniqid (Runiqid"€
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
played_gods_data (2.PBPlayedGodsDataSRplayedGodsData"·
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
	all_stars (RallStars"Ë
PBRankLevel*

ghost_rank (2.PBRankNodeR	ghostRank*

human_rank (2.PBRankNodeR	humanRank1
ghost_top_rank (2.PBRankNodeRghostTopRank1
human_top_rank (2.PBRankNodeRhumanTopRank"4
PBPinchFaceData!
setting_data (	RsettingData"ª
PBSimpleRoleData
	config_id (RconfigId2
skins (2.PBSimpleRoleData.SkinsEntryRskinsE

SkinsEntry
key (Rkey!
value (2.PBItemDataRvalue:8"¶

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
value (2.PBSkillRvalue:8"¾
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
value (2.PBItemDataRvalue:8"
PBGhostImage
	config_id (RconfigId

star_level (R	starLevel
exp (Rexp
cur_skin_id (R	curSkinId 
skin_id_list (R
skinIdList"š
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
value (2.PBGhostImageRvalue:8"€
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
exp (Rexp"ü
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
value (2.PBImageRvalue:8"ô
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
uid (Ruid"€
PBClientGetUsrSimInfoRspCmd
code (Rcode
error (	Rerror
uid (Ruid%
info (2.PBUserSimpleInfoRinfo"0
PBClientGetUsrBagsInfoReqCmd
uid (Ruid"€
PBClientGetUsrBagsInfoRspCmd
code (Rcode
error (	Rerror
uid (Ruid$
	bags_info (2.PBBagsRbagsInfo"¶
PBClientLightReqCmd
uid (Ruid
roleid (Rroleid
ghostid (Rghostid
bagid (Rbagid
pos (Rpos
	config_id (RconfigId
uniqid (Runiqid"à
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
add_exp (RaddExp"¨
PBClientMagicItemUpLvRspCmd
code (Rcode
error (	Rerror
uid (Ruid
	config_id (RconfigId
add_exp (RaddExp
now_exp (RnowExpJ†v
  ‘

  

   è´§å¸



 

  

  	

  

  

 

 	

 

 


	 


	

 ,

 

  

 *+

  èµç¦æ•°æ®





 

 

 

 









  é€šç”¨å±æ€§





 $

 

 

 "#

 







   é€šç”¨è¯æ¡





 

 

 

 









# ' é€šç”¨æŠ€èƒ½



#

 %,

 %

 %!

 %*+

&,

&

&

&*+
2
* .& æ‹¥æœ‰è€ä¹…åº¦çš„ä¸å¯å †å é“å…·



*

 ,#"å½“å‰è€ä¹…åº¦


 ,

 ,

 ,!"

-#"è€ä¹…åº¦ä¸Šé™


-

-

-!"

1 7 æ³•å™¨



1

 3+"å½“å‰è€ä¹…åº¦


 3

 3&

 3)*

4+"è€ä¹…åº¦ä¸Šé™


4

4&

4)*

5,

5

5!

5*+
(
6$"éšæœºè¯æ¡id,æœ€å¤§10æ¡


6

6

6

6"#

: @ å…«å¦ç‰Œ



:

 <+"å½“å‰è€ä¹…åº¦


 <

 <&

 <)*

=+"è€ä¹…åº¦ä¸Šé™


=

=&

=)*

>,

>

>!

>*+
(
?$"éšæœºè¯æ¡id,æœ€å¤§10æ¡


?

?

?

?"#

	C G é•‡å±±ä¹‹å®



	C

	 E4

	 E

	 E

	 E23
-
	F$"  å½“å‰ç­‰çº§å‡çº§å¤±è´¥æ¬¡æ•°


	F

	F

	F"#


J Q å¤è‘£




J


 L"" ä»·æ ¼



 L


 L


 L !
!

M0" å‰©ä½™é‰´å®šæ¬¡æ•°



M


M+


M./
'

N!" è¯æ¡æ•°é‡,æœ€å¤§10ä¸ª



N


N


N


N 


O$


O


O


O"#
!

P-" å†å²é‰´å®šç»“æœ



P


P


P(


P+,
 
T [ é€šç”¨é“å…·æ•°æ®



T

 V$

 V	

 V

 V"#

W,

W

W

W*+

X$

X	

X

X"#

Y,"é“å…·ç±»å‹


Y

Y!

Y*+

Z,"å¯äº¤æ˜“æ¬¡æ•°


Z

Z!

Z*+
 
^ e ç‰¹æ®Šé“å…·æ•°æ®



^

 `,

 `

 `"

 `*+

a$

a

a

a"#

b,

b

b%

b*+

c,

c

c 

c*+

d4

d

d$

d23


g l


g

 i

 i

 i

 i

j4

j

j#

j23

k,

k

k$

k*+
 
o t é“å…·ç®€åŒ–ä¿¡æ¯



o

 q,

 q

 q!

 q*+

r,

r

r"

r*+

s,

s

s

s*+
$
w † æ‹å–è¡Œé¢å¤–æ•°æ®



w

 y4"å‡çº§


 y

 y (

 y23

z4

z

z &

z23

{4"å‡æ˜Ÿ


{

{ *

{23

|4"é¢å¤–å±æ€§


|

|

| +

|23
%
~<æ³•å™¨
"å…ƒç´ è¯æ¡id


~

~

~(4

~:;

D"æ™®é€šè¯æ¡id






(,

BC

,é¬¼æ€ª
"é˜´å¯¿






*+

‚,"é˜´æ°”


‚

‚!

‚*+

ƒ4"é¬¼æ€ªæŠ€èƒ½


ƒ

ƒ

ƒ .

ƒ23
!
	„."è§£é”è£…å¤‡æ•°é‡


	„

	„(

	„+-


…-"æ€ªç‰©æ˜µç§°



…


…!


…*,

ˆ Œ

ˆ

 Š" æ§½ä½


 Š

 Š

 Š

‹"
 ç¥æ˜id


‹

‹

‹

 ‘



 7

 

 !

 "2

 56

” ˜ ç¥æ˜


”

 –." ç¥æ˜åˆ—è¡¨


 –

 –

 – )

 –,-
%
—=" å‡ºæˆ˜çš„ç¥æ˜æ•°æ®


—

—(8

—;<

š Ÿ

š

 œ$

 œ

 œ

 œ"#

$





"#

,



 %

*+

¡ ¤

¡

 £)

 £

 £ $

 £'(
a
§ ®S----------------------------------æ–°å¢åè®®----------------------------------//


§

 ¨ "å“é˜¶


 ¨

 ¨

 ¨

© "å“çº§


©

©

©
!
ª"å½“å‰æ˜Ÿæ˜Ÿæ•°é‡


ª

ª

ª

« "
éšè—åˆ†


«

«

«
9
¬("+ç­‘åŸºç‚¹ï¼ˆç”¨äºå‡æ˜Ÿæˆ–æŠµæ‰£æ˜Ÿæ˜Ÿï¼‰


¬

¬#

¬&'
i
­$"[æ‰€æœ‰æ˜Ÿæ˜Ÿæ•°ï¼ˆè®°å½•ç©å®¶æ‰€æœ‰çš„æ˜Ÿæ˜Ÿæ•°é‡ï¼Œç”¨äºæ¢ç®—å“é˜¶ã€å“çº§è¿™äº›ï¼‰


­

­

­"#

° ¸ æ®µä½


°

 ³"

 ³

 ³

 ³ !

´"

´

´

´ !
"
¶& å†å²æœ€é«˜æ®µä½


¶

¶!

¶$%

·&

·

·!

·$%
"
» ¾ æè„¸æ•°æ®å®šä¹‰


»

 ½

 ½


 ½

 ½
"
Á Å è§’è‰²ç®€ç•¥ä¿¡æ¯


Á

 Ã<"
 é…ç½®ID


 Ã	

 Ã


 Ã:;

Ä," ç©¿æˆ´çš®è‚¤


Ä

Ä 

Ä*+
"
È Ú è§’è‰²è¯¦ç»†æ•°æ®


È

 Ê,"	é…ç½®ID


 Ê

 Ê

 Ê*+

Ë,"æ˜Ÿçº§


Ë

Ë

Ë*+

Ì4"
ç»éªŒå€¼


Ì

Ì

Ì23

Í$"æ³•å™¨


Í

Í

Í"#

Î4"
å…«å¦ç‰Œ


Î

Î,

Î23

Ï4"å·²è£…å¤‡çœŸç»


Ï

Ï

Ï"

Ï23

Ğ4"å­¦ä¹ ä¸­çœŸç»


Ğ

Ğ

Ğ"

Ğ23

Ñ,"ç©¿æˆ´çš®è‚¤


Ñ

Ñ$

Ñ*+
 
Ò4"é€‰å®šä¸»æŠ€èƒ½id


Ò

Ò

Ò23

	Ó-"å¯é€‰ä¸»æŠ€èƒ½


	Ó

	Ó&

	Ó*,
!

Ô="é€‰å®šå°æŠ€èƒ½1id



Ô


Ô!


Ô:<

Õ5"å¯é€‰å°æŠ€èƒ½1


Õ

Õ(

Õ24
!
Ö="é€‰å®šå°æŠ€èƒ½2id


Ö

Ö!

Ö:<

×5"å¯é€‰å°æŠ€èƒ½2


×

×(

×24

Ø="è¢«åŠ¨æŠ€èƒ½


Ø

Ø

Ø:<

Ù="
è¡¨æƒ…æ§½


Ù

Ù

Ù

Ù:<

İ á è§’è‰²æ•°æ®


İ

 ß4

 ß

 ß

 ß23

à4

à

à(

à23
"
ä è é¬¼å® ç®€ç•¥ä¿¡æ¯


ä

 æ"
 é…ç½®ID


 æ	

 æ


 æ

ç" ç©¿æˆ´çš®è‚¤


ç

ç

ç
"
ë ö é¬¼å® è¯¦ç»†æ•°æ®


ë

 í,"	é…ç½®ID


 í

 í

 í*+

î,"	å”¯ä¸€ID


î

î

î*+

ï,"æ˜Ÿçº§


ï

ï

ï*+

ğ4"
ç»éªŒå€¼


ğ

ğ

ğ23

ñ4"
å…«å¦ç‰Œ


ñ

ñ,

ñ23

ò<"è¢«åŠ¨æŠ€èƒ½


ò

ò

ò'

ò:;

ó<"ä¸»åŠ¨æŠ€èƒ½


ó

ó

ó&

ó:;

ôD"å±æ€§


ô

ô

ô"

ôBC

õ,"æ€§æ ¼


õ

õ

õ*+

ù € é¬¼å® å›¾é‰´


ù

 û$"	é…ç½®ID


 û

 û

 û"#

ü$"æ˜Ÿçº§


ü

ü

ü"#

ı,"
ç»éªŒå€¼


ı

ı

ı*+
!
ş$"å½“å‰è£…å¤‡çš®è‚¤


ş

ş

ş"#

ÿ,"æ‹¥æœ‰çš®è‚¤


ÿ

ÿ

ÿ#

ÿ*+

ƒ ‰ é¬¼å® æ•°æ®


ƒ
&
 …4"å‡ºæˆ˜çš„é¬¼å® é…ç½®id


 …

 …

 …23
&
†4"å‡ºæˆ˜çš„é¬¼å® å”¯ä¸€id


†

†!

†23

‡4

‡

‡ *

‡23

ˆ<

ˆ 

ˆ!1

ˆ:;

Œ – é¬¼å® è‘«èŠ¦


Œ

 $"	è‘«èŠ¦id


 

 

 "#

$"è‘«èŠ¦æ˜µç§°






"#

$"è‘«èŠ¦ç­‰çº§






"#

‘$"è‘«èŠ¦ç»éªŒ


‘

‘

‘"#

’$"æ€»å¤©èµ‹ç‚¹


’

’

’"#

“$"å½“å‰å¤©èµ‹ç‚¹


“

“

“"#

”-"å¤©èµ‹å±æ€§


”

”

”(

”+,
!
•$"è‘«èŠ¦å†·å´æ—¶é—´


•

•

•"#

 ˜ ›

 ˜

  š*

  š

  š

  š#

  š()

! £ é“å…·å›¾é‰´


!

!  $"	é…ç½®ID


!  

!  

!  "#

!¡$"æ˜Ÿçº§


!¡

!¡

!¡"#

!¢,"
ç»éªŒå€¼


!¢

!¢

!¢*+

"¥ «

"¥

" §D"é“å…·å›¾é‰´


" §

" §&

" §BC

"¨<"æ³•å™¨å›¾é‰´


"¨

"¨,

"¨:;
$
"©<"è§’è‰²å…«å¦ç‰Œå›¾é‰´


"©

"©0

"©:;
$
"ª<"é¬¼å® å…«å¦ç‰Œå›¾é‰´


"ª

"ª0

"ª:;

#­ Ç

#­

# ¯"

# ¯

# ¯

# ¯ !

#°

#°


#°

#°

#±"

#±

#±

#± !

#²

#²	

#²


#²
$
#³" 0-æœªé€‰ 1-ç”· 2-å¥³


#³	

#³


#³

#´" ç‚¹èµ


#´	

#´


#´

#µ" å¤´åƒæ¡†


#µ	

#µ


#µ
"
#¶"" è´¦æˆ·åˆ›å»ºæ—¶é—´


#¶	

#¶


#¶ !
)
#¸ è´¦æˆ·ç»éªŒ è´¦æˆ·ç­‰çº§


#¸	

#¸


#¸

#	¹

#	¹	

#	¹


#	¹

#
»
 æˆ˜é˜ŸID


#
»	

#
»


#
»

#¼

#¼	

#¼


#¼

#¾% æ®µä½ä¿¡æ¯


#¾

#¾

#¾"$

#¿(

#¿

#¿"

#¿%'

#À)" æè„¸æ•°æ®


#À

#À#

#À&(
$
#Á"å½“å‰ä½©æˆ´çš„ç§°å·


#Á

#Á

#Á

#Â "ç©å®¶æ ‡ç­¾


#Â

#Â

#Â
'
#Ã!"æœ€åä¸€æ¬¡åœ¨çº¿æ—¶é—´


#Ã

#Ã

#Ã 
+
#Ä#"ç´¯è®¡åœ¨çº¿æ—¶é•¿ å•ä½ç§’


#Ä

#Ä

#Ä "
%
#Å" æ˜¯å¦ç¦è¨€ç­‰æ“ä½œ


#Å

#Å

#Å

#Æ5

#Æ

#Æ(

#Æ24
+
$Ê Î å®¢æˆ·ç«¯è¯·æ±‚ç®€ç•¥æ•°æ®


$Ê#

$ Í åè®®æ•°æ®


$ Í	

$ Í


$ Í
8
%Ñ ×* å®¢æˆ·ç«¯è¯·æ±‚ç®€ç•¥æ•°æ® è¿”å›ä¿¡æ¯


%Ñ#
:
% Ó", æœåŠ¡å™¨éªŒè¯è¿”å›,0æˆåŠŸ,å…¶ä»–å¤±è´¥


% Ó	

% Ó


% Ó

%Ô" é”™è¯¯ä¿¡æ¯


%Ô


%Ô

%Ô

%Õ"
 ç”¨æˆ·ID


%Õ	

%Õ


%Õ

%Ö" ç®€ç•¥ä¿¡æ¯


%Ö

%Ö

%Ö
1
&Ú Ş# å®¢æˆ·ç«¯è¯·æ±‚æ‰€æœ‰èƒŒåŒ…æ•°æ®


&Ú$

& İ åè®®æ•°æ®


& İ	

& İ


& İ

'à æ

'à$
:
' â", æœåŠ¡å™¨éªŒè¯è¿”å›,0æˆåŠŸ,å…¶ä»–å¤±è´¥


' â	

' â


' â

'ã" é”™è¯¯ä¿¡æ¯


'ã


'ã

'ã

'ä"
 ç”¨æˆ·ID


'ä	

'ä


'ä
"
'å" æ‰€æœ‰èƒŒåŒ…æ•°æ®


'å


'å

'å
-
(é ò å®¢æˆ·ç«¯è¯·æ±‚--è£…å¤‡å¼€å…‰


(é

( ë$

( ë

( ë

( ë"#

(ì

(ì

(ì

(ì

(í

(í

(í

(í

(î$

(î

(î

(î"#

(ï$

(ï

(ï

(ï"#

(ğ

(ğ

(ğ

(ğ

(ñ

(ñ

(ñ

(ñ

)ô ÿ

)ô
:
) ö$", æœåŠ¡å™¨éªŒè¯è¿”å›,0æˆåŠŸ,å…¶ä»–å¤±è´¥


) ö

) ö

) ö"#

)÷" é”™è¯¯ä¿¡æ¯


)÷


)÷

)÷

)ø$

)ø

)ø

)ø"#

)ù

)ù

)ù

)ù

)ú

)ú

)ú

)ú

)û$

)û

)û

)û"#

)ü$

)ü

)ü

)ü"#

)ı

)ı

)ı

)ı

)ş

)ş

)ş

)ş
-
*‚ ‡ å®¢æˆ·ç«¯è¯·æ±‚--æ³•å™¨å‡çº§


*‚#

* „$

* „

* „

* „"#

*…

*…

*…

*…

*†

*†

*†

*†

+‰ ‘

+‰#
:
+ ‹$", æœåŠ¡å™¨éªŒè¯è¿”å›,0æˆåŠŸ,å…¶ä»–å¤±è´¥


+ ‹

+ ‹

+ ‹"#

+Œ" é”™è¯¯ä¿¡æ¯


+Œ


+Œ

+Œ

+$

+

+

+"#

+

+

+

+

+

+

+

+

+

+

+

+bproto3
„—
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

guild_data (2.PBGuildMemberDataR	guildData"ğ
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
last_refresh_time (RlastRefreshTime"Z
PBGuildBagDB
guild_id (RguildId/
bag_item_list (2.PBItemDataRbagItemList"a
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

AO_DELJŸ
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
a-"*åªåœ¨æˆ˜åˆ©å“å‘æ”¾æ—¶ä½¿ç”¨ï¼Œç‰©å“id


a

a

a(

a*,
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
…	/":å…¬ä¼šä»“åº“ï¼ˆåŒ…å«è´§å¸ã€æ™®é€šç‰©å“ã€çš®è‚¤ç­‰ï¼‰


…	

…

…*

…-.
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
Æ&"æ·»åŠ ç‰©å“åˆ—è¡¨


Æ

Æ

Æ!

Æ$%
'
Ç"åŠ æ“ä½œè¿˜æ˜¯å‡æ“ä½œ


Ç

Ç

Ç
"
 Ë Ğ æ·»åŠ å…¬ä¼šç‰©å“


 Ë
?
  Ï& åè®®æ•°æ®
 å…¬ä¼šè®°å½•
"æ·»åŠ ç‰©å“åˆ—è¡¨


  Ï

  Ï

  Ï!

  Ï$%
"
!Ó Ø åˆ é™¤å…¬ä¼šç‰©å“


!Ó
?
! ×& åè®®æ•°æ®
 å…¬ä¼šè®°å½•
"æ·»åŠ ç‰©å“åˆ—è¡¨


! ×

! ×

! ×!

! ×$%
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
# è& åè®®æ•°æ®
 å…¬ä¼šè®°å½•
"å˜åŒ–çš„ä»“åº“ç‰©å“åˆ—è¡¨


# è

# è

# è!

# è$%
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
* ¢* åè®®æ•°æ®
 ç©å®¶çš„æ•°æ®
"è·å¾—çš„ç‰©å“ï¼ˆåˆ—è¡¨ï¼‰


* ¢

* ¢

* ¢%

* ¢()
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

|ı,

|ı

|ı

|ı$

|ı*+

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