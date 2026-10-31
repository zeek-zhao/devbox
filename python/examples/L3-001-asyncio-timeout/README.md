# L3-001-asyncio-timeout


## 考点
对应 KP-PY-L3-01：用 `gather` 并发等待并处理超时和取消。
结果排序稳定，超时被捕获且子任务清理后为 cancelled，说明掌握了该 KP。

## 易错点
只取消外层任务可能遗留子任务；保存子任务引用并在超时后等待结束。
不要断言墙钟耗时，改验收取消状态和清理动作。

## 延伸
将超时策略应用到多个并发输入源，并区分单项失败和整体失败。
练习用 `TaskGroup` 管理相关任务的取消与异常传播。

## 复现
TAG=latest scripts/run-example.sh python L3-001-asyncio-timeout
