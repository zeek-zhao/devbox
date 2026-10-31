# L4-017-mediator

<!-- coverage: pending -->

## 考点

对应 KP-PY-L4-17：用中介者集中协调多个同事对象的交互，同事之间不直接引用。

可观察判据：中介者注册同事并转发，同事间无直接引用，输出固定转发记录。

## 为什么这样写

`Mediator.register` 保存名称到同事对象的映射，`forward` 的 `receive(...)` 行执行转发。
`Colleague` 仅保存自己的名称与中介者；`send()` 接收目标名称而非另一个同事对象。
三条输出均在接收方 `receive()` 发生。删除转发行，三行全消失；删除注册行，发送会失败，
因此没有用打印转发记录冒充实际协调。重复注册、未注册发送者和未知接收者不会静默成功。

## 怎么跑

TAG=latest bash scripts/run-example.sh python L4-017-mediator
