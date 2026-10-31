# L1-015-type-deduction

<!-- coverage: pending -->

## 考点
对应 KP-L1-15：比较 `auto`、`const auto&` 与 `decltype(auto)` 对 const 和引用的推导。
类型特征输出显示 `auto` 得到非 const 值，而引用声明保留 const 引用，现象可直接验证推导结果。

## 易错点
`auto` 通常会丢弃顶层 const 和引用限定；以为它自动保留原类型可能造成意外复制。
需要引用时显式使用引用声明；`decltype(auto)` 还会受表达式是否加括号影响。

## 延伸
用 `decltype(auto)` 编写保持返回表达式值类别的包装函数，并通过类型特征检查返回类型。
比较 `auto`、`auto&`、`const auto&` 与 `decltype(auto)` 在索引元素遍历中的差异。

## 复现
TAG=latest scripts/run-example.sh cpp L1-015-type-deduction
