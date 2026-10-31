# L2-007-fmt-check


## 考点
对应 KP-RS-L2-07：用 `cargo fmt --check` 验证源码符合 rustfmt 格式。
看到已格式化源码的检查结论为通过，说明格式门禁成功执行且未改写文件。

## 易错点
只在本机手动格式化，可能漏掉提交时 CI 的格式差异。
提交前运行检查模式，并按 rustfmt 输出修正后再次检查。

## 延伸
把 `cargo fmt --check` 纳入 Rust 项目的持续集成门禁。
检查多目标 crate 的所有源码，确保格式一致且可复现。

## 复现
TAG=latest scripts/run-example.sh rust L2-007-fmt-check
