# L3-002-race-detector


## 考点
对应 KP-GO-L3-02：普通运行成功并不能证明并发访问没有竞态。
`-race` 检出未同步计数，而加 Mutex 后得到固定计数且无竞争报告，说明掌握竞态检测与同步。
输出只给出检测结论，不依赖竞态报告中的地址、栈帧或 goroutine 编号。

## 易错点
普通运行通过不代表没有竞态，且输出顺序不是检测依据；用 `-race` 检查并用互斥锁或 channel 建立同步。
不要把报告中的地址或调度顺序当成断言；本例仅检查是否出现 race detector 标记。

## 延伸
用 channel 替代共享计数，比较两种同步方式的所有权和通信语义。
在并行索引状态一致性测试中持续运行 `go test -race`。

## 复现
TAG=latest scripts/run-example.sh go L3-002-race-detector
