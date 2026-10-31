# L1-024-stdout-stderr

<!-- coverage: pending -->

## 考点
对应 KP-SH-L1-24：用文件描述符区分标准输出中的业务数据与标准错误中的诊断信息。
看到两个流分别只含各自文本、最终业务输出不含诊断信息，就说明掌握了分流。

## 易错点
错误信息写到 stdout 会污染管道数据，让下游把诊断文本当成业务结果。
诊断输出应显式写到 stderr，调用方再按需要分别重定向或显示。

## 延伸
将命令 stdout 接入处理管道，同时单独收集 stderr 作为诊断日志。
练习分别重定向两个文件描述符，并验证每个流的内容边界。

## 复现
TAG=latest scripts/run-example.sh shell L1-024-stdout-stderr
