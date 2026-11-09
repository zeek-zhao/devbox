# E-015-antipattern-compare —— 前端错误处理反模式对照

<!-- coverage: exempt Vue 轨 E 段错误处理专题示例（E-015 前端反模式对照），面向错误处理教学，不接入毕业项目；排查指引将收录于 vue/docs/排查手册.md 错误处理章（该章由 M11-DOC-vue 卡统一落盘，先以本指向登记） -->

## 现象

前端错误处理三大假绿：解构 reactive 后界面"不动了"（响应性丢失，
数据在变视图不变）；子组件直接改 props（单向数据流被破坏，
父组件状态被无声改写）；Promise 失败被空 catch 吞掉
（`catch(() => {})`，失败连记录都没有）。它们的共性是：
**没有报错、没有崩溃，只有错误的行为**。

## 复现命令

```bash
TAG=latest bash scripts/run-example.sh vue E-015-antipattern-compare
# 或直接在 devbox-vue 容器内跑断言：
docker run --rm -v "$PWD":/work -w /work/vue/examples/E-015-antipattern-compare \
  ghcr.io/zeek-zhao/devbox-vue:latest bash assert.sh
```

## 期望输出

与 expected.txt 逐行一致：三组对照，bad= 一侧是坏写法的真实现象
（界面停在 1、父组件被改成 99、失败零记录），good= 一侧是正确写法。

## 为什么这样处理

- 对照实验而不是论述：三组 bad/good 同屏并排，全部真跑取证，
  不是编造的典型现象（素材纪律）。
- 对照一指向响应性纪律：需要"拆出来的响应式"用 `toRefs`/`storeToRefs`，
  普通解构拿到的是快照值（watchEffect 读普通值不再追踪）。
- 对照二指向单向数据流：子组件要改就改本地副本 + emit 交还父组件，
  直接改 props 让父组件状态被无声污染，排障时根因在儿子、症状在老子。
- 对照三指向吞错纪律：空 catch 是零记录的失败（E-008），
  接住后至少计数/上报，接 E-013 的结构化上报。

## 反例

- "先解构再用，反正值都一样"：值一样的那一刻就是响应性断掉的那一刻。
- "改一下 props 最方便"：方便这一次，排障多花一小时。
- "这个请求不会失败"：catch(() => {}) 里的自信，就是生产事故的来源。
