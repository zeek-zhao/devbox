# L1-005-control-flow

<!-- coverage: pending -->

## 考点
对应 KP-GO-L1-05：用 if、for 和 switch 处理边界、匹配、默认分支与有限循环。
正确分类并在明确 break 条件结束迭代，说明控制流边界清晰。

## 易错点
Go 只有 `for` 循环；无终止条件的循环会持续运行。
设置明确的循环边界或 break 条件，避免意外无限迭代。

## 延伸
将边界条件用于查询过滤，并遍历一批固定输入。
为 switch 的匹配与默认分支分别提供输入测试。

## 复现
TAG=latest scripts/run-example.sh go L1-005-control-flow
