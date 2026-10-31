# L4-013-chain-of-responsibility

<!-- coverage: pending -->

## 考点

对应 KP-JV-L4-13：请求沿处理者链传递，任一处理者可处理或交给下一个。

可观察判据：抽象处理者持有后继引用，三种输入各命中一个处理者并输出固定标签。

## 为什么这样写

`src/Main.java` 的 `Handler` 用私有 `next` 保存后继，`handle` 中的
`return next.handle(level)` 实际转交请求；三个子类只实现 `accepts` 和 `label`。
`main` 从外部组装链，三种输入都通过同一个 `Handler` 引用进入。
如果去掉转交语句，`WARNING -> warning-handler` 和 `ERROR -> error-handler`
无法产生；若把判断写成始终接受，后两行会错误地输出 `info-handler`。
链尾未处理的请求明确抛异常，不用默认标签掩盖组装错误。

## 怎么跑

```bash
TAG=latest bash scripts/run-example.sh java L4-013-chain-of-responsibility
```
