# L1-022-panic-recover


## 考点
对应 KP-GO-L1-22：只在任务边界的延迟函数中 recover，普通失败仍返回 error。
看到 empty document 错误、固定恢复标记，以及恢复后下一任务正常完成，即掌握异常隔离。

## 易错点
把 panic 当作输入校验或常规控制流会跳过清晰错误处理，也会中断任务剩余语句。
可预期失败返回 error，仅在边界隔离 panic；recover 后从边界返回，不从触发点续跑。

## 延伸
在索引批任务边界记录失败文档，并确保后续任务仍能处理。
为正常完成、可预期错误和异常隔离分别断言，不将恢复标记伪装成成功结果。

## 复现
TAG=latest scripts/run-example.sh go L1-022-panic-recover
