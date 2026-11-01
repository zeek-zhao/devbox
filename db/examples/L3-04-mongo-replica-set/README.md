# L3-04-mongo-replica-set · 副本集与读写关注

<!-- coverage: pending -->

## 考点

三节点副本集、选举、readPreference、writeConcern

## 判据（验收按这一条核对）

输出 rs.status 主节点与写关注结果

## 依赖服务

`mongodb`

## 命名空间

`l3_04_mongo_replica_set`（用例开始时必须自己清理，保证可重复运行）

## 契约

- `run.sh` 跑在**宿主**上，用 `scripts/lib/common.sh` 里的 `tb` / `mysql_file` / `psql_file` / `redis_file` / `sqlite_file` / `py_file` 进容器
- stdout 必须确定：显式 `ORDER BY`、不打时间戳、不打耗时
- 交付前必须自己跑一次 `bash db/scripts/run-example.sh db L3-04-mongo-replica-set --update` 生成 `expected.txt`，
  并**人工确认输出确实体现了上面的考点**（不是「跑通就算」）
- 完成后把上面的 `coverage: pending` 去掉，或保留 pending 并在 PR 里说明为什么
