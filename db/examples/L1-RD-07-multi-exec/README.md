<!-- coverage: pending -->

# L1-RD-07-multi-exec · 事务

## 考点
- MULTI/EXEC 将写入和递增作为一组命令执行，DISCARD 丢弃排队命令。
- 两个客户端演示 WATCH 冲突：第二个连接改 key 后，第一个连接的 EXEC 返回 nil。
- Lua 脚本原子递增，和客户端排队的 MULTI/EXEC 作对照。

## 为什么这么写
WATCH 必须由两个独立连接交错操作，故使用两个 redis-py 客户端；redis-py 把空 EXEC 转成 WatchError，脚本只将该预期冲突映射为稳定判定。

## 易错点
- 单连接在 WATCH 后自行修改 key，无法制造并发冲突。
- EXEC 返回 nil 表示 WATCH 条件失效，不是空事务成功。
- DISCARD 后要确认写入未发生；只看没有异常不足以证明队列被丢弃。

## 依赖服务
`redis`

## 命名空间
`l1-rd-07:*`
