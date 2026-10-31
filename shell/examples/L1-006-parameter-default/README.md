# L1-006-parameter-default

<!-- coverage: pending -->

## 考点
对应 KP-SH-L1-06：用 `${var:-default}` 为未设置或空值提供默认值。
看到未设置和空值都得到 fallback、非空值仍保留原值，即为掌握。

## 易错点
`${var-default}` 只对未设置生效；变量为空时它会展开为空字符串。
需要空值也走默认分支时用冒号形式 `:-`，并在 `set -u` 下用安全展开。

## 延伸
比较 `${var-default}`、`${var:-default}` 与带 `=` 的赋值形式，区分展开和赋值。
将默认展开用于可选环境配置，并测试未设置、空值和非空值三种输入。

## 复现
TAG=latest scripts/run-example.sh shell L1-006-parameter-default
