# L1-001-shebang-execution


## 考点
对应 KP-SH-L1-01：用 shebang 指定解释器，并区分直接执行与 `bash script.sh`。
看到直接执行脚本输出 `interpreter=bash`，说明 shebang 选择了 Bash。

## 易错点
直接执行没有执行权限的文件会报权限错误，因为执行位决定能否启动脚本。
提交前设置执行位，或明确用 Bash 调用；不要把 shebang 当成执行权限。

## 延伸
检查脚本首行、文件执行位与调用方式，理解它们分别影响解释器选择和启动权限。
项目入口脚本可用明确的 Bash shebang，避免依赖调用者当前的交互式 Shell。

## 复现
TAG=latest scripts/run-example.sh shell L1-001-shebang-execution
