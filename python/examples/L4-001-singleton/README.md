# L4-001-singleton

<!-- coverage: exempt 本项目每次 CLI 调用独立消费一个 CSV，计数与去重状态必须按调用隔离；没有需要进程全局唯一实例的共享服务 -->

## 考点

对应 KP-PY-L4-01：同一类型全局只存在一个实例，所有取用点看到同一份状态。

可观察判据：用 `__new__` 缓存实例或改用模块级实例；两次构造得到同一对象（`is` 为真），对其中一次赋的属性在另一次可见。

## 为什么这样写

代码位置：`main.py:1-8` 缓存实例，`main.py:11-19` 验证身份与共享状态。

`main.py` 的 `__new__` 中，`super().__new__(cls)` 只在缓存为空时运行，
`return cls._instance` 让后续构造取回原对象；默认属性也只初始化一次。
`main()` 先给 `first.mode` 赋值再构造 `second`，随后实际比较身份、读取共享状态，
并直接计算 `Config() is Config()`。若移除缓存，`same instance: True` 和
`two constructions: True` 会变成 `False`，`second sees: offline` 会变成默认状态。
若每次构造重置属性，身份虽相同，共享状态那行仍会失败。

## 怎么跑

```bash
TAG=latest bash scripts/run-example.sh python L4-001-singleton
```
