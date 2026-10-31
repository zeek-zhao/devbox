# L4-004-builder

<!-- coverage: pending -->

## 考点

对应 KP-PY-L4-04：用链式步骤逐步构造复杂对象，最终 `build()` 一次性产出结果。

可观察判据：链式方法返回 `self`，`build()` 返回 dataclass 实例；缺必填字段抛 `ValueError`。

## 为什么这样写

代码位置：`main.py:6-33` 定义结果与建造步骤，`main.py:36-54` 验证链式身份、结果与异常。

`main.py` 的 `source()`、`limit()`、`fields()` 都在修改建造者后 `return self`，
入口保存每步返回值并继续调用，实际检查所有步骤的身份。
`build()` 的 `return Query(...)` 一次性产出冻结 dataclass，后续建造者变化不影响旧结果。
若链式方法返回新建造者，`steps return self: True` 会改变且配置可能丢失；
若返回建造者本身，`dataclass instance: True` 会改变。
入口用缺少 source 的建造者真正执行 `build()`，只捕获指定 `ValueError`；
去掉必填检查后不会出现预期的异常输出，且 `else` 会使程序失败。

## 怎么跑

```bash
TAG=latest bash scripts/run-example.sh python L4-004-builder
```
