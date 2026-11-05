# SOLUTION · T-001-goroutine-leak（faded 挑战档答案）

> 仅供自查，**不进 CI 断言**（docs/72 §4.3）。先自己写完判读再回来对。
> 以下输出均为 2026-11-06 devbox-go 容器真跑（地址/goroutine 编号已归一化）。

## 1. 先趟环境坑，再谈代码

容器里把仓库 mount 进来直接 `go build` 会先死在 VCS 打戳（git 拒绝非属主操作）：

```text
error obtaining VCS status: exit status 128
	Use -buildvcs=false to disable VCS stamping.
```

这是环境问题不是代码问题（素材 S-06 的 Go 变体），加 `-buildvcs=false`。
然后确认标记行 `leak: start` 打印了 → 二进制真的被执行过 → 可以谈代码。

predict–observe–explain：预测「100 个请求处理完程序正常退出 rc=0」→ 观察
`delta=100`、`LEAK-CONFIRMED`、rc=1 → 解释：无缓冲 channel 全程无人接收，
100 个 worker 永久 park。若程序没有 NumGoroutine 自检，它会以 rc=0 安静退出、
缺陷原封不动——「CI 全绿/程序不报错」在并发缺陷面前毫无证据价值（素材 S-07）。

## 2. 两个缺陷分别钉在哪，互相关联吗

**缺陷 1：goroutine 泄漏（NumGoroutine 对照 + 栈快照 + pprof 三证）**

```text
leak: goroutines before=1 after=101 delta=100          ← 一个都不回落
goroutine 7 [chan send]:                                ← 停泊状态指纹
main.handleRequest(...)
	.../main.go:19                                      ← 案发行：results <- id
created by main.main in goroutine 1
	.../main.go:28
```

`go tool pprof -top`：`main.handleRequest` cum=100（goroutine profile 每
goroutine 一个样本，累计值 ≈ 泄漏数）。

**缺陷 2：数据竞争（-race）**

```text
WARNING: DATA RACE
Read at 0xADDR by goroutine G:
  main.handleRequest()
	.../main.go:18                                      ← 案发行：counter++
Previous write at 0xADDR by goroutine G:
	.../main.go:18
Goroutine G (running) created at:
	.../main.go:28                                      ← 出生地：go handleRequest(...)
```

**互相关联吗？否。** 两条证据链互不重叠：race 只钉 `counter++`（main.go:18），
泄漏栈在 `results <- id`（main.go:19）。修掉竞争泄漏仍在；修好泄漏竞争仍在——
修复 diff 必须两处都改（细节见上层 WALKTHROUGH §6）。

注意退出码：GORACE 默认 66 只在程序自然退出时生效；本程序自检后 `os.Exit(1)`，
所以 -race 命中的现场 rc=1。锚诊断头行，别锚退出码数值。

## 3. 被否决的假设（自查：你至少写了两条吗）

- H1 只是调度慢？→ 多等 delta 应下降、栈状态应 `[runnable]`；实际恒 100 且全是
  `[chan send]` → 否，是永久阻塞。
- H2 race 把程序搞坏了？→ 应见 deadlock/崩溃栈；实际两证据链独立 → 否。
- H3 缓冲太小？→ `make(chan int, 100)` 只是把阻塞推迟到缓冲满 → 否，根因是没有
  接收方，修复要有 drain/close 语义。
- H4（修复侧）drain 收满就归零？→ 立即测 delta=100——worker 退出是异步的，
  观测代码要留调度窗口再测，否则健康程序也误报 → 「修好」≠「测准」。

## 4. 修复 diff 与验证

```diff
-var counter int
+var counter atomic.Int64
...
-	counter++
+	counter.Add(1)
...
-	results := make(chan int) // 无缓冲，且全程没有接收方
+	done := make(chan int)   // 接收方 = 主 goroutine
...
-	time.Sleep(300 * time.Millisecond)
+	for i := 0; i < n; i++ {           // drain：收满 n 个，worker 正常返回
+		<-done
+	}
+	time.Sleep(100 * time.Millisecond) // 调度窗口
```

验证（2026-11-06 修复版真跑，plain 与 -race 各一次）：

```text
leak: start
leak: goroutines before=1 after=1 delta=0
leak: clean
rc=0                                   # -race 版同样 rc=0、无任何 WARNING: DATA RACE
```

两个维度都绿才算修好；把改动落到 lab 的 main.go 前先想清楚——那是缺陷现场，
assert.sh 按设计断言「故障在场」，修了它 lab 就废了。
