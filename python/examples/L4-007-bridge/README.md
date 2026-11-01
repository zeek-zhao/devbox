# L4-007-bridge

<!-- coverage: exempt 本项目报表只使用标准库文本表格，没有 HTML、终端或远端等独立实现后端；summary 与 report 是输出策略差异而非两套需正交扩展的继承维度 -->

## 考点

对应 KP-PY-L4-07：把抽象与实现分离成两个独立继承体系，二者可独立扩展。

可观察判据：抽象类持有实现对象，四种组合输出固定字符串。

## 为什么这样写

代码位置：`main.py:4-17` 定义实现体系，`main.py:20-36` 定义抽象体系，`main.py:43-46` 运行四种组合。

`main.py` 的 `DataSource` 体系负责数据，`Report` 体系负责格式；
`Report.__init__` 中的 `self._source = source` 是桥接点。
两个报表子类都通过抽象数据接口 `self._source.read()` 获取内容，不选择具体来源。
入口双层循环实际运行两种来源与两种格式的四种组合，`display()` 仅依赖 `Report`。
若报表内部写死内存来源，`plain:file-data` 和 `[file-data]` 都会变成内存内容。
这里的 `FileSource` 返回固定文件来源样本，不依赖磁盘或网络，保留独立实现维度。

## 怎么跑

```bash
TAG=latest bash scripts/run-example.sh python L4-007-bridge
```
