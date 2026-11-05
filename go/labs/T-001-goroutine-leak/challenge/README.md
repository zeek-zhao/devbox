# T-001-goroutine-leak · faded 挑战档

> 规则（docs/72 §4.3）：这里只给触发症状与可用工具清单，不给判读。
> 请先自己按 WALKTHROUGH 的 §4.1 结构（触发症状 / 前 60 秒三条只读检查 / 互斥决策树 /
> 逐行判读 / 改动后验证）写一遍，再对照 [SOLUTION.md](SOLUTION.md)。

## 触发症状

同事报障：一个 Go 请求处理服务「goroutine 数随运行时长线性上涨、两天后 OOM」。
你在 devbox-go 容器内复现（缩小版：100 个请求一次性打进来）：

```bash
go build -o /tmp/buggy . && /tmp/buggy; echo "rc=$?"
```

程序打印几行观测输出后安静退出。`go vet ./...` 干净、`gofmt` 干净、CI 全绿——
但线上 goroutine 只涨不跌是事实，且 review 时谁也指不出哪一行有问题。

## 你的任务

1. 先排除「二进制没被真正执行 / 构建根本没成功」（容器里挂载仓库跑 `go build`
   有一个 Go 特有的环境坑，先趟过去）；
2. 判断「goroutine 只涨不跌」与「隐藏的并发隐患」各是哪个缺陷，用工具把它们
   分别钉到 main.go 的具体行；回答：两个缺陷互相关联吗？修一个另一个会好吗？
3. 给出修复 diff 与修复后的验证证据（两个维度都要复查；注意「修好」与「测准」
   是两件事——观测代码本身也有一个坑）。

## 可用工具清单（均在 devbox-go 镜像内，宿主上没有）

- go 1.27（含 `go build` / `go vet` / `gofmt`）
- `-race` 构建开关（同 ASan 的用法：构建开关而非独立二进制；注意退出码语义）
- `runtime/pprof`（进程内取 goroutine profile/栈快照；`go tool pprof -top` 聚合）
- 同目录 `repro.sh` / `run.sh` / `assert.sh` 可作对照（先别看 WALKTHROUGH）

## 提交判据

`bash assert.sh` 输出 ASSERT-PASS；你的判读文档里至少有 1 个 predict–observe–explain
点与 2 条被否决的假设。
