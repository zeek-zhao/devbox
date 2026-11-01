
# L1-RD-04-hash · 哈希

## 考点
- HSET 写入字段，HINCRBY 对整数值原子递增。
- HGETALL 与 HSCAN 的字段值相同，并在输出前按字段名排序。
- HDEL 删除指定字段，OBJECT ENCODING 展示小 hash 的 listpack 编码。

## 为什么这么写
字段值都很短且字段数小于默认 listpack 阈值，确保本例使用小 hash 编码；SCAN 结果主动排序，避免字段顺序变化。

## 易错点
- HGETALL 返回的是映射而不是稳定有序列表。
- HINCRBY 要求字段可解析为整数；对任意文本字段递增会报错。
- hash 为空后再读 HLEN 得到 0，不代表 key 清理过整个 Redis。

## 依赖服务
`redis`

## 命名空间
`l1-rd-04:*`
