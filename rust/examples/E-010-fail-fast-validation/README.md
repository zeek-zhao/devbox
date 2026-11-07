# E-010-fail-fast-validation

<!-- coverage: exempt E 系错误处理演练：示范用例不接入毕业项目（毕业项目形态无批量校验落点），排查指引见 rust/docs/排查手册.md 错误处理章（M11-DOC-rust 卡落盘） -->

## 现象

批次里第 2 行 id 非法。快速失败形态：`validate` 先整体校验，
返回 `invalid id at line 2: 'bad'`，`apply` 根本没被调用——
副作用计数为零，拒绝信息精确到行号与字段。对照形态（边解析边执行）
则第 1 行已经写入，第 2 行才失败，留下半批脏数据。

## 复现

```
TAG=latest scripts/run-example.sh rust E-010-fail-fast-validation
```

容器内断言：

```
docker run --rm -v "$PWD:/work" -w /work/rust/examples/E-010-fail-fast-validation \
  ghcr.io/zeek-zhao/devbox-rust:latest bash assert.sh
```

## 期望输出

```
valid batch: 2 requests applied, ids [1, 2] total 300
invalid batch rejected before any side effect: invalid id at line 2: `bad`
empty batch rejected: empty batch
bad amount rejected: invalid amount at line 2
```

## 为什么

副作用（写库、调用下游、发消息）一旦发生就只能补偿，不能撤销。
「先校验后执行」把失败压缩到副作用之前的纯计算阶段，此时失败代价为零。
实现要点：`validate` 与 `apply` 分成两个函数，`apply` 的入参类型是
校验产物 `Vec<Request>`（newtype 可再进一步），让「没校验就不能执行」
成为类型约束而不是口头约定。

## 反例

解析与写库混在同一个循环里：第 N 行失败时前 N-1 行已经落库，
需要人工对账 + 补偿事务；错误信息里也只有「第 N 行坏了」，
没有整体批次号，重跑时不知道哪些行要排除。

## 落点

fail-fast 边界与副作用隔离见 `rust/docs/排查手册.md` 错误处理章
（M11-DOC-rust 卡落盘）。
