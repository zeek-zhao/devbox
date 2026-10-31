# L1-033-integer-overflow


## 考点
对应 KP-RS-L1-33：显式选择溢出检查策略，并处理窄化转换结果。
看到 `checked_add` 给出 `None`、有效的 `try_from` 精确转换为 42，说明掌握了数值边界。

## 易错点
调试与优化构建的默认溢出行为不同，不能假设两者都会 panic。
需稳定处理边界时使用 `checked_*`、`saturating_*` 或显式转换并检查结果。

## 延伸
把输入范围验证应用到文件长度与文档偏移量转换。
比较 `checked_add` 与 `saturating_add` 在边界策略上的差异。

## 复现
TAG=latest scripts/run-example.sh rust L1-033-integer-overflow
