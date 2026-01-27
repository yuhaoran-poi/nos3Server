---@class RankConfig_cfg
---@field public id integer @段位ID
---@field public chapterid_range integer[] @章节id范围
---@field public exp_type string @使用的等级积分组
---@field public reward_type string @使用的等级奖励组
---@field public maxlv integer @最大等级
---@field public maxexp integer @积分上限
return {
[1] = { id=1,chapterid_range={1,1000},exp_type="exp_1",reward_type="reward_1",maxlv=0,maxexp=0 },
[2] = { id=2,chapterid_range={1001,2000},exp_type="exp_2",reward_type="reward_2",maxlv=0,maxexp=0 },
[3] = { id=3,chapterid_range={2001,3000},exp_type="exp_3",reward_type="reward_3",maxlv=0,maxexp=0 },
[4] = { id=4,chapterid_range={3001,4000},exp_type="exp_4",reward_type="reward_4",maxlv=0,maxexp=0 }
}