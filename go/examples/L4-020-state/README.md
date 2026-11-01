# L4-020-state

<!-- coverage: exempt accepted/completed/failed/rejected 是指标槽位，任务处理后即释放，没有驻留任务对象按状态切换行为；网关关闭是一次性标志而非状态对象协议 -->

## 考点

对应 KP-GO-L4-20：把状态相关行为分散到状态对象，上下文在状态切换后行为随之改变。

可观察判据：状态接口实现 `Handle(ctx)` 并返回下一状态，两次调用输出固定序列。

## 为什么这样写

`main.go` 第 5–14 行定义状态接口，上下文只经 `Handle` 调用并接纳返回的下一状态。
第 16–36 行的待办、进行中、完成状态各自实现行为；后继通过接口字段注入，
状态实现不直接构造其他具体状态，装配集中在第 40–42 行。
第 43–45 行对同一个上下文连续调用，前两次从 pending 切到 running，
第三次验证 done 不再增加工作量。若拆掉第 14 行的状态接纳，
第二行 `running: finished work=2` 会变成 `pending: started work=2`，
第三行也不会进入 done；工作量来自状态实际修改的上下文字段。

## 怎么跑

```bash
TAG=latest bash scripts/run-example.sh go L4-020-state
```
