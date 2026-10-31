# Go 毕业项目：并发任务网关

仅用标准库实现 HTTP → 有界 worker pool → channel 令牌桶 → Prometheus 文本指标 → 优雅退出。
模块没有 `require`，强制禁用代理、自动工具链下载和 VCS stamping。

## 目录

```text
go.mod                     零依赖模块及本地 replace 验证
src/main.go                CLI、TCP HTTP 服务、信号退出、可选 CPU profile
internal/gateway/          任务处理、限流、指标、HTTP、自检及测试
COVERAGE.md                全部 54 个用例的真实代码/测试/脚本落点
build.sh                   格式、vet、测试覆盖、静态构建、自检
check-runtime.sh           runtime 容器逐字比对，不监听端口
test.sh                    race、benchmark/profile、arm64 交叉编译
build/                     忽略的构建产物及测试报告
```

## 构建 / 运行 / 测试

从仓库根执行：

```bash
bash go/project/build.sh
go/project/build/devbox-go-project --addr 127.0.0.1:8080
bash go/project/test.sh
```

宿主没有 Go 时，脚本使用本地 `ghcr.io/zeek-zhao/devbox-go:${TAG:-latest}` 镜像，
挂载本项目、保持宿主用户身份，并使用 `--network none`，不会 pull。
构建可重复执行，产物是 `CGO_ENABLED=0 go build -trimpath` 生成的
`build/devbox-go-project`。runtime 验证命令为 `bash go/project/check-runtime.sh`；
缺产物先构建，缺本地 runtime 镜像明确 skip。

## HTTP 契约

`POST /submit` 接收单个 JSON，例如 `{"id":1,"text":"Alpha beta alpha"}`。
ID 为非零 uint32，文本为非空 UTF-8、最多 4096 字节，请求体上限 8192 字节，
拒绝未知字段及尾随 JSON。成功后等待 worker 返回小写词频结果，按词排序：

```json
{"id":1,"status":"completed","total":3,"words":[{"word":"alpha","count":2},{"word":"beta","count":1}]}
```

设置 `Accept: application/octet-stream` 返回 9 字节 checkpoint：
版本 1（1 字节）、ID（4 字节大端）、总词数（4 字节大端）。
400 表示输入错误，429 表示无令牌，503 表示队列满或已关闭，
408 表示等待取消，500 表示处理器失败（记录错误，panic 隔离不杀死 worker）。
队列满会归还令牌；已接收的任务即使客户端取消，也会完成并计入指标。

`GET /healthz` 正常返回 `ok`；进入 pool 关闭状态后返回 503。
`GET /metrics` 输出带 HELP/TYPE 的 `gateway_tasks_total{state="..."}`：
accepted、completed、failed、rejected 四种计数，各自只增不减。
HTTP 方法由路由限制；其他路径返回 404。

默认 4 workers、16 队列、8 burst，每 100ms 补充一个令牌（不超过 burst）。
可用 `--workers`、`--queue`、`--burst`、`--refill` 调整。
SIGINT/SIGTERM 先 `srv.Shutdown`（10 秒超时，超时明确报错并强制关闭连接），
再关闭派发 channel，排空任务并等待 workers 和 ticker 退出。
处理器应是有限、可终止的计算；无法强杀任意 Go goroutine。

`--self-check` 用内存 HTTP 请求覆盖健康检查、Unicode 排序、令牌耗尽、
显式补充令牌、二进制结果、非法输入、关闭拒绝和最终指标。
使用与生产相同的 refill 操作，但不启动 ticker，因此不依赖调度速度、时间或端口。
只有 `bash go/project/test.sh --integration` 才启用真实回环 TCP 测试。
无宿主 Go 时，在容器内只编译静态测试程序，再在宿主执行 TCP 测试，
所有容器（包括测试容器）均不监听端口。

`--cpu-profile build/server.pprof` 可采集服务 CPU profile。
测试脚本在真实词频 benchmark 上采样并验证存在处理器样本，
报告位于 `build/benchmark.txt`、`build/profile.txt`；
语句覆盖位于 `build/coverage.out`。测试还验证 typed-nil、panic 后继续处理、
队列满、客户端取消、并发关闭排空、本地 replace 与失败测试退出码。
本地 replace 测试仅在 `t.TempDir()` 的 `probe.mod` 中建立本地消费者，
激活项目已有的 `replace ... => .` 并验证解析目录；
项目 `go.mod` 始终不含 `require`，不下载任何外部模块。
