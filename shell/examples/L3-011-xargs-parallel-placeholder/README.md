# L3-011-xargs-parallel-placeholder

## 考点
对应 KP-SH-L3-11：xargs -P 并行执行、-I{} 占位传参；并行输出顺序不定，先收集再排序才稳定。

## 易错点
把并行输出直接当结果用会偶发乱序；-P 下每个任务的退出码也不汇入 xargs 退出码，失败要另行收集。

## 延伸
把并行模式接入巡检：分片并行扫描 + 排序汇总 + 失败分片重跑。

## 复现
TAG=latest scripts/run-example.sh shell L3-011-xargs-parallel-placeholder
