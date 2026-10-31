# L2-01-pool-timeout · 连接池与超时

<!-- coverage: pending -->

## 考点

池上限、获取超时、空闲回收、连接泄漏指纹

## 判据（验收按这一条核对）

输出池打满时的等待耗时与拒绝行为

## 依赖服务

`mysql,redis`

## 命名空间

`l2_01_pool_timeout`（用例开始时必须自己清理，保证可重复运行）

## 契约

- `run.sh` 跑在**宿主**上，用 `scripts/lib/common.sh` 里的 `tb` / `mysql_file` / `psql_file` / `redis_file` / `sqlite_file` / `py_file` 进容器
- stdout 必须确定：显式 `ORDER BY`、不打时间戳、不打耗时
- 交付前必须自己跑一次 `bash db/scripts/run-example.sh db L2-01-pool-timeout --update` 生成 `expected.txt`，
  并**人工确认输出确实体现了上面的考点**（不是「跑通就算」）
- 完成后把上面的 `coverage: pending` 去掉，或保留 pending 并在 PR 里说明为什么
