# E-001-error-taxonomy —— Vue 错误来源分类体系

<!-- coverage: exempt Vue 轨 E 段错误处理专题示例（E-001 错误来源分类体系），面向错误处理教学，不接入毕业项目；排查指引将收录于 vue/docs/排查手册.md 错误处理章（该章由 M11-DOC-vue 卡统一落盘，先以本指向登记） -->

## 现象

「Vue 报错了」被当成一种错误处理：控制台一片红就开始猜。实际上错误来自不同源头——
setup 抛错、render 函数抛错、异步 setup 的 Promise 拒绝——三类错误的定位方法与
处理策略完全不同，混着处理就会把可重试的当成调用方 bug（或反之）。

## 复现命令

```bash
TAG=latest bash scripts/run-example.sh vue E-001-error-taxonomy
# 或直接在 devbox-vue 容器内跑断言：
docker run --rm -v "$PWD":/work -w /work/vue/examples/E-001-error-taxonomy \
  ghcr.io/zeek-zhao/devbox-vue:latest bash assert.sh
```

## 期望输出

与 expected.txt 逐行一致：三类来源各自给出 `info=setup function` /
`info=render function` 位置类别，汇总 `sync=2 async=1 captured=3`。

## 为什么这样处理

- 统一汇入口 `app.config.errorHandler`：它同时接住同步渲染错误与异步 setup
  拒绝，返回 false 停止默认告警，让「分类」成为唯一出口。
- `info` 参数是官方给的位置类别（setup function / render function）：
  分类挂在官方字段上而不是解析消息文本，Vue 升级不破坏分派逻辑。
- 异步 setup 的错误在 SSR 下也会汇入 errorHandler——「异步错误会漏掉」
  只对与组件生命周期无关的游离 Promise 成立（见 E-009 的对照）。

## 反例

- 按消息文本字符串匹配分派：`if (err.message.includes('setup'))`——文案一改全挂。
- 只处理 render 错误：setup / 异步 setup 的失败静默走默认告警，分类体系缺口。
- 把所有错误一视同仁地重试：render 函数 bug 重试多少次都是同一个 bug。
