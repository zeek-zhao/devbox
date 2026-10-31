# L1-004-types-conversions

<!-- coverage: pending -->

## 考点
对应 KP-GO-L1-04：数值跨类型需要显式转换，且转换前检查窄化范围。
边界值转换正确、超范围输入被拒绝，说明掌握显式类型转换。

## 易错点
Go 不做隐式数值转换；直接窄化会丢弃高位或产生意外值。
先检查目标类型范围，并用边界输入验证转换结果。

## 延伸
在文档 ID 与偏移量解析中区分整数类型，并统一转换边界。
为负值、最大可表示值和超范围值补充表驱动测试。

## 复现
TAG=latest scripts/run-example.sh go L1-004-types-conversions
