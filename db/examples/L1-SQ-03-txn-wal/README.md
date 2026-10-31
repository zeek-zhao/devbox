
# L1-SQ-03-txn-wal · 事务与 WAL

## 考点
- 查询实际启用的 WAL 模式，并展示 WAL 中 `BEGIN EXCLUSIVE` 可以取得写事务。
- 在一个连接持有 `BEGIN IMMEDIATE` 时，第二写连接稳定得到 `database is locked`。
- 用 SAVEPOINT 回滚局部插入，验证其余事务仍可提交。

## 为什么这么写
两个 Python SQLite 连接访问同一独立数据库文件；短 `busy_timeout` 让竞争结果可重复，不依赖手工调度或长时间等待。

## 易错点
- WAL 模式下 `BEGIN EXCLUSIVE` 与 `BEGIN IMMEDIATE` 的锁行为不同于 rollback journal 模式。
- 只检查锁错误还不够，保存点回滚后的行数也用于证明外层事务成功提交。

## 依赖服务
`toolbox`

## 命名空间
`/tmp/l1-sq-03-txn-wal.db`
