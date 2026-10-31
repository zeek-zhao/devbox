# L3-003-jq-json-processing

<!-- coverage: pending -->

## 考点
对应 KP-SH-L3-03：用 `jq` 读取嵌套 JSON 字段并筛选满足条件的对象。
正确读取含转义引号的消息且只列出健康检查，就说明掌握了该 KP。

## 易错点
JSON 字符串可含转义符且字段可能嵌套，文本匹配会错读结构或匹配到错误字段。
使用 `jq` 按键路径查询和按布尔字段筛选，不要用正则猜 JSON 结构。

## 延伸
练习处理可选或缺失字段，并明确约定默认值与空值的区别。
把响应校验扩展为多个检查项的失败汇总，用于服务状态巡检。

## 复现
TAG=latest scripts/run-example.sh shell L3-003-jq-json-processing
