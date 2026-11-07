# E-005-box-dyn-error

<!-- coverage: exempt E 系错误处理演练：示范用例不接入毕业项目（毕业项目形态无 trait object 错误边界落点），排查指引见 rust/docs/排查手册.md 错误处理章（M11-DOC-rust 卡落盘） -->

## 现象

两个互不相干的错误源（std 的 `ParseIntError` 与自定义 `MalformedRecordError`）
都被 `?`/`Box::new` 装箱成 `Box<dyn Error>`，在一个 match 边界统一处理；
需要针对性恢复时用 `downcast_ref::<T>()` 取回具体类型分流，
未知类型走兜底分支。异构来源不再各自为政。

## 复现

```
TAG=latest scripts/run-example.sh rust E-005-box-dyn-error
```

容器内断言：

```
docker run --rm -v "$PWD:/work" -w /work/rust/examples/E-005-box-dyn-error \
  ghcr.io/zeek-zhao/devbox-rust:latest bash assert.sh
```

## 期望输出

```
record 0: id 42
record 1: malformed -> skip entry
record 2: parse failure on port -> use default id 0
heterogeneous errors handled at one boundary: 2
```

## 为什么

`Box<dyn Error>` 用动态分发换开发速度：任何实现了 `Error` 的类型自动可转
（`From<E: Error> for Box<dyn Error>`），原型期不用先设计错误枚举。
`downcast_ref` 是逃生门——类型信息还在装箱里，针对性恢复仍可行。
代价是调用方拿不到编译期的穷尽检查：新增错误源不会让 match 编译失败。

## 反例

把 `Box<dyn Error>` 当长期 API 契约：库函数永远返回
`Result<_, Box<dyn Error>>`，调用方只能 downcast 猜类型，一旦库内部换了
错误类型，静默落进 unknown 分支。公开边界的正确形态是具体错误 enum
（穷尽可查），`Box<dyn Error>` 留给应用层与原型。

## 落点

Box dyn 与具体 enum 的边界取舍见 `rust/docs/排查手册.md` 错误处理章
（M11-DOC-rust 卡落盘）。
