# SOLUTION · T-001-deadlock-oom（faded 挑战档答案）

> 仅供自查，**不进 CI 断言**（docs/72 §4.3）。先自己写完判读再回来对。
> 以下输出均为 2026-11-06 devbox-java 容器真跑（地址/pid/线程号已归一化）。

## 1. OOM：细分与成因

```text
Exception in thread "main" java.lang.OutOfMemoryError: Java heap space
	at OomMain.main(OomMain.java:15)
```

- 细分是 `Java heap space`（堆耗尽，不是 Metaspace / GC overhead）；
- 成因：`bag` 持有全部引用且分配无界——是**分配速率型**不是泄漏型；栈顶（OomMain.java:15）
  只是压垮现场，根因是此前所有 1MB 块都存活。加大 `-Xmx` 只会推迟结局；
  治理根因 = 有界分配（§3）。

## 2. 卡死：哪一类，闭环在哪

`jps -l` 进程还在 + `top -b -n1 -p <pid>` 的 %CPU=0.0 → 锁等待卡死（忙循环会是 ~100%）。
`jcmd <pid> Thread.print`：

```text
Found one Java-level deadlock:
"worker-1":
  waiting to lock monitor 0xADDR (object 0xADDR, a java.lang.Object),
  which is held by "worker-2"
"worker-2":
  ... which is held by "worker-1"
```

worker-1 持 A 等 B、worker-2 持 B 等 A——加锁顺序不一致。worker 完整栈帧里
`BLOCKED (on object monitor)` + 同帧 `- locked <0xADDR>` 与
`- waiting to lock <0xADDR>` 把持锁点/等锁点钉到 DeadlockMain.java:27-29。
`jstack <pid>` 复核同报 `Found one Java-level deadlock`（第二检测器）。

## 3. 修复 diff 与验证

死锁：统一锁序 + 移除 GATE 屏障（关键坑：只改序不动 GATE 时，worker-2 卡在
`synchronized(LOCK_A)` 外面数不到 GATE.countDown()=2，worker-1 永远等在 GATE——
修复版实测仍卡死过一次，被否决的假设 H4 记录了这一过程）：

```java
Thread t1 = new Thread(() -> lockOrder(LOCK_A, LOCK_B), "worker-1");
Thread t2 = new Thread(() -> lockOrder(LOCK_A, LOCK_B), "worker-2");
// lockOrder 里不再 countDown/await
```

OOM：有界 + 小块：

```java
for (int i = 0; i < 64; i++) {
    bag.add(new byte[256 * 1024]);
}
```

验证（2026-11-06 修复版真跑）：

```text
deadlock: start
critical: entered by worker-1
critical: entered by worker-2
deadlock: done          # rc=0

oom: start
oom: done size=64       # rc=0（同 -Xmx32m）
```

两个缺陷都绿才算修好；判据是「退出 + rc=0 + 标记行收尾」。把改动落到 lab 的
DeadlockMain.java / OomMain.java 前先想清楚——那是缺陷现场，assert.sh 按设计断言
「故障在场」，修了它 lab 就废了。
