# E-002-main-return-result

<!-- coverage: exempt E 系错误处理演练：示范用例不接入毕业项目（毕业项目形态无 main 退出码语义落点），排查指引见 rust/docs/排查手册.md 错误处理章（M11-DOC-rust 卡落盘） -->

## 现象

`fn main() -> Result<(), Box<dyn Error>>` 返回 `Ok(())` 时退出码 0；
返回 `Err(e)` 时 std 运行时向 stderr 打印 `Error: <Debug>` 并以退出码 1 结束，
全程不需要手写 match 或 `std::process::exit`。本例 ok 模式与 bad-config 模式
各跑一次，对比退出码与诊断行。

## 复现

```
TAG=latest scripts/run-example.sh rust E-002-main-return-result
```

容器内断言：

```
docker run --rm -v "$PWD:/work" -w /work/rust/examples/E-002-main-return-result \
  ghcr.io/zeek-zhao/devbox-rust:latest bash assert.sh
```

## 期望输出

```
== case: ok ==
pipeline finished
ok-exit=0
== case: bad-config ==
bad-config-exit=1
Error: ConfigError { field: "workers", source: ParseIntError { kind: InvalidDigit } }
```

## 为什么

CLI 的调用方（shell、CI、systemd）只认退出码，不看 stdout。
`main` 返回 `Result` 把「成功/失败」映射成 0/非 0，错误值经 `Debug` 进 stderr，
一行代码就接入了 Unix 失败语义；`?` 在 `main` 里同样经 `From` 自动转换，
所以 `run` 返回 `Box<dyn Error>`、`parse_workers` 返回自定义错误，两者能直接串起来。

## 反例

`main` 返回 `()`、失败分支手动 `std::process::exit(1)`：错误信息要么丢失，
要么 `eprintln!` 散落在各处，格式不一且容易漏打；`exit` 还会跳过栈展开，
局部变量的 `Drop` 不执行，临时文件/锁的清理逻辑静默失效。

## 落点

退出码与诊断行口径见 `rust/docs/排查手册.md` 错误处理章（M11-DOC-rust 卡落盘）。
