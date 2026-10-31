# Go 毕业项目：用例覆盖表

项目目标：并发任务网关（HTTP 入口 → worker pool → 限流 → Prometheus 指标 → 优雅退出）。
覆盖 `go/examples/` 的全部 54 个目录（含 hello）。落点相对本目录，
每个 ID 紧邻真实实现或执行该知识点的测试/构建命令；不使用汇总注释自证。
TCP 测试以 integration build tag 隔离，容器只编译，宿主执行。

| 用例ID | 落点 | 说明 |
|---|---|---|
| hello | src/main.go:46 | 运行完整程序的确定性自检入口 |
| L1-001-package-exports | internal/gateway/task.go:33 | 导出的 Task API 被 main 和外部测试包导入 |
| L1-002-zero-values | internal/gateway/gateway.go:72 | bool、计数器、WaitGroup 使用零值初始化 |
| L1-003-constants-iota | internal/gateway/task.go:24 | iota 定义状态及固定计数器槽位 |
| L1-004-types-conversions | internal/gateway/task.go:133 | 检查范围后将 int 转为 wire uint32 |
| L1-005-control-flow | internal/gateway/http.go:52 | switch 按错误类别映射 HTTP 状态码 |
| L1-006-functions-results | internal/gateway/task.go:106 | Process 返回 Result 和 error |
| L1-007-pointers | internal/gateway/gateway.go:36 | 指针接收者在锁内修改共享指标 |
| L1-008-arrays | internal/gateway/gateway.go:32 | 固定数组保存全部状态计数 |
| L1-009-slice-backing-array | internal/gateway/gateway_test.go:116 | 验证 cap 受限后 append 分离及容量足够时共享 |
| L1-010-slice-capacity | internal/gateway/task.go:124 | 按不同词数量预分配 slice 容量 |
| L1-011-maps-comma-ok | internal/gateway/task.go:116 | comma-ok 区分词频首次初始化及递增 |
| L1-012-strings-runes | internal/gateway/task.go:113 | 标准库 Unicode 小写转换与空白切词 |
| L1-013-structs | internal/gateway/task.go:32 | 任务结构体的非零 ID 与文本字段 |
| L1-014-struct-embedding | internal/gateway/gateway.go:17 | job 嵌入 Task，携带 promoted 字段及 reply |
| L1-015-method-receivers | internal/gateway/gateway.go:60 | 指针方法接收者操作共享令牌桶 |
| L1-016-interfaces-method-sets | internal/gateway/task.go:76 | Processor 接口及指针实现的编译期断言 |
| L1-017-type-assertions | internal/gateway/gateway.go:135 | panic 值断言为 error 后保留错误身份 |
| L1-018-nil-interfaces | internal/gateway/gateway.go:90 | 检测非 nil 接口包裹的 typed-nil 实现 |
| L1-019-sentinel-errors | internal/gateway/task.go:15 | 共享哨兵区分输入、限流、队列满、关闭 |
| L1-020-error-wrapping | internal/gateway/task.go:109 | %w 保留处理器验证错误链 |
| L1-021-defer-order-return | internal/gateway/gateway.go:130 | defer recover 修改命名 error 返回值 |
| L1-022-panic-recover | internal/gateway/gateway.go:133 | worker 边界恢复 panic，失败计数并继续下一任务 |
| L1-023-closures | internal/gateway/http.go:26 | HTTP handler 捕获所属 Gateway 实例 |
| L1-024-generic-functions | internal/gateway/task.go:95 | 泛型函数抽取不同 map 值类型的排序键 |
| L1-025-generic-constraints | internal/gateway/task.go:92 | ~string 约束允许命名字符串键并支持比较 |
| L1-026-range-semantics | internal/gateway/gateway.go:149 | range channel 每轮独立任务，关闭后排空 |
| L1-027-goroutines | internal/gateway/gateway.go:107 | 按固定数量启动 worker goroutine |
| L1-028-channels-select-close | internal/gateway/gateway.go:194 | select 等待结果或取消，关闭派发 channel 排空 |
| L1-029-directional-channels | internal/gateway/gateway.go:146 | worker 参数为只读 channel，不能发送或关闭 |
| L1-030-io-copy | internal/gateway/http.go:18 | Reader→Writer 流式复制 HTTP 响应并检查写错误 |
| L1-031-fmt-formatting | internal/gateway/http.go:98 | %q 和 %d 生成精确 Prometheus label/计数 |
| L1-032-json-tags | internal/gateway/task.go:34 | json tags 固定请求字段名 |
| L1-033-error-identity | internal/gateway/http.go:54 | errors.Is 穿过包装错误选择 400 |
| L1-034-sorting-determinism | internal/gateway/task.go:101 | 显式排序，消除 map 遍历顺序影响 |
| L1-035-integer-boundaries | internal/gateway/task.go:129 | 在整数窄化前比较 MaxUint32 |
| L2-001-local-module-replace | internal/gateway/gateway_test.go:249 | 临时消费者激活本地 replace 并验证解析路径，生产模块无 require |
| L2-002-gofmt-vet | build.sh:16 | gofmt 列表非空即失败，随后运行 go vet |
| L2-003-table-tests | internal/gateway/gateway_test.go:37 | 命名表驱动子测试覆盖有效、边界及非法输入 |
| L2-004-test-coverage | build.sh:23 | go test -coverprofile 输出真实语句覆盖报告 |
| L2-005-go-benchmark | internal/gateway/gateway_test.go:283 | benchmark 测量真实词频、Unicode 和排序计算 |
| L2-006-build-tags | internal/gateway/integration_test.go:3 | integration 编译约束隔离监听端口的测试 |
| L2-007-cross-compilation | test.sh:39 | GOOS/GOARCH 交叉编译 arm64 静态程序，不执行异构产物 |
| L2-008-flag-cli | src/main.go:21 | flag 解析自检、服务参数及 profile 开关 |
| L2-009-slog-logging | src/main.go:59 | 标准库结构化日志写 stderr，移除时间属性 |
| L2-010-os-exec | internal/gateway/gateway_test.go:272 | 独立 argv 执行 go test，捕获输出和退出错误 |
| L2-011-package-tests | internal/gateway/export_test.go:11 | 外部测试包仅调用导出 API；模块根测试全部包 |
| L2-012-test-exit-status | internal/gateway/gateway_test.go:277 | 故意失败的子测试必须退出 1 且包含失败诊断 |
| L3-001-worker-pool-shutdown | internal/gateway/gateway.go:203 | 锁保证 submit/close 互斥，WaitGroup 等待队列排空 |
| L3-002-race-detector | test.sh:27 | -race 检验并发指标、任务提交与多次关闭 |
| L3-003-cpu-profile | src/main.go:39 | runtime/pprof 对真实程序采样，defer 停采样后关闭文件 |
| L3-004-custom-marshal-json | internal/gateway/task.go:50 | 自定义 MarshalJSON 返回固定字段和有序词频 |
| L3-005-binary-format | internal/gateway/task.go:60 | 版本字节与大端字段编码 checkpoint，校验长度/版本 |
| L3-006-tcp-echo | internal/gateway/integration_test.go:17 | 回环 TCP 上 echo 项目真实 checkpoint 并逐字节验证 |
