# L4-014-command

<!-- coverage: exempt 本项目一次 CLI 调用同步执行一个操作，没有请求队列、历史或撤销；clean 的原子发布是异常安全文件替换，不是可保存并逆序撤销的接收者命令 -->

## 考点

对应 KP-PY-L4-14：把请求封装成对象，从而可参数化、排队、撤销。

可观察判据：命令类封装接收者与参数，`execute`/`undo` 后输出固定状态序列。

## 为什么这样写

`AppendCommand.__init__` 保存接收者 `receiver`、参数 `text` 和独立历史列表；
`execute()` 保存执行前状态，`undo()` 的赋值行恢复它。`Invoker` 只调用命令接口，
队列提交不会立即改文档，撤销按执行的逆序进行。删除接收者调用，第二行仍为空；
删除恢复赋值，第四行仍是 `'hello world'`。没有可变默认参数，历史不在命令间共享。

## 怎么跑

TAG=latest bash scripts/run-example.sh python L4-014-command
