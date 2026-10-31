# L4-006-adapter

<!-- coverage: pending -->

## 考点

对应 KP-PY-L4-06：把不兼容的既有接口包装成调用方期望的接口，且不修改被适配方。

可观察判据：适配器类持有旧对象并实现目标方法，转发后输出与直接调用旧方法一致。

## 为什么这样写

代码位置：`main.py:4-20` 定义旧接口、目标接口与适配器，`main.py:23-38` 验证转发及旧对象未变。

`main.py` 的 `SearchAdapter.__init__` 保存旧对象，`search()` 中
`return self._legacy.lookup(term)` 将目标接口转发到旧接口。
`client(search: Search, ...)` 只调用目标方法；入口比较同一输入的直接调用与适配调用。
若去掉转发或改变传入参数，`adapted: legacy:PYTHON` 与 `same result: True`
会变化或调用报错。`not hasattr(legacy, "search")` 行也实际验证旧对象未被猴子补丁修改，
修改旧类会让 `legacy unchanged: True` 变为 `False`。

## 怎么跑

```bash
TAG=latest bash scripts/run-example.sh python L4-006-adapter
```
