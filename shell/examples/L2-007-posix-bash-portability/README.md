# L2-007-posix-bash-portability


## 考点
对应 KP-SH-L2-07：按脚本方言选择解释器。
看到 POSIX 脚本由 `sh` 执行、Bash 数组脚本由 `bash` 执行且输出各自判据，说明掌握可移植性边界。

## 易错点
将 Bash 数组脚本的 shebang 写为 `sh` 会触发语法错误，因为 POSIX `sh` 不支持 Bash 数组。
声明正确解释器并避免混用方言；本例分别显式调用 `sh` 和 `bash`。

## 延伸
检查部署环境提供的 `/bin/sh` 方言，并在 POSIX 脚本中用兼容语法实现功能。
将 Bash 专属脚本的解释器要求纳入项目运行环境契约。

## 复现
TAG=latest scripts/run-example.sh shell L2-007-posix-bash-portability
