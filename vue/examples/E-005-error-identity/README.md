# E-005-error-identity —— 错误身份：同一错误逐层不变

<!-- coverage: exempt Vue 轨 E 段错误处理专题示例（E-005 错误身份），面向错误处理教学，不接入毕业项目；排查指引将收录于 vue/docs/排查手册.md 错误处理章（该章由 M11-DOC-vue 卡统一落盘，先以本指向登记） -->

## 现象

composable 抛出的 ServiceError，穿过组件层后上层拿到的可能是一个"长得像"
的新 Error：`new Error(err.message)` 一行就把引用换掉、instanceof 打断、
code 字段抹掉。调用方按类型分派的处理（E-003）全部落空，
错误上报里也出现了两条"不同"的失败。

## 复现命令

```bash
TAG=latest bash scripts/run-example.sh vue E-005-error-identity
# 或直接在 devbox-vue 容器内跑断言：
docker run --rm -v "$PWD":/work -w /work/vue/examples/E-005-error-identity \
  ghcr.io/zeek-zhao/devbox-vue:latest bash assert.sh
```

## 期望输出

与 expected.txt 逐行一致：链上身份保持（same=true、code 存活）；
重包装后身份断裂（same=false、instanceof=false）。

## 为什么这样处理

- 中间层（composable）的职责是透传：不 catch、不重包、不改写——
  同一引用一路到底，`code` 等自定义字段天然存活。
- 需要加上下文时用 cause 包装（E-004）而不是文本复制：
  cause 链保留了原对象的引用与类型。
- 用 `===` 断言身份：身份不是"消息一样就算"，是同一个对象——
  这也是 onErrorCaptured 链上标注（E-006）不破坏身份的前提。

## 反例

- `throw new Error(err.message)`：最常见的断身份写法，文案一样、
  类型全丢，分派表从此哑火。
- 中间层 catch 后 `throw 'string'`：错误退化成字符串，什么身份都没了。
- 为了日志把错误 JSON.parse(JSON.stringify(err)) 再抛：栈与原型全灭。
