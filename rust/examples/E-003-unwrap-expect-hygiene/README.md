# E-003-unwrap-expect-hygiene

<!-- coverage: exempt E 系错误处理演练：示范用例不接入毕业项目（毕业项目形态无 unwrap 治理落点），排查指引见 rust/docs/排查手册.md 错误处理章（M11-DOC-rust 卡落盘） -->

## 现象

对不可信输入 `unwrap()`：进程以退出码 101 panic，stderr 只有
`called Result::unwrap() on an Err value: ...`，没有任何业务上下文，
只有一条 `RUST_BACKTRACE=1` 提示。同样的输入走 `Result` 处理则回退默认值、
退出码保持 0；`expect("语境")` 则把前提写进 panic 消息。

## 复现

```
TAG=latest scripts/run-example.sh rust E-003-unwrap-expect-hygiene
```

容器内断言：

```
docker run --rm -v "$PWD:/work" -w /work/rust/examples/E-003-unwrap-expect-hygiene \
  ghcr.io/zeek-zhao/devbox-rust:latest bash assert.sh
```

## 期望输出

```
expect-mode: fixture port 8080 (context attached)
handled-mode: invalid config -> fallback 0, exit stays 0
unwrap-mode: exit=101 (101 = panic)
unwrap-mode: stderr-panicked=yes
unwrap-mode: backtrace-hint=yes
unwrap-mode: context-in-message=no
```

## 为什么

`unwrap` 与 `expect` 的语义差异只在 panic 消息：`expect` 强迫写作者回答
「为什么这里不可能失败」，排查时这条语境直接指认被打破的前提；`unwrap` 消息
没有语境，线上只看到类型名。治理规则：外部输入一律 `Result`；
`unwrap`/`expect` 只允许出现在前提由测试钉死的位置（fixture、不变量断言），
并优先 `expect` 留下语境。

## 反例

为了「代码干净」把 `?` 全换成 `unwrap`：编译过了、测试输入过了，
第一个非法用户输入就把服务打崩（退出码 101 且无上下文）。反向反例是
把 `expect` 的消息写成 "parse failed" 这类废话——和不写一样，定位仍要靠猜。

## 落点

unwrap/expect 治理清单见 `rust/docs/排查手册.md` 错误处理章（M11-DOC-rust 卡落盘）。
