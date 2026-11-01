# DB-06 覆盖表

| 用例ID | 落点 | 说明 |
|---|---|---|
| L1-MG-01-doc-collection | order_service/audit.py:16 | 按固定日期建立行为事件集合 |
| L1-MG-02-crud | order_service/audit.py:22 | 写入、更新并查询独立行为文档 |
| L1-MG-03-query-operators | order_service/audit.py:43 | 按租户和事件序号范围查询 |
| L1-MG-04-aggregation | order_service/audit.py:43 | 对事件类型分组计数并排序 |
| L1-MG-05-index | order_service/audit.py:16 | 为租户和事件序号建立复合索引 |
| L1-MG-06-user-role | pending | standalone 项目不创建 MongoDB 全局用户或角色 |
| L1-MG-07-dump-restore | pending | 本项目没有 Mongo 导出/恢复数据流 |
| L1-MG-08-replica-concept | pending | 共享环境只有 standalone MongoDB |
| L1-MY-01-create-and-types | order_service/order.py:77 | 定义有约束的订单及明细类型 |
| L1-MY-02-crud | order_service/order.py:77 | 创建订单并执行租户范围读写 |
| L1-MY-03-join-group | order_service/order.py:175 | 联结订单头和明细快照 |
| L1-MY-04-index-explain | order_service/order.py:77 | 验证复合索引支持的订单读取 |
| L1-MY-05-transaction | order_service/order.py:135 | 原子提交订单、明细和幂等记录 |
| L1-MY-06-user-grant | order_service/order.py:78 | 使用仅限项目库的应用账号授权 |
| L1-MY-07-import-export | order_service/snapshot.py:57 | 导出活动订单到 SQLite 快照 |
| L1-MY-08-functions | order_service/order.py:259 | ROUND 计算确定性金额 |
| L1-PG-01-types-jsonb | order_service/report.py:14 | 使用 JSONB 保存报表维度 |
| L1-PG-02-crud | order_service/report.py:14 | 写入并读取 PostgreSQL 事实表 |
| L1-PG-03-window | order_service/report.py:84 | 使用窗口函数稳定计算日排名 |
| L1-PG-04-cte-recursive | order_service/report.py:85 | 递归生成报表日期范围 |
| L1-PG-05-index-gin | order_service/report.py:14 | GIN 索引服务 JSONB 包含查询 |
| L1-PG-06-savepoint | order_service/report.py:55 | 保存点隔离报表事实写入 |
| L1-PG-07-serial-sequence | order_service/report.py:15 | BIGSERIAL 生成内部事实键 |
| L1-PG-08-schema-grant | pending | 不创建共享 PostgreSQL 的额外角色 |
| L1-RD-01-key-ops | order_service/cache.py:22 | 只清理 DB-06 自有 Redis 前缀 |
| L1-RD-02-string | order_service/cache.py:66 | 用字符串键保存短期负缓存 |
| L1-RD-03-list | order_service/cache.py:124 | 维护有界订单活动列表 |
| L1-RD-04-hash | order_service/cache.py:60 | 用 Hash 缓存订单字段 |
| L1-RD-05-set-zset | order_service/cache.py:130 | 用有序集合按金额排列订单 |
| L1-RD-06-expire-evict | order_service/cache.py:98 | 为缓存设置 TTL |
| L1-RD-07-multi-exec | order_service/cache.py:98 | 事务管道原子写缓存、过期和计数 |
| L1-RD-08-pubsub | pending | 单进程流程没有独立订阅者 |
| L1-SQ-01-type-affinity | order_service/snapshot.py:20 | SQLite 按列亲和性保存快照 |
| L1-SQ-02-crud | order_service/snapshot.py:20 | 重建并查询离线订单快照 |
| L1-SQ-03-txn-wal | order_service/snapshot.py:20 | WAL 下事务化写本地快照 |
| L1-SQ-04-index | order_service/snapshot.py:32 | 为租户快照建立复合索引 |
| L1-SQ-05-view-trigger | order_service/snapshot.py:32 | 视图和触发器维护快照计数 |
| L1-SQ-06-attach | order_service/snapshot.py:45 | 独立 ATTACH 本地配置库 |
| L1-SQ-07-json1 | order_service/snapshot.py:21 | JSON1 读取快照状态字段 |
| L1-SQ-08-vacuum-backup | order_service/snapshot.py:79 | VACUUM INTO 并校验备份完整性 |
| L2-01-pool-timeout | order_service/order.py:20 | 有界应用连接池在耗尽时超时 |
| L2-02-slow-query | pending | 不制造人为慢查询 |
| L2-03-index-not-used | pending | 不故意构造索引失效扫描 |
| L2-04-txn-boundary-deadlock | pending | 不创建竞争写事务或死锁 |
| L2-05-cache-consistency | order_service/cache.py:120 | 状态更新后失效缓存并从 MySQL 重建 |
| L2-06-batch-pagination | order_service/order.py:188 | 订单和报表采用有序限量分页 |
| L2-07-backup-restore-drill | order_service/snapshot.py:87 | 在线备份后校验可恢复快照 |
| L2-08-schema-migration | order_service/order.py:78 | 记录项目 schema 迁移版本 |
| L2-09-least-privilege | order_service/order.py:78 | 订单应用账号仅获项目库 DML 权限 |
| L2-10-conn-security | pending | 共享 compose 没有 TLS 连接端点 |
| L2-11-metrics | run.py:150 | 维护并检查缓存命中指标 |
| L2-12-data-integrity | order_service/order.py:79 | 主外键、唯一键和 CHECK 约束保护数据 |
| L2-13-lock-wait | pending | 不竞争共享 MySQL 行锁 |
| L2-14-big-table-ddl | pending | 不在共享库执行大表 DDL |
| L2-15-db-selection | run.py:154 | 按数据职责分别访问五种数据库 |
| L3-01-mysql-replication | pending | 没有第二个 MySQL 实例 |
| L3-02-mysql-partition | pending | 项目只对 PostgreSQL 报表按日分区 |
| L3-03-pg-logical-replication | pending | 没有逻辑复制订阅实例 |
| L3-04-mongo-replica-set | pending | 共享 MongoDB 是 standalone |
| L3-05-redis-persistence | pending | 不重启共享 Redis 验证 AOF 恢复 |
| L3-06-redis-sharding | pending | 共享 Redis 只有一个节点 |
| L3-07-shard-strategy | pending | 项目未部署多分片或跨片路由 |
| L3-08-distributed-lock | order_service/cache.py:27 | SET NX EX 加锁并以持有者校验释放 |
| L3-09-cache-breakdown | order_service/cache.py:64 | Bloom 过滤、负缓存、互斥重建和分散 TTL |
| L3-10-archive-cold-hot | pending | 没有独立冷存储和冷热迁移 |
| L3-11-tls-end-to-end | pending | 共享服务没有可控 TLS 端点 |
| L3-12-audit-log | pending | 应用行为日志不是数据库原生审计日志 |
| L4-01-order-modeling | order_service/order.py:79 | 订单头、明细、状态机和金额快照 |
| L4-02-composite-index | order_service/order.py:79 | 租户、软删除标记和订单键的复合索引 |
| L4-03-cache-pattern | order_service/cache.py:55 | Cache-Aside 热读及冷读重建 |
| L4-04-idempotency | order_service/order.py:80 | 唯一幂等键与请求载荷绑定 |
| L4-05-multi-tenant | order_service/order.py:80 | 查询和快照均按租户隔离 |
| L4-06-timeseries | order_service/report.py:71 | 固定日期事实表和日分区报表 |
| L4-07-doc-vs-relational | order_service/audit.py:16 | 订单关系模型与行为文档分库存储 |
| L4-08-counter-ranking | order_service/cache.py:130 | Redis ZSET 按租户建立订单排行 |
| L4-09-soft-delete | order_service/order.py:80 | 软删除保留历史并从活动查询排除 |
| L4-10-report-aggregation | order_service/report.py:71 | PostgreSQL 物化日聚合报表 |
