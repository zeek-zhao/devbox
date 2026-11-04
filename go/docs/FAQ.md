---
track: go
guide: G5
dimensions: [D2, D5, D8]
level: P1
status: draft
links: [开发指南.md, 工具指南.md, 知识点清单.md]
examples: [L1-002-zero-values, L2-002-gofmt-vet, L3-002-race-detector]
---

# Go FAQ（G5）

> 一问一答，先结论、再一步命令、最后给「详见」。每条 50–200 字。
> G3 问题指南（按问题域的长排查）本轨道尚未建（M8 补齐），本篇先承接高频短问。

## 环境与镜像

### Q: devbox-go 里的 Go 是什么版本？想升级去哪改？

A: 版本只有一份真本：`images/versions.env` 的 `${GO_VERSION}`，Dockerfile 只写
`ARG GO_VERSION` 引用同名值，文档禁止写字面量。升级路径：改 versions.env →
发版流程重建镜像 → 全仓 examples job 自动换新。详见 [工具指南](工具指南.md) §1 / T0 §6。

### Q: 宿主机没装 Go，怎么编译 / 格式化 / 测试？

A: 全部走容器，别在宿主找 gofmt。格式化 `bash scripts/fmt.sh --lang go`；lint+测试+构建
一条龙 `docker run --rm -v "$PWD/go/project:/work" -w /work "ghcr.io/zeek-zhao/devbox-go:${TAG:-latest}" bash ./build.sh`
（宿主有 go 时该脚本会直接本地跑）。详见 [开发指南](开发指南.md) §4 / [工具指南](工具指南.md) §2.1。

### Q: go.mod 里的 go 版本比镜像新，报错了？

A: 镜像锁了 `GOTOOLCHAIN=local`，不会自作主张联网下载新工具链，这是防不可重现的特性
不是 bug。要么把 go.mod 降到镜像版本，要么升级 `${GO_VERSION}` 走发版。
详见 [工具指南](工具指南.md) §4。

### Q: 怎么进容器里手动排查？

A: `docker run --rm -it "ghcr.io/zeek-zhao/devbox-go:${TAG:-latest}" bash`；
跑用例想留现场就给 runner 加 `--keep` 再 `docker exec` 进去。
详见 [开发指南](开发指南.md) §1、§3。

## 构建与测试

### Q: go test 全绿，但我怀疑改动根本没跑到？

A: 先怀疑缓存：`go test` 默认复用上次的通过结果，重跑必须加 `-count=1`
（`docker run ... go test -count=1 ./...`）。再确认你改的包确实在 `./...` 范围内。
详见 [工具指南](工具指南.md) §2.1、§4。

### Q: 怎么跑单个教学用例？

A: 仓库根执行 `TAG=latest scripts/run-example.sh go <ID>`，例如
`TAG=latest scripts/run-example.sh go L1-002-zero-values`（实测 PASS 约 2s）；
列清单 `scripts/run-example.sh go --list`。ID 全表见 [知识点清单](知识点清单.md)。
详见 [开发指南](开发指南.md) §3。

### Q: runner 说「期望输出不匹配」，怎么对现场？

A: 期望值就是用例目录里的 `expected.txt`（逐行精确、忽略行尾空白）。加 `--keep`
保留容器，`docker exec` 进去手动跑 `run.sh`，把自己的输出和 expected 逐行 diff。
详见 [开发指南](开发指南.md) §3 / T0 §1。

## 并发与调试

### Q: 可疑的数据竞争怎么验证？

A: 竞争检测是工具链内置开关，不用装任何东西：`go test -race ./...` 或
`go run -race main.go`，命中时输出 DATA RACE 报告并给出两个冲突栈。
构造与排查全过程见用例 L3-002-race-detector。详见 [工具指南](工具指南.md) §2.3。

### Q: CPU 热点怎么查？

A: 先采集再分析：`go test -cpuprofile=cpu.out .` 采样，`go tool pprof <binary> cpu.out`
看 top/list；pprof 预装在 go 子命令里。完整流程见用例 L3-003-cpu-profile。
详见 [工具指南](工具指南.md) §2.4。

### Q: 有没有断点调试器？staticcheck 呢？

A: 都未预装（镜像内 `command -v dlv staticcheck` 实测无结果）。需要时容器内
`go install github.com/go-delve/delve/cmd/dlv@latest` 自装；但第三方 lint 不在
CI 门禁里，想进门禁必须走 T0 §3 的人工评审放行。详见 [工具指南](工具指南.md) §2.5。

## 文档与流程

### Q: 文档里能写具体版本号吗？

A: 不能。一律写 `images/versions.env` 的变量名（如 `${GO_VERSION}`）：写字面量，
升级当天文档集体过期，且与版本真本机制冲突。镜像 tag 同理，命令统一
`TAG=latest scripts/run-example.sh ...`。详见 T0 §6 / [开发指南](开发指南.md) §1。

### Q: 提交被拒：身份不允许 / AI 署名？

A: author 和 committer 都必须在白名单（当前 `zeek.zhao <zeek.zhao@foxmail.com>`），
且提交信息禁止 `Co-authored-by:` / `Generated with` 尾巴。先
`git config user.name zeek.zhao && git config user.email zeek.zhao@foxmail.com`。
详见 T0 §5。

### Q: 格式化 CI 红了但我本地「已经是格式好的」？

A: 本地和 CI 口径漂移多半是因为绕过了统一入口。宿主用 `bash scripts/fmt.sh --check --lang go`
复查（与 CI 同一命令、同一镜像口径），差异会直接列文件；不要自己手调空格。
gofmt 门禁语义见 L2-002-gofmt-vet。详见 [工具指南](工具指南.md) §2.2。

## 查不到时去哪查

- **练什么 / 用例 ID**：`go/docs/知识点清单.md`（L1–L4 各级表格）。
- **工具怎么调 / 是否预装**：[工具指南](工具指南.md)；本篇答不了的排查类问题等
  Go 轨道 G3 问题指南（M8 建成）承接，先按工具指南 §2 的定位命令走。
- **runner / CI / 门禁 / 提交 / 发版**：`docs/13-通用开发指南.md`（T0 单一真本）。
- **已知坑登记**：`docs/ROADMAP.md` 的 KI 段、`docs/40-问题清单.md`。
- **上游文档**：镜像内 `go doc <包>`、`go help <命令>` 是与 `${GO_VERSION}` 同版本的
  最可靠口径；再查不到带 `--keep` 现场去 GitHub issue 搜索 / 提 issue。
