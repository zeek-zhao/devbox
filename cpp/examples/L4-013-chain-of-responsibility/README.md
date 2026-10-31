# L4-013-chain-of-responsibility

<!-- coverage: pending -->

## 考点

对应 KP-L4-13：请求沿处理者链传递，任一处理者可处理或交给下一个。

可观察判据：三个处理者串成链，三种输入分别命中不同处理者并输出固定标签；无人处理时输出默认标签。

## 为什么这样写

代码位置（`main.cpp`）：第 12–18 行连接和转发，第 24–43 行实现三个处理者，第 45–54 行构造链并发送请求。

`Handler::set_next()` 用独占指针连接处理者；三个子类的 `handle()` 各自匹配一个级别，否则委托基类沿链转发。末尾空指针返回默认标签，独占所有权构造出无环链。`main()` 只通过 `Handler` 指针发送四种请求。

删掉任意一段转发，后面的请求会变成 `unhandled`；例如断开首节点后，第二行 `warning` 和第三行 `error` 都会改变。第四行实际经过整条链的终止分支，不是直接打印结论。

## 怎么跑

TAG=latest bash scripts/run-example.sh cpp L4-013-chain-of-responsibility
