# L1-030-synchronized-counter


## 考点
对应 KP-JV-L1-30：用同一个 monitor 保护复合读改写操作。
看到两个线程各增 1000 次、join 后结果严格为 2000，即说明完整自增受互斥保护。

## 易错点
`++` 会拆成多步，未互斥时计数可能丢失；不同锁也无法保护同一共享状态。
让所有相关读写都使用同一个锁，不依赖坏例每次都能复现。

## 延伸
将受保护计数用于构建进度更新，并检查读取与写入是否都遵守同一锁约定。
比较 synchronized 与原子计数器在复合状态更新时的适用边界。

## 复现
TAG=latest scripts/run-example.sh java L1-030-synchronized-counter
