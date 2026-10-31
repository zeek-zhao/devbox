# L1-019-lambda-method-reference


## 考点
对应 KP-JV-L1-19：lambda 捕获稳定局部变量，方法引用匹配目标函数签名。
输出展示捕获值与 `String::length` 的映射结果；编译探针确认重赋值捕获变量会被拒绝。

## 易错点
回调读取的局部变量不能重新赋值，因为捕获要求 effectively final；先构造稳定值，不用共享可变盒子掩盖设计问题。
先计算稳定捕获值；若设计需要改变状态，应重新审视状态归属而非用可变盒子规避限制。

## 延伸
比较 `String::length` 与等价 lambda 的函数签名和可读性。
在词长统计中组合方法引用与标准函数式接口。

## 复现
TAG=latest scripts/run-example.sh java L1-019-lambda-method-reference
