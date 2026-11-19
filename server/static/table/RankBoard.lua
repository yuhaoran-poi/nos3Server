---@class RankBoard_cfg
---@field public id integer @榜实例ID(=rank_type): 101~199竞速周 201~299竞速总 301摸金周 401摸金总 501~599古董周 601~699古董总
---@field public category integer @一级标签 1=鬼王竞速 2=摸金 3=古董(领奖聚合粒度, 每标签各领一次)
---@field public sub_id integer @二级标签: 竞速=鬼王章节ID(2001~3000), 古董=红古董配置ID(quality=5), 摸金=0(无二级)
---@field public window integer @统计窗口 1=周榜(周一刷新) 2=总榜(赛季结束刷新), 同一sub_id的周/总各自独立分卷
---@field public merge integer @成绩合并 1=取最高(最好一次/最高一件) 2=累加(本周合计)
return {
-- 鬼王竞速: 地狱难度(5)通关计时, 取最好一次 (章节清单由策划补全)
[101] = { id=101, category=1, sub_id=2001, window=1, merge=1 },
[201] = { id=201, category=1, sub_id=2001, window=2, merge=1 },
-- 摸金: 成功带出(通关或撤离成功)的战利品估值, 本周累加, 无二级标签
[301] = { id=301, category=2, sub_id=0, window=1, merge=2 },
[401] = { id=401, category=2, sub_id=0, window=2, merge=2 },
-- 古董: 红古董(quality=5)鉴定完成且为真的价值, 同款取最高一件 (清单由策划补全)
[501] = { id=501, category=3, sub_id=625018, window=1, merge=1 },
[601] = { id=601, category=3, sub_id=625018, window=2, merge=1 },
[502] = { id=502, category=3, sub_id=625024, window=1, merge=1 },
[602] = { id=602, category=3, sub_id=625024, window=2, merge=1 },
[503] = { id=503, category=3, sub_id=625025, window=1, merge=1 },
[603] = { id=603, category=3, sub_id=625025, window=2, merge=1 },
}
