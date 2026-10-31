# L1-012-if-exit-status

<!-- coverage: pending -->

## 考点
对应 KP-SH-L1-12：`if` 根据命令的退出状态选择分支。
看到成功命令进入 `then`、非零命令进入 `else`，说明掌握了状态判断。

## 易错点
`if` 检查的是命令状态，非零不代表每种场景下都是致命错误。
显式处理成功和失败分支，不要用 `$?` 间接判断或吞掉失败。

## 延伸
将命令状态判断用于部署步骤，并为失败分支定义清晰的处理动作。
练习区分可恢复失败与必须中止流程的失败。

## 复现
TAG=latest scripts/run-example.sh shell L1-012-if-exit-status
