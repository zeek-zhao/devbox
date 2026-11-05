---
title: WALKTHROUGH · T-001-goroutine-leak（Go goroutine 泄漏与数据竞争排查）
track: go
lab: T-001-goroutine-leak
难度: P2          # P0–P5 刻度：环境齐全、双缺陷、需跨 -race / runtime.NumGoroutine / pprof 多工具交叉验证
status: draft
owner: zeek.zhao <zeek.zhao@foxmail.com>
last_verified: 2026-11-06
素材: 类型②实验（复现命令见 §1）+ 素材 S-07（CI 全绿 ≠ 教学质量达标）+ 素材 S-06（执行标记行纪律）
verified_env: devbox-go:latest（go 1.27.3 linux/amd64）
---

# WALKTHROUGH · T-001-goroutine-leak

> 依据 [docs/72 排障演练规范](../../../../docs/72-排障演练规范.md) §4 编写；D1 拍板见
> [docs/73 §11](../../../../docs/73-M11并发执行计划.md)。所有输出均为 2026-11-06 在
> devbox-go 容器内真跑所得（地址/goroutine 编号已按规范归一化，无内网信息）。
>
> 与样板 cpp/labs/T-001-asan-heap-overflow 的差异点：Go 轨道没有 valgrind/gdb 这类
> 外部检测器，工具链全部内建——`go vet`（静态）、`-race`（构建开关，同 ASan 的用法）、
> `runtime/pprof` + `go tool pprof`（profile）。另有一个 Go 特有环境坑：容器里挂载仓库
> 时 `go build` 会因 VCS 打戳失败，须加 `-buildvcs=false`（§4.0）。

## 1. 触发症状

在 devbox-go 容器内编译并直跑（无任何检测构建）：

```bash
go build -buildvcs=false -o /tmp/buggy . && /tmp/buggy; echo "rc=$?"
```

真实输出（类型②实验，2026-11-06）：

```text
leak: start
leak: goroutines before=1 after=101 delta=100
LEAK-CONFIRMED: 100 goroutines still blocked (expect 0 leaked)
rc=1
```

**症状一：静态检查全绿。** `go vet ./...` 退出 0、无任何告警；`go build` 干净。
代码里有两个真实缺陷（`main.go:19` 的 `results <- id` 永远无人接收、`main.go:18` 的
无锁 `counter++`），但静态检查一个都不报（来源：S-07）。

**症状二：goroutine 数只涨不跌。** 每个请求 spawn 一个 worker，高峰过后 delta=100
一个都不回落。真实事故的形态是：服务每处理一类请求泄漏一个 goroutine，RSS 与
goroutine 数随运行时长线性上涨，GC 压力与调度延迟随之劣化，最终 OOM 或请求超时。
**goroutine 泄漏不崩进程、不留 core**——进程退出时 goroutine 直接被销毁，若程序没有
`runtime.NumGoroutine` 自检（本 lab 内置），缺陷对外完全静默。

**症状三：数据竞争只在 -race 构建下现形。** plain 构建下 `counter++` 的丢失更新
静默发生（本程序不打印 counter，肉眼不可见）；`-race` 构建直接报
`WARNING: DATA RACE` 并钉到具体行（§4.2）。

## 2. 前 60 秒三条只读检查（成本从低到高，均不改任何状态）

| # | 命令 | 健康时看到 | 异常时看到 |
|---|---|---|---|
| 1 | 重跑一次并看标记行与 `echo $?` | `leak: start` 打印、退出码符合预期 | **无 `leak: start` 却报错/无错** → 二进制可能根本没被执行（素材 S-06：先排除环境，再谈代码）；`LEAK-CONFIRMED` + rc=1 → 泄漏坐实 |
| 2 | `go version` | `go version go1.27.3 linux/amd64` | `command not found` → 是镜像/环境问题（工具未装），不是代码问题；停，交维护者 |
| 3 | `bash repro.sh 2>&1 \| tail -3` | 异常现场：`LEAK-CONFIRMED: 100 goroutines still blocked ...` 且退出非零 | 无 `LEAK-CONFIRMED` 且退出 0 → 泄漏未被触发，走 §3 决策树 Q1' 分支 |

