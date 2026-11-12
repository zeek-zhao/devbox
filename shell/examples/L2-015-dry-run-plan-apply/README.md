# L2-015-dry-run-plan-apply

## 考点
对应 KP-SH-L2-15：变更操作提供 --dry-run，计划阶段只描述将要发生的动作，执行阶段才落盘。

## 易错点
dry-run 分支里夹带副作用会让「预览」悄悄改状态；把计划收敛成一个纯函数，执行阶段单独消费。

## 延伸
给部署工具加 diff 输出：计划阶段同时打印「当前状态 → 目标状态」的差异清单。

## 复现
TAG=latest scripts/run-example.sh shell L2-015-dry-run-plan-apply
