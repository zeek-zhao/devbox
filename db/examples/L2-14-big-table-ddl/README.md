# L2-14-big-table-ddl · 大表 DDL 安全

<!-- coverage: exempt DB-06 使用固定小型订单数据集和显式版本迁移，不在共享服务上创建大表或执行会阻塞业务的 DDL。 -->

## 考点

加索引的锁行为、Online DDL 算法、分批回填

## 判据（验收按这一条核对）

输出 DDL 执行期间并发写入是否被阻塞

## 为什么这么写

先插入 50,000 行，再用 ALGORITHM=INPLACE、LOCK=NONE 明确约束加索引方式，并由另一个连接并发写入；不以毫秒耗时作断言。

## 易错点

- 省略 LOCK=NONE 会允许服务端选择更强的锁，例子就不再证明在线写入。
- 写线程和 DDL 都必须完成成功，不能只打印静态结论。

## 依赖服务

`mysql`

## 命名空间

`l2_14_big_table_ddl`（用例开始时必须自己清理，保证可重复运行）

## 契约

- `run.sh` 跑在**宿主**上，用 `scripts/lib/common.sh` 里的 `tb` / `mysql_file` / `psql_file` / `redis_file` / `sqlite_file` / `py_file` 进容器
- stdout 必须确定：显式 `ORDER BY`、不打时间戳、不打耗时
- 交付前必须自己跑一次 `bash db/scripts/run-example.sh db L2-14-big-table-ddl --update` 生成 `expected.txt`，
  并**人工确认输出确实体现了上面的考点**（不是「跑通就算」）
- 本用例与 DB-06 的覆盖处置及理由见顶部声明。
