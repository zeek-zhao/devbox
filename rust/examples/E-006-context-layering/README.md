# E-006-context-layering

<!-- coverage: exempt E 系错误处理演练：示范用例不接入毕业项目（毕业项目形态无上下文分层落点），排查指引见 rust/docs/排查手册.md 错误处理章（M11-DOC-rust 卡落盘） -->

## 现象

底层错误（`invalid digit found in string`）裸抛到顶层时，使用者只知道
「解析失败」，不知道失败发生在哪个业务动作里。给 `Result` 逐层附加语境后，
顶层报告变成完整链条：`loading document for search index` →
`parsing document id from 'seven'` → 根因，`source` 链全程保留。

## 复现

```
TAG=latest scripts/run-example.sh rust E-006-context-layering
```

容器内断言：

```
docker run --rm -v "$PWD:/work" -w /work/rust/examples/E-006-context-layering \
  ghcr.io/zeek-zhao/devbox-rust:latest bash assert.sh
```

## 期望输出

```
top context: loading document for search index
next layer: parsing document id from `seven`
root cause: invalid digit found in string
context stack depth: 3
ok path: id 42
```

## 为什么

anyhow 的 `with_context` 本质只是一个 trait 扩展：`map_err` 把底层错误装箱、
记下「当时在做什么」。本例纯 std 手写等价实现，拆开看只有三件事——
上下文字符串、`Box<dyn Error>` 持有下一层、`Error::source` 把链条串起来。
`ContextError` 自己也实现 `Error`，所以语境可以无限叠加；根因永远在链尾。

## 反例

只在最顶层 `format!("load failed: {e}")` 包一层：链上每层的业务语境全靠
这一句话猜，中层是谁、参数是什么一概丢失。反向反例是每层都 `to_string()`
把错误拍平成字符串——`source()` 变成 `None`，根因类型信息永久丢失，
顶层无法按类别处理。

## 落点

上下文分层与 source 链规范见 `rust/docs/排查手册.md` 错误处理章
（M11-DOC-rust 卡落盘）。
