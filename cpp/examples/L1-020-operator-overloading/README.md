# L1-020-operator-overloading

<!-- coverage: pending -->

## 考点
对应 KP-L1-20：二维点的 `+` 表示坐标相加，`==` 比较两个点的坐标。
输出链式加法结果和相等比较，能观察一致的运算语义与返回值。

## 易错点
重载不能改变运算符优先级或操作数数量，语义不自然的类型不应强行定义运算符。
加法返回新点而非意外修改操作数；比较返回布尔值，表达坐标相等。

## 延伸
可补充 `+=` 并让它返回左操作数引用，以支持符合预期的链式赋值。
学习比较运算符与 `std::strong_ordering`，定义更完整的值类型语义。

## 复现
TAG=latest scripts/run-example.sh cpp L1-020-operator-overloading
