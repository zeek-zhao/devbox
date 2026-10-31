# L1-026-numbers-bool


## 考点
对应 KP-PY-L1-26：观察布尔值与整数的相等及继承关系，并校验计数输入。
计数接口拒绝 `bool`、接受整数，且十进制金额精确相加，说明掌握类型边界与比较策略。

## 易错点
`bool` 是 `int` 的子类且 `True == 1`，仅用 `isinstance(value, int)` 会放宽计数输入。
计数校验显式排除布尔值；十进制金额使用 `Decimal`，避免依赖二进制浮点精确相等。

## 延伸
可以为汇总接口定义统一的计数校验，并测试布尔值、负数及非整数输入。
处理金额时从文本构造 `Decimal`，再明确规定舍入和量化规则。

## 复现
TAG=latest scripts/run-example.sh python L1-026-numbers-bool
