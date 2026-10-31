# L4-009-decorator

<!-- coverage: pending -->

## 考点

对应 KP-PY-L4-09：用包装对象在运行时叠加职责，替代为每种组合派生一个子类。

可观察判据：装饰器类实现同一接口并持有被装饰对象，两层叠加后输出固定文本。

## 为什么这样写

代码位置：`main.py:18-33` 定义包装与叠加职责，`main.py:36-46` 通过统一接口显示不同组合。

`main.py` 的 `MessageDecorator(Message)` 在 `self._wrapped = wrapped` 行持有被装饰对象，
`render()` 转发；`Brackets` 与 `Prefix` 在 `super().render()` 的结果上增加职责。
`display(message: Message)` 对原对象、单层与双层包装一视同仁，入口还反转叠加顺序。
若移除内层包装，`audit:[python]` 会变成 `audit:python`；
若移除外层，结果变成 `[python]`。最后一行再次显示原对象，证明包装未修改它。
这是持有对象、保持对象接口的**类装饰器模式**，不是 Python 的
`@decorator` 函数装饰器语法；`@abstractmethod` 仅用于声明抽象接口。

## 怎么跑

```bash
TAG=latest bash scripts/run-example.sh python L4-009-decorator
```
