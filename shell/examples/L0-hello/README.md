## 考点
通过 `bash hello.sh` 验证 Bash 5.2 的严格模式、数组、算术扩展及命令替换/退出码判断。
预期输出检查数组长度、累加结果和成功状态。

## 运行
在仓库根目录执行：`TAG=latest scripts/run-example.sh shell hello`。

## 易错点
脚本使用 Bash 数组和 `set -euo pipefail`，必须由 Bash 执行；用 `sh hello.sh` 会不兼容。
运行器会调用 `bash hello.sh`，因此无需依赖脚本的可执行权限。
