# L1-031-volatile-publication


## 考点
对应 KP-JV-L1-31：volatile 写入发布先前的普通字段写入。
看到读取线程观察到 ready 后稳定读出 payload=42，且等待超时会失败，即掌握可见性边界。
字节码还显示 volatile 自增由读、加、写组成，而不是原子操作。

## 易错点
共享 volatile 计数仍可能丢更新，因为 volatile 不合并读改写。
只用 volatile 发布状态；计数改用锁或 AtomicInteger，并对等待设超时、超时报告失败。

## 延伸
用 AtomicInteger 做并发计数，并比较其原子更新与 volatile 状态发布的不同职责。
继续学习 Java 内存模型中的 happens-before 规则及锁的发布语义。

## 复现
TAG=latest scripts/run-example.sh java L1-031-volatile-publication
