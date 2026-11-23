---@class RankBoard_cfg
---@field public id integer @榜ID
---@field public category integer @榜分类 1-竞速 2-摸金 3-古董
---@field public sub_id integer @二级分类 竞速配章节ID 古董配古董ID 摸金=0
---@field public window integer @统计窗口 1=周榜 2=总榜
---@field public merge integer @成绩合并 1=最高 2=累加
return {
[101] = { id=101,category=1,sub_id=2001,window=1,merge=1 },
[102] = { id=102,category=1,sub_id=2004,window=1,merge=1 },
[103] = { id=103,category=1,sub_id=2011,window=1,merge=1 },
[104] = { id=104,category=1,sub_id=2045,window=1,merge=1 },
[105] = { id=105,category=1,sub_id=2084,window=1,merge=1 },
[106] = { id=106,category=1,sub_id=2007,window=1,merge=1 },
[201] = { id=201,category=1,sub_id=2001,window=2,merge=1 },
[202] = { id=202,category=1,sub_id=2004,window=2,merge=1 },
[203] = { id=203,category=1,sub_id=2011,window=2,merge=1 },
[204] = { id=204,category=1,sub_id=2045,window=2,merge=1 },
[205] = { id=205,category=1,sub_id=2084,window=2,merge=1 },
[206] = { id=206,category=1,sub_id=2007,window=2,merge=1 },
[301] = { id=301,category=2,sub_id=0,window=1,merge=2 },
[401] = { id=401,category=2,sub_id=0,window=2,merge=2 },
[501] = { id=501,category=3,sub_id=625048,window=1,merge=1 },
[502] = { id=502,category=3,sub_id=625040,window=1,merge=1 },
[503] = { id=503,category=3,sub_id=625034,window=1,merge=1 },
[504] = { id=504,category=3,sub_id=625032,window=1,merge=1 },
[505] = { id=505,category=3,sub_id=625025,window=1,merge=1 },
[506] = { id=506,category=3,sub_id=625024,window=1,merge=1 },
[507] = { id=507,category=3,sub_id=625018,window=1,merge=1 },
[601] = { id=601,category=3,sub_id=625048,window=2,merge=1 },
[602] = { id=602,category=3,sub_id=625040,window=2,merge=1 },
[603] = { id=603,category=3,sub_id=625034,window=2,merge=1 },
[604] = { id=604,category=3,sub_id=625032,window=2,merge=1 },
[605] = { id=605,category=3,sub_id=625025,window=2,merge=1 },
[606] = { id=606,category=3,sub_id=625024,window=2,merge=1 },
[607] = { id=607,category=3,sub_id=625018,window=2,merge=1 }
}