三条都只读：不改代码、不改构建、不装东西。

## 3. 互斥决策树（每叉二选一，无死分支、无循环）

```text
Q0 重跑 repro（plain 构建），标记行 leak: start 打印了吗？
├─ 没打印 → 素材 S-06 分支：先确认二进制真的被执行过——
│     ls -l ${TMPDIR:-/tmp}/devbox-go-T-001-goroutine-leak/buggy-leak  （存在且时间新鲜？）
│     再看 go build 是否真成功：容器内挂载仓库常见
│     "error obtaining VCS status: exit status 128"（§4.0，加 -buildvcs=false）
│     → 修环境，不是修代码
└─ 打印了 → Q1 对照行 delta 是多少（leak: goroutines before=N after=N delta=N）？
    ├─ delta >= 90 → 泄漏坐实 → Q2 泄漏的 goroutine 停泊在哪？
    │   ├─ [chan send]（LEAK_DUMP=1 或 pprof goroutine profile）
    │   │     → 发送端阻塞：查接收方——本 lab 是无缓冲 channel 全程无人接收
    │   │       （main.go:19 发送 / :26 无缓冲 make / :28 无人 <-results）→ §6 改动后验证
    │   ├─ [chan receive] / [select] / [IO wait]
    │   │     → 接收端等一个永不到来的事件（源 channel 没 close、连接没关），
    │   │       判读思路同源但案发行不同 → 与本 lab 现场不符，登记 UNVERIFIED 交维护者
    │   └─ 多数 [running]/[runnable] → 不是阻塞型泄漏，怀疑忙等/死循环 → 停，另立现场
    └─ delta < 90 → Q1' 隔 2 秒重跑一次仍小？
        ├─ 仍小 → 泄漏未被触发：对照 main.go:53 判据与 goroutine 调度环境，
        │     连续两次失败 → 停，登记 UNVERIFIED 交维护者（docs/71 §5 stop rules）
        └─ 变大了 → 只是调度慢，重跑即可

（附加）-race 构建报 WARNING: DATA RACE 吗？
├─ 报 → 读写两栈都钉在 counter++（main.go:18）→ 独立缺陷 2，与泄漏互不背锅（§5 H2）
└─ 不报 → 竞争偶发未触发（两 goroutine 没真正并发到同一地址）→ 加大并发重跑；
      泄漏判定不受影响（两条证据链独立）
```

## 4. 逐行判读（真实输出，2026-11-06 devbox-go 容器真跑）

### 4.0 环境坑先行：容器内 `go build` 报 VCS 错误

容器里把仓库 mount 到 /w 时，`go build` 会先死在这里：

```text
error obtaining VCS status: exit status 128
	Use -buildvcs=false to disable VCS stamping.
```

这不是代码缺陷：git 出于安全拒绝非属主操作仓库（容器 uid ≠ 仓库属主），Go 的
VCS 打戳随之失败。解法是构建参数加 `-buildvcs=false`（本 lab 的 repro.sh/run.sh
已内置）。教学点：**先分清「构建失败」与「程序缺陷」，再谈判读**——这正是
素材 S-06 的「环境问题被误读为代码问题」的 Go 变体。

### 4.1 plain 直跑（NumGoroutine 前后对照）

```text
leak: start
leak: goroutines before=1 after=101 delta=100
LEAK-CONFIRMED: 100 goroutines still blocked (expect 0 leaked)
rc=1
```

