# L4-004-builder

<!-- coverage: pending -->

## 考点

对应 KP-L4-04：用链式步骤逐步构造复杂对象，最终 `build()` 一次性产出结果。

可观察判据：链式调用设置三个字段后 `build()` 返回对象且字段值固定；漏设必填项时 `build()` 返回错误或抛出可捕获异常。

## 为什么这样写

`main.cpp` 第 14–25 行的设置步骤返回建造者引用，第 26–34 行检查必填查询与正数限制，并按值产出独立的 `Request`。
第 44–47 行链式设置三个字段，随后修改建造者再打印已完成对象，输出仍为 `request: cpp, 3, json`。
若结果引用建造者内部状态，查询会变成 `changed`；若移除必填检查，第 48–54 行不再输出 `build error: query is required`，而是报意外成功并非零退出。

## 怎么跑

```bash
TAG=latest bash scripts/run-example.sh cpp L4-004-builder
```
