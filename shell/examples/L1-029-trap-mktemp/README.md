# L1-029-trap-mktemp

<!-- coverage: pending -->

## 考点
对应 KP-SH-L1-29：使用 `mktemp` 创建唯一文件，并由 `trap ... EXIT` 清理。
正常退出和显式非零退出后文件都不存在，说明临时资源的退出清理已生效。

## 易错点
固定 `/tmp/x` 可能覆盖他人文件或冲突；用 `mktemp` 生成唯一目标并注册退出清理。
把清理逻辑放进 `EXIT` trap，避免正常与失败退出路径留下临时文件。

## 延伸
将临时目录与文件统一放在受控工作目录中，并为多项资源集中注册清理。
为收到终止信号时的清理需求单独设计信号 trap，并明确最终退出状态。

## 复现
TAG=latest scripts/run-example.sh shell L1-029-trap-mktemp