- `leak: start`：执行标记，证明二进制真的被跑过（素材 S-06）；
- `before=1`：进程起跑时只有 main 自己；`after=101`：100 个 worker 全部还活着；
- `delta=100`：**一个都没回落**——每请求一个、从不回收的泄漏指纹；
- `LEAK-CONFIRMED ...`：程序自检（判据在 `main.go:53`，`after-before >= 90`），
  以 rc=1 把「泄漏坐实」变成机器可判定的信号——真实系统里等价的观测是
  `/debug/pprof/goroutine` 曲线或容器指标。

### 4.2 -race 构建（数据竞争定位）

```text
==================
WARNING: DATA RACE
Read at 0xADDR by goroutine G:
  main.handleRequest()
      /w/go/labs/T-001-goroutine-leak/main.go:18 +0x39
  main.main.gowrap1()
      /w/go/labs/T-001-goroutine-leak/main.go:28 +0x12

Previous write at 0xADDR by goroutine G:
  main.handleRequest()
      /w/go/labs/T-001-goroutine-leak/main.go:18 +0x56
  main.main.gowrap1()
      /w/go/labs/T-001-goroutine-leak/main.go:28 +0x12

Goroutine G (running) created at:
  main.main()
      /w/go/labs/T-001-goroutine-leak/main.go:28 +0xba
==================
```

- `WARNING: DATA RACE`：诊断头，assert.sh 锚的就是它；
- `Read at 0xADDR ... main.go:18` 与 `Previous write at 0xADDR ... main.go:18`：
  读写**两份**调用栈钉在同一地址——`counter++`（读-改-写）在两个 goroutine 之间
  无同步交叠，18 行就是案发行；
- `main.go:28`（两处出现）：竞争双方的出生地——`go handleRequest(i, results)`，
  修复时从这里想「并发模型哪里错了」；
- **退出码注意**：GORACE 默认退出码是 66，但那只在程序自然退出时生效；本程序
  自检后走 `os.Exit(1)`，所以 -race 命中的进程 rc=1。**别拿「rc==66」当 -race
  命中的必要条件**，诊断头行才是锚点。
- 另：`-race` 构建跑一次通常报多条（本例 2 条），但条数不是稳定断言目标——
  取决于调度交错，断言只锚「至少命中一条」。

### 4.3 debug=2 栈快照（泄漏的停泊状态）

`LEAK_DUMP=1` 时程序打出 goroutine 栈快照（`pprof.Lookup("goroutine").WriteTo(os.Stdout, 2)`）：

```text
goroutine 7 [chan send]:
main.handleRequest(...)
	/w/go/labs/T-001-goroutine-leak/main.go:19
created by main.main in goroutine 1
	/w/go/labs/T-001-goroutine-leak/main.go:28 +0xe5
```

- `[chan send]`：**停泊状态**——这个 goroutine 卡在 channel 发送原语里，
  快照里 100 个 worker 全是这个状态（实测 `grep -c '\[chan send\]'` = 100）；
- `main.go:19`：案发行 `results <- id`；
- `created by ... main.go:28`：出生地，与 4.2 的 race 报告互证。

### 4.4 go tool pprof -top（泄漏聚合画像）

```text
Showing nodes accounting for 101, 100% of 101 total
Showing top 5 nodes out of 11
      flat  flat%   sum%        cum   cum%
       100 99.01% 99.01%        100 99.01%  runtime.gopark
         1  0.99%   100%          1  0.99%  runtime.goroutineProfileWithLabels
         0     0%   100%        100 99.01%  main.handleRequest
         0     0%   100%        100 99.01%  main.main
         0     0%   100%        100 99.01%  runtime.chansend
```

- goroutine profile 的语义：**每个 goroutine 记一个样本**，`101 total` =
  100 个泄漏 worker + 1 个正在采样的 dumper；
- `runtime.gopark` flat=100：park 是调度器「让 goroutine 睡觉」的原语——flat 全在
  运行时函数，说明没有用户代码在跑；
- 看 **cum 链**才能回答「谁把它们停下的」：`main.handleRequest` →
  `runtime.chansend`，cum=100 ≈ 泄漏数，把「泄漏多少」从快照逐个数升级成一行统计。

