# E-007-error-aggregation

<!-- coverage: exempt E 系错误处理演练：示范用例不接入毕业项目（毕业项目形态无批量聚合落点），排查指引见 rust/docs/排查手册.md 错误处理章（M11-DOC-rust 卡落盘） -->

## 现象

批量导入 5 行数据，2 行非法。`collect::<Result<Vec,_>>()` 在第 1 个错误处
短路，只报「row 1 坏了」——第 3 行还有没有问题使用者不得不知，修一行重跑
一次。聚合模式把成功/失败一分为二，一次报出全部失败（行号 + 各自原因），
使用者修完所有问题一次重跑。

## 复现

```
TAG=latest scripts/run-example.sh rust E-007-error-aggregation
```

容器内断言：

```
docker run --rm -v "$PWD:/work" -w /work/rust/examples/E-007-error-aggregation \
  ghcr.io/zeek-zhao/devbox-rust:latest bash assert.sh
```

## 期望输出

```
aggregated: 3 ok, 2 failed
ok row value: 12
ok row value: 34
ok row value: 56
failed: row 1: invalid digit found in string
failed: row 3: invalid digit found in string
all-or-nothing short-circuits: true
```

## 为什么

`Result` 是单错误的容器，`?`/`collect` 都在首错短路；「报全部」必须自己攒
`Vec<RowError>`（或用 iterator 的 partition）。两种语义各有适用面：
校验类场景（用户提交表单）聚合反馈体验好；事务类场景（要么全写入要么全不写）
all-or-nothing 才是正确语义——聚合反而是 bug。

## 反例

把首错短路硬套在用户校验上：用户每修一个字段就要重新提交一轮，第 N 轮才
发现第 N+1 个错误。反向反例是聚合用在外部副作用批次上——失败的行被跳过、
成功的行照常写入，「部分成功」没有对账记录，重跑时不知道哪些要补。

## 落点

聚合 vs 短路的场景对照见 `rust/docs/排查手册.md` 错误处理章
（M11-DOC-rust 卡落盘）。
