# E-006-error-context —— 多层组件的错误上下文路径

<!-- coverage: exempt Vue 轨 E 段错误处理专题示例（E-006 多层组件错误上下文路径），面向错误处理教学，不接入毕业项目；排查指引将收录于 vue/docs/排查手册.md 错误处理章（该章由 M11-DOC-vue 卡统一落盘，先以本指向登记） -->

## 现象

深层嵌套组件里 leaf 抛错，app 级 errorHandler 只收到一句 "leaf boom"：
不知道它经过了哪条组件链。日志里同一条消息可能来自页面上五处不同的 leaf，
排障时只能挨个点开猜。

## 复现命令

```bash
TAG=latest bash scripts/run-example.sh vue E-006-error-context
# 或直接在 devbox-vue 容器内跑断言：
docker run --rm -v "$PWD":/work -w /work/vue/examples/E-006-error-context \
  ghcr.io/zeek-zhao/devbox-vue:latest bash assert.sh
```

## 期望输出

与 expected.txt 逐行一致：app 级收到的错误自带完整路径
`Root > Mid > Leaf`，深度 3。

## 为什么这样处理

- 每层 onErrorCaptured 只做两件事：把自己的名字前置进 `err.context`、
  `return undefined` 放行——上下文逐层追加（与 shell 轨 E-006 同构），
  没有一层需要知道全貌。
- 标注直接写在错误对象上（同一引用，E-005 的身份纪律）：链不破坏类型、
  不复制文本，app 级拿到的还是那个错误，只是多了 context 字段。
- app 级 errorHandler 是唯一落点：路径在最终上报处一次性可见，
  上报数据自带定位信息。

## 反例

- 每层 console.error 一句自己的报错：日志里三段消息对不齐，链拼不出来。
- 拦截后重新抛新错误再往上扔：身份断了（E-005），context 也要另想办法带。
- 只在 app 级解析组件栈打印：instance 信息不稳定，依赖实现细节。
