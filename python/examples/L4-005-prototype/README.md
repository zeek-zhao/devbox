# L4-005-prototype

<!-- coverage: exempt 本项目逐行读取不可变 Record 并重新汇总 Group，不从预配置的可变对象克隆作业；复制报表原型会额外引入跨调用状态隔离问题 -->

## 考点

对应 KP-PY-L4-05：通过克隆已有实例创建新对象，避免重复执行昂贵构造。

可观察判据：用 `copy.deepcopy` 或自定义 `clone()`，副本的内层列表与原对象互不影响。

## 为什么这样写

代码位置：`main.py:4-12` 定义构造计数与克隆，`main.py:15-27` 验证双向修改隔离。

`main.py` 的 `clone()` 用 `return deepcopy(self)` 克隆现有配置，而非再次调用构造器。
入口比较对象及内层列表身份，分别向副本第一组与原对象第二组追加数据，再输出双方内容。
若换成浅拷贝，`independent inner lists: True` 会变为 `False`，
`original:` 会混入 `copy-only`，`clone:` 会混入 `original-only`。
构造计数在 `__init__` 增加；若克隆重新构造实例，`constructor calls: 1` 会变为 `2`。

## 怎么跑

```bash
TAG=latest bash scripts/run-example.sh python L4-005-prototype
```
