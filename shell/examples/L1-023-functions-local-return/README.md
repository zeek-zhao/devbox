# L1-023-functions-local-return


## 考点
对应 KP-SH-L1-23：观察 `local` 作用域、函数 stdout 字符串结果和整数返回状态。
看到局部值不改全局值、字符串可捕获且 `return 7` 得到状态 7，即掌握此点。

## 易错点
`return` 只能返回 0–255 的整数状态，不能直接返回字符串。
字符串写到 stdout 并由调用方用命令替换接收；状态用条件分支检查。

## 延伸
把函数拆成 stdout 业务结果与退出状态两条通道，让调用方分别处理。
在部署或清理函数中用 `local` 限制临时变量，避免污染全局状态。

## 复现
TAG=latest scripts/run-example.sh shell L1-023-functions-local-return
