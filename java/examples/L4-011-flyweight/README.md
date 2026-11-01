# L4-011-flyweight

<!-- coverage: exempt 每条 Item 仅有唯一 ID 和短 name，无可拆分的昂贵共享内蕴状态；跨实体共享可变对象会破坏不可变快照契约 -->

## 考点

对应 KP-JV-L4-11：共享内在状态、外部状态由调用方传入，避免重复创建大量同质对象。

可观察判据：工厂用 `HashMap` 缓存，相同 key 返回同一引用，构造计数固定。

## 为什么这样写

`src/Main.java` 第 18–24 行的 `TokenFactory.cache` 是真实 `HashMap<String, Token>`，
`computeIfAbsent` 只在未命中时构造；`Token` 的文本为私有 final 内在状态，无 setter，
行列作为 `render` 的外部参数，不存进共享对象。
第 26–37 行用两个值相同但引用不同的字符串取对象，再取不同 key，比较对象引用并输出构造计数。
若去掉缓存而每次 new，第一行变为 `false`，最后一行从 2 变为 3。
同一享元的两次渲染分别为 `java@1:2`、`java@3:4`，证明位置由调用方独立传入。

## 怎么跑

```bash
TAG=latest bash scripts/run-example.sh java L4-011-flyweight
```
