# L4-016-iterator

<!-- coverage: pending -->

## 考点

对应 KP-JV-L4-16：提供顺序访问聚合元素的统一方式，不暴露内部结构。

可观察判据：实现 `Iterator<T>` 的 `hasNext`/`next`，遍历得到固定序列，耗尽后 `next()` 抛 `NoSuchElementException`。

## 为什么这样写

`src/Main.java` 的 `Sequence<T>` 封装列表，私有 `Cursor` 实现 `Iterator<T>`，
`hasNext` 只比较游标，只有 `next` 的 `position++` 推进。调用方仅拿到
`Iterator<String>`，每轮两次检查 `hasNext` 后才读取，另取游标验证独立位置。
如果 `hasNext` 推进，`visited: alpha, beta, gamma` 会跳项或运行失败；
若移除耗尽检查，真实的额外 `next()` 会抛其他异常或返回元素，
不再输出 `exhausted: NoSuchElementException`。只捕获这一预期异常，
未抛异常则显式失败，不用直接打印异常标签充数。

## 怎么跑

```bash
TAG=latest bash scripts/run-example.sh java L4-016-iterator
```
