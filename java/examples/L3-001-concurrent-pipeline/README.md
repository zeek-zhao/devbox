# L3-001-concurrent-pipeline

<!-- coverage: pending -->

## 考点
对应 KP-JV-L3-01：用 CompletableFuture、ExecutorService 与并发集合做异步汇总。
四任务完成并得到排序后的 `a=2,b=2`、完成数 4；注入异常后仍明确失败并保留 cause，说明汇总可靠。

## 易错点
get-then-put 不是原子更新，且未等待 future 会丢统计或隐藏失败。
用 ConcurrentHashMap.merge 与 AtomicInteger，等待 allOf 并限制超时；finally 关闭线程池。

## 延伸
将固定词项扩展为分片文档并行计数，比较合并点与任务粒度。
为取消、超时及部分失败定义明确的索引错误策略。

## 复现
TAG=latest scripts/run-example.sh java L3-001-concurrent-pipeline
