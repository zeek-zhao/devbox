# T-001-deadlock-oom · faded 挑战档

> 规则（docs/72 §4.3）：这里只给触发症状与可用工具清单，不给判读。
> 请先自己按 WALKTHROUGH 的 §4.1 结构（触发症状 / 前 60 秒三条只读检查 / 互斥决策树 /
> 逐行判读 / 改动后验证）写一遍，再对照 [SOLUTION.md](SOLUTION.md)。

## 触发症状

同事报障：批处理作业「有时候跑不完也不报错，只能 kill 掉」，今天还偶发
`OutOfMemoryError` 把进程带走。devbox-java 镜像内复跑：

```bash
docker run --rm -v "$PWD":/w -w /w ghcr.io/zeek-zhao/devbox-java:latest \
  bash java/examples/T-001-deadlock-oom/repro.sh
```

输出先以 `Exception in thread "main" java.lang.OutOfMemoryError: Java heap space`
结束一个程序；随后另一个程序打印 `deadlock: start` 后再无下文，进程不退出也不报错；
`jcmd Thread.print` 能抓到 `Found one Java-level deadlock:`。

## 你的任务

1. 先排除「程序根本没跑起来」分支（标记行与 jps）；
2. 两个缺陷分别定性：OOM 判断细分类型（heap space？）与成因（无界分配还是泄漏）；
   卡死判断是哪一类（忙循环还是锁等待），并用 ≥2 个工具把互等闭环钉到具体线程与锁；
3. 给出两个缺陷的修复与修复后的验证证据；特别地，死锁修复必须处理「为确定性而设的
   辅助机制」带来的坑（不做这一步，只统一锁序的修复版仍会卡死）。

## 可用工具清单（均在 devbox-java 镜像内，宿主上没有）

- javac / java（OpenJDK 21，`-Xmx` 可调堆上限）
- jps（先抓 pid——容器内 attach 只认同 PID 命名空间内的 JVM）
- jcmd Thread.print / VM.uptime（互等闭环与存活证据）
- jstack（第二检测器，交叉验证）
- top -b -n1 -p <pid>（CPU 对照，区分忙循环与锁等待）
- 同目录 repro.sh / run.sh / assert.sh 可作对照（先别看 WALKTHROUGH）

## 提交判据

`bash assert.sh` 输出 ASSERT-PASS；你的判读文档里至少有 1 个 predict–observe–explain
点与 2 条被否决的假设。
