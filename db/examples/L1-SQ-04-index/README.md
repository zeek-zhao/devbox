<!-- coverage: pending -->

# L1-SQ-04-index · 索引与查询计划

## 考点
- 用 `EXPLAIN QUERY PLAN` 显示覆盖复合索引和部分索引的实际使用。
- 通过 `NOT INDEXED` 对照执行计划中的全表扫描。
- 执行 `ANALYZE` 后查看计划，并保持输出按查询顺序展示。

## 为什么这么写
查询条件和数据显式匹配已建立的索引；计划输出只用于比对 `SEARCH`/索引名和 `SCAN`，不依赖耗时。

## 易错点
- 部分索引只包含满足谓词 `active = 1` 的行，查询需包含同一约束才能匹配。
- `EXPLAIN QUERY PLAN` 的 detail 文本是计划说明，不应当误当成查询结果集。

## 依赖服务
`toolbox`

## 命名空间
`/tmp/l1-sq-04-index.db`
