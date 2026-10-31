# L1-033-command-lists

<!-- coverage: pending -->

## 考点
对应 KP-SH-L1-33：观察 `&&` 与 `||` 根据前一条命令的状态执行后续命令。
`true && false || ...` 仍运行回退命令，而显式 `if` 报告第二步失败，说明掌握组合语义。

## 易错点
`cmd1 && cmd2 || cmd3` 不是总等价于 if/else，尤其 `cmd2` 失败时会运行 `cmd3`；需完整分支时写 `if`。
为成功与失败路径互斥的业务逻辑写明确的条件分支，避免误触发回退动作。

## 延伸
为多步骤脚本明确区分“前置步骤失败”和“整体条件不成立”的处理路径。
练习用 `if`、`elif` 和 `else` 表达互斥分支，再用命令列表简化无歧义的短操作。

## 复现
TAG=latest scripts/run-example.sh shell L1-033-command-lists
