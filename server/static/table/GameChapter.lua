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
---@field public account_exp integer @结算可获得的基础账户经验
---@field public item_exp integer @结算可获得的基础养成经验
return {
[1] = { id=1,chapterid=1,difficulty=1,mapid={[5001]=100},bossid={[2001]=100,[2011]=100,[2035]=0,[2045]=0,[2048]=0,[2083]=0,[2084]=0},playerlvlimits=0,rolelvlimits=0,codexmission="",cost={},account_exp=100,item_exp=50 },
[2] = { id=2,chapterid=1,difficulty=2,mapid={[5001]=100},bossid={[2001]=100,[2011]=100,[2035]=0,[2045]=0,[2048]=0,[2083]=0,[2084]=0},playerlvlimits=1,rolelvlimits=1,codexmission="1,6",cost={[1]=1000},account_exp=100,item_exp=50 },
[3] = { id=3,chapterid=1,difficulty=3,mapid={[5001]=100},bossid={[2001]=100,[2011]=100,[2035]=0,[2045]=0,[2048]=0,[2083]=0,[2084]=0},playerlvlimits=2,rolelvlimits=2,codexmission="",cost={},account_exp=100,item_exp=50 },
[4] = { id=4,chapterid=1,difficulty=4,mapid={[5001]=100},bossid={[2001]=100,[2011]=100,[2035]=0,[2045]=0,[2048]=0,[2083]=0,[2084]=0},playerlvlimits=3,rolelvlimits=3,codexmission="5,10",cost={},account_exp=100,item_exp=50 },
[5] = { id=5,chapterid=1001,difficulty=1,mapid={[5200]=100},bossid={[2001]=100,[2004]=100},playerlvlimits=0,rolelvlimits=0,codexmission="",cost={},account_exp=99,item_exp=49 },
[6] = { id=6,chapterid=1001,difficulty=2,mapid={[5200]=100},bossid={[2001]=100,[2004]=100},playerlvlimits=0,rolelvlimits=0,codexmission="",cost={},account_exp=100,item_exp=50 },
[7] = { id=7,chapterid=1001,difficulty=3,mapid={[5200]=100},bossid={[2001]=100,[2004]=100},playerlvlimits=0,rolelvlimits=0,codexmission="",cost={},account_exp=100,item_exp=50 },
[8] = { id=8,chapterid=1001,difficulty=4,mapid={[5200]=100},bossid={[2001]=100,[2004]=100},playerlvlimits=0,rolelvlimits=0,codexmission="",cost={},account_exp=100,item_exp=50 },
[9] = { id=9,chapterid=2001,difficulty=1,mapid={[5001]=100},bossid={[2001]=100,[2004]=100},playerlvlimits=0,rolelvlimits=0,codexmission="",cost={},account_exp=100,item_exp=50 },
[10] = { id=10,chapterid=3001,difficulty=1,mapid={[5300]=100},bossid={[2001]=100,[2004]=100},playerlvlimits=0,rolelvlimits=0,codexmission="",cost={},account_exp=100,item_exp=50 },
[11] = { id=11,chapterid=3001,difficulty=2,mapid={[5300]=100},bossid={[2001]=100,[2004]=100},playerlvlimits=0,rolelvlimits=0,codexmission="",cost={},account_exp=100,item_exp=50 },
[12] = { id=12,chapterid=3001,difficulty=3,mapid={[5300]=100},bossid={[2001]=100,[2004]=100},playerlvlimits=0,rolelvlimits=0,codexmission="",cost={},account_exp=100,item_exp=50 },
[13] = { id=13,chapterid=3001,difficulty=4,mapid={[5300]=100},bossid={[2001]=100,[2004]=100},playerlvlimits=0,rolelvlimits=0,codexmission="",cost={},account_exp=100,item_exp=50 },
[14] = { id=14,chapterid=3001,difficulty=5,mapid={[5300]=100},bossid={[2001]=100,[2004]=100},playerlvlimits=0,rolelvlimits=0,codexmission="",cost={},account_exp=100,item_exp=50 },
[15] = { id=15,chapterid=3001,difficulty=6,mapid={[5300]=100},bossid={[2001]=100,[2004]=100},playerlvlimits=0,rolelvlimits=0,codexmission="",cost={},account_exp=100,item_exp=50 },
[16] = { id=16,chapterid=3001,difficulty=7,mapid={[5300]=100},bossid={[2001]=100,[2004]=100},playerlvlimits=0,rolelvlimits=0,codexmission="",cost={},account_exp=100,item_exp=50 },
[17] = { id=17,chapterid=3001,difficulty=8,mapid={[5300]=100},bossid={[2001]=100,[2004]=100},playerlvlimits=0,rolelvlimits=0,codexmission="",cost={},account_exp=100,item_exp=50 },
[18] = { id=18,chapterid=3001,difficulty=9,mapid={[5300]=100},bossid={[2001]=100,[2004]=100},playerlvlimits=0,rolelvlimits=0,codexmission="",cost={},account_exp=100,item_exp=50 },
[19] = { id=19,chapterid=3001,difficulty=10,mapid={[5300]=100},bossid={[2001]=100,[2004]=100},playerlvlimits=0,rolelvlimits=0,codexmission="",cost={},account_exp=100,item_exp=50 }
}