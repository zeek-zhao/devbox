# L1-036-loop-labels

## 考点
对应 KP-RS-L1-36：标签循环及带值 break。嵌套循环通过带标签 break 直接返回找到元素的位置

## 易错点
在嵌套循环里只写 `break`，只会退出最内层循环，搜索命中后外层仍可能继续扫描或覆盖结果。给目标循环加标签并用 `break 'search value` 一次退出到正确层级；没有命中时也要明确给结果一个退出路径。

## 延伸
项目的 `src/lib.rs` 目前用 `collect_files` 的 `while let` 逐层遍历目录，没有需要用带标签 `break` 从多层循环带值跳出的搜索逻辑。标签循环在这个 CLI 里没有真正需要的地方，本例只作 Rust 控制流能力练习。

## 复现
TAG=latest scripts/run-example.sh rust L1-036-loop-labels
