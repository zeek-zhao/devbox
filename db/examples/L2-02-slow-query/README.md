<!-- coverage: pending -->

# L2-02-slow-query · 慢查询定位

## 考点

- PostgreSQL `pg_stat_activity` 可观察正在执行的长查询及其状态。
- 查询标记可用于从活动会话中准确定位目标语句。
- 慢查询观测需要独立观察连接，不能在目标查询结束后再找活动状态。

## 为什么这么写

选择 `pg_stat_activity` 路径：一个连接运行固定 `pg_sleep` 查询，另一个连接轮询并确认目标语句处于 `active`。共享实例没有通过 `shared_preload_libraries` 预加载 `pg_stat_statements`，因此创建扩展不可用；活动视图不要求改共享配置，也不会只验证一个尚未执行的日志配置。

## 易错点

- `pg_stat_activity` 只呈现当前活动，不是历史统计；本例在目标语句执行期间捕获它。
- 轮询有总超时，超时会明确失败，不会以缺少观测的成功输出兜底。
- 输出不包含运行时长或动态 SQL 文本，只报告是否实际捕获到活动查询。

## 依赖服务

`postgres`

## 命名空间

`db_l2_02_slow_query`
