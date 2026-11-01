# L3-08-distributed-lock · 分布式锁


## 考点

SET NX PX + 续期、DB 行锁、误删锁与 fencing token

## 判据（验收按这一条核对）

输出抢锁失败/成功与超时释放

## 为什么这么写

通过真实 Redis SET NX PX 验证竞争失败和过期后接管，并对照无条件 DEL 与按 value 比较后 Lua 原子释放的区别。

## 易错点

- SET NX 和 PX 必须在同一条命令中，否则加锁与过期设置之间会出现永久锁窗口。
- Lua 释放脚本只允许持有者删除 key；不使用 FLUSHALL 清理。

## 依赖服务

`redis,mysql`

## 命名空间

`l3_08_distributed_lock`（用例开始时必须自己清理，保证可重复运行）

## 契约

- `run.sh` 跑在**宿主**上，用 `scripts/lib/common.sh` 里的 `tb` / `mysql_file` / `psql_file` / `redis_file` / `sqlite_file` / `py_file` 进容器
- stdout 必须确定：显式 `ORDER BY`、不打时间戳、不打耗时
- 交付前必须自己跑一次 `bash db/scripts/run-example.sh db L3-08-distributed-lock --update` 生成 `expected.txt`，
  并**人工确认输出确实体现了上面的考点**（不是「跑通就算」）
- 本用例在 DB-06 项目里按 B 类豁免，理由见 `db/project/COVERAGE.md`
