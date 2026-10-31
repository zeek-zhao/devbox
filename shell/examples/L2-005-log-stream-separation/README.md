# L2-005-log-stream-separation


## 考点
对应 KP-SH-L2-05：机器可读结果写 stdout，进度日志写 stderr。
分开重定向后 stdout 只有部署结果、stderr 只有进度信息，说明两条输出流没有混杂。

## 易错点
把进度也写 stdout 会破坏调用方解析，管道可能把日志误当作业务数据。
给日志明确使用 `>&2`，并分别重定向和验证两条输出流。

## 延伸
为毕业项目定义稳定的 stdout 结果格式，并将诊断信息统一输出到 stderr。
将结果流接入管道或 JSON 解析器，同时保留独立的日志采集路径。

## 复现
TAG=latest scripts/run-example.sh shell L2-005-log-stream-separation
