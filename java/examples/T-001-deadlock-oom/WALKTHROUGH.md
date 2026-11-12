---
title: WALKTHROUGH · T-001-deadlock-oom（死锁互等闭环与小堆 OOM 排查）
track: java
lab: T-001-deadlock-oom
难度: P2          # P0–P5 刻度：双缺陷两类卡死形态，需 jcmd/jstack/top/javac 四工具交叉验证
status: draft
owner: zeek.zhao <zeek.zhao@foxmail.com>
last_verified: 2026-11-06
素材: 素材 S-14（两把锁反序死锁）+ 类型②实验（小堆 OOM，复现命令见 §1）
verified_env: devbox-java:latest（OpenJDK 21.0.12.1 / jps-jcmd-jstack 同源 JDK）
---

# WALKTHROUGH · T-001-deadlock-oom

> 依据 [docs/72 排障演练规范](../../../docs/72-排障演练规范.md) §4 编写；D1 拍板见
> [docs/73 §11](../../../docs/73-M11并发执行计划.md)。所有输出均为 2026-11-06 在
> devbox-java 容器内真跑所得（锁地址 / tid / nid / pid 已按规范归一化为 `0xADDR` /
> `#N` / `<PID>`，无内网信息）。

## 1. 触发症状

devbox-java 容器内（`bash repro.sh` 内部同款动作，DeadlockMain 编译后后台启动）：

```bash
docker run --rm -v "$PWD":/w -w /w ghcr.io/zeek-zhao/devbox-java:latest \
  bash java/examples/T-001-deadlock-oom/repro.sh; echo "rc=$?"
```

真实输出（类型②实验 + 来源：S-14，2026-11-06）：

```text
oom: start
Exception in thread "main" java.lang.OutOfMemoryError: Java heap space
	at OomMain.main(OomMain.java:15)
deadlock: start
Found one Java-level deadlock:
=============================
"worker-1":
  waiting to lock monitor 0xADDR (object 0xADDR, a java.lang.Object),
  which is held by "worker-2"

"worker-2":
  waiting to lock monitor 0xADDR (object 0xADDR, a java.lang.Object),
  which is held by "worker-1"
rc=1
```

**症状一：小堆 OOM。** `-Xmx32m` 下 OomMain 秒级死于
`Exception in thread "main" java.lang.OutOfMemoryError: Java heap space`——
无界分配把堆打满，时间只由堆上限决定。

**症状二：程序不退出也不报错（活着但卡死）。** `deadlock: start` 打印后 main 卡在
`t1.join()`（DeadlockMain.java:18）永远等不到；`critical: entered` 一行始终缺席——
两个 worker 都卡在第二把锁上。

**症状三：互等闭环写进报告。** `jcmd <pid> Thread.print` 直接给出
`Found one Java-level deadlock:` 与两段 `waiting to lock ... which is held by ...`。

## 2. 前 60 秒三条只读检查（成本从低到高，均不改任何状态）

| # | 命令 | 健康时看到 | 异常时看到 |
|---|---|---|---|
| 1 | `jps -l` | 无残留 Java 进程（或只有你认识的那个） | DeadlockMain **还在** → 不是崩了，是卡死（S-14 检查 1） |
| 2 | `top -b -n1 -p <pid>` | —— | `%CPU` 接近 **0%** → 锁等待卡死；接近 100% → 忙循环卡死，另查（S-14 检查 2） |
| 3 | `jstack <pid> \| grep -c BLOCKED` | `0` | `>= 2` → 两个线程都在等锁（S-14 检查 3） |

三条都只读：不 kill、不重启、不装东西。

## 3. 互斥决策树（每叉二选一，无死分支、无循环）

