# DB-06 · 毕业项目：带缓存的订单服务

## 架构与分库取舍

订单的权威状态、事务边界和幂等键放在 MySQL；Redis 只承担可失效重建的热读缓存、
互斥重建、短期负缓存和排行榜；PostgreSQL 保存按日分区的报表事实并物化聚合；
MongoDB 保存按日归档的半结构化行为事件；SQLite 保存租户过滤后的离线快照与本地配置。
服务不会把缓存或报表副本当作订单写入的真相来源。

MySQL 使用项目专属数据库及受限应用账号，订单头、明细和幂等记录在单事务提交；
tenant/order 复合索引支持有序读取，软删除行仍保留历史。Redis 所有键均使用
`db_db06:` 前缀，锁释放通过 Lua 校验持有者；缓存 TTL 按业务键作确定性分散。
PostgreSQL 使用 JSONB、GIN 索引、日分区、窗口/递归 CTE 和物化视图。
Mongo 行为事件使用固定日期集合，不存 Mongo ObjectId 到输出。
SQLite 使用 WAL、JSON1、触发器、独立 ATTACH 配置库，并验证 VACUUM INTO 和在线备份。

## 运行

```bash
bash db/scripts/status.sh
bash db/scripts/wait-ready.sh
bash db/project/run.sh
bash scripts/coverage-check.sh db
```

`run.sh` 只把项目源码临时送入 toolbox 执行，不重建或停止共享 compose 栈。
数据库、Redis key、Mongo 数据库和本地文件均由 DB-06 独占命名空间，重复运行会先清理本项目数据。

## 端到端输出

```text
== 下单
order=O1001 amount=199.00 status=CREATED
== 幂等重放
order=O1001 (same, idempotent)
== 缓存命中
cache=HIT amount=199.00
== 分布式锁
lock=ACQUIRED then RELEASED
== 报表（PG 预聚合）
day=2026-01-01 orders=1 amount=199.00
== 行为日志（Mongo）
events=3 latest=ORDER_CREATED
== 离线快照（SQLite）
snapshot_orders=1
```

订单号、租户、金额和日期均为固定业务值；不输出自增键、ObjectId、时间戳、耗时或版本。
报表和快照只读活动订单，输出以业务键排序。

## 覆盖

`COVERAGE.md` 登记全部 77 个用例：56 个由项目实际路径接入，21 个保留 pending。

### 未接入说明（21 个 pending）

- `L1-MG-06-user-role`：项目不创建 MongoDB 全局用户或角色；服务使用共享栈的既有认证账号。
- `L1-MG-07-dump-restore`：行为集合是本次运行重建的服务数据，没有 Mongo 导出/恢复需求。
- `L1-MG-08-replica-concept`：共享环境只提供单机 MongoDB，没有副本集可验证。
- `L1-PG-08-schema-grant`：项目不创建共享 PostgreSQL 的额外角色；schema 隔离不等同于角色授权。
- `L1-RD-08-pubsub`：单进程演示没有独立订阅者；服务事件通过持久日志而非临时广播消费。
- `L2-02-slow-query`：项目不制造人为慢查询；报表路径是有界且带索引的业务查询。
- `L2-03-index-not-used`：项目校验索引支持的正常查询，不故意构造索引失效的扫描路径。
- `L2-04-txn-boundary-deadlock`：端到端流程没有两个竞争写事务，无法诚实声称演示死锁边界。
- `L2-10-conn-security`：共享 compose 服务没有 TLS 端点；本卡不改共享服务配置。
- `L2-13-lock-wait`：本项目的互斥由 Redis 实现，不通过竞争共享 MySQL 行锁制造等待。
- `L2-14-big-table-ddl`：项目数据集刻意保持很小，不在共享服务上执行大表 DDL 演练。
- `L3-01-mysql-replication`：没有第二个 MySQL 实例或复制拓扑。
- `L3-02-mysql-partition`：项目选择 PostgreSQL 日分区报表，不配置 MySQL 分区表。
- `L3-03-pg-logical-replication`：没有第二个 PostgreSQL 实例及逻辑复制订阅端。
- `L3-04-mongo-replica-set`：共享 MongoDB 是 standalone，不能验证副本集选举。
- `L3-05-redis-persistence`：不重启共享 Redis 或验证 AOF 恢复；缓存丢失可由 MySQL 重建。
- `L3-06-redis-sharding`：共享环境只有一个 Redis 节点，没有分片拓扑。
- `L3-07-shard-strategy`：项目使用租户键隔离数据，但不部署多分片或跨片路由。
- `L3-10-archive-cold-hot`：固定日期集合便于按天归档，但项目不配置独立冷存储和冷热迁移。
- `L3-11-tls-end-to-end`：共享 compose 服务没有本卡可控的 TLS 服务端证书与连接端点。
- `L3-12-audit-log`：Mongo 保存的是应用行为文档，不是数据库原生审计插件或服务端审计日志。

## 完成情况

- 已落地：56 个用例，详见 `COVERAGE.md`；pending 21 个。
- 自测：`run-example.sh db --all` → 77/77 PASS；项目端到端 → PASS。
- 覆盖：`coverage-check.sh db` → 覆盖 56 个，pending 21 个。
- 反向验证：把订单金额输入临时改为不匹配值，端到端断言失败；恢复后原输出通过。
- 发现的问题：无。
- 分库取舍结论：MySQL 保存唯一可写的订单真相，Redis 只做可重建加速，分析、行为和离线读取分别落在更适合其数据形态的 PostgreSQL、MongoDB 与 SQLite。
