# L4-011-flyweight

<!-- coverage: exempt 本项目按流读取 CSV，聚合字典已按分类保存一次计数和金额；没有大量可共享内在状态的图元对象，金额解析缓存是函数结果缓存而非享元对象池 -->

## 考点

对应 KP-PY-L4-11：共享内在状态、外部状态由调用方传入，避免重复创建大量同质对象。

可观察判据：缓存字典按 key 复用实例，相同 key `is` 为真，构造计数等于不同 key 数。

## 为什么这样写

代码位置：`main.py:6-24` 定义共享状态与缓存，`main.py:27-40` 验证复用、外部位置与构造计数。

`main.py` 的 `TokenFactory.get()` 只在 `key not in self._cache` 时构造 `Token`，
并返回缓存对象。冻结 dataclass 的 `text` 是内在状态，
`render(position)` 的位置是调用方每次传入的外部状态，不保存在共享对象中。
入口用四次取用实际比较两个重复 key 的身份；
`__post_init__` 统计真实构造，最后与输入的 `len(set(keys))` 比较。
若去掉缓存，`same python: True` 和 `same patterns: True` 会变为 `False`，
`constructions: 2` 会变为 `4`。若把位置写死到共享对象里，
同一词元的 `python@0` / `python@2` 就无法正确反映不同外部状态。

## 怎么跑

```bash
TAG=latest bash scripts/run-example.sh python L4-011-flyweight
```
