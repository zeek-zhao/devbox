# L1-034-preprocessor

<!-- coverage: pending -->

## 考点
对应 KP-L1-34：宏对实参做文本替换，`SQUARE(1 + 2)` 展开后结果为 5，而 `constexpr` 函数结果为 9。
看到两种结果不同，即可说明理解了宏参数缺少括号时的优先级陷阱。

## 易错点
宏参数会被多次替换且不自动分组，可能改变运算优先级或重复求值；优先使用类型安全函数。
宏展开发生在编译前，无法像函数那样执行类型检查；需要计算时应写 `constexpr` 函数。

## 延伸
可以尝试为宏参数和整个替换表达式补括号，观察优先级问题如何变化。
还可比较 `constexpr` 函数与 `consteval` 函数在编译期求值要求上的区别。

## 复现
TAG=latest scripts/run-example.sh cpp L1-034-preprocessor
