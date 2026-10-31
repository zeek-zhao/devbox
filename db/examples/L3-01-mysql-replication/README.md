# L3-01-mysql-replication · MySQL 主从复制

<!-- coverage: pending -->

## 考点

binlog 格式、主从搭建、复制延迟、半同步

## 判据（验收按这一条核对）

输出 SHOW REPLICA STATUS 的关键字段

## 为什么这么写

主从都使用独立 MySQL 容器，主库启用 GTID/binlog，从库用自动定位连接；只有复制线程为 Yes 且实际读到主库业务键时才通过。

## 易错点

- 共享 MySQL 没开 binlog，不能拿它冒充主库。
- 复制账号使用 GET_SOURCE_PUBLIC_KEY，避免明文密码插件导致复制 I/O 线程连接失败。

## 依赖服务

`mysql`

## 命名空间

`l3_01_mysql_replication`（用例开始时必须自己清理，保证可重复运行）

## 契约

- `run.sh` 跑在**宿主**上，用 `scripts/lib/common.sh` 里的 `tb` / `mysql_file` / `psql_file` / `redis_file` / `sqlite_file` / `py_file` 进容器
- stdout 必须确定：显式 `ORDER BY`、不打时间戳、不打耗时
- 交付前必须自己跑一次 `bash db/scripts/run-example.sh db L3-01-mysql-replication --update` 生成 `expected.txt`，
  并**人工确认输出确实体现了上面的考点**（不是「跑通就算」）
- 完成后把上面的 `coverage: pending` 去掉，或保留 pending 并在 PR 里说明为什么
