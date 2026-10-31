# L4-006-adapter

<!-- coverage: pending -->

## 考点

对应 KP-JV-L4-06：把不兼容的既有接口包装成调用方期望的接口，且不修改被适配方。

可观察判据：对象适配器持有目标实例并实现新接口，转发结果固定；类适配器用继承实现同一效果。

## 为什么这样写

`src/Main.java` 第 6–10 行的旧类 `LegacySearch` 只有 `lookup`，并不实现新接口 `Query`。
第 12–23 行的 `ObjectAdapter` 持有外部注入的旧实例，将 `find` 转发到 `lookup`；
第 25–30 行的 `ClassAdapter` 继承旧类并实现同一新接口，旧类有意不标 final 以允许这种形式。
`main` 通过 `Query` 引用调用两种适配器，并对另一输入比较结果。
若对象适配器不转发参数而固定查询别的词，第一行的 `legacy[java]` 会改变，
第三行的一致性也会失败；删除类适配器的 `find` 实现则无法编译。

## 怎么跑

```bash
TAG=latest bash scripts/run-example.sh java L4-006-adapter
```
