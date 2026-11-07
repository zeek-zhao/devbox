# E-008-retry-backoff

<!-- coverage: exempt E 系错误处理演练：示范用例不接入毕业项目（毕业项目形态无重试策略落点），排查指引见 rust/docs/排查手册.md 错误处理章（M11-DOC-rust 卡落盘） -->

## 现象

不分类的重试两种下场：对瞬时故障（超时、限流）不重试，一次抖动直接报错；
对永久故障（schema 不匹配）盲目重试，把一次失败放大成持续压垮对方的流量。
本例演示正确形态：错误先分成 Transient / Permanent 两类，瞬时错误按指数
退避（1ms、2ms、4ms……）重试且设 5 次上限，永久错误立即上抛。

## 复现

```
TAG=latest scripts/run-example.sh rust E-008-retry-backoff
```

容器内断言：

```
docker run --rm -v "$PWD:/work" -w /work/rust/examples/E-008-retry-backoff \
  ghcr.io/zeek-zhao/devbox-rust:latest bash assert.sh
```

## 期望输出

```
retry: recovered after transient errors, value payload
broken: no retry on permanent error (schema mismatch)
policy: retry transient with exponential backoff, fail fast on permanent
```

## 为什么

重试只在「错误与时间相关」时有意义。指数退避让重试在时间上错开，
避免重试风暴；上限保证最坏情况有界（快速失败）。`with_retry` 接受
`FnMut(u32) -> Result<_, FetchError>`，重试策略与业务操作解耦——
策略写一次，所有调用点复用。

## 反例

`loop { if let Ok(v) = fetch() { break v } }` 无退避无上限：对方故障时
变成忙等打满 CPU 并持续加压。另一个反例是对「参数非法」这类永久错误
照常重试——结果永远一样，白白烧掉重试预算还把故障窗口拖长。

## 落点

重试分类与退避参数口径见 `rust/docs/排查手册.md` 错误处理章
（M11-DOC-rust 卡落盘）。
