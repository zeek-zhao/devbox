# E-011-deadlock-diagnosis —— 死锁检测与锁序修复

<!-- coverage: exempt Java 轨 E 段错误处理专题示例（E-011 死锁检测与锁序修复），面向错误处理教学，不接入毕业项目；排查指引将收录于 java/docs/排查手册.md 错误处理章（该章由 M11-DOC-java 卡统一落盘，先以本指向登记） -->

## 现象

两个线程以相反顺序获取 lockA/lockB：程序不退出也不报错（活着但卡死）。
与 S-14 同源：`jcmd <pid> Thread.print` 会打出 `Found one Java-level
deadlock:` 的互等闭环；本例用标准库的 ThreadMXBean 做同一件事——
在进程内程序化地检出互等闭环并定位涉事线程。

## 复现命令

```bash
TAG=latest bash scripts/run-example.sh java E-011-deadlock-diagnosis
# 或直接在 devbox-java 容器内跑断言：
docker run --rm -v "$PWD":/work -w /work/java/examples/E-011-deadlock-diagnosis \
  ghcr.io/zeek-zhao/devbox-java:latest bash assert.sh
```

## 期望输出

与 expected.txt 逐行一致：两线程反序加锁后 `findDeadlockedThreads`
检出互等闭环（deadlocked-threads: worker-1,worker-2，排序输出）；改用
统一锁序的两线程都顺利通过（fix-1/fix-2: crossed）；末行固定输出
「统一锁序消除环、tryLock 带超时兜底」的规则。

## 为什么这样处理

- `ThreadMXBean.findDeadlockedThreads()` 是 jstack/jcmd 死锁检测的
  程序化接口：检测在进程内完成、结论（涉事线程名）结构化可断言，
  不依赖抓栈文本里的地址/PID 等不稳定字段。
- 反序加锁前先 sleep 100ms：让两个线程必然交错持锁，检出确定而非偶发。
- 修复演示用统一锁序（两线程都先 A 后 B）：环不存在，死锁在结构上
  被消除；轮询循环限时 2.5s（50×50ms），检出失败的失败模式是
  「deadlock-detected: false」而不是进程 hang。

## 反例

- 「偶发卡死就重启」：死锁是结构问题，重启后概率复现；锁序统一才是根治。
- 用中断解 synchronized 死锁：synchronized 不响应中断，interrupt 无效
  （这正是改用 tryLock 带超时的理由）。
- 加锁顺序散落在各处代码里：新增持锁点引入新的顺序，环悄悄回来——
  锁获取点集中 + 全局锁序约定才可维持。
