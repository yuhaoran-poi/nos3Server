---@class RankLevel_cfg
---@field public id integer @唯一ID(必须为第一列且名称为id，类型为INT)
---@field public grade_level integer @品阶（5表示宇宙洪荒两个品阶，星星数大于49表示洪荒）
---@field public max_level integer @最大品级
---@field public top_star integer @最大星数（0表示无上限，此时大于49颗表示洪荒）
---@field public top_score integer @最大加星分
---@field public bottom_score integer @最大扣星抵扣分
return {
[1] = { id=1,grade_level=1,max_level=9,top_star=2,top_score=300,bottom_score=0 },
[2] = { id=2,grade_level=2,max_level=9,top_star=3,top_score=350,bottom_score=100 },
[3] = { id=3,grade_level=3,max_level=9,top_star=4,top_score=500,bottom_score=150 },
[4] = { id=4,grade_level=4,max_level=9,top_star=5,top_score=1000,bottom_score=300 },
[5] = { id=5,grade_level=5,max_level=0,top_star=0,top_score=1500,bottom_score=450 }
}