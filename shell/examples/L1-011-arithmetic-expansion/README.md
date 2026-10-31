# L1-011-arithmetic-expansion

<!-- coverage: pending -->

## 考点
对应 KP-SH-L1-11：用 Bash 算术展开计算整数表达式。
看到 7 加 1 得到 8、7 除以 2 得到 3，说明掌握了整数计算及截断。

## 易错点
算术上下文按整数求值，除法会截断小数部分。
外部输入先校验为数值再参与计算，避免非数值内容导致意外结果。

## 延伸
用算术展开实现有限重试次数和计数器更新。
继续练习除数为零等边界条件的显式处理。

## 复现
TAG=latest scripts/run-example.sh shell L1-011-arithmetic-expansion
