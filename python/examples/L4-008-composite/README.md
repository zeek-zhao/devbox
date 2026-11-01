# L4-008-composite


## 考点

对应 KP-PY-L4-08：把叶子与容器统一成同一接口，递归组合后可整体操作。

可观察判据：叶子与容器共用同一接口，`render()` 递归输出固定文本。

## 为什么这样写

代码位置：`main.py:4-29` 定义统一接口及递归委托，`main.py:32-46` 构造嵌套树并统一显示。

`main.py` 的 `Leaf` 和 `Group` 都实现 `Component.render()`；
容器的 `list[Component]` 同时保存叶子和子容器，不按具体类型分支。
`lines.extend(child.render(depth + 1) ...)` 行递归委托给统一接口，
入口构造三层容器，再用同一个 `display(component: Component)` 显示整树和独立叶子。
若取消递归调用，`singleton.py`、`structural/` 和 `composite.py` 的输出会缺失；
若不传递深度，这些行的缩进会变化。该缩进是业务输出，必须逐字保留。

## 怎么跑

```bash
TAG=latest bash scripts/run-example.sh python L4-008-composite
```
