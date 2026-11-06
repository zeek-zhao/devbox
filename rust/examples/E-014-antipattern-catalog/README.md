# E-014-antipattern-catalog

<!-- coverage: exempt E 系错误处理演练：示范用例不接入毕业项目（毕业项目形态无反模式对照落点），排查指引见 rust/docs/排查手册.md 错误处理章（M11-DOC-rust 卡落盘） -->

## 现象

三组高频反模式，每组「反模式 + 修正版」成对输出：
① `.ok()` 吞错——失败原因被拍成 `None`，调用方只见缺失不见病因；
② `Err(String)` stringly-typed——调用方只能对消息文本做 `starts_with`
约定，无法按类别分支；③ 错误后继续跑——坏行按 0 混入，`total 5`
静默失真（应为整体拒绝）。

## 复现

```
TAG=latest scripts/run-example.sh rust E-014-antipattern-catalog
```

容器内断言：

```
docker run --rm -v "$PWD:/work" -w /work/rust/examples/E-014-antipattern-catalog \
  ghcr.io/zeek-zhao/devbox-rust:latest bash assert.sh
```

## 期望输出

```
anti-1 swallowed: true (error cause destroyed by .ok())
anti-1 fixed: Err(ParseIntError { kind: InvalidDigit })
anti-2 stringly-typed: caller matches on message text only (true)
anti-2 fixed: variant ConfigError::Port matches by type (true)
anti-3 continue-on-error: total 5 (bad rows silently vanish)
anti-3 fixed: aborted (invalid digit found in string)
```

## 为什么

三个反模式的共同点是「把失败伪装成正常」：吞错让失败消失、
字符串错误让失败无法分类、带病继续让失败污染结果。修正版分别是
`match` 保留病因、enum 变体保留类型、`collect` 整体拒绝保留正确性。
code review 时三条都能机械识别：搜 `.ok()` / `let _ =`、搜
`Result<_, String>`、搜循环内 `unwrap_or` 后继续聚合。

## 反例

把本例的反模式写法当「容错性强」推广：吞错被当成优雅降级（区别在
E-013 的来源标签——降级记录路径，吞错销毁证据）、字符串错误被当成
「灵活」（换来的每个调用点文本约定都会在改文案时静默破裂）。

## 落点

反模式清单与识别方法见 `rust/docs/排查手册.md` 错误处理章
（M11-DOC-rust 卡落盘）。
