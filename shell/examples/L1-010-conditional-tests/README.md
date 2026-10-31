# L1-010-conditional-tests

<!-- coverage: pending -->

## 考点
对应 KP-SH-L1-10：区分 Bash 的 `[[ ]]` 与 `[ ]` 条件测试。
看到含空格值被完整匹配，且 `[[ ]]` 正则匹配成功，说明掌握了两种测试的用途。

## 易错点
`[` 在 Bash 中通常是内建命令，但展开仍可能拆词，且必须写结束符 `]`。
需要 Bash 专用匹配时用 `[[ ]]`，使用 `[` 时将变量引用起来。

## 延伸
练习在参数校验中组合字符串相等判断与 `[[ ]]` 的正则匹配。
进一步比较 `[[ ]]` 与 POSIX `test` 在可移植脚本中的适用边界。

## 复现
TAG=latest scripts/run-example.sh shell L1-010-conditional-tests
