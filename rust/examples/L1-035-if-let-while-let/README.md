# L1-035-if-let-while-let

## 考点
对应 KP-RS-L1-35：if let、while let 与 let else 解构控制流。匹配值被逐项输出，None 终止 while let，而 let else 对空切片走提前返回

## 易错点
把 `Option` 直接 `unwrap`，会在遇到 `None` 时 panic；用 `if let`、`while let` 或 `let else` 才能把缺值路径写清楚。循环匹配失败时 `while let` 会自然结束，而 `let else` 的失败分支必须发散（例如提前返回），不能继续执行后续代码。

## 延伸
项目的 `src/lib.rs` 用 `if let Some(value)` 解析 `--threads=` 参数，也用 `while let Some(path) = pending.pop()` 遍历待处理路径。前者只处理可选参数值，后者在栈耗尽时结束目录扫描，不必手写 `match` 后再检查退出条件。

## 复现
TAG=latest scripts/run-example.sh rust L1-035-if-let-while-let
