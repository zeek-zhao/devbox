# E-009-iterator-error-flow

<!-- coverage: exempt E 系错误处理演练：示范用例不接入毕业项目（毕业项目形态无迭代器错误流落点），排查指引见 rust/docs/排查手册.md 错误处理章（M11-DOC-rust 卡落盘） -->

## 现象

`Result` 混进迭代器管道后有四种收敛方式，语义各不相同：
`collect()` 任一 `Err` 则整体 `Err`（首错短路）；`try_fold()` 首错即停
且保留累积值；`filter_map(Result::ok)` 静默丢弃失败只留成功项；
`fold` 计数完成成功/失败分区。同一个输入 `["1", " 2 ", "x", "4"]`
四种写法给出四种结果。

## 复现

```
TAG=latest scripts/run-example.sh rust E-009-iterator-error-flow
```

容器内断言：

```
docker run --rm -v "$PWD:/work" -w /work/rust/examples/E-009-iterator-error-flow \
  ghcr.io/zeek-zhao/devbox-rust:latest bash assert.sh
```

## 期望输出

```
collect all: true
try_fold: short-circuited
ok-only: [2, 4, 8]
partition: 3 ok, 1 err
```

## 为什么

`FromIterator for Result<V, E>` 让 `collect` 自动「翻转容器」：所有 `Ok`
收敛成 `Ok(Vec)`，遇到第一个 `Err` 整体失败——这正是 `?` 语义在迭代
维度的对应物。`try_fold` 是显式版短路与折叠一体；`filter_map(Result::ok)`
把错误当「可丢弃噪声」，丢之前要想清楚后果。选型口诀：要么全对用
`collect`，要统计用 `partition`/`fold`，明确可丢弃才用 `ok()`。

## 反例

管道里随手 `.ok()` 消掉 `Err` 只是为了让类型对上：一半输入悄悄消失，
下游统计数字对不上时无从排查。另一个反例是用 `unwrap()` 收敛——
迭代到第 3 个脏数据直接 panic，前面算了一半的累积值全部丢失。

## 落点

迭代器错误流选型见 `rust/docs/排查手册.md` 错误处理章（M11-DOC-rust 卡落盘）。
