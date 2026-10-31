# L4-004-builder

<!-- coverage: pending -->

## 考点

对应 KP-JV-L4-04：用链式步骤逐步构造复杂对象，最终 `build()` 一次性产出结果。

可观察判据：静态内部 `Builder` 链式设置后 `build()` 返回不可变对象；缺必填项抛 `IllegalStateException`。

## 为什么这样写

`src/Main.java` 第 24–53 行的 `Query.Builder` 链式收集必填词、可选上限与字段，
`build()` 验证必填项后调用私有构造器；`Query` 为 final 类、字段为 private final、
不提供 setter，并以 `List.copyOf` 隔离可变集合。
第 56–74 行构建后修改建造者，第二行仍保持原结果；若直接共享字段列表，该行会多出 `body`。
随后真实尝试修改结果列表和缺项构建，分别捕获精确异常；去掉保护会触发断言错误，
而非打印假成功。

## 怎么跑

```bash
TAG=latest bash scripts/run-example.sh java L4-004-builder
```
