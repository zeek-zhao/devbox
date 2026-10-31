# L4-020-state

<!-- coverage: pending -->

## 考点

对应 KP-PY-L4-20：把状态相关行为分散到状态对象，上下文在状态切换后行为随之改变。

可观察判据：状态对象返回下一状态，两次调用输出固定标签。

## 为什么这样写

`Pending/Running/Done.advance()` 各自返回标签及下一状态对象，终态返回自身。
上下文 `Task.advance()` 的解包赋值行将下一状态写回 `_state`，没有按字符串分支判断。
`main()` 在同一任务上两次调用同一方法。删除状态写回，第二行会重复 `pending -> running`；
因此标签虽由状态定义，选择哪一个标签来自实际状态切换。

## 怎么跑

TAG=latest bash scripts/run-example.sh python L4-020-state
