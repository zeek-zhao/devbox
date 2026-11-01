
# L1-RD-06-expire-evict · 过期与淘汰

## 考点
- PEXPIRE 设置毫秒级过期并断言 TTL 为正，不输出波动秒数。
- 专用临时 Redis 实例配置 `allkeys-lru`，施加内存压力并检查实际淘汰计数。

## 为什么这么写
maxmemory 是全局配置，不能修改共享 Redis；用带本卡 ID 的临时容器并由 trap 删除。该 Redis 进程的基础内存已接近 1 MiB，因此只在启动隔离实例后临时提高内存上限以准备样本，再降回 1 MiB，并清零统计后验证限额下发生的淘汰。

## 易错点
- 共享 Redis 执行 CONFIG SET 会改变其他用例的行为。
- Redis 基础开销可能超过 1 MiB，初始就写数据会直接 OOM；先准备样本再降限额。
- TTL 是递减值，断言范围即可；不要把精确秒数写入 expected。

## 依赖服务
`redis`；本例另起并清理 `devbox-db-ex-l1-rd-06`

## 命名空间
`l1-rd-06:*`
