# L1-005-ifs-field-splitting


## 考点
对应 KP-SH-L1-05：`IFS` 指定未引用展开时的字段分隔符。
看到逗号分隔值拆成两个字段，恢复默认 IFS 后空格分隔也生效，即为掌握。

## 易错点
临时改 `IFS` 后不恢复会影响后续读行或拆词，因为它是当前 Shell 的分隔设置。
将设置限制在局部作用域或及时还原默认值；复原后再验证空格拆分。
ShellCheck 的 SC2086 是 info 级检查，`-S warning` 不显示，`-S info` 可见。

## 延伸
用 `while IFS=, read -r ...` 局部解析逗号分隔的一行，避免改动全局设置。
进一步测试包含空字段的输入，确认拆分规则与数据格式约定一致。

## 复现
TAG=latest scripts/run-example.sh shell L1-005-ifs-field-splitting
