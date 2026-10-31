# L1-011-maps-comma-ok


## 考点
对应 KP-GO-L1-11：用 comma-ok 区分不存在的键与值为零的键。
看到删除后查找为 false，且排序后的键值稳定输出，说明掌握了 map 查找与遍历。

## 易错点
map 遍历顺序不保证，并发写入还可能 panic。
先排序键再比较输出；跨 goroutine 访问时用同步保护。

## 延伸
将 map 用作词项到文档列表的索引，并按词项排序生成稳定摘要。
为共享 map 增加互斥锁，再验证并发读写边界。

## 复现
TAG=latest scripts/run-example.sh go L1-011-maps-comma-ok
