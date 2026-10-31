# L4-016-iterator

<!-- coverage: pending -->

## 考点

对应 KP-GO-L4-16：提供顺序访问聚合元素的统一方式，不暴露内部结构。

可观察判据：自定义 `Next() (T, bool)` 遍历得到固定序列，耗尽后返回 `false`。

## 为什么这样写

`main.go` 第 5–18 行让聚合返回迭代器接口，游标和元素快照保存在具体迭代器中；
第 20–26 行检查边界、递增游标并返回元素与状态。
第 31–44 行的遍历只调用 `Next`，没有读取聚合的内部切片；
耗尽时和耗尽后各调用一次，还创建独立迭代器验证新游标从头开始。
若拆掉边界检查，`exhausted: false` 之前会发生越界 panic；
若复用耗尽游标，`new iterator: go true` 会变成空值和 false。

## 怎么跑

```bash
TAG=latest bash scripts/run-example.sh go L4-016-iterator
```
