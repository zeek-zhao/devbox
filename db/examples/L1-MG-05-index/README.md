<!-- coverage: pending -->

# L1-MG-05-index · 索引与 explain

## 考点
- 创建单字段、复合、多键、唯一、部分和 TTL 索引。
- 对有索引的条件查询运行 executionStats，输出实际执行阶段与返回数。

## 为什么这么写
`hint("score_1")` 让小型固定数据集也稳定使用指定索引；从 winningPlan 递归读取 stage，而不是输出 explain 中随版本变化的完整计划和耗时。TTL 日期固定在未来，避免后台过期任务删除样本。

## 易错点
- 小表上优化器可能认为表扫描更便宜；未使用 hint 时不能假定 explain 一定出现 IXSCAN。
- TTL 索引字段需要 Date 类型，且后台过期清理不是即时操作。
- 唯一索引应使用互不重复的样本值；重复数据会使建索引失败。

## 依赖服务
`mongodb`

## 命名空间
`db_l1_mg_05_index`
