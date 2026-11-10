# E-010-retry-backoff —— 重试与退避

<!-- coverage: exempt Shell 轨 E 段错误处理专题示例（E-010 重试与退避），面向错误处理教学，不接入毕业项目；排查指引将收录于 shell/docs/排查手册.md 错误处理章（该章由 M11-DOC-shell 卡统一落盘，先以本指向登记） -->

## 现象

两种重试事故：一是「见错就重试」——对配额超限、参数错误这类永远修不好的
失败反复重试，把限流放大成打挂下游；二是无预算无退避——同一时刻的故障
被按固定频率原样重放，抖动被放大成风暴。

## 复现命令

```bash
TAG=latest bash scripts/run-example.sh shell E-010-retry-backoff
# 或直接在 devbox-shell 容器内跑断言：
docker run --rm -v "$PWD":/work -w /work/shell/examples/E-010-retry-backoff \
  ghcr.io/zeek-zhao/devbox-shell:latest bash assert.sh
```

## 期望输出

与 expected.txt 逐行一致：第 3 次成功（累计退避 30ms）、不可重试错误
首次即停（waited=0ms）、持续故障在 4 次预算耗尽后报 give-up。

## 为什么这样处理

- 重试决策挂在错误类别上：只有 rc=7（瞬时故障）进退避循环，rc=2
  （配额/权限类）首次即停——「值得再试吗」由失败类别决定，不是由循环决定。
- 有限次数 + 指数退避（10ms 翻倍）：预算（4 次）写死在 `retry` 的参数上，
  每轮间隔翻倍给系统恢复时间；预算耗尽必须带着最后一次错误上抛
  （return 7），绝不把「重试失败」吞成「成功」。
- waited 逐轮累计并在输出里可见：重试花了多少时间是排障的一等公民，
  不是藏在循环里的副作用。

## 反例

- 无预算、无退避的死循环重试：把抖动放大成事故。
- 对不可重试错误（配额、参数、认证）重试：除了放大故障什么也修不好。
- 重试耗尽后 return 0 或换一个新错误：排查时丢失真正的最后一次根因。
