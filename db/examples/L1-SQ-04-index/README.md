# L1-SQ-04-index · 索引与查询计划

<!-- coverage: pending -->

## 考点

EXPLAIN QUERY PLAN、覆盖索引、部分索引、ANALYZE

## 判据（验收按这一条核对）

输出两种查询的 QUERY PLAN 对比

## 依赖服务

`toolbox`

## 命名空间

`l1_sq_04_index`（用例开始时必须自己清理，保证可重复运行）

## 契约

- `run.sh` 跑在**宿主**上，用 `scripts/lib/common.sh` 里的 `tb` / `mysql_file` / `psql_file` / `redis_file` / `sqlite_file` / `py_file` 进容器
- stdout 必须确定：显式 `ORDER BY`、不打时间戳、不打耗时
- 交付前必须自己跑一次 `bash db/scripts/run-example.sh db L1-SQ-04-index --update` 生成 `expected.txt`，
  并**人工确认输出确实体现了上面的考点**（不是「跑通就算」）
- 完成后把上面的 `coverage: pending` 去掉，或保留 pending 并在 PR 里说明为什么