```text
Q0 标记行 deadlock: start / oom: start 打印了吗？
├─ 没打印 → 进程根本没起来（jps 找不到、classpath 错、容器没挂载）：
│     jps -l; ls -l *.class   → 修环境/调用方式，不修代码（S-06 分支）
└─ 打印了 → Q1 程序退出/崩了吗？
    ├─ 退了且 rc!=0 → Q2 诊断头是什么？
    │   ├─ Exception in thread "main" java.lang.OutOfMemoryError
    │   │     → 看冒号后的细分：Java heap space（堆耗尽，本 lab 现场）/
    │   │       GC overhead limit exceeded / Metaspace → 各自走不同分支
    │   │     → 判断是「分配速率太快（无界分配）」还是「泄漏（只增不减）」：
    │   │       本 lab 是前者 → 治理分配边界，不是加大堆（§6）
    │   └─ 其他异常 → 与本 lab 现场不符，停止并登记 UNVERIFIED 交维护者
    └─ 没退出（活着但卡死）→ Q3 CPU 占用多少？
        ├─ 接近 100% → 忙循环卡死（busy-wait / 无退出条件的 while），
        │     本 lab 现场不符，停止并登记 UNVERIFIED
        └─ 接近 0% → Q4 抓栈（先抓 pid：jps -l，容器内 jcmd 只认同 PID 命名空间
              且同用户的 JVM）：
            ├─ Found one Java-level deadlock → 读闭环两段「waiting to lock /
            │     which is held by」→ 谁持 A 等 B、谁持 B 等 A → 统一加锁顺序（§6）
            ├─ 有 BLOCKED 但无 deadlock 段 → 死等外部资源（连接池/远端），
            │     看栈顶 waiting on condition → 与本 lab 现场不符，登记 UNVERIFIED
            └─ attach 失败/抓不到 → jps 能看到吗？
                  ├─ 看不到 → JVM 没起来，回 Q0
                  └─ 看得到但 attach 失败 → 用户/PID 命名空间不对（容器内注意
                        用容器内的 jcmd 与容器内 pid）→ 修环境，停止交维护者
```

## 4. 逐行判读（真实输出，2026-11-06 devbox-java 容器真跑）

### 4.1 OOM 现场（症状一）

```text
oom: start
Exception in thread "main" java.lang.OutOfMemoryError: Java heap space
	at OomMain.main(OomMain.java:15)
```

- `oom: start` 是执行标记（素材 S-06 的方法论）：它打印过 = 程序真的跑过、
  崩在运行期而非没起来；
- `Java heap space` = 堆耗尽（不是 Metaspace / GC overhead / 直接内存，细分决定分支）；
- 栈只有一帧 `OomMain.main(OomMain.java:15)`：案发行就是 `bag.add(new byte[1024*1024])`
  ——分配请求那一刻堆拿不出 1MB 连续空间。注意：**OOM 的栈顶指认的是「压垮现场」，
  不一定是「根因」**——根因是这 15 次×1MB 全都存活（bag 一直持有引用）。

### 4.2 活着但卡死（症状二，run.sh step 3）

```text
jps: pid=<PID> DeadlockMain
VM.uptime: 0.266 s
```

- jps 还能看到 DeadlockMain、VM.uptime 在增长 → 进程活着；但 `critical: entered`
  永不打印、main 卡在 join → 「不退出 + 不报错」的第三类状态。健康时这两行的对照：
  修复版数秒内退出 rc=0（§6）。

### 4.3 CPU 对照（症状二佐证，run.sh step 4）

```text
| pid=<PID> %CPU=0.0
```

- `top -b -n1 -p <pid>` 的 %CPU 接近 0：线程都在 `BLOCKED`，内核根本没给它们调度时间
  ——这是「等锁」；若忙循环卡死这里会是 ~100%。一条命令区分两类卡死（S-14 检查 2）。

### 4.4 jcmd Thread.print 互等闭环（症状三，S-14 定位命令）

```text
"worker-1":
  waiting to lock monitor 0xADDR (object 0xADDR, a java.lang.Object),
  which is held by "worker-2"
"worker-2":
  waiting to lock monitor 0xADDR (object 0xADDR, a java.lang.Object),
  which is held by "worker-1"
```

- 闭环结构：worker-1 持第一把等第二把、worker-2 反向——**加锁顺序不一致**写在报告里；
- 报告里两把锁的对象地址不同（`object 0xADDR` 两处不一样）→ 是两个不同的 Object
  实例，不是「同一把锁自等待」；
- JVM 能报 `Found one Java-level deadlock` 是因为 monitor 等待构成可检测的环路；
  若换成 `java.util.concurrent` 的 Lock 死等，环路检测不出来（那是「卡死但无
  deadlock 段」分支，看 `waiting on condition`）。

### 4.5 worker 线程完整栈帧（Thread.print 下半段）

