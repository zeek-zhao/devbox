# L4-016-iterator

<!-- coverage: pending -->

## 考点

对应 KP-PY-L4-16：提供顺序访问聚合元素的统一方式，不暴露内部结构。

可观察判据：实现 `__iter__`/`__next__`，`list(it)` 得到固定序列，耗尽后抛 `StopIteration`。

## 为什么这样写

`TokenIndex.__iter__` 的返回行为聚合创建独立游标，调用方不访问内部 tuple。
`TokenIterator.__iter__` 返回自身，`__next__` 的位置递增行推进游标，
边界行明确抛 `StopIteration`。`main()` 先用 `list(iterator)` 耗尽，再两次实际调用 `next()`，
并以新迭代器重新遍历。删除位置递增会令第二行无法完成；耗尽时返回 `None` 会令 `list()` 永不结束，
而不是得到两行异常输出。

## 怎么跑

TAG=latest bash scripts/run-example.sh python L4-016-iterator
