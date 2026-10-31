# L1-013-pattern-bindings

<!-- coverage: pending -->

## 考点
对应 KP-RS-L1-13：用 `if let`、`while let` 和 `@` 模式提取所需值。
看到 `if let` 选择性执行、`while let` 逐项处理到结束，且 `@` 保留整体与字段，说明掌握了绑定。

## 易错点
会在不需要的地方使用 `_` 丢弃后续还要用的值；用 `@` 同时保留整体绑定和解构结果。
在同一模式里绑定整体和字段，避免丢弃之后仍需使用的数据。

## 延伸
将 `while let` 用于逐条读取可选的解析结果，并分别处理成功与停止。
在解析事件时用 `@` 保留原事件，同时提取重试次数。

## 复现
TAG=latest scripts/run-example.sh rust L1-013-pattern-bindings
