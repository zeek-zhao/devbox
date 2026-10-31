# L3-001-worker-pool-shutdown


## 考点
对应 KP-GO-L3-01：用 WaitGroup、Once 与 Mutex 协调 worker pool。
关闭任务 channel 后六个任务都完成、worker 全退出且 Once 只执行一次，说明掌握关闭与等待。
父 context 取消后子任务收到 Done，说明取消传播已生效。

## 易错点
忘记关闭任务源或等待 worker 会造成 goroutine 泄漏；先定义 channel 所有者，再关闭并等待。
取消 context 后，阻塞操作必须监听 Done；本例用 Done 通知并等待子任务退出。

## 延伸
为 worker 增加有界队列和背压策略，并比较关闭任务源与取消 context 的职责。
将优雅关闭接入并行解析、索引提交及服务关闭流程。

## 复现
TAG=latest scripts/run-example.sh go L3-001-worker-pool-shutdown