## 5. 认知学徒双层（docs/72 §4.2 拍板项）

### 5.1 predict–observe–explain（POE 点）

先书面写下你的预测再跑：

> **预测**：100 个请求全部处理完，程序会怎样退出？退出码是多少？
> （多数人预测：请求都「发出去了」，程序正常退出，rc=0。）

**观察**（真实输出）：

```text
leak: goroutines before=1 after=101 delta=100
LEAK-CONFIRMED: 100 goroutines still blocked (expect 0 leaked)
rc=1
```

**explain 落差**：请求不是「发出去」而是「卡住了」——无缓冲 channel 的发送必须
等到接收方就绪，100 个 worker 全部永久 park 在 `main.go:19`。更深一层：goroutine
泄漏**不崩进程、不留 core、不 panic**，进程退出时一切被静默销毁；若没有 NumGoroutine
自检，这个程序会以 rc=0 干净退出，而缺陷原封不动。所以「程序没报错」在并发缺陷
面前毫无证据价值（素材 S-07 的并发版）。

### 5.2 被否决的假设（≥2 条，含排除过程）

| # | 假设 | 若为真应看到 | 实际看到 | 结论 |
|---|---|---|---|---|
| H1 | goroutine 只是还没跑完（调度延迟），多等等就归零 | 隔几秒重跑 delta 下降；快照状态是 `[runnable]`/`[running]` | sleep 300ms 后 delta 恒 100；快照状态全是 `[chan send]` | 排除：是**永久阻塞**不是慢，发出去的值永远没人收 |
| H2 | 是数据竞争把程序搞坏了（race 警告 = 同步坏了 = 大概率死锁/崩溃） | -race 报 deadlock 或崩溃栈；修掉竞争泄漏随之消失 | WARNING: DATA RACE 只钉 `counter++`（main.go:18），泄漏栈在 `results <- id`（main.go:19）；两条证据链互不重叠 | 排除：两个**独立**缺陷；修复版（§6）两处都改才转绿 |
| H3 | channel 缓冲太小导致阻塞，加缓冲能修 | `make(chan int, 100)` 后 delta 归零 | 加缓冲只是把阻塞点从第 1 个发送推迟到缓冲满，之后照常泄漏；根因是**没有接收方** | 排除：缓冲治标不治本，修复必须有 drain/close 语义（§6） |
| H4（修复侧） | 修好后 `<-done` 收满 n 个，NumGoroutine 立刻归零 | drain 循环结束后 delta=0 | 直接测 delta=100——worker 收到放行后还需要被调度一次才真正退出（假阳性！） | 修正：观测代码要留调度窗口（`time.Sleep(100ms)`）再测；「修好」与「测准」是两件事 |

## 6. 改动后验证

修复 = 两处独立改动（在**副本**上做，别动 lab 自身的缺陷现场，否则断言全红）：

```bash
cd go/labs/T-001-goroutine-leak
mkdir -p /tmp/fixed && cp main.go go.mod /tmp/fixed/
```

手工改 /tmp/fixed/main.go：

```diff
-var counter int
+var counter atomic.Int64          // 缺陷 2 修复：atomic 替代裸 ++（import "sync/atomic"）

-	counter++     // 缺陷 2：数据竞争（-race 报 WARNING: DATA RACE）
-	results <- id // 缺陷 1：无缓冲且无人接收 → 永远阻塞在 chan send
+	counter.Add(1)
+	done <- id                       // 形参改为 done chan<- int

-	results := make(chan int) // 缺陷根源：无缓冲，且全程没有接收方
+	done := make(chan int)   // 修复：接收方 = 主 goroutine
 	for i := 0; i < n; i++ {
-		go handleRequest(i, results) // 每个请求 spawn 一个，从不回收
+		go handleRequest(i, done)
 	}
-	time.Sleep(300 * time.Millisecond) // 让 worker 都跑到阻塞点（真实事故里就是「高峰后不降」）
+	for i := 0; i < n; i++ {           // 缺陷 1 修复：drain——收满 n 个，worker 正常返回
+		<-done
+	}
+	time.Sleep(100 * time.Millisecond) // 调度窗口（§5.2 H4）：退出是异步的，测准需要等待
```

