<!-- coverage: pending -->

# L4-03-cache-pattern · 缓存一致性模式

## 考点
- 两个 Python 线程通过 barrier 同时提交版本 1/2 写入，分别执行 Cache-Aside、Write-Through、Write-Behind。
- 逐模式比较数据库版本/值与缓存值；版本条件保证最终保留较新的写。
- Cache-Aside 仅失效缓存，Write-Through 同步写缓存，Write-Behind 先排队再按版本落库。
- 让 Cache-Aside key 到期后回源数据库，证明 TTL 是缓存丢失时的恢复兜底而非一致性保证。

## 为什么这么写
并发写用固定版本而非线程完成顺序来确定期望结果；Write-Through 用 Redis Lua 原子比较版本，Write-Behind 使用按版本排序的队列。无并发读时，Cache-Aside 在写入完成后回源并填充最终值。

## 易错点
- 串行调用两次不能暴露并发竞态；本例的两个 writer 在 barrier 后同时开始。
- 不做版本比较时，较旧写可能最后覆盖缓存或数据库，不能仅凭「线程执行完」声称一致。
- 示例不模拟读写期间的缓存穿透窗口，也不把它当作一致性保证。

## 依赖服务
`mysql`、`redis`

## 命名空间
MySQL `db_l4_03_cache_pattern`；Redis 前缀 `l4_03_cache_pattern:`
