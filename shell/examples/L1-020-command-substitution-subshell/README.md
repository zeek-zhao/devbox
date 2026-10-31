# L1-020-command-substitution-subshell


## 考点
对应 KP-SH-L1-20：用 `$(...)` 捕获输出，并观察其中的目录切换和赋值不改变父 Shell。
看到捕获值为 `child`、父变量仍为 `parent` 且目录未变，即掌握子 Shell 隔离。

## 易错点
`$(...)` 在子 Shell 环境执行，里面的 `cd` 或赋值不会改写调用方状态。
命令替换还会去掉末尾换行；不要依赖它传递状态变更或保留尾部换行。

## 延伸
用命令替换采集命令输出，再与当前 Shell 的目录、变量状态分别比较。
需要修改调用方状态时，直接在当前 Shell 执行命令，而不是放进 `$(...)`。

## 复现
TAG=latest scripts/run-example.sh shell L1-020-command-substitution-subshell
