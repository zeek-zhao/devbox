## 考点
用 Go 工具链执行 `hello.go`，验证 `go run` 和标准库并发原语 `goroutine`、`WaitGroup`、`Mutex` 可用。
输出检查并发用例标记及 1 到 100 的求和，不依赖并发调度顺序。

## 运行
在仓库根目录执行：`TAG=latest scripts/run-example.sh go hello`。

## 易错点
脚本使用 `go run hello.go`，显式运行单个源码文件；不要改成 `go run .`，后者会要求包/模块上下文。
不要让 `GOFLAGS` 注入不适用于此文件运行方式的构建参数。
