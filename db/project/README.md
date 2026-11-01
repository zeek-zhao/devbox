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

`COVERAGE.md` 登记全部 77 个用例：56 个由项目实际路径接入，另有 21 个逐项说明理由并标记为 `coverage: exempt`。豁免表示这些技术点不属于单一订单服务的部署或业务拓扑，不代表用例未实现；相关数据库概念仍由各自的独立用例验证。

## 完成情况

- 已落地：56 个用例由项目实际路径接入；21 个用例有具体项目形态理由并登记 exempt。
- 自测：`run-example.sh db --all` → 77/77 PASS；项目端到端 → PASS。
- 覆盖：`coverage-check.sh db --strict` → 覆盖 56 个，pending 0 个，exempt 21 个。
- 反向验证：把订单金额输入临时改为不匹配值，端到端断言失败；恢复后原输出通过。
- 发现的问题：无。
- 分库取舍结论：MySQL 保存唯一可写的订单真相，Redis 只做可重建加速，分析、行为和离线读取分别落在更适合其数据形态的 PostgreSQL、MongoDB 与 SQLite。
