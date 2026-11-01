# L4-014-command

<!-- coverage: exempt 写入在请求事务内立即完成，服务不承诺命令排队、重放或撤销；把请求再包装成命令对象不会提供这些业务语义 -->

## 考点

对应 KP-JV-L4-14：把请求封装成对象，从而可参数化、排队、撤销。

可观察判据：命令接口实现 `execute`/`undo`，撤销后字段回到原值。

## 为什么这样写

`src/Main.java` 的 `Command` 声明执行与撤销，`ReplaceCommand.execute`
保存接收者 `Document` 的旧字段，`undo` 用 `document.replace(previous)` 恢复。
调用者 `Editor` 仅操作命令接口并用栈保存历史，不自己反向修改文档。
`main` 连续提交两个命令，再依次撤销，所有文本均读取真实字段。
如果去掉命令内的恢复语句，`undo: review`、`undo: draft` 都会变为
`undo: published`，实际比较得到的 `restored: true` 会变为 `false`。
执行状态检查避免未执行就撤销或重复执行覆盖旧值。

## 怎么跑

```bash
TAG=latest bash scripts/run-example.sh java L4-014-command
```
