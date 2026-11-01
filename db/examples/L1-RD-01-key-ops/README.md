<!-- coverage: pending -->

# L1-RD-01-key-ops · key 操作

## 考点
- 对本用例前缀执行 SET、TYPE、EXISTS、DEL，并核对删除前后的状态。
- EXPIRE/TTL 只断言 TTL 为正数；PERSIST 后断言 TTL 为 -1。
- 用 SCAN 按前缀找 key，排序后输出，避免依赖游标返回顺序。

## 为什么这么写
使用 Redis Python 客户端逐页遍历 SCAN，并通过 `UNLINK` 仅清理本用例 key；TTL 输出判定而非变化中的原始秒数。

## 易错点
- SCAN 可能重复返回 key，且顺序不固定；不要把单次扫描结果当全局有序结果。
- DEL/EXISTS 返回整数，key 不存在时为 0。
- 不可使用 KEYS 阻塞共享实例，也不可使用 FLUSHDB/FLUSHALL。

## 依赖服务
`redis`

## 命名空间
`l1-rd-01:*`
