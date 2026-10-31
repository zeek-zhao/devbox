# L1-027-goroutines


## 考点
对应 KP-GO-L1-27：用 go 语句启动函数，用 channel 接收作为任务结果完成点。
看到等待标记、任务结果 6、接收完成标记按固定顺序输出，即掌握主流程等待结果。

## 易错点
main 返回会结束进程并丢弃未完成任务，仅启动 goroutine 不能保证拿到结果。
通过 channel 或 WaitGroup 明确等待；本例任务算完后发送，主流程接收后才输出并返回。

## 延伸
把并行文档解析的单个任务结果通过 channel 交回主流程。
扩展为多个固定编号任务时先收集全部结果，再按编号输出，避免依赖调度顺序。

## 复现
TAG=latest scripts/run-example.sh go L1-027-goroutines
