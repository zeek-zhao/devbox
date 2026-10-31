# L2-009-slog-logging


## 考点
对应 KP-GO-L2-09：用 log/slog 输出包含级别、消息和字段的结构化日志。
看到固定的 INFO 级别、`index built` 消息及 records=3 字段，说明字段可观察。
日志不含时间戳等易变值，且业务结果不依赖这些值。

## 易错点
默认日志记录可能带有当前时间等非稳定字段，因此重复运行的输出会变化。
使用固定 handler 或只断言稳定字段；本例的 handler 会移除时间字段。

## 延伸
为日志添加请求级字段，并使用 `With` 让同一上下文的事件共享字段。
比较 JSON handler 和文本 handler 的结构化输出及其下游采集方式。

## 复现
TAG=latest scripts/run-example.sh go L2-009-slog-logging
