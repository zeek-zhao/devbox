# L4-010-facade


## 考点

对应 KP-PY-L4-10：用单一入口封装子系统多个步骤，调用方不感知内部协作。

可观察判据：外观类聚合三个子系统，一次调用产生固定顺序输出。

## 为什么这样写

代码位置：`main.py:1-21` 实现三个子系统，`main.py:24-33` 聚合并编排，`main.py:36-39` 单次调用。

`main.py` 的 `SearchFacade.__init__` 聚合 `Parser`、`Indexer`、`Renderer`；
`run()` 的三行调用依次传递真实的词列表和计数字典，不只是打印步骤标签。
入口只调用一次 `facade.run(...)`，不获取或手动调用子系统。
若跳过解析，`parse:` 行消失；若跳过索引，`index:` 行消失且渲染拿不到计数；
若索引不统计重复词，`render: patterns=1, python=2` 会变化。
输出由各子系统实际执行时产生，因此顺序变化或缺步骤都会使期望文本不匹配。

## 怎么跑

```bash
TAG=latest bash scripts/run-example.sh python L4-010-facade
```
