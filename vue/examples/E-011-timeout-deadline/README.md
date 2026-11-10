# E-011-timeout-deadline —— 异步加载的截止时间

<!-- coverage: exempt Vue 轨 E 段错误处理专题示例（E-011 异步加载截止时间），面向错误处理教学，不接入毕业项目；排查指引将收录于 vue/docs/排查手册.md 错误处理章（该章由 M11-DOC-vue 卡统一落盘，先以本指向登记） -->

## 现象

页面请求一个不响应的接口：loading 态永远挂着，用户只能刷新；
或者上层 finally 兜底了，但没有"多久算太久"的判定——
截止时间缺失让网络故障的恢复时间由对端决定。

## 复现命令

```bash
TAG=latest bash scripts/run-example.sh vue E-011-timeout-deadline
# 或直接在 devbox-vue 容器内跑断言：
docker run --rm -v "$PWD":/work -w /work/vue/examples/E-011-timeout-deadline \
  ghcr.io/zeek-zhao/devbox-vue:latest bash assert.sh
```

## 期望输出

与 expected.txt 逐行一致：快加载按时返回 data；挂起加载在 50ms
截止处被判定为 E_TIMEOUT；截止换算 1 次。

## 为什么这样处理

- `Promise.race([load, deadline])` 是语言层的截止时间实现：
  挂起的 Promise 变成有限时间的失败，UI 的三态（加载/成功/失败）
  在有界时间内总能落到一个。
- 截止结果用显式标记（timedOut: true）而不是 reject 一个裸 Error：
  上层拿到的是"可分派的错误类别"（接 E-003 的 retry/report），
  而不是要解析的异常文本。
- `finally clearTimeout`：输赢都要拆定时器，否则截止定时器本身
  就是泄漏（与 E-007 的清理保证同一纪律）。

## 反例

- 裸 await 一个可能永不 settle 的请求：loading 态挂在页面上。
- 截止后不 clearTimeout：每次超时泄漏一个定时器。
- 用"加载了 5 分钟还没回来"当超时：截止时间要以交互可容忍度为准。
