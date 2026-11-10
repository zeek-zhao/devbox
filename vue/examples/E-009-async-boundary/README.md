# E-009-async-boundary —— 异步错误与边界覆盖范围

<!-- coverage: exempt Vue 轨 E 段错误处理专题示例（E-009 异步错误边界），面向错误处理教学，不接入毕业项目；排查指引将收录于 vue/docs/排查手册.md 错误处理章（该章由 M11-DOC-vue 卡统一落盘，先以本指向登记） -->

## 现象

"加了 onErrorCaptured 就稳了"是错觉：组件生命周期内的错误（含异步 setup
的 Promise 拒绝）确实汇入 errorHandler，但 composable 里游离的
Promise（自己发起的后台刷新、无主的 setTimeout 回调）根本不进任何
Vue 边界——漏 catch 就是 unhandledRejection，用户端一片静默失败。

## 复现命令

```bash
TAG=latest bash scripts/run-example.sh vue E-009-async-boundary
# 或直接在 devbox-vue 容器内跑断言：
docker run --rm -v "$PWD":/work -w /work/vue/examples/E-009-async-boundary \
  ghcr.io/zeek-zhao/devbox-vue:latest bash assert.sh
```

## 期望输出

与 expected.txt 逐行一致：同步渲染错误 info=render function；
异步 setup 错误 info=setup function（SSR 下也进 errorHandler）；
游离 Promise 不进 errorHandler，只有显式 catch 接住它。

## 为什么这样处理

- 边界的能力范围以实测为准：Vue 的 errorHandler 覆盖组件树内
  同步+异步 setup 错误；判定"谁在边界内"看错误发起方是否挂在
  组件生命周期上，而不是看错误是不是异步。
- 游离 Promise 必须在发起处显式 catch：边界框架替不了"没人认领"的失败；
  catch 后按统一错误体系分派（E-003）。
- 判据写成可断言的计数（app-saw=false caught-by-catch=true）：
  边界覆盖范围不是文档声明，是跑出来的事实。

## 反例

- 以为 onErrorCaptured 能接住一切异步错误：游离 Promise 直接漏网。
- 游离 Promise 只 .then 不 .catch：unhandledRejection，
  生产端用户无感失败。
- 把"异步错误接不住"归咎于边界失效而加层层 try/catch：
  正解是给每个游离 Promise 认领 catch。
