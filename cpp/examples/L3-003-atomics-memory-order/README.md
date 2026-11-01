# L3-003-atomics-memory-order


## 考点
对应 KP-L3-03：生产者先写普通数据，再用 release 原子标志发布它。
消费者以 acquire 读取标志后打印载荷，能看到发布值即说明建立了 happens-before。

## 易错点
只使用 relaxed 标志不会发布关联的普通数据；以 release store 和 acquire load 配对。
不等待标志就读取载荷会造成数据竞争；循环等待同步状态后再读，并在主线程 join。

## 延伸
比较 release/acquire 与互斥锁在任务状态发布中的表达方式。
继续研究 acquire-release 读改写操作，以及多个发布者时所需的同步关系。

## 复现
TAG=latest scripts/run-example.sh cpp L3-003-atomics-memory-order
