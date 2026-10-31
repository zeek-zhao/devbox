# L1-021-pipeline-pipefail


## 考点
对应 KP-SH-L1-21：比较普通管道与启用 `pipefail` 后的管道状态。
看到 `false | true` 默认成功、启用后失败，说明理解了上游失败的传播。

## 易错点
没有 `pipefail` 时，管道状态通常只取最后一条命令，前面的失败会被吞掉。
脚本使用 `set -euo pipefail`，避免关键上游命令失败却被当成成功。

## 延伸
将 `pipefail` 用在检查与过滤组成的管道，确认任一关键阶段失败都能被发现。
结合条件分支处理预期失败，避免让 `set -e` 误终止错误处理逻辑。

## 复现
TAG=latest scripts/run-example.sh shell L1-021-pipeline-pipefail