```text
"worker-2" #N [91] prio=5 os_prio=0 cpu=0.11ms elapsed=2.20s tid=0xADDR nid=91 waiting for monitor entry  [0xADDR]
   java.lang.Thread.State: BLOCKED (on object monitor)
	at DeadlockMain.lockOrder(DeadlockMain.java:28)
	- waiting to lock <0xADDR> (a java.lang.Object)
	- locked <0xADDR> (a java.lang.Object)
	at DeadlockMain.lambda$main$1(DeadlockMain.java:15)
```

- `BLOCKED (on object monitor)` + `waiting for monitor entry`：等的是 **synchronized
  monitor 锁**（不是 j.u.c Lock）；
- `- locked <0xADDR>` 与 `- waiting to lock <0xADDR>` 同帧出现：**持锁点与等锁点就在
  同一个 synchronized 嵌套块**（DeadlockMain.java:27-29），案发行钉死；
- `Java stack information for the threads listed above` 段末的 `Found 1 deadlock.`
  是 JVM 自己数出来的闭环数，可与上文闭环段互相印证。

### 4.6 jstack 交叉验证（run.sh step 6）

jstack 与 jcmd 是两个独立入口（同为 attach 机制但工具路径不同），两者都报
`Found one Java-level deadlock` 且闭环方向一致——同一现象两份独立证据才叫钉死
（docs/72 要求 run.sh ≥2 种工具的原因）。

## 5. 认知学徒双层（docs/72 §4.2 拍板项）

### 5.1 predict–observe–explain（POE 点）

先书面写下你的预测再跑（DeadlockMain 后台启动后观察）：

> **预测**：两个线程先后拿 A、B，最终会怎样？程序几秒内会退出吗？
> （多数人预测：有一方会拿到两把锁进入临界区，程序正常退出。）

**观察**（真实输出）：

```text
deadlock: start
jps: pid=<PID> DeadlockMain        ← 还活着
| pid=<PID> %CPU=0.0               ← 但 CPU 为 0
critical: entered ...              ← 永远不出现
```

**explain 落差**：GATE 同步屏障让两线程都先拿到各自的**第一**把锁后同时去抢**第二**把
——A、B 两把锁互相被对方持有，谁也不放、谁也进不去。程序既不崩也不退（main 的 join
无超时），CPU 又是 0——「活着的卡死」没有异常可报，唯一的出口是主动抓栈。

### 5.2 被否决的假设（≥2 条，含排除过程）

| # | 假设 | 若为真应看到 | 实际看到 | 结论 |
|---|---|---|---|---|
| H1 | 进程没退出是「启动慢」/还在干活 | CPU 高、栈里线程在 RUNNABLE 且栈在变化 | `%CPU=0.0`；连续两次抓栈 worker 帧完全不动 | 排除：死等，非慢跑 |
| H2 | 是忙循环（while 没退出条件）空转卡死 | top 接近 100% | `%CPU=0.0`，且线程状态 `BLOCKED (on object monitor)` | 排除：锁等待卡死 |
| H3 | 是 JVM 内部 bug 或 native 死锁（如 JNI 层） | 报 `Found one deadlocked thread`（native 层描述）或栈里有 native 帧 | 报 `Found one Java-level deadlock`，栈全是 Java 帧（DeadlockMain.java） | 排除：纯 Java monitor 闭环 |
| H4 | 修复只要把两个线程改成同一取锁顺序就行 | 同序后线程依次拿锁，程序退出 | **实测踩坑**：只改序不动 GATE 时，worker-2 会卡在 `synchronized(LOCK_A)` 外面永远数不到 GATE.countDown()=2，worker-1 反而永远等在 GATE——换个姿势继续死锁；正确修复要**连同测试用的 GATE 屏障一起移除**（§6 的修复版就是这么写的，rc=0 退出） | 排除：修复必须覆盖「为确定性而生的辅助机制」，否则按下葫芦浮起瓢 |

## 6. 改动后验证

修复分两个缺陷，在**副本**上做（别改 lab 自身的缺陷现场，否则断言全红，lab 就废了）。

**修复 1（死锁）：统一加锁顺序，并移除仅为确定性而设的 GATE 屏障。**

```java
// 两个线程都传 lockOrder(LOCK_A, LOCK_B)，lockOrder 里不再 countDown/await：
private static void lockOrder(Object first, Object second) {
    synchronized (first) {
        synchronized (second) {
            System.out.println("critical: entered by " + Thread.currentThread().getName());
        }
    }
}
```

2026-11-06 修复版真跑（健康对照，`timeout 30` 兜底）：

