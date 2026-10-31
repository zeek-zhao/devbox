# L2-006-standard-logging

<!-- coverage: pending -->

## 考点
对应 KP-JV-L2-06：java.util.logging 将诊断日志与 stdout 业务结果隔离。
看到 stderr 仅有固定 `INFO:index-ready`、stdout 仅有业务结果且 FINE 被过滤，即掌握级别与格式控制。

## 易错点
日志重复或输出随时间变化，因为父 handler 与默认格式同时生效。
关闭传播并显式设置 logger/handler 级别，使用不含时间字段的固定 Formatter。

## 延伸
为索引构建阶段定义稳定日志级别，并保持命令业务输出适合脚本消费。
进一步验证多 handler 配置及日志级别继承对诊断信息的影响。

## 复现
TAG=latest scripts/run-example.sh java L2-006-standard-logging
