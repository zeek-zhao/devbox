# E-005-uncaught-handler —— 线程未捕获异常的两条出口

<!-- coverage: exempt Java 轨 E 段错误处理专题示例（E-005 线程未捕获异常的两条出口），面向错误处理教学，不接入毕业项目；排查指引将收录于 java/docs/排查手册.md 错误处理章（该章由 M11-DOC-java 卡统一落盘，先以本指向登记） -->

## 现象

裸 `Thread` 里抛出的异常默认只往 stderr 打一行就结束（进程不知道任务
失败了）；线程池里更隐蔽——异常被 Future 静默持有，不 `get()` 就永远
无人知晓，「任务跑了但没结果」成为排障最痛的静默失败。

## 复现命令

```bash
TAG=latest bash scripts/run-example.sh java E-005-uncaught-handler
# 或直接在 devbox-java 容器内跑断言：
docker run --rm -v "$PWD":/work -w /work/java/examples/E-005-uncaught-handler \
  ghcr.io/zeek-zhao/devbox-java:latest bash assert.sh
```

## 期望输出

与 expected.txt 逐行一致：裸线程的异常被 `UncaughtExceptionHandler`
捕获并记录线程名与异常类型；线程池任务不 get 时异常静默持有，
get 时以 `ExecutionException` 解包出 cause；末行固定输出两条出口规则。

## 为什么这样处理

- 两条出口必须二选一覆盖：裸线程靠 handler（或 `ThreadFactory` 统一装），
  池任务靠「每个 Future 都被 get/回调观测」。只配一条，另一条路径
  的失败必然静默。
- `ExecutionException.getCause()` 是池任务的异常解包点：业务异常
  藏在 cause 里，只看 ExecutionException 自身的消息等于没看。
- handler 记录线程名：多线程事故的第一定位信息就是「哪条线程炸的」。

## 反例

- 裸线程不设 handler：异常只有默认 stderr 一行，生产日志采集里
  极易被淹没，任务失败无任何结构化痕迹。
- `pool.submit(...)` 后不 get 不回调：异常永远躺在 Future 里，
  与「任务成功」从外部完全无法区分。
- `catch (ExecutionException e) { e.printStackTrace(); }`：不解包
  cause、不打线程上下文，等于把静默失败换了个格式继续静默。
