# L4-017-mediator

<!-- coverage: exempt HttpApp 单向调用 Api，实体不互相通信；不存在多个对等组件交互网需要中介协调 -->

## 考点

对应 KP-JV-L4-17：用中介者集中协调多个同事对象的交互，同事之间不直接引用。

可观察判据：中介者持有同事列表，发送后按注册顺序输出固定标签。

## 为什么这样写

`src/Main.java` 的 `Room` 持有 `List<Colleague>`，`send` 按列表顺序通知
除发送者外的同事；`Colleague` 的字段只有名字和 `Mediator` 引用。
`Colleague.send` 中的 `mediator.send(this, message)` 是唯一发送路径，
`receive` 只收到发送者名字，不持有其他同事引用。
`main` 注册三人并让两人分别发送，消息标签来自真实接收者。
如果去掉中介者转发，四行输出全部消失；如果倒序遍历，
第一条消息的 `bob`、`carol` 两行就会交换。未注册发送者明确抛异常。

## 怎么跑

```bash
TAG=latest bash scripts/run-example.sh java L4-017-mediator
```
