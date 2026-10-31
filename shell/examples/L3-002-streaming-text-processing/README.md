# L3-002-streaming-text-processing

<!-- coverage: pending -->

## 考点
对应 KP-SH-L3-02：用逐行流式工具处理大型输入，不把整个文件读进 Shell 变量或数组。
生成 5000 行后仍能正确统计行数并报告首尾记录，就说明掌握了该 KP。

## 易错点
`content=$(cat large-file)` 会把全部内容载入内存，而且命令替换会去掉末尾换行。
用 `awk`、`sed` 或管道逐行串接处理，只保留必要的汇总状态。

## 延伸
将固定记录替换成日志流，按状态码分组统计并输出可复核的汇总。
比较逐行处理与整文件加载在内存占用和错误处理上的差异。

## 复现
TAG=latest scripts/run-example.sh shell L3-002-streaming-text-processing
