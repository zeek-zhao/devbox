# L2-006-logging


## 考点
对应 KP-PY-L2-06：使用命名 logger、日志等级和固定格式输出诊断信息。
门槛以上的消息带有固定 logger 名与等级、较低等级消息不出现，说明配置有效。

## 易错点
在业务逻辑里到处 `print` 会混淆数据输出和诊断，也无法统一控制等级。
使用命名 logger，并只在应用入口配置 handler、等级和格式。

## 延伸
为 CLI 的处理过程和错误诊断分别设计日志等级，避免把日志当作业务结果。
在应用入口集中配置格式与 handler，并在测试中验证记录内容和等级。

## 复现
TAG=latest scripts/run-example.sh python L2-006-logging
