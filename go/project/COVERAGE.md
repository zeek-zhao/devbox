# Go 毕业项目：用例覆盖表

项目目标：并发任务网关（HTTP 入口 → worker pool → 限流 → Prometheus 指标 → 优雅退出）。
阶段 0 只有 hello 用例。

| 用例ID | 落点 | 说明 |
|---|---|---|
| hello | src/main.go:3 | 工具链版本与 goroutine 验证 |