健康对照（2026-11-06 修复版真跑，plain 与 -race 各一次）：

```text
leak: start
leak: goroutines before=1 after=1 delta=0
leak: clean
rc=0
```

-race 修复版退出 0 且**无任何 WARNING: DATA RACE**（对照 §4.2 的异常输出）。
两个维度都绿 = 修好：`delta=0 / leak: clean` 是泄漏维度的健康判据，
「无 race 警告 + rc=0」是竞争维度的。注意不是只看「不崩」——修复版同样不崩，
区别只在观测数字。

## 7. 停止 / 升级条件（docs/71 §5 stop rules 对齐）

碰到任一条，停下来交维护者，不自行发挥：

1. `go` 本身 `command not found`，或 `go build` 报非 VCS 类错误（镜像缺工具/环境问题）；
2. 同一验证命令**连续两次失败**（含 assert.sh 连红两次）；
3. 栈快照停泊状态与本 lab 现场不符（非 `[chan send]` 主导），提示 Go 版本或
   调度行为漂移；
4. 需要修改 `go/labs/T-001-goroutine-leak/` 目录之外的文件才能继续；
5. 验收判据有歧义。

## 8. last verified 与 UNVERIFIED 表

**last verified: 2026-11-06**，devbox-go:latest 容器（go 1.27.3 linux/amd64，Docker
on Linux）。`run.sh` 连跑 3 次（含 assert.sh 内两次）均 RUN-PASS 5/5、退出码 0；
`assert.sh` 连跑 2 次均 ASSERT-PASS、退出码 0，结论一致。

| 判据 | 状态 | 原因 | 谁来补验 |
|---|---|---|---|
| `net/http/pprof` HTTP 端点形态（`curl /debug/pprof/goroutine?debug=2`） | UNVERIFIED | 本 lab 用 `runtime/pprof` 进程内钩子等效替代，未起 HTTP 服务 | 做服务形态变体 lab 时补 |
| 大并发（n=10000+）下 delta 与调度窗口是否仍稳定 | UNVERIFIED | 只实测 n=100、sleep 300ms | 压测变体或维护者换机器时复跑 |
| GORACE 退出码 66 路径（程序自然退出时的 -race 退出码） | UNVERIFIED | 本程序自检后 `os.Exit(1)`，66 未在本现场出现（§4.2 已文字注明） | 维护者用最小样例补测 |
| `go test -race` 单测形态的等价演练 | UNVERIFIED | 本 lab 用 main 程序而非 test 现场 | 做单测形态变体 lab 时补 |
| challenge/ 档的学习者实测用时与卡点 | UNVERIFIED | faded 档按定义不给判读，无真人试做记录 | 首位完成 challenge 的学习者回填 |

## 9. 素材来源

- **类型②实验**：§1/§4 全部现象均为 2026-11-06 在 devbox-go 容器内真跑所得，
  复现命令即 §1 与 `repro.sh`；输出已按 docs/72 §2 归一化（`0x` 地址 → `0xADDR`、
  goroutine 编号 → `G`），不含内网信息。
- **来源：S-07**（docs/24-G3素材池.md）：「CI 全绿 ≠ 教学质量达标」的 Go 变体——
  §1 症状一（vet 全绿但双缺陷在场）、run.sh step 1（健康对照）与 §5.1 POE 点
  （程序安静退出 ≠ 没有缺陷）都是该素材的应用。
- **来源：S-06**（docs/24-G3素材池.md）：「镜像探测失败被误读为代码问题」——
  §2 检查 1、§3 Q0 分支（标记行缺失 → 先证二进制真的被执行过）与 §4.0 的
  -buildvcs 环境坑判读都遵循该素材的纪律。
