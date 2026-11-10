# E-011-timeout-deadline —— 超时与截止

<!-- coverage: exempt Python 轨 E 段错误处理专题示例（E-011 超时与截止），面向错误处理教学，不接入毕业项目；排查指引将收录于 python/docs/排查手册.md 错误处理章（该章由 M11-DOC-python 卡统一落盘，先以本指向登记） -->

## 现象

等待没有上限的调用在下游变慢时把整条链路拖死：调用方无限阻塞、线程池
被占满、日志里连一条「卡在哪」的记录都没有。排障时区分「慢」与「死」
的第一步就是问：这个等待有没有截止时间？

## 复现命令

```bash
TAG=latest bash scripts/run-example.sh python E-011-timeout-deadline
# 或直接在 devbox-python 容器内跑断言：
docker run --rm -v "$PWD":/work -w /work/python/examples/E-011-timeout-deadline \
  ghcr.io/zeek-zhao/devbox-python:latest bash assert.sh
```

## 期望输出

与 expected.txt 逐行一致：0.2s 的慢任务在 0.05s 截止处抛
`TimeoutError`，归类为 TIMEOUT 并取消任务善后；随后 0.05s 的快速任务
正常返回，证明线程池没有被死等拖垮。

## 为什么这样处理

- `future.result(timeout=...)` 把「等多久」写进调用契约：等待有上限，
  最坏情况的阻塞时间可计算。
- 超时是独立的错误类别（TIMEOUT），处理动作是 cancel-and-report：
  既不是 TRANSIENT（盲目重试会堆积等待），也不是 UNKNOWN（不吞不猜）。
- 命中超时后 `future.cancel()` 善后：任务若未启动即被回收，已启动的
  由线程池自然回收，不占用调度名额。
- `with ThreadPoolExecutor` 收尾时 join 已提交任务：演示中慢任务 0.2s
  后自然结束，进程整体退出干净。

## 反例

- `future.result()` 不带 timeout：下游 hang 住时调用方陪葬，且无日志。
- 把 TimeoutError 归进「重试」：超时常常意味着下游已过载，重试是雪崩放大。
- 命中超时后不取消不记录：任务滞留、下次排障找不到「谁还在等」。
