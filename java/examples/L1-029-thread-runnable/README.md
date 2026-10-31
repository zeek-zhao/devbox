# L1-029-thread-runnable

<!-- coverage: pending -->

## 考点
对应 KP-JV-L1-29：Runnable 描述任务，Thread.start 启动新线程，join 等待完成。
看到 start 后线程不同、直接 run 仍在调用线程、join 后计数稳定且工作线程失败可交回主线程，即说明掌握。

## 易错点
未 join 会过早汇总，直接调用 run 则根本没有启动新线程。
使用 start/join；在线程内收集失败，再由主线程统一检查或报告。

## 延伸
把固定任务计数用于后台文档处理，并比较 join 与更高层任务执行器的等待方式。
让工作线程返回可检查的结果，明确失败传播和取消的边界。

## 复现
TAG=latest scripts/run-example.sh java L1-029-thread-runnable
