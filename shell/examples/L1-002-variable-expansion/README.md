# L1-002-variable-expansion

<!-- coverage: pending -->

## 考点
对应 KP-SH-L1-02：区分 `name=value` 赋值与 `$name`、`${name}` 展开。
看到含空格的原值被完整输出，说明赋值和引用展开正确。

## 易错点
赋值号两侧加空格会把赋值解析成命令及参数，而不是变量赋值。
写成 `name=value`，输出数据时引用变量，避免内容被拆成多个字段。

## 延伸
练习给变量赋空值、使用花括号区分相邻文本中的变量名。
把配置值作为一个整体引用传递给命令，避免空格改变参数边界。

## 复现
TAG=latest scripts/run-example.sh shell L1-002-variable-expansion
