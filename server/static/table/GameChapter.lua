---@class GameChapter_cfg
---@field public id integer @唯一ID(必须为第一列且名称为id，类型为INT)
---@field public chapterid integer @章节唯一ID 1~1000主线 1001~2000鬼门关 2001~3000BOSS战 3001~4000爬塔
---@field public difficulty integer @第二个参数
---@field public mapid table @随机的地图id
---@field public bossid table @随机的bossID
---@field public playerlvlimits integer @条件 账户等级限制
---@field public rolelvlimits integer @条件 出战角色等级限制
---@field public codexmission string @挑战该难度所需要的前置条件 填写图鉴表中对应的任务
---@field public cost table @条件 该章节该难度的额外消耗 该资源不足无法开始游戏
---@field public yinshoucost integer @结算 消耗出战鬼怪的阴寿
---@field public yinqicost integer @结算 消耗出战鬼怪的阴气
---@field public victoryexp integer @结算 该章节该难度【获胜】后可获得的账户经验
---@field public failexp integer @结算 该章节该难度【失败】后可获得的账户经验
---@field public roleexp integer @结算 该章节该难度可获得的出战角色最大经验值
---@field public equipmentexp integer @结算 该章节该难度可获得的出战角色携带法器的最大经验值
---@field public getcost table @获取结算奖励的消耗 （限定领取奖励）
return {
[1] = { id=1,chapterid=1,difficulty=1,mapid={[5001]=100},bossid={[2001]=100,[2011]=100,[2035]=0,[2045]=0,[2048]=0,[2083]=0,[2084]=0},playerlvlimits=0,rolelvlimits=0,codexmission="",cost={},yinshoucost=5,yinqicost=50,victoryexp=100,failexp=50,roleexp=100,equipmentexp=20,getcost={} },
[2] = { id=2,chapterid=1,difficulty=2,mapid={[5001]=100},bossid={[2001]=100,[2011]=100,[2035]=0,[2045]=0,[2048]=0,[2083]=0,[2084]=0},playerlvlimits=1,rolelvlimits=1,codexmission="1,6",cost={[1]=1000},yinshoucost=6,yinqicost=60,victoryexp=100,failexp=50,roleexp=101,equipmentexp=20,getcost={} },
[3] = { id=3,chapterid=1,difficulty=3,mapid={[5001]=100},bossid={[2001]=100,[2011]=100,[2035]=0,[2045]=0,[2048]=0,[2083]=0,[2084]=0},playerlvlimits=2,rolelvlimits=2,codexmission="",cost={},yinshoucost=7,yinqicost=70,victoryexp=100,failexp=50,roleexp=102,equipmentexp=20,getcost={} },
[4] = { id=4,chapterid=1,difficulty=4,mapid={[5001]=100},bossid={[2001]=100,[2011]=100,[2035]=0,[2045]=0,[2048]=0,[2083]=0,[2084]=0},playerlvlimits=3,rolelvlimits=3,codexmission="5,10",cost={},yinshoucost=8,yinqicost=80,victoryexp=100,failexp=50,roleexp=103,equipmentexp=20,getcost={} },
[5] = { id=5,chapterid=1001,difficulty=1,mapid={[5200]=100},bossid={[2001]=100,[2004]=100},playerlvlimits=0,rolelvlimits=0,codexmission="",cost={},yinshoucost=4,yinqicost=49,victoryexp=99,failexp=49,roleexp=99,equipmentexp=19,getcost={[1]=1000} },
[6] = { id=6,chapterid=1001,difficulty=2,mapid={[5200]=100},bossid={[2001]=100,[2004]=100},playerlvlimits=0,rolelvlimits=0,codexmission="",cost={},yinshoucost=5,yinqicost=50,victoryexp=100,failexp=50,roleexp=100,equipmentexp=20,getcost={[1]=1001} },
[7] = { id=7,chapterid=1001,difficulty=3,mapid={[5200]=100},bossid={[2001]=100,[2004]=100},playerlvlimits=0,rolelvlimits=0,codexmission="",cost={},yinshoucost=5,yinqicost=50,victoryexp=100,failexp=50,roleexp=100,equipmentexp=20,getcost={[1]=1002} },
[8] = { id=8,chapterid=1001,difficulty=4,mapid={[5200]=100},bossid={[2001]=100,[2004]=100},playerlvlimits=0,rolelvlimits=0,codexmission="",cost={},yinshoucost=5,yinqicost=50,victoryexp=100,failexp=50,roleexp=100,equipmentexp=20,getcost={[1]=1003} },
[9] = { id=9,chapterid=2001,difficulty=1,mapid={[5001]=100},bossid={[2001]=100,[2004]=100},playerlvlimits=0,rolelvlimits=0,codexmission="",cost={},yinshoucost=5,yinqicost=50,victoryexp=100,failexp=50,roleexp=100,equipmentexp=20,getcost={} },
[10] = { id=10,chapterid=3001,difficulty=1,mapid={[5300]=100},bossid={[2001]=100,[2004]=100},playerlvlimits=0,rolelvlimits=0,codexmission="",cost={},yinshoucost=5,yinqicost=50,victoryexp=100,failexp=50,roleexp=100,equipmentexp=20,getcost={} },
[11] = { id=11,chapterid=3001,difficulty=2,mapid={[5300]=100},bossid={[2001]=100,[2004]=100},playerlvlimits=0,rolelvlimits=0,codexmission="",cost={},yinshoucost=5,yinqicost=50,victoryexp=100,failexp=50,roleexp=100,equipmentexp=20,getcost={} },
[12] = { id=12,chapterid=3001,difficulty=3,mapid={[5300]=100},bossid={[2001]=100,[2004]=100},playerlvlimits=0,rolelvlimits=0,codexmission="",cost={},yinshoucost=5,yinqicost=50,victoryexp=100,failexp=50,roleexp=100,equipmentexp=20,getcost={} },
[13] = { id=13,chapterid=3001,difficulty=4,mapid={[5300]=100},bossid={[2001]=100,[2004]=100},playerlvlimits=0,rolelvlimits=0,codexmission="",cost={},yinshoucost=5,yinqicost=50,victoryexp=100,failexp=50,roleexp=100,equipmentexp=20,getcost={} },
[14] = { id=14,chapterid=3001,difficulty=5,mapid={[5300]=100},bossid={[2001]=100,[2004]=100},playerlvlimits=0,rolelvlimits=0,codexmission="",cost={},yinshoucost=5,yinqicost=50,victoryexp=100,failexp=50,roleexp=100,equipmentexp=20,getcost={} },
[15] = { id=15,chapterid=3001,difficulty=6,mapid={[5300]=100},bossid={[2001]=100,[2004]=100},playerlvlimits=0,rolelvlimits=0,codexmission="",cost={},yinshoucost=5,yinqicost=50,victoryexp=100,failexp=50,roleexp=100,equipmentexp=20,getcost={} },
[16] = { id=16,chapterid=3001,difficulty=7,mapid={[5300]=100},bossid={[2001]=100,[2004]=100},playerlvlimits=0,rolelvlimits=0,codexmission="",cost={},yinshoucost=5,yinqicost=50,victoryexp=100,failexp=50,roleexp=100,equipmentexp=20,getcost={} },
[17] = { id=17,chapterid=3001,difficulty=8,mapid={[5300]=100},bossid={[2001]=100,[2004]=100},playerlvlimits=0,rolelvlimits=0,codexmission="",cost={},yinshoucost=5,yinqicost=50,victoryexp=100,failexp=50,roleexp=100,equipmentexp=20,getcost={} },
[18] = { id=18,chapterid=3001,difficulty=9,mapid={[5300]=100},bossid={[2001]=100,[2004]=100},playerlvlimits=0,rolelvlimits=0,codexmission="",cost={},yinshoucost=5,yinqicost=50,victoryexp=100,failexp=50,roleexp=100,equipmentexp=20,getcost={} },
[19] = { id=19,chapterid=3001,difficulty=10,mapid={[5300]=100},bossid={[2001]=100,[2004]=100},playerlvlimits=0,rolelvlimits=0,codexmission="",cost={},yinshoucost=5,yinqicost=50,victoryexp=100,failexp=50,roleexp=100,equipmentexp=20,getcost={} }
}