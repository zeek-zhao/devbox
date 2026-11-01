# DB-06 覆盖表

| 用例ID | 落点 | 说明 |
|---|---|---|
| L1-MG-01-doc-collection | order_service/audit.py:16 | 按固定日期建立行为事件集合 |
| L1-MG-02-crud | order_service/audit.py:22 | 写入、更新并查询独立行为文档 |
| L1-MG-03-query-operators | order_service/audit.py:43 | 按租户和事件序号范围查询 |
| L1-MG-04-aggregation | order_service/audit.py:43 | 对事件类型分组计数并排序 |
| L1-MG-05-index | order_service/audit.py:16 | 为租户和事件序号建立复合索引 |
| L1-MG-06-user-role | exempt | 订单服务使用部署预置 MongoDB 身份，不管理全局用户或角色生命周期 |
| L1-MG-07-dump-restore | exempt | 行为集合按命名空间重建，无 Mongo 导出/恢复流程；离线恢复针对 SQLite 快照 |
| L1-MG-08-replica-concept | exempt | Mongo 行为日志可重建且订单真相在 MySQL，不需要 Mongo 副本集选举 |
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
| L1-PG-08-schema-grant | exempt | 使用部署预置 PostgreSQL 身份，只访问项目报表 schema，不管理全局角色或授权 |
| L1-RD-01-key-ops | order_service/cache.py:22 | 只清理 DB-06 自有 Redis 前缀 |
| L1-RD-02-string | order_service/cache.py:66 | 用字符串键保存短期负缓存 |
| L1-RD-03-list | order_service/cache.py:124 | 维护有界订单活动列表 |
| L1-RD-04-hash | order_service/cache.py:60 | 用 Hash 缓存订单字段 |
| L1-RD-05-set-zset | order_service/cache.py:130 | 用有序集合按金额排列订单 |
| L1-RD-06-expire-evict | order_service/cache.py:98 | 为缓存设置 TTL |
| L1-RD-07-multi-exec | order_service/cache.py:98 | 事务管道原子写缓存、过期和计数 |
| L1-RD-08-pubsub | exempt | 单进程流程无独立订阅者，行为事件写入 MongoDB 持久记录而非临时广播 |
| L1-SQ-01-type-affinity | order_service/snapshot.py:20 | SQLite 按列亲和性保存快照 |
| L1-SQ-02-crud | order_service/snapshot.py:20 | 重建并查询离线订单快照 |
| L1-SQ-03-txn-wal | order_service/snapshot.py:20 | WAL 下事务化写本地快照 |
| L1-SQ-04-index | order_service/snapshot.py:32 | 为租户快照建立复合索引 |
| L1-SQ-05-view-trigger | order_service/snapshot.py:32 | 视图和触发器维护快照计数 |
| L1-SQ-06-attach | order_service/snapshot.py:45 | 独立 ATTACH 本地配置库 |
| L1-SQ-07-json1 | order_service/snapshot.py:21 | JSON1 读取快照状态字段 |
| L1-SQ-08-vacuum-backup | order_service/snapshot.py:79 | VACUUM INTO 并校验备份完整性 |
| L2-01-pool-timeout | order_service/order.py:20 | 有界应用连接池在耗尽时超时 |
| L2-02-slow-query | exempt | 有界且带索引的业务查询不人为制造慢查询，报表仅使用固定小型数据集 |
| L2-03-index-not-used | exempt | 业务查询必须沿租户和业务键索引执行，索引失效扫描违反项目性能路径 |
| L2-04-txn-boundary-deadlock | exempt | 订单写入按单事务顺序执行，无竞争写事务或死锁恢复需求 |
| L2-05-cache-consistency | order_service/cache.py:120 | 状态更新后失效缓存并从 MySQL 重建 |
| L2-06-batch-pagination | order_service/order.py:188 | 订单和报表采用有序限量分页 |
| L2-07-backup-restore-drill | order_service/snapshot.py:87 | 在线备份后校验可恢复快照 |
| L2-08-schema-migration | order_service/order.py:78 | 记录项目 schema 迁移版本 |
| L2-09-least-privilege | order_service/order.py:78 | 订单应用账号仅获项目库 DML 权限 |
| L2-10-conn-security | exempt | 本地 Compose 教学服务不提供外部连接端点，TLS 终止和传输策略由部署层负责 |
| L2-11-metrics | run.py:150 | 维护并检查缓存命中指标 |
| L2-12-data-integrity | order_service/order.py:79 | 主外键、唯一键和 CHECK 约束保护数据 |
| L2-13-lock-wait | exempt | 并发互斥由 Redis 锁协调，不以 MySQL 行锁等待协调请求 |
| L2-14-big-table-ddl | exempt | 使用固定小数据集和显式版本迁移，不在共享库执行大表 DDL |
| L2-15-db-selection | run.py:154 | 按数据职责分别访问五种数据库 |
| L3-01-mysql-replication | exempt | 单一 MySQL 是订单唯一写入真相，没有只读流量或副本一致性需求 |
| L3-02-mysql-partition | exempt | 时间序列报表由 PostgreSQL 日分区承担，MySQL 订单表是小型 OLTP 表 |
| L3-03-pg-logical-replication | exempt | 报表由应用直接写入，没有独立下游订阅者或跨实例发布需求 |
| L3-04-mongo-replica-set | exempt | Mongo 仅保存可重建行为事件，订单业务不依赖其选举或写确认 |
| L3-05-redis-persistence | exempt | Redis 仅保存可从 MySQL 重建的缓存、锁和排行，不承载唯一持久数据 |
| L3-06-redis-sharding | exempt | 单一订单服务不按 Redis 槽拆分权威数据，缓存从 MySQL 重建，不部署 Cluster 路由 |
| L3-07-shard-strategy | exempt | tenant_key 采用行级隔离，订单集中在单库，不需要跨物理分片路由 |
| L3-08-distributed-lock | order_service/cache.py:27 | SET NX EX 加锁并以持有者校验释放 |
| L3-09-cache-breakdown | order_service/cache.py:64 | Bloom 过滤、负缓存、互斥重建和分散 TTL |
| L3-10-archive-cold-hot | exempt | 无独立对象存储、保留期迁移或冷读接口，不实现冷热存储生命周期 |
| L3-11-tls-end-to-end | exempt | 项目仅用本机 Compose 网络且不管理数据库证书或 TLS 终止 |
| L3-12-audit-log | exempt | Mongo 记录应用行为而非 DBA 操作，项目不管理数据库原生审计策略 |
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
