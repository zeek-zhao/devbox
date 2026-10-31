# L1-009-template-constraints

<!-- coverage: pending -->

## 考点
对应 KP-L1-09：C++20 `requires` 检查类型是否提供 `size()`。
`has_size_v<std::string>` 为 `true`、`has_size_v<int>` 为 `false`，表示约束判定符合预期。
用布尔结果观察不满足约束的类型，不需要编写会导致编译失败的调用。

## 易错点
只检查类型而不检查表达式，可能让不支持 `size()` 的类型通过约束。
对不满足要求的类型直接实例化受约束函数会使程序无法编译。
把所需操作写进 `requires` 表达式，并通过特征值验证约束结果。

## 延伸
继续为 `size()` 的结果添加返回类型要求，收紧模板可接受的类型。
可探索标准库 concepts 如何组合表达更复杂的模板约束。

## 复现
TAG=latest scripts/run-example.sh cpp L1-009-template-constraints
