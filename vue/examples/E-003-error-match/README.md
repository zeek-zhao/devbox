# E-003-error-match —— 按错误身份匹配处理策略

<!-- coverage: exempt Vue 轨 E 段错误处理专题示例（E-003 错误匹配），面向错误处理教学，不接入毕业项目；排查指引将收录于 vue/docs/排查手册.md 错误处理章（该章由 M11-DOC-vue 卡统一落盘，先以本指向登记） -->

## 现象

catch 里一坨 if/else 解析 message 文本：`if (err.message.includes('network'))`。
文案一改全部失灵；未知错误落进错误的分支——网络抖动被当成表单输入错误
"修复"，真正的输入错误被拿去重试。

## 复现命令

```bash
TAG=latest bash scripts/run-example.sh vue E-003-error-match
# 或直接在 devbox-vue 容器内跑断言：
docker run --rm -v "$PWD":/work -w /work/vue/examples/E-003-error-match \
  ghcr.io/zeek-zhao/devbox-vue:latest bash assert.sh
```

## 期望输出

与 expected.txt 逐行一致：四种错误各自落到唯一策略
（retry / fix-input / fix-input / report）。

## 为什么这样处理

- 匹配对象是「身份」：`instanceof AppError` 先分类型，`error.code` 再分分支——
  两级匹配都是结构化字段，与文案无关（身份由 E-002 的创建侧保证）。
- 未知错误（不是 AppError、code 不认识）走保守动作 report：
  分派表允许「不认识」，不允许「猜」。
- 同一 code 只落一个分支：策略函数是纯函数，配 assert 锁死
  ——分派表漂移在测试期就红。

## 反例

- 解析 message 匹配：文案是给人看的，拿它当协议必然漂移。
- 匹配表只写认识的情况不写兜底：新错误类型落进 undefined 行为。
- 对 fix-input 类错误重试：输入不会因为重试变对（E-001 的类别纪律）。
