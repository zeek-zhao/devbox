# L1-013-iterator-protocol


## 考点
对应 KP-PY-L1-13：实现 `__iter__` 与 `__next__`，并在迭代结束时抛出 `StopIteration`。
遍历能输出作为数据的 `None`，随后明确观察到迭代结束，即说明掌握了耗尽语义。

## 易错点
用 `None` 表示耗尽会把合法数据误判为结束，导致数据丢失。
让迭代器在耗尽时抛出 `StopIteration`；可重用容器则应每次提供新的迭代器。

## 延伸
为大型输入记录实现可重复遍历的容器，并分别创建两个独立迭代器。
将迭代器用于流式读取，验证消费一条记录不会预先加载后续记录。

## 复现
TAG=latest scripts/run-example.sh python L1-013-iterator-protocol
