# L4-007-bridge

<!-- coverage: pending -->

## 考点

对应 KP-JV-L4-07：把抽象与实现分离成两个独立继承体系，二者可独立扩展。

可观察判据：抽象类持有 `Implementor` 引用，四种组合各输出固定标签。

## 为什么这样写

`src/Main.java` 第 20–50 行的 `Report` 抽象类持有构造器注入的 `Implementor`，
报告格式由 `TextReport`、`JsonReport` 扩展，来源由 `MemorySource`、`FileSource` 扩展。
第 52–62 行实际组装两个维度的四种组合，通过 `Report` 父类型调用 `render()`。
若基类构造器不接收实现而写死 `new MemorySource()`，第二行 `text/file`
变为 `text/memory`，第四行同样失去 file，直接暴露实现维度被锁死。

## 怎么跑

```bash
TAG=latest bash scripts/run-example.sh java L4-007-bridge
```
