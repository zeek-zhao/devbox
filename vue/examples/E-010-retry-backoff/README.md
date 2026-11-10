# E-010-retry-backoff —— 数据加载的重试与退避

<!-- coverage: exempt Vue 轨 E 段错误处理专题示例（E-010 数据加载重试与退避），面向错误处理教学，不接入毕业项目；排查指引将收录于 vue/docs/排查手册.md 错误处理章（该章由 M11-DOC-vue 卡统一落盘，先以本指向登记） -->

## 现象

前端加载失败处理两个极端：要么一失败就放弃（用户看到报错页，
其实网络抖一下就好了）；要么无脑循环重试——对 4xx 参数错、配额超限
这类永远修不好的失败反复打请求，把限流放大成打挂网关。

## 复现命令

```bash
TAG=latest bash scripts/run-example.sh vue E-010-retry-backoff
# 或直接在 devbox-vue 容器内跑断言：
docker run --rm -v "$PWD":/work -w /work/vue/examples/E-010-retry-backoff \
  ghcr.io/zeek-zhao/devbox-vue:latest bash assert.sh
```

## 期望输出

与 expected.txt 逐行一致：第 3 次成功（累计退避 30ms）、不可重试错误
首次即停（waited=0ms）、持续瞬时故障在 4 次预算耗尽后报 give-up。

## 为什么这样处理

- 重试决策挂在 `err.code === 'E_TRANSIENT'` 上：值得再试的只有瞬时故障；
  E_PERM 这类永久失败一次都不要重试（分派身份来自 E-002/E-003）。
- 有限次数 + 指数退避（10ms 翻倍）：预算写死在 `retry(max, baseMs, fn)`
  签名可见处，每轮间隔翻倍给系统恢复窗口。
- 每种结局（success/non-retryable/give-up）都是显式返回值， waited 计入
  返回值——重试花了多少时间与最终结果一样是一等公民，方便观测（E-013）。

## 反例

- `while (true) { try { await load() } catch {} }`：无预算无退避，
  抖动被放大成事故。
- 对 E_PERM/E_REQUIRED 重试：除了刷日志和打挂下游什么也修不好。
- 重试耗尽后 resolve 默认值：失败被吞成假成功，缓存里躺着错误数据。
