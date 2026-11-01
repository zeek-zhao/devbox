# L3-03-pg-logical-replication · PG 逻辑复制

<!-- coverage: exempt DB-06 的 PostgreSQL 报表由同一应用直接写入，没有独立下游订阅者或跨实例发布需求；增加逻辑复制端点不会服务项目读取路径。 -->

## 考点

publication/subscription、复制槽、冲突处理

## 判据（验收按这一条核对）

输出订阅端收到的行数

## 为什么这么写

发布端和订阅端分开启动，发布端启用 wal_level=logical；订阅建立后轮询订阅端的业务键，确认数据实际到达。

## 易错点

- 逻辑复制不复制 DDL，因此两端都需先创建兼容表结构。
- CREATE SUBSCRIPTION 不能与其他语句组合在同一个 psql 多语句调用中。

## 依赖服务

`postgres`

## 命名空间

`l3_03_pg_logical_replication`（用例开始时必须自己清理，保证可重复运行）

## 契约

- `run.sh` 跑在**宿主**上，用 `scripts/lib/common.sh` 里的 `tb` / `mysql_file` / `psql_file` / `redis_file` / `sqlite_file` / `py_file` 进容器
- stdout 必须确定：显式 `ORDER BY`、不打时间戳、不打耗时
- 交付前必须自己跑一次 `bash db/scripts/run-example.sh db L3-03-pg-logical-replication --update` 生成 `expected.txt`，
  并**人工确认输出确实体现了上面的考点**（不是「跑通就算」）
- 本用例与 DB-06 的覆盖处置及理由见顶部声明。
