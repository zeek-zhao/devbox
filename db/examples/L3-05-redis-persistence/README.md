# L3-05-redis-persistence · Redis 持久化

<!-- coverage: exempt DB-06 的 Redis 仅保存可从 MySQL 重建的缓存、锁和短期排行，不承载唯一持久数据；项目不需要以 AOF 恢复作为成功条件。 -->

## 考点

RDB/AOF/混合、appendfsync 三档、重启恢复

## 判据（验收按这一条核对）

输出重启后 key 是否还在

## 为什么这么写

专用 Redis 容器启用 AOF 和 appendfsync always；写入后关闭并重启同一容器，再从恢复后的实例读取 key。

## 易错点

- 禁止重启共享 Redis；AOF 文件必须留在同一个临时容器可持久化的可写层。
- Redis 关闭时 docker exec 可能因主进程退出返回非零，随后要确认容器确实已停止。

## 依赖服务

`redis`

## 命名空间

`l3_05_redis_persistence`（用例开始时必须自己清理，保证可重复运行）

## 契约

- `run.sh` 跑在**宿主**上，用 `scripts/lib/common.sh` 里的 `tb` / `mysql_file` / `psql_file` / `redis_file` / `sqlite_file` / `py_file` 进容器
- stdout 必须确定：显式 `ORDER BY`、不打时间戳、不打耗时
- 交付前必须自己跑一次 `bash db/scripts/run-example.sh db L3-05-redis-persistence --update` 生成 `expected.txt`，
  并**人工确认输出确实体现了上面的考点**（不是「跑通就算」）
- 本用例与 DB-06 的覆盖处置及理由见顶部声明。
