# L1-013-var-inference

<!-- coverage: pending -->

## 考点
对应 KP-JV-L1-13：var 只推断有初始化器的局部变量类型，并非动态类型。
输出同时展示推断的整数与显式声明的 null、lambda 目标类型；编译探针报告无效推断被拒绝。

## 易错点
空值或 lambda 无法推断目标类型，因为缺少有效初始化类型；此类位置写明类型，字段与参数不用 var。
var 只用于允许的位置且必须有初始化器，遇到目标类型不明确时显式声明类型。

## 延伸
比较局部变量的类型推断与泛型方法调用中的目标类型推断。
在复杂表达式中选择清晰的显式类型，避免 var 降低代码可读性。

## 复现
TAG=latest scripts/run-example.sh java L1-013-var-inference
