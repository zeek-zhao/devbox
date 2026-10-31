# L4-013-chain-of-responsibility

<!-- coverage: pending -->

## 考点

对应 KP-PY-L4-13：请求沿处理者链传递，任一处理者可处理或交给下一个。

可观察判据：每个处理者持有 `next_handler`，三种输入命中不同处理者，未命中输出默认标签。

## 为什么这样写

`Handler.__init__` 的 `self.next_handler` 行保存后继；`handle()` 中命中即返回，否则调用后继的 `handle()`。
三个子类只决定各自接受的级别。`main()` 用同一条链处理四种输入，
不是直接打印结论。拆掉转发行，第二、三行会变为默认标签；拆掉末尾默认返回，第四行会变为 `None`。

## 怎么跑

TAG=latest bash scripts/run-example.sh python L4-013-chain-of-responsibility
