# L1-021-custom-iterator

<!-- coverage: pending -->

## 考点
对应 KP-RS-L1-21：实现 `Iterator::next`，用 `Some` 交出编号、用 `None` 结束。
看到收集结果 `[21, 22, 23]`、耗尽后三次均为 `true`、空范围为 `None`，说明终止状态正确。

## 易错点
耗尽后继续返回重复或无效值，会使收集无法结束，因为迭代结束信号错误。
先检查排他上界，只有返回元素时推进状态；达到终止条件后稳定返回 `None`。

## 延伸
在毕业项目中用同样的状态机生成固定范围的文档编号，避免生成上界编号。
增加起点大于终点的输入，验证空范围仍能稳定终止。

## 复现
TAG=latest scripts/run-example.sh rust L1-021-custom-iterator
