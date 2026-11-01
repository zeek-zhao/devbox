<!-- coverage: pending -->

# L3-003-memory-pool —— 固定大小块的复用

## 考点

- 从固定块池中分配和释放对象。
- 验证释放的块可以再次分配，并且仍与未释放块不同。

## 为什么这么写

块用 `max_align_t` 联合体承载，保证存储适用于任意基本类型；输出关系而非进程相关地址。

## 易错点

- 块步长必须满足 `max_align_t` 对齐。
- 释放块不能仍处于空闲链中，否则会重复分配同一块。

## 运行

```bash
TAG=latest scripts/run-example.sh c L3-003-memory-pool
```
