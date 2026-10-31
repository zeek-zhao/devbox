# L1-032-executor-future


## 考点
对应 KP-JV-L1-32：ExecutorService 管理任务，Future.get 取得结果并暴露异常。
按提交顺序得到 `[2, 4]`、观察指定任务异常，并确认线程池终止，说明掌握任务生命周期。

## 易错点
任务异常会漏报或进程不退出，因为未 get 或未关闭线程池。
逐项限时 get，在 finally 关闭执行器并限时等待；超时必须作为失败报告。

## 延伸
比较固定线程池与单线程执行器对任务并发及提交顺序的影响。
进一步用 Callable 返回业务结果，并设计取消任务的协作式停止。

## 复现
TAG=latest scripts/run-example.sh java L1-032-executor-future
