# L3-006-atomics-ordering

<!-- coverage: pending -->

## 考点
对应 KP-RS-L3-06：用 `SeqCst` 原子计数，并以 Release/Acquire 发布完成状态。
看到固定计数和互斥保护后读取的普通数据，说明计数原子性没有被误当作数据保护。

## 易错点
会认为原子计数自动保护关联的普通数据，造成数据竞争；分别为计数和数据发布建立适当同步关系。
完成标记的 Release/Acquire 建立发布关系，普通可变数据仍通过互斥量保护。

## 延伸
比较不同原子内存序能表达的同步关系，并用并发测试检查状态机边界。
将计数与任务完成标记拆开设计，明确每个共享变量各自依赖的同步机制。

## 复现
TAG=latest scripts/run-example.sh rust L3-006-atomics-ordering
