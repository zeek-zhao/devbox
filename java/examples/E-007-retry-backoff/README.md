# E-007-retry-backoff —— 重试与指数退避

<!-- coverage: exempt Java 轨 E 段错误处理专题示例（E-007 重试与指数退避），面向错误处理教学，不接入毕业项目；排查指引将收录于 java/docs/排查手册.md 错误处理章（该章由 M11-DOC-java 卡统一落盘，先以本指向登记） -->

## 现象

临时故障（连接被拒、超时）一失败就整体报错，服务可用性被单次抖动放大；
或者不区分错误类型全部重试：把参数错误重试三次后原样失败，还把下游打得
更满——无退避的紧逼重试是雪崩放大器。

## 复现命令

```bash
TAG=latest bash scripts/run-example.sh java E-007-retry-backoff
# 或直接在 devbox-java 容器内跑断言：
docker run --rm -v "$PWD":/work -w /work/java/examples/E-007-retry-backoff \
  ghcr.io/zeek-zhao/devbox-java:latest bash assert.sh
```

## 期望输出

与 expected.txt 逐行一致：前两次 TRANSIENT 失败按 10ms、20ms 指数退避
后第三次成功；`ValidationException` 一进重试器就按「不重试」立即拒绝，
末行固定输出重试规则。

## 为什么这样处理

- 重试器只接 `TransientException`：VALIDATION 是调用方 bug，重试修不好，
  只会推迟失败并放大下游压力。
- 退避按 `base * 2^(n-1)` 指数增长且次数封顶（retries=3）：给环境自愈
  时间，同时保证最坏情况的等待上限可计算。
- 每次失败都留一行结构化记录（attempt、类别、原因）：排障时能分清
  「重试自愈了」还是「耗尽次数后失败」。
- 退避等待用真实 `Thread.sleep`（10ms/20ms 级别）：教学示例体感真实；
  生产实现再加 jitter 防止重试风暴对齐。

## 反例

- `catch (Exception e) { retry(); }`：把不可重试错误也重试，掩盖真正的 bug。
- 固定间隔紧逼重试（0 间隔 100 次）：对已过载的下游是二次伤害。
- 重试循环里不区分「自愈成功」与「最终失败」：排障时只剩一条失败日志，
  丢失全部重试现场。
