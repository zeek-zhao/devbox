# L3-06-redis-sharding · Redis 分片

<!-- coverage: exempt DB-06 是单一订单写入服务，订单权威数据不按 Redis 槽位拆分，且缓存可从 MySQL 重建；项目不部署 Redis Cluster 路由。 -->

## 考点

Cluster 槽位、CRC16、MOVED/ASK 重定向、客户端分片

## 判据（验收按这一条核对）

输出真实三主 Redis Cluster 状态、槽覆盖、MOVED 重定向后的读结果、hash-tag 同槽和副本故障切换结论。

## 为什么这么写

用本例脚本独立启动三主 Redis Cluster，建满全部槽，分别触发 MOVED 客户端重定向与迁移槽的 ASK 服务端响应，并临时加入一个副本验证主节点故障切换。输出只包含固定结论，不包含随机节点 ID 或槽数值；退出时删除三个集群节点和临时副本。

## 易错点

- CRC16 取模必须是 16384，hash-tag 只在 `{}` 非空时生效。
- 本例以 Redis 的实际 MOVED 响应及 cluster-aware 客户端读验证 MOVED，以迁移槽的 ASK 响应验证 ASK；临时副本用于验证原主槽位接管。

## 依赖服务

`docker`, `redis:7-alpine` image (from the compose profile)

## 命名空间

`l3_06_redis_sharding`（用例开始时必须自己清理，保证可重复运行）

## 契约

- `run.sh` 在宿主用 Compose 启动集群 profile，并在容器网络中直接运行 Redis CLI
- stdout 必须确定：显式 `ORDER BY`、不打时间戳、不打耗时
- 交付前必须自己跑一次 `bash db/scripts/run-example.sh db L3-06-redis-sharding --update` 生成 `expected.txt`，
  并**人工确认输出确实体现了上面的考点**（不是「跑通就算」）
- 本例与 DB-06 项目接入的豁免理由见顶部声明；本例本身仍完整运行和验证真实集群行为。