```text
deadlock: start
critical: entered by worker-1
critical: entered by worker-2
deadlock: done
rc=0
```

对照缺陷现场（§4.2）：两个 critical 都打印、程序正常退出 rc=0。注意 H4 的教训：
只统一顺序而不移除 GATE，修复版本身仍会卡死——修复要覆盖全部成因机制。

**修复 2（OOM）：治理无界分配这个根因（有界 + 小块），而不是加大堆。**

```java
for (int i = 0; i < 64; i++) {          // 有界
    bag.add(new byte[256 * 1024]);      // 小块，避开 G1 humongous 对象
}
System.out.println("oom: done size=" + bag.size());
```

2026-11-06 修复版真跑（同样 `-Xmx32m`）：

```text
oom: start
oom: done size=64
rc=0
```

对照缺陷现场（§4.1）：同堆上限下 rc=0 收场。反证「加大堆不是修法」：无界分配下
`-Xmx` 从 32m 改大只会把 OOM 推迟到更晚的时刻，分配速率不变、结局不变。
日常排障补充：怀疑泄漏型 OOM（只增不减）时用 `jcmd <pid> GC.heap_info` 与
`jmap -histo` 对比两个时点的类直方图——本 lab 是分配速率型，不在其射程。

两个缺陷都绿 = 修好；判据是「程序退出 + 退出码 0 + 标记行收尾（deadlock: done /
oom: done）」，不是「没报错」。

## 7. 停止 / 升级条件（docs/71 §5 stop rules 对齐）

碰到任一条，停下来交维护者，不自行发挥：

1. `javac` / `java` / `jps` / `jcmd` / `jstack` 任一 `command not found`（镜像缺工具，环境问题）；
2. 同一验证命令**连续两次失败**（含 assert.sh 连红两次）；
3. jps 看得到进程但 jcmd/jstack attach 失败（同用户/同 PID 命名空间前提被破坏，环境问题）；
4. Thread.print 报 `Found one deadlocked thread`（native 层）或「BLOCKED 但无 deadlock 段」，
   与本 lab 现场不符；
5. OOM 细分不是 `Java heap space`（如 Metaspace / GC overhead / direct memory），分支不同；
6. 需要修改 `java/examples/T-001-deadlock-oom/` 目录之外的文件才能继续；
7. 验收判据有歧义。

## 8. last verified 与 UNVERIFIED 表

**last verified: 2026-11-06**，devbox-java:latest 容器（OpenJDK 21.0.12.1+1-1-24.04.4-Ubuntu，
Docker on Linux）。`run.sh` 连跑 2 次、`assert.sh` 连跑 2 次，结论均一致（RUN-PASS 6/6、
ASSERT-PASS）。

| 判据 | 状态 | 原因 | 谁来补验 |
|---|---|---|---|
| `j.u.c` Lock（非 synchronized）死等不进 deadlock 段的分支（决策树 Q4 中枝） | UNVERIFIED | 本镜像未构造 ReentrantLock 双向死等现场 | 做变体 lab 时补 |
| `jcmd <pid> GC.heap_info` 泄漏型 OOM 判读（§6 补充） | UNVERIFIED | 本 lab 是分配速率型，未构造泄漏现场 | 变体 lab 或维护者复验 |
| 容器内非默认用户跑 jcmd attach（--user 场景） | UNVERIFIED | 本轮全部以镜像默认用户跑 | CI 真跑如换用户则补验 |
| challenge/ 档的学习者实测用时与卡点 | UNVERIFIED | faded 档按定义不给判读，无真人试做记录 | 首位完成 challenge 的学习者回填 |

## 9. 素材来源

- **来源：S-14**（docs/24-G3素材池.md）：两把锁反序死锁——§1 症状二/三、§2 三条只读检查、
  §3 决策树 Q3/Q4、§4.4 的互等闭环与 §4.6 双工具交叉验证均按该素材的现场与检查清单落地；
- **类型②实验**：§1 症状一（小堆 OOM）、§4.1、§4.3、§4.5、§5.2 H4 的踩坑与 §6 修复验证
  全部现象为 2026-11-06 在 devbox-java 容器内真跑所得，复现命令即 §1 与 `repro.sh`；
  输出已归一化（`0x` 地址 → `0xADDR`、线程号 → `#N`、pid → `<PID>`），不含内网信息。
