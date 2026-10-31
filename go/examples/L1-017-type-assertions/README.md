# L1-017-type-assertions

<!-- coverage: pending -->

## 考点
对应 KP-GO-L1-17：用 any 接收动态值，并以 comma-ok 类型断言处理匹配和不匹配。
看到匹配时取得值、不匹配时得到 false 且程序继续运行，说明掌握了安全断言。

## 易错点
单返回值类型断言在动态类型不匹配时会 panic。
先使用 `value, ok := input.(T)` 检查结果，再读取断言值。

## 延伸
将 any 用于可扩展查询参数解析，并按目标类型分支验证输入。
为不支持的动态类型设计明确的错误处理路径。

## 复现
TAG=latest scripts/run-example.sh go L1-017-type-assertions
