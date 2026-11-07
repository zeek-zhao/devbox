# E-004-from-vs-map-err

<!-- coverage: exempt E 系错误处理演练：示范用例不接入毕业项目（毕业项目形态无 From 转换对照落点），排查指引见 rust/docs/排查手册.md 错误处理章（M11-DOC-rust 卡落盘） -->

## 现象

同一处底层错误（`ParseIntError`）转成领域错误（`ConfigError`）有两条等价路径：
实现 `From<ParseIntError> for ConfigError` 后，`?` 自动完成转换（写法 A）；
或者每个调用点 `map_err(ConfigError::Port)` 手动转换（写法 B）。
两条路径产出的错误值逐字段相等，`?` 展开后就是 `Err(From::from(e))`。

## 复现

```
TAG=latest scripts/run-example.sh rust E-004-from-vs-map-err
```

容器内断言：

```
docker run --rm -v "$PWD:/work" -w /work/rust/examples/E-004-from-vs-map-err \
  ghcr.io/zeek-zhao/devbox-rust:latest bash assert.sh
```

## 期望输出

```
ok path equal: true
err path equal: true
question-mark is From::from: true
display keeps root cause: config port: invalid digit found in string
prefer From when one target type dominates: yes
```

## 为什么

`?` 的语义是 `match expr { Ok(v) => v, Err(e) => return Err(From::from(e)) }`，
转换规则集中在 `From` 实现里，调用链免样板；`map_err` 是显式版本，适合
目标类型不固定、或临时聚合进 `String` 的场景。选型经验：一种底层错误固定
流向一种目标类型时实现 `From`；多处流向不同目标时用 `map_err` 就地标注语境。

## 反例

在几十个调用点重复 `map_err(|e| format!("port: {e}"))` 把错误揉成 `String`：
领域类型信息丢失，调用方无法按类别分支，`Error::source` 也无从实现。
另一个反例是滥用 `From` 做「远程转换」——为两个语义无关的类型实现 `From`，
让 `?` 在调用链里悄悄改变错误含义，排查时来源链断裂。

## 落点

From/map_err 选型规则见 `rust/docs/排查手册.md` 错误处理章（M11-DOC-rust 卡落盘）。
