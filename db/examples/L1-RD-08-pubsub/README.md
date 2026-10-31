<!-- coverage: pending -->

# L1-RD-08-pubsub · 发布订阅

## 考点
- SUBSCRIBE 与 PSUBSCRIBE 均在发布前等待服务器订阅确认。
- 顺序发布两条消息，验证频道订阅者与模式订阅者收到相同序列。
- 同一前缀下写入 Redis Stream 并读回消息，体现 Stream 可保留消息而 Pub/Sub 不持久化。

## 为什么这么写
订阅确认后才发布，避免靠固定 sleep 祈祷；每次读取均有超时并验证消息序列，异常时用例失败。

## 易错点
- SUBSCRIBE/PSUBSCRIBE 的确认消息不是业务消息；必须先消费确认再统计 payload。
- Pub/Sub 不缓存订阅者断线期间的消息，不能当作持久队列。
- PSUBSCRIBE 会按模式收到频道消息；频道和模式输出分别采集，避免重复误计。

## 依赖服务
`redis`

## 命名空间
`l1-rd-08:*`
