# L1-005-string-builder


## 考点
对应 KP-JV-L1-05：循环动态拼接可复用 `StringBuilder`，`String` 则保持不可变。
循环 `+` 与 `append` 结果相同，旧 `String` 快照不变而 builder 别名可见追加，即掌握此 KP。

## 易错点
循环拼接可能反复复制累计内容，因为 `String` 不可变。
长循环复用 builder；不要用单次运行耗时断言性能优劣。

## 延伸
在查询结果格式化中集中追加片段，并用 `toString` 在边界处生成最终值。
比较 builder 别名共享可变状态与字符串快照的不可变语义。

## 复现
TAG=latest scripts/run-example.sh java L1-005-string-builder
