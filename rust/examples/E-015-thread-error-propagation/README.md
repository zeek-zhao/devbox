# E-015-thread-error-propagation

<!-- coverage: exempt E 系错误处理演练：示范用例不接入毕业项目（毕业项目形态无线程错误传播落点），排查指引见 rust/docs/排查手册.md 错误处理章（M11-DOC-rust 卡落盘） -->

## 现象

worker 线程的三种错误回流通道：`join()` 收回 `Ok(Ok(42))`（双层 Result：
外层是线程 panic 与否，内层是业务成功与否）；`join()` 收回业务错误
`BadInput(7)` 并还原成具体类型；`mpsc::channel` 把错误当值传出
`Ok(Err(BadInput(9)))`（外层 `Ok` 表示 recv 成功，内层 `Err` 是业务错误）。
第 3 段演示 `Mutex` 中毒：持锁线程 panic 后锁标记
中毒，但 increment 发生在 panic 之前、数据仍一致，`into_inner` 恢复
后计数为 1。

## 复现

```
TAG=latest scripts/run-example.sh rust E-015-thread-error-propagation
```

容器内断言：

```
docker run --rm -v "$PWD:/work" -w /work/rust/examples/E-015-thread-error-propagation \
  ghcr.io/zeek-zhao/devbox-rust:latest bash assert.sh
```

## 期望输出

```
join ok: Ok(Ok(42))
join err propagated: BadInput(7)
channel: Err(BadInput(9))
poison recovered: counter 1 (increment before panic survived)
```

## 为什么

线程边界是 Rust 错误处理的强制检查点：`join()` 的外层 `Result<_, Box<dyn Any>>`
逼你面对「worker 可能 panic」；业务错误要穿过去只能作为返回值或消息，
`Send` 约束保证了错误类型可跨线程。`Mutex` 的毒化设计同理——锁被标记
中毒是因为「持锁期间发生了不可预期的事」，数据是否真的损坏必须由
写作者判断，`into_inner` 是显式的「我确认数据仍可用」，不是绕过检查的 hack。

## 反例

worker 里 `unwrap()` 掉所有错误然后只返回裸值：调用方 `join()` 拿到的
永远是 `Ok`，失败信息只留在 worker 的 stderr 里，主线程无从重试。
另一个反例是见到 `PoisonError` 就 `unwrap()` 或者一律 `into_inner`——
前者把「持锁 panic」当正常路径，后者把可能真的损坏的数据放行给下游。

## 落点

线程边界错误传播与锁中毒处置见 `rust/docs/排查手册.md` 错误处理章
（M11-DOC-rust 卡落盘）。
