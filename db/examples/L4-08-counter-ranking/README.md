
# L4-08-counter-ranking · 计数与排行榜

## 考点
- Redis ZSet 输出前三名和指定用户名次，并包含同分用户。
- 通过相同分数的成员顺序展示 Redis 反向范围查询的字典序并列规则。
- 删除排行榜后从 toolbox 内独立 SQLite 源表重建，并比较重建结果。

## 为什么这么写
用 ZREVRANGE 分页取榜单、`ZREVRANK` 查询一基名次。SQLite 是本用例内的持久数据源，Redis 只作可重建派生索引；不依赖共享 MySQL，也不清理其他用例的 Redis key。

## 易错点
- `ZREVRANK` 返回 0 起始排名，展示时加 1；分页偏移量仍按 0 起始。
- 同分时 ZREVRANGE 按成员字典序逆序排列，不能把并列顺序当成插入顺序。
- `ZREVRANGE` 的结束下标包含在内，前三名区间是 `0..2`。

## 依赖服务
`redis`、toolbox 内的 SQLite

## 命名空间
Redis `l4_08_counter_ranking:board`；SQLite `/tmp/l4_08_counter_ranking.db`
