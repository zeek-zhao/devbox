# E-010-retry-backoff —— 重试与退避

<!-- coverage: exempt C 轨 E 段错误处理专题示例（E-010 重试与退避），面向错误处理教学，不接入毕业项目；排查指引将收录于 c/docs/排查手册.md 错误处理章（该章由 M11-DOC-c 卡统一落盘，先以本指向登记） -->

## 现象

对任何失败一律立刻重试：参数错误被重试到上限（浪费且放大故障），
真超时却又因为「立即重试」打在同一个拥堵窗口上，三次全失败。
或者反过来：该重试的暂态错误直接上抛，一次抖动就变成整次任务失败。

## 复现命令

```bash
TAG=latest bash scripts/run-example.sh c E-010-retry-backoff
docker run --rm -v "$PWD":/work -w /work/c/examples/E-010-retry-backoff \
  ghcr.io/zeek-zhao/devbox-cpp:latest bash assert.sh
```

## 期望输出

与 expected.txt 逐行一致：flaky 场景两次退避（100/200ms）后第三次成功；
strict 场景第一个 attempt 即 give_up=1（不可重试类不重试）。

## 为什么这样处理

- 先分类再重试：只有 TIMEOUT/UNAVAILABLE 这类「下一刻可能就好」的错误进重试环；
  BAD_INPUT 立即放弃，重试只是把失败推迟。
- 固定退避表（100/200/400ms）并设 attempts 上限：延迟有界、行为可复现；
  每次重试打印 attempt 与退避计划，输出即执行轨迹。
- 教学实现用「按调用次数计数」的假后端代替真网络：结果确定，断言稳定。

## 反例

- 无上限 `while (true) retry();`：后端永久不可用时调用方把自己也拖死。
- 对参数错误重试：输入不变，结果不变，白烧 CPU 还刷日志。
- 随机抖动退避不落日志：每次运行轨迹都不同，教学与排障都无法复现。
