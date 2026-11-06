# E-011-error-display-reporting

<!-- coverage: exempt E 系错误处理演练：示范用例不接入毕业项目（毕业项目形态无错误展示分层落点），排查指引见 rust/docs/排查手册.md 错误处理章（M11-DOC-rust 卡落盘） -->

## 现象

同一个 `PaymentError` 给出两个视图：用户界面显示
`payment PAY-1234 failed`（稳定文案，无内部细节）；日志/工单里是完整
Debug 结构 `PaymentError { reference: ..., source: ParseIntError { kind: InvalidDigit } }`；
根因经 `source` 链单独走一层 `root cause walk`。两个视图来自同一个错误值，
不是两份手写文案。

## 复现

```
TAG=latest scripts/run-example.sh rust E-011-error-display-reporting
```

容器内断言：

```
docker run --rm -v "$PWD:/work" -w /work/rust/examples/E-011-error-display-reporting \
  ghcr.io/zeek-zhao/devbox-rust:latest bash assert.sh
```

## 期望输出

```
user view: payment PAY-1234 failed
operator view: PaymentError { reference: "PAY-1234", source: ParseIntError { kind: InvalidDigit } }
root cause walk: invalid digit found in string
```

## 为什么

`Display` 是承诺给使用者的文案，格式一变用户界面就跟着抖；`Debug` 是给
排障者的结构化现场，字段随便加。混用的两种事故：把 Debug 文案直接弹给
用户（内部类型名、字段名全部暴露）；把 Display 写进日志（根因和现场
全被文案吃掉，只能靠猜）。正确分工：UI 取 `Display`，日志取 `Debug`，
根因遍历取 `source` 链。

## 反例

在 `Display` 里塞根因细节：`"payment failed: ParseIntError { kind: ... }"`
——文案与内部实现耦合，重构一个字段名 UI 就变；同时日志里反而没有结构
（被拍平成一句话），聚合检索失效。

## 落点

错误展示分层（用户/排障/根因）见 `rust/docs/排查手册.md` 错误处理章
（M11-DOC-rust 卡落盘）。
