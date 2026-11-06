# E-013-graceful-degradation

<!-- coverage: exempt E 系错误处理演练：示范用例不接入毕业项目（毕业项目形态无降级链落点），排查指引见 rust/docs/排查手册.md 错误处理章（M11-DOC-rust 卡落盘） -->

## 现象

三级数据源逐级兜底：主源直接命中 `via primary`；主源拒收带空白的输入时
备用源接管 `via replica`；两级都失败落默认值 `via default`。
每条结果携带来源标签，降级路径一眼可查。末尾附 std 惯用法
`unwrap_or_else`（惰性：仅在失败时构造默认值）。

## 复现

```
TAG=latest scripts/run-example.sh rust E-013-graceful-degradation
```

容器内断言：

```
docker run --rm -v "$PWD:/work" -w /work/rust/examples/E-013-graceful-degradation \
  ghcr.io/zeek-zhao/devbox-rust:latest bash assert.sh
```

## 期望输出

```
query `42` -> 42 via primary
query ` 7 ` -> 7 via replica
query `gone` -> 0 via default
unwrap_or_else default: 0
```

## 为什么

降级链条的关键不是「有兜底」，而是「兜底可追溯」：返回值带上
`via primary/replica/default` 标签，下游和排障者能立刻知道这份数据
可信到什么程度。`unwrap_or_else(|_| 0)` 优于 `unwrap_or(0)` 的地方是
惰性求值——默认值构造有成本（克隆、分配）时只在真正失败时才付。

## 反例

静默兜底：`unwrap_or(0)` 直接焊死在调用点，主源挂了三个小时，业务
「看起来正常」，只有数据质量团队事后发现一堆 0。降级不报不记，
等于把故障伪装成合法数据——比直接失败更难排查。

## 落点

降级链与来源标签规范见 `rust/docs/排查手册.md` 错误处理章
（M11-DOC-rust 卡落盘）。
