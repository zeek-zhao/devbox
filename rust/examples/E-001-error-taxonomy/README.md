# E-001-error-taxonomy

<!-- coverage: exempt E 系错误处理演练：示范用例不接入毕业项目（毕业项目形态无对应错误分类落点），排查指引见 rust/docs/排查手册.md 错误处理章（M11-DOC-rust 卡落盘） -->

## 现象

同一种「失败」在不同场景该走不同出口：外部输入解析失败是可恢复错误（`Result`），
排序后仍乱序这类不变量破坏是不可恢复错误（panic）。本例把两类失败各演示一次：
可恢复分支回退默认端口后继续执行，不可恢复分支 panic（示例用 `catch_unwind`
捕获取证，避免示例自身崩溃；真实代码不这样用）。

## 复现

```
TAG=latest scripts/run-example.sh rust E-001-error-taxonomy
```

容器内断言：

```
docker run --rm -v "$PWD:/work" -w /work/rust/examples/E-001-error-taxonomy \
  ghcr.io/zeek-zhao/devbox-rust:latest bash assert.sh
```

## 期望输出

```
recoverable: Err -> fallback port 0
recoverable: Ok -> port 8080
unrecoverable: invariant panic caught = true
taxonomy: recoverable=Result, unrecoverable=panic
```

## 为什么

分类决策是错误处理的第一步：失败「能否被调用方有意义地处理」决定出口。
可恢复错误用 `Result` 上抛，让调用方决定重试、降级或取默认值；破坏不变量的
状态继续跑只会污染下游，panic 终止是唯一安全选择。`catch_unwind` 在真实代码
里只用于 FFI 边界与线程池兜底，不是常规错误处理手段——被捕获的 panic 仍是 bug。

## 反例

把所有失败都写成 panic（对外部输入 `assert!`/`unwrap`）：配置解析失败直接打崩
服务，调用方没有任何介入机会。反过来用 `Result` 表达不变量破坏（返回一个
「不可能发生」的枚举变体），调用方被迫「处理」一个本不该发生的错误，把 bug
伪装成业务分支，排障时真假失败混在一起无从下手。

## 落点

错误分类决策表见 `rust/docs/排查手册.md` 错误处理章（M11-DOC-rust 卡落盘）。
