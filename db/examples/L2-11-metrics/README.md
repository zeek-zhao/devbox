# L2-11-metrics · 监控指标


## 考点

连接数/命中率/慢查询/QPS、pg_stat_*、Redis INFO 分节

## 判据（验收按这一条核对）

输出四个库的关键指标快照

## 为什么这么写

MySQL 与 Redis 分别采样单调递增的语句/命令计数器，在两次采样间执行固定查询，并只输出是否达到宽松下界，不输出计数值。计数器可能包含同机其他连接、后台任务和采样命令，因而增量取决于并发负载；这里断言方向和最低增量而不是精确数值。PostgreSQL 与 MongoDB 保留字段可用性检查。

## 易错点

- Redis 命令计数器采用区间增量下界，不把并发环境中的精确计数误当稳定断言。
- 删除本用例 Redis 前缀，不清共享库全局数据。

## 依赖服务

`mysql,postgres,mongodb,redis`

## 命名空间

`l2_11_metrics`（用例开始时必须自己清理，保证可重复运行）

## 契约

- `run.sh` 跑在**宿主**上，用 `scripts/lib/common.sh` 里的 `tb` / `mysql_file` / `psql_file` / `redis_file` / `sqlite_file` / `py_file` 进容器
- stdout 必须确定：显式 `ORDER BY`、不打时间戳、不打耗时
- 交付前必须自己跑一次 `bash db/scripts/run-example.sh db L2-11-metrics --update` 生成 `expected.txt`，
  并**人工确认输出确实体现了上面的考点**（不是「跑通就算」）
- 本用例在 DB-06 项目里按 B 类豁免，理由见 `db/project/COVERAGE.md`
