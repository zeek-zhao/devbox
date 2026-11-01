# L4-10-report-aggregation · 报表聚合

<!-- coverage: pending -->

## 考点

物化视图/预聚合表、增量刷新、MATERIALIZED VIEW

## 判据（验收按这一条核对）

输出预聚合与实时聚合结果一致

## 依赖服务

`mysql,postgres`

## 命名空间

`l4_10_report_aggregation`（用例开始时必须自己清理，保证可重复运行）

## 契约

- `run.sh` 跑在**宿主**上，用 `scripts/lib/common.sh` 里的 `tb` / `mysql_file` / `psql_file` / `redis_file` / `sqlite_file` / `py_file` 进容器
- stdout 必须确定：显式 `ORDER BY`、不打时间戳、不打耗时
- 交付前必须自己跑一次 `bash db/scripts/run-example.sh db L4-10-report-aggregation --update` 生成 `expected.txt`，
  并**人工确认输出确实体现了上面的考点**（不是「跑通就算」）
- 完成后把上面的 `coverage: pending` 去掉，或保留 pending 并在 PR 里说明为什么
