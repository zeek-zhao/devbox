# L4-014-command


## 考点

对应 KP-L4-14：把请求封装成对象，从而可参数化、排队、撤销。

可观察判据：命令对象记录执行前状态，`execute()` 后 `undo()` 恢复原值，输出固定前后值。

## 为什么这样写

代码位置（`main.cpp`）：第 30–44 行保存及恢复状态，第 52–65 行封装调用者，第 67–75 行读取执行前后的接收者状态。

`Document` 是接收者，`ReplaceCommand` 保存接收者引用和替换参数。`execute()` 先记录原文再覆盖，`undo()` 读取快照恢复；`Invoker` 只持有 `unique_ptr<Command>`，经抽象接口执行和撤销。重复执行、无快照撤销都会抛出明确异常。

替换文本不是可逆运算。删掉 `before_` 的保存或恢复，第三行 `after undo: original` 就无法从接收者状态得到；三行均读取同一个真实文档，不打印预设的状态结论。

## 怎么跑

TAG=latest bash scripts/run-example.sh cpp L4-014-command
