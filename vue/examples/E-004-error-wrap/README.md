# E-004-error-wrap —— 错误包装与 cause 链

<!-- coverage: exempt Vue 轨 E 段错误处理专题示例（E-004 错误包装与 cause 链），面向错误处理教学，不接入毕业项目；排查指引将收录于 vue/docs/排查手册.md 错误处理章（该章由 M11-DOC-vue 卡统一落盘，先以本指向登记） -->

## 现象

组件层把底层错误直接抛给上层：UI 收到一句 `Unexpected token 'b', ...`——
不知道是哪个组件、在加载什么数据时炸的。反过来全包成一句
"加载失败" 又丢了根因。两层事故，同一个根因：包装时没带上原文。

## 复现命令

```bash
TAG=latest bash scripts/run-example.sh vue E-004-error-wrap
# 或直接在 devbox-vue 容器内跑断言：
docker run --rm -v "$PWD":/work -w /work/vue/examples/E-004-error-wrap \
  ghcr.io/zeek-zhao/devbox-vue:latest bash assert.sh
```

## 期望输出

与 expected.txt 逐行一致：顶层包装带组件上下文，cause 链两层都在，
最底层保持 SyntaxError 身份，链深 3。

## 为什么这样处理

- 包装 = 新错误带自己的上下文（"哪个组件、在干什么"）+ 原错误挂 `cause`：
  `new Error(msg, { cause: err })` 是语言标准（ES2022 Error cause），
  不需要自定义包装类。
- cause 链可嵌套：Page -> Card -> SyntaxError，每层一句话、逐层可下钻；
  最底层的 `instanceof SyntaxError` 仍然成立，按类型分派（E-003）不受包装影响。
- message 不抄 cause 的文本：链是结构（cause 指针），不是字符串拼接。

## 反例

- `catch (err) { throw new Error(err.message) }`：原文还在，但身份、栈、
  附加字段全丢——重新包装应该用 cause 而不是复制文本。
- 只包上下文丢 cause：上层知道"Card 炸了"，不知道为什么炸。
- 吞掉底层错误直接 return 默认值：包装语义退化成吞错语义（E-008）。
