# L1-016-constexpr

<!-- coverage: pending -->

## 考点
对应 KP-L1-16：`static_assert` 通过证明 `constexpr` 函数可在编译期求值。
运行期变量调用同一函数并输出结果，能区分编译期证据与运行期计算。

## 易错点
`constexpr` 只表示函数具备编译期求值资格，不代表每次调用都在编译期执行。
用可修改的运行期变量调用，并用 `static_assert` 单独验证常量表达式。

## 延伸
尝试用 `constexpr` 结果定义 `std::array` 的长度，并继续学习 `consteval`。
比较编译期常量和运行期数据在接口中的适用场景。

## 复现
TAG=latest scripts/run-example.sh cpp L1-016-constexpr
