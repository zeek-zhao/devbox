# L2-15-db-selection · 多库选型对比

<!-- coverage: pending -->

## 考点

同一需求（订单+缓存+日志）在五种库的实现与代价

## 判据（验收按这一条核对）

输出五种实现的取舍对照表

## 依赖服务

`mysql,postgres,mongodb,redis,toolbox`

## 命名空间

`l2_15_db_selection`（用例开始时必须自己清理，保证可重复运行）

## 契约

- `run.sh` 跑在**宿主**上，用 `scripts/lib/common.sh` 里的 `tb` / `mysql_file` / `psql_file` / `redis_file` / `sqlite_file` / `py_file` 进容器
- stdout 必须确定：显式 `ORDER BY`、不打时间戳、不打耗时
- 交付前必须自己跑一次 `bash db/scripts/run-example.sh db L2-15-db-selection --update` 生成 `expected.txt`，
  并**人工确认输出确实体现了上面的考点**（不是「跑通就算」）
- 完成后把上面的 `coverage: pending` 去掉，或保留 pending 并在 PR 里说明为什么
