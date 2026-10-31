# L1-004-positional-parameters

<!-- coverage: pending -->

## 考点
对应 KP-SH-L1-04：理解 `"$@"` 逐个保留位置参数、`"$*"` 合并成一个字段。
看到两个 `at-item`（第二个含空格）和一个合并的 `star-field`，说明掌握了区别。

## 易错点
未引用的 `$@` 会再次拆词，原本含空格的参数可能变成多个参数。
转发全部参数时使用 `"$@"`，不要用未引用的 `$@` 或把参数拼成字符串。

## 延伸
编写接收任意参数的包装脚本，并将 `"$@"` 原样传递给子命令。
测试空参数与含空格参数，确认转发前后参数数量和边界一致。

## 复现
TAG=latest scripts/run-example.sh shell L1-004-positional-parameters
