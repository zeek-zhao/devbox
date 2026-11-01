
# L1-RD-05-set-zset · 集合与有序集合

## 考点
- 两个集合分别演示交集、并集和差集。
- ZADD 写入分数后，用 ZREVRANGE 取前两名、ZRANGEBYSCORE 过滤区间并查成员排名。
- 同分成员按 Redis 字典序确定顺序。

## 为什么这么写
集合结果在输出前排序；有序集合用固定分数，前 N 名包含同分成员以显示字典序规则。

## 易错点
- SINTER/SDIFF 等集合运算返回无序集合，不能直接输出。
- ZRANK 从 0 开始且按分数升序；ZREVRANGE 是降序。
- ZRANGEBYSCORE 的上下界默认包含端点。

## 依赖服务
`redis`

## 命名空间
`l1-rd-05:*`
