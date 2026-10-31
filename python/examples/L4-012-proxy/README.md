# L4-012-proxy

<!-- coverage: pending -->

## 考点

对应 KP-PY-L4-12：用代理对象控制对目标对象的访问，代理与目标实现同一接口。

可观察判据：代理类实现同一接口，转发并计数，输出固定计数。

## 为什么这样写

代码位置：`main.py:4-22` 定义统一接口与计数转发，`main.py:25-39` 验证实际请求结果和访问次数。

`main.py` 的 `RealQuery` 与 `CountingProxy` 都实现 `QueryService`，
代理在 `self._target = target` 行持有目标；显式 `query()` 先增加计数再转发，
不使用 `__getattr__` 全量透传。此例的访问控制职责是统计所有通过代理的访问。
`client(service: QueryService, ...)` 对代理与目标使用同一接口，
入口实际请求三次，并把每次转发结果与直接请求目标的结果比较。
若绕过代理或删除计数，`calls after: 3` 会变为 `0`；
若漏掉转发，`result:PYTHON` / `result:PATTERNS` 会变化或断言失败。
直接调用目标不会增加代理计数，因此最终计数验证的是代理路径而非总查询次数。

## 怎么跑

```bash
TAG=latest bash scripts/run-example.sh python L4-012-proxy
```
