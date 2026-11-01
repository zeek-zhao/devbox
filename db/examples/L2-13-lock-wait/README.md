# L2-13-lock-wait · 锁等待与阻塞排查

<!-- coverage: exempt DB-06 的并发互斥由带过期时间的 Redis 锁实现，不以竞争 MySQL 行锁协调请求；项目流程无需要长时间等待的行锁。 -->

## 考点

INNODB_TRX/INNODB_LOCK_WAITS、pg_locks、currentOp

## 判据（验收按这一条核对）

输出阻塞链的等待者与被等待者

## 为什么这么写

阻塞者先锁住 id=1；等待者先锁 id=2 再申请 id=1。第三个连接从 performance_schema.data_lock_waits 实际观察等待关系后才释放锁。

## 易错点

- 仅看到等待线程不等于验证了阻塞链；要观察到 data_lock_waits 行。
- 线程设置有限等待时间，避免失败时遗留事务。

## 依赖服务

`mysql,postgres`

## 命名空间

`l2_13_lock_wait`（用例开始时必须自己清理，保证可重复运行）

## 契约

- `run.sh` 跑在**宿主**上，用 `scripts/lib/common.sh` 里的 `tb` / `mysql_file` / `psql_file` / `redis_file` / `sqlite_file` / `py_file` 进容器
- stdout 必须确定：显式 `ORDER BY`、不打时间戳、不打耗时
- 交付前必须自己跑一次 `bash db/scripts/run-example.sh db L2-13-lock-wait --update` 生成 `expected.txt`，
  并**人工确认输出确实体现了上面的考点**（不是「跑通就算」）
- 本用例与 DB-06 的覆盖处置及理由见顶部声明。
