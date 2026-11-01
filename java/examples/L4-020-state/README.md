# L4-020-state

<!-- coverage: exempt Item 没有生命周期状态，ready 只是首次请求完成后的单向发布标志；没有随状态改变的多组行为或可逆迁移 -->

## 考点

对应 KP-JV-L4-20：把状态相关行为分散到状态对象，上下文在状态切换后行为随之改变。

可观察判据：上下文委托给状态对象，切换后输出固定序列。

## 为什么这样写

`src/Main.java` 的上下文 `Task` 持有 `State`，`describe` 委托 `state.label()`，
`advance` 委托 `state.advance(this)`。`Pending`、`Running` 在各自实现中
调用 `task.transition(...)`，由上下文实际赋值；`Completed` 保持终态。
没有在上下文用 `switch` 模拟状态分支，状态对象也不保存上下文强引用。
`main` 对同一任务逐步推进，每次读取当前状态对象的行为标签。
如果 `transition` 不再赋值，后三行都会变成 `pending: waiting`；
如果移除委托，具体状态的 `running: processing` 等标签不会被调用产生。

## 怎么跑

```bash
TAG=latest bash scripts/run-example.sh java L4-020-state
```
