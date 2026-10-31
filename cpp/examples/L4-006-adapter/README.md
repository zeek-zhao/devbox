# L4-006-adapter

<!-- coverage: pending -->

## 考点

对应 KP-L4-06：把不兼容的既有接口包装成调用方期望的接口，且不修改被适配方。

可观察判据：适配器类实现目标接口并持有旧类实例，调用目标方法输出旧类方法的结果。

## 为什么这样写

`main.cpp` 第 6–13 行的旧接口只提供 `fetch_record()`，第 15–19 行的目标接口要求 `execute()`。
第 21–28 行的适配器按值持有旧类，第 24 行直接委托旧方法，不复制其业务逻辑。
第 31–36 行通过两个 `unique_ptr<Query>` 调用目标虚函数，结果来自不同旧实例的状态。
若拆掉委托并返回固定的第一条记录，第二行 `legacy: record-9` 会错误地变成 `legacy: record-7`；旧方法的返回格式改动也会自然反映到目标接口输出。

## 怎么跑

```bash
TAG=latest bash scripts/run-example.sh cpp L4-006-adapter
```
