# L4-013-chain-of-responsibility

<!-- coverage: pending -->

## 考点

对应 KP-GO-L4-13：请求沿处理者链传递，任一处理者可处理或交给下一个。

可观察判据：处理者接口含 `SetNext`，三种输入分别输出固定标签，未命中输出默认标签。

## 为什么这样写

`main.go` 第 5–18 行定义处理者接口、接口类型的后继和返回后继的 `SetNext`；
第 20–27 行先尝试处理，再经接口转交，链尾才返回默认标签。
第 31–35 行链式连接三个处理者，并真正提交三种级别及未命中请求。
若拆掉第 25 行的转交，`handled: warning` 和 `handled: error` 会变成
`handled: default`；输出来自链的处理结果，不是预先打印结论。

## 怎么跑

```bash
TAG=latest bash scripts/run-example.sh go L4-013-chain-of-responsibility
```
