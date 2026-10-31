# L2-008-clippy-warnings

<!-- coverage: pending -->

## 考点
对应 KP-RS-L2-08：使用 `cargo clippy --offline --all-targets -- -D warnings` 设立零告警门禁。
看到无告警工程通过门禁并输出通过标记，说明掌握了将 Clippy 诊断纳入验收。

## 易错点
会把警告当作不影响验收的提示而持续累积；使用 `-D warnings` 并修复诊断，而非压制无关告警。
门禁命令必须从工程入口执行，并保留诊断和失败状态。

## 延伸
为库、二进制和测试目标分别增加 Clippy 覆盖。
将同一门禁放入持续集成，并针对新诊断修复代码而非降低检查级别。

## 复现
TAG=latest scripts/run-example.sh rust L2-008-clippy-warnings
